// Migrated from DRO_fnc_getUnitPositionId — M3 CfgFunctions migration
private ["_vvn", "_str"];
	_vvn = vehicleVarName (_this select 0);
	(_this select 0) setVehicleVarName "";
	_str = str (_this select 0);
	(_this select 0) setVehicleVarName _vvn;
	parseNumber (_str select [(_str find ":") + 1]);
