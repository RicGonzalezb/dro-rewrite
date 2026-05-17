// Migrated from DRO_fnc_playSubtitleRadio — M3 CfgFunctions migration
_radioArray = [		
		["RadioAmbient2", 9],
		["RadioAmbient6", 6],
		["RadioAmbient8", 11]
	];
	0 fadeSpeech 1;
	_thisSound = (selectRandom _radioArray);
	_endRadio = false;
	_currentSoundTime = 0;
	_soundStartTime = time;
	if (getSubtitleOptions select 0) then {
		0 fadeSpeech 0.15;
		playSound ["TacticalPing4", false];
		while {!_endRadio} do {
			//diag_log format ["currentSoundTime = %1", _currentSoundTime];
			sleep 0.7;
			if (isNil "bis_fnc_showsubtitle_subtitle") then {
				_thisSound = (selectRandom _radioArray);
				_currentSoundTime = (_thisSound select 1);
				_soundStartTime = time;
				//playSound [(_thisSound select 0), true];
			} else {
				if (_currentSoundTime <= 0 && !isNull bis_fnc_showsubtitle_subtitle) then {
					_thisSound = (selectRandom _radioArray);
					_currentSoundTime = (_thisSound select 1);
					_soundStartTime = time;
					//playSound [(_thisSound select 0), true];		
				};		
				_currentSoundTime = (_thisSound select 1) - (time - _soundStartTime);
				//hint str _currentSoundTime;
				if (isNull bis_fnc_showsubtitle_subtitle) then {
					_endRadio = true;
					1 fadeSpeech 0;
					sleep _currentSoundTime + 1;//((_thisSound select 1) - _currentSoundTime);			
					0 fadeSpeech 1;
				};
			};
			sleep 0.3;
		};
		playSound ["TacticalPing4", false];
	};
	/*
	while {!isNull bis_fnc_showsubtitle_subtitle} do {
		
		_radioArray = [		
			"RadioAmbient2",
			"RadioAmbient6",
			"RadioAmbient8"
		];
		playSound [(selectRandom _radioArray), true];
		//sleep 0.5;
		_sound = ASLToAGL [0,0,0] nearestObject "#soundonvehicle";
		diag_log _sound;
		diag_log isNull bis_fnc_showsubtitle_subtitle;
		waitUntil {isNull _sound || isNull bis_fnc_showsubtitle_subtitle};
		format ["DRO: Passed waitUntil with _sound %1 and subtitle %2", isNull _sound, isNull bis_fnc_showsubtitle_subtitle];
		sleep 0.5;
		if (!isNull _sound) then {1 fadeSpeech 0; sleep 1; deleteVehicle _sound; 0 fadeSpeech 1;};		
	};	
	*/
