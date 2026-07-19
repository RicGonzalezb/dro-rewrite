// Migrated from DRO_fnc_createSimpleObject — M3 CfgFunctions migration
//
// _simple = true  -> engine createSimpleObject: VISUAL ONLY (no physics, no collision,
//                    no simulation), LOCAL to the calling machine. Use for decoration
//                    created client-side, e.g. the intel scatter.
// _simple = false -> legacy path: createVehicle with "CAN_COLLIDE", i.e. a full physical
//                    network object forced to the EXACT position. Next to a wall the prop
//                    spawns inside the building geometry and the physics engine ejects it
//                    violently, damaging or destroying the structure (reported: house
//                    collapsed while searching a body for intel). Kept as default for the
//                    server-side ambient props (craters/wrecks) every client must see.
params ["_class", "_pos", ["_dir", 0], ["_special", "CAN_COLLIDE"], ["_simple", false]];
private _object = objNull;
_pos set [2, 0];
if (_simple) then {
	_object = createSimpleObject [_class, (ATLToASL [(_pos select 0), (_pos select 1), 0])];
} else {
	_object = createVehicle [_class, _pos, [], 0, _special];
};
_object setDir _dir;
if (isNil "DRO_simpleObjects") then {DRO_simpleObjects = [_object]} else {DRO_simpleObjects pushBack _object};
_object
