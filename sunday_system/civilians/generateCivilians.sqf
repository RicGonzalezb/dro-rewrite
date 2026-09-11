// *****
// Civilians
// *****

private _AOIndex = _this select 0;
private _debug = 0;
patrolGroups = [];

// civiliansAsAgents: 0 = ENABLED (agents, melhor performance), 1 = DISABLED (units completas)
private _useAgents = (civiliansAsAgents == 0);
diag_log format ["DRO: Civilians as Agents = %1", _useAgents];

// M7 fix: hostis SOMENTE com civiliansEnabled == 2 (enabled & hostile)
// civiliansEnabled == 1 (enabled) → sem hostis
hostileCivsEnabled = (civiliansEnabled == 2);
publicVariable "hostileCivsEnabled";

if (hostileCivsEnabled) then {
	//A3
	_hwearables = [
		["H_Bandanna_blu","H_Bandanna_gry","H_Beret_blk","H_ShemagOpen_khk","H_Bandanna_surfer_blk"],
		["H_Bandanna_camo","H_Bandanna_sgg","H_Hat_Safari_sand_F","H_Shemag_olive","H_Bandanna_surfer_grn"],
		["H_Bandanna_cbr","H_Bandanna_khk","H_Bandanna_sand","H_ShemagOpen_tan","H_Booniehat_wdl"]
	];
	DRO_C_HWearables = selectRandom _hwearables;
	_vwearables = [
		["V_BandollierB_blk","V_BandollierB_cbr","V_LegStrapBag_black_F","V_TacChestrig_oli_F","V_Pocketed_black_F"],
		["V_BandollierB_oli","V_BandollierB_rgr","V_LegStrapBag_olive_F","V_TacChestrig_grn_F","V_Pocketed_olive_F"],
		["V_HarnessO_brn","V_BandollierB_khk","V_LegStrapBag_coyote_F","V_TacChestrig_cbr_F","V_Pocketed_coyote_F"]
	];	
	DRO_C_VWearables = selectRandom _vwearables;
	
	//IFA3 partizans
	if ((configfile >> "CfgMods" >> "IF") call BIS_fnc_getCfgIsClass) then {
		_hwearablesIFA3 = [
			["H_LIB_CIV_Villager_Cap_1","H_LIB_CIV_Villager_Cap_2","H_LIB_CIV_Villager_Cap_3","H_LIB_CIV_Villager_Cap_4","H_HeadBandage_clean_F","H_HeadBandage_stained_F","H_Hat_checker"],
			["H_LIB_CIV_Worker_Cap_1","H_LIB_CIV_Worker_Cap_2","H_LIB_CIV_Worker_Cap_3","H_Hat_grey","H_HeadBandage_clean_F","H_HeadBandage_stained_F","H_LIB_GER_Cap"],
			["H_Hat_Safari_sand_F","H_StrawHat","H_StrawHat_dark","H_Hat_brown","H_Hat_tan","H_HeadBandage_clean_F","H_HeadBandage_stained_F","H_LIB_SOV_RA_PrivateCap"]
		];
		DRO_C_HWearables = selectRandom _hwearablesIFA3;
		_vwearablesIFA3 = [];
		if ("H_Hat_checker" in DRO_C_HWearables) then {
			_vwearablesIFA3 append ["V_Pocketed_coyote_F","V_Pocketed_olive_F","V_Pocketed_black_F"];
		};
		if ("H_LIB_GER_Cap" in DRO_C_HWearables) then {
			_vwearablesIFA3 append ["V_LIB_GER_SniperBelt","V_Pocketed_olive_F"];
		};
		if ("H_LIB_SOV_RA_PrivateCap" in DRO_C_HWearables) then {
			_vwearablesIFA3 append ["V_LIB_SOV_RA_SniperVest","V_Pocketed_coyote_F"];
		};
		DRO_C_VWearables = _vwearablesIFA3;
	};
	
	//SPE maquis
	if ((configfile >> "CfgMods" >> "SPE") call BIS_fnc_getCfgIsClass) then {
		_hwearablesSPE = [
			["H_SPE_CIV_Fedora_Cap_3","H_SPE_CIV_Fedora_Cap_4","H_SPE_CIV_Fedora_Cap_2","H_LIB_CIV_Villager_Cap_4","H_HeadBandage_clean_F","H_StrawHat"],
			["H_SPE_CIV_Worker_Cap_2","H_SPE_CIV_Worker_Cap_3","H_SPE_CIV_Fedora_Cap_1","H_Hat_grey","H_HeadBandage_clean_F","H_HeadBandage_stained_F","H_SPE_CIV_Fedora_Cap_5"],
			["H_StrawHat_dark","H_HeadBandage_bloody_F","H_HeadBandage_stained_F","H_Hat_brown","H_SPE_CIV_Worker_Cap_1","H_SPE_CIV_Fedora_Cap_6"]
		];
		DRO_C_HWearables = selectRandom _hwearablesSPE;
		_vwearablesSPE = [];
		if ("H_StrawHat" in DRO_C_HWearables) then {
			_vwearablesSPE append ["V_SPE_FFI_Vest_SMG","V_SPE_FFI_Vest_rifle_pouch","V_SPE_FFI_Vest_rifle_frag"];
		};
		if ("H_SPE_CIV_Fedora_Cap_5" in DRO_C_HWearables) then {
			_vwearablesSPE append ["V_SPE_FFI_Vest_Pouch","V_SPE_FFI_Vest_SMG_pouch","V_SPE_FFI_Vest_SMG_frag"];
		};
		if ("H_SPE_CIV_Fedora_Cap_6" in DRO_C_HWearables) then {
			_vwearablesSPE append ["V_SPE_FFI_Vest_rifle","V_SPE_FFI_Vest_Pouch_frag","V_SPE_GER_PistolBelt"];
		};
		DRO_C_VWearables = _vwearablesSPE;
	};
	
	//VN VC
	if ((configfile >> "CfgMods" >> "vn") call BIS_fnc_getCfgIsClass) then {
		_hwearablesVN = [
			["vn_c_headband_02","H_HeadBandage_bloody_F","H_HeadBandage_stained_F"],
			["vn_c_conehat_01","vn_c_headband_03","H_HeadBandage_clean_F"],
			["vn_c_conehat_02","vn_b_headband_03","vn_c_headband_01","vn_c_headband_04"]
		];
		DRO_C_HWearables = selectRandom _hwearablesVN;
		_vwearablesVN = ["vn_o_vest_04","vn_o_vest_05"];
		DRO_C_VWearables = _vwearablesVN;
	};
	
	diag_log DRO_C_HWearables;
	publicVariable "DRO_C_HWearables";
	diag_log DRO_C_VWearables;
	publicVariable "DRO_C_VWearables";
		
	hostileCivIntel = "Some of the civilian militia may be wearing similar clothing. Check and ID your targets visually.";	
	publicVariable "hostileCivIntel";
};

