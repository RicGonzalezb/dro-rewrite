// DRO_fnc_findSeaCorridor - finds a boat-insertion water corridor seeded from a reference point.
// Params:
//   _origin (position)     - landward seed (AO centre for the default corridor, or the custom point).
//   _avoidPerimeter (bool) - if true, prefer a flanking beach OUTSIDE the AO's occupied footprint
//                            (stealth), falling back to the nearest-to-origin beach if none is viable.
// Returns: [_viable, _spawnPos, _dropPos, _corridor, _origin]. Pure: publishes nothing. Map-agnostic.
params [["_origin", [0,0,0]], ["_avoidPerimeter", false]];

private _maxScan = missionNamespace getVariable ["DRO_seaDropMaxRadius", aoSize + 1000];
private _maxDist = missionNamespace getVariable ["DRO_seaInsertMaxDist", 800];
private _aoLocs  = missionNamespace getVariable ["AOLocations", []];

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

// Build a full corridor result from a given drop candidate. Returns [_viable, _spawn, _drop, _corridor].
private _fnc_buildFromDrop = {
	params ["_dropPos"];

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

	// Advance the drop shoreward to the last floatable cell before the beach (~0.4 m).
	private _refined = +_dropPos;
	private _rd = 5;
	private _walk = true;
	while {_walk && (_rd <= 150)} do {
		private _cp = _dropPos getPos [_rd, _landward];
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

	// Reverse path: offshore spawn along the seaward normal, scored to prefer the perpendicular.
	private _anglePenalty = 8;
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

	private _res = [false, [], _dropPos, []];
	if (count _bestSpawn > 0) then {
		private _spawnPos = [_bestSpawn select 0, _bestSpawn select 1, 0];
		private _corridor = [];
		private _cdir = [_spawnPos, _dropPos] call BIS_fnc_dirTo;
		private _ctot = _spawnPos distance2D _dropPos;
		private _steps = 3;
		for "_i" from 0 to _steps do {
			private _cp = _spawnPos getPos [(_ctot * _i / _steps), _cdir];
			_corridor pushBack [_cp select 0, _cp select 1, 0];
		};
		_res = [true, _spawnPos, _dropPos, _corridor];
	};
	_res
};

// Assemble candidate drops in priority order.
private _candidates = [];

// Primary (stealth): walk the coastline, score each beach by isolation from the enemy clusters, and
// try the most-isolated first. Degrades gracefully: worst case is the least-isolated beach, never a
// hard fall to the AO heart. Only used when _avoidPerimeter (the default/centre-seeded corridor).
if (_avoidPerimeter) then {
	private _occCap = 550;   // per-location "occupied" radius (~where enemies actually sit; tunable)
	private _beaches = [];
	for "_ang" from 0 to 350 step 10 do {
		private _r = 200;
		private _beach = [];
		while {(count _beach == 0) && (_r <= _maxScan)} do {
			private _pp = _origin getPos [_r, _ang];
			if (surfaceIsWater _pp) then {
				private _depth = getTerrainHeightASL _pp;
				if ((_depth < 0) && (_depth > -3) && {[_pp] call _fnc_waterReachesEdge}) then {
					_beach = [_pp select 0, _pp select 1, 0];
				};
			};
			_r = _r + 50;
		};
		if (count _beach > 0) then {
			private _iso = 1e9;
			{
				private _occR = (_x select 1) min _occCap;
				private _clear = (_beach distance2D (_x select 0)) - _occR;
				if (_clear < _iso) then { _iso = _clear; };
			} forEach _aoLocs;
			_beaches pushBack [_iso, _beach];
		};
	};
	_beaches sort false;   // most-isolated first (descending by score)
	{ _candidates pushBack (_x select 1); } forEach _beaches;
};

private _stealthCount = count _candidates;

// Fallback: nearest shallow sea to the origin (also the custom-point behaviour), tried last.
private _near = [];
private _found = false;
private _floods = 0;
private _r0 = 200;
while {(!_found) && (_r0 <= _maxScan) && (_floods < 8)} do {
	private _deg = 0;
	while {(!_found) && (_deg < 360) && (_floods < 8)} do {
		private _pp = _origin getPos [_r0, _deg];
		if (surfaceIsWater _pp) then {
			private _depth = getTerrainHeightASL _pp;
			if ((_depth < 0) && (_depth > -3)) then {
				_floods = _floods + 1;
				if ([_pp] call _fnc_waterReachesEdge) then {
					_near = [_pp select 0, _pp select 1, 0];
					_found = true;
				};
			};
		};
		_deg = _deg + 20;
	};
	_r0 = _r0 + 100;
};
if (count _near > 0) then { _candidates pushBack _near; };

// Try candidates in order; the first that yields a viable corridor wins.
private _out = [false, [], [], [], _origin];
private _done = false;
private _winIdx = -1;
{
	if (!_done) then {
		private _b = [_x] call _fnc_buildFromDrop;
		if (_b select 0) then {
			_out = [true, _b select 1, _b select 2, _b select 3, _origin];
			_done = true;
			_winIdx = _forEachIndex;
		};
	};
} forEach _candidates;

_out
