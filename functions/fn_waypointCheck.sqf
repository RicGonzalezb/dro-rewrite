// Migrated from DRO_fnc_waypointCheck — M3 CfgFunctions migration
params ["_group", "_waypoints"];	
	_pos = getPos leader _group;
	sleep 30;
	if (alive leader _group) then {
		if (getPos leader _group distance _pos < 30) then {			
			while {(count (waypoints _group)) > 0} do {
				deleteWaypoint ((waypoints _group) select 0);
			};
			{
				_group addWaypoint [(_x select 0), (_x select 1)];
			} forEach _waypoints;
		};
	};
