// DRO_fnc_selectRemove — selects and removes a random element from the passed array (mutates it)
// Usage: [_array] call DRO_fnc_selectRemove → returns removed element, or objNull if empty
// Migrated from sun_selectRemove / dro_selectRemove (identical) — M3 CfgFunctions migration
params [["_arr", []]];
if (_arr isEqualTo []) exitWith { objNull };
private _index = [0, (count _arr) - 1] call BIS_fnc_randomInt;
private _return = _arr select _index;
_arr deleteAt _index;
_return
