// functions/fn_livingEntities.sqf
// DRO_fnc_livingEntities — filters a mixed array of objects and/or groups down to
// the entries that are still real and usable.
//
// THE POINT OF THIS FUNCTION
// `select {!isNull _x}` is the reflex guard and it is WRONG for groups. Deleting a
// unit (Zeus, script cleanup, mod despawn) removes the UNIT but leaves the GROUP:
// an emptied group is NOT grpNull, so isNull passes it through. That surviving shell
// keeps its waypoint cycle, stays in allGroups and stays registered with LAMBS,
// which is what produces the sustained "Object X:Y not found" bursts in the .rpt.
//
// Group liveness must be tested with `count units _x > 0`. Centralised here so the
// distinction is stated once instead of being re-derived (or forgotten) at each site.

params ["_entities"];

_entities select {
    if (_x isEqualType grpNull) then {
        !isNull _x && {count (units _x) > 0}
    } else {
        !isNull _x && {alive _x}
    }
}
