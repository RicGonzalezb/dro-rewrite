// functions/fn_removeAIFromSquad.sqf
// DRO_fnc_removeAIFromSquad — M12 Team Planning "+1 AI". SERVER ONLY.
//
// params: [_ai] — triggered by the per-row remove checkbox created only on
// AI rows in fn_rebuildRoster.sqf (see sunday_system/dialogs/removeAI.sqf,
// which remoteExecs here). Deletes the AI unit outright, drops it from
// DRO_createdAI, and broadcasts a roster rebuild. Refuses to touch human
// players — this is a hard guard, not just a UI-level restriction, since
// humans never get a remove control created in the first place.
params [["_ai", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _ai) exitWith {};
if (isPlayer _ai) exitWith {
	diag_log format ["DRO: removeAIFromSquad - refused, %1 is a human player", _ai];
};

if (!isNil "DRO_createdAI") then {
	DRO_createdAI = DRO_createdAI - [_ai];
	publicVariable "DRO_createdAI";
};

diag_log format ["DRO: removeAIFromSquad - deleting %1", _ai];
deleteVehicle _ai;

[] remoteExec ["DRO_fnc_rebuildRoster", 0];
