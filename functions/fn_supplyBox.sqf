// Migrated from DRO_fnc_supplyBox — M3 CfgFunctions migration
params ["_box", "_boxName", "_actionStr"];
	_boxName = (configFile >> "CfgVehicles" >> (typeOf _box) >> "displayName") call BIS_fnc_GetCfgData;
	_actionStr = format ["Force rearm at %1", _boxName];
	[_box, [
		_actionStr,
		{
			_unit = (_this select 1);
			
			_primaryWeapon = [primaryWeapon (_this select 1)] call BIS_fnc_baseWeapon;
			_secondaryWeapon = secondaryWeapon (_this select 1);
			//_handgun = [handgunWeapon (_this select 1)] call BIS_fnc_baseWeapon;
			
			if (count _primaryWeapon > 0) then {
				_unit addMagazines [(((configfile >> "CfgWeapons" >> _primaryWeapon >> "magazines") call BIS_fnc_getCfgData) select 0), 5];
			};
			if (count _secondaryWeapon > 0) then {
				_unit addMagazines [(((configfile >> "CfgWeapons" >> _secondaryWeapon >> "magazines") call BIS_fnc_getCfgData) select 0), 2];
			};
			/*
			if (count _handgun > 0) then {
				_unit addMagazines [(((configfile >> "CfgWeapons" >> _handgun >> "magazines") call BIS_fnc_getCfgData) select 0), 2];
			};
			*/
		},
		[],
		20,
		false,
		false,
		"",
		"!isPlayer (_this)",
		200,
		false
	]] remoteExec ["addAction", 0, true];
