// Migrated from DRO_fnc_lobbyReadyButton — M3 CfgFunctions migration
// M10 REQ3: leader-only START MISSION — replaces per-player ready toggle
// Non-leaders have the button hidden; this guard is belt-and-suspenders
if (player != topUnit) exitWith {};
missionNamespace setVariable ["lobbyComplete", 1, true];
