// Migrated from DRO_fnc_hvtCapture — M3 CfgFunctions migration
params ["_hostage", "_player"];		
	[_hostage] joinSilent (group _player);
	[_hostage] call DRO_fnc_addResetAction;
	[_hostage, false] remoteExec ["setCaptive", _hostage, true];	
	[_hostage, 'MOVE'] remoteExec ["enableAI", _hostage, true];			
	[(_hostage getVariable 'captureTask'), 'SUCCEEDED', true] remoteExec ["BIS_fnc_taskSetState", (leader(group _player)), true];
	'mkrAOC' setMarkerAlpha 1;
	for "_i" from ((count taskIntel)-1) to 0 step -1 do {
		if (((taskIntel select _i) select 0) == ([(_hostage getVariable 'captureTask')] call BIS_fnc_taskParent)) then {taskIntel deleteAt _i};
	};
	publicVariable "taskIntel";
