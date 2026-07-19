_allHCs = entities "HeadlessClient_F";
_allHPs = (units (group player)) - _allHCs;

_dialogPlayer = {
	if (isPlayer _x) exitWith {
		_x
	};
} forEach _allHPs;
diag_log format ["DRO: _allHPs = ", _allHPs];
diag_log format ["DRO: %2 considers dialog top control player to be: %2", player, _dialogPlayer];

disableSerialization;

_lobbyCamHandle = [] execVM "sunday_system\dialogs\initLobbyCam.sqf";
diag_log format ["DRO: Lobby cam script executed: %1", _lobbyCamHandle];

// M12: AI squad rework — per-unit row creation (nametag/loadout/arsenal/
// remove-AI controls) moved to functions/fn_rebuildRoster.sqf, a reusable
// function also called by Add AI / Remove AI / JIP backfill so the roster
// stays in sync without duplicating this whole script (which also does
// one-time work below — menuSliderArray, insertion/support combos — that
// must NOT run again on every roster change).
{
	_x setDir (_x getVariable ["startDir", 0]);
} forEach _allHPs;

call DRO_fnc_rebuildRoster;

menuSliderArray = [	
	["SQUAD LOADOUT", 6060],
	["INSERTION", 6070],
	["SUPPORTS", 6080]	
];
menuSliderCurrent = 0;

{
	((findDisplay 626262) displayCtrl (ctrlIDC _x)) ctrlSetFade 0;
	((findDisplay 626262) displayCtrl (ctrlIDC _x)) ctrlCommit 0.3;
} forEach (allControls findDisplay 626262);

// M10 REQ3: hide START MISSION button for non-leaders
if (player != topUnit) then {
	((findDisplay 626262) displayCtrl 1601) ctrlShow false;
	((findDisplay 626262) displayCtrl 1601) ctrlEnable false;
};

// M12: per-unit loadout-listbox population (and the "disable delete for
// players" no-op, since players never get that control now) moved into
// functions/fn_rebuildRoster.sqf, which is called above and again on every
// roster change — this duplicate stale-'playerGroup' pass is removed.

lbAdd [6009, "Random"];
lbAdd [6009, "Ground"];
lbAdd [6009, "Air - HALO"];
lbAdd [6009, "Air - Helicopter"];
lbAdd [6009, "None"]; // M11: índice 4 — sem inserção (players ficam na staging area)
if (missionNamespace getVariable ["DRO_seaInsertViable", false]) then {
	lbAdd [6009, "Sea - Boat"]; // index 5 — only offered when a water corridor exists
};
if (player == _dialogPlayer) then {
	lbSetCurSel [6009, ([insertType, 1] select (insertType >= (lbSize 6009) || insertType < 0))];
};

// Insert vehicle options
if (player == _dialogPlayer) then {
	
	_validVehicles = if (missionPreset == 3) then {
		pCarClasses + pAPCClasses + pTankClasses + pArtyClasses + pHeliClasses;
	} else {
		pCarClasses + pHeliClasses;
	};
	{
		_thisIDC = _x;
		_thisIDCIndex = _forEachIndex;
		_index0 = lbAdd [_thisIDC, "Random"];
		lbSetData [_thisIDC, _index0, ""];		
		{
			_index = lbAdd [_thisIDC, ((configfile >> "CfgVehicles" >> _x >> "displayName") call BIS_fnc_getCfgData)];
			lbSetPicture [_thisIDC, _index, ((configfile >> "CfgVehicles" >> _x >> "icon") call BIS_fnc_getCfgData)];	
			lbSetPictureColor [_thisIDC, _index, [1, 1, 1, 1]];
			lbSetData [_thisIDC, _index, _x];			
			if ((startVehicles select _thisIDCIndex) == _x) then {
				lbSetCurSel [_thisIDC, _index];
			};						
		} forEach _validVehicles;
		if (lbCurSel _thisIDC == -1) then {
			lbSetCurSel [_thisIDC, _index0];
		};
	} forEach [6021, 6022];
};

