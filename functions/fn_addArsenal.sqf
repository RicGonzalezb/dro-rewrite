// Migrated from DRO_fnc_addArsenal — M3 CfgFunctions migration
(_this select 0) addAction ["Arsenal", "['Open', true] call BIS_fnc_arsenal", nil, 6];
	[(_this select 0), true] call ACE_arsenal_fnc_initBox;