_createHostileCivUnit = {
	params ["_pos", ["_patrol", false], ["_customWaypoints", []], ["_allowGroup", false]];
	_civType = selectRandom _customClasses;
	_group = createGroup civilian;
	_unit = _group createUnit [_civType, _pos, [], 0, "NONE"];	
	[_unit, _customClasses] execVM "sunday_system\civilians\hostileCivilians.sqf";
	
	if (_patrol) then {patrolGroups pushBack _group} else {
		if (count _customWaypoints > 0) then {
			{
				_wp = _group addWaypoint [_x, 15];
				if ((count _customWaypoints) > 1) then {
					if (_forEachIndex == ((count _customWaypoints)-1)) then {
						_wp setWaypointType "CYCLE";
					} else {
						_wp setWaypointType "MOVE";
					};
				} else {
					_wp setWaypointType "MOVE";
				};
				_wp setWaypointBehaviour "SAFE";
				_wp setWaypointSpeed "LIMITED";
				_wp setWaypointCompletionRadius 1.5;
				_wp setWaypointTimeout [15, 30, 40];
			} forEach _customWaypoints;
		};
	};
	
	// M8: civs ALWAYS get dynamic simulation regardless of user toggle
	_group enableDynamicSimulation true;
	_group;
};

_createSafeSpot = {
	params ["_pos", ["_useBuilding", true], ["_type", 1], ["_capacity", 1]];
	_modCivsSafeSpot = (createGroup centerSide) createUnit ["ModuleCivilianPresenceSafeSpot_F", _pos, [], 0, "FORM"];
	{
		_modCivsSafeSpot setVariable [(_x select 0),(_x select 1),true];
	} forEach [
		["#useBuilding", _useBuilding],
		["#type", _type],
		["#terminal", false],
		["#capacity", _capacity],  // M7 fix: usa parâmetro (antes hardcoded 3)
		["objectarea", [0.1,0.1,0,false,-1]]
	];
};

