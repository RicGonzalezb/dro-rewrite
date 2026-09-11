#include "sunday_system\fnc_lib\sundayFunctions.sqf"

missionNameSpace setVariable ["factionDataReady", 0, true];
missionNameSpace setVariable ["weatherChanged", 0, true];
missionNameSpace setVariable ["factionsChosen", 0, true];
missionNameSpace setVariable ["arsenalComplete", 0, true];
missionNameSpace setVariable ["aoCamPos", [], true];
missionNameSpace setVariable ["dro_introCamReady", 0, true];
missionNameSpace setVariable ["dro_introCamComplete", 0, true];
missionNameSpace setVariable ["briefingReady", 0, true];
missionNameSpace setVariable ["playersReady", 0, true];
missionNameSpace setVariable ["publicCampName", "", true];
missionNameSpace setVariable ["startPos", [], true];
missionNameSpace setVariable ["initArsenal", 0, true];
missionNameSpace setVariable ["allArsenalComplete", 0, true];
missionNameSpace setVariable ["aoComplete", 0, true];
missionNameSpace setVariable ["objectivesSpawned", 0, true];
missionNameSpace setVariable ["aoLocationName", "", true];
missionNameSpace setVariable ["aoLocation", "", true];
missionNameSpace setVariable ["lobbyComplete", 0, true];

// M10 REQ4: leader handover guard — prevents lobby lock if topUnit disconnects before start
addMissionEventHandler ["HandleDisconnect", {
    params ["_unit"];
    if (!isNil "topUnit" && {_unit isEqualTo topUnit} && {(missionNamespace getVariable ["lobbyComplete", 0]) != 1}) then {
        private _rem = (call BIS_fnc_listPlayers) - [_unit];
        if (count _rem > 0) then {
            topUnit = _rem select 0;
            publicVariable "topUnit";
            [] remoteExec ["DRO_fnc_becomeLeader", topUnit];
        };
    };
    false // must return false (HandleDisconnect contract)
}];

// Orphan-entity cleanup. Deleting a unit leaves its GROUP behind; the empty group
// keeps replicating (waypoint cycle, LAMBS registration) and the engine then logs
// "Server: Object X:Y not found (message Type_N)" thousands of times for the
// unit+group pair. Confirmed reproduction: a Zeus deleting a server-spawned unit
// that still has background scripts driving it.
//
// There used to be an addMissionEventHandler ["CuratorObjectDeleted", ...] here. DO NOT
// PUT IT BACK in that form. Three separate reasons:
//   1. "CuratorObjectDeleted" is a CURATOR event handler, not a mission one. The engine
//      rejected it outright every single round with
//        Foreign error: Unknown enum value: "CuratorObjectDeleted"
//      so the handler was never registered and never fired - it was log noise attached to
//      nothing. Curator EHs go on a curator logic via `addEventHandler`, not here.
//   2. Even written correctly, a curator EH fires where the CURATOR IS LOCAL - the Zeus
//      player's client - while DRO_fnc_untrackEntity is server-only by design (it edits
//      server-side tracking lists and calls deleteGroup on server-local groups). It would
//      need an explicit remoteExec hop to the server, which nothing here ever had.
//   3. mission.sqm ships NO curator module (the only assignCurator in the project, in
//      setupPlayersFaction.sqf, is inside a commented-out block), so on a vanilla run
//      there is no curator logic to attach to in the first place.
// Coverage is unaffected: DRO_fnc_orphanSweep below is death-cause agnostic and collects
// exactly the same orphans, whatever deleted the unit. If a Zeus mod is ever in play and
// the 300s sweep interval turns out to be too slow, the correct shape is a client-side
// hook on `getAssignedCuratorLogic player` that remoteExecs the cleanup to the server.

addMissionEventHandler ["EntityKilled", {
    params ["_unit"];
    [{ _this call DRO_fnc_untrackEntity; }, [_unit], 5] call CBA_fnc_waitAndExecute;
}];

// Death-cause agnostic janitor. Starts only after mission generation has finished,
// so it never collects groups that are legitimately empty mid-spawn.
[{ (missionNamespace getVariable ["objectivesSpawned", 0]) == 1 }, {
    DRO_orphanSweepPFH = [DRO_fnc_orphanSweep, 300, []] call CBA_fnc_addPerFrameHandler;
}] call CBA_fnc_waitUntilAndExecute;

_vn_allowed_radio_backpacks = (missionConfigFile >> "vn_artillery_settings" >> "radio_backpacks") call BIS_fnc_getCfgDataArray;
missionNameSpace setVariable ["vn_allowed_radio_backpacks", _vn_allowed_radio_backpacks, true];
_vn_allowed_radio_vehicles = (missionConfigFile >> "vn_artillery_settings" >> "radio_vehicles") call BIS_fnc_getCfgDataArray;
missionNameSpace setVariable ["vn_allowed_radio_vehicles", _vn_allowed_radio_vehicles, true];

[] execVM "start.sqf";
