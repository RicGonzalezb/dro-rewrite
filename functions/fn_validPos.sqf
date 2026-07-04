// Returns true when _pos is a usable on-map ground position: a >=3-element array, not
// [0,0,0], inside the world bounds. Catches BIS_fnc_findSafePos failures whether they
// return [0,0,0] (no default) or [[0,0,0],[0,0,0]] (count-2 default), and off-map values.
// Optional _tag: when a non-empty string is passed, a REJECT is logged to the .rpt so a
// skipped spawn is never silent. Untagged callers (e.g. AO position-pool building, where
// misses are normal) stay quiet to avoid spamming the log.
params [["_pos", []], ["_tag", ""]];
private _ok = (_pos isEqualType []) && {count _pos >= 3} && {!(_pos isEqualTo [0,0,0])} &&
{(_pos select 0) > 0} && {(_pos select 0) < worldSize} &&
{(_pos select 1) > 0} && {(_pos select 1) < worldSize};
if (!_ok && {_tag isEqualType "" && {_tag != ""}}) then {
	diag_log format ["DRO: validPos REJECT [%1] pos=%2 -> spawn skipped", _tag, _pos];
};
_ok
