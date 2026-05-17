// Migrated from DRO_fnc_replaceSimpleObject — M3 CfgFunctions migration
params ["_object"];	
	_vectorUp = (surfaceNormal (getPosATL _object));
	_simpleObject = [_object] call BIS_fnc_replaceWithSimpleObject;
	_simpleObject setVectorUp _vectorUp;	
	_simpleObject
