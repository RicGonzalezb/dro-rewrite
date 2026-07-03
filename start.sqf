diag_log "DRO: Main DRO script started";

// Mod detection fallback — start.sqf is launched from initServer.sqf, which can run before
// init.sqf on the server, so the DRO_ace*/DRO_lambs* globals may not exist yet here.
// Idempotent with init.sqf (same machine-local config reads); guarded so it won't re-run.
if (isNil "DRO_aceMedical") then {
	DRO_aceLoaded  = isClass (configFile >> "CfgPatches" >> "ace_main");
	DRO_aceMedical = isClass (configFile >> "CfgPatches" >> "ace_medical");
	DRO_aceArsenal = isClass (configFile >> "CfgPatches" >> "ace_arsenal");
	DRO_aceFatigue = isClass (configFile >> "CfgPatches" >> "ace_advanced_fatigue");
};
if (isNil "DRO_lambsCompat") then {
	DRO_lambsLoaded = isClass (configFile >> "CfgPatches" >> "lambs_main");
	DRO_lambsWP     = isClass (configFile >> "CfgPatches" >> "lambs_wp");
	DRO_lambsCompat = DRO_lambsLoaded && ((["DRO_ParamLambsReinforce", 1] call BIS_fnc_getParamValue) == 1);
};

// [M3 removed] #include "sunday_system\fnc_lib\sundayFunctions.sqf";
// [M3 removed] #include "sunday_system\fnc_lib\droFunctions.sqf";
// [M3 removed] #include "sunday_revive\reviveFunctions.sqf";
// [M3 removed] #include "sunday_system\generate_enemies\generateEnemiesFunctions.sqf";

[] execVM "sunday_system\fnc_lib\objectsLibrary.sqf";

diag_log "DRO: Libraries included";

respawnTime = switch (["Respawn", 0] call BIS_fnc_getParamValue) do {
	case 0: {20};
	case 1: {45};
	case 2: {90};
	case 3: {300};
	case 4: {600};
	case 5: {1200};
	case 6: {1800};
	case 7: {nil};
};
publicVariable "respawnTime";

diag_log "DRO: Waiting for player count";

waitUntil {(count ([] call BIS_fnc_listPlayers) > 0)};
_topUnit = (([] call BIS_fnc_listPlayers) select 0);

{
	[_x, false] remoteExec ["allowDamage", _x];
	[_x, "ALL"] remoteExec ["disableAI", _x];
} forEach units(group _topUnit);
topUnit = _topUnit;
publicVariable "topUnit";

diag_log format ["DRO: topUnit = %1", topUnit];

// M9: Em dedicated server, profileNamespace e do servidor (diferente do host).
// Se override ativo, le timeOfDay direto do param (mesmo resultado em todas as maquinas).
// Override OFF: comportamento original preservado (le do server profileNamespace).
private _DRO_m9_todParam = ["DRO_ParamOverride", 0] call BIS_fnc_getParamValue;
private _DRO_m9_toD = if (_DRO_m9_todParam == 1) then {
	["DRO_ParamTimeOfDay", 0] call BIS_fnc_getParamValue
} else {
	profileNamespace getVariable ["DRO_timeOfDay", 0]
};
[_DRO_m9_toD] call DRO_fnc_randomTime;

playersFaction = "";
enemyFaction = "";
civFaction = "";
pFactionIndex = 1;
publicVariable "pFactionIndex";
playersFactionAdv = [0,0,0];
publicVariable "playersFactionAdv";
eFactionIndex = 2;
publicVariable "eFactionIndex";
enemyFactionAdv = [0,0,0];
publicVariable "enemyFactionAdv";
cFactionIndex = 0;
publicVariable "cFactionIndex";
customPos = [];
publicVariable "customPos";
playerGroup = [];
civTrue = false;
startVehicles = ["", ""];
publicVariable "startVehicles";
firstLobbyOpen = true;
publicVariable "firstLobbyOpen";
enemyIntelMarkers = [];
publicVariable "enemyIntelMarkers";

extractLeave = false;
publicVariable "extractLeave";
extractHeliUsed = false;
reinforceChance = 0.5;
stealthActive = false;
enemyCommsActive = true;
hostileCivsEnabled = false; // M7 fix: será setado corretamente em generateCivilians.sqf baseado em civiliansEnabled

civDeathCounter = 0;
publicVariable "civDeathCounter";
hostileCivilians = [];
publicVariable "hostileCivilians";
neutralTasksChosen = false;
noNeutralTasksChosen = false;
taskCreationInProgress = false;
insertType = 0;
friendlySquad = nil;
reactiveChance = random 1;
holdAO = [];
droGroupIconsVisible = false;
publicVariable "droGroupIconsVisible";
dro_messageStack = [];
enemyPosCollection = [];

diag_log "DRO: Variables defined";

// M9 — Lobby Param Override: aplicar params do lobby sobre as vars de geracao.
// Roda APOS as inicializacoes de variaveis acima para que loadParams
// possa sobrescrever valores (ex: playersFaction, numObjectives).
// Com override OFF: sai no exitWith inicial e nao muda nada.
// Com override ON + UseFactions: seta playersFaction/enemyFaction +
//   factionsChosen=1, destravando o waitUntil na linha ~127.
[] call compile preprocessFileLineNumbers "loadParams.sqf";
diag_log "DRO M9: loadParams.sqf chamado de start.sqf";

diag_log "DRO: Compiling scripts";

