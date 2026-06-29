// *****
// Corridor & Satellite Civilians v5
// Phase 1: Satellite — ring _aoSize*0.6 … _aoSize+1500 around each AO center
// Phase 2: Corridor — explicit point-to-segment geometry (no markers/inArea)
// Fix: excludeRadius = aoSize*0.6 liberates perimeter villages from exclusion.
// Direct agent/unit creation (no BIS module).
// *****

// Satellite (Phase 1) runs for ANY number of AOs, including a single AO.
// The corridor pass (Phase 2) self-skips when there is only 1 AO, because
// its pair loop (`for _i from 0 to count-2`) simply doesn't iterate.

// Only populate corridors/satellites when civilians-as-agents is ENABLED.
// With full units (agents OFF), spreading extra civs across the periphery
// is a performance cost not worth paying.
if (civiliansAsAgents != 0) exitWith {
	diag_log "DRO: Corridor/satellite civs skipped — civilians-as-agents is DISABLED";
};

// audit: bail se nao ha classes de civis (faccao civ sem unidades) — evita selectRandom nil no spawn
if (isNil "civClasses" || {civClasses isEqualTo []}) exitWith {
	diag_log "DRO: Corridor/satellite civs skipped — civClasses vazio";
};

private _useAgents = (civiliansAsAgents == 0);
diag_log format ["DRO: Generating corridor/satellite civilians v5 (agents=%1, AOs=%2)", _useAgents, count AOLocations];

// Collect AO positions and sizes for filtering
private _aoPositions = AOLocations apply {_x select 0};
private _aoSizes = AOLocations apply {_x select 1};

private _allLocations = [];
private _usedLocationNames = [];

// --- Phase 1: Satellite — ring _excludeRadius … _aoSize+1500 around each AO center ---
// Finds villages/hamlets near each AO but OUTSIDE its exclusion core.
// These are "suburb" locations not covered by generateCivilians.sqf.

{
	private _aoPos = _x;
	private _aoSize = _aoSizes select _forEachIndex;
	private _aoIdx = _forEachIndex;
	private _excludeRadius = _aoSize * 0.6;
	private _searchRadius = 2000; // teto 2km a partir do CENTRO da AO (Gonza). Era _aoSize+1500. Fase 2 (corredor) NAO alterada.

	private _nearLocs = nearestLocations [_aoPos, ["NameLocal", "NameVillage"], _searchRadius];

	{
		private _locPos = getPos _x;
		private _locName = text _x;

		// Must be OUTSIDE this AO's exclusion radius
		private _distToAO = _locPos distance2D _aoPos;
		if (_distToAO < _excludeRadius) then {
			diag_log format ["DRO: Sat SKIP (inside AO %1): %2, dist=%3m < excludeRadius=%4m",
				_aoIdx, _locName, round _distToAO, round _excludeRadius];
		} else {
			// Must not be inside any OTHER AO's exclusion radius either
			private _insideOtherAO = false;
			private _whichAO = -1;
			{
				private _otherExclude = (_aoSizes select _forEachIndex) * 0.6;
				if (_forEachIndex != _aoIdx && {_locPos distance2D _x < _otherExclude}) exitWith {
					_insideOtherAO = true;
					_whichAO = _forEachIndex;
				};
			} forEach _aoPositions;

			if (_insideOtherAO) then {
				diag_log format ["DRO: Sat SKIP (inside other AO %1): %2", _whichAO, _locName];
			} else {
				if (_locName in _usedLocationNames) then {
					diag_log format ["DRO: Sat SKIP (duplicate): %1", _locName];
				} else {
					_allLocations pushBack _x;
					_usedLocationNames pushBack _locName;
					diag_log format ["DRO: Satellite location: %1 (%2) at %3 [AO %4, dist=%5m]",
						_locName, type _x, _locPos, _aoIdx, round _distToAO];
				};
			};
		};
	} forEach _nearLocs;
} forEach _aoPositions;

diag_log format ["DRO: Phase 1 (satellite) found %1 locations", count _allLocations];

