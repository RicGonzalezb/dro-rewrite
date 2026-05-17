// Migrated from DRO_fnc_switchButtonWeather — M3 CfgFunctions migration
params ["_table", "_idc", ["_change", true], ["_setVal", -1]];	
	_optionData = [_table, _idc] call DRO_fnc_switchLookup;
	//diag_log _optionData;
	_varStr = (_optionData select 0);
	_currentIndex = (_optionData select 1);
	if (_currentIndex isEqualType "") then {
		weatherOvercast = 'RANDOM';
		_currentIndex = 0;
	} else {
		if (_currentIndex == 0) then {
			weatherOvercast = 'RANDOM';
		} else {
			weatherOvercast = (round (((sliderPosition 2109)/10) * (10 ^ 3)) / (10 ^ 3));
			//_currentIndex = 1;
		};
	};	
	if (typeName weatherOvercast isEqualTo 'SCALAR') then {
		[weatherOvercast] call BIS_fnc_setOvercast;
	};
	_allValues = (_optionData select 2);
	_newIndex = -1;
	if (_setVal == -1) then {
		if (_change) then {
			if (ctrlText (_idc + 3) == "RANDOM") then {
				_newIndex = 1
			} else {
				_newIndex = 0;
				weatherOvercast = 'RANDOM';
			};	
		} else {
			_newIndex = 0;
			weatherOvercast = 'RANDOM';
		};
	} else {
		_newIndex = _setVal;
	};
	publicVariable 'weatherOvercast';
	profileNamespace setVariable ['DRO_weatherOvercast', weatherOvercast];	
	ctrlSetText [(_idc + 3), (_allValues select _newIndex)];
