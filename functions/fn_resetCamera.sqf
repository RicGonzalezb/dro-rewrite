// Migrated from DRO_fnc_resetCamera — M3 CfgFunctions migration
if (!isNil "VAR_CAMERA_VIEW") then {		
		[] spawn
		{
			titleCut ["","BLACK OUT",0.5];
			sleep 0.5;
			if (cameraView != VAR_CAMERA_VIEW) then {
				player switchCamera VAR_CAMERA_VIEW;
			};
			{_x ppEffectCommit 0; _x ppEffectEnable false; _x ppEffectForceInNVG false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
			titleCut ["","BLACK IN",0.5];
		};		
	} else {
		[] spawn
			{
				titleCut ["","BLACK OUT",0.5];
				sleep 0.5;
				player switchCamera "INTERNAL";
				{_x ppEffectCommit 0; _x ppEffectEnable false; _x ppEffectForceInNVG false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
				titleCut ["","BLACK IN",0.5];
			};
	};