private _AOPos = ((AOLocations select _AOIndex) select 0);
private _AOSize = ((AOLocations select _AOIndex) select 1);
centerSide = createCenter sideLogic;
private _totalSpawnPoints = 0;
// Every position that feeds a civilian spawn, collected as it is created. In AGENTS
// mode we spawn from this list directly instead of going through the BIS module -
// see the branch at the bottom of this file for why.
private _civSpawnPositions = [];

// Spawn-point and safe-spot entities feed ModuleCivilianPresence_F only. Agents mode
// bypasses that module entirely, so creating them there is pure sideLogic bloat.
if (!_useAgents) then {
	(createGroup centerSide) createUnit ["ModuleCivilianPresenceUnit_F", _AOPos, [], 0, "FORM"];
};
_totalSpawnPoints = _totalSpawnPoints + 1;
_civSpawnPositions pushBack _AOPos;

private _customClasses = civClasses;
if (civFaction == "CIV_F") then {
	_locText = text ((AOLocations select _AOIndex) select 5);	
	switch (_locText) do {
		case "dump": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Black_F", "C_Man_UtilityWorker_01_F"]};
		case "quarry": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Red_F", "C_Man_UtilityWorker_01_F"]};
		case "factory": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Blue_F", "C_Man_UtilityWorker_01_F"]};
		case "military": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Black_F", "C_Man_ConstructionWorker_01_Blue_F", "C_Man_ConstructionWorker_01_Red_F", "C_Man_ConstructionWorker_01_Vrana_F"]};
		case "training base": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Black_F", "C_Man_ConstructionWorker_01_Blue_F", "C_Man_ConstructionWorker_01_Red_F", "C_Man_ConstructionWorker_01_Vrana_F"]};
		case "power plant": {_customClasses = ["C_man_w_worker_F", "C_Man_UtilityWorker_01_F", "C_Man_ConstructionWorker_01_Black_F", "C_Man_ConstructionWorker_01_Blue_F", "C_Man_ConstructionWorker_01_Red_F", "C_Man_ConstructionWorker_01_Vrana_F"]};
		case "storage": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Blue_F", "C_Man_UtilityWorker_01_F"]};
		case "farm": {_customClasses = ["C_man_w_worker_F", "C_Farmer_01_enoch_F", "C_man_hunter_1_F", "C_Man_Fisherman_01_F"]};
		case "ind.": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Black_F", "C_Man_ConstructionWorker_01_Blue_F", "C_Man_ConstructionWorker_01_Red_F", "C_Man_ConstructionWorker_01_Vrana_F"]};
		case "lumberyard": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Blue_F", "C_man_hunter_1_F"]};		
		case "sawmill": {_customClasses = ["C_man_w_worker_F", "C_Man_ConstructionWorker_01_Red_F", "C_man_hunter_1_F"]};
		default {_customClasses = civClasses};
	};
};
diag_log format ["DRO: %2 Civilian custom classes = %1", _customClasses, text ((AOLocations select _AOIndex) select 5)];

