// Migrated from DRO_fnc_lobbyReadyButton — M3 CfgFunctions migration
// M10 REQ3: leader-only START MISSION — replaces per-player ready toggle
// Non-leaders have the button hidden; this guard is belt-and-suspenders
if (player != topUnit) exitWith {};
// Resolve the effective insert type here (locked before START proceeds) so SEA can be validated.
// Random may now roll SEA when a sea corridor exists (DRO_fnc_resolveInsertType).
private _eff = [insertType] call DRO_fnc_resolveInsertType;

// SEA + custom insertion point: block START if the chosen point has no viable sea corridor.
// Leave insertType as the raw selection so a re-press re-resolves (re-rolls if it was Random).
if (_eff == 5 && {count customPos > 0} && {!(([customPos] call DRO_fnc_findSeaCorridor) select 0)}) exitWith {
	cutText ["<t color='#ff0000' size='1.5' align='center' shadow='1'>Bad sea insertion point <br/>select another insertion position</t>", "PLAIN", -1, true, true];
};

// Valid (or non-SEA): lock the resolved type and complete the lobby.
insertType = _eff;
publicVariable "insertType";
missionNamespace setVariable ["lobbyComplete", 1, true];
