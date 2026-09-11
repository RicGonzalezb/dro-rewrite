// functions/fn_orphanSweep.sqf
// DRO_fnc_orphanSweep — periodic janitor for orphaned groups and stale object lists.
//
// This is the ONLY cleanup path for deletions. The Curator hook that initServer.sqf used
// to advertise never worked - "CuratorObjectDeleted" is not a mission event handler, so
// the engine refused it every round (see the note in initServer.sqf). The sweep was
// already carrying the confirmed reproduction on its own: whatever
// emptied the group — Zeus, a raw deleteVehicle, the Civilian Presence Module's
// forced unit->agent conversion, or an ACE/mod cleanup — the empty shell is
// collected here.
//
// Runs server-side on a slow CBA PFH; the cost is one pass over allGroups.

if (!isServer) exitWith {};

private _playerGroup = grpNull;
private _gnid = missionNamespace getVariable ["grpNetId", ""];
if (_gnid != "") then { _playerGroup = _gnid call BIS_fnc_groupFromNetId; };
private _killed = 0;

{
    private _g = _x;
    if (count (units _g) == 0
        && {side _g != sideLogic}
        && {!(_g isEqualTo _playerGroup)}
    ) then {
        if (!isNil "patrolGroups") then { patrolGroups = patrolGroups - [_g]; };
        // No public setVariable here: broadcasting state on a group that is deleted
        // on the very next line is exactly the wasted-network-message pattern this
        // whole fix exists to remove. deleteGroup already unregisters it.
        deleteGroup _g;
        _killed = _killed + 1;
    };
} forEach allGroups;

// Compact the object registries so they cannot grow without bound across a long
// session and so later consumers never touch a dead reference.
if (!isNil "DRO_createdAI") then { DRO_createdAI = DRO_createdAI select { !isNull _x }; };
if (!isNil "DRO_simpleObjects") then { DRO_simpleObjects = DRO_simpleObjects select { !isNull _x }; };
if (!isNil "patrolGroups") then { patrolGroups = [patrolGroups] call DRO_fnc_livingEntities; };