// Extract civ identities and wearables
private _keyClass = (_customClasses select 0);
// Identities

private _identities = [_keyClass, civilian] call DRO_fnc_extractIdentities;
_C_firstNames = (_identities select 0);
_C_lastNames = (_identities select 1);
_C_speakers = (_identities select 2);
_C_faces = (_identities select 3);

// Uniform
// A class with no uniformClass entry makes getCfgData return nil, and pushBackUnique nil
// throws. Every stock civilian class has one, so this never fired in practice, but a
// modded class pool is exactly where it would.
_C_uniformList = [];
{
	private _uniformClass = ([(configFile >> "CfgVehicles" >> _x >> "uniformClass")] call BIS_fnc_getCfgData);
	if (!isNil "_uniformClass" && {_uniformClass isEqualType ""} && {_uniformClass != ""}) then {
		_C_uniformList pushBackUnique _uniformClass;
	};
} forEach _customClasses;

// Headgear
// Fix: the guard used to test `isNil "_headgearList"` - a variable that exists nowhere in
// this file - so it was always true and _C_headgearList was always [] (no civilian ever
// got headgear). Its else branch read DRO_C_headgearList, another never-declared global.
// Second fix: CfgVehicles >> headgearList is a WEIGHTED array, e.g.
//   headgearList[] = {"H_Cap_press", 0.4, "", 0.6};
// class names and their probabilities interleaved, with "" meaning "bare head". Feeding
// that straight to selectRandom would hand addHeadgear a number or an empty string, so
// keep only the non-empty string entries. The 0.6 chance roll at the spawn site already
// covers the "no headgear" case the "" entries encode.
private _headgearRaw = ([(configFile >> "CfgVehicles" >> _keyClass >> "headgearList")] call BIS_fnc_getCfgData);
_C_headgearList = [];
if (!isNil "_headgearRaw" && {_headgearRaw isEqualType []}) then {
	{
		if (_x isEqualType "" && {_x != ""}) then { _C_headgearList pushBackUnique _x };
	} forEach _headgearRaw;
};

// Vest
_C_vestList = [];
private _thisLinked = ([(configFile >> "CfgVehicles" >> _keyClass >> "linkedItems")] call BIS_fnc_getCfgData); //{"H_Cap_press","V_Press_F","ItemMap","ItemCompass","ItemWatch"};
// Fix: this loop used to push into DRO_C_vestList - a global that is never declared
// anywhere in the project - while the list actually consumed below is _C_vestList.
// Net effect: _C_vestList stayed empty forever (no civilian ever got a vest) and the
// pushBack on the undeclared global threw on every linked vest. Writes to _C_vestList
// now. Also type-guards _thisLinked: getCfgData returns whatever the config holds, and
// forEach over a non-array errors.
if (!isNil "_thisLinked" && {_thisLinked isEqualType []}) then {
	{
		if (_x isKindOf ["Vest_Camo_Base", configFile >> "CfgWeapons"]) then {_C_vestList pushBackUnique _x};
		if (_x isKindOf ["Vest_NoCamo_Base", configFile >> "CfgWeapons"]) then {_C_vestList pushBackUnique _x};
	} forEach _thisLinked;
};

