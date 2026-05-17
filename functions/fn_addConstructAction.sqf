// Migrated from DRO_fnc_addConstructAction — M3 CfgFunctions migration
params ["_obj", "_objsToDelete", "_createPos", "_createDir", "_taskName"];		
	[
		_obj,
		"Construct Barricade",
		"\A3\ui_f\data\igui\cfg\actions\repair_ca.paa",
		"\A3\ui_f\data\igui\cfg\actions\repair_ca.paa",
		"((_this distance _target) < 4)",
		"true",
		{},
		{
			// Progress
			if ((_this select 4) % 4 == 0) then {			
				_sound = selectRandom ["A3\Sounds_F\arsenal\weapons\Rifles\Katiba\reload_Katiba.wss", "A3\Sounds_F\arsenal\weapons\Rifles\Mk20\reload_Mk20.wss", "A3\Sounds_F\arsenal\weapons\Rifles\MX\Reload_MX.wss", "A3\Sounds_F\arsenal\weapons\Rifles\SDAR\reload_sdar.wss", "A3\Sounds_F\arsenal\weapons\SMG\Vermin\reload_vermin.wss", "A3\Sounds_F\arsenal\weapons\SMG\PDW2000\Reload_pdw2000.wss"];
				playSound3D [_sound, (_this select 1)];
				if (count (((_this select 3) select 0) select {!isObjectHidden _x}) > 0) then {
					(selectRandom (((_this select 3) select 0) select {!isObjectHidden _x})) hideObjectGlobal true;
				};
			};
		},
		{
			// Completed
			// Remove barricade components			
			{deleteVehicle _x} forEach (((_this select 3) select 0) + [_this select 0]);
			
			// Create barricade
			_objects = selectRandom compositionsConstructs;
			_spawnedObjects = [((_this select 3) select 1), ((_this select 3) select 2), _objects] call BIS_fnc_ObjectsMapper;
			
			// Complete the task
			if ([((_this select 3) select 3)] call BIS_fnc_taskExists) then {
				_taskState = [((_this select 3) select 3)] call BIS_fnc_taskState;				
				if !(_taskState isEqualTo "SUCCEEDED") then {
					[((_this select 3) select 3), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;					
				};
			};
			missionNamespace setVariable [format ['%1Completed', ((_this select 3) select 0)], 1, true];
		},
		{
			// Interrupted
			{
				_x hideObjectGlobal false;
			} forEach ((_this select 3) select 0);
		},
		[_objsToDelete, _createPos, _createDir, _taskName],
		20,
		10,
		true,
		false
	] remoteExec ["bis_fnc_holdActionAdd", 0, true];
