// *****
// Corridor Civilians v3 — Extended AO only
// Spawns peaceful civilians at villages/hamlets BETWEEN AOs.
// Direct agent/unit creation (no BIS module — simpler, more reliable).
// Searches along the full axis between each AO pair, not just midpoints.
// *****

if (count AOLocations <= 1) exitWith {
	diag_log "DRO: Corridor civs skipped — single AO";
};

private _useAgents = (civiliansAsAgents == 0);
diag_log format ["DRO: Generating corridor civilians v3 (agents=%1)", _useAgents];

// Collect AO positions and sizes for exclusion filtering
private _aoPositions = AOLocations apply {_x select 0};
private _aoSizes = AOLocations apply {_x select 1};

// --- Phase 1: Find unique corridor locations between all AO pairs ---
// Search at 3 points along each axis (25%, 50%, 75%) to catch locations
// that aren't near the midpoint but ARE between two AOs.

private _corridorLocations = [];
private _usedLocationNames = [];

for "_i" from 0 to (count AOLocations - 2) do {
	for "_j" from (_i + 1) to (count AOLocations - 1) do {
		private _posA = (AOLocations select _i) select 0;
		private _posB = (AOLocations select _j) select 0;
		private _dist = _posA distance2D _posB;

		// Skip AO pairs too close together (< 600m — likely overlapping)
		if (_dist < 600) then { continue };

		// Search at 25%, 50%, 75% along the axis
		{
			private _t = _x;
			private _searchPos = [
				((_posA select 0) * (1 - _t)) + ((_posB select 0) * _t),
				((_posA select 1) * (1 - _t)) + ((_posB select 1) * _t)
			];

			// Search radius: 1/3 of distance, clamped 400–2000m
			private _searchRadius = ((_dist / 3) max 400) min 2000;

			private _nearLocs = nearestLocations [_searchPos, ["NameLocal", "NameVillage"], _searchRadius];

			{
				private _locPos = getPos _x;
				private _locName = text _x;

				// Skip if inside any existing AO radius
				private _insideAO = false;
				{
					if (_locPos distance2D _x < (_aoSizes select _forEachIndex)) exitWith { _insideAO = true };
				} forEach _aoPositions;

				// Skip duplicates
				if (!_insideAO && !(_locName in _usedLocationNames)) then {
					_corridorLocations pushBack _x;
					_usedLocationNames pushBack _locName;
					diag_log format ["DRO: Corridor location found: %1 (%2) at %3 [axis %4-%5, t=%6]",
						_locName, type _x, _locPos, _i, _j, _t];
				};
			} forEach _nearLocs;
		} forEach [0.25, 0.5, 0.75];
	};
};

// Cap at 8 corridor locations (raised from 5 — direct spawn is cheaper than BIS module)
if (count _corridorLocations > 8) then {
	_corridorLocations resize 8;
};

if (count _corridorLocations == 0) exitWith {
	diag_log "DRO: No corridor locations found between AOs";
};

diag_log format ["DRO: Found %1 corridor locations for direct civilian spawn", count _corridorLocations];

// --- Phase 2: Spawn civilians directly at each corridor location ---
// No BIS module — just createAgent (or createUnit). Simple, reliable.

private _totalSpawned = 0;

{
	private _loc = _x;
	private _locPos = getPos _loc;
	private _locName = text _loc;
	private _locType = type _loc;

	// Lighter unit counts than AO civs
	private _unitCount = switch (_locType) do {
		case "NameVillage": { [4, 7] call BIS_fnc_randomInt };
		case "NameLocal": { [2, 4] call BIS_fnc_randomInt };
		default { [2, 3] call BIS_fnc_randomInt };
	};

	// Area size based on location type
	private _areaSize = switch (_locType) do {
		case "NameVillage": { 400 };
		case "NameLocal": { 250 };
		default { 200 };
	};

	// --- Gather spawn positions: roads (+ buildings when units mode) ---
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

	// Buildings — only when units mode (agents can't navigate interiors)
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

	// Spawn civs directly — no BIS module needed
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
	diag_log format ["DRO: Corridor civs at %1: %2/%3 spawned (agents=%4), area %5m",
		_locName, _spawned, _unitCount, _useAgents, _areaSize];

} forEach _corridorLocations;

diag_log format ["DRO: Corridor civilian generation complete — %1 locations, %2 civs total", count _corridorLocations, _totalSpawned];
