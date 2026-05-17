// Migrated from DRO_fnc_selectRemove / DRO_fnc_selectRemove (identical) — M3 CfgFunctions migration
_index = [0, (count (_this select 0) -1)] call BIS_fnc_randomInt;	
	private _return = (_this select 0) select _index;
	(_this select 0) deleteAt _index;
	_return;
