// functions/fn_untrackEntity.sqf
// DRO_fnc_untrackEntity — best-effort removal of a single entity from every
// mission-side tracking list, plus disposal of the group it leaves behind.
//
// WHY THIS EXISTS
// Deleting a unit (Zeus/Curator, script cleanup, or any non-Killed path) removes
// the UNIT but NOT its GROUP. An emptied group is still a live, network-replicated
// object: it keeps its waypoint cycle, it stays in allGroups, and it stays
// registered with LAMBS via lambs_danger_enableGroupReinforce (generateEnemies.sqf).
// Background loops and mods keep driving that ghost group, and the engine emits
// "Server: Object X:Y not found (message Type_N)" for every replication attempt.
// That is the observed unit+group PAIR pattern in the .rpt (two consecutive netIds
// with identical hit counts, thousands of repeats each).
//
// NOTE: isNull is NOT sufficient to detect this. An emptied group is not grpNull,
// so `select {!isNull _x}` lets exactly this orphan through. Group liveness must be
// tested with `count units _x > 0`.
//
// Server-only: all tracking lists below are server-side, and deleteGroup must run
// where the group is local (groups spawned by the mission are server-local).

if (!isServer) exitWith {};

params ["_entity"];

private _group = grpNull;

if (_entity isEqualType grpNull) then {
    _group = _entity;
} else {
    if (_entity isEqualType objNull && {!isNull _entity}) then {
        _group = group _entity;
        if (!isNil "DRO_createdAI") then { DRO_createdAI = DRO_createdAI - [_entity]; };
        if (!isNil "DRO_simpleObjects") then { DRO_simpleObjects = DRO_simpleObjects - [_entity]; };
    };
};

if (isNull _group) exitWith {};

if (!isNil "patrolGroups") then { patrolGroups = patrolGroups - [_group]; };

// Dispose of the group only once it is genuinely empty, never the player group,
// and never a logic/module group (curator modules live in allGroups too).
// grpNetId may not exist yet during early mission init, hence the guarded read.
private _playerGroup = grpNull;
private _gnid = missionNamespace getVariable ["grpNetId", ""];
if (_gnid != "") then { _playerGroup = _gnid call BIS_fnc_groupFromNetId; };

if (count (units _group) == 0
    && {side _group != sideLogic}
    && {!(_group isEqualTo _playerGroup)}
) then {
    // deleteGroup disposes the waypoints and the LAMBS registration; setting group
    // variables here would only queue network messages for an object about to vanish.
    deleteGroup _group;
};
