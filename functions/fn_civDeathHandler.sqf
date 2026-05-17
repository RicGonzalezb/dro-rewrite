// Migrated from DRO_fnc_civDeathHandler — M3 CfgFunctions migration
params ["_unit"];
	_index = _unit addMPEventHandler ["mpkilled", {
	
		//LordShade modified for ACE3 killer detection
		_condition = (group (_this select 1) == (grpNetId call BIS_fnc_groupFromNetId));
		if (isClass (configfile >> "CfgPatches" >> "ace_medical")) then {
			_condition = (group((_this select 0) getVariable ["ace_medical_lastDamageSource", (_this select 0)]) == (grpNetId call BIS_fnc_groupFromNetId));
		};
		
		if (_condition) then {
			if (isServer) then {
				if (isNil "civDeathCounter") then {
					civDeathCounter = 1;
					publicVariable "civDeathCounter";			
					_text = format["%1 has been responsible for a civilian casualty. Command will not accept collateral damage, adjust your approach to ensure civilians are kept out of the line of fire.", name ((_this select 0) select 1)];
					//["Command", _text] spawn BIS_fnc_showSubtitle;
					//[] spawn DRO_fnc_playSubtitleRadio;				
					dro_messageStack pushBack [[["Command", _text, 0]], true];
				} else {
					civDeathCounter = civDeathCounter + 1;
					publicVariable "civDeathCounter";			
					switch (civDeathCounter) do {
						case 0: {};
						case 1: {
							// Migrated from `[_this] spawn { sleep 2; pushBack message }` to CBA_fnc_waitAndExecute.
							private _text = format["%1 has caused a civilian casualty. Command will not accept collateral damage, adjust your approach to ensure civilians are kept out of the line of fire.", name (_this select 1)];
							[{
								params ["_text"];
								dro_messageStack pushBack [[["Command", _text, 0]], true];
							}, [_text], 2] call CBA_fnc_waitAndExecute;
						};
						case 3: {
							// Migrated from `[_this] spawn { sleep 2; pushBack message }` to CBA_fnc_waitAndExecute.
							private _text = format["%1 has caused a civilian casualty. This is your second warning! If you cannot complete your objectives without causing collateral damage you must withdraw.", name (_this select 1)];
							[{
								params ["_text"];
								dro_messageStack pushBack [[["Command", _text, 0]], true];
							}, [_text], 2] call CBA_fnc_waitAndExecute;
						};
						case 5: {
							// Migrated from `[_this] spawn { sleep 2; message + fail all tasks }` to CBA_fnc_waitAndExecute.
							private _text = format["Your team are responsible for excessive civilian casualties! Pull out immediately, the mission is over!"];
							[{
								params ["_text"];
								dro_messageStack pushBack [[["Command", _text, 0]], true];
								{
									[_x, "FAILED", true] spawn BIS_fnc_taskSetState;
								} forEach taskIDs;
							}, [_text], 2] call CBA_fnc_waitAndExecute;
						};
						case 6: {
							// Migrated from `[_this] spawn { sleep 2; FX; sleep 5; endMission }` to chained CBA_fnc_waitAndExecute.
							[{
								[["", "BLACK OUT", 5]] remoteExec ["cutText", 0];
								[5, 0] remoteExec ["fadeSound", 0];
								[5, 0] remoteExec ["fadeSpeech", 0];
								[{
									if (isMultiplayer) then {
										"DROEnd_FailCiv2" call BIS_fnc_endMissionServer;
									} else {
										"DROEnd_FailCiv2" call BIS_fnc_endMission;
									};
								}, [], 5] call CBA_fnc_waitAndExecute;
							}, [], 2] call CBA_fnc_waitAndExecute;
						};
						default {
							// Removed `[_this] spawn { ... }` wrapper — no sleep, message can be pushed synchronously.
							private _text = format["%1 has caused a civilian casualty. Command will not accept collateral damage, adjust your approach to ensure civilians are kept out of the line of fire.", name (_this select 1)];
							dro_messageStack pushBack [[["Command", _text, 0]], true];
						};
					};
				};
			};
		};
	}];
