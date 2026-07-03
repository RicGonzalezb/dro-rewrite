_rscLayer = ["RscLogo"] call BIS_fnc_rscLayer;
_rscLayer cutRsc ["DRO_Splash", "PLAIN", 0, true];

diag_log format ["DRO: Player %1 waiting for player init", player];
waitUntil {!isNull player};

// [M3 removed] #include "sunday_system\fnc_lib\sundayFunctions.sqf";
// [M3 removed] #include "sunday_system\fnc_lib\droFunctions.sqf";
// [M3 removed] #include "sunday_revive\reviveFunctions.sqf";
// [M3 removed] #include "sunday_system\fnc_lib\menuFunctions.sqf";

addWeaponItemEverywhere = compileFinal " _this select 0 addPrimaryWeaponItem (_this select 1); ";
addHandgunItemEverywhere = compileFinal " _this select 0 addHandgunItem (_this select 1); ";
removeWeaponItemEverywhere = compileFinal "_this select 0 removePrimaryWeaponItem (_this select 1)";

if (!hasInterface || isDedicated) exitWith {};

// M10 REQ3: startReady removed — leader-only START button replaces per-player ready toggle
playerCameraView = cameraView;
loadoutSavingStarted = false;

fnc_missionText = {
	// Mission info readout
	_campName = (missionNameSpace getVariable "publicCampName");
	diag_log format ["DRO: Player %1 establishing shot initialized", player];
	sleep 3;
	[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1</t>", toUpper _campName], true, nil, 5, 0.7, 0] spawn BIS_fnc_textTiles;
	sleep 6;
	_hours = "";
	if ((date select 3) < 10) then {
		_hours = format ["0%1", (date select 3)];
	} else {
		_hours = str (date select 3);
	};
	_minutes = "";
	if ((date select 4) < 10) then {
		_minutes = format ["0%1", (date select 4)];
	} else {
		_minutes = str (date select 4);
	};
	[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1  %2</t>", str(date select 1) + "." + str(date select 2) + "." + str(date select 0), _hours + _minutes + " HOURS"], true, nil, 5, 0.7, 0] spawn BIS_fnc_textTiles;
	sleep 6;
	// Operation title text
	_missionName = missionNameSpace getVariable ["mName", ""];
	_string = format ["<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1</t>", _missionName];
	[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1</t>", toUpper _missionName], true, nil, 7, 0.7, 0] spawn BIS_fnc_textTiles;
};

// Turn on menu music
0 fadeMusic 0;
playMusic "LeadTrack01_F_Jets";
5 fadeMusic 1;

player createDiarySubject ["dro", "Dynamic Recon Ops"];
player createDiaryRecord ["dro", ["Dynamic Recon Ops", "
	<font image='images\recon_image_collection.jpg' width='350' height='175'></font><br /><br />
	Dynamic Recon Ops is a randomized, re-playable scenario that generates an enemy occupied AO with a selection of tasks to complete within.
	Select your AO location, the factions you want to use and any supports available or leave them all randomized and see what mission you are sent on.<br /><br />
	Designed to be simple to use but with plenty of options to customize your mission setup, the objective behind DRO is to create a way to quickly get playing a new scenario in singleplayer or co-op. With as few changes to the base game as possible, DRO aims to showcase the unique and varied gameplay that Arma 3 has to offer for smaller scale infantry combat.<br /><br />
	Additionally, DRO has been designed from the ground up to take advantage of faction mods. If you have any mods that create new factions they will be selectable as player or enemy sides within the mission. However, the scenario itself requires no mods apart from specific terrains if you want to use them.<br /><br />
	Thank you for playing!	
"]];

//add ACE3 diary entry
player createDiarySubject ["dro_ace3compat", "DRO ACE Compatibility"];
player createDiaryRecord ["dro_ace3compat", ["DRO ACE Compatibility", "
	ACE3 is the collaborative efforts of the former AGM and CSE teams, along with many of the developers from Arma 2's ACE2 project. It adds many features to the core Arma 3 experience including disposable launchers, backblast and overpressure, realisitc night and thermal vision, advanced movements, advanced ballistics, improved weapons handling, a deeper medical and injury system, and much more.<br /><br />
	ACE3 has been integrated into DRO by re-writing several internal functions to better support detecting if the ACE Medical system is loaded, better enumeration of players using CBA functions, and the inclusion of the ACE3 Arsenal feature for those that prefer it.<br /><br />
	When at the Team Planning area, press <t font='PuristaBold'>Escape</font> and in the <t font='PuristaBold'>Action</font> menu (accessed by the scroll wheel or pressing your <t font='PuristaBold'>Action</font> button) you can select to use the ACE3 Arsenal to outfit your unit. You can then return to the Team Planning menu to continue the mission.
"]];

player setVariable ["respawnLoadout", (getUnitLoadout player), true];
VAR_CAMERA_VIEW = playerCameraView;

diag_log format ["clientOwner = %1", clientOwner];
playerReady = 0;
enableTeamSwitch false;
enableSentences false;

// Move to mission area if JIP and do not process intro script
_doJIP = if (didJIP) then {
	if ((missionNameSpace getVariable ["lobbyComplete", 0]) == 0) then {
		false
	} else {
		true
	};	
} else {
	false
};

if (_doJIP) exitWith {
	["DRO: JIP detected for player %1", player] call bis_fnc_logFormat;
	//Position
	_pos = if (getMarkerColor "respawn" == "") then {
		getMarkerPos "campMkr"
	} else {
		getMarkerPos "respawn"
	};
	_pos set [2,0];
	// Loadout	
	_chosenSlotUnit = objNull;
	{
		if (!isPlayer _x) exitWith {
			_chosenSlotUnit = _x;
		};
	} forEach units (grpNetId call BIS_fnc_groupFromNetId);	
	if (!isNull _chosenSlotUnit) then {
		["DRO: JIP player %1 will be selectPlayer'd into %2", player, _chosenSlotUnit] call bis_fnc_logFormat;		
		selectPlayer _chosenSlotUnit;
		removeAllActions _chosenSlotUnit;
		if (reviveDisabled < 3) then {
			[_chosenSlotUnit] call DRO_fnc_addReviveToUnit;	
		};
	} else {
		//_class = (selectRandom unitList);
		//[player, _class] execVM 'sunday_system\player_setup\switchUnitLoadout.sqf';
		//sleep 1;
		[player, _pos] call DRO_fnc_jipNewUnit;
	};
	_allHCs = entities "HeadlessClient_F";
	_currentPlayers = allPlayers - _allHCs;
	_currentPlayers = _currentPlayers - [player];
	_tasks = [_currentPlayers select 0] call BIS_fnc_tasksUnit;
	{
		_taskDesc = [_x] call BIS_fnc_taskDescription;
		_taskDest = [_x] call BIS_fnc_taskDestination;		
		_taskState = [_x] call BIS_fnc_taskState;		
		_taskType = missionNamespace getVariable [(format ["%1_taskType", _x]), "Default"];	
		_id = [_x, player, _taskDesc, _taskDest, _taskState, 1, false, false, _taskType, true] call BIS_fnc_setTask;
		//[_x, _taskType] call BIS_fnc_taskSetType;
	} forEach _tasks;
	player createDiaryRecord ["Diary", ["Briefing", briefingString]];
	_rscLayer cutFadeOut 2;
	enableSentences true;
	cutText ["", "BLACK IN", 3];
	playMusic "";
	[] call fnc_missionText;
};

sleep 0.1;
["objectivesSpawned"] spawn DRO_fnc_randomCam;

//cutText ["", "BLACK IN", 2];

//["Preload"] spawn BIS_fnc_arsenal;
//sleep 2;
diag_log format ["DRO: Player %1 waiting for factionDataReady", player];
waitUntil {(missionNameSpace getVariable ["factionDataReady", 0]) == 1};
diag_log format ["DRO: Player %1 received factionDataReady", player];
waitUntil {!isNil "topUnit"};
/*
_counter = 0;
while {_counter < 1} do {
	{
		((findDisplay 999991) displayCtrl _x) ctrlSetFade _counter;
		((findDisplay 999991) displayCtrl _x) ctrlCommit 0;
	} forEach [1000, 1001, 1002];
	sleep 0.02;
	_counter = _counter + 0.01;
};
closeDialog 1;
*/
sleep 3;


if (player == topUnit) then {
	// M9: Carregar profile e params ANTES das decisoes de UI.
	[] call compile preprocessFileLineNumbers "loadProfile.sqf";
	[] call compile preprocessFileLineNumbers "loadParams.sqf";

	if (DRO_paramSkipUI) then {
		// Both scenario AND factions come from params -> nothing to configure -> skip the sunday dialog.
		diag_log "DRO: sunday dialog skipped (scenario + factions via params).";
	} else {
		// ESTADO #3 ou Vanilla. Funcao reutilizavel para (re)abrir o menu.
		DRO_openSetupMenu = {
			if (!isNull (findDisplay 52525)) exitWith {};
			if ((missionNameSpace getVariable ["factionsChosen", 0]) == 1) exitWith {};
			createDialog "sundayDialog";
			menuComplete = false;
			[] execVM "sunday_system\dialogs\populateStartupMenu.sqf";
			if (DRO_scenarioFromParams || DRO_factionsFromParams) then {
				[] spawn {
					waitUntil { !isNil "menuComplete" && {menuComplete} };
					disableSerialization;
					// Rebuild tab list: drop scenario tabs if scenario is param'd, drop the advanced-factions tab if factions are param'd.
					private _arr = [["INFO", 1140]];
					if (!DRO_scenarioFromParams) then { _arr append [["SCENARIO", 2000], ["ENVIRONMENT", 3000], ["OBJECTIVES", 4000]]; };
					if (!DRO_factionsFromParams) then { _arr pushBack ["ADVANCED FACTIONS", 5000]; };
					menuSliderArray = _arr;
					menuSliderCurrent = 0;
					// Lock the always-visible faction bar when factions come from params.
					private _resolvedFactionsMsg = "";
					if (DRO_factionsFromParams) then {
						{ ((findDisplay 52525) displayCtrl _x) ctrlEnable false; } forEach [1301, 1311, 1321];
						// Reflect the server-resolved factions (RANDOM already rolled by loadParams.sqf) in the
						// locked listboxes, instead of leaving fn_clearData.sqf's default selection on screen.
						private _selByData = {
							params ["_idc", "_cn"];
							private _sel = -1;
							for "_i" from 0 to ((lbSize _idc) - 1) do {
								if ((lbData [_idc, _i]) isEqualTo _cn) exitWith { _sel = _i };
							};
							if (_sel >= 0) then { lbSetCurSel [_idc, _sel]; };
							_sel
						};
						// playersFaction / enemyFaction / civFaction are publicVariable'd by the server in loadParams.sqf;
						// wait briefly (bounded, no new spawn) so we don't select against a nil value on a slow client.
						private _waitCounter = 0;
						waitUntil {
							_waitCounter = _waitCounter + 1;
							(!isNil "playersFaction" && !isNil "enemyFaction" && !isNil "civFaction") || _waitCounter > 100
						};
						private _pfCN = missionNamespace getVariable ["playersFaction", ""];
						private _efCN = missionNamespace getVariable ["enemyFaction", ""];
						private _cfCN = missionNamespace getVariable ["civFaction", ""];
						private _pfName = if (_pfCN != "") then { getText (configFile >> "CfgFactionClasses" >> _pfCN >> "displayName") } else { "-" };
						private _efName = if (_efCN != "") then { getText (configFile >> "CfgFactionClasses" >> _efCN >> "displayName") } else { "-" };
						private _cfName = if (_cfCN != "") then { getText (configFile >> "CfgFactionClasses" >> _cfCN >> "displayName") } else { "None" };
						if (_pfCN != "") then {
							if (([1301, _pfCN] call _selByData) < 0) then { _pfName = _pfCN + " (unavailable in list)"; };
						};
						if (_efCN != "") then {
							if (([1311, _efCN] call _selByData) < 0) then { _efName = _efCN + " (unavailable in list)"; };
						};
						if (_cfCN != "") then {
							if (([1321, _cfCN] call _selByData) < 0) then { _cfName = _cfCN + " (unavailable in list)"; };
						};
						_resolvedFactionsMsg = format ["<br/><br/><t size='0.9'>Player: %1 | Enemy: %2 | Civ: %3</t>", _pfName, _efName, _cfName];
					};
					private _msg = if (DRO_scenarioFromParams) then {
						"Scenario / Environment / Objectives are server-defined. Choose factions and press START."
					} else {
						"Factions are server-defined. Configure the scenario and press START."
					};
					private _n = (findDisplay 52525) displayCtrl 1144;
					_n ctrlSetStructuredText (parseText ("<t size='1.15' shadow='1'>SERVER-DEFINED SETUP</t><br/><br/><t size='0.95'>" + _msg + "</t>" + _resolvedFactionsMsg));
					_n ctrlSetFade 0;
					_n ctrlShow true;
					_n ctrlCommit 0;
					diag_log "DRO: sunday dialog locked per sphere.";
				};
			};
		};

		waitUntil {!dialog};
		call DRO_openSetupMenu;

		// M9: HOME (199) reabre o menu se fechado por ESC sem dar START.
		// M9 (auditoria leaks): remove EH antigo antes de readicionar (idempotente, NOTED-3).
		if (!isNil "DRO_setupReopenEH") then { (findDisplay 46) displayRemoveEventHandler ["KeyDown", DRO_setupReopenEH] };
		DRO_setupReopenEH = (findDisplay 46) displayAddEventHandler ["KeyDown", {
			params ["_disp", "_key"];
			if (_key == 199 && {(missionNameSpace getVariable ["factionsChosen", 0]) == 0} && {isNull (findDisplay 52525)}) then {
				call DRO_openSetupMenu;
				("DRO_reopenHint" call BIS_fnc_rscLayer) cutText ["", "PLAIN", 0];
			};
			false
		}];

		// Watcher: avisa quando o menu esta fechado e ainda nao confirmado.
		// M9 (auditoria leaks): remove PFH antigo antes de recriar (idempotente, NOTED-4).
		if (!isNil "DRO_setupWatchPFH") then { [DRO_setupWatchPFH] call CBA_fnc_removePerFrameHandler };
		DRO_setupWatchPFH = [{
			params ["_a", "_h"];
			private _layer = "DRO_reopenHint" call BIS_fnc_rscLayer;
			if ((missionNameSpace getVariable ["factionsChosen", 0]) == 1) exitWith {
				_layer cutText ["", "PLAIN", 0];
				if (!isNil "DRO_setupReopenEH") then { (findDisplay 46) displayRemoveEventHandler ["KeyDown", DRO_setupReopenEH]; };
				[_h] call CBA_fnc_removePerFrameHandler;
			};
			if (isNull (findDisplay 52525)) then {
				_layer cutText ["Mission config Menu closed - press HOME open it", "PLAIN", 0, true];
			} else {
				_layer cutText ["", "PLAIN", 0];
			};
		}, 0.5, []] call CBA_fnc_addPerFrameHandler;
	};
};

_rscLayer cutFadeOut 2;

//diag_log format ["DRO: Player %1 waiting for serverReady", player];
//waitUntil {(missionNameSpace getVariable ["serverReady", 0]) == 1};
//diag_log format ["DRO: Player %1 received serverReady", player];

if (player != topUnit) then {
	[toUpper "Please wait while mission is generated", "objectivesSpawned", 1, ""] spawn DRO_fnc_callLoadScreen;
};

[] spawn {
	// Turn off menu music
	waitUntil {(missionNameSpace getVariable ["factionsChosen", 0]) == 1};
	10 fadeMusic 0;
};

diag_log format ["DRO: Player %1 waiting for objectivesSpawned", player];
waitUntil{(missionNameSpace getVariable ["objectivesSpawned", 0]) == 1};
diag_log format ["DRO: Player %1 objectivesSpawned == 1", player];


// Get camera target point
_heightEnd = getTerrainHeightASL (missionNameSpace getVariable ["aoCamPos", []]);
_camEndPos = [(missionNameSpace getVariable "aoCamPos") select 0, (missionNameSpace getVariable ["aoCamPos", []]) select 1, 10];
_iconPos = ASLToAGL _camEndPos;

_aoLocationName = (missionNameSpace getVariable "aoLocationName");

// Create camera initial zoom point
_camDir = (random 360);
_initialCamPos = [_camEndPos, 3000, _camDir] call BIS_fnc_relPos;

// Create camera slowdown point
_extendPos = [_camEndPos, 200, _camDir] call BIS_fnc_relPos;
_heightStart = getTerrainHeightASL _extendPos;
if (_heightStart < _heightEnd) then {
	_heightStart = _heightEnd; 
};
if (_heightStart < 20) then {_heightStart = 0};
_camStartPos = [(_extendPos select 0), (_extendPos select 1), (_heightStart+15)];

_initialHeight = (_heightStart+50);
_initialCamPos set [2, _initialHeight];
_attempts = 0;
while {(terrainIntersectASL [_camStartPos, _initialCamPos])} do {
	if (_attempts > 10) exitWith {};
	_initialHeight = _initialHeight + 30;
	_initialCamPos set [2, _initialHeight];	
	_attempts = _attempts + 1;
	diag_log "DRO: Raised _initialCamPos";
};

// Init camera
cam = "camera" camCreate _initialCamPos;
diag_log format ["DRO: Player %1 waiting for randomCamActive", player];
waitUntil {!randomCamActive};
diag_log format ["DRO: Player %1 received randomCamActive", player];
cam cameraEffect ["internal", "BACK"];
cam camSetPos _initialCamPos;
cam camSetTarget _camEndPos;
cam camCommit 0;
if (sunOrMoon < 0.9) then {
	camUseNVG true;
};	
cameraEffectEnableHUD false;
cam camPreparePos _camStartPos;
cam camCommitPrepared 3;

cutText ["", "BLACK IN", 3];
diag_log "DRO: Intro camera begun";

playMusic "";
0 fadeMusic 1;
playmusic [musicIntroSting, 0];

sleep 3;
cam camPreparePos _camEndPos;
cam camPrepareFov 0.2;
cam camCommitPrepared 50;

[
	[
		[toUpper _aoLocationName, "align = 'center' shadow = '0' size = '2' font='EtelkaMonospaceProBold'"]		
	],
	0 * safezoneW + safezoneX,
	0.75 * safezoneH + safezoneY,
	false
] spawn BIS_fnc_typeText2;
sleep 7;
cutText ["", "BLACK OUT", 1];
10 fademusic 0;
sleep 1;

closeDialog 1;

cam cameraEffect ["terminate","back"];
camUseNVG false;
camDestroy cam;	
diag_log format ["DRO: Player %1 cam terminated", player];	


//waitUntil{(missionNameSpace getVariable ["dro_introCamComplete", 0]) == 1};
// Team Planning lobby — bypassed when DRO_paramSkipTeamPlanning is set, EXCEPT when the chosen
// insertion is Sea-Boat (5) but no water corridor is viable for this AO: then force the lobby
// open so the leader can pick another insertion type.
private _skipTP = missionNamespace getVariable ["DRO_paramSkipTeamPlanning", false];
private _forceLobbyForSea = _skipTP && (insertType isEqualTo 5) && (!(missionNamespace getVariable ["DRO_seaInsertViable", false]));
if ((!_skipTP) || _forceLobbyForSea) then {
	// Open map
	_mapOpen = openMap [true, false];
	mapAnimAdd [0, 0.05, markerPos "centerMkr"];
	mapAnimCommit;
	cutText ["", "BLACK IN", 1];
	hintSilent "Close map when ready to access loadout menu";
	diag_log format ["DRO: Player %1 map initialized", player];

	waitUntil {!visibleMap};
	diag_log format ["DRO: Player %1 map closed", player];
	hintSilent "";

	cutText ["", "BLACK FADED"];

	// Open lobby — M10 REQ2 hotfix: only the leader (topUnit) auto-opens Team Planning.
	// Non-leaders assume their unit directly and are pointed at the Arsenal scroll action.
	// Both keep the "Open Team Planning" / "Open Arsenal" addActions below.
	if (player == topUnit) then {
		_handle = CreateDialog "DRO_lobbyDialog";
		diag_log format ["DRO: Player %1 created DRO_lobbyDialog: %2", player, _handle];
		[] execVM "sunday_system\dialogs\populateLobby.sqf";
		if (_forceLobbyForSea) then { hintSilent "Sea insertion unavailable for this AO — select another insertion type."; };
		sleep 0.5;
		cutText ["", "BLACK IN", 1];
	} else {
		cutText ["", "BLACK IN", 1];
		hintSilent "Use 'Open Arsenal' scroll action to customize your gear";
	};
} else {
	// Skip Team Planning: AO intro cam already played; go straight to the mission.
	// Leader marks the lobby complete so the server (start.sqf) proceeds to player setup.
	cutText ["", "BLACK IN", 1];
	if (player == topUnit) then {
		missionNamespace setVariable ["lobbyComplete", 1, true];
		diag_log "DRO: Team Planning skipped (param) - lobbyComplete set by leader";
	};
};

_actionID = player addAction ["Open Team Planning", 
	{
		_handle = CreateDialog "DRO_lobbyDialog";
		[] execVM "sunday_system\dialogs\populateLobby.sqf";
	}, nil, 6
];

//add ACE Arsenal to action menu (skip when Arsenal toggle is disabled)
_actionID2 = -1;
if (((missionNamespace getVariable ["arsenalEnabled", 0]) != 1) && DRO_aceArsenal) then {
	_actionID2 = player addAction ["<t color='#FFDF00'>Open ACE Arsenal</t>", 
		{
			[player, player, true] call ACE_arsenal_fnc_openBox;
		}, nil, 7
	];

	//add ACE Arsenal to interaction on team members
	_CHZ_AIACEArsenal = [
		"AIACEArsenal",
		"Change Equipment",
		"",
		{
			params ["_target", "_player", "_params"];
			[_target, _target, true] call ACE_arsenal_fnc_openBox;
		},
		{
			(isPlayer _player) && (!(isPlayer _target)) && (_target in (units _player)) && (alive _target) && 
			[_player, _target, []] call ACE_common_fnc_canInteractWith
		}
	] call ACE_interact_menu_fnc_createAction;
	{
		[_x, 0, ["ACE_MainActions"], _CHZ_AIACEArsenal] call ACE_interact_menu_fnc_addActionToObject;
	} forEach units player;
};

// M10 REQ2+REQ3: Only leader runs cosmetic loop; non-leader skips to waitUntil
// startReady coloring removed (REQ3); ready-count removed (REQ3 — leader button sets lobbyComplete directly)
if (player == topUnit) then {
	while {((missionNameSpace getVariable ["lobbyComplete", 0]) == 0)} do {
		sleep 0.2;
		if (!isNull (findDisplay 626262)) then {
			if ((getMarkerColor "campMkr" == "")) then {
				((findDisplay 626262) displayCtrl 6006) ctrlSetText "Insertion position: RANDOM";
			} else {
				((findDisplay 626262) displayCtrl 6006) ctrlSetText format ["Insertion position: %1", (mapGridPosition (getMarkerPos 'campMkr'))];
			};
		};
	};
};

// Wait for host to press the start button
diag_log format ["DRO: Player %1 waiting for lobbyComplete", player];
waitUntil {((missionNameSpace getVariable ["lobbyComplete", 0]) == 1)};
diag_log format ["DRO: Player %1 received lobbyComplete", player];

// Close dialogs twice in case player has arsenal open
closeDialog 1;	
closeDialog 1;	

1 fadeSound 0;

player removeAction _actionID;

//remove ACE Arsenal from action menu on lobby complete
player removeAction _actionID2;

(format ["DRO: Player %1 lobby closed", player]) remoteExec ["diag_log", 2, false];

cutText ["", "BLACK FADED"];

// M10 REQ2 / skip: guard — non-leader or skipped Team Planning may never have created camLobby
if (!isNil "camLobby") then {
	(format ["DRO: Player %1 preparing to terminate camera %2", player, camLobby]) remoteExec ["diag_log", 2, false];
	camLobby cameraEffect ["terminate","back"];
	camUseNVG false;
	camDestroy camLobby;
	(format ["DRO: Player %1 terminated camera %2", player, camLobby]) remoteExec ["diag_log", 2, false];
};
player switchCamera playerCameraView;
(format ["DRO: Player %1 switched to cameraView %2", player, cameraView]) remoteExec ["diag_log", 2, false];

waitUntil {count (missionNameSpace getVariable ["startPos", []]) > 0};

3 fadeSound 1;
enableSentences true;
cutText ["", "BLACK IN", 3];

//remove ACE Arsenal interaction from team members on lobby complete
if (DRO_aceArsenal) then {
	{
		[_x, 0, ["ACE_MainActions", "AIACEArsenal"]] call ACE_interact_menu_fnc_removeActionFromObject;
	} forEach units player;
};

// Mission info readout
[] call fnc_missionText;

player createDiarySubject ["dro", "Dynamic Recon Ops"];
player createDiaryRecord ["dro", ["Dynamic Recon Ops", "
	<font image='images\recon_image_collection.jpg' width='350' height='175'></font><br /><br />
	Dynamic Recon Ops is a randomized, re-playable scenario that generates an enemy occupied AO with a selection of tasks to complete within.
	Select your AO location, the factions you want to use and any supports available or leave them all randomized and see what mission you are sent on.<br /><br />
	Designed to be simple to use but with plenty of options to customize your mission setup, the objective behind DRO is to create a way to quickly get playing a new scenario in singleplayer or co-op. With as few changes to the base game as possible, DRO aims to showcase the unique and varied gameplay that Arma 3 has to offer for smaller scale infantry combat.<br /><br />
	Thank you for playing!	
"]];

// Start saving player loadout periodically.
// Migrated to a non-scheduled CBA per-frame handler with 5s delta.
loadoutSavingStarted = true;
playerRespawning = false;
diag_log format ["DRO: Initial respawn loadout = %1", (getUnitLoadout player)];
if (isNil "DRO_loadoutSaverPFH") then {
	DRO_loadoutSaverPFH = [{
		if (alive player && !playerRespawning) then {
			player setVariable ["respawnLoadout", getUnitLoadout player, true];
		};
	}, 5, []] call CBA_fnc_addPerFrameHandler;
};
