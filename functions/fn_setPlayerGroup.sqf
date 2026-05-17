// Migrated from DRO_fnc_setPlayerGroup — M3 CfgFunctions migration
params ["_newPos"];
	_newGroup = createGroup playersSide;
	_playerGroupUnique = ((units (grpNetId call BIS_fnc_groupFromNetId) + ([] call CBA_fnc_players)) arrayIntersect (units (grpNetId call BIS_fnc_groupFromNetId) + ([] call CBA_fnc_players)));
	//(units (grpNetId call BIS_fnc_groupFromNetId)) joinSilent _newGroup;
	_playerGroupUnique joinSilent _newGroup;
	grpNetId = _newGroup call BIS_fnc_netId;
	publicVariable "grpNetId";
	{
		_x setPos _newPos;
		//_x enableAI "ALL";
		[_x, "ALL"] remoteExec ["enableAI", _x, false];
		[_x, false] remoteExec ["setCaptive", _x, true];		
	} forEach (units (grpNetId call BIS_fnc_groupFromNetId));
	
	newUnitsReady = true;
	publicVariable "newUnitsReady";
	diag_log format ["DRO: New Group Net ID is %1", grpNetId];
