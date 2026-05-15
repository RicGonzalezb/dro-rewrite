// bleedout.sqf
// Per-downed-unit bleedout countdown. Invoked via execVM from the revive
// handler; the caller does not wait on completion.
//
// Migrated from two scheduled loops (`[] spawn { while {rev_downed} do { sleep 1; ppAdjust } }`
// and `waitUntil { sleep 0.1; tick; exitCondition }`) to two non-scheduled
// CBA per-frame handlers. The script returns immediately after wiring up the
// handlers; cleanup runs inside the handlers when their exit conditions fire.

sleep 0.05;

_unit = _this select 0;

[(format ["Revive: Bleedout started for %1", _unit])] remoteExec ["diag_log", 2];

private _time = bleedTime;
private _timeBefore = time;
private _total = _time;

// Use -1 as the "no suicide action" sentinel so the value can be carried
// through PFH args (nil values would truncate the args array).
private _suicideActionId = -1;

BIS_BleedCC = ppEffectCreate ["ColorCorrections", 1634];

// Post-process effects (player only, non-dedicated). PFH delta=1; self-removes
// the instant rev_downed becomes false, then resets PP and schedules the
// ppEffectEnable false 1s later (mirrors original `sleep 1` after cleanup).
if (!isDedicated && _unit == player) then {
	[{
		params ["_args", "_pfhId"];
		if (player getVariable "rev_downed") then {
			private _blood = player getVariable ["rev_blood", 1];

			// Desaturation
			private _bright = 0.2 + (0.1 * _blood);
			bis_revive_ppColor ppEffectAdjust [1,1, 0.15 * _blood,[0.3,0.3,0.3,0],[_bright,_bright,_bright,_bright],[1,1,1,1]];

			// Vignette intensity
			private _intense = 0.6 + (0.4 * _blood);
			bis_revive_ppVig ppEffectAdjust [1,1,0,[0.15,0,0,1],[1.0,0.5,0.5,1],[0.587,0.199,0.114,0],[_intense,_intense,0,0,0,0.2,1]];

			// Blur intensity
			private _blur = 0.7 * (1 - _blood);
			bis_revive_ppBlur ppEffectAdjust [_blur];

			// Smooth transition
			{_x ppEffectCommit 1} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
		} else {
			[_pfhId] call CBA_fnc_removePerFrameHandler;

			bis_revive_ppColor ppEffectAdjust [1, 1, 0, [1, 1, 1, 0], [0, 0, 0, 1],[0,0,0,0]];
			bis_revive_ppVig ppEffectAdjust [1, 1, 0, [1, 1, 1, 0], [0, 0, 0, 1],[0,0,0,0]];
			bis_revive_ppBlur ppEffectAdjust [0];

			{_x ppEffectCommit 1} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
			[{
				{_x ppEffectEnable false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
			}, [], 1] call CBA_fnc_waitAndExecute;
		};
	}, 1, []] call CBA_fnc_addPerFrameHandler;
	/*
	[] spawn {
		sleep 5;
		_suicide = 0;
		_suicideKey = actionKeysNames ["action", 1, "Keyboard"];
		_suicideText = format ["<t color='#ffffff' size = '.6'>Hold %1 to commit suicide<br />or await revive</t>", _suicideKey];
		[_suicideText,-1,1,10,2,0,789] spawn BIS_fnc_dynamicText;
		//titleText ["Hold space to commit suicide", "PLAIN"];
		while {(player getVariable "rev_downed")} do {
			if (inputAction "action" > 0) then {
				while {(inputAction "action" > 0)} do {
					_suicide = _suicide + 1;
					if (_suicide >= 5) then {
						player setDamage 1;
					};
					sleep 1;
				};
				_suicide = 0;
			};
		};
	};
	*/

	//_suicideAction = player addAction ["Suicide", {(_this select 0) setDamage 1; (_this select 0) removeAction (_this select 2)}, nil, 1000, true, true, "", "alive _target", -1, true];
	_suicideActionId = [player] call rev_suicideActionAdd;

};


// Main bleedout loop. PFH delta=0.1; state mutated in place across ticks via
// the shared `_state` array (passed by reference into PFH args).
// State layout: [_time, _timeBefore, _total, _suicideActionId, _unit]
private _state = [_time, _timeBefore, _total, _suicideActionId, _unit];
[{
	params ["_args", "_pfhId"];
	_args params ["_state"];
	_state params ["_time", "_timeBefore", "_total", "_suicideActionId", "_unit"];

	if !(_unit getVariable "rev_beingRevived") then {
		_time = _time - (time - _timeBefore);
	};
	_timeBefore = time;
	_state set [0, _time];
	_state set [1, _timeBefore];

	private _blood = (_time / _total);

	if (_unit getVariable "rev_downed") then {
		_unit setVariable ["rev_blood", _blood];
	};

	// Continue ticking until blood is depleted, unit dies, or unit is no longer downed
	if (!(_blood <= 0 || {!alive _unit} || {!(_unit getVariable "rev_downed")})) exitWith {};

	[_pfhId] call CBA_fnc_removePerFrameHandler;

	[(format ["Revive: %1 blood = %2", _unit, _blood])] remoteExec ["diag_log", 2];

	if (_suicideActionId >= 0) then {
		_unit removeAction _suicideActionId;
	};

	// Kill unit if it bled out
	if (alive _unit && {_blood <= 0}) then {
		_unit setDamage 1;
	};
}, 0.1, [_state]] call CBA_fnc_addPerFrameHandler;
