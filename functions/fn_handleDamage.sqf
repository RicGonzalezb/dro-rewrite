// Migrated from DRO_fnc_handleDamage — M3 CfgFunctions migration
params ["_unit", "_selection", "_damage","_source","","_index"];
	/*
	if (_unit getVariable ["rev_downed", false]) then {
		_damage = 0;
	};
	*/
	if(alive _unit && _selection == "" && _damage >= 0.9 && !(_unit getVariable ["rev_downed", false])) then {
		_unit setVariable ["rev_downed", true, true];
		[(format ["Revive: Lethal damage handled for %1", _unit])] remoteExec ["diag_log", 2];
		//diag_log (format ["Revive: Lethal damage handled for %1", _unit]);		
		_unit setVariable ["rev_beingRevived", false, true];		
		_unit setDamage 0.95;
		_unit setCaptive true;		
		if(vehicle _unit != _unit) then {moveOut _unit};	
		_unit setUnconscious true;		
		
		// Player PP effects
		if (_unit == player) then {					
			VAR_CAMERA_VIEW = cameraView;
		
			bis_revive_ppColor = ppEffectCreate ["ColorCorrections", 1632];
			bis_revive_ppVig = ppEffectCreate ["ColorCorrections", 1633];
			bis_revive_ppBlur = ppEffectCreate ["DynamicBlur", 525];

			bis_revive_ppColor ppEffectAdjust [1,1,0.15,[0.3,0.3,0.3,0],[0.3,0.3,0.3,0.3],[1,1,1,1]];
			bis_revive_ppVig ppEffectAdjust [1,1,0,[0.15,0,0,1],[1.0,0.5,0.5,1],[0.587,0.199,0.114,0],[1,1,0,0,0,0.2,1]];
			bis_revive_ppBlur ppEffectAdjust [0];
			{_x ppEffectCommit 0; _x ppEffectEnable true; _x ppEffectForceInNVG true} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];			
		};
		
		_damage = 0;
		_string = selectRandom ["I'm hit!", "Need medical attention!", "I'm down!"];		
		[_unit, _string] remoteExec ["groupChat", 0];				
		
		[_unit] execVM "sunday_revive\bleedout.sqf";			
	};	
	
	if(_damage >= 1) then {_damage = 0.85};	
	//diag_log (format ["Revive: %1 _damage = %2", _unit, _damage]);
	//[(format ["Revive: %1 _damage = %2", _unit, _damage])] remoteExec ["diag_log", 2];
	_damage
