// Migrated from DRO_fnc_getRoadDir — M3 CfgFunctions migration
params ["_road", "_roadsConnectedTo", "_connectedRoad", "_dir"];
	if (_road isEqualType []) then {
		_road = ((_road nearRoads 10) select 0);
	};
	_roadsConnectedTo = roadsConnectedTo _road;
	_dir = if (count _roadsConnectedTo > 0) then {
		_connectedRoad = _roadsConnectedTo select 0;
		[_road, _connectedRoad] call BIS_fnc_DirTo
	} else {
		(random 360)
	};
	_dir
