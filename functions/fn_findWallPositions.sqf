// Migrated from DRO_fnc_findWallPositions — M3 CfgFunctions migration
params ["_building"];
	_buildingDir = getDir _building;
	private _posArr = [];
	private _return = [];
	for "_i" from 0 to 270 step 90 do {
		_thisPos = ([getPos _building, 20, _buildingDir+_i] call BIS_fnc_relPos);	
		_posArr pushBack [_thisPos, _i];	
	};
	{
		_thisPos = (_x select 0);
		_thisDir = (_x select 1);
		_thisPos set [2, 1.5];
		_buildingPos = getPos _building;
		_buildingPos set [2, 1.5];
		_intersects = lineIntersectsSurfaces [
			AGLToASL _thisPos,
			AGLToASL _buildingPos,
			objNull,
			objNull,
			true,
			1,
			"GEOM"
		];		
		{
			if ((_x select 2) == _building) then {
				_return pushBack [(ASLToAGL (_x select 0)), _thisDir];
			};
		} forEach _intersects; 
	} forEach _posArr;	
	_return
