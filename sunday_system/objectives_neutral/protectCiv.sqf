params ["_AOIndex"];

_reconChance = 0;
_subTasks = [];
_taskName = format ["task%1", floor(random 100000)];
_subTaskName = format ["subtask%1", floor(random 100000)];
_subTaskName2 = format ["subtask%1", floor(random 100000)];
_thisPos = [];
_thisHouse = [(((AOLocations select _AOIndex) select 2) select 7)] call sun_selectRemove;	
_buildingPositions = [_thisHouse] call BIS_fnc_buildingPositions;
_thisCiv = objNull;
if (count _buildingPositions > 0) then {
	_thisPos = selectRandom _buildingPositions;
	_civType = selectRandom civClasses;
	_group = createGroup playersSide;
	_thisCiv = _group createUnit [_civType, _thisPos, [], 0, "NONE"];	
	[_thisCiv] call dro_civDeathHandler;
	_thisCiv setVariable ["NOHOSTILE", true, true];
	_thisCiv setCaptive true;
	_thisCiv disableAI "PATH";
};

if (isNull _thisCiv) exitWith {[(AOLocations call BIS_fnc_randomIndex), false] call fnc_selectObjective};

// Marker
_markerName = format["protectMkr%1", floor(random 10000)];
_markerProtect = createMarker [_markerName, _thisPos];			
_markerProtect setMarkerShape "ICON";
_markerProtect setMarkerType "mil_end";
_markerProtect setMarkerColor "ColorCivilian";		
_markerProtect setMarkerAlpha 0;

// Create task
_taskTitle = "Protect Civilian";
_taskDesc = selectRandom [
	(format ["%3 is a journalist in the %2 region who has been under house arrest for the last year. Based on intelligence gathered in a previous operation we believe that there is now a credible threat on his life from %1. Move to %3's location and protect him.", enemyFactionName, aoLocationName, name _thisCiv]),
	(format ["We've received a communication that a local civilian is willing to give us detailed information on %1 troop movements but that his life is currently threatened. Find him and protect him from harm.", enemyFactionName, aoLocationName, name _thisCiv]),
	(format ["%1 has begun cracking down on protesters in the %2 region. A vocal campaigner named %3 has called for aid after receiving credible threats on his life. Get to him and protect him from harm.", enemyFactionName, aoLocationName, name _thisCiv])
];

_taskType = "defend";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
missionNamespace setVariable [(format ["%1_taskType", _taskName]), _taskType, true];

// Create subtasks	
_subTaskDesc = format ["Make contact with %1.", name _thisCiv];
_subTaskTitle = "Contact";
_subTasks pushBack [_subTaskName, _subTaskDesc, _subTaskTitle, "help"];
missionNamespace setVariable [(format ["%1_taskType", _subTaskName]), "help", true];

_subTaskDesc2 = format ["Protect %1 from harm.", name _thisCiv];
_subTaskTitle2 = "Protect";
_subTasks pushBack [_subTaskName2, _subTaskDesc2, _subTaskTitle2, "defend"];
missionNamespace setVariable [(format ["%1_taskType", _subTaskName2]), "defend", true];

_thisCiv setVariable ["taskName", _taskName, true];
_thisCiv setVariable ["subTasks", _subTasks, true];

