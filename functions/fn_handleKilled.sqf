// Migrated from DRO_fnc_handleKilled — M3 CfgFunctions migration
private ["_unit"];	
	_unit = (_this select 0);
	_unit setVariable ["rev_beingAssisted", false, true];		
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_revivingUnit", false, true];
	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_dragged", false, true];
	if (_unit == player) then {
		if (!isNil "bis_revive_ppColor") then {
			{_x ppEffectCommit 0; _x ppEffectEnable false; _x ppEffectForceInNVG false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
		};
	};
	[(format ["Revive: handleKilled fired for %1", _unit])] remoteExec ["diag_log", 2];
