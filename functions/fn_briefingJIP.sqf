// Migrated from DRO_fnc_briefingJIP — M3 CfgFunctions migration
params ["_briefingString"];	
	player createDiaryRecord ["Diary", ["Briefing", _briefingString]];