private _filteredHouses = (((AOLocations select _AOIndex) select 2) select 7);
private _numHouses = count _filteredHouses;
private _percentToFill = 0.3;
if (_numHouses < 9) then {_percentToFill = 0.5};
_numHousesToFill = _numHouses * _percentToFill;
if (_numHousesToFill > 10) then {_numHousesToFill = 10};
// M8: agents can't navigate building interiors — skip building spawn points/safe spots when agents enabled
if (!_useAgents) then {
for "_i" from 1 to _numHousesToFill do {
	private _thisHouse = [_filteredHouses] call DRO_fnc_selectRemove;
	if (isNull _thisHouse) then { continue };
	(createGroup centerSide) createUnit ["ModuleCivilianPresenceUnit_F", (getPos _thisHouse), [], 0, "FORM"];
	_totalSpawnPoints = _totalSpawnPoints + 1;
	private _buildingPositions = [_thisHouse] call BIS_fnc_buildingPositions;
	// M7 fix: max 1 civ hostil por posição de building (antes spawnava até 3 no mesmo ponto)
	{
		if (random 1 > 0.5) then {
			[_x, false, [], false] call _createHostileCivUnit;
		};
	} forEach _buildingPositions;
	[(getPos _thisHouse), true, 1] call _createSafeSpot;
	if (_debug == 1) then {
		_garMarker = createMarker [format["garMkr%1", random 10000], getPos _thisHouse];
		_garMarker setMarkerShape "ICON";
		_garMarker setMarkerColor "ColorGreen";
		_garMarker setMarkerType "mil_dot";
		_garMarker setMarkerText format ["Civ %1", (typeOf  _thisHouse)];
	};
}; // end for _i (building loop)
}; // end if (!_useAgents) — agents skip building interiors entirely

_civPositions = (((AOLocations select _AOIndex) select 2) select 0) + (((AOLocations select _AOIndex) select 2) select 2) + (((AOLocations select _AOIndex) select 2) select 4);

_minAI = 3;
_maxAI = 6;

if (((AOLocations select _AOIndex) select 4) == 1) then {
	_minAI = round (_minAI * 1.5);
	_maxAI = round (_minAI * 1.5);
};

diag_log format ["DRO: Generating civilian positions at AO %1", (name ((AOLocations select _AOIndex) select 5))];

// M7 fix: embaralhar e filtrar posições para evitar aglomeração
private _shuffledCivPositions = +_civPositions;
if (count _shuffledCivPositions > 0) then {
	_shuffledCivPositions call BIS_fnc_arrayShuffle;
};
// Filtrar posições muito próximas — mínimo 30m entre cada spawn point
private _filteredCivPositions = [];
{
	private _pos = _x;
	private _tooClose = false;
	{
		if (_pos distance2D _x < 30) exitWith { _tooClose = true };
	} forEach _filteredCivPositions;
	if (!_tooClose) then { _filteredCivPositions pushBack _pos };
} forEach _shuffledCivPositions;
if (count _filteredCivPositions == 0 && {count _shuffledCivPositions > 0}) then {
	_filteredCivPositions = _shuffledCivPositions; // fallback: usar sem filtro
};
private _posCount = count _filteredCivPositions;
diag_log format ["DRO: civPositions raw=%1, filtered=%2", count _shuffledCivPositions, _posCount];

private _spawnCount = 0;
if (_posCount == 0) then {
	diag_log "DRO: WARNING — _civPositions empty, skipping open-area civ spawn";
};
if (_posCount > 0) then {

// M8: determine _numCivs by location type
private _numCivs = 0;
switch (type ((AOLocations select _AOIndex) select 5)) do {
	case "NameVillage": { _numCivs = [_minAI, _maxAI] call BIS_fnc_randomInt; };
	case "NameCity": { _numCivs = [_minAI + 2, _maxAI + 2] call BIS_fnc_randomInt; };
	case "NameCityCapital": { _numCivs = [_minAI + 3, _maxAI + 3] call BIS_fnc_randomInt; };
	case "NameLocal": { _numCivs = [_minAI, _maxAI] call BIS_fnc_randomInt; };
};

diag_log format ["DRO: Civilian spawn — type=%1, minAI=%2, maxAI=%3, numCivs=%4, spawnCount=%5, filteredPositions=%6",
	type ((AOLocations select _AOIndex) select 5), _minAI, _maxAI, _numCivs, _spawnCount, _posCount];

// M8 fix: create spawn points for min(_numCivs, _posCount) UNIQUE positions only
// Prevents duplicates (old bug) without flooding sideLogic with 60+ entities (new bug)
_spawnCount = _numCivs min _posCount;
for "_x" from 0 to (_spawnCount - 1) do {
	private _civPosition = _filteredCivPositions select _x;
	if (!_useAgents) then {
		(createGroup centerSide) createUnit ["ModuleCivilianPresenceUnit_F", _civPosition, [], 0, "FORM"];
		[_civPosition, true, 2] call _createSafeSpot;
	};
	_totalSpawnPoints = _totalSpawnPoints + 1;
	_civSpawnPositions pushBack _civPosition;
};

// Spawn hostile civs if enabled
if (hostileCivsEnabled) then {
	private _hostileCount = floor (_numCivs * 0.4);
	for "_x" from 1 to _hostileCount do {
		private _civPosition = _filteredCivPositions select ((_x - 1) mod _spawnCount);
		[_civPosition, true, [], true] call _createHostileCivUnit;
	};
};

}; // end if (_posCount > 0)

