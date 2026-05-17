// Migrated from DRO_fnc_extendPos — M3 CfgFunctions migration
//private ["_extendCenter", "_dist", "angle", "_x2", "_y2"];
	//_extendCenter = (_this select 0);
	//_dist = (_this select 1);
	//_angle = (_this select 2);
	_x2 = (((_this select 0) select 0) + ((cos (90-(_this select 2))) * (_this select 1)));
	_y2 = (((_this select 0) select 1) + ((sin (90-(_this select 2))) * (_this select 1)));
	[_x2, _y2, 0];
