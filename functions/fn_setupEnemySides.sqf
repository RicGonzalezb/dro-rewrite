/*
 * DRO_fnc_setupEnemySides
 *
 * Determines enemySide from enemyFaction, resolves conflict if
 * playersSide == enemySide, and configures sideFriendship between
 * all enemy sides (including enemyFactionAdv).
 *
 * Globals set:   enemySide (publicVariable)
 * Globals read:  enemyFaction, enemyFactionAdv, playersSide
 */

_enemySideNum = (configFile >> "CfgFactionClasses" >> enemyFaction >> "side") call BIS_fnc_GetCfgData;
sleep 0.01;
enemySide = [_enemySideNum] call DRO_fnc_getCfgSide;

if (playersSide == enemySide) then {
	enemySide = switch (enemySide) do {
		case east: {resistance};
		default {east};				
	};
	publicVariable "enemySide";	
};

_enemySides = [];
{
	if (count _x > 0) then {
		_thisSide = switch ((configFile >> "CfgFactionClasses" >> _x >> "side") call BIS_fnc_GetCfgData) do {
			case 0: {east};
			case 1: {west};
			case 2: {resistance};
			case 3: {civilian};
		};
		_enemySides pushBack _thisSide;
	};
} forEach [enemyFaction] + enemyFactionAdv;

{
	_thisSide = _x;
	if (_thisSide != playersSide) then {
		{
			if (_thisSide != _x) then {
				if (_x != playersSide) then {
					_thisSide setFriend [_x, 1];
				};
			};
		} forEach _enemySides;
	};
} forEach _enemySides;

// Force every enemy side HOSTILE to the player side. Arma's default side relations are NOT
// all mutually hostile — WEST and INDEPENDENT are FRIENDLY by default, so a BLUFOR player vs
// an INDEPENDENT enemy faction would never engage. Never trust the defaults: set the enemy
// relation explicitly (setFriend 0), both directions, for the resolved enemySide and every
// advanced enemy faction side. Includes the switched enemySide (playersSide==enemySide case)
// which is not in _enemySides.
//
// Two layers on purpose:
//  1. DIRECT on the server (this script is server-side). Not a remoteExec, so it is immune to
//     any CfgRemoteExec >> Commands lockdown — this guarantees the server-local enemy AI
//     always treats the player as hostile and engages, whatever a third-party mod does.
//  2. BROADCAST to clients only (-2, JIP true): each player's own client-local squad AI needs
//     the relation to return fire, and the map needs it to paint the enemy correctly. If a
//     strict Commands whitelist blocks this remoteExec, layer 1 still keeps enemies attacking.
{
	private _es = _x;
	if (_es != playersSide) then {
		_es setFriend [playersSide, 0];
		playersSide setFriend [_es, 0];
		[_es, [playersSide, 0]] remoteExec ["setFriend", -2, true];
		[playersSide, [_es, 0]] remoteExec ["setFriend", -2, true];
	};
} forEach (_enemySides + [enemySide]);

publicVariable "enemySide";
diag_log format ["DRO: Enemy side detected as %1", enemySide];
