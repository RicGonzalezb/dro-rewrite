// Migrated from DRO_fnc_lobbyReadyButton — M3 CfgFunctions migration
if (player getVariable ['startReady', false]) then {
		player setVariable ['startReady', false, true];
		((findDisplay 626262) displayCtrl 1601) ctrlSetEventHandler ["MouseEnter", "(_this select 0) ctrlsettextcolor [0,0,0,1]"];
		((findDisplay 626262) displayCtrl 1601) ctrlSetEventHandler ["MouseExit", "(_this select 0) ctrlsettextcolor [1,1,1,1]"];
		((findDisplay 626262) displayCtrl 1601) ctrlSetTextColor [0,0,0,1];
	} else {
		player setVariable ['startReady', true, true];
		((findDisplay 626262) displayCtrl 1601) ctrlSetEventHandler ["MouseEnter", "(_this select 0) ctrlsettextcolor [0.04, 0.7, 0.4, 1]"];
		((findDisplay 626262) displayCtrl 1601) ctrlSetEventHandler ["MouseExit", "(_this select 0) ctrlsettextcolor [0.05, 1, 0.5, 1]"];
		((findDisplay 626262) displayCtrl 1601) ctrlSetTextColor [0.05, 1, 0.5, 1];
	};
