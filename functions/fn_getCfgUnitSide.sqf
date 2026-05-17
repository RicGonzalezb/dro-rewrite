// Migrated from DRO_fnc_getCfgUnitSide — M3 CfgFunctions migration
params ["_configName"];
	private _return = west;
	_sideNum = (((configFile >> "CfgVehicles" >> _configName >> "side")) call BIS_fnc_GetCfgData);
	if (!isNil "_sideNum") then {
		if (typeName _sideNum == "TEXT") then {
			if ((["west", _sideNum, false] call BIS_fnc_inString)) then {
				_sideNum = 1;
			};
			if ((["east", _sideNum, false] call BIS_fnc_inString)) then {
				_sideNum = 0;
			};
			if ((["guer", _sideNum, false] call BIS_fnc_inString) || (["ind", _sideNum, false] call BIS_fnc_inString)) then {
				_sideNum = 2;
			};
		};			
		if (typeName _sideNum == "SCALAR") then {
			if (_sideNum <= 3 && _sideNum > -1) then {
				switch (_sideNum) do {
					case 0: {_return = east};
					case 1: {_return = west};
					case 2: {_return = resistance};
					case 3: {_return = civilian};
				};
			};	
		};
	};
	_return
