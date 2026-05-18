// Migrated from DRO_fnc_helicopterCanFly — M3 CfgFunctions migration
// Hotfix: macro `aliveVeh` precisa estar definido no escopo desta função
// (CfgFunctions compila o arquivo isolado, sem ver #defines do caller).
#define aliveVeh(none) (none getHitPointDamage "hitHull") < 0.7
params ["_heli", "_return"];
	_return = true;
	//if (alive _heli && alive (driver _heli)) then { //#LordShadeAceVeh
	if ((aliveVeh(_heli)) && (alive (driver _heli))) then { //#LordShadeAceVeh
		_damageTypes = [
			["HitEngine", 0.4],
			["HitHRotor", 0.5],
			["HitVRotor", 0.5],
			["HitTransmission", 1.0],
			["HitHydraulics", 0.9]
		];		
		{
			if (_heli getHitPointDamage (_x select 0) > (_x select 1)) exitWith {
				_return = false;
			};			
		} forEach _damageTypes;		  
	} else {
		_return = true;
	};
	_return;
