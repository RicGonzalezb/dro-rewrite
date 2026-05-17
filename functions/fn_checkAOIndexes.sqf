// Migrated from DRO_fnc_checkAOIndexes — M3 CfgFunctions migration
params ["_indexes"];
	_availableIndexes = [];
	{
		if (count (((AOLocations select _AOIndex) select 2) select _x) > 0) then {_availableIndexes pushBack _x};
	} forEach _indexes;	
	_availableIndexes
