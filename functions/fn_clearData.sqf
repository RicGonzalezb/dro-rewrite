// Migrated from DRO_fnc_clearData — M3 CfgFunctions migration
// Faction data
	lbSetCurSel [1301, 1];
	lbSetCurSel [1310, 2];
	lbSetCurSel [1321, 0];
	lbSetCurSel [3800, 0];
	lbSetCurSel [3801, 0];
	lbSetCurSel [3802, 0];
	lbSetCurSel [3803, 0];
	lbSetCurSel [3804, 0];
	lbSetCurSel [3805, 0];
	
	// Other data
	//lbSetCurSel [2103, 0];
	lbSetCurSel [2104, 0];		
	lbSetCurSel [2106, 0];
	//lbSetCurSel [2116, 0];
	["MAIN", 2020, 1] call DRO_fnc_switchButtonSet;
	["MAIN", 2030, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 2050, 0] call DRO_fnc_switchButtonSet;		
	["MAIN", 2060, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 2065, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 2085, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 2070, 0] call DRO_fnc_switchButtonSet;
	
	if (DRO_aceMedical) then {
		["MAIN", 2080, 3] call DRO_fnc_switchButtonSet;
	} else {
		["MAIN", 2080, 0] call DRO_fnc_switchButtonSet;
	};
	
	["MAIN", 2090, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 2400, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 3010, 0] call DRO_fnc_switchButtonSet;
	['MAIN', 3020, false, 0] call DRO_fnc_switchButtonWeather;
	["MAIN", 3030, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 3040, 0] call DRO_fnc_switchButtonSet;
	["MAIN", 4010, 0] call DRO_fnc_switchButtonSet;
	sliderSetPosition [2041, 1*10];
	sliderSetPosition [2109, 3];
	[2301] call DRO_fnc_inputDaysData;	
	
	pFactionIndex = 1;
	publicVariable "pFactionIndex";
	playersFactionAdv = [0,0,0];
	publicVariable "playersFactionAdv";
	eFactionIndex = 2;
	publicVariable "eFactionIndex";
	enemyFactionAdv = [0,0,0];
	publicVariable "enemyFactionAdv";
	cFactionIndex = 0;
	publicVariable "cFactionIndex";
	
	month = 0;
	profileNamespace setVariable ["DRO_month", nil];
	publicVariable "month";
	day = 0;
	profileNamespace setVariable ["DRO_day", nil];
	publicVariable "day";
	preferredObjectives = [];
	publicVariable "preferredObjectives";	
	customPos = [];
	publicVariable "customPos";	
	
	profileNamespace setVariable ["DRO_playersFaction", nil];
	profileNamespace setVariable ["DRO_enemyFaction", nil];
	profileNamespace setVariable ['DRO_objectivePrefs', nil];
	
	deleteMarker 'aoSelectMkr';
	aoName = nil;	
	ctrlSetText [2300, 'AO location: RANDOM'];
	selectedLocMarker setMarkerColor 'ColorPink';
	
	{
		((findDisplay 52525) displayCtrl _x) ctrlSetTextColor [1, 1, 1, 1];
	} forEach [2200, 2201, 2202, 2203, 2204, 2207, 2210, 2211, 2212, 2213];
