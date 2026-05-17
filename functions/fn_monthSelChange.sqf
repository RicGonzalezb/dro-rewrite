// Migrated from DRO_fnc_monthSelChange — M3 CfgFunctions migration
params ["_data"];
	month = (_data select 1);
	publicVariable 'month';
	_newDate = date;
	_newDate set [1, month];
	[_newDate] remoteExec ['setDate', 0, true];
	[2301] call DRO_fnc_inputDaysData;
	profileNamespace setVariable ['DRO_month', (_data select 1)];
	if (menuComplete) then {
		sleep 0.4;
		[timeOfDay] remoteExec ['DRO_fnc_randomTime', 0, true]
	};
