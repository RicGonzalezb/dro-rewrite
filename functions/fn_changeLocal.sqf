// Migrated from DRO_fnc_changeLocal — M3 CfgFunctions migration
params ["_unit", "_local"];
	(format ["Revive: Attempting locality change for unit %1", _unit]) remoteExec ["diag_log", 2];
	if (_local) then {
		_unit removeAllEventHandlers "HandleDamage";		
		_unit removeAllEventHandlers "Killed";		
		_handlerDamage = [_unit, ["HandleDamage", DRO_fnc_handleDamage]] remoteExec ["addEventHandler", _unit, true];	
		_handlerKilled = [_unit, ["Killed", DRO_fnc_handleKilled]] remoteExec ["addEventHandler", _unit, true];
		_handlerRespawn = [_unit, ["Respawn", {
			_handlerDamage = (_this select 0) addEventHandler ["HandleDamage", DRO_fnc_handleDamage];
			_handlerKilled = (_this select 0) addEventHandler ["Killed", DRO_fnc_handleKilled];
			(_this select 0) setCaptive false;
			reviveUnits = reviveUnits - [(_this select 1)];
			reviveUnits pushBack (_this select 0);
			publicVariable 'reviveUnits';
		}]] remoteExec ["addEventHandler", _unit, true];		
		
		private _reviveUnits = reviveUnits;
		_reviveUnits = _reviveUnits - [_unit];
		if !((_reviveUnits select 0) getVariable ["rev_downed", false]) then {
			if (group _unit != group (_reviveUnits select 0)) then {
				[_unit] joinSilent group (_reviveUnits select 0);
			};
		};
		
		(format ["Revive: Locality changed for unit %1", _unit]) remoteExec ["diag_log", 2];
		//diag_log (format ["Revive: Locality changed for unit %1", _unit]);		
		 
	};
