// Migrated from DRO_fnc_getCfgSide — M3 CfgFunctions migration
params ["_sideValue"];
	private _return = west;	
	if (typeName _sideValue == "TEXT") then {
		if ((["west", _sideValue, false] call BIS_fnc_inString)) then {
			_sideValue = 1;
		};
		if ((["east", _sideValue, false] call BIS_fnc_inString)) then {
			_sideValue = 0;
		};
		if ((["guer", _sideValue, false] call BIS_fnc_inString) || (["ind", _sideValue, false] call BIS_fnc_inString)) then {
			_sideValue = 2;
		};
	};			
	if (typeName _sideValue == "SCALAR") then {
		if (_sideValue <= 3 && _sideValue > -1) then {
			switch (_sideValue) do {
				case 0: {_return = east};
				case 1: {_return = west};
				case 2: {_return = resistance};
				case 3: {_return = civilian};
			};
		};	
	};	
	_return