// [M3 removed] DRO_fnc_generateAO = compile preprocessFile "sunday_system\generate_ao\generateAO.sqf";
// [M3 removed] DRO_fnc_generateAOLoc = compile preprocessFile "sunday_system\generate_ao\generateAOLocation.sqf";
// [M3 removed] DRO_fnc_generateCampsite = compile preprocessFile "sunday_system\generate_ao\generateCampsite.sqf";

// [M3 removed] DRO_fnc_selectObjective = compile preprocessFile "sunday_system\objectives\objSelect.sqf";
// [M3 removed] DRO_fnc_selectReactiveObjective = compile preprocessFile "sunday_system\objectives\selectReactiveTask.sqf";
// [M3 removed] DRO_fnc_defineFactionClasses = compile preprocessFile "sunday_system\fnc_lib\defineFactionClasses.sqf";

// [M3 removed] DRO_fnc_generateRoadblock = compile preprocessFile "sunday_system\generate_enemies\generateRoadblock.sqf";
// [M3 removed] DRO_fnc_generateBunker = compile preprocessFile "sunday_system\generate_enemies\generateBunker.sqf";
// [M3 removed] DRO_fnc_generateBarrier = compile preprocessFile "sunday_system\generate_enemies\generateBarrier.sqf";
// [M3 removed] DRO_fnc_generateEmplacement = compile preprocessFile "sunday_system\generate_enemies\generateEmplacement.sqf";
// [M3 removed] DRO_fnc_spawnEnemyCompound = compile preprocessFile "sunday_system\generate_enemies\generateCompound.sqf";

diag_log "DRO: Compiling scripts finished";

blackList = [];

_musicIntroStings = [
	"EventTrack02_F_EPB",
	"EventTrack02a_F_EPB",
	"EventTrack01a_F_EPA"
];
musicIntroSting = selectRandom _musicIntroStings;
publicVariable "musicIntroSting";

diag_log "DRO: Music sting chosen";

// --- Faction data extraction ---
call DRO_fnc_extractFactionData;

// Initialise potential AO markers
[] execVM "sunday_system\generate_ao\initAO.sqf";
diag_log "DRO: AO markers initialized";

// *****
// PLAYERS SETUP
// *****

diag_log "DRO: Waiting for factions to be chosen by host";
waitUntil {(missionNameSpace getVariable ["factionsChosen", 0]) == 1};
diag_log "DRO: Factions chosen";

// M8: Dynamic Simulation system stays ALWAYS ON.
// When dynamicSim == 1 (user disabled), enemies simply won't be marked —
// they stay always simulated. Civilians are ALWAYS marked for dynSim
// regardless of this toggle (performance savings on civs are always worth it).
// Civ vehicles excluded — they keep traveling the map even when far from players.

// M8: DynSim distances — increased from defaults (group 500, vehicle 350, emptyVehicle 250)
"Group" setDynamicSimulationDistance 1000;
"Vehicle" setDynamicSimulationDistance 2000;
"EmptyVehicle" setDynamicSimulationDistance 1000;

// Force Sunday Revive disabled if ACE3 has cardiac arrest time greater than zero
if ((["Respawn", 0] call BIS_fnc_getParamValue) != 7) then {
	if (DRO_aceMedical) then {
		if (!isNil "ace_medical_statemachine_cardiacArrestTime") then {
			if (ace_medical_statemachine_cardiacArrestTime > 0) then {
				reviveDisabled = 3;
				publicVariable "reviveDisabled";
			};
		};
	};
};

// Force A3 Stamina enabled if ACE3 Adv Fatigue enabled
if ((["Stamina", 0] call BIS_fnc_getParamValue) > 0) then {
	if (DRO_aceFatigue) then {
		if (!isNil "ace_advanced_fatigue_enabled") then {
			if (ace_advanced_fatigue_enabled) then {
				staminaDisabled = 0;
				publicVariable "staminaDisabled";
			} else {
				staminaDisabled = 1;
				publicVariable "staminaDisabled";
			};
		};
	};
};

// AI Weapon Light status
paramAIWeaponLight = ["AIWeaponLight", 1] call BIS_fnc_getParamValue;
switch (paramAIWeaponLight) do {
	case 0: { missionAIWeaponLight = "Auto"; publicVariable "missionAIWeaponLight"; };
	case 1: { missionAIWeaponLight = "ForceOn"; publicVariable "missionAIWeaponLight"; };
	case 2: { missionAIWeaponLight = "ForceOFF"; publicVariable "missionAIWeaponLight"; };
};

// Get player faction
playersFactionName = (configFile >> "CfgFactionClasses" >> playersFaction >> "displayName") call BIS_fnc_GetCfgData;
_playerSideNum = (configFile >> "CfgFactionClasses" >> playersFaction >> "side") call BIS_fnc_GetCfgData;
playersSide = [_playerSideNum] call DRO_fnc_getCfgSide;
playersSideCfgGroups = "West";
switch (playersSide) do {
	case east: {		
		playersSideCfgGroups = "East";		
	};
	case west: {		
		playersSideCfgGroups = "West";		
	};
	case resistance: {		
		playersSideCfgGroups = "Indep";		
	};
	case civilian: {
		playersSide = civilian
	};
};
publicVariable "playersSide";
publicVariable "playersSideCfgGroups";
diag_log format ["DRO: playersSide = %1, playersFaction = %2", playersSide, playersFaction];

diag_log "DRO: Define player group";
playerGroup = units (group _topUnit);
DROgroupPlayers = group _topUnit;
groupLeader = leader DROgroupPlayers;
callsigns = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Lima", "Kilo", "Viper", "Scorpion", "Hunter"];
playerCallsign = [callsigns] call DRO_fnc_selectRemove; 
publicVariable "playerCallsign";

