// Migrated from DRO_fnc_daySelChange — M3 CfgFunctions migration
params ["_data"];
	day = (_data select 1);
	publicVariable 'day';
	_newDate = date;
	_newDate set [2, day];
	[_newDate] remoteExec ['setDate', 0, true];
	profileNamespace setVariable ['DRO_day', (_data select 1)];
	if (menuComplete) then {
		sleep 0.4;
		[timeOfDay] remoteExec ['DRO_fnc_randomTime', 0, true]
	};
