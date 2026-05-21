/*
 * DRO_fnc_setupReinforcementTrigger
 *
 * Creates the AO reinforcement trigger (EmptyDetector, 400m radius).
 * Fires reinforce.sqf when enemy count in area drops below 4.5× player
 * count AND enemy comms are active AND stealth is not active.
 * Only created if the primary AO location has a reinforcement flag (index 4 == 0).
 *
 * Globals set:   (none — trigger object is local)
 * Globals read:  AOLocations, centerPos, enemySide, enemyCommsActive,
 *                stealthActive, grpNetId
 */

// Reinforcement trigger
if (((AOLocations select 0) select 4) == 0) then {
	_trgReinf = createTrigger ["EmptyDetector", centerPos, true];
	_trgReinf setTriggerArea [400, 400, 0, false];
	_trgReinf setTriggerActivation ["ANY", "PRESENT", false];
	_trgReinf setTriggerStatements ["
		(({alive _x && side _x == enemySide} count thisList) < (({alive _x && group _x == (grpNetId call BIS_fnc_groupFromNetId)} count thisList)*4.5)) &&
		enemyCommsActive &&
		!stealthActive
		
	", "diag_log 'DRO: Reinforcing due to player incursion'; [getPos thisTrigger, [1,2]] execVM 'sunday_system\reinforce.sqf';", ""];	
};
