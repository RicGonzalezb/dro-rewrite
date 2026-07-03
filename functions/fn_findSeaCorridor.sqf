// DRO_fnc_findSeaCorridor — finds a boat-insertion water corridor seeded from a reference point.
// Param: _origin (position) — the landward seed (AO centre for the default corridor, or the
//   custom insertion point the player set in Team Planning).
// Returns: [_viable, _spawnPos, _dropPos, _corridor, _origin]
//   _dropPos  — shallow, floatable shore cell nearest _origin that connects to the open sea.
//   _spawnPos — offshore boat spawn with an all-water straight corridor to the drop.
//   _corridor — array of waypoint positions spawn->drop.
// Pure: does NOT publish globals; the caller commits. Map-agnostic. No exitWith inside loops.
params [["_origin", [0,0,0]]];

private _maxScan = missionNamespace getVariable ["DRO_seaDropMaxRadius", aoSize + 800];
private _maxDist = missionNamespace getVariable ["DRO_seaInsertMaxDist", 800];

private _fnc_lineIsWater = {
	params ["_a", "_b", ["_step", 40]];
	private _d = _a distance2D _b;
	private _dir = [_a, _b] call BIS_fnc_dirTo;
	private _n = (ceil (_d / _step)) max 1;
	private _ok = true;
	for "_i" from 0 to _n do {
		if (_ok) then {
			private _sp = _a getPos [(_d * _i / _n), _dir];
			if (!surfaceIsWater _sp) then { _ok = false; };
		};
	};
	_ok
};

// Sea vs lake test: BFS flood over 100m water cells; true if the body reaches the map edge (= sea).
private _fnc_waterReachesEdge = {
	params ["_p"];
	private _cell = 100;
	private _ws = worldSize;
	private _margin = 200;
	private _cap = 1500;
	private _sx = (floor ((_p select 0) / _cell)) * _cell + (_cell / 2);
	private _sy = (floor ((_p select 1) / _cell)) * _cell + (_cell / 2);
	private _open = [[_sx, _sy]];
	private _seen = createHashMap;
	_seen set [format ["%1_%2", _sx, _sy], true];
	private _reached = false;
	private _cnt = 0;
	while {(count _open > 0) && (!_reached) && (_cnt < _cap)} do {
		private _c = _open deleteAt 0;
		_cnt = _cnt + 1;
		private _cx = _c select 0;
		private _cy = _c select 1;
		if ((_cx < _margin) || (_cx > (_ws - _margin)) || (_cy < _margin) || (_cy > (_ws - _margin))) then {
			_reached = true;
		} else {
			{
				private _nx = _cx + (_x select 0);
				private _ny = _cy + (_x select 1);
				private _k = format ["%1_%2", _nx, _ny];
				if (isNil {_seen get _k}) then {
					_seen set [_k, true];
					if (surfaceIsWater [_nx, _ny, 0]) then { _open pushBack [_nx, _ny]; };
				};
			} forEach [[_cell, 0], [-_cell, 0], [0, _cell], [0, -_cell]];
		};
	};
	_reached || (_cnt >= _cap)
};

// 1. Nearest shallow SEA cell to the seed (depth 0..-3m, connects to the map edge, not a lake).
private _dropPos = [];
private _foundDrop = false;
private _floods = 0;
private _maxFloods = 8;
private _r = 200;
while {(!_foundDrop) && (_r <= _maxScan) && (_floods < _maxFloods)} do {
	private _deg = 0;
	while {(!_foundDrop) && (_deg < 360) && (_floods < _maxFloods)} do {
		private _pp = _origin getPos [_r, _deg];
		if (surfaceIsWater _pp) then {
			private _depth = getTerrainHeightASL _pp;
			if ((_depth < 0) && (_depth > -3)) then {
				_floods = _floods + 1;
				if ([_pp] call _fnc_waterReachesEdge) then {
					_dropPos = [_pp select 0, _pp select 1, 0];
					_foundDrop = true;
				};
			};
		};
		_deg = _deg + 20;
	};
	_r = _r + 100;
};

private _viable = false;
private _spawnPos = [];
private _corridor = [];

if (_foundDrop) then {
	// Local shore normal at the drop: nearest-land direction is landward; seaward is opposite.
	// True beach-perpendicular, independent of where the AO centre sits along the coast.
	private _landward = [_dropPos, _origin] call BIS_fnc_dirTo;   // fallback: toward the AO centre
	private _bestLandDist = 1e9;
	for "_a" from 0 to 345 step 15 do {
		private _dd = 10;
		private _hit = -1;
		while {(_hit < 0) && (_dd <= 220)} do {
			private _tp = _dropPos getPos [_dd, _a];
			if (!surfaceIsWater _tp) then { _hit = _dd; };
			_dd = _dd + 10;
		};
		if ((_hit > 0) && (_hit < _bestLandDist)) then {
			_bestLandDist = _hit;
			_landward = _a;
		};
	};
	private _seaward = _landward + 180;

	// 2. Advance the drop shoreward (toward nearest land) to the last floatable cell before the beach.
	private _landDir = _landward;
	private _refined = +_dropPos;
	private _rd = 5;
	private _walk = true;
	while {_walk && (_rd <= 150)} do {
		private _cp = _dropPos getPos [_rd, _landDir];
		if (surfaceIsWater _cp) then {
			if ((getTerrainHeightASL _cp) > -0.4) then {
				_walk = false;
			} else {
				_refined = [_cp select 0, _cp select 1, 0];
			};
		} else {
			_walk = false;
		};
		_rd = _rd + 5;
	};
	_dropPos = _refined;

	// 3. Reverse path: offshore spawn within maxDist with an all-water corridor to the drop.
	// Prefer lanes closer to the shore-perpendicular: score = clear reach minus an angle penalty,
	// so an oblique lane only wins if it has substantially more open water than the perpendicular.
	private _anglePenalty = 8;   // metres of reach penalised per degree off perpendicular (tunable)
	private _bestScore = -1e9;
	private _bestSpawn = [];
	{
		private _deg = _seaward + _x;
		private _clearTo = 0;
		private _d = 100;
		private _broken = false;
		while {(!_broken) && (_d <= _maxDist)} do {
			private _cand = _dropPos getPos [_d, _deg];
			if ((surfaceIsWater _cand) && {[_dropPos, _cand, 40] call _fnc_lineIsWater}) then {
				_clearTo = _d;
			} else {
				_broken = true;
			};
			_d = _d + 50;
		};
		if (_clearTo >= 300) then {
			private _score = _clearTo - (abs _x) * _anglePenalty;
			if (_score > _bestScore) then {
				_bestScore = _score;
				_bestSpawn = _dropPos getPos [_clearTo, _deg];
			};
		};
	} forEach [-40, -20, -15, -10, -5, 0, 5, 10, 15, 20, 40];

	if (count _bestSpawn > 0) then {   // set only when a lane >=300m existed
		_spawnPos = [_bestSpawn select 0, _bestSpawn select 1, 0];
		private _cdir = [_spawnPos, _dropPos] call BIS_fnc_dirTo;
		private _ctot = _spawnPos distance2D _dropPos;
		private _steps = 3;
		for "_i" from 0 to _steps do {
			private _cp = _spawnPos getPos [(_ctot * _i / _steps), _cdir];
			_corridor pushBack [_cp select 0, _cp select 1, 0];
		};
		_viable = true;
	};
};

[_viable, _spawnPos, _dropPos, _corridor, _origin]
