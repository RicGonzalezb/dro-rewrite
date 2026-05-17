// Migrated from DRO_fnc_goat — M3 CfgFunctions migration
{
		if (side _x != playersSide) then {
			_unit = _x;		
			_unit hideObjectGlobal true;
			_goat = createVehicle ["Goat_random_F", getPos _unit, [], 0, "NONE"];
			_goat attachTo [_unit, [0, 0, 0], "Pelvis"];
		};
	} forEach allunits;
