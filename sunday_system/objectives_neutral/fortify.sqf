params ["_AOIndex"];

_subTasks = [];
_taskName = format ["task%1", floor(random 100000)];
_intelSubTaskName = format ["subtask%1", floor(random 100000)];

diag_log format["DRO: Task seeking a position in: %1", str (((AOLocations select _AOIndex) select 2) select 4)];

_thisPos = [(((AOLocations select _AOIndex) select 2) select 4)] call sun_selectRemove;

_grid = [_thisPos, 3, 3, 5.5] call sun_defineGrid;
_gridSorted = [(_grid select 0), (_grid select 3), (_grid select 6), (_grid select 7), (_grid select 8), (_grid select 5), (_grid select 2), (_grid select 1)];
_dirOut = 225;

_allBoxes = [];
_constructPool = [["Land_SandbagBarricade_01_F", "Land_SandbagBarricade_01_half_F", "Land_SandbagBarricade_01_F"], ["Land_SandbagBarricade_01_F", "Land_SandbagBarricade_01_half_F", "Land_SandbagBarricade_01_F"], ["Land_SandbagBarricade_01_F", "Land_SandbagBarricade_01_hole_F", "Land_SandbagBarricade_01_F"]];
{
	_thisGridPos = _x;
	_select = [];
	if (_forEachIndex == 0) then {		
		_select = ["Land_SandbagBarricade_01_F", "Land_Mil_WiredFence_Gate_F", "Land_SandbagBarricade_01_F"];
	} else {
		_select = selectRandom _constructPool;
	};
	_distShift = 0;
	if (_forEachIndex == 1 || _forEachIndex == 3 || _forEachIndex == 5 || _forEachIndex == 7) then {
		_distShift = 1.8;
	};
	_box = [_thisGridPos, _select, _dirOut, _distShift] call dro_addConstructPoint;
	_allBoxes pushBack _box;
	_dirOut = _dirOut - 45;
} forEach _gridSorted;

/*
{
	_x hideObjectGlobal true;
} forEach _allSpheres;
*/

// Marker
_markerName = format["fortifyMkr%1", floor(random 10000)];
_markerFortify = createMarker [_markerName, _thisPos];			
_markerFortify setMarkerShape "ICON";
_markerFortify setMarkerType "loc_Bunker";
_markerFortify setMarkerSize [2.5, 2.5];
_markerText = format ["OP %1", ([FOBNames] call sun_selectRemove)];
_markerFortify setMarkerText _markerText;
_markerFortify setMarkerColor markerColorPlayers;		
_markerFortify setMarkerAlpha 0;
	
_taskDesc = selectRandom [
	(format ["As we prepare to make a move into %2 you are tasked with constructing an operating post in the area. Move to the marked location and fortify it.", enemyFactionName, aoLocationName]),
	(format ["With increased %1 activity we can expect them to move into %2 at some point in the future. Fortify this location in preparation.", enemyFactionName, aoLocationName])	
];	

// Create task
_taskTitle = "Construct Fortifications";
_taskType = "use";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
missionNamespace setVariable [(format ["%1_taskType", _taskName]), _taskType, true];

