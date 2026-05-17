// Migrated from DRO_fnc_loadoutCompat — M3 CfgFunctions migration
params ["_thisUnit"];
	//detect ALiVE ORBAT loadout
	if (isNil {((configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "ALiVE_orbatCreator_owned") call BIS_fnc_getCfgData)}) then {
		diag_log format ["DRO: %1 is not ORBAT configured", _thisUnit];
	} else {
		_ALiVE_orbatCreator_loadout = ((configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "ALiVE_orbatCreator_loadout") call BIS_fnc_getCfgData);
		_thisUnit setUnitLoadout _ALiVE_orbatCreator_loadout;
		diag_log format ["DRO: %1 has an ORBAT configuration copied to loadout", _thisUnit];
	};
	//fix for 3CB Factions missing inventory
	if (isNil {((configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_alloweduniform") call BIS_fnc_getCfgData)}) then {
		diag_log format ["DRO: %1 is not a 3CB Faction unit", _thisUnit];
	} else {
		//read in allowed gear from unit config entry arrays
		//randomize
		private _uk3cb_faction_backpack = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_allowedbackpack") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_facewear = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_allowedfacewear") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_headgear = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_allowedheadgear") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_uniform = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_alloweduniform") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_vest = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_allowedvest") call BIS_fnc_getCfgDataArray;
		//add all
		private _uk3cb_faction_ace_backpack = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_ace_backpack") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_ace_gear = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_ace_gear") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_magazines = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_magazines") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_magazines_backpack = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_magazines_backpack") call BIS_fnc_getCfgDataArray;
		//conditional
		private _uk3cb_faction_nightTime_items = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_nightTime_items") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_reduced_medical_items = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_reduced_medical_items") call BIS_fnc_getCfgDataArray;
		//not used in DRO ACE
		private _uk3cb_faction_vanilla_backpack = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_vanilla_backpack") call BIS_fnc_getCfgDataArray;
		private _uk3cb_faction_vanilla_gear = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_vanilla_gear") call BIS_fnc_getCfgDataArray;
		//randomized add/remove
		private _uk3cb_faction_variable_items = (configFile >> "CfgVehicles" >> (_thisUnit getVariable ["unitClass",""]) >> "UK3CB_loadout_variable_items") call BIS_fnc_getCfgDataArray;
		
		//select and apply gear
		removeBackpack _thisUnit;
		_thisUnit addBackpack (selectRandom _uk3cb_faction_backpack);
		_thisUnit addGoggles (selectRandom _uk3cb_faction_facewear);
		_thisUnit addHeadgear (selectRandom _uk3cb_faction_headgear);
		_thisUnit forceAddUniform (selectRandom _uk3cb_faction_uniform);
		_thisUnit addVest (selectRandom _uk3cb_faction_vest);
		
		{ for "_i" from 1 to (_x select 1) do { _thisUnit addItemToBackpack (_x select 0); }; } forEach _uk3cb_faction_ace_backpack;
		{ for "_i" from 1 to (_x select 1) do { _thisUnit addItemToUniform (_x select 0); }; } forEach _uk3cb_faction_ace_gear;
		{ for "_i" from 1 to (_x select 1) do { _thisUnit addItemToVest (_x select 0); }; } forEach _uk3cb_faction_magazines;
		{ for "_i" from 1 to (_x select 1) do { _thisUnit addItemToBackpack (_x select 0); }; } forEach _uk3cb_faction_magazines_backpack;
		
		if (random 100 > 50) then {
			{ _thisUnit addItem _x; } forEach _uk3cb_faction_nightTime_items;
		};
		
		//{ for "_i" from 1 to (_x select 1) do { _thisUnit addItem (_x select 0); }; } forEach _uk3cb_faction_vanilla_backpack;
		//{ for "_i" from 1 to (_x select 1) do { _thisUnit addItem (_x select 0); }; } forEach _uk3cb_faction_vanilla_gear;
		
		{ if (_x in (backpackItems _thisUnit)) then { if (random 100 > 50) then { _thisUnit addItemToBackpack _x; } else { _thisUnit removeItemFromBackpack _x; }; }; } forEach _uk3cb_faction_variable_items;
		{ if (_x in ((((weaponsItems _thisUnit) select 0) select 5) select 0)) then { for "_i" from 1 to (floor (random [0, 12, 6])) do { _thisUnit addItem _x; }; }; } forEach _uk3cb_faction_variable_items;
		{ if (_x in ((((weaponsItems _thisUnit) select 1) select 4) select 0)) then { for "_i" from 1 to (floor (random [0, 2, 1])) do { _thisUnit addItemToBackpack _x; }; }; } forEach _uk3cb_faction_variable_items;
		
		diag_log format ["DRO: %1 is a 3CB Faction unit with a forced loadout", _thisUnit];
	};
