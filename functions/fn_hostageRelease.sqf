// Migrated from DRO_fnc_hostageRelease — M3 CfgFunctions migration
params ["_hostage", "_player"];	
	_hostage setVariable ["hostageBound", false, true];
	[_hostage, "Acts_AidlPsitMstpSsurWnonDnon_out"] remoteExec ["playMoveNow", 0]; 
	[_hostage] joinSilent (group _player);
	[_hostage] call DRO_fnc_addResetAction;
	[_hostage, false] remoteExec ["setCaptive", _hostage, true];	
	[_hostage, 'MOVE'] remoteExec ["enableAI", _hostage, true];			
	[(_hostage getVariable 'joinTask'), 'SUCCEEDED', true] remoteExec ["BIS_fnc_taskSetState", (leader(group _player)), true];
	'mkrAOC' setMarkerAlpha 1;
	for "_i" from ((count taskIntel)-1) to 0 step -1 do {
		if (((taskIntel select _i) select 0) == ([(_hostage getVariable 'joinTask')] call BIS_fnc_taskParent)) then {taskIntel deleteAt _i};
	};
	publicVariable "taskIntel";
	//missionNamespace setVariable [format ['%1Completed', ((_this select 0) getVariable 'taskName')], 1, true];
