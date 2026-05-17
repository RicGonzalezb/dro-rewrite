// Migrated from DRO_fnc_checkVehicleSpawn — M3 CfgFunctions migration
params [["_vehicle", objNull]];
	if (!isNull _vehicle) then {
		//if (!aliveVeh(_vehicle)) then { //#LordShadeAceVeh
		if (!(aliveVeh(_vehicle))) then { //#LordShadeAceVeh
			_thisPos = (getPos _vehicle) findEmptyPosition [15, 200, _vehicleType];
			if (count _thisPos > 0) then {
				_vehicle = _vehicleType createVehicle _thisPos;
			} else {
				_vehicle = objNull;
			};
		};
	};
	_vehicle;
