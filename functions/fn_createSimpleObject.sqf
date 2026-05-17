// Migrated from DRO_fnc_createSimpleObject — M3 CfgFunctions migration
params ["_class", "_pos", ["_dir", 0], ["_special", "CAN_COLLIDE"], "_object"];
	_pos set [2, 0];
	_object = createVehicle [_class, _pos, [], 0, _special];		
	_object setDir _dir;
	if (isNil "DRO_simpleObjects") then {DRO_simpleObjects = [_object]} else {DRO_simpleObjects pushBack _object};
	/*
	_vectorUp = (surfaceNormal (getPosATL _object));
	_simpleObject = [_object] call BIS_fnc_replaceWithSimpleObject;
	_simpleObject setVectorUp _vectorUp;
	_simpleObject
	*/
	_object
