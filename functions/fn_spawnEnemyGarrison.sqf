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
			if (!isNil "_group") then {
				_unit = ((units _group) select 0);
				_unit setUnitPos "UP";
				if (_garrisonCounter == 0) then {
					_leader = _unit;
				} else {
					[_unit] joinSilent _leader;
					//doStop _unit;
				};
			};
		};
		_garrisonCounter = _garrisonCounter + 1;
	} forEach _buildingPositions;
	
	if (!isNil "_leader") then {
		enemySemiAlertableGroups pushBack (group _leader);
	};
	enemyPosCollection pushBack (getPos _thisBuilding);
	group _leader
