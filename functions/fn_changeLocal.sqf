// Migrated from DRO_fnc_changeLocal — M3 CfgFunctions migration
params ["_unit", "_local"];
	(format ["Revive: Attempting locality change for unit %1", _unit]) remoteExec ["diag_log", 2];
	if (_local) then {
		_unit removeAllEventHandlers "HandleDamage";		
		_unit removeAllEventHandlers "Killed";		
		_handlerDamage = [_unit, ["HandleDamage", DRO_fnc_handleDamage]] remoteExec ["addEventHandler", _unit, true];	
		_handlerKilled = [_unit, ["Killed", DRO_fnc_handleKilled]] remoteExec ["addEventHandler", _unit, true];
		// "Respawn" EH removido (NOTED-1 fix, 2026-06-27):
		// fn_addReviveToUnit já registra um "Respawn" EH completo (com cleanup de HD/Killed,
		// DRO_revHandlerIds, actions e re-add) no servidor — cobre tudo que este bloco fazia.
		// Ambos rodam no servidor (fn_changeLocal é disparado pelo "Local" EH de máquina 0).
		// Manter os dois causava acumulação após cada troca de localidade → HD/Killed duplicados no respawn.

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
