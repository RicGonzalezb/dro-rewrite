// Migrated from DRO_fnc_suicideActionAdd — M3 CfgFunctions migration
private ["_id"];
	_id = [
		(_this select 0),
		"Suicide",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d50_ca.paa",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d100_ca.paa",
		"alive _target",
		"alive _target",
		{},
		{},
		{			
			(_this select 0) setDamage 1;
			//[(_this select 0), (_this select 2)] remoteExec ["bis_fnc_holdActionRemove", 0, true];			
		},
		{},
		[],
		3,
		1000,
		true,
		true
	] call BIS_fnc_holdActionAdd;
	[(format ["Revive: Suicide action ID %1 added for unit %1", _id, (_this select 0)])] remoteExec ["diag_log", 2];
	_id
