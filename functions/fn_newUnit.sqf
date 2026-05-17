// Migrated from DRO_fnc_newUnit — M3 CfgFunctions migration
params ["_oldUnit", "_newPos"];	
	diag_log format ["DRO: Changing unit %1", _oldUnit];
	private _loadout = getUnitLoadout _oldUnit;
	private _face = face _oldUnit;
	private _speaker = speaker _oldUnit;
	private _class = _oldUnit getVariable ["unitClass", ""];
	private _identity = (_oldUnit getVariable ["respawnIdentity", []]);	
	if (count _class == 0) then {
		_class = ((selectRandom unitList) select 0);
	};	
	private _tempGroup = createGroup playersSide;
	private _newUnit = _tempGroup createUnit [_class, _newPos, [], 0, "NONE"];
	setPlayable _newUnit;
	addSwitchableUnit _newUnit;	
	if (isPlayer _oldUnit) then {
		 _newUnit remoteExec ["selectPlayer", _oldUnit];
	};	
	private _varName = format ["u%1", ((vehicleVarName _oldUnit) select [1])];
	diag_log format ["DRO: New unit %1 created for %2 with class %3", _newUnit, _oldUnit, _class];
	deleteVehicle _oldUnit;
	diag_log format ["DRO: Setting new unit %1 to var %2", _newUnit, _varName];
	[_newUnit, _varName] remoteExec ["setVehicleVarName", 0, true];
	missionNamespace setVariable [_varName, _newUnit, true];
	waitUntil {
		diag_log format ["DRO: Waiting for %1", (missionNamespace getVariable _varName)];
		!isNull (missionNamespace getVariable _varName)
	};
	
	_newUnit setUnitLoadout _loadout;	
	if (count _identity > 0) then {
		_newUnit setVariable ["respawnIdentity", [_newUnit,  _identity select 1, _identity select 2, _speaker, _face], true];
		[_newUnit, _identity select 1, _identity select 2, _speaker, _face] remoteExec ["DRO_fnc_setNameMP", 0, true];		
	};
	//diag_log _newGroup;
	sun_newUnitArray pushBack _newUnit;
	publicVariable "sun_newUnitArray";
	//[_newUnit] joinSilent _newGroup;
	
	_newUnit setVariable ["respawnLoadout", (getUnitLoadout _newUnit), true];
	_newUnit setVariable ["respawnPWeapon", [(primaryWeapon  _newUnit), primaryWeaponItems _newUnit], true];	
	_newUnit setUnitTrait ["Medic", true];
	_newUnit setUnitTrait ["engineer", true];
	_newUnit setUnitTrait ["explosiveSpecialist", true];
	_newUnit setUnitTrait ["UAVHacker", true];

	_newUnit setUnitTrait ["ACE_medical_medicClass", true, true];
	_newUnit setUnitTrait ["ACE_IsEngineer", true, true];
	_newUnit setUnitTrait ["ACE_isEOD", true, true];
	
	if ((["SOGPFRadioSupportTrait", 0] call BIS_fnc_getParamValue) == 1) then {
		_newUnit setUnitTrait ["vn_artillery", true, true];
	};
	
	_newUnit setCaptive false;
