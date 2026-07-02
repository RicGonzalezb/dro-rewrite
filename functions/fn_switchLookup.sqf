// Migrated from DRO_fnc_switchLookup — M3 CfgFunctions migration
params ["_table", "_idc"];
	_return = [];	
	switch (_table) do {
		case "MAIN": {
			switch (_idc) do {
				case 2020: {
					_return pushBack "aoOptionSelect";
					_return pushBack aoOptionSelect;
					_return pushBack ["ENABLED", "DISABLED"];
				};
				case 2030: {
					_return pushBack "aiSkill";
					_return pushBack aiSkill;			
					_return pushBack ["NORMAL", "HARD", "CUSTOM"];
				};
				case 2050: {
					_return pushBack "minesEnabled";
					_return pushBack minesEnabled;
					_return pushBack ["DISABLED", "ENABLED"];
				};
				case 2060: {
					_return pushBack "civiliansEnabled";
					_return pushBack civiliansEnabled;
					_return pushBack ["RANDOM", "ENABLED", "ENABLED & HOSTILE", "DISABLED"];
				};
				case 2065: {
					_return pushBack "civiliansAsAgents";
					_return pushBack civiliansAsAgents;
					_return pushBack ["ENABLED", "DISABLED"];
				};
				case 2085: {
					_return pushBack "arsenalEnabled";
					_return pushBack arsenalEnabled;
					_return pushBack ["ENABLED", "DISABLED"];
				};
				case 2070: {
					_return pushBack "stealthEnabled";
					_return pushBack stealthEnabled;
					_return pushBack ["RANDOM", "ENABLED", "DISABLED"];
				};
				case 2080: {
					_return pushBack "reviveDisabled";
					_return pushBack reviveDisabled;
					_return pushBack ["300 SECONDS", "120 SECONDS", "60 SECONDS", "DISABLED"];
				};
				case 2090: {
					_return pushBack "missionPreset";
					_return pushBack missionPreset;
					_return pushBack ["CURRENT SETTINGS", "RECON OPS", "SNIPER OPS", "COMBINED ARMS"];
				};
				case 2400: {
					_return pushBack "dynamicSim";
					_return pushBack dynamicSim;
					_return pushBack ["ENABLED", "DISABLED"];
				};
				case 3010: {
					_return pushBack "timeOfDay";
					_return pushBack timeOfDay;
					//_return pushBack ["RANDOM", "DAWN", "DAY", "DUSK", "NIGHT"];
					_return pushBack ["RANDOM", "DAWN", "MORNING", "MIDDAY", "AFTERNOON", "DUSK", "EVENING", "MIDNIGHT"];
				};
				case 3020: {
					_return pushBack "weatherOvercast";
					_return pushBack weatherOvercast;
					_return pushBack ["RANDOM", "CUSTOM"];
				};
				case 3030: {
					_return pushBack "animalsEnabled";
					_return pushBack animalsEnabled;
					_return pushBack ["ENABLED", "DISABLED"];
				};
				case 3040: {
					_return pushBack "staminaDisabled";
					_return pushBack staminaDisabled;
					_return pushBack ["ENABLED", "DISABLED"];
				};
				case 4010: {
					_return pushBack "numObjectives";
					_return pushBack numObjectives;
					_return pushBack ["RANDOM", "1", "2", "3", "4", "5"];
				};
			};			
		};
		case "LOBBY": {
			
		};
	};
	_return
