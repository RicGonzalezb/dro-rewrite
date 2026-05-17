// Migrated from DRO_fnc_randomCam — M3 CfgFunctions migration
params ["_var"];	
	_worldCenterVal = (worldSize/2);
	_worldCenter = [_worldCenterVal, _worldCenterVal, 0];	
	_randomPos = [] call BIS_fnc_randomPos;	
	_randomPos set [2, (random [2, 5, 20])];
	_dir = [_randomPos, _worldCenter] call BIS_fnc_dirTo;
	_targetPos = [_randomPos, 600, _dir] call BIS_fnc_relPos;			
	_cam = "camera" camCreate _randomPos;
	randomCamActive = true;
	_cam cameraEffect ["internal", "BACK"];
	_cam camSetPos _randomPos;
	_cam camSetTarget _targetPos;	
	_cam camCommit 0;
	_preparePos = _randomPos getPos [15, 90];
	_preparePos set [2, (_randomPos select 2)];
	_cam camPreparePos _preparePos;	
	_cam camCommitPrepared 20;
	cameraEffectEnableHUD false;
	showCinemaBorder false;
	["Mediterranean"] call BIS_fnc_setPPeffectTemplate;	
	_end = false;
	_blackOut = false;
	sleep 5;
	while {(missionNameSpace getVariable [_var, 0]) == 0} do {
		_startTime = time;		
		while {time < (_startTime + 10)} do {
			if (sunOrMoon < 0.9) then {camUseNVG true} else {camUseNVG false};			
			if ((missionNameSpace getVariable [_var, 0]) == 1) exitWith {_end = true};
		};
		if (_end) exitWith {_blackOut = true};
		cutText ["", "BLACK OUT", 2];
		_startTime = time;
		while {time < (_startTime + 2.5)} do {
			if ((missionNameSpace getVariable [_var, 0]) == 1) exitWith {_end = true};
		};		
		if (_end) exitWith {};
		_randomPos = [] call BIS_fnc_randomPos;		
		_targetPos = [];
		if (random 1 > 0.6) then {
			_randomPos set [2, (random [220, 250, 300])];
			_dir = [_randomPos, _worldCenter] call BIS_fnc_dirTo;			
			_targetPos = [_randomPos, 1500, _dir] call BIS_fnc_relPos;
			_targetPos set [2, 0];
			_preparePos = _randomPos getPos [100, 90];
			_preparePos set [2, (_randomPos select 2)];
		} else {
			_randomPos set [2, (random [2, 5, 20])];
			_dir = [_randomPos, _worldCenter] call BIS_fnc_dirTo;
			_targetPos = [_randomPos, 600, _dir] call BIS_fnc_relPos;
			_preparePos = _randomPos getPos [15, 90];
			_preparePos set [2, (_randomPos select 2)];
		};		
		_cam camSetPos _randomPos;
		_cam camSetTarget _targetPos;	
		_cam camCommit 0;
		
		_cam camPreparePos _preparePos;
		_cam camCommitPrepared 20;
		_startTime = time;
		while {time < (_startTime + 2)} do {
			if ((missionNameSpace getVariable [_var, 0]) == 1) exitWith {_end = true};
		};
		if (_end) exitWith {};
		cutText ["", "BLACK IN", 2];
	};
	if (_blackOut) then {
		cutText ["", "BLACK OUT", 2];
		sleep 2;
	};
	_cam cameraEffect ["terminate","back"];
	camUseNVG false;
	camDestroy _cam;
	["Default"] call BIS_fnc_setPPeffectTemplate;
	randomCamActive = false;
	/*
	if (_blackOut) then {
		sleep 1;
		cutText ["", "BLACK IN", 2];		
	};
	*/
	diag_log "DRO: Closed random cam";
