// Returns true when _pos is a usable on-map ground position: a >=3-element array, not
// [0,0,0], inside the world bounds. Catches BIS_fnc_findSafePos failures whether they
// return [0,0,0] (no default) or [[0,0,0],[0,0,0]] (count-2 default), and off-map values.
// Use before spawning anything at a findSafePos / randomPos-derived position.
params [["_pos", []]];
(_pos isEqualType []) && {count _pos >= 3} && {!(_pos isEqualTo [0,0,0])} &&
{(_pos select 0) > 0} && {(_pos select 0) < worldSize} &&
{(_pos select 1) > 0} && {(_pos select 1) < worldSize}
