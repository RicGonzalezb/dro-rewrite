// Migrated from DRO_fnc_removeEnemyNVG — M3 CfgFunctions migration
{
		if (side _x != playersSide) then {
			_unit = _x;		
			_nvgs = hmd _unit;			
			_unit unassignItem _nvgs;
			_unit removeItem _nvgs;			
			_unit removePrimaryWeaponItem "acc_pointer_IR";   
			_unit addPrimaryWeaponItem "acc_flashlight";
			if (sunOrMoon < 0.9) then {
				_unit enableGunLights missionAIWeaponLight;
			};
		};
	} forEach allunits;
