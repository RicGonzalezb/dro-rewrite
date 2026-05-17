// Migrated from DRO_fnc_lobbyCamTarget — M3 CfgFunctions migration
params ["_target"];
	if (camLobbyTarget != _target) then {
		((findDisplay 626262) displayCtrl 1159) ctrlSetPosition [1 * safezoneW + safezoneX, (ctrlPosition ((findDisplay 626262) displayCtrl 1159)) select 1, (ctrlPosition ((findDisplay 626262) displayCtrl 1159)) select 2, (ctrlPosition ((findDisplay 626262) displayCtrl 1159)) select 3];
		((findDisplay 626262) displayCtrl 1159) ctrlCommit 0.1;
		((findDisplay 626262) displayCtrl 1160) ctrlSetText "";
		((findDisplay 626262) displayCtrl 1160) ctrlSetFade 1;
		((findDisplay 626262) displayCtrl 1160) ctrlCommit 0;
		camLobbyTarget = _target;		
		_camPos = [(getPos _target), 3.4, (getDir _target)] call BIS_fnc_relPos;
		_camPos set [2, 1.1];
		_camTarget = [(getPos _target), 0.4, (getDir _target)+90] call BIS_fnc_relPos;
		_camTarget set [2, 0.9];
		camLobby camSetPos _camPos;
		camLobby camSetTarget _camTarget;
		camLobby camSetFocus [3.4, 1];
		camLobby camCommit 1;
		//sleep 1;
		[_target] spawn {
			_target = _this select 0;			
			_class = (configfile >> "CfgVehicles" >> (_target getVariable "unitClass") >> "displayName") call BIS_fnc_getCfgData;		
			_weapon	= (configfile >> "CfgWeapons" >> primaryWeapon _target >> "displayName") call BIS_fnc_getCfgData;			
			_string = format ["%2%1%3%1%4%1%5", "\n", name _target, rank _target, _class, _weapon];
			sleep 0.8;
			((findDisplay 626262) displayCtrl 1159) ctrlSetPosition [0.73 * safezoneW + safezoneX, (ctrlPosition ((findDisplay 626262) displayCtrl 1159)) select 1, (ctrlPosition ((findDisplay 626262) displayCtrl 1159)) select 2, (ctrlPosition ((findDisplay 626262) displayCtrl 1159)) select 3];			
			((findDisplay 626262) displayCtrl 1159) ctrlCommit 0.1;
			sleep 0.1;
			((findDisplay 626262) displayCtrl 1160) ctrlSetText _string;
			((findDisplay 626262) displayCtrl 1160) ctrlSetFade 0;
			((findDisplay 626262) displayCtrl 1160) ctrlCommit 0.2;
		};		
	};
