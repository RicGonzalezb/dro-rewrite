// Migrated from DRO_fnc_stringCommaList — M3 CfgFunctions migration
params ["_strings"];
	_stringsCommas = "";	
	_stringsLast = "";
	if (count _strings > 1) then {
		_stringsLast = _strings call BIS_fnc_arrayPop;
		_stringsCommas = _strings joinString ", ";		
	} else {
		_stringsCommas = _strings select 0;
	};
	_stringsFull = if (count _stringsLast > 0) then {
		format ["%1 and %2", _stringsCommas, _stringsLast];
	} else {
		_stringsCommas;
	};
	_stringsFull;
