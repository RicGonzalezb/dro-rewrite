// Migrated from DRO_fnc_triggerAmbushSpawn — M3 CfgFunctions migration
params ["_pos", ["_spawnPosOverride", []]];
	_return = grpNull;
	_spawnPos = [];
	if (count _spawnPosOverride == 0) then {	
		_attempts = 0;
		_scan = true;
		while {_scan} do {
			_thisPos = [_pos, 250, 450, 2, 0, 1, 0] call BIS_fnc_findSafePos;
			//_terrainBlocked = terrainIntersect [_pos, _spawnPos];
			//if (_terrainBlocked) then {_scan = false};
			if ([objNull, "VIEW"] checkVisibility [_pos, _thisPos] < 0.2) then { _spawnPos = _thisPos; _scan = false;};		
			if (_attempts > 200) then {_scan = false};
			_attempts = _attempts + 1;
		};
	} else {
		_spawnPos = _spawnPosOverride;
	};
	if (count _spawnPos > 0) then {
		_numInf = round (([2,4] call BIS_fnc_randomInt) * aiMultiplier);			
		_spawnedSquad = nil;	
		_minAI = (round ((4 * aiMultiplier) / (0.4 * _numInf)) min 6);
		_maxAI = (round ((6 * aiMultiplier) / (0.4 * _numInf)) min 8);
		_spawnedSquad = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI], false] call DRO_fnc_spawnGroupWeighted;
		// M6: spawnGroupWeighted é síncrono — waitUntil era relic. Substituído por guard direto.
		//     !isNil não captura grpNull; adicionado !isNull explícito.
		if (isNil "_spawnedSquad" || {isNull _spawnedSquad}) exitWith {
			diag_log "DRO: triggerAmbushSpawn — spawnGroupWeighted retornou nil/grpNull, abortando ambush.";
		};
		if (DRO_lambsCompat) then {
			// LAMBS soft-compat: CREEP — stalk from the hidden spawn, close in, then unleash.
			// Matches the ambush intent (group spawned outside player LOS). Range ~800 covers the 250-450m spawn.
			[_spawnedSquad, 800] spawn lambs_wp_fnc_taskCreep;
		} else {
			_spawnedSquad setBehaviour "AWARE";
			_spawnedSquad setSpeedMode "FULL";
			{_x doMove (_pos getPos [10, (random 360)])} forEach (units _spawnedSquad);
		};
		/*
		_wpStart = _spawnedSquad addWaypoint[(getPos (leader _spawnedSquad)), 0];
		_wpStart setWaypointBehaviour "AWARE";	
		_wpStart setWaypointType "MOVE";
		_wpStart setWaypointSpeed "FULL";
		
		_wp1 = _spawnedSquad addWaypoint[_pos, 0];								
		_wp1 setWaypointType "MOVE";
		*/
		diag_log "DRO: Spawned ambush attack";
		_return = _spawnedSquad;
	} else {	
		diag_log "DRO: Could not find valid hidden spawn position";
	};
	_return
