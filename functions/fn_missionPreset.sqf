// Migrated from DRO_fnc_missionPreset — M3 CfgFunctions migration
params ["_preset"];
	/*
		lbSetCurSel [2107, aoOptionSelect];		
		sliderSetPosition [2111, 1*10];	//AI COUNT	
		lbSetCurSel [2113, minesEnabled];			
		lbSetCurSel [2115, civiliansEnabled];			
		lbSetCurSel [2119, stealthEnabled];				
		lbSetCurSel [2103, timeOfDay];		
		lbSetCurSel [2106, numObjectives];
	*/
	switch (_preset) do {
		case 1: {					
			["MAIN", 2020, 0] call DRO_fnc_switchButtonSet;
			sliderSetPosition [2041, 1*10];
			((findDisplay 52525) displayCtrl 2040) ctrlSetText "Enemy force size multiplier: x1.0";				
			["MAIN", 2050, 0] call DRO_fnc_switchButtonSet;
			["MAIN", 2060, 0] call DRO_fnc_switchButtonSet;
			["MAIN", 2070, 0] call DRO_fnc_switchButtonSet;
			["MAIN", 4010, 0] call DRO_fnc_switchButtonSet;				
			lbSetCurSel [2103, 0];							
			lbSetCurSel [2106, 0];
			preferredObjectives = [];
			profileNamespace setVariable ['DRO_objectivePrefs', preferredObjectives];
			{
				((findDisplay 52525) displayCtrl _x) ctrlSetTextColor [1, 1, 1, 1]
			} forEach [2200, 2201, 2202, 2203, 2204, 2207, 2210, 2211, 2212, 2213];			
		};
		case 2: {					
			["MAIN", 2020, 0] call DRO_fnc_switchButtonSet;
			sliderSetPosition [2041, 0.5*10];
			((findDisplay 52525) displayCtrl 2040) ctrlSetText "Enemy force size multiplier: x0.5";	
			["MAIN", 2050, 0] call DRO_fnc_switchButtonSet;			
			["MAIN", 2060, 0] call DRO_fnc_switchButtonSet;					
			["MAIN", 2070, 1] call DRO_fnc_switchButtonSet;	
			lbSetCurSel [2103, (selectRandom [3, 4])];		
			["MAIN", 4010, 1] call DRO_fnc_switchButtonSet;	
			preferredObjectives = ["HVT"];
			profileNamespace setVariable ['DRO_objectivePrefs', preferredObjectives];
			((findDisplay 52525) displayCtrl 2200) ctrlSetTextColor [0.05, 1, 0.5, 1];
			{			
				((findDisplay 52525) displayCtrl _x) ctrlSetTextColor [1, 1, 1, 1]
			} forEach [2201, 2202, 2203, 2204, 2207, 2210, 2211, 2212, 2213];			
		};
		case 3: {					
			["MAIN", 2020, 0] call DRO_fnc_switchButtonSet;
			sliderSetPosition [2041, 1*12.5];	
			((findDisplay 52525) displayCtrl 2040) ctrlSetText "Enemy force size multiplier: x1.25";	
			["MAIN", 2050, 0] call DRO_fnc_switchButtonSet;
			["MAIN", 2060, 0] call DRO_fnc_switchButtonSet;
			["MAIN", 2070, 0] call DRO_fnc_switchButtonSet;
			["MAIN", 4010, 0] call DRO_fnc_switchButtonSet;				
			lbSetCurSel [2103, 0];							
			lbSetCurSel [2106, 0];
			preferredObjectives = [];
			profileNamespace setVariable ['DRO_objectivePrefs', preferredObjectives];
			{
				((findDisplay 52525) displayCtrl _x) ctrlSetTextColor [1, 1, 1, 1]
			} forEach [2200, 2201, 2202, 2203, 2204, 2207, 2210, 2211, 2212, 2213];		
		};
		default {};
	};
