// Migrated from DRO_fnc_jipNewUnit — M3 CfgFunctions migration
params ["_oldUnit", "_newPos"];	
	
	private _class = player getVariable ["unitClass", ""];
	if (count _class == 0) then {
		_class = ((selectRandom unitList) select 0);
	};
	
	player setVariable ["unitClass", _class, true];
	player setUnitLoadout (getUnitLoadout _class);
	
	player call DRO_fnc_loadoutCompat;
	
	_playerID = parseNumber ((str player) select [1, 1]);
	_identity = (nameLookup select _playerID);
	player setVariable ["respawnIdentity", [player,  _identity select 0, _identity select 1, _identity select 2, _identity select 3], true];
	[player, _identity select 0, _identity select 1, _identity select 2, _identity select 3] remoteExec ["DRO_fnc_setNameMP", 0, true];
	
	/*
	private _newUnit = _newGroup createUnit [_class, _newPos, [], 0, "NONE"];
	setPlayable _newUnit;
	addSwitchableUnit _newUnit;
	selectPlayer _newUnit;
	private _varName = format ["u%1", ((vehicleVarName _oldUnit) select [1,1])];
	[_newUnit, _varName] remoteExec ["setVehicleVarName", 0, true];
	missionNamespace setVariable [_varName, _newUnit, true];
	waitUntil {!isNull (missionNamespace getVariable _varName)};
	_newUnit setUnitLoadout _loadout;
	private _identity = (_oldUnit getVariable ["respawnIdentity", []]);	
	if (count _identity > 0) then {
		_newUnit setVariable ["respawnIdentity", [_newUnit,  _identity select 1, _identity select 2, _speaker, _face], true];
		[_newUnit, _identity select 1, _identity select 2, _speaker, _face] remoteExec ["DRO_fnc_setNameMP", 0, true];
	};
	diag_log format ["DRO: New unit %1 created for %2 with class %3", _newUnit, _oldUnit, _class];
	//deleteVehicle _oldUnit;
	*/
	
	// M12: free a slot from lobby-created AI if the squad is already full
	// before this player joins (server-authoritative; see fn_jipAIBump.sqf).
	[player] remoteExec ["DRO_fnc_jipAIBump", 2];
	[player] joinSilent (grpNetId call BIS_fnc_groupFromNetId);
	player setPos _newPos;
	player setVariable ["respawnLoadout", (getUnitLoadout player), true];
	player setVariable ["respawnPWeapon", [(primaryWeapon  player), primaryWeaponItems player], true];
	if (reviveDisabled < 3) then {
		[player] call DRO_fnc_addReviveToUnit;
	};	
	player setUnitTrait ["Medic", true];
	player setUnitTrait ["engineer", true];
	player setUnitTrait ["explosiveSpecialist", true];
	player setUnitTrait ["UAVHacker", true];
	
	player setCaptive false;
	
	if ((["Stamina", 0] call BIS_fnc_getParamValue) > 0) then {
		player setAnimSpeedCoef 1;
		player enableFatigue false;
		player enableStamina false;
		if (!isNil "ace_advanced_fatigue_enabled") then {
			[missionNamespace, ["ace_advanced_fatigue_enabled", false]] remoteExec ["setVariable", player];
		};
	};