grpNetId = group _topUnit call BIS_fnc_netId;
publicVariable "grpNetId";
diag_log grpNetId;

publicVariable "playerGroup";
publicVariable "DROgroupPlayers";
publicVariable "groupLeader";

diag_log format ["DRO: grpNetId = %1", grpNetId];

// Keep group name assigned throughout setup process
/*
[] spawn {
	while {(missionNameSpace getVariable ["playersReady", 0] == 0)} do {	
		if (isNull (grpNetId call BIS_fnc_groupFromNetId)) then {
			grpNetId = (group(([] call BIS_fnc_listPlayers) select 0)) call BIS_fnc_netId;
			publicVariable "grpNetId";
		};
	};
};
*/
//unitDirs = [];
{
	if (!isNull _x) then {
		_x setVariable ["startDir", (getDir _x), true];
		//unitDirs set [_forEachIndex, (getDir _x)];
	};
	removeFromRemainsCollector [_x];
	diag_log format ["DRO: %1 startDir set and removed from remains collector", _x];
} forEach playerGroup;
//publicVariable "unitDirs";

// Prepare data for player lobby
_scriptStartTime = time;
[((findDisplay 888888) displayCtrl 8889), "EXTRACTING FACTION DATA"] remoteExecCall ["ctrlSetText", 0];
diag_log "DRO: Beginning faction extraction";
[] call DRO_fnc_defineFactionClasses;

DROgroupPlayers = (group _topUnit);

publicVariable "pCarClasses";
publicVariable "pTankClasses";
publicVariable "pHeliClasses";
publicVariable "pMortarClasses";
publicVariable "pUAVClasses";
publicVariable "pArtyClasses";

enemyGVPool = [];
if (count eCarNoTurretClasses > 0) then {	
	for "_gv" from 1 to ([2,3] call BIS_fnc_randomInt) step 1 do {
		enemyGVPool pushBack (selectRandom eCarNoTurretClasses);
	};	
};
enemyGVTPool = [];
if (count eCarTurretClasses > 0) then {
	enemyGVTPool pushBack (selectRandom eCarTurretClasses);	
};
enemyHeliPool = [];
if (count eHeliClasses > 0) then {	
	for "_h" from 1 to ([1,3] call BIS_fnc_randomInt) step 1 do {
		enemyHeliPool pushBack (selectRandom eHeliClasses);
	};	
};

// Get CAS options
availableCASClasses = [];
if (count pHeliClasses > 0 || count pPlaneClasses > 0) then {	
	{
		_availableSupportTypes = (configfile >> "CfgVehicles" >> _x >> "availableForSupportTypes") call BIS_fnc_GetCfgData;	
		if ("CAS_Bombing" in _availableSupportTypes) then {			
			availableCASClasses pushBack _x;
		};
		if ("CAS_Heli" in _availableSupportTypes) then {			
			availableCASClasses pushBack _x;
		};
	} forEach (pHeliClasses + pPlaneClasses);
};
publicVariable "availableCASClasses";

_pInfGroups = [];
_playersFaction = playersFaction;
if (playersFaction == "BLU_G_F") then {_playersFaction = "Guerilla"};
if (playersFaction == "BLU_GEN_F") then {_playersFaction = "Gendarmerie"};
{	
	_thisCategory = _x;
	{
		_thisGroup = _x;
		if (
			!(["diver", (configName _thisGroup)] call BIS_fnc_inString) &&
			!(["support", (configName _thisGroup)] call BIS_fnc_inString)
		) then {
			_save = true;
			{			
				_vehicle = ((_x >> "vehicle") call BIS_fnc_getCfgData);
				if !(_vehicle isKindOf "Man") then {_save = false};
			} forEach ([_thisGroup] call BIS_fnc_returnChildren);
			if (_save) then {_pInfGroups pushBack [_thisGroup, ((_thisGroup >> "name") call BIS_fnc_getCfgData)]};
		};
	} forEach ([_thisCategory] call BIS_fnc_returnChildren);
} forEach ([configfile >> "CfgGroups" >> playersSideCfgGroups >> _playersFaction] call BIS_fnc_returnChildren);
//diag_log format ["DRO: _pInfGroups: %1", _pInfGroups];

_pInfGroups8 = [];
_pInfGroupsNon8 = [];
_startingLoadoutGroup = [];

// Use sniper preset classes
if (missionPreset == 2) then {
	_spotterClasses = [];
	_sniperClasses = [];	
	{
		_thisClass = _x;
		_thisRole = ((configFile >> "CfgVehicles" >> _thisClass >> "role") call BIS_fnc_GetCfgData);
		switch (_thisRole) do {		
			case "Marksman": {_sniperClasses pushBackUnique _thisClass};			
			case "SpecialOperative": {_spotterClasses pushBackUnique _thisClass};
			default {};
		};				
		_thisDisplayName = ((configFile >> "CfgVehicles" >> _thisClass >> "displayName") call BIS_fnc_GetCfgData);		
		{			
			if (([_x, _thisDisplayName, false] call BIS_fnc_inString)) exitWith {
				_sniperClasses pushBackUnique _thisClass;
			};
		} forEach ["sniper", "marksman"];
		if ((["spotter", _thisDisplayName, false] call BIS_fnc_inString)) exitWith {
			_spotterClasses pushBackUnique _thisClass;
		};		
	} forEach pInfClasses;
	if (count _spotterClasses > 0) then {_startingLoadoutGroup set [1, (selectRandom _spotterClasses)]} else {
		if (count _sniperClasses > 0) then {_startingLoadoutGroup set [1, (selectRandom _sniperClasses)]};
	};
	if (count _sniperClasses > 0) then {_startingLoadoutGroup set [0, (selectRandom _sniperClasses)]};
}; 