// Support options
lbAdd [6010, "Random"];
lbAdd [6010, "Custom"];

if (player == _dialogPlayer) then {
	lbSetCurSel [6010, randomSupports];
	if ('SUPPLY' in customSupports) then {		
		((findDisplay 626262) displayCtrl 6011) ctrlSetTextColor [0.05, 1, 0.5, 1];
	};
	if ('ARTY' in customSupports) then {		
		((findDisplay 626262) displayCtrl 6012) ctrlSetTextColor [0.05, 1, 0.5, 1];
	};
	if ('CAS' in customSupports) then {		
		((findDisplay 626262) displayCtrl 6013) ctrlSetTextColor [0.05, 1, 0.5, 1];
	};
	if ('UAV' in customSupports) then {			
		((findDisplay 626262) displayCtrl 6014) ctrlSetTextColor [0.05, 1, 0.5, 1];
	};	
	if ((count pHeliClasses) == 0) then {
		ctrlEnable [6011, false];
		if ('SUPPLY' in customSupports) then {customSupports = customSupports - ['SUPPLY']};
	};
	if ((count (pMortarClasses + pArtyClasses)) == 0) then {
		ctrlEnable [6012, false];
		if ('ARTY' in customSupports) then {customSupports = customSupports - ['ARTY']};
	};
	if ((count availableCASClasses) == 0) then {
		ctrlEnable [6013, false];
		if ('CAS' in customSupports) then {customSupports = customSupports - ['CAS']};
	};
	if (({_x isKindOf "Plane"} count pUAVClasses) == 0) then {
		ctrlEnable [6014, false];
		if ('UAV' in customSupports) then {customSupports = customSupports - ['UAV']};
	};	
};

// If player is not _dialogPlayer then disable the shared (non-per-unit)
// controls below. Per-unit disabling (arsenal/remove-AI buttons on rows that
// aren't this client's own) is handled per-rebuild by
// functions/fn_rebuildRoster.sqf using the LIVE group, since 'playerGroup'
// here is a stale snapshot from mission boot that never reflects lobby-added
// AI (M12).
if (player != _dialogPlayer) then {
	ctrlEnable [6004, false];
	ctrlEnable [6005, false];
	ctrlEnable [6009, false];
	ctrlEnable [6010, false];
	ctrlEnable [6011, false];
	ctrlEnable [6012, false];
	ctrlEnable [6013, false];
	ctrlEnable [6014, false];
	ctrlEnable [6050, false];
	ctrlEnable [6021, false];
	ctrlEnable [6022, false];
};

// M12: the old "hide AI beyond preset default squad size" first-open trim
// (firstLobbyOpen) and the "un-hide controls for AI no longer in group" sweep
// belonged to the auto-fill-then-trim model this refactor replaces (REQ1: no
// AI exist by default, so there is nothing to trim). Removed. firstLobbyOpen
// itself is left alone (declared/publicVariable'd in start.sqf) in case other
// scripts still read it; it is simply no longer consumed here.

// Destroy camera and allow player control if lobby isn't complete and dialog is exited
waitUntil {!dialog};
if (((missionNameSpace getVariable "lobbyComplete") != 1)) then {	
	if (isNull (uiNamespace getVariable ["BIS_fnc_arsenal_cam", objNull ]) || isNull (findDisplay 1127001)) then {
		if (!visibleMap) then {
			camLobby cameraEffect ["terminate","back"];
			camUseNVG false;
			camDestroy camLobby;
			player switchCamera playerCameraView;
		};
	};	
};
// M10 REQ1: hint for any player who ESC'd the lobby before mission start
if ((missionNamespace getVariable ["lobbyComplete", 0]) != 1) then {
	hintSilent "Use 'Open Team Planning' scroll action to configure and start the mission";
};
