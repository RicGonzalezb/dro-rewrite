// Migrated from DRO_fnc_createVehicleCrew — M3 CfgFunctions migration
params ["_vehicle", ["_side", enemySide], ["_enableDynSim", true]];
	createVehicleCrew _vehicle;	
	private _group = createGroup _side;
	(crew _vehicle) joinSilent _group;
	if (dynamicSim == 0 && _enableDynSim) then {
		_group enableDynamicSimulation true;
	};
