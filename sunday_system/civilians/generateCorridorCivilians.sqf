// *****
// Corridor Civilians — Extended AO only
// Spawns peaceful civilians at villages/hamlets BETWEEN AOs.
// Makes the map feel more alive outside combat zones.
// Only agents (civiliansAsAgents == 0) or isolated units — no groups, no hostile civs.
// *****

if (count AOLocations <= 1) exitWith {
	diag_log "DRO: Corridor civs skipped — single AO";
};

private _useAgents = (civiliansAsAgents == 0);
diag_log format ["DRO: Generating corridor civilians (agents=%1)", _useAgents];

// Collect AO positions and sizes for exclusion filtering
private _aoPositions = AOLocations apply {_x select 0};
private _aoSizes = AOLocations apply {_x select 1};

// --- Phase 1: Find unique corridor locations between all AO pairs ---

private _corridorLocations = [];
private _usedLocationNames = [];

for "_i" from 0 to (count AOLocations - 2) do {
	for "_j" from (_i + 1) to (count AOLocations - 1) do {
		private _posA = (AOLocations select _i) select 0;
		private _posB = (AOLocations select _j) select 0;

		// Midpoint between the two AOs
		private _midpoint = [
			((_posA select 0) + (_posB select 0)) / 2,
			((_posA select 1) + (_posB select 1)) / 2
		];

		// Search radius: 1/3 of distance, clamped 300–1500m
		private _dist = _posA distance2D _posB;
		private _searchRadius = ((_dist / 3) max 300) min 1500;

		// Find villages/hamlets in the corridor
		private _nearLocs = nearestLocations [_midpoint, ["NameLocal", "NameVillage"], _searchRadius];

		{
			private _locPos = getPos _x;
			private _locName = text _x;

			// Skip if inside any existing AO radius (already has civs from generateCivilians)
			private _insideAO = false;
			{
				if (_locPos distance2D _x < (_aoSizes select _forEachIndex)) exitWith { _insideAO = true };
			} forEach _aoPositions;

			// Skip duplicates (same village found in multiple corridors)
			if (!_insideAO && !(_locName in _usedLocationNames)) then {
				_corridorLocations pushBack _x;
				_usedLocationNames pushBack _locName;
				diag_log format ["DRO: Corridor location found: %1 (%2) at %3", _locName, type _x, _locPos];
			};
		} forEach _nearLocs;
	};
};

// Cap at 5 corridor locations to avoid performance hit
if (count _corridorLocations > 5) then {
	_corridorLocations resize 5;
};

if (count _corridorLocations == 0) exitWith {
	diag_log "DRO: No corridor locations found between AOs";
};

diag_log format ["DRO: Found %1 corridor locations for civilian presence", count _corridorLocations];

// --- Phase 2: Spawn civilian presence at each corridor location ---
// IMPORTANT: reuse centerSide from generateCivilians.sqf (already created via createCenter sideLogic)
// Do NOT call createCenter sideLogic again — minimise sideLogic entity count for Zeus compatibility

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

	// --- Gather spawn positions: roads + buildings ---
	private _spawnPositions = [];

	// Roads nearby
	private _roads = _locPos nearRoads _areaSize;
	{
		if (count _spawnPositions >= 8) exitWith {};
		private _rPos = getPos _x;
		private _tooClose = false;
		{ if (_rPos distance2D _x < 30) exitWith { _tooClose = true } } forEach _spawnPositions;
		if (!_tooClose) then { _spawnPositions pushBack _rPos };
	} forEach _roads;

	// Buildings nearby
	private _buildings = _locPos nearObjects ["House", _areaSize];
	{
		if (count _spawnPositions >= 10) exitWith {};
		private _bPos = getPos _x;
		private _tooClose = false;
		{ if (_bPos distance2D _x < 30) exitWith { _tooClose = true } } forEach _spawnPositions;
		if (!_tooClose) then { _spawnPositions pushBack _bPos };
	} forEach _buildings;

	// Fallback: at least the location center
	if (count _spawnPositions == 0) then {
		_spawnPositions pushBack _locPos;
	};

	// Create spawn point modules — LIMIT to min(_unitCount, posCount) to avoid Zeus entity flood
	private _spawnCount = _unitCount min (count _spawnPositions);
	for "_i" from 0 to (_spawnCount - 1) do {
		(createGroup centerSide) createUnit ["ModuleCivilianPresenceUnit_F", (_spawnPositions select _i), [], 0, "FORM"];
	};

	// Create safe spots at buildings so civs have places to hang out (max 4)
	{
		if (_forEachIndex >= 4) exitWith {};
		private _ssUnit = (createGroup centerSide) createUnit ["ModuleCivilianPresenceSafeSpot_F", (getPos _x), [], 0, "FORM"];
		{
			_ssUnit setVariable [(_x select 0), (_x select 1), true];
		} forEach [
			["#useBuilding", true],
			["#type", 1],
			["#terminal", false],
			["#capacity", 2],
			["objectarea", [0.1, 0.1, 0, false, -1]]
		];
	} forEach _buildings;

	// Create the civilian presence controller
	private _modCivs = (createGroup centerSide) createUnit ["ModuleCivilianPresence_F", _locPos, [], 0, "FORM"];
	_modCivs setVariable ["#unitCount", _unitCount, true];
	_modCivs setVariable ["objectarea", [_areaSize, _areaSize, 0, false, -1], true];
	_modCivs setVariable ["#useAgents", _useAgents, true];
	_modCivs setVariable ["#usePanicMode", true, true];
	_modCivs setVariable ["#onCreated", {
		[_this] call DRO_fnc_civDeathHandler;
		diag_log format ["DRO: Corridor civilian spawned — isAgent=%1, typeOf=%2", (isNull (group _this)), typeOf _this];
	}, true];
	["init", [_modCivs]] call bis_fnc_moduleCivilianPresence;

	diag_log format ["DRO: Corridor civs at %1: %2 units, %3 spawn points, %4 safe spots, area %5m",
		_locName, _unitCount, _spawnCount, (count _buildings) min 4, _areaSize];

} forEach _corridorLocations;

diag_log format ["DRO: Corridor civilian generation complete — %1 locations populated", count _corridorLocations];