if (count _startingLoadoutGroup == 0) then {
	{
		if (count ([(_x select 0)] call BIS_fnc_returnChildren) >= 8) then {		
			_pInfGroups8 pushBack (_x select 0);	
		} else {
			_pInfGroupsNon8 pushBack (_x select 0);
		};
	} forEach _pInfGroups;
	//diag_log format ["DRO: _pInfGroups8: %1", _pInfGroups8];

	if (count _pInfGroups8 > 0) then {
		_chosenGroup = selectRandom _pInfGroups8;
		{
			_startingLoadoutGroup pushBack ((_x >> "vehicle") call BIS_fnc_getCfgData);
		} forEach ([_chosenGroup] call BIS_fnc_returnChildren);
	} else {
		if (count _pInfGroupsNon8 > 0) then {
			_chosenGroup = selectRandom _pInfGroupsNon8;
			{
				_startingLoadoutGroup pushBack ((_x >> "vehicle") call BIS_fnc_getCfgData);
			} forEach ([_chosenGroup] call BIS_fnc_returnChildren);
		};
	};
};
//diag_log format ["DRO: _startingLoadoutGroup: %1", _startingLoadoutGroup];

// Define unitList for all selectable lobby classes
unitList = [];
publicVariable "unitList";
{
	_displayName = ((configfile >> "CfgVehicles" >> _x >> "displayName") call BIS_fnc_getCfgData);
	_factionClass = ((configfile >> "CfgVehicles" >> _x >> "faction") call BIS_fnc_getCfgData);
	_factionName = ((configfile >> "CfgFactionClasses" >> _factionClass >> "displayName") call BIS_fnc_getCfgData);	
	unitList pushBackUnique [_x, _displayName, _factionName];
} forEach pInfClasses;
publicVariable "unitList";
/*
{
	diag_log _x;
} forEach unitList;
*/
//diag_log format ["DRO: unitList: %1", unitList];

diag_log format ["DRO: Player side extraction scripts run time = %1", time - _scriptStartTime];
// Init player unit lobby variables
{
	_thisUnitType = if (count _startingLoadoutGroup > 0) then {
		_desiredUnit = if (_forEachIndex < (count _startingLoadoutGroup)) then {
			_startingLoadoutGroup select _forEachIndex			
		} else {
			selectRandom _startingLoadoutGroup
		};		
		//diag_log format ["DRO: _desiredUnit: %1", _desiredUnit];
		
		_index = {
			if ((_x select 0) == _desiredUnit) exitWith {_forEachIndex};
		} forEach unitList;
		
		if (isNil "_index") then {
			selectRandom unitList
		} else {
			unitList select _index	
		};			
	} else {
		selectRandom unitList
	};		
	_x setVariable ['unitLoadoutIDC', (1200 + _forEachIndex), true];
	_x setVariable ['unitArsenalIDC', (1300 + _forEachIndex), true];
	_x setVariable ['unitDeleteIDC', (1500 + _forEachIndex), true];
	_x setVariable ['unitNameTagIDC', (1700 + _forEachIndex), true];
	
	[[_x, _thisUnitType], 'sunday_system\player_setup\switchUnitLoadout.sqf'] remoteExec ["execVM", _x, false];	
	
} forEach playerGroup;

// *****
// ENEMY SETUP
// *****

// Get enemy faction
enemyFactionName = (configFile >> "CfgFactionClasses" >> enemyFaction >> "displayName") call BIS_fnc_GetCfgData;
// --- Enemy side setup ---
call DRO_fnc_setupEnemySides;

// --- Marker colors ---
call DRO_fnc_defineMarkerColors;

// *****
// AO SETUP
// *****

diag_log "DRO: Call AO script";
_scriptStartTime = time;
[((findDisplay 888888) displayCtrl 8889), "GENERATING AREA OF OPERATIONS"] remoteExecCall ["ctrlSetText", 0];
// Generate AO and collect data
[] call DRO_fnc_generateAO;
diag_log format ["DRO: AO script run time = %1", time - _scriptStartTime];
// Reconfigure AO markers
{
	_x setMarkerColor markerColorEnemy;
} forEach AOMarkers;


// Enemy AO flag marker
_enemyFactionFlagIcon = ((configfile >> "CfgFactionClasses" >> enemyFaction >> "flag") call BIS_fnc_GetCfgData);
_enemyFactionName = ((configfile >> "CfgFactionClasses" >> enemyFaction >> "displayName") call BIS_fnc_GetCfgData);
_enemyFactionFlag = "";
_nonBaseFaction = 0;

if (!isNil "_enemyFactionName") then {
	{ 
		if (((configFile >> "CfgMarkers" >> (configName _x) >> "name") call BIS_fnc_GetCfgData) == _enemyFactionName) then {
			_enemyFactionFlag = (configName _x);			
		};
	} forEach ("true" configClasses (configFile / "CfgMarkers"));
};

