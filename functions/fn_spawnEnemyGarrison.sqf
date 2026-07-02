// Migrated from DRO_fnc_spawnEnemyGarrison — M3 CfgFunctions migration
_thisBuilding = _this select 0;	
	/*
	_garMarker = createMarker [format["garMkr%1", random 10000], getPos _thisBuilding];
	_garMarker setMarkerShape "ICON";
	_garMarker setMarkerColor "ColorOrange";
	_garMarker setMarkerType "mil_dot";
	*/
	_buildingPositions = [_thisBuilding] call BIS_fnc_buildingPositions;	
	_totalGarrison = [0, ((count _buildingPositions) min 2)] call BIS_fnc_randomInt;
	
	_garrisonCounter = 0;
	_leader = nil;
	{
		if (_garrisonCounter <= _totalGarrison) then {
			_group = [_x, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call DRO_fnc_spawnGroupWeighted;
			// Hotfix: spawnGroupWeighted pode retornar grpNull (não nil) quando falha — adicionar
			// guards extras para evitar undefined _unit. Bug latente do código original.
			if (!isNil "_group" && {!isNull _group} && {count (units _group) > 0}) then {
				private _unit = ((units _group) select 0);
				_unit setUnitPos "UP";
				if (isNil "_leader") then {
					_leader = _unit;
				} else {
					[_unit] joinSilent (group _leader);
					//doStop _unit;
				};
			};
		};
		_garrisonCounter = _garrisonCounter + 1;
	} forEach _buildingPositions;
	
	if (!isNil "_leader") then {
		enemySemiAlertableGroups pushBack (group _leader);
		// LAMBS soft-compat: garrison leader broadcasts contact at radio range so distant
		// reinforcement-enabled patrols are summoned when the garrisoned objective is engaged.
		if (DRO_lambsCompat) then {
			_leader setVariable ["lambs_danger_dangerRadio", true, true];
		};
	};
	enemyPosCollection pushBack (getPos _thisBuilding);
	if (!isNil "_leader") then { group _leader } else { grpNull }
