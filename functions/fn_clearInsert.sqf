// Migrated from DRO_fnc_clearInsert — M3 CfgFunctions migration
deleteMarker 'campMkr';
	{
		[626262, 6006, "Insertion position: RANDOM"] remoteExec ["DRO_fnc_lobbyChangeLabel", _x];	
	} forEach allPlayers;
