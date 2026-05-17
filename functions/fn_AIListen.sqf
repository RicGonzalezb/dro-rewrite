// Migrated from DRO_fnc_AIListen — M3 CfgFunctions migration
params ["_aiUnits"];
	{
		//diag_log reviveUnits;
		//diag_log format ["%5 - rev_downed: %1, rev_beingAssisted: %2, rev_dragged: %3, rev_beingRevived: %4", (_x getVariable ["rev_downed", false]), (_x getVariable ["rev_beingAssisted", false]), (_x getVariable ["rev_dragged", false]), (_x getVariable ["rev_beingRevived", false]), _x];
		if ((_x getVariable ["rev_downed", false]) && !(_x getVariable ["rev_beingAssisted", false]) && !(_x getVariable ["rev_dragged", false]) && !(_x getVariable ["rev_beingRevived", false]) && (side _x != sideEnemy)) then {			
			_downedUnit = _x;
			_availableMedics = [];
			_medicWeights = [];
			// Get medic weights
			{
				_medic = _x;				
				if (alive _medic && !(_medic getVariable ["rev_downed", false]) && !(_medic getVariable ["rev_revivingUnit", false])) then {
					_thisWeight = 0;
					// Check for medikits and FAKS
					if ("Medikit" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.7;
					};
					if ("FirstAidKit" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.1;
					};
					if ("gm_ge_army_burnBandage" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.1;
					};
					if ("gm_gc_army_gauzeBandage" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.1;
					};
					if ("gm_ge_army_gauzeBandage" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.1;
					};
					if ("gm_ge_army_gauzeCompress" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.1;
					};
					if ("gm_gc_army_medkit" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.7;
					};
					if ("gm_ge_army_medkit_80" in (items _medic)) then {
						_thisWeight = _thisWeight + 0.7;
					};
					// If no medikits or FAKS are present exit without giving a weight - this unit will not be used
					if (_thisWeight == 0) exitWith {
						if (isPlayer _downedUnit) then {							
							[_medic] remoteExec ["DRO_fnc_findFAK", _medic];
						};
					};
					// Apply distance weighting
					_dist = _medic distance _downedUnit;
					if (_dist <= 200) then {
						_thisWeight = (_thisWeight + ((1-(_dist/100))*0.5)) max 0;
					};										
					// Apply timeout weighting
					_thisWeight = _thisWeight - ((_medic getVariable ["rev_timeoutCounter", 0])*0.9);
					_thisWeight = _thisWeight max 1;
					_availableMedics pushBack _medic;
					_medicWeights pushBack _thisWeight;
				};				
			} forEach _aiUnits;	
			
			if (count _availableMedics > 0) then {
				diag_log _availableMedics;
				diag_log _medicWeights;
				_chosenMedic = _availableMedics selectRandomWeighted _medicWeights;
				[_chosenMedic, _downedUnit] remoteExec ["DRO_fnc_AIHeal", _chosenMedic];
				_chosenMedic setVariable ["rev_revivingUnit", true, true];	
			};			
		};
	} forEach reviveUnits;