if (count _enemyFactionFlag == 0) then {
	if (!isNil "_enemyFactionFlagIcon") then {		
		{ 
			if ([((configFile >> "CfgMarkers" >> (configName _x) >> "icon") call BIS_fnc_GetCfgData), _enemyFactionFlagIcon, false] call BIS_fnc_inString) then {
				_enemyFactionFlag = (configName _x);
				_nonBaseFaction = 1;
			};
		} forEach ("true" configClasses (configFile / "CfgMarkers"));

		switch (enemyFaction) do {
			case "BLU_F": {
				_enemyFactionFlag = "flag_NATO";
			};
			case "BLU_G_F": {
				_enemyFactionFlag = "flag_FIA";
			};
			case "IND_F": {
				_enemyFactionFlag = "flag_AAF";
			};
			case "OPF_F": {
				_enemyFactionFlag = "flag_CSAT";
			};
		};
	};
};
if (count _enemyFactionFlag == 0) then {
	deleteMarker "mkrFlag";
} else {
	"mkrFlag" setMarkerType _enemyFactionFlag;
	if (_nonBaseFaction == 1) then {
		"mkrFlag" setMarkerSize [2, 1.3];
	};
};

/*
if (aoOptionSelect == 0) then {
	aoOptionSelect = [1,5] call BIS_fnc_randomInt;
};
*/

// *****
// INTRO SETUP
// *****

// --- Mission music selection ---
call DRO_fnc_chooseMissionMusic;

// Mission Name
FOBNames = ["Partisan", "Shepherd", "Warden", "Stone", "Gullion", "Beech", "Elm", "Ash", "Cedar", "Hammer", "Axe", "Stanford", "Yale", "Oxford", "Cambridge", "Farmstead", "Temple", "Humboldt", "Herringbone", "Dogtooth", "Underhill", "Matterhorn", "Snowdon", "Coniston", "Windermere", "Victoria", "Ontario", "Como", "Bear", "Eiger"];

missionNameSpace setVariable ["weatherChanged", 1, true];


// *****
// PLAYERS SETUP
// *****

// --- Player identity generation ---
call DRO_fnc_generatePlayerIdentities;
/*
if (month == 0 || day == 0) then {
	[timeOfDay] remoteExec ['DRO_fnc_randomTime', 0, true];
};
*/

// *****
// OBJECTIVES SETUP
// *****

_scriptStartTime = time;
// Get number of tasks
_numObjs = 1;
if (numObjectives == 0) then {
	_numObjs = [1,3] call BIS_fnc_randomInt;
} else {
	_numObjs = numObjectives;
};
diag_log format ["DRO: _numObjs = %1", _numObjs];

// Generate task data and physical objects
allObjectives = [];
objData = [];
taskIDs = [];
taskIntel = [];
publicVariable "taskIntel";
baseReconChance = 0.8;
publicVariable "baseReconChance";
hvtCodenames = ["Condor", "Vulture", "Scorpion", "Einstein", "Pascal", "Loner", "Spearhead", "Dalton", "Damocles", "Paris", "Huxley", "Ghost", "Gaunt", "Goblin", "Reptile"];
powJoinTasks = [];
// --- POW class selection ---
call DRO_fnc_chooseObjectivesPOWClass;
reconPatrolUnused = true;
for "_i" from 1 to (_numObjs) do {
	[((findDisplay 888888) displayCtrl 8889), (format ["GENERATING OBJECTIVE %1", _i])] remoteExecCall ["ctrlSetText", 0];
	if (_i == 1) then {		
		[0] call DRO_fnc_selectObjective;
	} else {		
		[(AOLocations call BIS_fnc_randomIndex)] call DRO_fnc_selectObjective;	
	};	
};
// Hardening: timeout guard. Objectives are created asynchronously above; if one cannot
// be placed (faction without usable units, no valid position, or a restrictive objective
// param combo), allObjectives would never reach _numObjs and this waitUntil would hang
// forever on the intro camera. Proceed with whatever was created after a safety timeout.
private _objWaitEnd = time + 90;
waitUntil { sleep 0.25; (count allObjectives >= _numObjs) || (time > _objWaitEnd) };
if (count allObjectives < _numObjs) then {
	diag_log format ["DRO: WARNING - objective generation timed out at %1/%2 after 90s; proceeding with what was created.", count allObjectives, _numObjs];
};
{
	diag_log format ["DRO: objData %1 = %2", _forEachIndex, objData select _forEachIndex];
} forEach objData;

