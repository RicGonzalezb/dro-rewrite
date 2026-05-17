// Migrated from DRO_fnc_unitTaskObjective — M3 CfgFunctions migration
params ["_thisTask"];
	// Migrated from `[_thisTask] spawn { trigger setup; waitUntil {sleep 5; revealed}; marker + task }`
	// to: synchronous setup + trigger + self-removing CBA PFH delta=5 that
	// fires the marker/task creation once the target is revealed.
	private _taskName = format ["task%1", floor(random 100000)];
	missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
	private _object = vehicle (leader (_thisTask select 0));
	private _groupStrength = count (units (_thisTask select 0));
	private _groupVehicles = [];

	// Create trigger
	if (_object == (leader (_thisTask select 0))) then {
		// Trigger if leader is not inside a vehicle
		private _trgClear = createTrigger ["EmptyDetector", getPos _object, true];
		_trgClear setTriggerArea [50, 50, 0, false];
		_trgClear setTriggerActivation ["ANY", "PRESENT", false];
		_trgClear setTriggerStatements [
			"
				(({alive _x} count (units (thisTrigger getVariable 'group'))) <= ((thisTrigger getVariable 'groupStrength') * 0.2))
			",
			"
				[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
				missionNamespace setVariable [format ['%1Completed', (thisTrigger getVariable 'thisTask')], 1, true];
			",
			""
		];
		_trgClear setVariable ["group", (_thisTask select 0)];
		_trgClear setVariable ["groupStrength", _groupStrength];
		_trgClear setVariable ["thisTask", _taskName];
	} else {
		// Trigger if leader is inside a vehicle
		{
			if (vehicle _x != _x) then {
				_groupVehicles pushBackUnique (vehicle _x);
			};
		} forEach (units (_thisTask select 0));

		private _trgClear = createTrigger ["EmptyDetector", getPos _object, true];
		_trgClear setTriggerArea [50, 50, 0, false];
		_trgClear setTriggerActivation ["ANY", "PRESENT", false];
		_trgClear setTriggerStatements [
			"
				(({alive _x} count (thisTrigger getVariable 'groupVehicles')) == 0) OR (({(count (crew _x) > 0)} count (thisTrigger getVariable 'groupVehicles')) == 0)
			",
			"
				[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
				missionNamespace setVariable [format ['%1Completed', (thisTrigger getVariable 'thisTask')], 1, true];
			",
			""
		];
		_trgClear setVariable ["groupVehicles", _groupVehicles];
		_trgClear setVariable ["thisTask", _taskName];
	};

	// Wait for target reveal, then create marker and task.
	[{
		params ["_args", "_pfhId"];
		_args params ["_thisTask", "_object", "_taskName", "_groupVehicles"];
		if (isNull _object) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler };
		if ((playersSide knowsAbout _object) <= 2) exitWith {};
		[_pfhId] call CBA_fnc_removePerFrameHandler;

		// Marker
		private _markerName = format ["taskMkr%1", floor(random 100000)];
		private _markerTask = createMarker [_markerName, getPos _object];
		_markerTask setMarkerShape "ICON";
		_markerTask setMarkerAlpha 0;

		private _taskTitle = format ["Optional: Eliminate %1", toLower (_thisTask select 1)];
		private _taskDesc = format ["We have located a potential %1 target in the AO.", toLower (_thisTask select 1)];

		if (count _groupVehicles > 0) then {
			private _vehicleStrings = [];
			{
				_vehicleStrings pushBack ((configFile >> "CfgVehicles" >> (typeOf _x) >> "displayName") call BIS_fnc_GetCfgData);
			} forEach _groupVehicles;
			switch (true) do {
				case ((_groupVehicles select 0) isKindOf "Helicopter"): { _taskTitle = format ["Eliminate helicopter%1", (if (count _groupVehicles > 1) then {"s"} else {""})] };
				case ((_groupVehicles select 0) isKindOf "Plane"): { _taskTitle = format ["Eliminate plane%1", (if (count _groupVehicles > 1) then {"s"} else {""})] };
				case ((_groupVehicles select 0) isKindOf "LandVehicle"): { _taskTitle = format ["Eliminate vehicle%1", (if (count _groupVehicles > 1) then {"s"} else {""})] };
			};
			_taskDesc = format ["Eliminate the %1", ([_vehicleStrings] call DRO_fnc_stringCommaList)];
		};

		// Create task
		if ((missionNamespace getVariable (format ["%1Completed", _taskName])) == 0) then {
			[_taskName, true, [_taskDesc, _taskTitle, _markerName], _object, "CREATED", 1, true, true, "target", true] call BIS_fnc_setTask;
		} else {
			[_taskName, true, [_taskDesc, _taskTitle, _markerName], _object, "SUCCEEDED", 1, true, true, "target", true] call BIS_fnc_setTask;
		};
	}, 5, [_thisTask, _object, _taskName, _groupVehicles]] call CBA_fnc_addPerFrameHandler;
