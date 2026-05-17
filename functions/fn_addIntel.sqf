// Migrated from DRO_fnc_addIntel — M3 CfgFunctions migration
_intelObject = _this select 0;
	_taskName = _this select 1;
	_intelObject setVariable ["task", _taskName];	
	_intelObject addAction [
		"Collect Intel",
		{
			[_this select 3, 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
			missionNamespace setVariable [format ["%1Completed", (_this select 3)], 1, true];
			deleteVehicle (_this select 0);
			[5, false, (_this select 1)] execVM "sunday_system\intel\revealIntel.sqf";			
		},
		_taskName,
		6,
		true,
		true,
		"",
		"true",
		5
	];
