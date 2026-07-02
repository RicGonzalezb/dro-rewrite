// Migrated from DRO_fnc_addArsenal — M3 CfgFunctions migration
if (DRO_aceArsenal) then {
	[(_this select 0), true, true] call ACE_arsenal_fnc_initBox;
	(_this select 0) addAction ["Arsenal", "[(_this select 0), (_this select 1), true] call ace_arsenal_fnc_openBox", nil, 6];
	
} else {
	(_this select 0) addAction ["Arsenal", "['Open', true] call BIS_fnc_arsenal", nil, 6];
};
	