// Create market bustle
private _continue = if (isNil "marketPositionsUsed") then {true} else {if (marketPositionsUsed) then {false}};
if (_continue && !isNil "marketPositions") then {
	marketPositionsUsed = true;
	if (count marketPositions > 0) then {
		{			
			private _thisMarketPositions = _x;
			
			diag_log (format ["DRO: _thisMarketPositions = %1", _thisMarketPositions]);
			_count = 0;
			{	
				if (hostileCivsEnabled) then {
					if (_count < 3) then {
						[_x, true, _thisMarketPositions, true] call _createHostileCivUnit;
						_count = _count + 1;
					};
				};
				if (_forEachIndex % 2 == 0) then {
					if (!_useAgents) then {
						(createGroup centerSide) createUnit ["ModuleCivilianPresenceUnit_F", _x, [], 0, "FORM"];
						[_x, true, 2] call _createSafeSpot;
					};
					_totalSpawnPoints = _totalSpawnPoints + 1;
					_civSpawnPositions pushBack (if (_x isEqualType objNull) then { getPos _x } else { _x });
				};		
			} forEach _thisMarketPositions;
		} forEach marketPositions;
	};
};	

// Spawn civilian vehicles
if (count civCarClasses > 0) then {
	// M8: always spawn civ vehicles (removed 50% chance gate)
	_numCivVehicles = [1,3] call BIS_fnc_randomInt;
	for "_i" from 1 to _numCivVehicles do {
		if (count (((AOLocations select _AOIndex) select 2) select 0) > 0) then {
			_pos = [(((AOLocations select _AOIndex) select 2) select 0)] call DRO_fnc_selectRemove;
			_class = (selectRandom civCarClasses);
			_pos = _pos findEmptyPosition [0, 20, _class];
			if (count _pos > 0) then {
				_veh = createVehicle [_class, _pos, [], 0, "NONE"];
				_roadList = _pos nearRoads 10;
				if (count _roadList > 0) then {
					_thisRoad = _roadList select 0;
					_direction = [_thisRoad] call DRO_fnc_getRoadDir;
					_veh setDir _direction;
					_newPos = [_pos, 4, (_direction + 90)] call BIS_fnc_relPos;
					if (!(_newPos isFlatEmpty [5, -1, -1, -1, 0, false] isEqualTo [])) then {
						_veh setPos _newPos;
					};
				};
				if (random 1 > 0.75) then {
					createVehicleCrew _veh;
					waitUntil {!isNull (driver _veh)};
					// M8: all crewed civ vehicles patrol (removed 50% chance)
					patrolGroups pushBack (group driver _veh);
					{
						[_x] call DRO_fnc_civDeathHandler;
					} forEach units (group driver _veh);
				};
			};
		};
	};
};

