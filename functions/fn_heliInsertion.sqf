// Migrated from DRO_fnc_heliInsertion — M3 CfgFunctions migration
_heli = _this select 0;
	_insertPos = _this select 1;
	_type = _this select 2;
	
	diag_log format ["DRO: Init heli insertion with heli %1 to %2", _heli, _insertPos];
	
	_heliGroup = (group _heli);
	_startPos = [((getPos _heli) select 0), ((getPos _heli) select 1), ((getPos _heli) select 2)];
	_height = getTerrainHeightASL _insertPos; 
	_insertPosHigh = [(_insertPos select 0), (_insertPos select 1), _height+150];
	
	_flyDir = [_startPos, _insertPosHigh] call BIS_fnc_dirTo;
	_flyByPosExtend = [_insertPosHigh, 3000, _flyDir] call DRO_fnc_extendPos;
	_flyByPos = [(_flyByPosExtend select 0), (_flyByPosExtend select 1), 200];
	
	_heli flyInHeight 200;
	_heliGroup = (group _heli);
	
	_driver = driver _heli;
	_heliGroup setBehaviour "careless";
    _driver disableAI "FSM";
    _driver disableAI "Target";
    _driver disableAI "AutoTarget";
	
	// Clear current waypoints
	while {(count (waypoints _heliGroup)) > 0} do {
		deleteWaypoint ((waypoints _heliGroup) select 0);
	};
	
	_wp0 = _heliGroup addWaypoint [_startPos, 0];
	_wp0 setWaypointSpeed "FULL";
	_wp0 setWaypointType "MOVE";
	_wp0 setWaypointBehaviour "COMBAT";
	
	_wp1 = _heliGroup addWaypoint [_flyByPos, 0];
	_wp1 setWaypointSpeed "FULL";
	_wp1 setWaypointType "MOVE";
	
	_trgEject = createTrigger ["EmptyDetector", _insertPosHigh];
	_trgEject setTriggerArea [800, 50, _flyDir, false];
	_trgEject setTriggerActivation ["ANY", "PRESENT", false];
	_trgEject setTriggerStatements ["(thisTrigger getVariable 'heli') in thisList", "[(assignedCargo (thisTrigger getVariable 'heli'))] execVM 'sunday_system\player_setup\callParadrop.sqf';", ""];
	_trgEject setVariable ["heli", _heli];
	
	_trgDelete = createTrigger ["EmptyDetector", _flyByPos];
	_trgDelete setTriggerArea [100, 100, 0, false];
	_trgDelete setTriggerActivation ["ANY", "PRESENT", false];
	_trgDelete setTriggerStatements ["(thisTrigger getVariable 'heli') in thisList", "deleteVehicle (thisTrigger getVariable 'heli');", ""];
	_trgDelete setVariable ["heli", _heli];
	
	
	diag_log format ["DRO: heli waypoints %1, %2", waypointPosition [_heliGroup, 0], waypointPosition [_heliGroup, 1]];
