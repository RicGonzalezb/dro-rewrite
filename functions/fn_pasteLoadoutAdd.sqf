// Migrated from DRO_fnc_pasteLoadoutAdd — M3 CfgFunctions migration
_target = _this select 0;
	
	_actionIndex = _target addAction [
		"Paste Loadout",
		{
			_unit = _this select 1;
			_target = _this select 0;
			
			// Remove current loadout			
			_target removeWeaponGlobal (primaryWeapon _target);
			_target removeWeaponGlobal (secondaryWeapon _target);
			_target removeWeaponGlobal (handgunWeapon _target);
			removeUniform _target;
			removeVest _target;
			removeHeadgear _target;
			removeGoggles _target;
			removeBackpack _target;
			_target unassignItem hmd _target;
			_target removeItem hmd _target;	
			
			// Paste player's loadout
			_loadoutName = format ["loadout%1", _unit];
			[_unit, [missionNameSpace, _loadoutName]] call BIS_fnc_saveInventory;
			[_target, [missionNameSpace, _loadoutName]] call BIS_fnc_loadInventory;			
		},
		nil,
		1.5,
		false,
		false
	];
	
	// Record this action index for later removal
	_target setVariable ["loadoutAction", _actionIndex];