// ============================================================
// SEA insertion — water corridor finder (server-side, runs once at generation).
// Publishes DRO_seaInsertViable + DRO_seaSpawnPos (offshore) + DRO_seaDropPos (shallow
// shore) + DRO_seaCorridor (waypoints). A corridor is a straight, all-water line
// spawn->drop of length <= DRO_seaInsertMaxDist. If none, SEA insert is not offered.
// No exitWith inside loops (SQF footgun) — flags gate early termination.
// ============================================================
DRO_seaInsertMaxDist = 800;
DRO_seaDropMaxRadius = aoSize + 600;   // max distance drop point may be from AO centre (tunable; keeps landings near the objective, like the heli LZ)
DRO_seaInsertViable = false;
DRO_seaSpawnPos = [];
DRO_seaDropPos = [];
DRO_seaCorridor = [];
[] call {
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

	private _maxScan = DRO_seaDropMaxRadius;
	// Sea vs lake test: BFS flood over 100m water cells from _p; true if the body reaches the
	// map edge (= sea). Stops early on edge, or on a cell cap (a body that big is treated as sea).
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

	// 1. Nearest shallow-water shore point to the AO center that is SEA (connects to the map edge,
	//    not a landlocked lake). Flood-checks each shallow candidate, capped at _maxFloods.
	private _dropPos = [];
	private _foundDrop = false;
	private _floods = 0;
	private _maxFloods = 8;
	private _r = 200;
	while {(!_foundDrop) && (_r <= _maxScan) && (_floods < _maxFloods)} do {
		private _deg = 0;
		while {(!_foundDrop) && (_deg < 360) && (_floods < _maxFloods)} do {
			private _pp = centerPos getPos [_r, _deg];
			if (surfaceIsWater _pp) then {
				private _depth = getTerrainHeightASL _pp;
				if ((_depth < 0) && (_depth > -8)) then {
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

	// 2. Offshore spawn within maxDist with an all-water corridor to the drop.
	if (_foundDrop) then {
		private _seaward = [centerPos, _dropPos] call BIS_fnc_dirTo;
		private _bestDist = 0;
		private _bestSpawn = [];
		{
			private _deg = _seaward + _x;
			private _clearTo = 0;
			private _d = 100;
			private _broken = false;
			while {(!_broken) && (_d <= DRO_seaInsertMaxDist)} do {
				private _cand = _dropPos getPos [_d, _deg];
				if ((surfaceIsWater _cand) && {[_dropPos, _cand, 40] call _fnc_lineIsWater}) then {
					_clearTo = _d;
				} else {
					_broken = true;
				};
				_d = _d + 50;
			};
			if (_clearTo > _bestDist) then {
				_bestDist = _clearTo;
				_bestSpawn = _dropPos getPos [_clearTo, _deg];
			};
		} forEach [-40, -20, 0, 20, 40];

		if ((_bestDist >= 300) && {count _bestSpawn > 0}) then {
			DRO_seaDropPos = _dropPos;
			DRO_seaSpawnPos = [_bestSpawn select 0, _bestSpawn select 1, 0];
			private _cdir = [DRO_seaSpawnPos, DRO_seaDropPos] call BIS_fnc_dirTo;
			private _ctot = DRO_seaSpawnPos distance2D DRO_seaDropPos;
			private _steps = 3;
			DRO_seaCorridor = [];
			for "_i" from 0 to _steps do {
				private _cp = DRO_seaSpawnPos getPos [(_ctot * _i / _steps), _cdir];
				DRO_seaCorridor pushBack [_cp select 0, _cp select 1, 0];
			};
			DRO_seaInsertViable = true;
		};
	};
};
publicVariable "DRO_seaInsertViable";
publicVariable "DRO_seaSpawnPos";
publicVariable "DRO_seaDropPos";
publicVariable "DRO_seaCorridor";
publicVariable "DRO_seaInsertMaxDist";
publicVariable "DRO_seaDropMaxRadius";
diag_log format ["DRO: SEA insert viable=%1 spawn=%2 drop=%3", DRO_seaInsertViable, DRO_seaSpawnPos, DRO_seaDropPos];


_objGroupingHandle = [] execVM "sunday_system\objectives\objGrouping.sqf";
waitUntil {scriptDone _objGroupingHandle};

// Based on task data, assign tasks to players or assign recon tasks instead
{
	diag_log format ["DRO: %1 recon chance %2 checked against %3", (_x select 0), (_x select 6), baseReconChance]; 
	if ((_x select 6) < baseReconChance) then {
		// Create task from task data
		diag_log "DRO: Creating regular task";
		[_x, true, true] call DRO_fnc_assignTask;			
	} else {		
		// Create recon addition
		diag_log "DRO: Creating a recon task";
		[_x, true, true] execVM "sunday_system\objectives\reconTask.sqf";		
	};
} forEach objData;

diag_log format ["DRO: Objective scripts run time = %1", time - _scriptStartTime];

// Mission name
_missionName = [] call DRO_fnc_missionName;
missionNameSpace setVariable ["mName", _missionName, true];

// *****
// CIVILIAN SETUP
// *****

// civiliansEnabled 0 (random), 1 (enabled), 2 (enabled & hostile), 3 (disabled)

// Collect civilian classes
if (civiliansEnabled == 0) then {
	// Civilians only randomly spawned if time of day is not nighttime
	if (timeOfDay <= 3) then {		
		civiliansEnabled = (selectRandom [1, 3]);
	} else {civiliansEnabled = 3};
};
if (civiliansEnabled == 1 || civiliansEnabled == 2) then {	
	[((findDisplay 888888) displayCtrl 8889), "SPAWNING CIVILIANS"] remoteExecCall ["ctrlSetText", 0];			
		civTrue = true;
		[] spawn {			
			_scripts = [];
			{
				_civSpawn = [_forEachIndex] execVM "sunday_system\civilians\generateCivilians.sqf";
				_scripts pushBack _civSpawn;
			} forEach AOLocations;			
			//waitUntil {({!scriptDone _x} count _scripts) == 0};			
			if (random 1 > 0.3) then {				
				[] execVM "sunday_system\intel\addCivilianIntel.sqf";				
			};					
		};

		// Satellite (sempre, inclusive 1 AO) + corridor (apenas AOs>1) civilians.
		// Gating de contagem de AO e de civilians-as-agents é feito dentro do script.
		[] execVM "sunday_system\civilians\generateCorridorCivilians.sqf";
};

missionNameSpace setVariable ["objectivesSpawned", 1, true];

// *****
// WEATHER & TIME
// *****

if (timeOfDay == 0) then {
	timeOfDay = [1,4] call BIS_fnc_randomInt;
};
publicVariable "timeOfDay";

if (month == 0 || day == 0) then {
	_newDate = date;
	if (month == 0) then {
		_newDate set [1, ([1, 12] call BIS_fnc_randomInt)];
	};
	if (day == 0) then {
		_days = [(date select 0), (date select 1)] call BIS_fnc_monthDays;
		_newDate set [2, ([1, _days] call BIS_fnc_randomInt)];
	};
	[_newDate] remoteExec ['setDate', 0, true];	 
};

sleep 0.4;
if (typeName weatherOvercast == "STRING") then {
	[(random [0, 0.4, 1])] call BIS_fnc_setOvercast;
};
_fog = if (overcast < 0.7) then {
	//diag_log (date);
	if (((date select 3) <= 7) || ((date select 3) >= 17)) then {
		if (random 1 > 0.2) then {
			//diag_log 0;
			[0.3, (random 0.05), 20];
		} else {
			//diag_log 1;
			0;
		};
	} else {
		if (random 1 > 0.9) then {
			//diag_log 2;
			[(random 0.1), (random [0.03, 0.05, 0.04]), 20];
		} else {
			//diag_log 3;
			0;
		};
	};	
} else {
	if (random 1 > 0.6) then {
		//diag_log 4;
		[(random 0.3), (random [0.03, 0.05, 0.04]), 20];
	} else {
		//diag_log 5;
		0;
	};
};
0 setFog _fog;
simulWeatherSync;

diag_log format ["DRO: Overcast = %1", overcast];
diag_log format ["DRO: Fog = %1", _fog];

_nextOvercast = (random 1);
_nextFog = if (_nextOvercast < 0.7) then {
	if (random 1 > 0.6) then {
		[(random 0.3), (random [0.03, 0.05, 0.04]), 20];
	} else {
		0;
	};
} else {
	if (random 1 > 0.3) then {
		[0.3, (random 0.05), 20];
	} else {
		0;
	};	
};
2500 setFog _nextFog;
[2500, _nextOvercast] remoteExec ["setOvercast", 0, true];
diag_log format ["DRO: Time of day is %1", timeOfDay];

// *****
// GENERATE ENEMIES
// *****

[((findDisplay 888888) displayCtrl 8889), "SPAWNING ENEMIES"] remoteExecCall ["ctrlSetText", 0];

_garrisionScriptHandle = [] execVM "sunday_system\generate_ao\findGarrisonBuildings.sqf";
waitUntil {scriptDone _garrisionScriptHandle};

_enemyScripts = [];
{
	if (((AOLocations select _forEachIndex) select 4) == 0) then {
		if (_forEachIndex > 0) then {
			_enemyScripts pushBack ([_forEachIndex, "SMALL"] execVM "sunday_system\generate_enemies\generateEnemies.sqf");
		} else {
			_enemyScripts pushBack ([0, "REGULAR"] execVM "sunday_system\generate_enemies\generateEnemies.sqf");
		};
	};
} forEach AOLocations;

waitUntil {({!scriptDone _x} count _enemyScripts) == 0};
[] execVM "sunday_system\intel\addIntelObjects.sqf";

if (stealthEnabled == 0) then {
	if (timeOfDay >= 3 && missionPreset != 3) then {
		stealthEnabled = selectRandom [1,2];
	} else {
		stealthEnabled = 2;
	};
}; 
publicVariable "stealthEnabled";

// Generate power units
if (stealthEnabled == 1) then {
	_maxPowerUnits = ([1,3] call BIS_fnc_randomInt);
	_p = 0;
	while {_p <= _maxPowerUnits} do {
		_AOIndexes = [];
		{
			_AOIndexes pushBack _forEachIndex;			
		} forEach AOLocations;
		_AOIndexesShuffled = _AOIndexes call BIS_fnc_arrayShuffle;
		{
			if (count (((AOLocations select _x) select 2) select 7) > 0) exitWith {
				_building = [(((AOLocations select _x) select 2) select 7)] call DRO_fnc_selectRemove;
				[_building] execVM "sunday_system\objectives\destroyPowerUnit.sqf";
			};
		} forEach _AOIndexesShuffled;		
		_p = _p + 1;
	};	
}; 
if (random 1 > 0.5) then {
	[] execVM "sunday_system\objectives\destroyCommsTower.sqf";
};

// Create intro sequence
// Collect all possible camera targets
/*
_introPosCollect = travelPosPOIMil + enemyPosCollection;
{_introPosCollect pushBack (_x select 5)} forEach objData;
for "_c" from 0 to 2 do {
	_thisTarget = [_introPosCollect] call DRO_fnc_selectRemove;
	_randPos = [_thisTarget, 5, 15, 3, 1, 0.4, 0, [], [0,0,0]] call BIS_fnc_findSafePos;
	if !(_randPos isEqualTo [0,0,0]) then {
	
	};
};
*/
missionNamespace setVariable ["dro_introCamReady", 1, true];

// *****
// GENERATE FRIENDLIES
// *****

// Generate chances
//_friendlyChance = if (count AOLocations > 1) then {random 1} else {0};
_friendlyChance = if (missionPreset == 3) then {1} else {0};
//_friendlyChance = 1; // DEBUG
/*
_ambFriendlyChance = if (count AOLocations > 1 || stealthEnabled == 2) then {
	if (_friendlyChance > 0.75) then {random 1.2} else {random 1};
} else {0};
*/
_ambFriendlyChance = if (missionPreset == 3) then {1} else {0};
//if (missionPreset == 3) then {_ambFriendlyChance = 1};

if (_friendlyChance > 0.8 || _ambFriendlyChance > 0.8) then {
	[_friendlyChance, _ambFriendlyChance] execVM "sunday_system\player_setup\generateFriendlies.sqf";	
};


// *****
// WAIT FOR LOBBY COMPLETION
// *****

_scriptStartTime = time;
waitUntil {(missionNameSpace getVariable "lobbyComplete") == 1};

_setupPlayersHandle = [] execVM "sunday_system\player_setup\setupPlayersFaction.sqf";
waitUntil {scriptDone _setupPlayersHandle};

missionNameSpace setVariable ["playersReady", 1, true];

diag_log "DRO: setupPlayersFaction completed";
diag_log format ["DRO: Player setup script run time = %1", time - _scriptStartTime];

// *****
// Set all simple objects
// *****

if (!isNil "DRO_simpleObjects") then {
	if (count DRO_simpleObjects > 0) then {
		{
			[_x] call DRO_fnc_replaceSimpleObject;
		} forEach DRO_simpleObjects;
	};
};


// *****
// MISC EXTRAS
// *****

// Start message listener
[] execVM "sunday_system\messageListener.sqf";

// Create a few empty enemy vehicles for use in escape
if (random 1 > 0.3) then {
	_numEscapeVehicles = [1,5] call BIS_fnc_randomInt;
	for "_i" from 1 to _numEscapeVehicles do {
		_vehClass = "";
		if (count eCarNoTurretClasses > 0) then {
			_vehClass = selectRandom eCarNoTurretClasses;
		} else {
			if (count eCarClasses > 0) then {
				_vehClass = selectRandom eCarClasses;
			};
		};
		if (count _vehClass > 0) then {
			if (count (((AOLocations select 0) select 2) select 0) > 0) then {
				_pos = [(((AOLocations select 0) select 2) select 0)] call DRO_fnc_selectRemove;
				_veh = _vehClass createVehicle _pos;			
				_roadList = _pos nearRoads 10;
				if (count _roadList > 0) then {
					_thisRoad = _roadList select 0;
					_roadConnectedTo = roadsConnectedTo _thisRoad;
					_direction = 0;
					if (count _roadConnectedTo == 0) then {
						_direction = 0; 
					} else {
						_connectedRoad = _roadConnectedTo select 0;
						_direction = [_thisRoad, _connectedRoad] call BIS_fnc_DirTo;
					};				
					_veh setDir _direction;
					_newPos = [_pos, 4, (_direction + 90)] call BIS_fnc_relPos;
					_veh setPos _newPos;
				};
			};
		};
	};
};

// Ambient flyover setup
_ambientFlyByChance = random 1;
if (_ambientFlyByChance > 0.65) then {
	_flyerClasses = (eHeliClasses + ePlaneClasses);
	if (count _flyerClasses > 0) then {
		[centerPos, _flyerClasses] execVM "sunday_system\generate_ao\ambientFlyBy.sqf";
	};
};

if (animalsEnabled == 0) then {
	[centerPos] execVM "sunday_system\generate_ao\generateAnimals.sqf";
};
[] execVM "sunday_system\civilians\civMoveAction.sqf";

// Add intel items
[] execVM "sunday_system\intel\addEnemyIntel.sqf";

// Briefing init
[_missionName] execVM "briefing.sqf";

// Handle minefields
if (minesEnabled == 1) then {
	[centerPos] execVM "sunday_system\generate_ao\generateMinefield.sqf";
};

// Remove enemy NVG because it's bullshit
[] call DRO_fnc_removeEnemyNVG;

// Attempt to set CBA ACE3 stamina
if ((["Stamina", 0] call BIS_fnc_getParamValue > 0) || ((staminaDisabled) > 0)) then {
	if (!isNil "ace_advanced_fatigue_enabled") then {
		[missionNamespace, ["ace_advanced_fatigue_enabled", false]] remoteExec ["setVariable", 0];
	};
};

// Attempt to set vn_artillery trait for each player if Always Allowed
if ((["SOGPFRadioSupportTrait", 0] call BIS_fnc_getParamValue) == 1) then {
	_playersInGroup = [] call CBA_fnc_players;
	{
		_x setUnitTrait ["vn_artillery", true, true];
	} forEach _playersInGroup; 
};

// *****
// SEQUENCING
// *****

// --- Reinforcement trigger ---
call DRO_fnc_setupReinforcementTrigger;

// Wait until all assigned tasks are confirmed complete (stable for 6s),
// then bump reinforceChance and dispatch the extract task.
//
// Migrated from a scheduled `waituntil { sleep 10; check; if (ok) then { sleep 6; recheck }; ok }`
// to a CBA per-frame watcher (10s polling) + non-scheduled 6s stability
// recheck via CBA_fnc_waitAndExecute. Same flow, no scheduled thread.

diag_log format ["DRO: taskIDs = %1", taskIDs];

DRO_fnc_allTasksComplete = {
	if (taskCreationInProgress) exitWith { false };
	private _ok = true;
	{
		if (!([_x] call BIS_fnc_taskCompleted)) exitWith { _ok = false; };
	} forEach taskIDs;
	_ok
};

DRO_fnc_onAllTasksComplete = {
	diag_log "DRO: All assigned tasks confirmed complete (stable 6s)";
	reinforceChance = reinforceChance + 0.1;
	[] execVM "sunday_system\createExtractTask.sqf";
};

DRO_fnc_taskWatcherTick = {
	params ["_args", "_pfhId"];
	if (!(call DRO_fnc_allTasksComplete)) exitWith {};
	// Tasks look complete — pause polling and schedule a 6s stability recheck.
	[_pfhId] call CBA_fnc_removePerFrameHandler;
	[{
		if (call DRO_fnc_allTasksComplete) then {
			call DRO_fnc_onAllTasksComplete;
		} else {
			// Stability recheck failed — resume 10s polling.
			DRO_taskWatcherPFH = [DRO_fnc_taskWatcherTick, 10, []] call CBA_fnc_addPerFrameHandler;
		};
	}, [], 6] call CBA_fnc_waitAndExecute;
};

DRO_taskWatcherPFH = [DRO_fnc_taskWatcherTick, 10, []] call CBA_fnc_addPerFrameHandler;
