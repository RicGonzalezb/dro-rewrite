// DRO_fnc_spawnInsertArsenal
// Insertion Arsenal feature.
// Spawns a supply crate at the given position, fills it with the same
// consumables/explosives/group ammo as the original GROUND (FOB) insertion
// crate, initializes it as a persistent ACE arsenal box, adds an "Open Arsenal"
// scroll action for every client (including JIP), drops a map marker, and queues
// the force-rearm once players are ready. Shared single source used by every
// insertType (GROUND, HALO, HELI, NONE). Runs server-side.
//
// Params: [_pos] call DRO_fnc_spawnInsertArsenal
// Returns: the crate object, or objNull if it could not be created.

params [["_pos", [0, 0, 0], [[]]]];

// Arsenal toggle: when disabled via UI / lobby param, do not spawn insertion arsenal crates.
if ((missionNamespace getVariable ["arsenalEnabled", 0]) == 1) exitWith { objNull };

if (count _pos == 0) exitWith { objNull };

private _boxLocation = _pos findEmptyPosition [0, 20, "B_supplyCrate_F"];
if (count _boxLocation == 0) then {
	_boxLocation = _pos;
};

private _box = createVehicle ["B_supplyCrate_F", _boxLocation, [], 0, "NONE"];
if (isNil "sun_checkVehicleSpawn") then {
	sun_checkVehicleSpawn = DRO_fnc_checkVehicleSpawn;
};
_box = [_box] call sun_checkVehicleSpawn;

if (isNull _box) exitWith {
	diag_log "DRO: spawnInsertArsenal failed to create supply crate";
	objNull
};

// Map marker — tied 1:1 to the crate, name keyed off netId so repeated calls
// (one per insertType per round) never collide with each other or with the
// mid-AO "resupplyMkr". Offset 20m south of the crate so the icon doesn't render
// stacked on campMkr (Drop Point / LZ / FOB / Staging), which sits at the same spot.
private _mkrPos = [(_boxLocation select 0), ((_boxLocation select 1) - 20), 0];
private _mkrName = format ["insertArsenalMkr_%1", netId _box];
private _mkr = createMarker [_mkrName, _mkrPos];
_mkr setMarkerShape "ICON";
_mkr setMarkerType "mil_flag";
_mkr setMarkerColor markerColorPlayers;
_mkr setMarkerText "Spawn Point & Resupply";
_mkr setMarkerSize [0.6, 0.6];

// Fill the crate (mirrors the original GROUND / FOB crate).
clearWeaponCargoGlobal _box;
clearMagazineCargoGlobal _box;
clearItemCargoGlobal _box;

_box addMagazineCargoGlobal ["SatchelCharge_Remote_Mag", 2];
_box addMagazineCargoGlobal ["DemoCharge_Remote_Mag", 4];
_box addItemCargoGlobal ["Medikit", 1];
_box addItemCargoGlobal ["FirstAidKit", 10];
_box addItemCargoGlobal ["Toolkit", 1];
_box addItemCargoGlobal ["MineDetector", 1];

{
	private _magazines = magazinesAmmoFull _x;
	{
		_box addMagazineCargoGlobal [(_x select 0), 2];
	} forEach _magazines;
} forEach (units (grpNetId call BIS_fnc_groupFromNetId));

// Persistent ACE arsenal + an "Open Arsenal" scroll action for every client (JIP too).
// Runs server-side, so the addAction is remoteExec'd (target 0, JIP true) — a plain
// local addAction here would only ever exist on the server, invisible to clients.
if (DRO_aceArsenal) then {
	[_box, true, true] call ACE_arsenal_fnc_initBox;
	[_box, [
		"<t size='2'>Open Arsenal</t>",
		"[(_this select 0), (_this select 1), true] call ace_arsenal_fnc_openBox",
		nil, 6, true, true, "", "true", 3
	]] remoteExec ["addAction", 0, true];
} else {
	["AmmoboxInit", [_box, true]] call BIS_fnc_arsenal;
	[_box, [
		"<t size='2'>Open Arsenal</t>",
		"['Open', true] call BIS_fnc_arsenal",
		nil, 6, true, true, "", "true", 3
	]] remoteExec ["addAction", 0, true];
};

// Force-rearm once players exist. CBA (not spawn+waitUntil), mirroring the project pattern.
if (isNil "sun_supplyBox") then {
	sun_supplyBox = DRO_fnc_supplyBox;
};
[
	{ (missionNameSpace getVariable ["playersReady", 0]) == 1 },
	{
		params ["_box"];
		[_box] call sun_supplyBox;
	},
	[_box]
] call CBA_fnc_waitUntilAndExecute;

_box
