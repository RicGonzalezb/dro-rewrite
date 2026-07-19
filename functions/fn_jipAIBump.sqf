// functions/fn_jipAIBump.sqf
// DRO_fnc_jipAIBump — M12 Team Planning "+1 AI" — JIP backfill. SERVER ONLY.
//
// params: [_joiningPlayer] — called by fn_jipNewUnit.sqf right before a
// newly-connected human joins grpNetId's group. If the squad is already at
// (or somehow above) DRO_maxSquad, deletes the most-recently-created lobby AI
// (last entry of DRO_createdAI, i.e. LIFO — last-added AI is bumped first) to
// make room, and warns ONLY the leader via a local systemChat (remoteExec
// targeted at topUnit specifically, not broadcast).
//
// NOTE: whether this ever actually fires depends on whether AI added in the
// lobby consume a "slot" the same way editor-placed playable slots do. They
// are additive members of grpNetId's group, not tied to a specific playable
// slot index, so in practice JIP humans join their OWN pre-assigned slot
// independently of AI headcount and this bump path may rarely or never
// trigger. It is implemented so the (b)/(d) mental-test guarantee — a human
// is never blocked or short of a slot by AI — holds even if that assumption
// turns out to be wrong for a given server config.
params [["_joiningPlayer", objNull, [objNull]]];

if (!isServer) exitWith {};

private _group = grpNetId call BIS_fnc_groupFromNetId;
if (isNull _group) exitWith {};

private _maxSquad = missionNamespace getVariable ["DRO_maxSquad", 16];

if ((count (units _group)) >= _maxSquad) then {
	if (!isNil "DRO_createdAI" && {count DRO_createdAI > 0}) then {
		private _bumped = DRO_createdAI select (count DRO_createdAI - 1);
		DRO_createdAI deleteAt (count DRO_createdAI - 1);
		publicVariable "DRO_createdAI";

		private _joiningName = if (!isNull _joiningPlayer) then { name _joiningPlayer } else { "a new player" };
		diag_log format ["DRO: jipAIBump - squad full (%1/%2), bumping %3 to make room for %4", count (units _group), _maxSquad, _bumped, _joiningName];

		if (!isNull _bumped) then { deleteVehicle _bumped; };

		if (!isNil "topUnit" && {!isNull topUnit}) then {
			[format ["AI removed to make room for %1", _joiningName]] remoteExec ["systemChat", topUnit];
		};

		[] remoteExec ["DRO_fnc_rebuildRoster", 0];
	} else {
		diag_log format ["DRO: jipAIBump - squad full (%1/%2) but no lobby AI available to bump for %3", count (units _group), _maxSquad, _joiningPlayer];
	};
};
