// Migrated from DRO_fnc_addReviveToUnit — M3 CfgFunctions migration
params ["_unit", "_unitOld"];
	_unit setVariable ["rev_beingAssisted", false, true];		
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_revivingUnit", false, true];
	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_dragged", false, true];	
	_unit setVariable ["rev_lastPatient", objNull, true];		
	_unit setVariable ["rev_timeoutCounter", 0, true];		
	
	if (isMultiplayer) then {
		if (!isPlayer _unit) then {
			_handlerLocal = [_unit, ["Local", DRO_fnc_changeLocal]] remoteExec ["addEventHandler", 0, true];
		};
		_handlerDamage = [_unit, ["HandleDamage", DRO_fnc_handleDamage]] remoteExec ["addEventHandler", _unit, true];	
		_handlerKilled = [_unit, ["Killed", DRO_fnc_handleKilled]] remoteExec ["addEventHandler", _unit, true];
		_handlerRespawn = [_unit, ["Respawn", {
			params ["_newUnit", "_oldUnit"];

			// --- Cleanup: Event Handlers ---
			// removeAllEventHandlers covers HandleDamage and Killed (the only EHs added per-respawn).
			// DRO_revHandlerIds tracks any future directly-added EHs for targeted removal.
			_newUnit removeAllEventHandlers "HandleDamage";
			_newUnit removeAllEventHandlers "Killed";
			{
				_newUnit removeEventHandler [_x select 0, _x select 1];
			} forEach (_newUnit getVariable ["DRO_revHandlerIds", []]);
			_newUnit setVariable ["DRO_revHandlerIds", [], true];

			// --- Cleanup: Actions ---
			// Compute player list early so it covers both cleanup and re-add targets.
			private _allPlayers = allPlayers - [_newUnit];
			// Remove old revive hold action globally before re-adding.
			private _DRO_oldHoldId = _newUnit getVariable ["rev_holdActionID", -1];
			if (_DRO_oldHoldId >= 0) then {
				[_newUnit, _DRO_oldHoldId] call BIS_fnc_holdActionRemove;
			};
			// Remove old drag addAction on every client before re-adding (no JIP — cleanup only).
			// remoteExec with an EMPTY target array logs
			// "Trying to call RemoteExec(Call) with 0 targets" and is discarded. allPlayers minus
			// the unit itself IS empty whenever that unit is the only player on the server.
			if (count _allPlayers > 0) then {
				[_newUnit] remoteExec ["DRO_fnc_removeDragAction", _allPlayers, false];
			};

			// --- Re-add Event Handlers ---
			_newUnit addEventHandler ["HandleDamage", DRO_fnc_handleDamage];
			_newUnit addEventHandler ["Killed", DRO_fnc_handleKilled];
			_newUnit removeAllEventHandlers "HandleRating"; // paridade com initRevive: clampa rating negativo, sem acumular
			_newUnit addEventHandler ["HandleRating", {if ((_this select 1) < 0) then {0}}];
			_newUnit setCaptive false;
			reviveUnits = reviveUnits - [_oldUnit];
			reviveUnits pushBack _newUnit;
			publicVariable 'reviveUnits';
			if (count _allPlayers > 0) then {
				[_newUnit] remoteExec ["DRO_fnc_reviveActionAdd", _allPlayers, true];
				[_newUnit] remoteExec ["DRO_fnc_dragActionAdd", _allPlayers, true];
			};
			[(format ["Revive actions added for unit %1 called for %2", _newUnit, _allPlayers])] remoteExec ["diag_log", 2];
		}]] remoteExec ["addEventHandler", _unit, true];			
	} else {
		_handlerDamage = _unit addEventHandler ["HandleDamage", DRO_fnc_handleDamage];
		_handlerKilled = _unit addEventHandler ["Killed", DRO_fnc_handleKilled];		
	};	
	if (!isNil "_unitOld") then {			
		reviveUnits = reviveUnits - [_unitOld];			
	};
	_unit setCaptive false;
	reviveUnits pushBack _unit;
	// HandleRating: clampa rating negativo p/ evitar loop de heal/kill da IA (paridade com initRevive)
	[_unit, ["HandleRating", {if ((_this select 1) < 0) then {0}}]] remoteExec ["addEventHandler", _unit, true];
	
	private _allPlayers = allPlayers;
	_allPlayers = _allPlayers - [_unit];	
	// remoteExec with an EMPTY target array logs
	// "Trying to call RemoteExec(Call) with 0 targets" and is discarded. allPlayers minus
	// the unit itself IS empty whenever that unit is the only player on the server.
	if (count _allPlayers > 0) then {
		[_unit] remoteExec ["DRO_fnc_reviveActionAdd", _allPlayers, true];
		[_unit] remoteExec ["DRO_fnc_dragActionAdd", _allPlayers, true];
	};	
	if (player == _unit) then {
		{
			if (_x != _unit) then {
				[_x] call DRO_fnc_reviveActionAdd;
				[_x] call DRO_fnc_dragActionAdd;				
			};
		} forEach reviveUnits;
	};
	diag_log format ["Revive actions add for unit %1 called for %2", _unit, _allPlayers];
	[(format ["Revive actions add for unit %1 called for %2", _unit, _allPlayers])] remoteExec ["diag_log", 2];	
	
	publicVariable 'reviveUnits';
	[(format ["Revive added to unit %1", _unit])] remoteExec ["diag_log", 2];
	//diag_log format ["Revive added to unit %1", _unit];
