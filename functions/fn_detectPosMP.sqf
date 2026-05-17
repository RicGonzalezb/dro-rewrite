// Migrated from DRO_fnc_detectPosMP — M3 CfgFunctions migration
private ["_taskName", "_taskPosFake"];
	_taskName = _this select 0;
	_taskPosFake = _this select 1;		
	if (alive player) then {
		if ((((vehicle player) distance _taskPosFake) < 1000) || (((getConnectedUAV player) distance _taskPosFake) < 1000)) then {			
			_aimedPos = screenToWorld [0.5, 0.5];
			if ((_aimedPos distance _taskPosFake) < 500) then {				
				_inspTime = (missionNamespace getVariable _taskName);
				_inspTime = _inspTime + 1;
				["DRO: Received an observe hit on %1(%3) by player %2, setting to %4", _taskName, player, (missionNamespace getVariable _taskName), _inspTime] call BIS_fnc_logFormatServer;
				missionNamespace setVariable [_taskName, _inspTime, true];
			};
		};
	};
