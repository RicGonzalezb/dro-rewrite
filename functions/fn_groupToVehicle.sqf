// Migrated from DRO_fnc_groupToVehicle — M3 CfgFunctions migration
params ["_group", "_vehicle", ["_cargoOnly", false]];
	
	if (typeName _group == "GROUP") then {
		_group = units _group;
	};
	diag_log format ["DRO_fnc_groupToVehicle called for %1", _group];
	
	_commanderPositions = _vehicle emptyPositions "Commander";
	_driverPositions = _vehicle emptyPositions "Driver";
	_gunnerPositions = _vehicle emptyPositions "Gunner";
	
	if (_cargoOnly) then {
		_commanderPositions = 0;
		_driverPositions = 0;	
		_gunnerPositions = 0;
	};	
	
	_cargoPositions = _vehicle emptyPositions "Cargo";	
	//diag_log format ["DRO_fnc_groupToVehicle: commander slots = %1", _commanderPositions];
	//diag_log format ["DRO_fnc_groupToVehicle: driver slots = %1", _driverPositions];
	//diag_log format ["DRO_fnc_groupToVehicle: gunner slots = %1", _gunnerPositions];
	//diag_log format ["DRO_fnc_groupToVehicle: cargo slots = %1", _cargoPositions];
	{
		_unit = _x;
		diag_log format ["DRO_fnc_groupToVehicle: assigning %1", _unit];
		if (_commanderPositions > 0) then {			
			_unit assignAsCommander _vehicle;			
			[_unit, _vehicle] remoteExecCall ["moveInCommander", _unit];
			//diag_log format ["DRO_fnc_groupToVehicle: remote %1 moveInCommander to %2", _unit, _vehicle];						
			_commanderPositions = _commanderPositions - 1;			
		} else {
			if (_driverPositions > 0) then {			
				_unit assignAsDriver _vehicle;				
				[_unit, _vehicle] remoteExecCall ["moveInDriver", _unit];
				//diag_log format ["DRO_fnc_groupToVehicle: remote %1 moveInDriver to %2", _unit, _vehicle];			
				_driverPositions = _driverPositions - 1;			
			} else {
				if (_gunnerPositions > 0) then {			
					_unit assignAsGunner _vehicle;					
					[_unit, _vehicle] remoteExecCall ["moveInGunner", _unit];
					//diag_log format ["DRO_fnc_groupToVehicle: remote %1 moveInDriver to %2", _unit, _vehicle];					
					_gunnerPositions = _gunnerPositions - 1;			
				} else {
					if (_cargoPositions > 0) then {			
						_unit assignAsCargo _vehicle;						
						[_unit, _vehicle] remoteExecCall ["moveInCargo", _unit];
						//diag_log format ["DRO_fnc_groupToVehicle: remote %1 moveInDriver to %2", _unit, _vehicle];						
						_cargoPositions = _cargoPositions - 1;			
					};
				};
			};
		};		
		waitUntil {vehicle _unit != _unit};
	} forEach _group;
