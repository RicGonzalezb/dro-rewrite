// Migrated from DRO_fnc_addSabotageAction — M3 CfgFunctions migration
params ["_objects", ["_taskName", ""]];
	if (typeName _objects == "OBJECT") then {		
		_objects = [_objects];		
	};
	{
		_x setVariable ['sabotaged', false, true];
	} forEach _objects;
	if (count _taskName == 0) then {
		_taskName = (_objects select 0) getVariable "thisTask";
	};
	{
		[
			_x,
			"Sabotage",
			"\A3\ui_f\data\igui\cfg\actions\ico_OFF_ca.paa",
			"\A3\ui_f\data\igui\cfg\actions\ico_OFF_ca.paa",
			"(alive _target) && !(_target getVariable ['sabotaged', false]) && ((_this distance _target) < 4) && ('ToolKit' in (items _this + assignedItems _this))",
			"true",
			{},
			{
				if ((_this select 4) % 3 == 0) then {			
					_sound = selectRandom ["A3\Sounds_F\arsenal\weapons\Rifles\Katiba\reload_Katiba.wss", "A3\Sounds_F\arsenal\weapons\Rifles\Mk20\reload_Mk20.wss", "A3\Sounds_F\arsenal\weapons\Rifles\MX\Reload_MX.wss", "A3\Sounds_F\arsenal\weapons\Rifles\SDAR\reload_sdar.wss", "A3\Sounds_F\arsenal\weapons\SMG\Vermin\reload_vermin.wss", "A3\Sounds_F\arsenal\weapons\SMG\PDW2000\Reload_pdw2000.wss"];
					playSound3D [_sound, (_this select 1)];
					//(selectRandom ["FD_Skeet_Launch1_F", "FD_Skeet_Launch2_F"]) remoteExec ["playSound", (_this select 1)];
				};
			},
			{
				// Sabotage this object
				((_this select 0) setVariable ['sabotaged', true, true]);				
				(_this select 0) removeAllEventHandlers "Explosion";
				(_this select 0) removeAllEventHandlers "Killed";
				[(_this select 0), "ALL"] remoteExec ["disableAI", (_this select 0), true];
				[(_this select 0), "LOCKED"] remoteExec ["setVehicleLock", (_this select 0), true];
				[(_this select 0)] remoteExec ["removeAllItems", (_this select 0), true];
				[(_this select 0)] remoteExec ["removeAllWeapons", (_this select 0), true];
				{[(_this select 0), _x] remoteExec ["removeMagazine", (_this select 0), true]} forEach magazines (_this select 0);
				// Check for any other objects that might need sabotaging for task completion
				_complete = true;
				{	
					
					if !(_x getVariable ['sabotaged', false]) then {
						_complete = false;
					};
				} forEach ((_this select 3) select 0);
				// If all are sabotaged then complete the task				
				if (_complete) then {					
					if ([((_this select 3) select 1)] call BIS_fnc_taskExists) then {
						_taskState = [((_this select 3) select 1)] call BIS_fnc_taskState;				
						if !(_taskState isEqualTo "SUCCEEDED") then {
							[((_this select 3) select 1), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;							
						};
					};
					missionNamespace setVariable [format ['%1Completed', ((_this select 3) select 0)], 1, true];					
				};				
			},
			{},
			[_objects, _taskName],
			10,
			10,
			true,
			false
		] remoteExec ["bis_fnc_holdActionAdd", 0, true];
	} forEach _objects;
