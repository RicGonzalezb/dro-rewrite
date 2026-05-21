// Migrated from DRO_fnc_checkVehicleSpawn — M3 CfgFunctions migration
// Hotfix M3: macro `aliveVeh` precisa estar definido no escopo desta função
// (CfgFunctions compila o arquivo isolado, sem ver #defines do caller).
// Hotfix M6: adicionado _vehicleType nos params (era escopo herdado via #include no original).
//            Adicionado guard para _vehicleType vazio (callers atuais não passam tipo = recreate inativo).
#define aliveVeh(none) (none getHitPointDamage "hitHull") < 0.7
params [["_vehicle", objNull], ["_vehicleType", ""]];
	if (!isNull _vehicle) then {
		//if (!aliveVeh(_vehicle)) then { //#LordShadeAceVeh
		if (!(aliveVeh(_vehicle))) then { //#LordShadeAceVeh
			if (_vehicleType isEqualTo "") exitWith { _vehicle = objNull };
			_thisPos = (getPos _vehicle) findEmptyPosition [15, 200, _vehicleType];
			if (count _thisPos > 0) then {
				_vehicle = _vehicleType createVehicle _thisPos;
			} else {
				_vehicle = objNull;
			};
		};
	};
	_vehicle;