// --- Phase 2: Corridor — explicit point-to-segment geometry ---
// For each unique pair (i,j): accept locations within _corridorHalfWidth of
// the A→B axis, within the A→B extent (t in [-0.1, 1.1]), and outside AO cores.
// No markers or inArea — avoids the rotation/semantics bug.

private _corridorHalfWidth = 700;

for "_i" from 0 to (count _aoPositions - 2) do {
	for "_j" from (_i + 1) to (count _aoPositions - 1) do {
		private _posA = _aoPositions select _i;
		private _posB = _aoPositions select _j;
		private _dist = _posA distance2D _posB;

		// Skip overlapping AOs
		if (_dist < 600) then {
			diag_log format ["DRO: Corridor SKIP pair %1-%2: dist=%3m (< 600m)", _i, _j, round _dist];
			continue;
		};

		// Midpoint between the two AO centers
		private _midPos = [
			((_posA select 0) + (_posB select 0)) / 2,
			((_posA select 1) + (_posB select 1)) / 2
		];

		// Search radius: half-dist + corridor half-width + margin
		private _searchRadius = (_dist / 2) + 800;
		private _nearLocs = nearestLocations [_midPos, ["NameLocal", "NameVillage"], _searchRadius];

		diag_log format ["DRO: Corridor pair %1-%2: dist=%3m, %4 candidates (searchRadius=%5m)",
			_i, _j, round _dist, count _nearLocs, round _searchRadius];

		// Segment AB components for point-to-segment projection
		private _ax = _posA select 0; private _ay = _posA select 1;
		private _bx = _posB select 0; private _by = _posB select 1;
		private _dxAB = _bx - _ax; private _dyAB = _by - _ay;
		private _lenSq = (_dxAB * _dxAB) + (_dyAB * _dyAB);

		private _foundThisPair = 0;
		{
			private _locPos = getPos _x;
			private _locName = text _x;
			private _px = _locPos select 0; private _py = _locPos select 1;

			// Project P onto segment A→B; clamp foot to segment for perp distance
			private _t = if (_lenSq > 0) then {
				(((_px - _ax) * _dxAB) + ((_py - _ay) * _dyAB)) / _lenSq
			} else { 0 };
			private _tc = (0 max _t) min 1;
			private _footX = _ax + _tc * _dxAB;
			private _footY = _ay + _tc * _dyAB;
			private _perp = [_px, _py] distance2D [_footX, _footY];

			// Accept if within half-width and within segment extent (small margin)
			private _inCorridor = (_perp <= _corridorHalfWidth) && (_t >= -0.1) && (_t <= 1.1);

			if (!_inCorridor) then {
				diag_log format ["DRO: Corridor cand %1: perp=%2m, t=%3, decision=REJECT (outside corridor)",
					_locName, round _perp, _t toFixed 2];
			} else {
				// Must not be inside any AO's exclusion core
				private _insideAO = false;
				private _whichAO = -1;
				{
					private _aoExclude = (_aoSizes select _forEachIndex) * 0.6;
					private _d = _locPos distance2D _x;
					if (_d < _aoExclude) exitWith {
						_insideAO = true;
						_whichAO = _forEachIndex;
						diag_log format ["DRO: excluded (AO core %1): %2, dist=%3 < %4",
							_forEachIndex, _locName, round _d, round _aoExclude];
					};
				} forEach _aoPositions;

				if (_insideAO) then {
					diag_log format ["DRO: Corridor cand %1: perp=%2m, t=%3, decision=REJECT (AO core %4)",
						_locName, round _perp, _t toFixed 2, _whichAO];
				} else {
					if (_locName in _usedLocationNames) then {
						diag_log format ["DRO: Corridor cand %1: perp=%2m, t=%3, decision=REJECT (duplicate)",
							_locName, round _perp, _t toFixed 2];
					} else {
						_allLocations pushBack _x;
						_usedLocationNames pushBack _locName;
						_foundThisPair = _foundThisPair + 1;
						diag_log format ["DRO: Corridor cand %1: perp=%2m, t=%3, decision=ACCEPT [pair %4-%5]",
							_locName, round _perp, _t toFixed 2, _i, _j];
					};
				};
			};
		} forEach _nearLocs;

		diag_log format ["DRO: Corridor pair %1-%2: searched %3 candidates, added %4 new locations",
			_i, _j, count _nearLocs, _foundThisPair];
	};
};

