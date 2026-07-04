// DRO_fnc_boatInsertion — piloted boat insertion (naval analog of fn_heliInsertion).
// Server-side. Uses the water corridor computed at generation (start.sqf):
//   DRO_seaSpawnPos (offshore), DRO_seaDropPos (shallow shore), DRO_seaCorridor.
// Spawns N B_Boat_Transport_01_F with bot pilots, loads the player group, rails each
// boat down a parallel lane of the corridor, force-ejects passengers at the drop
// (proximity OR timeout), then sends the boats back to spawn to be deleted.
// Boat class is fixed by design (no faction scan).

if (!DRO_seaInsertViable || {count DRO_seaSpawnPos == 0} || {count DRO_seaDropPos == 0}) exitWith {
	diag_log "DRO: boatInsertion aborted — sea corridor not viable.";
	false
};

private _boatClass = "B_Boat_Transport_01_F";
private _spawnPos  = +DRO_seaSpawnPos;
private _dropPos   = +DRO_seaDropPos;
private _fwd  = [_spawnPos, _dropPos] call BIS_fnc_dirTo;
private _perp = _fwd + 90;

// Spawn the player group at the offshore start. sun_setPlayerGroup joins the squad into a NEW
// group and reassigns grpNetId, so the group/units MUST be resolved AFTER it runs — a handle
// captured before points at the now-empty old group (that was the "1 boat, nobody aboard" bug).
[_spawnPos] remoteExec ["sun_setPlayerGroup"];
waitUntil {newUnitsReady};
sleep 2;

private _grp     = grpNetId call BIS_fnc_groupFromNetId;
private _players = (units _grp) - [objNull];
private _seats      = count (_boatClass call BIS_fnc_vehicleRoles);
private _paxPerBoat = (_seats - 1) max 1;
private _numBoats   = (ceil ((count _players) / _paxPerBoat)) max 1;

// Spawn boats with bot pilots, on parallel lanes at the offshore start.
private _boats = [];
for "_bi" from 0 to (_numBoats - 1) do {
	private _off = (_bi - (_numBoats - 1) / 2) * 25;
	private _bearing = if (_off < 0) then { _perp + 180 } else { _perp };
	private _bpos = _spawnPos getPos [abs _off, _bearing];
	private _empty = _bpos findEmptyPosition [0, 30, _boatClass];
	if (count _empty > 0) then { _bpos = _empty; };
	private _boat = createVehicle [_boatClass, _bpos, [], 0, "NONE"];
	_boat setDir _fwd;
	_boat allowDamage false;
	// Pilot: 1-man group from the PLAYERS' faction (correct side/faction), invulnerable and
	// passive (careless, captive, no targeting, no dynamic sim) for the whole insertion.
	private _bg = [_bpos, playersSide, pInfClassesForWeights, pInfClassWeights, [1,1], false] call DRO_fnc_spawnGroupWeighted;
	if ((!isNull _bg) && {(count (units _bg)) > 0}) then {
		private _pilot = (units _bg) select 0;
		_pilot allowDamage false;
		_pilot moveInDriver _boat;
		_bg setBehaviour "CARELESS";
		_bg setCombatMode "BLUE";
		[_pilot, true] remoteExec ["setCaptive", _pilot, true];
		_pilot disableAI "TARGET";
		_pilot disableAI "AUTOTARGET";
	};
	waitUntil {!isNull (driver _boat)};
	_boats pushBack _boat;
};

// Distribute the squad across boats.
private _pi = 0;
{
	private _thisBoat = _x;
	private _cap = _paxPerBoat min ((count _players) - _pi);
	if (_cap > 0) then {
		private _assign = [];
		for "_j" from 0 to (_cap - 1) do {
			_assign pushBack (_players select _pi);
			_pi = _pi + 1;
		};
		[_assign, _thisBoat] spawn sun_groupToVehicle;
	};
} forEach _boats;

