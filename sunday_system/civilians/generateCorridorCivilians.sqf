// *****
// Corridor & Satellite Civilians v4
// Phase 1: Satellite — 1km radius around each AO center (outside AO radius)
// Phase 2: Corridor — rectangular area between each AO pair (length=dist, width=1km)
// Direct agent/unit creation (no BIS module).
// Marker rectangles used only for inArea calculation, deleted after use.
// *****

if (count AOLocations <= 1) exitWith {
	diag_log "DRO: Corridor civs skipped — single AO";
};

private _useAgents = (civiliansAsAgents == 0);
diag_log format ["DRO: Generating corridor/satellite civilians v4 (agents=%1, AOs=%2)", _useAgents, count AOLocations];

// Collect AO positions and sizes for filtering
private _aoPositions = AOLocations apply {_x select 0};
private _aoSizes = AOLocations apply {_x select 1};

private _allLocations = [];
private _usedLocationNames = [];

// --- Phase 1: Satellite — 1km radius around each AO center ---
// Finds villages/hamlets near each AO but OUTSIDE its operational radius.
// These are "suburb" locations not covered by generateCivilians.sqf.

{
	private _aoPos = _x;
	private _aoSize = _aoSizes select _forEachIndex;
	private _aoIdx = _forEachIndex;

	private _nearLocs = nearestLocations [_aoPos, ["NameLocal", "NameVillage"], 1000];

	{
		private _locPos = getPos _x;
		private _locName = text _x;

		// Must be OUTSIDE this AO's operational radius
		private _distToAO = _locPos distance2D _aoPos;
		if (_distToAO < _aoSize) then {
			diag_log format ["DRO: Sat SKIP (inside AO %1): %2, dist=%3m < aoSize=%4m",
				_aoIdx, _locName, round _distToAO, round _aoSize];
		} else {
			// Must not be inside any OTHER AO's radius either
			private _insideOtherAO = false;
			private _whichAO = -1;
			{
				if (_forEachIndex != _aoIdx && {_locPos distance2D _x < (_aoSizes select _forEachIndex)}) exitWith {
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

// --- Phase 2: Corridor — rectangular area between each AO pair ---
// For each unique pair (i,j): create invisible rectangular marker centered
// at midpoint, length = distance between AO centers, width = 1km.
// Find locations inside the rectangle, excluding AOs and Phase 1 results.

private _corridorMarkers = [];

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

		// Direction from A to B (compass bearing for setMarkerDir)
		private _dx = (_posB select 0) - (_posA select 0);
		private _dy = (_posB select 1) - (_posA select 1);
		private _dir = _dx atan2 _dy;

		// Create invisible rectangular marker
		// setMarkerSize [halfWidth, halfLength] — after setMarkerDir, the b-axis aligns with direction
		private _markerName = format ["DRO_corridor_%1_%2", _i, _j];
		private _marker = createMarker [_markerName, _midPos];
		_marker setMarkerShape "RECTANGLE";
		_marker setMarkerSize [500, _dist / 2];
		_marker setMarkerDir _dir;
		_marker setMarkerAlpha 0;
		_corridorMarkers pushBack _marker;

		diag_log format ["DRO: Corridor marker %1-%2: mid=%3, dist=%4m, dir=%5, size=[500,%6]",
			_i, _j, _midPos, round _dist, round _dir, round (_dist / 2)];

		// Search for locations — radius covers the rectangle's diagonal + margin
		private _searchRadius = (_dist / 2) + 600;
		private _nearLocs = nearestLocations [_midPos, ["NameLocal", "NameVillage"], _searchRadius];

		private _foundThisPair = 0;
		{
			private _locPos = getPos _x;
			private _locName = text _x;

			// Must be inside the corridor rectangle
			if !(_locPos inArea _marker) then {
				// Skip silently — most locations won't be in the rectangle
			} else {
				// Must not be inside any AO radius
				private _insideAO = false;
				private _whichAO = -1;
				{
					if (_locPos distance2D _x < (_aoSizes select _forEachIndex)) exitWith {
						_insideAO = true;
						_whichAO = _forEachIndex;
					};
				} forEach _aoPositions;

				if (_insideAO) then {
					diag_log format ["DRO: Corridor SKIP (inside AO %1): %2", _whichAO, _locName];
				} else {
					if (_locName in _usedLocationNames) then {
						diag_log format ["DRO: Corridor SKIP (already found): %1", _locName];
					} else {
						_allLocations pushBack _x;
						_usedLocationNames pushBack _locName;
						_foundThisPair = _foundThisPair + 1;
						diag_log format ["DRO: Corridor location: %1 (%2) at %3 [pair %4-%5]",
							_locName, type _x, _locPos, _i, _j];
					};
				};
			};
		} forEach _nearLocs;

		diag_log format ["DRO: Corridor pair %1-%2: searched %3 candidates, added %4 new locations",
			_i, _j, count _nearLocs, _foundThisPair];
	};
};

// Cleanup — markers served their purpose
{ deleteMarker _x } forEach _corridorMarkers;

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
