// Migrated from DRO_fnc_getTrueCargo — M3 CfgFunctions migration
private _allTurrets = ([(_this select 0)] call BIS_fnc_getTurrets);	
	private _cargoTurretCount = {([_x >> "isPersonTurret"] call BIS_fnc_getCfgData) == 1} count _allTurrets;
	diag_log format ["DRO_fnc_getTrueCargo: %1 = %2", (_this select 0), _cargoTurretCount];
	(_cargoTurretCount + ((configFile >> "CfgVehicles" >> (_this select 0) >> "transportSoldier") call BIS_fnc_GetCfgData))
