_extractStyles = ["LEAVE"];
_extractWeights = [0.3];
if (insertType == "GROUND") then {
	_extractStyles pushBack "RTB";
	_extractWeights pushBack 0.1;
};

if (!isNil "friendlySquad") then {
	if (({alive _x} count (units friendlySquad)) > 0) then {
		_extractStyles = ["RENDEZVOUS"];
		_extractWeights = [];
		if (count holdAO > 0) then {
			_extractWeights pushBack 0;
		} else {
			_extractWeights pushBack 0.5;
		};
	};
};

if (count holdAO > 0) then {
	_extractStyles pushBack "HOLD";
	_extractWeights pushBack 1;
};

_extractStyle = _extractStyles selectRandomWeighted _extractWeights;

// Filter available helicopters for transportation space
_numPassengers = count (units (grpNetId call BIS_fnc_groupFromNetId));
_heliTransports = [];
{
	if ([_x] call DRO_fnc_getTrueCargo >= _numPassengers) then {
		_heliTransports pushBack _x;
	};
} forEach pHeliClasses;

diag_log format ["DRO: _extractStyles = %1", _extractStyles];
diag_log format ["DRO: _extractWeights = %1", _extractWeights];
diag_log format ["DRO: _extractStyle = %1", _extractStyle];

// Create extract task
_playerGroup = [] call CBA_fnc_players;
_playerGroupAlive = [];
_playerGroupLeader = (leader (grpNetId call BIS_fnc_groupFromNetId));
if (isNull _playerGroupLeader) then {
	_playerGroup call BIS_fnc_sortAlphabetically;
	{
		if (alive _x) then { _playerGroupAlive pushBackUnique _x; };
	} forEach _playerGroup;
	_playerGroupLeader = _playerGroupAlive select 0;
};
diag_log format ["DRO: Player group leader %1, from NetID %2", _playerGroupLeader, (_playerGroupLeader call BIS_fnc_netId)];
dro_messageStack pushBack [[[str (name _playerGroupLeader), "Time to leave, gotta call it in on the radio...", 0]], true];
switch (_extractStyle) do {
	case "LEAVE": {
		if (((count _heliTransports) > 0) && !extractHeliUsed) then {
			_taskCreated = ["taskExtract", true, ["Extract from the AO. A helicopter transport is available to support. Alternatively leave the AO by any means available.", "Extract", ""], objNull, "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;	
			diag_log format ["DRO: Extract task created: %1", _taskCreated];
			//[(leader (grpNetId call BIS_fnc_groupFromNetId)), "heliExtract"] remoteExec ["BIS_fnc_addCommMenuItem", (leader (grpNetId call BIS_fnc_groupFromNetId)), true];
			[_playerGroupLeader, "heliExtract"] remoteExec ["BIS_fnc_addCommMenuItem", _playerGroupLeader, true];
		} else {
			_taskCreated = ["taskExtract", true, ["Leave the AO by any means to extract. Helicopter transport is unavailable.", "Extract", ""], objNull, "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;
			diag_log format ["DRO: Extract task created: %1", _taskCreated];
		};
		
		// Send new enemies to chase players if stealth is not maintained
		if (!stealthActive) then {
			if (enemyCommsActive) then {
				diag_log 'DRO: Reinforcing due to mission completion';
				//[(leader (grpNetId call BIS_fnc_groupFromNetId)), [2,4]] execVM 'sunday_system\reinforce.sqf';
				[_playerGroupLeader, [2,4]] execVM 'sunday_system\reinforce.sqf';
			};
			// Make existing enemies close in on players
			diag_log "DRO: Init staggered attack";
			[30] execVM 'sunday_system\generate_enemies\staggeredAttack.sqf';
		};
		
		"mkrAOC" setMarkerAlpha 1;
		// Extraction success trigger
		trgExtract = createTrigger ["EmptyDetector", getPos trgAOC, true];
		trgExtract setTriggerArea [(triggerArea trgAOC) select 0, (triggerArea trgAOC) select 1, 0, true];
		trgExtract setTriggerActivation ["ANY", "PRESENT", false];
		trgExtract setTriggerStatements [
			"
				({vehicle _x in thisList} count allPlayers == 0) &&
				({alive _x} count allPlayers > 0)
			",
			"
				[] execVM 'sunday_system\endMission.sqf';
			",
			""
		];
		
		//["LeadTrack02_F_Mark"] remoteExec ["playMusic", 0];
		if (worldName in ["Cam_Lao_Nam","vn_khe_sanh","vn_the_bra"]) then {
			[musicVNExtract, 0, 0.7] remoteExec ["BIS_fnc_playMusic", ([0, -2] select isDedicated)];
		} else {
			[musicExtract, 0, 0.7] remoteExec ["BIS_fnc_playMusic", ([0, -2] select isDedicated)];
		};
		["END_LEAVE"] spawn DRO_fnc_sendProgressMessage;
	};
	case "RTB": {
		if (((count _heliTransports) > 0) && !extractHeliUsed) then {
			_taskCreated = ["taskExtract", true, ["Extract from the AO and return to base. A helicopter transport is available to support. Alternatively leave the AO by any means available.", "RTB", ""], objNull, "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;	
			diag_log format ["DRO: Extract task created: %1", _taskCreated];
			//[(leader (grpNetId call BIS_fnc_groupFromNetId)), "heliExtract"] remoteExec ["BIS_fnc_addCommMenuItem", (leader (grpNetId call BIS_fnc_groupFromNetId)), true];
			[_playerGroupLeader, "heliExtract"] remoteExec ["BIS_fnc_addCommMenuItem", _playerGroupLeader, true];
		} else {
			_taskCreated = ["taskExtract", true, ["Leave the AO by any means to extract. Helicopter transport is unavailable.", "RTB", ""], objNull, "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;	
			diag_log format ["DRO: Extract task created: %1", _taskCreated];
		};
		
		// Send new enemies to chase players if stealth is not maintained
		if (!stealthActive) then {
			if (enemyCommsActive) then {
				diag_log 'DRO: Reinforcing due to mission completion';
				//[(leader (grpNetId call BIS_fnc_groupFromNetId)), [2,4]] execVM 'sunday_system\reinforce.sqf';
				[_playerGroupLeader, [2,4]] execVM 'sunday_system\reinforce.sqf';
			};
			// Make existing enemies close in on players
			diag_log "DRO: Init staggered attack";	
			[30] execVM 'sunday_system\generate_enemies\staggeredAttack.sqf';
		};
		
		// Extraction success trigger
		extractPos = (getMarkerPos "campMkr");
		publicVariable "extractPos";
		trgExtract = createTrigger ["EmptyDetector", getMarkerPos "campMkr", true];
		trgExtract setTriggerArea [50, 50, 0, true];
		trgExtract setTriggerActivation ["ANY", "PRESENT", false];
		trgExtract setTriggerStatements [
			"
				({vehicle _x in thisList} count allPlayers > 0) &&
				({alive _x} count allPlayers > 0)
			",
			"
				[] execVM 'sunday_system\endMission.sqf';
			",
			""
		];
		
		//["LeadTrack02_F_Mark"] remoteExec ["playMusic", 0];
		if (worldName in ["Cam_Lao_Nam","vn_khe_sanh","vn_the_bra"]) then {
			[musicVNExtract, 0, 0.7] remoteExec ["BIS_fnc_playMusic", ([0, -2] select isDedicated)];
		} else {
			[musicExtract, 0, 0.7] remoteExec ["BIS_fnc_playMusic", ([0, -2] select isDedicated)];
		};
		["END_RTB"] spawn DRO_fnc_sendProgressMessage;
	};
	case "RENDEZVOUS": {
		_string = format ["Rendezvous with %1 before leaving the AO.", groupId friendlySquad];
		_taskMeet = ["taskExtract_b", true, [_string, "Rendezvous", ""], (leader friendlySquad), "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;
		["END_RENDEZVOUS"] spawn DRO_fnc_sendProgressMessage;
		// Migrated from scheduled `waitUntil {sleep 5; player near friendly}; lots_of_cleanup`
		// to self-removing CBA PFH delta=5. All post-rendezvous setup moves into the callback.
		[{
			params ["_args", "_pfhId"];
			_args params ["_playerGroupLeader"];
			if (({(_x distance (leader friendlySquad)) < 10} count allPlayers) == 0) exitWith {};
			[_pfhId] call CBA_fnc_removePerFrameHandler;

			(units friendlySquad) joinSilent (grpNetId call BIS_fnc_groupFromNetId);
			["taskExtract_b", "SUCCEEDED", true] spawn BIS_fnc_taskSetState;

			// Filter available helicopters for transportation space
			private _numPassengers = count (units (grpNetId call BIS_fnc_groupFromNetId));
			private _heliTransports = [];
			{
				if ([_x] call DRO_fnc_getTrueCargo >= _numPassengers) then {
					_heliTransports pushBack _x;
				};
			} forEach pHeliClasses;
			diag_log format ["DRO: _heliTransports = %1", _heliTransports];
			private _taskCreated = "";
			if (((count _heliTransports) > 0) && {!extractHeliUsed}) then {
				_taskCreated = ["taskExtract", true, ["Extract from the AO. A helicopter transport is available to support. Alternatively leave the AO by any means available.", "Extract", ""], objNull, "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;
				diag_log format ["DRO: Extract task created: %1", _taskCreated];
				[_playerGroupLeader, "heliExtract"] remoteExec ["BIS_fnc_addCommMenuItem", _playerGroupLeader, true];
			} else {
				_taskCreated = ["taskExtract", true, ["Leave the AO by any means to extract. Helicopter transport is unavailable.", "Extract", ""], objNull, "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;
				diag_log format ["DRO: Extract task created: %1", _taskCreated];
			};
			"mkrAOC" setMarkerAlpha 1;

			// Send new enemies to chase players if stealth is not maintained
			if (!stealthActive) then {
				if (enemyCommsActive) then {
					diag_log "DRO: Reinforcing due to mission completion";
					[_playerGroupLeader, [2,4]] execVM "sunday_system\reinforce.sqf";
				};
				diag_log "DRO: Init staggered attack";
				[30] execVM "sunday_system\generate_enemies\staggeredAttack.sqf";
			};

			// Extraction success trigger
			trgExtract = createTrigger ["EmptyDetector", getPos trgAOC, true];
			trgExtract setTriggerArea [(triggerArea trgAOC) select 0, (triggerArea trgAOC) select 1, 0, true];
			trgExtract setTriggerActivation ["ANY", "PRESENT", false];
			trgExtract setTriggerStatements [
				"
					({vehicle _x in thisList} count allPlayers == 0) &&
					({alive _x} count allPlayers > 0)
				",
				"
					[] execVM 'sunday_system\endMission.sqf';
				",
				""
			];

			if (worldName in ["Cam_Lao_Nam","vn_khe_sanh","vn_the_bra"]) then {
				[musicVNExtract, 0, 0.7] remoteExec ["BIS_fnc_playMusic", ([0, -2] select isDedicated)];
			} else {
				[musicExtract, 0, 0.7] remoteExec ["BIS_fnc_playMusic", ([0, -2] select isDedicated)];
			};
		}, 5, [_playerGroupLeader]] call CBA_fnc_addPerFrameHandler;
	};
	case "HOLD": {
		if ("RENDEZVOUS" in _extractStyles) then {
			_string = format ["Rendezvous with %1 and hold the area together.", groupId friendlySquad];
			_taskMeet = ["taskExtract_b", true, [_string, "Rendezvous", ""], (leader friendlySquad), "CREATED", 5, true, true, "exit", true] call BIS_fnc_setTask;
			// Migrated from `[] spawn { waitUntil {sleep 5; player near friendly}; cleanup }`
			// to self-removing CBA PFH delta=5.
			[{
				params ["_args", "_pfhId"];
				if (({(_x distance (leader friendlySquad)) < 10} count allPlayers) == 0) exitWith {};
				[_pfhId] call CBA_fnc_removePerFrameHandler;
				(units friendlySquad) joinSilent (grpNetId call BIS_fnc_groupFromNetId);
				["taskExtract_b", "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
			}, 5, []] call CBA_fnc_addPerFrameHandler;
		};
		
		_groupPositions = [];
		{
			if (side _x == enemySide) then {
				if ((leader _x distance (holdAO select 0)) < (holdAO select 1)) then {
					_groupPositions pushBack (getPos leader _x);
				};
			};
		} forEach allGroups;
		diag_log format ["DRO: _groupPositions = %1", _groupPositions];
		_avgPos = if (count _groupPositions > 0) then {
			[_groupPositions] call DRO_fnc_avgPos;
		} else {
			(holdAO select 0)
		};
		
		_string = format ["Secure %1 and defend it while %2 forces move in to secure the area. If you cannot achieve this objective then extract from the AO and the rest of the force will attempt the assault alone.", (text (holdAO select 5)), playersFactionName];
		_taskCreated = ["taskExtract", true, [_string, "Take and Hold", ""], _avgPos, "CREATED", 5, true, true, "defend", true] call BIS_fnc_setTask;
		diag_log format ["DRO: Extract task created: %1", _taskCreated];
		
		["END_HOLD"] spawn DRO_fnc_sendProgressMessage;
		
		_holdAreaSize = ((holdAO select 1) / 4);
		_markerHold = createMarker ["mkrHold", _avgPos];
		_markerHold setMarkerShape "ELLIPSE";
		_markerHold setMarkerSize [_holdAreaSize, _holdAreaSize];
		_markerHold setMarkerBrush "Solid";		
		_markerHold setMarkerColor "ColorGreen";
		_markerHold setMarkerAlpha 0.5;
		
		// Send new enemies to chase players if stealth is not maintained
		diag_log 'DRO: Reinforcing due to mission completion';
		[_avgPos, [3,5]] execVM 'sunday_system\reinforce.sqf';
		if (!stealthActive) then {
			if (enemyCommsActive) then {
				
				// Make existing enemies close in on players
				[15, _markerHold] execVM 'sunday_system\generate_enemies\staggeredAttack.sqf';
				diag_log "DRO: Init staggered attack";	
			};
		};
		
		//sleep 3;
		
		// Extract option
		"mkrAOC" setMarkerAlpha 1;
		// Extraction success trigger
		trgExtract_b = createTrigger ["EmptyDetector", getPos trgAOC, true];
		trgExtract_b setTriggerArea [(triggerArea trgAOC) select 0, (triggerArea trgAOC) select 1, 0, true];
		trgExtract_b setTriggerActivation ["ANY", "PRESENT", false];
		trgExtract_b setTriggerStatements [
			"
				({vehicle _x in thisList} count allPlayers == 0) &&
				({alive _x} count allPlayers > 0)
			",
			"
				[] execVM 'sunday_system\endMission.sqf';
			",
			""
		];
		
		// Hold success trigger	
		waitUntil {(_playerGroupLeader distance _avgPos) < _holdAreaSize};
		_startTime = time;
		trgExtract = createTrigger ["EmptyDetector", _avgPos, true];
		trgExtract setTriggerArea [_holdAreaSize, _holdAreaSize, 0, true];
		trgExtract setTriggerActivation ["ANY", "PRESENT", false];
		trgExtract setTriggerStatements [
			"
				((({alive _x && side _x == enemySide} count thisList) < round (({alive _x && side _x == playersSide} count thisList)*0.25))) || 
				(({alive _x && side _x == enemySide} count thisList) <= 5) ||
				time > ((thisTrigger getVariable 'startTime') + 240)
			",
			"
				[] execVM 'sunday_system\endMission.sqf';
			",
			""
		];
		trgExtract setVariable ["startTime", _startTime, true];
		
		//["LeadTrack02_F_Mark"] remoteExec ["playMusic", 0];
	};
};
