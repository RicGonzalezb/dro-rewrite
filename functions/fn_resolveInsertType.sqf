// DRO_fnc_resolveInsertType - resolves the raw insertion-type selection into a concrete type.
// Param: _t (number) - raw selection (0=Random 1=Ground 2=HALO 3=Helicopter 4=None 5=Sea-Boat).
// Returns: concrete type (never 0). Random draws Ground/HALO/Helicopter, plus Sea-Boat when a
//   sea corridor is viable. Helicopter is downgraded to Ground/HALO under IF/SPE mods (no heli).
// Idempotent for already-resolved values (non-0, and non-3 or 3-without-mod).
params [["_t", insertType]];
if (_t == 0) then {
	private _pool = [1,2,3];
	if (missionNamespace getVariable ["DRO_seaInsertViable", false]) then { _pool pushBack 5; };
	_t = selectRandom _pool;
};
if (_t == 3) then {
	if (((configfile >> "CfgMods" >> "IF") call BIS_fnc_getCfgIsClass) || ((configfile >> "CfgMods" >> "SPE") call BIS_fnc_getCfgIsClass)) then {
		_t = [1,2] call BIS_fnc_randomInt;
	};
};
_t
