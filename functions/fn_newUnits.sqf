// Migrated from DRO_fnc_newUnits — M3 CfgFunctions migration
params ["_newPos"];
	
	sun_newUnitArray = [];
	publicVariable "sun_newUnitArray";
	{		
		//diag_log _x;	
		[_x, _newPos] remoteExec ["DRO_fnc_newUnit", _x, true];	
		waitUntil {
			//diag_log format ["DRO: units in sun_newUnitArray = %1, _forEachIndex+1 = %2", (count sun_newUnitArray), (_forEachIndex + 1)];
			((count sun_newUnitArray) >= (_forEachIndex + 1))
		};
	} forEach units (grpNetId call BIS_fnc_groupFromNetId);	
	//diag_log format ["DRO: units _newGroup = %1", (units _newGroup)];
	{
		//diag_log format ["DRO: this vehicleVarName = %1", (vehicleVarName _x)];
		waitUntil {
			//diag_log format ["DRO: this vehicleVarName = %1", (vehicleVarName _x)];
			((vehicleVarName _x) select [0,1]) == "u";
		};
		diag_log format ["DRO: this vehicleVarName after wait = %1", (vehicleVarName _x)];
	} forEach sun_newUnitArray;
	private _newGroup = createGroup playersSide;
	{
		[_x] joinSilent _newGroup;
	} forEach sun_newUnitArray;
	grpNetId = _newGroup call BIS_fnc_netId;
	diag_log format ["DRO: New group %3 with netID %1 containing %2", grpNetId, units (grpNetId call BIS_fnc_groupFromNetId), _newGroup];	
	publicVariable "grpNetId";
	newUnitsReady = true;
	publicVariable "newUnitsReady";	
	
	// Keep grpNetId variable assigned to player group if C2 is present.
	// Migrated from `[] spawn { while {true} do { ... } }` (no sleep — ran every
	// scheduled tick) to a CBA PFH with 1s delta. Guarded against double-init.
	if (isClass (configFile >> "CfgPatches" >> "C2_Core")) then {
		if (isNil "DRO_c2GrpNetIdGuardPFH") then {
			DRO_c2GrpNetIdGuardPFH = [{
				private _refreshNeeded = if (isNil "grpNetId") then { true } else {
					isNull (grpNetId call BIS_fnc_groupFromNetId)
				};
				if (_refreshNeeded) then {
					grpNetId = (group(([] call BIS_fnc_listPlayers) select 0)) call BIS_fnc_netId;
					publicVariable "grpNetId";
				};
			}, 1, []] call CBA_fnc_addPerFrameHandler;
		};
	};
