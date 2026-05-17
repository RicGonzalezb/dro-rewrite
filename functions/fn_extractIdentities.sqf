// Migrated from DRO_fnc_extractIdentities — M3 CfgFunctions migration
params ["_baseClass", ["_side", civilian]];
	
	// Names
	_genericNames = ((configFile >> "CfgVehicles" >> _baseClass >> "genericNames") call BIS_fnc_GetCfgData);		
	_genericNames = if (isNil "_genericNames") then {"CivMen"} else {_genericNames};
	_firstNameClass = (configFile >> "CfgWorlds" >> "GenericNames" >> _genericNames >> "FirstNames");
	_firstNames = [];
	for "_i" from 0 to count _firstNameClass - 1 do {
		_firstNames pushBack (getText (_firstNameClass select _i));
	};
	_lastNameClass = (configFile >> "CfgWorlds" >> "GenericNames" >> _genericNames >> "LastNames");
	_lastNames = [];
	for "_i" from 0 to count _lastNameClass - 1 do {
		_lastNames pushBack (getText (_lastNameClass select _i));
	};
	
	// Voices
	_identityTypes = ((configFile >> "CfgVehicles" >> _baseClass >> "identityTypes") call BIS_fnc_GetCfgData);
	// Extract voice data
	_speakersArray = [];
	{
		_thisVoice = (configName _x);	
		_scopeVar = typeName ((configFile >> "CfgVoice" >> _thisVoice >> "scope") call BIS_fnc_GetCfgData);
		switch (_scopeVar) do {
			case "STRING": {
				if ( ((configFile >> "CfgVoice" >> _thisVoice >> "scope") call BIS_fnc_GetCfgData) == "public") then {		
					{
						if (typeName _x == "STRING") then {
							_thisVoiceID = _x;
							{
								if ([_x, _thisVoiceID, false] call BIS_fnc_inString) then {						
									_speakersArray pushBack _thisVoice;
								};
							} forEach _identityTypes;						
						};
					} forEach ((configFile >> "CfgVoice" >> _thisVoice >> "identityTypes") call BIS_fnc_GetCfgData);
				};	
			};		
			case "SCALAR": {
				if ( ((configFile >> "CfgVoice" >> _thisVoice >> "scope") call BIS_fnc_GetCfgData) == 2) then {		
					{			
						if (typeName _x == "STRING") then {
							_thisVoiceID = _x;
							{
								if ([_x, _thisVoiceID, false] call BIS_fnc_inString) then {						
									_speakersArray pushBack _thisVoice;
								};
							} forEach _identityTypes;
						};
					} forEach ((configFile >> "CfgVoice" >> _thisVoice >> "identityTypes") call BIS_fnc_GetCfgData);
				};	
			};		
		};	
	} forEach ("true" configClasses (configFile / "CfgVoice"));

	if (count _speakersArray == 0) then {	
		switch (_side) do {
			case west: {_speakersArray = ["Male01ENG", "Male02ENG", "Male03ENG", "Male04ENG", "Male05ENG", "Male06ENG", "Male07ENG", "Male08ENG", "Male10ENG", "Male11ENG", "Male12ENG", "Male01ENGB", "Male02ENGB", "Male03ENGB", "Male04ENGB", "Male05ENGB"]};
			case east: {_speakersArray = ["Male01PER", "Male02PER", "Male03PER"]};
			case resistance: {_speakersArray = ["Male01GRE", "Male02GRE", "Male03GRE", "Male04GRE", "Male05GRE", "Male06GRE"]};
			case civilian: {_speakersArray = ["Male01GRE", "Male02GRE", "Male03GRE", "Male04GRE", "Male05GRE", "Male06GRE"]};
		};	
	};
	
	// Faces	
	_faces = [];	
	{
		{		
			_thisFace = (configName _x);
			{
				_thisIDType = _x;
				{
					if ([_thisIDType, _x, false] call BIS_fnc_inString) then {						
						_faces pushBack _thisFace;
					};
				} forEach _identityTypes;				
			} forEach ((_x >> "identityTypes") call BIS_fnc_GetCfgData);
		} forEach ([(configFile >> "CfgFaces" >> (configName _x)), 0, false] call BIS_fnc_returnChildren);
	} forEach ("true" configClasses (configFile / "CfgFaces"));
	
	[_firstNames, _lastNames, _speakersArray, _faces]
