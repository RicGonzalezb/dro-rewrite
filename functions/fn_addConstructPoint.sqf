// Migrated from DRO_fnc_addConstructPoint — M3 CfgFunctions migration
params ["_pos", "_objType", "_dir", ["_posDistShift", 0]];		
	
	_useLib = if (_posDistShift == 0) then {false} else {true};
	_pos = _pos getPos [_posDistShift, _dir];
	_box = createVehicle [(selectRandom ["Land_WoodenCrate_01_F", "Land_WoodenCrate_01_stack_x3_F"]), _pos, [], 0, "CAN_COLLIDE"];
	_box setDir (random 360);
	[
		_box,
		"Construct Barricade",
		"\A3\ui_f\data\igui\cfg\actions\repair_ca.paa",
		"\A3\ui_f\data\igui\cfg\actions\repair_ca.paa",
		"((_this distance _target) < 4)",
		"true",
		{},
		{
			// Progress
			/*
			if ((_this select 4) % 3 == 0) then {			
				_sound = selectRandom ["A3\Sounds_F\arsenal\weapons\Rifles\Katiba\reload_Katiba.wss", "A3\Sounds_F\arsenal\weapons\Rifles\Mk20\reload_Mk20.wss", "A3\Sounds_F\arsenal\weapons\Rifles\MX\Reload_MX.wss", "A3\Sounds_F\arsenal\weapons\Rifles\SDAR\reload_sdar.wss", "A3\Sounds_F\arsenal\weapons\SMG\Vermin\reload_vermin.wss", "A3\Sounds_F\arsenal\weapons\SMG\PDW2000\Reload_pdw2000.wss"];
				playSound3D [_sound, (_this select 1)];				
			};
			*/
		},
		{
			// Completed
			// Remove helper
			deleteVehicle (_this select 0);			
			// Create object
			if ((_this select 3) select 3) then {				
				_objList = (selectRandom compositionsBunkerCorners);				
				_removeElements = [];
				{
					if ((_x select 0) == "Sign_Arrow_Blue_F") then {
						_removeElements pushBack _x;
					};
				} forEach (_objList);
				_objList = _objList - _removeElements;
				_spawnedObjects = [((_this select 3) select 1), ((_this select 3) select 2), _objList] call BIS_fnc_ObjectsMapper;
			} else {
				_objList = ((_this select 3) select 0);
				_pos = ((_this select 3) select 1);
				_dir = ((_this select 3) select 2);
				if (_objList isEqualType []) then {
					
					_distShift = -2;
					{					
						_spawnPos = _pos getPos [_distShift, _dir - 90];
						_spawnPos set [2, 0];			
						_obj = createVehicle [_x, _spawnPos, [], 0, "CAN_COLLIDE"];					
						_obj setDir _dir;					
						_distShift = _distShift + 2;
					} forEach _objList;				
				} else {				
					_pos set [2, 0];			
					_obj = createVehicle [_objList, _pos, [], 0, "CAN_COLLIDE"];
					_obj setDir _dir;
				};
			};
		},
		{
			// Interrupted			
		},
		[_objType, _pos, _dir, _useLib],
		5,
		10,
		true,
		false
	] remoteExec ["bis_fnc_holdActionAdd", 0, true];
	_box