diag_log format ["DRO: Phase 1+2 total: %1 unique locations", count _allLocations];

if (count _allLocations == 0) exitWith {
	diag_log "DRO: No corridor/satellite locations found — nothing to spawn";
};

// Safety cap
if (count _allLocations > 15) then {
	diag_log format ["DRO: Capping from %1 to 15 locations", count _allLocations];
	_allLocations resize 15;
};

// --- Phase 3: Spawn civilians at each discovered location ---
// Counts are 50-75% of AO standard (lighter population for periphery).

private _totalSpawned = 0;

{
	private _loc = _x;
	private _locPos = getPos _loc;
	private _locName = text _loc;
	private _locType = type _loc;

	// Reduced counts: ~60% of AO standard
	private _unitCount = switch (_locType) do {
		case "NameVillage": { [3, 5] call BIS_fnc_randomInt };
		case "NameLocal": { [1, 3] call BIS_fnc_randomInt };
		default { [1, 2] call BIS_fnc_randomInt };
	};

	private _areaSize = switch (_locType) do {
		case "NameVillage": { 400 };
		case "NameLocal": { 250 };
		default { 200 };
	};

	// --- Gather spawn positions: roads + buildings (units mode only) ---
	private _spawnPositions = [];

	// Roads nearby
	private _roads = _locPos nearRoads _areaSize;
	{
		if (count _spawnPositions >= _unitCount) exitWith {};
		private _rPos = getPos _x;
		private _tooClose = false;
		{ if (_rPos distance2D _x < 30) exitWith { _tooClose = true } } forEach _spawnPositions;
		if (!_tooClose) then { _spawnPositions pushBack _rPos };
	} forEach _roads;

	// Buildings — only in units mode (agents can't navigate interiors)
	if (!_useAgents) then {
		private _buildings = _locPos nearObjects ["House", _areaSize];
		{
			if (count _spawnPositions >= _unitCount) exitWith {};
			private _bPos = getPos _x;
			private _tooClose = false;
			{ if (_bPos distance2D _x < 30) exitWith { _tooClose = true } } forEach _spawnPositions;
			if (!_tooClose) then { _spawnPositions pushBack _bPos };
		} forEach _buildings;
	};

	// Fallback: location center
	if (count _spawnPositions == 0) then {
		_spawnPositions pushBack _locPos;
	};

	// Spawn civilians directly
	private _spawnCount = _unitCount min (count _spawnPositions);
	private _spawned = 0;

	for "_c" from 0 to (_spawnCount - 1) do {
		private _pos = _spawnPositions select _c;
		private _civType = selectRandom civClasses;

		if (_useAgents) then {
			private _agent = createAgent [_civType, _pos, [], 5, "NONE"];
			_agent setBehaviour "CARELESS";
			_agent enableDynamicSimulation true;
			[_agent] call DRO_fnc_civDeathHandler;
		} else {
			private _grp = createGroup civilian;
			private _unit = _grp createUnit [_civType, _pos, [], 5, "NONE"];
			_unit setBehaviour "CARELESS";
			_grp enableDynamicSimulation true;
			[_unit] call DRO_fnc_civDeathHandler;
		};
		_spawned = _spawned + 1;
	};

	_totalSpawned = _totalSpawned + _spawned;
	diag_log format ["DRO: Civs at %1: %2/%3 spawned (agents=%4), area %5m",
		_locName, _spawned, _unitCount, _useAgents, _areaSize];

} forEach _allLocations;

diag_log format ["DRO: Corridor/satellite generation complete — %1 locations, %2 civs total",
	count _allLocations, _totalSpawned];
