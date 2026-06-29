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

_vn_allowed_radio_backpacks = (missionConfigFile >> "vn_artillery_settings" >> "radio_backpacks") call BIS_fnc_getCfgDataArray;
missionNameSpace setVariable ["vn_allowed_radio_backpacks", _vn_allowed_radio_backpacks, true];
_vn_allowed_radio_vehicles = (missionConfigFile >> "vn_artillery_settings" >> "radio_vehicles") call BIS_fnc_getCfgDataArray;
missionNameSpace setVariable ["vn_allowed_radio_vehicles", _vn_allowed_radio_vehicles, true];

[] execVM "start.sqf";
