// Migrated from DRO_fnc_inputDaysData — M3 CfgFunctions migration
params ["_idc"];
	//_currentDaySelection = lbCurSel _idc;
	_currentDaySelection = profileNamespace getVariable ["DRO_day", 0];
	_days = [(date select 0), (date select 1)] call BIS_fnc_monthDays;	
	lbClear _idc;
	_daySelectionFound = false;
	for '_i' from 0 to _days step 1 do {
		if (_i == 0) then {
			lbAdd [_idc, "Random"];
		} else {
			lbAdd [_idc, str _i];
		};
		if (_i == _currentDaySelection) then {			
			lbSetCurSel [_idc, _i];
			_daySelectionFound = true;
		};
	};
	if !(_daySelectionFound) then {lbSetCurSel [_idc, 0];};