// Completion trigger — multi-stage flow.
// Migrated from a scheduled `[args] spawn { waitUntil sleep 3 ... loop sleep 40 ... waitUntil sleep 5 ... }`
// to a CBA chain. Each stage short-circuits if the parent task was already completed.
//   Stage A: PFH 3s — wait until player squad leader is within 6m of civ.
//   Stage B: synchronous — mark "Contact" subtask SUCCEEDED, civ goes DOWN.
//   Stage C: PFH 40s spawning N+1 ambush groups (first inline, rest via PFH).
//   Stage D: PFH 5s — wait until all spawned groups are dead/fleeing.
//   Stage E: synchronous — mark "Protect" subtask + main task SUCCEEDED.
//   Stage F: waitAndExecute 30s — re-enable civ AI and stand up.
if (!(_taskName call BIS_fnc_taskCompleted)) then {
	[{
		params ["_args", "_pfhId"];
		_args params ["_thisCiv", "_taskName", "_subTasks"];
		if (isNull _thisCiv) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler };
		if (_taskName call BIS_fnc_taskCompleted) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler };
		if (((leader (grpNetId call BIS_fnc_groupFromNetId)) distance _thisCiv) >= 6) exitWith {};
		[_pfhId] call CBA_fnc_removePerFrameHandler;

		// Stage B
		["PROTECT_CIV_MEET", (name (leader (grpNetId call BIS_fnc_groupFromNetId))), [name _thisCiv], false] spawn dro_sendProgressMessage;
		_thisCiv setUnitPos "DOWN";
		_thisCiv setCaptive false;
		[((_subTasks select 0) select 0), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
		missionNamespace setVariable [format ["%1Completed", ((_subTasks select 0) select 0)], 1, true];
		[((_subTasks select 0) select 1), "ASSIGNED", true] call BIS_fnc_taskSetState;

		// Stage C — spawn helper: pushes a new ambush group, sends AMBUSHCIV message once.
		// _state = [_allGroups, _messageSent, _i, _total]
		private _state = [[], false, 0, ([1, 3] call BIS_fnc_randomInt) + 1];
		private _spawnOne = {
			params ["_state", "_thisCiv", "_taskName"];
			if (_taskName call BIS_fnc_taskCompleted) exitWith {};
			private _spawnGroup = [(getPos _thisCiv)] call dro_triggerAmbushSpawn;
			if (!isNull _spawnGroup) then {
				(_state select 0) pushBack _spawnGroup;
			};
			if (!(_state select 1) && {!isNull _spawnGroup}) then {
				_state set [1, true];
				["AMBUSHCIV", "Command", [name _thisCiv]] spawn dro_sendProgressMessage;
			};
		};

		// First group inline (matches original: first iteration runs immediately)
		[_state, _thisCiv, _taskName] call _spawnOne;
		_state set [2, 1];

		// Stage D — kicks off once all groups have been spawned (or task already completed).
		private _stageD = {
			params ["_state", "_taskName", "_subTasks", "_thisCiv"];
			private _allGroups = _state select 0;
			if (count _allGroups == 0 || {_taskName call BIS_fnc_taskCompleted}) exitWith {
				[_state, _taskName, _subTasks, _thisCiv] call (missionNamespace getVariable "DRO_protectCiv_stageE");
			};
			[{
				params ["_args", "_pfhId"];
				_args params ["_allGroups", "_taskName", "_subTasks", "_thisCiv"];
				if (_taskName call BIS_fnc_taskCompleted) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler };
				if (!([_allGroups] call sun_checkAllDeadFleeing)) exitWith {};
				[_pfhId] call CBA_fnc_removePerFrameHandler;
				[nil, _taskName, _subTasks, _thisCiv] call (missionNamespace getVariable "DRO_protectCiv_stageE");
			}, 5, [_allGroups, _taskName, _subTasks, _thisCiv]] call CBA_fnc_addPerFrameHandler;
		};

		// Stage E — runs cleanup/SUCCEEDED + Stage F.
		missionNamespace setVariable ["DRO_protectCiv_stageE", {
			params ["", "_taskName", "_subTasks", "_thisCiv"];
			if (_taskName call BIS_fnc_taskCompleted) exitWith {};
			["PROTECT_CIV_CLEAR", (name (leader (grpNetId call BIS_fnc_groupFromNetId))), [name _thisCiv], false] spawn dro_sendProgressMessage;
			[((_subTasks select 0) select 1), "SUCCEEDED", true] call BIS_fnc_taskSetState;
			missionNamespace setVariable [format ["%1Completed", ((_subTasks select 0) select 1)], 1, true];
			[_taskName, "SUCCEEDED", true] call BIS_fnc_taskSetState;
			missionNamespace setVariable [format ["%1Completed", _taskName], 1, true];
			// Stage F
			[{
				params ["_thisCiv"];
				if (!isNull _thisCiv && {alive _thisCiv}) then {
					_thisCiv enableAI "PATH";
					_thisCiv setUnitPos "UP";
				};
			}, [_thisCiv], 30] call CBA_fnc_waitAndExecute;
		}];

		// Stage C — remaining groups via PFH 40s
		if ((_state select 2) >= (_state select 3)) then {
			[_state, _taskName, _subTasks, _thisCiv] call _stageD;
		} else {
			[{
				params ["_args", "_pfhId"];
				_args params ["_state", "_thisCiv", "_taskName", "_subTasks", "_spawnOne", "_stageD"];
				[_state, _thisCiv, _taskName] call _spawnOne;
				_state set [2, (_state select 2) + 1];
				if ((_state select 2) >= (_state select 3) || {_taskName call BIS_fnc_taskCompleted}) then {
					[_pfhId] call CBA_fnc_removePerFrameHandler;
					[_state, _taskName, _subTasks, _thisCiv] call _stageD;
				};
			}, 40, [_state, _thisCiv, _taskName, _subTasks, _spawnOne, _stageD]] call CBA_fnc_addPerFrameHandler;
		};
	}, 3, [_thisCiv, _taskName, _subTasks]] call CBA_fnc_addPerFrameHandler;
};

// Create triggers
_index = _thisCiv addMPEventHandler ["MPKilled", {
	if (!([((_this select 0) getVariable "taskName")] call BIS_fnc_taskCompleted)) then {
		[((_this select 0) getVariable "taskName"), "FAILED", true] spawn BIS_fnc_taskSetState;
	};
}];

allObjectives pushBack _taskName;
objData pushBack [
	_taskName,
	_taskDesc,
	_taskTitle,
	_markerName,
	_taskType,
	_thisPos,
	0,
	_subTasks,
	_thisCiv,
	0	
];
diag_log format ["DRO: Task created: %1, %2", _taskTitle, _taskName];
diag_log format ["DRO: objData: %1", objData];
diag_log format ["DRO: allObjectives is now %1", allObjectives];