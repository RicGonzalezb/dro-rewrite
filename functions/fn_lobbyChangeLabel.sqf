// Migrated from DRO_fnc_lobbyChangeLabel — M3 CfgFunctions migration
disableSerialization;
	params ["_display", "_idc", "_label"];
	if (!isNil "_idc") then {
		if ((ctrlClassName ((findDisplay _display) displayCtrl _idc) == "sundayText") OR (ctrlClassName ((findDisplay _display) displayCtrl _idc) == "sundayTextMT")) then {
			((findDisplay _display) displayCtrl _idc) ctrlSetText _label;
		};
	};
