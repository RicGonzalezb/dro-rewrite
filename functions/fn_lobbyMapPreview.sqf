// Migrated from DRO_fnc_lobbyMapPreview — M3 CfgFunctions migration
closeDialog 1;
	camLobby cameraEffect ["terminate","back"];
	camUseNVG false;
	camDestroy camLobby;	
	_mapOpen = openMap [true, false];
	mapAnimAdd [0, 0.05, markerPos "centerMkr"];
	mapAnimCommit;
	player switchCamera "INTERNAL";
	waitUntil {!visibleMap};	
	_handle = CreateDialog "DRO_lobbyDialog";
	[] execVM "sunday_system\dialogs\populateLobby.sqf";
