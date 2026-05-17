// Migrated from DRO_fnc_reviveUnit — M3 CfgFunctions migration
private ["_unit", "_medic"];
	_unit = _this select 0;
	_medic = _this select 1;
	
	//diag_log format ["DRO: Unit %1 is revived by medic %2", _unit, _medic];	
	if (isPlayer _unit) then {
		//diag_log format ["DRO: Revive of %1 processed as a player unit", _unit];		
		[] remoteExec ["DRO_fnc_resetCamera", _unit];	
		[_unit, false] remoteExec ["setUnconscious", _unit];		
		[_unit, true] remoteExec ["allowDamage", _unit];
		[_unit, false] remoteExec ["setCaptive", _unit];		
	} else {
		if (local _unit) then {
			//diag_log format ["DRO: Revive of %1 processed as a local AI unit", _unit]; 
			_unit setUnconscious false;			
			_unit allowDamage true;
			_unit setCaptive false;
		} else {
			//diag_log format ["DRO: Revive of %1 processed as a non-local AI unit", _unit]; 
			[_unit, false] remoteExec ["setUnconscious", _unit];		
			[_unit, true] remoteExec ["allowDamage", _unit];
			[_unit, false] remoteExec ["setCaptive", _unit];
		};
	};

	[(format ["DRO: Unit %1 is revived by medic %2", _unit, _medic])] remoteExec ["diag_log", 2];
	
	if ("Medikit" in (items _medic) OR "gm_gc_army_medkit" in (items _medic) OR "gm_ge_army_medkit_80" in (items _medic)) then {
		_unit setDamage 0;	
	} else {
		if ("FirstAidKit" in (items _medic) OR "gm_ge_army_burnBandage" in (items _medic) OR "gm_gc_army_gauzeBandage" in (items _medic) OR "gm_ge_army_gauzeBandage" in (items _medic) OR "gm_ge_army_gauzeCompress" in (items _medic)) then {
			_medic removeItem "FirstAidKit";
			if !(isClass(configFile >> "CfgPatches" >> "ace_medical")) then {_unit setDamage 0.4};					
		} else {
			if !(isClass(configFile >> "CfgPatches" >> "ace_medical")) then {_unit setDamage 0.75};			
		};
	};

	if !("FirstAidKit" in (items _medic) OR "Medikit" in (items _medic)) then {
		diag_log format ["Revive: %1 is out of medical supplies", _medic];
		_string = selectRandom ["I'm out of medical supplies.", "That was my last first aid kit.", "Going to need more medical supplies."];
		[_medic, _string] remoteExec ["groupChat", 0];
		
	};

	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_beingAssisted", false, true];
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_dragged", false, true];
		
	/*
	if (group _unit != group _medic) then {
		[_unit] joinSilent group _medic;
	};
	*/
