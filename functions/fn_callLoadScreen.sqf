// Migrated from DRO_fnc_callLoadScreen — M3 CfgFunctions migration
params ["_message", "_endVar", "_endValue", "_fadeType"];		
	disableSerialization;	
	_loadDisplay = findDisplay 46 createDisplay "SUN_loadScreen";	
	_loadScreen = _loadDisplay displayCtrl 8888;
	_loadScreenText = _loadDisplay displayCtrl 8889;
	
	_loadScreen ctrlSetFade 1;
	_loadScreenText ctrlSetFade 1;
	_loadScreen ctrlCommit 0;
	_loadScreenText ctrlCommit 0;
	
	_loadScreenText ctrlSetText _message;		
	_loadScreenText ctrlSetTextColor [1, 1, 1, 0.8];
	
	if (toUpper _fadeType == "BLACK") then {
		_loadScreen ctrlSetBackgroundColor [0, 0, 0, 1];
	};	
	
	_loadScreen ctrlSetFade 0;
	_loadScreenText ctrlSetFade 0;
	_loadScreen ctrlCommit 2;
	_loadScreenText ctrlCommit 2;

	sleep 2;	
	waitUntil {missionNameSpace getVariable _endVar == _endValue};
	_loadScreen ctrlSetFade 1;
	_loadScreenText ctrlSetFade 1;
	_loadScreen ctrlCommit 0.5;
	_loadScreenText ctrlCommit 0.5;
	sleep 0.5;
	_loadDisplay closeDisplay 1;
