/*
 * DRO_fnc_generatePlayerIdentities
 *
 * Reads first/last names from CfgWorlds GenericNames, extracts matching
 * voices from CfgVoice and faces from CfgFaces based on faction identity
 * types, then generates 24 identities and assigns them to playerGroup via
 * remoteExec DRO_fnc_setNameMP. Also sets initArsenal signal.
 *
 * Globals set:   nameLookup (publicVariable), pFacesArray, eFacesArray,
 *                initArsenal (publicVariable)
 * Globals read:  pGenericNames, pIdentityTypes, eIdentityTypes,
 *                playersSide, playerGroup
 *
 * Note: _speakersArray, _firstNames, _lastNames are intentionally local
 *       — they are not needed outside this function.
 */

// Setup player identities
_firstNameClass = (configFile >> "CfgWorlds" >> "GenericNames" >> pGenericNames >> "FirstNames");
_firstNames = [];
for "_i" from 0 to count _firstNameClass - 1 do {
	_firstNames pushBack (getText (_firstNameClass select _i));
};
_lastNameClass = (configFile >> "CfgWorlds" >> "GenericNames" >> pGenericNames >> "LastNames");
_lastNames = [];
for "_i" from 0 to count _lastNameClass - 1 do {
	_lastNames pushBack (getText (_lastNameClass select _i));
};

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
						} forEach pIdentityTypes;						
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
						} forEach pIdentityTypes;
					};
				} forEach ((configFile >> "CfgVoice" >> _thisVoice >> "identityTypes") call BIS_fnc_GetCfgData);
			};	
		};		
	};	
} forEach ("true" configClasses (configFile / "CfgVoice"));

if (count _speakersArray == 0) then {	
	switch (playersSide) do {
		case west: {_speakersArray = ["Male01ENG", "Male02ENG", "Male03ENG", "Male04ENG", "Male05ENG", "Male06ENG", "Male07ENG", "Male08ENG", "Male10ENG", "Male11ENG", "Male12ENG", "Male01ENGB", "Male02ENGB", "Male03ENGB", "Male04ENGB", "Male05ENGB"]};
		case east: {_speakersArray = ["Male01PER", "Male02PER", "Male03PER"]};
		case resistance: {_speakersArray = ["Male01GRE", "Male02GRE", "Male03GRE", "Male04GRE", "Male05GRE", "Male06GRE"]};
	};	
};

diag_log format ["DRO: Available voices: %1", _speakersArray];

// Extract face data
pFacesArray = [];
eFacesArray = [];
{
	{		
		_thisFace = (configName _x);
		{
			_thisIDType = _x;
			{
				if ([_thisIDType, _x, false] call BIS_fnc_inString) then {						
					pFacesArray pushBack _thisFace;
				};
			} forEach pIdentityTypes;
			{
				if ([_thisIDType, _x, false] call BIS_fnc_inString) then {						
					eFacesArray pushBack _thisFace;
				};
			} forEach eIdentityTypes;
		} forEach ((_x >> "identityTypes") call BIS_fnc_GetCfgData);
	} forEach ([(configFile >> "CfgFaces" >> (configName _x)), 0, false] call BIS_fnc_returnChildren);
} forEach ("true" configClasses (configFile / "CfgFaces"));

diag_log format ["DRO: Available player faces: %1", pFacesArray];
diag_log format ["DRO: Available enemy faces: %1", eFacesArray];

// Change units to correct ethnicity and voices
nameLookup = [];
// Generate 24 identities
if (count _speakersArray > 0) then {
	for "_p" from 0 to 23 do {		
		_firstName = selectRandom _firstNames;
		_lastName = selectRandom _lastNames;
		_speaker = selectRandom _speakersArray;
		_face = selectRandom pFacesArray;		
		nameLookup pushBack [_firstName, _lastName, _speaker, _face];					
	};
};
// Assign identities to players
{		
	_identity = (nameLookup select _forEachIndex);
	[_x, (_identity select 0), (_identity select 1), (_identity select 2), (_identity select 3)] remoteExec ["DRO_fnc_setNameMP", 0, true];
	_x setVariable ["respawnIdentity", [_x, (_identity select 0), (_identity select 1), (_identity select 2), (_identity select 3)], true];	
} forEach playerGroup;
publicVariable "nameLookup";

missionNameSpace setVariable ["initArsenal", 1];
publicVariable "initArsenal";
