// Migrated from DRO_fnc_AIHeal — M3 CfgFunctions migration
private ["_medic","_target","_moveTimeout","_cancelRevive","_previousMedicCommand","_previousBehaviour","_previousMedicPos"];

	_medic = (_this select 0);
	_target = (_this select 1);
	_targetPos = getPos _target;
	
	_medic enableAI "MOVE";
	
	endRevive = {	
		_medic enableAI "AUTOTARGET";
		_medic enableAI "TARGET";
		_medic enableAI "MOVE";		
		//_medic setCaptive false;
		_medic allowDamage true;	
		if (!isNil "_previousMedicCommand") then {
			if (count _previousMedicCommand == 0) then {
				_medic doFollow (leader group _medic);
			} else {
				_medic doMove _previousMedicPos;
				_medic moveTo _previousMedicPos;
			};
		} else {
			if (!isNil "_previousMedicPos") then {
				_medic doMove _previousMedicPos;
				_medic moveTo _previousMedicPos;
			};
		};
		/*
		if (count _previousBehaviour > 0) then {
			[_medic, _previousBehaviour] remoteExec ["switchBehaviour", 2];
		} else {
			[_medic, "AWARE"] remoteExec ["switchBehaviour", 2];
		};
		//["AWARE"] call switchBehaviour;
		*/
		_medic setVariable ["rev_revivingUnit", false, true];
		_target setVariable ["rev_beingAssisted", false, true];
	};

	switchBehaviour = {
		params ["_medic", "_behaviour", "_startGroup", "_tempGroup"];				
		_startGroup = (group _medic);
		_tempGroup = createGroup (side _medic);
		diag_log format ["Revive: medic switchBehaviour _startGroup: %1", _startGroup];
		diag_log format ["Revive: medic switchBehaviour _tempGroup: %1", _tempGroup];
		diag_log format ["Revive: medic switchBehaviour _behaviour: %1", _behaviour];
		[_medic] joinSilent _tempGroup;	
		_medic setBehaviour _behaviour;	
		diag_log format ["Revive: medic joinGroup: %1", _startGroup];		
		//[_medic] joinSilent _startGroup;					
		[_medic] joinSilent (reviveGroup call BIS_fnc_groupFromNetId);					
	};

	_medic setVariable ["rev_revivingUnit", true, true];
	_target setVariable ["rev_beingAssisted", true, true];
	
	[(format ["Revive: AI medic %1 activated for target %2", _medic, _target])] remoteExec ["diag_log", 2];
	//diag_log format ["Revive: AI medic %1 activated for target %2", _medic, _target];

	_previousMedicCommand = currentCommand _medic;
	_previousBehaviour = "";
	_previousBehaviour = behaviour (leader _medic);
	_previousMedicPos = getPosATL _medic;
	_cancelRevive = false;

	_medic allowDamage false;
	//_medic setCaptive true;
	_medic stop false;				
	_medic disableAI "AUTOTARGET";
	_medic disableAI "TARGET";
	//[_medic, "CARELESS"] remoteExec ["switchBehaviour", 2];
	//["CARELESS"] call switchBehaviour;
	//doStop _medic;
	_moveTimeout = time + 60;

	_lastName = "";
	if (!isPlayer _target) then {
		if (count (nameSound _target) > 0) then {
			_lastName = nameSound _target;
		} else {
			_name = name _target;
			_lastName = if (isPlayer _target) then {
				_name
			} else {
				_splitName = _name splitString " ";
				_splitName select (count _splitName - 1)
			};
		};
	} else {
		_name = name _target;
		_lastName = if (isMultiplayer) then {
			_name
		} else {
			_splitName = _name splitString " ";
			_splitName select (count _splitName - 1)
		};				
	};

	_string = selectRandom [format ["Assisting %1, sit tight!", _lastName], format ["I'm attending to %1!", _lastName], format ["Hold on %1, medic on the way!", _lastName]];
	[_medic, _string] remoteExec ["groupChat", 0];
	
	while {(_medic distance _target) >= 4} do {
		sleep 1;
		_medic doMove (getPos _target);
		_medic moveTo (getPosATL _target);
		sleep 2;
		if (!alive _target) exitWith {
			diag_log format ["Revive: AI %1 cancelling revive due to target death", _medic];
			_cancelRevive = true;	
		};
		if(!alive _medic) exitWith {
			diag_log format ["Revive: AI %1 cancelling revive due to medic death", _medic];
			_cancelRevive = true;	
		};
		if (_target getVariable ["rev_beingRevived", false]) exitWith {
			diag_log format ["Revive: AI %1 cancelling revive due to target already being revived", _medic];
			_cancelRevive = true;
		};
		if (_target getVariable ["rev_dragged", false]) exitWith {
			diag_log format ["Revive: AI %1 cancelling revive due to target being dragged", _medic];
			_cancelRevive = true;
		};
		if (time > _moveTimeout) exitWith {
			diag_log format ["Revive: AI %1 forced revive due to timeout", _medic];
			_medic setVariable ["rev_timeoutCounter", ((_medic getVariable ['rev_timeoutCounter', 0])+1), true];	
			//_cancelRevive = true;			
			_medic setPos (_target getPos [1, (random 360)]);
		};		
	};

	if (_cancelRevive) exitWith {
		[] call endRevive;
	};
	waitUntil {_medic distance _target <= 4};
	/*
	if(!alive _medic || (_target getVariable "rev_beingRevived") == 1 || (_target getVariable ["rev_dragged", false])) exitWith {		
		hint "cancel 2";
		[] call endRevive;
	};
	*/
	//_medic setCaptive true;
	//_medic allowDamage false;
	_medic disableAI "MOVE";
	_medic setDir ([_medic, _targetPos] call BIS_fnc_dirTo);

	_startTime = time;
	_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medic0S";
	//_target setVariable ["rev_beingRevived", true, true];
	while {time < _startTime + reviveTime} do {	
		_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medic0S";
		
		if (!alive _target) exitWith {
			_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medicEnd";
			sleep 3;
			_cancelRevive = true;	
		};
		if (_target getVariable ["rev_beingRevived", false])  exitWith {
			_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medicEnd";
			sleep 3;
			_cancelRevive = true;	
		};
		if (_target getVariable ["rev_dragged", false]) exitWith {
			_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medicEnd";
			sleep 3;
			_cancelRevive = true;
		};
		if !(_target getVariable ["rev_downed", false]) exitWith {
			_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medicEnd";
			sleep 3;
			_cancelRevive = true;
		};
	};
	_medic playMoveNow "AinvPknlMstpSnonWnonDnon_medicEnd";
	sleep 3;

	if (_cancelRevive) exitWith {	
		[] call endRevive;
	};

	[_target, _medic] call DRO_fnc_reviveUnit;
	_medic setVariable ["rev_timeoutCounter", 0, true];
	[] call endRevive;
