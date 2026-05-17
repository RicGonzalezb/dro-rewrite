// Migrated from DRO_fnc_setSkillAction — M3 CfgFunctions migration
switch (aiSkill) do {
		case 0: {
			if (typeName (_this select 0) == "OBJECT") then {
				_unit = (_this select 0);
				_unit setSkill ["aimingAccuracy", random [0.06, 0.08, 0.1]];
				_unit setSkill ["aimingShake", random [0.01, 0.03, 0.05]];
				_unit setSkill ["aimingSpeed", random [0.08, 0.12, 0.16]];
				_unit setSkill ["spotDistance", random [0.2, 0.3, 0.4]];
				_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
				_unit setSkill ["general", random [0.2, 0.3, 0.4]];
				_unit setSkill ["courage", random [0.1, 0.2, 0.3]];
				_unit setSkill ["reloadSpeed", random [0.1, 0.15, 0.2]];
			};
			if (typeName (_this select 0) == "GROUP") then {		
				{
					_unit = _x;
					_unit setSkill ["aimingAccuracy", random [0.06, 0.08, 0.1]];
					_unit setSkill ["aimingShake", random [0.01, 0.03, 0.05]];
					_unit setSkill ["aimingSpeed", random [0.08, 0.12, 0.16]];
					_unit setSkill ["spotDistance", random [0.2, 0.3, 0.4]];
					_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
					_unit setSkill ["general", random [0.2, 0.3, 0.4]];
					_unit setSkill ["courage", random [0.1, 0.2, 0.3]];
					_unit setSkill ["reloadSpeed", random [0.1, 0.15, 0.2]];
				} forEach (units (_this select 0));
			};
		};
		case 1: {
			if (typeName (_this select 0) == "OBJECT") then {
				_unit = (_this select 0);
				_unit setSkill ["aimingAccuracy", random [0.1, 0.15, 0.2]];
				_unit setSkill ["aimingShake", random [0.05, 0.07, 0.1]];
				_unit setSkill ["aimingSpeed", random [0.12, 0.16, 0.2]];
				_unit setSkill ["spotDistance", random [0.25, 0.33, 0.5]];
				_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
				_unit setSkill ["general", random [0.4, 0.5, 0.6]];
				_unit setSkill ["courage", random [0.2, 0.3, 0.4]];
				_unit setSkill ["reloadSpeed", random [0.15, 0.2, 0.25]];
			};
			if (typeName (_this select 0) == "GROUP") then {		
				{
					_unit = _x;
					_unit setSkill ["aimingAccuracy", random [0.1, 0.15, 0.2]];
					_unit setSkill ["aimingShake", random [0.05, 0.07, 0.1]];
					_unit setSkill ["aimingSpeed", random [0.12, 0.16, 0.2]];
					_unit setSkill ["spotDistance", random [0.25, 0.33, 0.5]];
					_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
					_unit setSkill ["general", random [0.4, 0.5, 0.6]];
					_unit setSkill ["courage", random [0.2, 0.3, 0.4]];
					_unit setSkill ["reloadSpeed", random [0.15, 0.2, 0.25]];
				} forEach (units (_this select 0));
			};
		};
		default {};
	};