// Completion trigger.
// Migrated from a scheduled multi-stage `[args] spawn { ... waitUntil sleep 5 ... sleep 20 loop ... waitUntil sleep 5 ... }`
// to a CBA chain:
//   Stage A: PFH 5s — wait for all construct boxes to be built (boxes nulled).
//   Stage B: synchronous cleanup (set fortify task SUCCEEDED, reveal marker).
//   Stage C: spawn 3–5 defense groups at 20s intervals (first inline, rest via PFH 20s).
//   Stage D: PFH 5s — wait for all defense groups dead/fleeing.
//   Stage E: set defend task SUCCEEDED.
[{
	params ["_args", "_pfhId"];
	_args params ["_allBoxes", "_taskName", "_markerName", "_markerText"];
	// Stage A: all construct boxes have been replaced (each becomes null after build)
	if (({isNull _x} count _allBoxes) != count _allBoxes) exitWith {};
	[_pfhId] call CBA_fnc_removePerFrameHandler;

	// Stage B: fortify task succeeded
	[_taskName, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
	missionNamespace setVariable [format ["%1Completed", _taskName], 1, true];
	_markerName setMarkerAlpha 1;

	taskCreationInProgress = true;

	// Compute ambush spawn positions (synchronous, cheap loop)
	private _spawnPos = [];
	private _attempts = 0;
	private _scan = true;
	while {_scan} do {
		private _candidate = [(getMarkerPos _markerName), 250, 450, 2, 0, 1, 0] call BIS_fnc_findSafePos;
		if ([objNull, "VIEW"] checkVisibility [(getMarkerPos _markerName), _candidate] < 0.2) then { _spawnPos = _candidate; _scan = false; };
		if (_attempts > 200) then { _scan = false; };
		_attempts = _attempts + 1;
	};
	private _spawnPos2 = [];
	if (count _spawnPos > 0) then {
		private _dir = _spawnPos getDir (getMarkerPos _markerName);
		private _candidate2 = _spawnPos getPos [(random [50, 100, 75]), (selectRandom [_dir - 90, _dir + 90])];
		if ([objNull, "VIEW"] checkVisibility [(getMarkerPos _markerName), _candidate2] < 0.2) then { _spawnPos2 = _candidate2; };
	};

	// Shared state for Stage C (mutated across PFH ticks via array reference)
	private _defendTaskName = format ["task%1", floor(random 100000)];
	// _state = [_allGroups, _messageSent, _i, _total]
	private _state = [[], false, 0, ([2, 4] call BIS_fnc_randomInt)];

	// Local helper to spawn one ambush group + handle the first-time defend-task creation
	private _spawnOne = {
		params ["_state", "_markerName", "_markerText", "_defendTaskName", "_spawnPos", "_spawnPos2"];
		_state params ["_allGroups", "_messageSent"];
		private _spawnGroup = if (count _spawnPos > 0) then {
			if (count _spawnPos2 > 0) then {
				[(getMarkerPos _markerName), (selectRandom [_spawnPos, _spawnPos2])] call dro_triggerAmbushSpawn;
			} else {
				[(getMarkerPos _markerName), _spawnPos] call dro_triggerAmbushSpawn;
			};
		} else {
			[(getMarkerPos _markerName)] call dro_triggerAmbushSpawn;
		};
		if (!isNull _spawnGroup) then {
			_allGroups pushBack _spawnGroup;
		};
		if (!_messageSent && !isNull _spawnGroup) then {
			_state set [1, true];
			["AMBUSHOP"] spawn dro_sendProgressMessage;
			[
				[
					_defendTaskName,
					(format ["Hold and defend %2 from the attacking %1 force.", enemyFactionName, _markerText]),
					"Defend",
					_markerName,
					"defend",
					(getMarkerPos _markerName),
					0,
					nil,
					nil,
					0
				],
				true,
				true,
				false,
				true
			] call sun_assignTask;
			taskCreationInProgress = false;
		};
	};

	// Stage C — first group inline (matches original behaviour: first spawn happens immediately)
	[_state, _markerName, _markerText, _defendTaskName, _spawnPos, _spawnPos2] call _spawnOne;

	// Stage C — remaining groups via PFH 20s
	if ((_state select 3) > 0) then {
		[{
			params ["_args", "_pfhId"];
			_args params ["_state", "_markerName", "_markerText", "_defendTaskName", "_spawnPos", "_spawnPos2", "_spawnOne"];
			[_state, _markerName, _markerText, _defendTaskName, _spawnPos, _spawnPos2] call _spawnOne;
			_state set [2, (_state select 2) + 1];
			if ((_state select 2) >= (_state select 3)) then {
				[_pfhId] call CBA_fnc_removePerFrameHandler;
				// Stage D — if any defenders spawned, wait until they're all dead/fleeing
				private _allGroups = _state select 0;
				if (count _allGroups > 0) then {
					[{
						params ["_args2", "_pfhId2"];
						_args2 params ["_allGroups", "_defendTaskName"];
						if (!([_allGroups] call sun_checkAllDeadFleeing)) exitWith {};
						[_pfhId2] call CBA_fnc_removePerFrameHandler;
						// Stage E — defend task succeeded
						[_defendTaskName, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
					}, 5, [_allGroups, _defendTaskName]] call CBA_fnc_addPerFrameHandler;
				};
			};
		}, 20, [_state, _markerName, _markerText, _defendTaskName, _spawnPos, _spawnPos2, _spawnOne]] call CBA_fnc_addPerFrameHandler;
	} else {
		// Edge case: only one group total — go straight to Stage D
		private _allGroups = _state select 0;
		if (count _allGroups > 0) then {
			[{
				params ["_args2", "_pfhId2"];
				_args2 params ["_allGroups", "_defendTaskName"];
				if (!([_allGroups] call sun_checkAllDeadFleeing)) exitWith {};
				[_pfhId2] call CBA_fnc_removePerFrameHandler;
				[_defendTaskName, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
			}, 5, [_allGroups, _defendTaskName]] call CBA_fnc_addPerFrameHandler;
		};
	};
}, 5, [_allBoxes, _taskName, _markerName, _markerText]] call CBA_fnc_addPerFrameHandler;

allObjectives pushBack _taskName;
objData pushBack [
	_taskName,
	_taskDesc,
	_taskTitle,
	_markerName,
	_taskType,
	_thisPos,
	0,
	nil,
	nil,
	3
];
diag_log format ["DRO: Task created: %1, %2", _taskTitle, _taskName];
diag_log format ["DRO: objData: %1", objData];
diag_log format ["DRO: allObjectives is now %1", allObjectives];