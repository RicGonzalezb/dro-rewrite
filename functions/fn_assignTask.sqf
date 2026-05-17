// Migrated from DRO_fnc_assignTask — M3 CfgFunctions migration
params ["_taskData", ["_pushToArray", true], ["_addExtras", true], ["_hideMarker", false], ["_notify", false]];	
	private _taskName = _taskData select 0;
	private _taskDesc = _taskData select 1;
	private _taskTitle = _taskData select 2;
	private _markerName = _taskData select 3;
	private _taskType = _taskData select 4;
	private _taskPos = _taskData select 5;
	private _reconChance = _taskData select 6;	
	private _subTasks = if (count _taskData > 7) then {_taskData select 7};	
	private _extraData = if (count _taskData > 8) then {_taskData select 8};	
	private _reinfType = if (count _taskData > 9) then {_taskData select 9} else {1};
	
	diag_log format["DRO: Task %1 all data:", _taskName];
	{		
		if (isNil '_x') then {
			diag_log format["      nil", -1];
		} else {
			diag_log format["      %1", _x];
		};
	} forEach _taskData;
	
	_createType = "CREATED";
	_completed = (missionNamespace getVariable [(format ["%1Completed", _taskName]), 0]);
	if (_completed == 1) then {
		_createType = "SUCCEEDED";
	};	
	// Create task from task data
	diag_log "DRO: Assigning regular task";
	_markerPos = getMarkerPos _markerName;		
	_markerPos set [2,0];
	diag_log format ["DRO: Task %1 _markerPos = %2", _taskName, _markerPos];
	_id = [_taskName, true, [_taskDesc, _taskTitle, _markerName], _markerPos, _createType, 1, _notify, true, _taskType, true] call BIS_fnc_setTask;
	diag_log format ["DRO: Assigned task %1: %2", _taskName, _taskTitle];
	if (_pushToArray) then {
		taskIDs pushBackUnique _id;
		diag_log format ["DRO: taskIDs is now: %1", taskIDs];
	};	
	if (_addExtras) then {		
		[_taskPos, _taskName, _reinfType] execVM "sunday_system\objectives\addTaskExtras.sqf";				
	};
	if (_hideMarker) then {
		_markerName setMarkerAlpha 0;
		_markerName setMarkerSize [1, 1];
	} else {
		if (markerShape _markerName == "ICON") then {} else {_markerName setMarkerAlpha 0.5};
	};	
	if (!isNil "_subTasks") then {		
		diag_log format ["DRO: Task %1 subTasks = %2", _taskName, _subTasks];
		if (count _subTasks > 0) then {
			{
				_subTaskName = _x select 0;
				_subTaskDesc = _x select 1;
				_subTaskTitle = _x select 2;
				_subTaskType = _x select 3;
				_id = [[_subTaskName, _taskName], true, [_subTaskDesc, _subTaskTitle, _markerName], objNull, "CREATED", 1, false, true, _subTaskType, true] call BIS_fnc_setTask;
			} forEach _subTasks;	
		};		
	};
	if (_reconChance >= baseReconChance) then {
		if (!isNil "_extraData") then {
			[_taskName, _extraData] call BIS_fnc_taskSetDestination;
		};
	};
