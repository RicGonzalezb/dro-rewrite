// Migrated from DRO_fnc_dragActionAdd — M3 CfgFunctions migration
private _id = (_this select 0) addAction [
		"Drag",
		{[_this select 0] call DRO_fnc_drag},
		nil,
		10,
		false,
		true,
		"",
		"alive _target && (_target getVariable ['rev_downed', false]) && !(_target getVariable ['rev_dragged', false]) && !(_target getVariable ['rev_beingRevived', false])",
		3,
		false];
	(_this select 0) setVariable ["rev_dragActionID", _id, true];
	[(format ["Revive: added drag action %2 for %1", (_this select 0), _id])] remoteExec ["diag_log", 2];
	//diag_log format ["Revive: added drag action %2 for %1", (_this select 0), _id];
