// Migrated from DRO_fnc_findRoadRoute — M3 CfgFunctions migration
params ["_startRoad", "_maxRoads"];	
	private _roadArray = [_startRoad];
	_connectedRoads = roadsConnectedTo _startRoad;	
	_roadChoice1 = nil;	

	// Get initial connected road, selecting randomly if there are more than one
	switch (count _connectedRoads) do {
		case 0: {
			_roadChoice1 = nil;			
		};
		case 1: {
			_roadChoice1 = (_connectedRoads select 0);			
		};		
		default {
			_roadChoice1 = selectRandom _connectedRoads;					
		};
	};	
	
	if (!isNil "_roadChoice1") then {
		// Add the second connected road and start searching for the next		
		_roadArray pushBack _roadChoice1;
		_lastRoad = _roadChoice1;
		for "_i" from 1 to (_maxRoads-1) step 1 do {
			// Check for new connected roads
			_connectedRoads = roadsConnectedTo _lastRoad;
			if (count _connectedRoads > 0) then {
				// Filter out any roads that have been used already
				_filteredRoadArray = _connectedRoads;
				{
					if (_x in _roadArray) then {
						_filteredRoadArray = _filteredRoadArray - [_x];
					};
				} forEach _connectedRoads;
				// If no new roads are found then exit loop
				if (count _filteredRoadArray == 0) exitWith {};				
				// Add new road to the array and use it to start the next loop
				_thisRoad = selectRandom _filteredRoadArray;								
				_roadArray pushBack _thisRoad;
				_lastRoad = _thisRoad;				
			};
		};
	};
	_roadArray
