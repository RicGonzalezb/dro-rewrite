// sunday_system/dialogs/removeAI.sqf
// M12: rewritten for the "AI squad rework" — the checkbox created only on AI
// rows (functions/fn_rebuildRoster.sqf) is now a one-shot "remove" action, not
// a hide/restore toggle: AI are no longer auto-filled and hidden, they are
// created on demand by the leader (functions/fn_addAIToSquad.sqf) and removed
// on demand here — actually deleted server-side, never just hidden.
if (!isNull (_this select 0)) then {
	private _ai = (_this select 0);
	private _selection = ((_this select 1) select 2);

	if (_selection == 1) then {
		[_ai] remoteExec ["DRO_fnc_removeAIFromSquad", 2];
		[{ [] call DRO_fnc_rebuildRoster }, [], 0.35] call CBA_fnc_waitAndExecute;
	};
	// _selection == 0 (unchecked): no-op — once removed the row and its
	// checkbox no longer exist after the rebuild broadcast, so this branch
	// is effectively unreachable in normal use.
};