// ---------------------------------------------------------------------------------
// Civilian spawning splits on _useAgents.
//
// UNITS MODE  -> ModuleCivilianPresence_F, exactly as before. The module works fine
//                here: it owns the units it creates, so panic mode (#usePanicMode),
//                the safe spots and the end-of-AO cleanup all reach them.
//
// AGENTS MODE -> the module is bypassed entirely and agents are created directly from
//                _civSpawnPositions, the same way generateCorridorCivilians.sqf already
//                does it. This replaces the old "#onCreated deletes the unit and makes
//                an agent in its place" hack, which was broken in four ways:
//                  1. the identity (name/face/speaker) was applied to the unit that was
//                     deleted one line later, so every converted agent was nameless;
//                  2. deleteVehicle fired inside the module's own creation routine while
//                     the module still held the reference, leaving null entries in its
//                     registry and making it top the unit count back up;
//                  3. the replacement agent was never registered, so panic mode, the
//                     safe spots and the end-of-AO cleanup never saw it;
//                  4. deleting the last unit of a group left an empty group behind -
//                     one of the reasons fn_orphanSweep.sqf exists.
//                Nothing is lost by bypassing: a converted agent already sat outside the
//                module, so panic mode and safe spots were already dead in this mode.
// ---------------------------------------------------------------------------------
if (_useAgents) then {

	private _agentsSpawned = 0;
	{
		private _spawnPos = _x;
		// Guard the pool: selectRandom on an empty array returns nil and undefines the
		// variable, which is how this codebase has been bitten before.
		if (count _customClasses > 0) then {
			private _civType = selectRandom _customClasses;
			private _agent = createAgent [_civType, _spawnPos, [], 5, "NONE"];
			_agent setBehaviour "CARELESS";
			// Civs ALWAYS get dynamic simulation, regardless of the user toggle.
			_agent enableDynamicSimulation true;

			removeAllItems _agent;
			removeVest _agent;
			removeHeadgear _agent;
			removeUniform _agent;

			if (!isNil "_C_uniformList" && {count _C_uniformList > 0}) then {
				private _uniform = selectRandom _C_uniformList;
				if (_uniform isEqualType "" && {_uniform != ""}) then { _agent addUniform _uniform };
			};
			if (!isNil "_C_headgearList" && {count _C_headgearList > 0} && {random 1 > 0.6}) then {
				private _headgear = selectRandom _C_headgearList;
				if (_headgear isEqualType "" && {_headgear != ""}) then { _agent addHeadgear _headgear };
			};
			if (!isNil "_C_vestList" && {count _C_vestList > 0} && {random 1 > 0.3}) then {
				private _vest = selectRandom _C_vestList;
				if (_vest isEqualType "" && {_vest != ""}) then { _agent addVest _vest };
			};

			// Identity goes on the AGENT - this is the bug the old conversion had, where the
			// name was set on the unit that was about to be deleted.
			if (count _C_firstNames > 0
				&& {count _C_lastNames > 0}
				&& {count _C_speakers > 0}
				&& {count _C_faces > 0}) then {
				[_agent, selectRandom _C_firstNames, selectRandom _C_lastNames, selectRandom _C_speakers, selectRandom _C_faces] remoteExec ["DRO_fnc_setNameMP", 0];
			};

			[_agent] call DRO_fnc_civDeathHandler;
			_agentsSpawned = _agentsSpawned + 1;
		};
	} forEach _civSpawnPositions;

	diag_log format ["DRO: Civilians spawned as agents (module bypassed) - %1 agent(s) from %2 spawn point(s)", _agentsSpawned, count _civSpawnPositions];

} else {

	private _modCivs = (createGroup centerSide) createUnit ["ModuleCivilianPresence_F", _AOPos, [], 0, "FORM"];
	// M8 fix: unitCount = total spawn points criados - 1 civ por ponto, sem clustering
	_modCivs setVariable ["#unitCount", (_totalSpawnPoints max 1), true];
	// M7 fix: area aumentada de AOSize/2 para AOSize*0.75 - civis se espalham mais
	_modCivs setVariable ["objectarea", [(_AOSize * 0.75), (_AOSize * 0.75), 0, false, -1], true];
	diag_log format ["DRO: ModuleCivilianPresence_F init - useAgents=%1, unitCount=%2, totalSpawnPoints=%3", _useAgents, _totalSpawnPoints, _totalSpawnPoints];
	_modCivs setVariable ["#useAgents", false, true];
	_modCivs setVariable ["#usePanicMode", true, true];
	_modCivs setVariable ["DRO_uniformList", _C_uniformList];
	_modCivs setVariable ["DRO_firstNames", _C_firstNames];
	_modCivs setVariable ["DRO_lastNames", _C_lastNames];
	_modCivs setVariable ["DRO_speakers", _C_speakers];
	_modCivs setVariable ["DRO_faces", _C_faces];
	_modCivs setVariable ["DRO_headgearList", _C_headgearList];
	_modCivs setVariable ["DRO_vestList", _C_vestList];
	_modCivs setVariable ["#onCreated", {
		removeAllItems _this;
		removeVest _this;
		removeHeadgear _this;
		removeUniform _this;
		private _module = (_this getVariable "#core");
		[_this, (selectRandom (_module getVariable "DRO_firstNames")), (selectRandom (_module getVariable "DRO_lastNames")), (selectRandom (_module getVariable "DRO_speakers")), (selectRandom (_module getVariable "DRO_faces"))] remoteExec ["DRO_fnc_setNameMP", 0];
		private _uniformList = _module getVariable ["DRO_uniformList", []];
		if (count _uniformList > 0) then { _this addUniform (selectRandom _uniformList) };
		private _headgearList = _module getVariable ["DRO_headgearList", []];
		if (count _headgearList > 0 && {random 1 > 0.6}) then { _this addHeadgear (selectRandom _headgearList) };
		private _vestList = _module getVariable ["DRO_vestList", []];
		if (count _vestList > 0 && {random 1 > 0.3}) then { _this addVest (selectRandom _vestList) };
		[_this] call DRO_fnc_civDeathHandler;
		// M8: civs ALWAYS get dynamic simulation (performance savings regardless of user toggle)
		_this enableDynamicSimulation true;
	}, true];
	["init", [_modCivs]] call bis_fnc_moduleCivilianPresence;

};

