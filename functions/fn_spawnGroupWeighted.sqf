// Migrated from DRO_fnc_spawnGroupWeighted — M3 CfgFunctions migration
params [["_pos", []], ["_side", enemySide], "_classes", "_weights", "_unitNumbers", ["_addToDyn", true], ["_singleUnitSpecial", "FORM"]];
	
	_unitArr = [];
	_unitArrWeights = [];
	
	if (_classes isEqualType "") then {
		_unitArr pushBack _classes;
		_unitArrWeights pushBack 1;
	} else {
		_unitArrIndex = [0, (count _classes -1)] call BIS_fnc_randomInt;
		_unitArr = (_classes select _unitArrIndex);
		_unitArrWeights = (_weights select _unitArrIndex);
	};
	
	if (count _pos > 0) then {
		// Get a random number of units to select between the boundaries
		_minUnits = (_unitNumbers select 0);
		if (_minUnits < 1) then {_minUnits = 1};
		_maxUnits = (_unitNumbers select 1);
		_limitUnits = [_minUnits, _maxUnits] call BIS_fnc_randomInt;
		
		_unitsToSpawn = [];
		for "_i" from 1 to _limitUnits do {
			_thisUnit = nil;
			if (count _unitArrWeights > 0) then {
				_thisUnit = _unitArr selectRandomWeighted _unitArrWeights;
			} else {
				_thisUnit = selectRandom _unitArr;
			};
			if (isNil _thisUnit) then {
				_unitsToSpawn pushBack _thisUnit;
			};
		};		
		_group = createGroup _side;
		_tempGroup = createGroup _side;	
		if (count _unitsToSpawn == 0) then {
			//_tempGroup createUnit [(_unitsToSpawn select 0), _pos, [], 0, _singleUnitSpecial];
			_tempGroup createUnit [(selectRandom ["I_L_Looter_SG_F","I_L_Looter_Rifle_F","I_C_Soldier_Bandit_1_F","I_C_Soldier_Bandit_4_F","I_C_Soldier_Bandit_7_F","I_C_Soldier_Para_7_F"]), _pos, [], 0, _singleUnitSpecial];
			["DRO: No valid units found for group %1 in faction %2! Spawned independent unit instead.", _tempGroup, enemyFaction] call BIS_fnc_error;
		} else {
			{
				_tempGroup createUnit [_x, _pos, [], 0, _singleUnitSpecial];
				diag_log format ["DRO: Spawned %1 for %2.", _x, _group];
			} forEach _unitsToSpawn;
		};
		units _tempGroup joinSilent _group;
		if (!isNil "aiSkill") then {
			[_group] call DRO_fnc_setSkillAction;
		};
		if (_addToDyn && dynamicSim == 0) then {
			_group enableDynamicSimulation true;
		};
		deleteGroup _tempGroup;
		_group;
	};
