// Migrated from DRO_fnc_addResetAction — M3 CfgFunctions migration
params ["_unit"];	
	[
		_unit,
		[
			"Reset Unit",
			{[_this select 0, _this select 1] execVM "sunday_system\player_setup\resetAIAction.sqf"},
			nil,
			20,
			false,
			true,
			"",
			"_this == _target"
		]	
	] remoteExec ["addAction", 0, true];
