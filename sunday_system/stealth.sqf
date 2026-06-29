// Optional "Maintain Stealth" objective + detection monitor.
// Migrated from scheduled `while {stealthActive} do { sleep 1; ... }` (+ nested spawn/sleep grace timers
// and a top-level `sleep 30` assault stagger) to CBA: PFH for the poll, waitAndExecute for all delays.
// No top-level sleep remains -> caller (setupPlayersFaction) invokes via `call`.

_taskDesc = "Maintain stealth by avoiding enemies or taking them out before they can alert other squads.";
_taskTitle = "Optional: Maintain Stealth";
DRO_stealthTaskID = ["taskStealth", true, [_taskDesc, _taskTitle, ""], nil, "CREATED", 0, true, true, "listen"] call BIS_fnc_setTask;
stealthActive = true;

// Enemy group leaders that can still raise the alarm (global: mutated from PFH + grace callbacks).
alertableLeaders = (allGroups select {side _x == enemySide}) apply {leader _x};

// --- Detection monitor: PFH delta 1s (replaces while {stealthActive} do { sleep 1 }) ---
if (isNil "DRO_stealthMonitorPFH") then {
	DRO_stealthMonitorPFH = [{
		params ["_args", "_pfhId"];

		// Stealth broken -> remove self and run the consequence once.
		if (!stealthActive) exitWith {
			[_pfhId] call CBA_fnc_removePerFrameHandler;
			DRO_stealthMonitorPFH = nil;

			// Fail the optional task.
			[DRO_stealthTaskID, "FAILED", true] spawn BIS_fnc_taskSetState;

			if (enemyCommsActive) then {
				// Alarm sound at each AO, auto-deleted after 120s.
				{
					private _alarm = createSoundSource ["Sound_Alarm", (_x select 0), [], 0];
					[{ deleteVehicle (_this select 0) }, [_alarm], 120] call CBA_fnc_waitAndExecute;
				} forEach AOLocations;

				// Staggered assault: nearby enemy groups attack the players, 30s apart.
				private _playerLeader = leader (grpNetId call BIS_fnc_groupFromNetId);
				private _grpArray = enemyAlertableGroups select { (leader _x) distance _playerLeader < 600 };
				{
					[{
						params ["_grp"];
						while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
						[_grp, getPos (leader (grpNetId call BIS_fnc_groupFromNetId))] call BIS_fnc_taskAttack;
					}, [_x], (_forEachIndex * 30)] call CBA_fnc_waitAndExecute;
				} forEach _grpArray;
			};
		};

		// Still stealthy: scan enemy leaders for detection of any player-group unit.
		{
			private _thisLeader = _x;
			if (alive _thisLeader) then {
				{
					private _target = _x;
					private _knowsAbout = ((group _thisLeader) knowsAbout _target);
					if (_knowsAbout >= 1.5) exitWith {
						// Stop polling this leader until the grace re-check decides.
						alertableLeaders = alertableLeaders - [_thisLeader];

						private _sentence = selectRandom [
							"I've been spotted, we need to take these guys out fast!",
							"They've seen me! We need to take them out now!",
							"I'm compromised, we've got to eliminate these guys before they raise the alarm!"
						];
						[_target, _sentence] remoteExec ["groupChat", 0];

						// Grace period: re-check after 30*(5-knowsAbout)s; alarm only if still detected.
						[{
							params ["_thisLeader", "_target", "_knowsAbout"];
							if (!alive _thisLeader) exitWith { diag_log "DRO: Alert avoided (leader dead)"; };
							if ((_thisLeader knowsAbout _target) >= _knowsAbout) then {
								stealthActive = false;
								diag_log format ["DRO: Alarm raised by %1", _thisLeader];
							} else {
								alertableLeaders pushBackUnique _thisLeader;
								diag_log "DRO: Alert avoided";
							};
						}, [_thisLeader, _target, _knowsAbout], (30 * (5 - _knowsAbout))] call CBA_fnc_waitAndExecute;
					};
				} forEach (units (grpNetId call BIS_fnc_groupFromNetId));
			};
		} forEach alertableLeaders;
	}, 1, []] call CBA_fnc_addPerFrameHandler;
};