// Wait until the squad is actually aboard before the boats move off — otherwise the
// boats drive away in CARELESS/FULL and leave the players swimming at the spawn.
private _tBoard = time + 20;
waitUntil { sleep 0.5; (({!isNull objectParent _x} count _players) >= (count _players)) || (time > _tBoard) };

// Rail each boat down its own parallel lane of the corridor to an offset drop.
{
	private _boat = _x;
	private _bg = group (driver _boat);
	private _off = (_forEachIndex - (_numBoats - 1) / 2) * 20;
	private _bearing = if (_off < 0) then { _perp + 180 } else { _perp };
	while {count (waypoints _bg) > 0} do { deleteWaypoint ((waypoints _bg) select 0); };
	{
		private _cp = _x getPos [abs _off, _bearing];
		private _wp = _bg addWaypoint [_cp, 0];
		_wp setWaypointType "MOVE";
		_wp setWaypointSpeed "FULL";
		_wp setWaypointBehaviour "CARELESS";
	} forEach DRO_seaCorridor;
	private _thisDrop = _dropPos getPos [abs _off, _bearing];
	// Offset can push the target onto land or into a deep pocket; fall back to the validated base drop.
	if (!(surfaceIsWater _thisDrop) || {(getTerrainHeightASL _thisDrop) < -4}) then { _thisDrop = +_dropPos; };
	// Aim the final waypoint onto the beach (past the drop) so the boat keeps coming all the way in;
	// the strong approach decel makes it arrive slowly (~0.4 m) instead of ramming/beaching.
	private _beachWp = _thisDrop getPos [35, _fwd];
	private _wpD = _bg addWaypoint [_beachWp, 0];
	_wpD setWaypointType "MOVE";
	_wpD setWaypointSpeed "LIMITED";
	_boat setVariable ["DRO_seaDrop", _thisDrop, true];
} forEach _boats;

// Nearest DRY LAND from the drop toward the AO — the beach the squad wades onto. This becomes
// the landing (beach) / respawn point and where the insertion arsenal spawns (like other insert types).
private _landRef = missionNamespace getVariable ["DRO_seaOrigin", centerPos];
private _landDir = [_dropPos, _landRef] call BIS_fnc_dirTo;
private _land = [];
private _ld = 0;
while { (count _land == 0) && (_ld <= 500) } do {
	private _lp = _dropPos getPos [_ld, _landDir];
	if (!surfaceIsWater _lp) then { _land = [_lp select 0, _lp select 1, 0]; };
	_ld = _ld + 10;
};
if (count _land == 0) then { _land = _dropPos; };
_land = _land getPos [12, _landDir];
private _lem = _land findEmptyPosition [0, 40];
if (count _lem > 0) then { _land = [_lem select 0, _lem select 1, 0]; };
_land set [2, 0];
DRO_seaLandPos = _land;
publicVariable "DRO_seaLandPos";

// Landing (beach) start marker on dry land.
deleteMarker "campMkr";
missionNameSpace setVariable ["publicCampName", "Landing Zone", true];
publicVariable "publicCampName";
markerPlayerStart = createMarker ["campMkr", _land];
markerPlayerStart setMarkerShape "ICON";
markerPlayerStart setMarkerColor markerColorPlayers;
markerPlayerStart setMarkerType "mil_start";
markerPlayerStart setMarkerText "Sea Insert";

// Mission start position on land so briefing/respawn/JIP use the beach.
missionNameSpace setVariable ["startPos", _land, true];
publicVariable "startPos";

// Insertion arsenal crate at the landing (beach) point (same as the other insertion types).
[_land] call DRO_fnc_spawnInsertArsenal;

