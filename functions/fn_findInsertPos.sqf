// functions/fn_findInsertPos.sqf
// DRO_fnc_findInsertPos - find a usable ground insertion position, or [] if none exists.
//
// WHY THIS EXISTS
// BIS_fnc_findSafePos never signals failure out of band: it signals by RETURNING A VALUE.
// With no defaultPos it hands back [0,0,0]; with the [[0,0,0],[0,0,0]] defaultPos this
// mission passes everywhere, it hands back that literal TWO-element array. Both sail
// straight through a `count _pos == 0` check, and both put the FOB on the map origin.
// Worse, the two-element form breaks any `_pos select 0 < 80` style guard, because
// `select 0` is then an ARRAY, and comparing an array to a number errors out - so the
// caller's own safety check dies exactly when it is needed. DRO_fnc_validPos already
// catches both shapes; what was missing was doing something useful when it fires.
//
// The old caller also retried the SAME findSafePos call up to 20 times. That cannot work:
// if the requested annulus is off-map, all water, all road or too steep, identical
// parameters fail deterministically however many times you ask. Retrying only helps when
// the parameters change.
//
// So this is a LADDER of progressively looser searches, first match wins. Each rung is
// attempted a few times (findSafePos is itself random, so repeats within a rung are worth
// something), and every candidate is checked with DRO_fnc_validPos plus a world-border
// margin. The strict rungs also apply the caller's extra predicate; the loosest rungs drop
// that predicate and then the blacklist, so a cosmetic footprint rule can never be the
// reason the whole search fails.
//
// PARAMS
//   0 _center    (Array or Object)  search centre, normally the AO centre.
//   1 _minDist   (Number)           preferred minimum distance from _center.
//   2 _maxDist   (Number)           preferred maximum distance from _center.
//   3 _blacklist (Array)            blacklist handed to findSafePos on the strict rungs.
//   4 _extraTest (Code)             optional predicate, called as [_pos] call _extraTest,
//                                   must return Bool. Pass {true} to skip. Must be
//                                   self-contained - do not rely on the caller's locals.
//   5 _tag       (String)           log tag.
//   6 _maxRadius (Number)           hard cap on how far the ladder may reach from _center.
//                                   The looser rungs widen the search ring outward, which is
//                                   right for a ground insert (anywhere off-map-edge will do)
//                                   and wrong for an air insert, where the drop point has to
//                                   stay over the AO. Ground callers leave the default.
//
// RETURNS
//   Array - a validated position, or [] when every rung failed. Callers MUST handle the
//   empty return; having somewhere to fall back to is the entire point of this function.

params [
	["_center", [0,0,0]],
	["_minDist", 0],
	["_maxDist", 0],
	["_blacklist", []],
	["_extraTest", {true}],
	["_tag", "insert"],
	["_maxRadius", (worldSize * 0.45)]
];

// Keep clear of the world border: the engine will happily hand back a position a few
// metres from the edge, where half the FOB footprint falls off the map.
private _edgeMargin = 80;

// Rung: [minDist, maxDist, minObjDist, waterMode, gradient, shoreMode, useBlacklist, useExtraTest, tries]
private _ladder = [
	[_minDist,          _maxDist,            8, 0, 0.25, 0, true,  true,  6],
	[_minDist,          _maxDist,            4, 0, 0.40, 0, true,  true,  6],
	[_minDist,          (_maxDist * 1.5),    2, 0, 0.60, 0, true,  true,  6],
	[(_minDist * 0.6),  (_maxDist * 2),      2, 0, 0.80, 0, true,  false, 6],
	[(_minDist * 0.4),  (worldSize * 0.45),  2, 0, 1.00, 0, false, false, 8]
];

private _result = [];

{
	_x params ["_rMin", "_rMax", "_rObj", "_rWater", "_rGrad", "_rShore", "_rUseBL", "_rUseTest", "_rTries"];
	private _rungIndex = _forEachIndex;
	private _bl = if (_rUseBL) then { _blacklist } else { [] };

	// Clamp the rung's reach to the caller's cap. _rMin is then held strictly below the
	// clamped max: an inverted annulus (min > max) makes findSafePos return nothing at all,
	// which would silently turn every capped rung into a guaranteed miss.
	private _rMaxC = _rMax min _maxRadius;
	private _rMinC = _rMin min (_rMaxC * 0.9);

	for "_i" from 1 to _rTries do {
		private _candidate = [_center, _rMinC, _rMaxC, _rObj, _rWater, _rGrad, _rShore, _bl, [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;

		// validPos is called UNTAGGED on purpose: a miss on an early rung is expected, not
		// an incident, and tagging would spam the .rpt with dozens of REJECT lines a round.
		if ([_candidate] call DRO_fnc_validPos) then {
			private _px = _candidate select 0;
			private _py = _candidate select 1;
			if ((_px > _edgeMargin) && {_px < (worldSize - _edgeMargin)}
				&& {_py > _edgeMargin} && {_py < (worldSize - _edgeMargin)}) then {
				private _passesExtra = true;
				if (_rUseTest) then { _passesExtra = [_candidate] call _extraTest; };
				// isEqualTo true, not a bare truth test: a predicate that errors or returns
				// nil must count as a failure, never as a pass.
				if (_passesExtra isEqualTo true) then { _result = _candidate; };
			};
		};
		if (count _result > 0) exitWith {};
	};

	if (count _result > 0) exitWith {
		diag_log format ["DRO: findInsertPos [%1] - rung %2 succeeded: %3", _tag, _rungIndex, _result];
	};
	diag_log format ["DRO: findInsertPos [%1] - rung %2 exhausted (tries=%3 ring=%4..%5 minObj=%6 grad=%7 blacklist=%8 extraTest=%9)", _tag, _rungIndex, _rTries, round _rMinC, round _rMaxC, _rObj, _rGrad, _rUseBL, _rUseTest];
} forEach _ladder;

if (count _result == 0) then {
	diag_log format ["DRO: findInsertPos [%1] - FAILED. Every rung exhausted, no valid position exists for these constraints. Caller must fall back.", _tag];
};

_result
