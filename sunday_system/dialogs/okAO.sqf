// Guard: block Start until the faction lists are populated. Clicking Start before the
// async faction extraction filled the bars (empty dropdowns) reads "" -> playersFaction
// empty -> cascade of config errors in start.sqf (undefined side, genericNames array).
// Abort and keep the dialog open so the player can wait and retry. Only the normal UI
// flow reads the bars; the params flow sets factions directly and is exempt.
if (
	!(missionNamespace getVariable ["DRO_factionsFromParams", false]) &&
	{
		(lbSize 1301 <= 0) || {lbSize 1311 <= 0}
		|| {(lbData [1301, lbCurSel 1301]) isEqualTo ""}
		|| {(lbData [1311, lbCurSel 1311]) isEqualTo ""}
	}
) exitWith {
	systemChat "DRO: Factions are still loading - wait a moment and press Start again.";
	hint "Factions are still loading.\n\nWait a moment, then press Start again.";
	diag_log "DRO: okAO Start blocked - faction lists not populated yet.";
};

// Skip faction reading when factions come from params (loadParams already set them).
if (!(missionNamespace getVariable ["DRO_factionsFromParams", false])) then {
_playersIndex = lbCurSel 1301;
_enemyIndex = lbCurSel 1311;
_civIndex = lbCurSel 1321;
_playersFaction = lbData [1301, _playersIndex];
_enemyFaction = lbData [1311, _enemyIndex];

_playersSideNum = ((configFile >> "CfgFactionClasses" >> _playersFaction >> "side") call BIS_fnc_GetCfgData);
_enemySideNum = ((configFile >> "CfgFactionClasses" >> _enemyFaction >> "side") call BIS_fnc_GetCfgData);
			
playersFaction = "";
if ((lbData [1301, _playersIndex]) == "RANDOM") then {			
	playersFaction = lbData [1301, ([1, lbSize 1301] call BIS_fnc_randomInt)];
	profileNamespace setVariable ["DRO_playersFaction", "RANDOM"];
} else {
	playersFaction = lbData [1301, _playersIndex];
	profileNamespace setVariable ["DRO_playersFaction", playersFaction];
};		
publicVariable "playersFaction";		
playersFactionAdv = [lbData [3800,  lbCurSel 3800], lbData [3801,  lbCurSel 3801], lbData [3802,  lbCurSel 3802]];
publicVariable "playersFactionAdv";			

if ((lbData [1311, _enemyIndex]) == "RANDOM") then {			
	enemyFaction = lbData [1311, ([1, lbSize 1311] call BIS_fnc_randomInt)];
	profileNamespace setVariable ["DRO_enemyFaction", "RANDOM"];
} else {
	enemyFaction = lbData [1311, _enemyIndex];
	profileNamespace setVariable ["DRO_enemyFaction", enemyFaction];
};
publicVariable "enemyFaction";		
enemyFactionAdv = [lbData [3803,  lbCurSel 3803], lbData [3804,  lbCurSel 3804], lbData [3805,  lbCurSel 3805]];
publicVariable "enemyFactionAdv";

civFaction = lbData [1321, _civIndex];
publicVariable "civFaction";		

diag_log format ["DRO: okAO.sqf: player %2 playersFaction = %1", playersFaction, player];
diag_log format ["DRO: okAO.sqf: player %2 playersFactionAdv = %1", playersFactionAdv, player];
diag_log format ["DRO: okAO.sqf: player %2 enemyFaction = %1", enemyFaction, player];
diag_log format ["DRO: okAO.sqf: player %2 enemyFactionAdv = %1", enemyFactionAdv, player];
}; // end faction-reading (skipped when factions via params)

missionNameSpace setVariable ["factionsChosen", 1, true];

diag_log format ["DRO: okAO.sqf: player %2 factionsChosen set to %1 and broadcast", (missionNameSpace getVariable ['factionsChosen', -1]), player];

// Skip scenario-derived values (enemy size, neutral tasks) when scenario comes from params.
if (!(missionNamespace getVariable ["DRO_scenarioFromParams", false])) then {
	aiMultiplier = (round (((sliderPosition 2041)/10) * (10 ^ 1)) / (10 ^ 1));
	if (aiMultiplier < 1.25) then {
		if (count playableUnits > 8) then {
			aiMultiplier = (aiMultiplier * (1 + ((count playableUnits * 0.28) / 10)));
		};
	};
	publicVariable "aiMultiplier";

	if (('FORTIFY' in preferredObjectives) || ('DISARM' in preferredObjectives) || ('PROTECTCIV' in preferredObjectives)) then {
		neutralTasksChosen = true
	} else {
		if (count preferredObjectives > 0) then {
			noNeutralTasksChosen = true;
		};
	};
};

hintSilent  "";
closeDialog 1;				
[toUpper "Please wait while mission is generated", "objectivesSpawned", 1, ""] call DRO_fnc_callLoadScreen;					
	


