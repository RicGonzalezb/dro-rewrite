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

publicVariable "enemySide";
diag_log format ["DRO: Enemy side detected as %1", enemySide];
