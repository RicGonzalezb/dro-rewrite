// M10 REQ4: DRO_fnc_becomeLeader
// Runs on the new leader's client when topUnit disconnects during lobby phase.
// Called via remoteExec from initServer.sqf HandleDisconnect EH.
//
// LOCALITY NOTE: new leader may already be sitting at waitUntil{lobbyComplete==1}
// (initPlayerLocal.sqf). Opening the dialog here runs in its own execVM env — OK.
// camLobby guard in initPlayerLocal teardown handles the case where becomeLeader
// created camLobby (via populateLobby) after the non-leader skipped the auto-open.

// Idempotency guard: prevent double-run if somehow called twice
if (!isNil "DRO_becomeLeaderRunning") exitWith {};
DRO_becomeLeaderRunning = true;

hintSilent "You are now the party leader — configure and start the mission";

// If lobby is already complete, nothing to do
if ((missionNamespace getVariable ["lobbyComplete", 0]) == 1) exitWith {
    DRO_becomeLeaderRunning = nil;
};

// Open Team Planning if not already open; otherwise just re-enable the START button
if (isNull (findDisplay 626262)) then {
    // populateLobby will now see player == topUnit and show the START button
    CreateDialog "DRO_lobbyDialog";
    [] execVM "sunday_system\dialogs\populateLobby.sqf";
} else {
    // Dialog already open (player had opened it via addAction) — re-show START button
    ((findDisplay 626262) displayCtrl 1601) ctrlShow true;
    ((findDisplay 626262) displayCtrl 1601) ctrlEnable true;
};

DRO_becomeLeaderRunning = nil;
