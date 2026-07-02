params ["_AOIndex"];

if (count (((AOLocations select _AOIndex) select 2) select 4) > 0) then {	
	_pos = [(((AOLocations select _AOIndex) select 2) select 4)] call DRO_fnc_selectRemove; 
	_objects = (selectRandom compositionsEmplacements);	
	_spawnedObjects = [_pos, random 360, _objects] call BIS_fnc_ObjectsMapper;
	
	_numInf = [3,5] call BIS_fnc_randomInt;
	_dirMod = 360 / _numInf;
	_direction = (random 360);	
	_leader = nil;
	_leaderChosen = false;	
	for "_i" from 1 to _numInf step 1 do {	
		_spawnPos = [_pos, (5 + random 2), _direction] call DRO_fnc_extendPos;		
		_dirOut = [_pos, _spawnPos] call BIS_fnc_dirTo;
		_direction = _direction + _dirMod;		
		_guardGroup = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call DRO_fnc_spawnGroupWeighted;
		// M7 fix: guard contra grpNull/nil de spawnGroupWeighted
		if (isNil "_guardGroup" || {isNull _guardGroup} || {count (units _guardGroup) == 0}) then { continue };
		private _guardUnit = ((units _guardGroup) select 0);
		_guardUnit setFormDir _dirOut;
		_guardUnit setDir _dirOut;
		if (!_leaderChosen) then {
			_leader = _guardUnit;
			_leaderChosen = true;
		} else {
			[_guardUnit] joinSilent _leader;
			doStop _guardUnit;
		};
		if (random 1 > 0.6) then {
			[_guardUnit, (selectRandom ["STAND", "STAND_IA", "KNEEL", "WATCH", "WATCH1", "WATCH2"]), "ASIS"] call BIS_fnc_ambientAnimCombat;
		};
	};
	// LAMBS soft-compat: emplacement guard leader broadcasts contact at radio range.
	if (DRO_lambsCompat && {!isNil "_leader"}) then {
		_leader setVariable ["lambs_danger_dangerRadio", true, true];
	};

	// Create Marker
	_markerName = format["emplaceMkr%1", floor(random 10000)];
	_markerEmplace = createMarker [_markerName, _pos];			
	_markerEmplace setMarkerShape "ICON";
	_markerEmplace setMarkerType "hd_warning";
	_markerEmplace setMarkerText "Emplacement";			
	_markerEmplace setMarkerColor markerColorEnemy;
	_markerEmplace setMarkerAlpha 0;
	enemyIntelMarkers pushBack _markerEmplace;		
	travelPosPOIMil pushBack _pos;
};