// Migrated from DRO_fnc_getArtilleryRanges — M3 CfgFunctions migration
private ["_turrets", "_vehicleMinRange", "_vehicleMaxRange", "_turretMinRange", "_turretMaxRange"];
	_turrets = [(_this select 0)] call BIS_fnc_getTurrets;
	_vehicleMinRange = 100000;
	_vehicleMaxRange = 0;
	{
		_modesToTest = [];
		_thisTurret = _x;
		_weapons = ((_thisTurret >> "weapons") call BIS_fnc_GetCfgData);	
		{		
			_thisWeapon = _x;
			_modes = ((configfile >> "CfgWeapons" >> _thisWeapon >> "modes") call BIS_fnc_GetCfgData);		
			{
				_weaponChild = _x;
				_weaponChildName = (configName _x);
				{
					if (_x == _weaponChildName) then {
						_modesToTest pushBackUnique _weaponChild;
					};
				} forEach _modes;
			} forEach ([(configfile >> "CfgWeapons" >> _thisWeapon), 0, true] call BIS_fnc_returnChildren);
			
		} forEach _weapons;	
		_turretMinRange = 100000;
		_turretMaxRange = 0;
		if (count _modesToTest > 0) then {
			{
				_minRange = ((_x >> "minRange") call BIS_fnc_GetCfgData);
				if (_minRange < _turretMinRange) then {_turretMinRange = _minRange};
				_maxRange = ((_x >> "maxRange") call BIS_fnc_GetCfgData);
				if (_maxRange > _turretMaxRange) then {_turretMaxRange = _maxRange};
			} forEach _modesToTest;	
		};	
		
		if (_turretMinRange < _vehicleMinRange) then {_vehicleMinRange = _turretMinRange};	
		if (_turretMaxRange > _vehicleMaxRange) then {_vehicleMaxRange = _turretMaxRange};

	} forEach _turrets;

	[_vehicleMinRange, _vehicleMaxRange];