// Initialise waypoints
// Drop groups emptied between spawn and here (see fn_untrackEntity.sqf): an empty
// group is not grpNull, and `getPos (leader _thisGroup)` on one yields [0,0,0],
// planting waypoints at map origin and leaving a replicating ghost group.
patrolGroups = [patrolGroups] call DRO_fnc_livingEntities;
if (count patrolGroups > 0) then {
	private _travelPositions = (((AOLocations select _AOIndex) select 2) select 0) + (((AOLocations select _AOIndex) select 2) select 2) + (((AOLocations select _AOIndex) select 2) select 4);		
	if (count _travelPositions > 0) then {		
		{				
			_thisGroup = _x;
			_availableTravelPositions = [];
			_randI = ([0, (count _travelPositions)-1] call BIS_fnc_randomInt);			
			for "_i" from _randI to ((_randI + ([2,3] call BIS_fnc_randomInt)) min (count _travelPositions)) step 1 do {
				_availableTravelPositions pushBack (_travelPositions select _i);
			};
			
			_startPos = (getPos (leader _thisGroup));						
			// Initialise route waypoints
			_wpFirst = _thisGroup addWaypoint [_startPos, 20];
			_wpFirst setWaypointType "MOVE";
			_wpFirst setWaypointBehaviour "SAFE";
			_wpFirst setWaypointSpeed "LIMITED";			
			{
				_pos = if (typeName _x == "OBJECT") then {getPos _x} else {_x};
				_wp = _thisGroup addWaypoint [_pos, 20];
				_wp setWaypointType "MOVE";
				_wp setWaypointCompletionRadius 20;
				_wp setWaypointTimeout [60, 90, 120];					
			} forEach _availableTravelPositions;
			_wpLast = _thisGroup addWaypoint [_startPos, 20];
			_wpLast setWaypointType "CYCLE";		
			_wpLast setWaypointCompletionRadius 20;
			_wpLast setWaypointTimeout [60, 90, 120];			
		} forEach patrolGroups;
	};	
};
/*
{
	if (!((teamType _x) in civClasses)) then {
		deleteTeam _x;
	};
} forEach agents;
*/
