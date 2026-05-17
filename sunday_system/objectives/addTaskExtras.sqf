params ["_objectivePos", "_thisTask", ["_reinfType", 1]];

// Add cancel button to task
_taskData = [_thisTask] call BIS_fnc_taskDescription;
_taskDesc = (_taskData select 0) select 0;
_taskTitle = _taskData select 1;
_taskMarker = _taskData select 2;
_taskDescNew = format ["%1<br /><br /><execute expression='[""%2"", ""CANCELED"", true] spawn BIS_fnc_taskSetState;'>Cancel task</execute>", _taskDesc, _thisTask];

[_thisTask, [_taskDescNew, _taskTitle, _taskMarker]] call BIS_fnc_taskSetDescription;

// Add task ends
switch (_reinfType) do {
	case 0: {
		// No reinforcements. Migrated from `waitUntil {sleep 10; complete}; followup`
		// to self-removing CBA PFH delta=10 (script returns immediately; callback
		// fires when task completes).
		[{
			params ["_args", "_pfhId"];
			_args params ["_thisTask"];
			if (!([_thisTask] call BIS_fnc_taskCompleted)) exitWith {};
			[_pfhId] call CBA_fnc_removePerFrameHandler;
			if (reactiveChance > 0.85) then {
				diag_log "DRO: Creating reactive task";
				reactiveChance = 0;
				[] call DRO_fnc_selectReactiveObjective;
			} else {
				["TASK_SUCCEED"] spawn DRO_fnc_sendProgressMessage;
			};
		}, 10, [_thisTask]] call CBA_fnc_addPerFrameHandler;
	};
	case 1: {
		// Regular reinforce. Migrated from `spawn { waitUntil {sleep 10; complete}; followup }`
		// to direct CBA PFH delta=10.
		[{
			params ["_args", "_pfhId"];
			_args params ["_objectivePos", "_thisTask"];
			if (!([_thisTask] call BIS_fnc_taskCompleted)) exitWith {};
			[_pfhId] call CBA_fnc_removePerFrameHandler;
			if (reactiveChance > 0.85) then {
				diag_log "DRO: Creating reactive task";
				reactiveChance = 0;
				[] call DRO_fnc_selectReactiveObjective;
			} else {
				["TASK_SUCCEED"] spawn DRO_fnc_sendProgressMessage;
			};
			reinforceChance = ((reinforceChance + 0.1) * aiMultiplier);
			if ((random 1) < reinforceChance) then {
				if (!stealthActive && enemyCommsActive) then {
					[_objectivePos, [1,2]] execVM "sunday_system\reinforce.sqf";
				};
			};
		}, 10, [_objectivePos, _thisTask]] call CBA_fnc_addPerFrameHandler;
	};
	case 2: {
		// Ambush. Migrated from `spawn { waitUntil {sleep 10; complete}; sleep 5; ambush }`
		// to: CBA PFH delta=10 (task completion watcher) → CBA_fnc_waitAndExecute (5s).
		[{
			params ["_args", "_pfhId"];
			_args params ["_objectivePos", "_thisTask"];
			if (!([_thisTask] call BIS_fnc_taskCompleted)) exitWith {};
			[_pfhId] call CBA_fnc_removePerFrameHandler;
			[{
				params ["_objectivePos"];
				private _ambushGroup = [_objectivePos] call DRO_fnc_triggerAmbushSpawn;
				if (!isNull _ambushGroup) then {
					["AMBUSH"] spawn DRO_fnc_sendProgressMessage;
				};
			}, [_objectivePos], 5] call CBA_fnc_waitAndExecute;
		}, 10, [_objectivePos, _thisTask]] call CBA_fnc_addPerFrameHandler;
	};
	case 3: {
		// No success message. Migrated to self-removing CBA PFH delta=10.
		[{
			params ["_args", "_pfhId"];
			_args params ["_thisTask"];
			if (!([_thisTask] call BIS_fnc_taskCompleted)) exitWith {};
			[_pfhId] call CBA_fnc_removePerFrameHandler;
			if (reactiveChance > 0.85) then {
				diag_log "DRO: Creating reactive task";
				reactiveChance = 0;
				[] call DRO_fnc_selectReactiveObjective;
			};
		}, 10, [_thisTask]] call CBA_fnc_addPerFrameHandler;
	};
	case 4: {
		// Nothing at all!
	};
};
