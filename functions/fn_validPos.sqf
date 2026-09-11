// functions/fn_validPos.sqf
// DRO_fnc_validPos - true when _pos is a usable on-map position.
//
// THE THING THIS FILE EXISTS TO GET RIGHT
// BIS_fnc_findSafePos returns a TWO-element [x, y] position on SUCCESS. It signals failure
// by returning a value too: [0,0,0] with no defaultPos, or whatever defaultPos was passed -
// and this mission passes [[0,0,0],[0,0,0]] everywhere, which is ALSO two elements.
// So `count` cannot tell success from failure, and the previous `count _pos >= 3` test
// rejected every single successful findSafePos result. Observed in the .rpt as
//   "DRO: validPos REJECT [bunker] pos=[9680.39,11293.2] -> spawn skipped"
// on positions that are perfectly fine - bunkers, resupply and the player insert were all
// being silently skipped.
//
// What actually separates the two is the TYPE OF THE ELEMENTS:
//   success          -> [9680.39, 11293.2]        slots 0/1 are Numbers
//   failure, default -> [[0,0,0],[0,0,0]]         slots 0/1 are Arrays
//   failure, no def  -> [0,0,0]                   Numbers, but 0,0 - caught by the bounds
// Hence: >= 2 elements, slots 0 and 1 are scalars, and the point is inside the world.
//
// Optional _tag: when a non-empty string is passed, a REJECT is logged to the .rpt so a
// skipped spawn is never silent. Untagged callers (e.g. AO position-pool building, where
// misses are normal) stay quiet to avoid spamming the log.

params [["_pos", []], ["_tag", ""]];

private _ok = false;
if (_pos isEqualType [] && {count _pos >= 2}) then {
	private _px = _pos select 0;
	private _py = _pos select 1;
	if (_px isEqualType 0 && {_py isEqualType 0}) then {
		_ok = (_px > 0) && {_px < worldSize} && {_py > 0} && {_py < worldSize};
	};
};

if (!_ok && {_tag isEqualType "" && {_tag != ""}}) then {
	diag_log format ["DRO: validPos REJECT [%1] pos=%2 -> spawn skipped", _tag, _pos];
};
_ok
