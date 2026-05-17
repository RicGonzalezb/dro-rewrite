// Migrated from DRO_fnc_reviveActionAdd — M3 CfgFunctions migration
private _id = [
		(_this select 0),
		"Revive",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\u100_ca.paa",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\r100_ca.paa",
		"((_this distance _target) < 3) && (alive _target) && (_target getVariable ['rev_downed', false]) && !(_target getVariable ['rev_dragged', false])",
		"((_caller distance _target) < 3) && (alive _target) && (_target getVariable ['rev_downed', false]) && !(_target getVariable ['rev_dragged', false])",
		{(_this select 0) setVariable ["rev_beingRevived", true, true]},
		{},
		{			
			[(_this select 0), (_this select 1)] remoteExec ["DRO_fnc_reviveUnit", (_this select 1)];
		},
		{(_this select 0) setVariable ["rev_beingRevived", false, true]},
		[],
		reviveTime,
		1000,
		false,
		false
	] call BIS_fnc_holdActionAdd;
	diag_log format ["Revive: Revive action ID %1 added for unit %1", _id, (_this select 0)];
	[(format ["Revive: Revive action ID %1 added for unit %1", _id, (_this select 0)])] remoteExec ["diag_log", 2];
	(_this select 0) setVariable ["rev_holdActionID", _id, true];
