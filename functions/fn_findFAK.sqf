// Migrated from DRO_fnc_findFAK — M3 CfgFunctions migration
params ["_unit"];
	_list = _unit nearSupplies 150;
	_FAKLocations = [];
	{
		if ("FirstAidKit" in (items _x)) then {
			_FAKLocations pushBack _x;
		};
		if ("gm_ge_army_burnBandage" in (items _x)) then {
			_FAKLocations pushBack _x;
		};
		if ("gm_gc_army_gauzeBandage" in (items _x)) then {
			_FAKLocations pushBack _x;
		};
		if ("gm_ge_army_gauzeBandage" in (items _x)) then {
			_FAKLocations pushBack _x;
		};
		if ("gm_ge_army_gauzeCompress" in (items _x)) then {
			_FAKLocations pushBack _x;
		};
	} forEach _list;
	if (count _FAKLocations > 0) then {		
		_nearFAKs = [_FAKLocations,[],{_unit distance _x},"ASCEND"] call BIS_fnc_sortBy;
		_nearestFAK = _nearFAKs select 0;			
		[_unit, "I'm going to find a first aid kit!"] remoteExec ["groupChat", 0];
		_unit setVariable ["rev_revivingUnit", true, true];
		[_unit, _nearestFAK] spawn {
			_unit = _this select 0;
			_nearestFAK = _this select 1;
			while {(_unit distance _nearestFAK) >= 4} do {
				sleep 1;
				_unit doMove (getPos _nearestFAK);
				_unit moveTo (getPosATL _nearestFAK);
			};		
			_unit playAction "PutDown";	
			_nearestFAK removeItem "FirstAidKit";
			_unit addItem "FirstAidKit";
			_unit setVariable ["rev_revivingUnit", false, true];
		};
	};