// Force-eject + RTB monitor (server). Ejects each boat's passengers when it reaches its
// drop OR after a timeout, then sends the boat back to spawn to be deleted.
// NOTE (MP): eject uses remoteExec of "GetOut" action on each passenger's owner — validate in MP.
if (isNil "DRO_seaInsertPFH") then {
	DRO_seaInsertPFH = [{
		params ["_args", "_pfhId"];
		_args params ["_boats", "_spawnPos", "_t0"];
		private _remaining = 0;
		{
			private _boat = _x;
			if (!isNull _boat && {alive _boat} && {!(_boat getVariable ["DRO_seaEjected", false])}) then {
				_remaining = _remaining + 1;
				private _drop = _boat getVariable ["DRO_seaDrop", _spawnPos];
				private _bpos = getPos _boat;
				private _depth = getTerrainHeightASL _bpos;
				private _dist = _boat distance2D _drop;
				private _spd = speed _boat;
				// Stall tracking: boats often refuse the last shallow metres and stop short of the drop.
				// Detect the stall and eject there instead of idling until the timeout.
				private _last = _boat getVariable ["DRO_seaLastPos", _bpos];
				private _moved = _bpos distance2D _last;
				_boat setVariable ["DRO_seaLastPos", _bpos];
				private _stall = _boat getVariable ["DRO_seaStall", 0];
				if ((_spd < 3) && (_moved < 4)) then { _stall = _stall + 1; } else { _stall = 0; };
				_boat setVariable ["DRO_seaStall", _stall];
				private _pastSpawn = (_boat distance2D _spawnPos) > 120;
				private _arrived   = (_dist < 50) && (_depth > -2);
				private _wadeable  = (_depth > -1.5) && (_dist < 160);   // primary disembark: in <=1.5m water
				private _stuckNear = (_stall >= 4) && _pastSpawn;        // stuck (deep or shallow) -> forced, boat nosed onto drop below
				// [DIAG - remove after tuning] per-boat eject state each tick.
				diag_log format ["DRO SEA eject-check boat=%1 dist=%2 depth=%3 spd=%4 stall=%5 arr=%6 wade=%7 stuck=%8", _boat, round _dist, (round (_depth*10))/10, round _spd, _stall, _arrived, _wadeable, _stuckNear];
				// Decelerate on approach so the boat noses into the shallows instead of ramming/grounding.
				if (_dist < 60) then { _boat limitSpeed (7 max (_dist * 0.5)); };   // slow in the last 60m but keep momentum to reach the shallow drop (>3km/h so it isn't flagged as stalled)
				if (_arrived || _wadeable || _stuckNear || {(time - _t0) > 180}) then {
					{
						if (_x != (driver _boat)) then {
							_boat disableCollisionWith _x;                        // don't run units over on exit (boat side)
							[_x, _boat] remoteExec ["disableCollisionWith", _x]; // unit side, on its owner
							[_x, ["GetOut", _boat]] remoteExec ["action", _x];
							unassignVehicle _x;
						};
					} forEach (crew _boat);
					_boat setVariable ["DRO_seaEjected", true, true];
					_boat limitSpeed 300;   // release the approach cap for the RTB run
					private _g = group (driver _boat);
					while {count (waypoints _g) > 0} do { deleteWaypoint ((waypoints _g) select 0); };
					private _wb = _g addWaypoint [_spawnPos, 0];
					_wb setWaypointType "MOVE";
					_wb setWaypointSpeed "FULL";
					_wb setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this)); deleteVehicle (vehicle this);"];
					// Guaranteed cleanup: the RTB waypoint statement only fires if the boat reaches spawn.
					// If it gets stuck (obstacle/pathing), delete it, its crew and its group anyway after a timeout.
					[{
						params ["_boat", "_grp"];
						if (!isNull _boat) then {
							{ deleteVehicle _x } forEach (crew _boat);
							deleteVehicle _boat;
						};
						if (!isNull _grp) then { deleteGroup _grp };
					}, [_boat, _g], 300] call CBA_fnc_waitAndExecute;
				};
			};
		} forEach _boats;
		if ((_remaining == 0) || {(time - _t0) > 480}) then { [_pfhId] call CBA_fnc_removePerFrameHandler; };
	}, 2, [_boats, _spawnPos, time]] call CBA_fnc_addPerFrameHandler;
};

true
