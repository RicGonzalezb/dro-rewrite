// Cycle / refresh the ENEMY ARMOR control (idc 2075, value text 2078), showing only the
// levels allowed by the current game mode: Sniper hides HIGH; Combined Arms hides NONE and
// LOW; Recon / Current Settings show all four. Stores the ABSOLUTE level in mechLevel
// (0=None, 1=Low, 2=Standard, 3=High). Called with [true] on click, [false] to refresh.
params [["_change", true]];
private _names = ["NONE", "LOW", "STANDARD", "HIGH"];
private _allowed = switch (missionPreset) do {
	case 2: {[0, 1, 2]};    // Sniper: None, Low, Standard
	case 3: {[2, 3]};       // Combined Arms: Standard, High
	default {[0, 1, 2, 3]}; // Recon / Current Settings: all
};
private _cur = if (isNil "mechLevel") then {2} else {mechLevel};
private _pos = _allowed find _cur;
private _lo = _allowed select 0;
private _hi = _allowed select (count _allowed - 1);
private _next = if (_change && {_pos >= 0}) then {
	_allowed select ((_pos + 1) mod (count _allowed))
} else {
	// refresh, or click while out of range -> clamp into the allowed band
	if (_pos >= 0) then {_cur} else {(_cur max _lo) min _hi}
};
mechLevel = _next;
publicVariable "mechLevel";
profileNamespace setVariable ["DRO_mechLevel", _next];
ctrlSetText [2078, (_names select _next)];
