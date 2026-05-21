/*
 * DRO_fnc_extractFactionData
 *
 * Scans CfgVehicles to collect factions that have infantry units,
 * filters by side validity, then populates and publicVariables:
 *   availableFactionsData       — factions with > 1 infantry unit
 *   availableFactionsDataNoInf  — factions with 0-1 infantry units (vehicles only)
 *
 * Also sets missionNameSpace variable "factionDataReady" = 1 when done.
 *
 * Globals set:   availableFactionsData, availableFactionsDataNoInf, factionDataReady
 * Globals read:  (none — reads from configFile)
 */

// Check for factions that have units
_availableFactions = [];
availableFactionsData = [];
availableFactionsDataNoInf = [];
_unavailableFactions = [];
//_factionsWithUnits = [];
_factionsWithNoInf = [];
_factionsWithUnitsFiltered = [];
// Record all factions with valid vehicles
{
	if (isNumber (configFile >> "CfgVehicles" >> (configName _x) >> "scope")) then {
		if (((configFile >> "CfgVehicles" >> (configName _x) >> "scope") call BIS_fnc_GetCfgData) == 2) then {
			_factionClass = ((configFile >> "CfgVehicles" >> (configName _x) >> "faction") call BIS_fnc_GetCfgData);
			//_factionsWithUnits pushBackUnique _factionClass;		
			if ((configName _x) isKindOf "Man") then {
				_index = ([_factionsWithUnitsFiltered, _factionClass] call BIS_fnc_findInPairs);
				if (_index == -1) then {
					_factionsWithUnitsFiltered pushBack [_factionClass, 1];
				} else {
					_factionsWithUnitsFiltered set [_index, [((_factionsWithUnitsFiltered select _index) select 0), ((_factionsWithUnitsFiltered select _index) select 1)+1]];
				}; 
			};		
		};
	};
} forEach ("(configName _x) isKindOf 'AllVehicles'" configClasses (configFile / "CfgVehicles"));
// Filter factions with 1 or less infantry units
/*
{
	_factionsWithUnitsFiltered pushBack [_x, 0];
} forEach _factionsWithUnits;
{		
	_index = [_factionsWithUnitsFiltered, ((configFile >> "CfgVehicles" >> (configName _x) >> "faction") call BIS_fnc_GetCfgData)] call BIS_fnc_findInPairs; 
	if (_index > -1) then {		
		_factionsWithUnitsFiltered set [_index, [((_factionsWithUnitsFiltered select _index) select 0), ((_factionsWithUnitsFiltered select _index) select 1)+1]];
	};
} forEach ("(configName _x) isKindOf 'Man'" configClasses (configFile / "CfgVehicles"));
*/
diag_log format ["DRO: _factionsWithUnitsFiltered = %1", _factionsWithUnitsFiltered];

// Filter out factions that have no vehicles
{
	_thisFaction = (_x select 0);
	_thisSideNum = ((configFile >> "CfgFactionClasses" >> _thisFaction >> "side") call BIS_fnc_GetCfgData);
	//diag_log format ["DRO: Fetching faction info for %1", _thisFaction];	
	//diag_log format ["DRO: faction sideNum = %1", _thisSideNum];
	if (!isNil "_thisSideNum") then {
		if (typeName _thisSideNum == "TEXT") then {
			if ((["west", _thisSideNum, false] call BIS_fnc_inString)) then {
				_thisSideNum = 1;
			};
			if ((["east", _thisSideNum, false] call BIS_fnc_inString)) then {
				_thisSideNum = 0;
			};
			if ((["guer", _thisSideNum, false] call BIS_fnc_inString) || (["ind", _thisSideNum, false] call BIS_fnc_inString)) then {
				_thisSideNum = 2;
			};
		};	
		
		if (typeName _thisSideNum == "SCALAR") then {
			if (_thisSideNum <= 3 && _thisSideNum > -1) then {
					
				_thisFactionName = ((configFile >> "CfgFactionClasses" >> _thisFaction >> "displayName") call BIS_fnc_GetCfgData);			
				_thisFactionFlag = ((configfile >> "CfgFactionClasses" >> _thisFaction >> "flag") call BIS_fnc_GetCfgData);
				
				if ((_x select 1) <= 1) then {
					if (!isNil "_thisFactionFlag") then {
						availableFactionsDataNoInf pushBack [_thisFaction, _thisFactionName, _thisFactionFlag, _thisSideNum];
					} else {
						availableFactionsDataNoInf pushBack [_thisFaction, _thisFactionName, "", _thisSideNum];
					};
				} else {				
					if (!isNil "_thisFactionFlag") then {
						availableFactionsData pushBack [_thisFaction, _thisFactionName, _thisFactionFlag, _thisSideNum];
					} else {
						availableFactionsData pushBack [_thisFaction, _thisFactionName, "", _thisSideNum];
					};
				};
						
			};	
		};
	};
} forEach _factionsWithUnitsFiltered;

publicVariable "availableFactionsData";
publicVariable "availableFactionsDataNoInf";

{
	diag_log format ["DRO: availableFactionsData %2: %1", _x, _forEachIndex];
} forEach availableFactionsData;
{
	diag_log format ["DRO: availableFactionsDataNoInf %2: %1", _x, _forEachIndex];
} forEach availableFactionsDataNoInf;

missionNameSpace setVariable ["factionDataReady", 1, true];
diag_log "DRO: factionDataReady set";
