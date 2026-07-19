// functions/fn_addAIToSquad.sqf
// DRO_fnc_addAIToSquad — M12 Team Planning "+1 AI". SERVER ONLY.
//
// Triggered by the leader's "+1 AI" button (dialogsLobby.hpp idc 1602) via
// remoteExec ["DRO_fnc_addAIToSquad", 2] (server target). Creates one AI in
// the squad's group (grpNetId), gives it a loadout from unitList (same pool
// the human loadout dropdown offers), tracks it in DRO_createdAI (creation
// order — used by fn_jipAIBump.sqf to bump the most recently added AI when a
// human needs the slot), and broadcasts a roster rebuild to every client.
//
// The new unit is created directly inside grpNetId's group (not joined via
// joinSilent afterwards), so it is already a full member of the group that
// fn_setPlayerGroup.sqf / setupPlayersFaction.sqf will carry into the mission
// once the leader presses START MISSION — no extra persistence plumbing
// needed (REQ6).

if (!isServer) exitWith {};

private _group = grpNetId call BIS_fnc_groupFromNetId;
if (isNull _group) exitWith {
	diag_log "DRO: addAIToSquad - grpNetId group is null, aborting";
};

private _maxSquad = missionNamespace getVariable ["DRO_maxSquad", 16];
if ((count (units _group)) >= _maxSquad) exitWith {
	diag_log format ["DRO: addAIToSquad - squad already at max (%1/%2), ignoring", count (units _group), _maxSquad];
};

if (isNil "DRO_createdAI") then { DRO_createdAI = []; };
if (isNil "unitList" || {count unitList == 0}) exitWith {
	diag_log "DRO: addAIToSquad - unitList empty, cannot pick a class yet (factions not ready?)";
};

private _class = (selectRandom unitList) select 0;
private _spawnPos = getPos (leader _group);
private _ai = _group createUnit [_class, _spawnPos, [], 0, "NONE"];

_ai setDir (getDir (leader _group));
_ai setVariable ["unitClass", _class, true];
_ai setVariable ["unitChoice", _class, true];
_ai setUnitLoadout (getUnitLoadout _class);
_ai call DRO_fnc_loadoutCompat;

// Mirror the "waiting in the lobby" state applied to the original editor-
// placed units at mission boot (start.sqf, units(group _topUnit) forEach) —
// invulnerable, AI disabled, captive — until fn_setPlayerGroup.sqf /
// setupPlayersFaction.sqf's final activation pass turns everything on.
[_ai, false] remoteExec ["allowDamage", _ai];
[_ai, "ALL"] remoteExec ["disableAI", _ai, false];
[_ai, true] remoteExec ["setCaptive", _ai, true];

// Give the AI a real identity (name/face/voice) + respawnIdentity, mirroring
// fn_generatePlayerIdentities.sqf. createUnit'd units have none, which shows "null" in
// the roster and CRASHES Open Arsenal (openArsenal.sqf reads respawnIdentity select 1..4).
if (!isNil "nameLookup" && {count nameLookup > 0}) then {
	private _idIdx = ((count (units _group)) - 1) min ((count nameLookup) - 1);
	private _identity = nameLookup select _idIdx;
	_ai setVariable ["respawnIdentity", [_ai, _identity select 0, _identity select 1, _identity select 2, _identity select 3], true];
	[_ai, _identity select 0, _identity select 1, _identity select 2, _identity select 3] remoteExec ["DRO_fnc_setNameMP", 0, true];
};

DRO_createdAI pushBack _ai;
publicVariable "DRO_createdAI";

diag_log format ["DRO: addAIToSquad - created %1 (class %2), squad now %3/%4", _ai, _class, count (units _group), _maxSquad];

[] remoteExec ["DRO_fnc_rebuildRoster", 0];
