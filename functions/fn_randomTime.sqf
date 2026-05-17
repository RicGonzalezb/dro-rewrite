// Migrated from DRO_fnc_randomTime — M3 CfgFunctions migration
params ["_time"];
	if (_time == 0) then {_time = [1,4] call BIS_fnc_randomInt};
	//date params ["_year", "_month", "_day", "_hours", "_minutes"];
	_date = date;
	_dawnDusk = date call BIS_fnc_sunriseSunsetTime;
	_dawnNum = _dawnDusk select 0;
	_duskNum = _dawnDusk select 1;
	//_dawnNum = _dawnNum - 0.5;
	_dawnHour = floor _dawnNum;
	_duskHour = _duskNum;
	_dawnMinutes = ((_dawnNum - _dawnHour) * 60);
	_duskMinutes = ((_duskNum - _duskHour) * 60);
	diag_log format ["Raw dawnNum = %1", _dawnNum];
	//["RANDOM", "DAWN", "MORNING", "MIDDAY", "AFTERNOON", "DUSK", "EVENING", "MIDNIGHT"]
	switch (_time) do {
		case 1: {
			// DAWN		
			//skipTime _dawnNum;
			_date set [3, _dawnHour];
			_date set [4, _dawnMinutes];
			_number = dateToNumber _date;
			_number = _number - 0.00005;
			_date = numberToDate [(date select 0), _number];
			setDate _date;
		};
		case 2: {
			// MORNING
			_dayTime = [_dawnNum + 1, _dawnNum + 4] call BIS_fnc_randomNum;
			//skipTime _dayTime;
			_date set [3, _dayTime];
			setDate _date;	
		};
		/*
		case 3: {
			// DAY
			_dayTime = [_dawnNum + 3, _duskNum - 3] call BIS_fnc_randomNum;
			//skipTime _dayTime;
			_date set [3, _dayTime];
			setDate _date;	
		};
		case 2: {
			// DAY
			_dayTime = [_dawnNum + 1, _duskNum - 1] call BIS_fnc_randomNum;
			//skipTime _dayTime;
			_date set [3, _dayTime];
			setDate _date;	
		};
		*/
		case 3: {
			// MIDDAY
			_dayTime = [_dawnNum + 5, _duskNum - 5] call BIS_fnc_randomNum;
			//skipTime _dayTime;
			_date set [3, _dayTime];
			setDate _date;	
		};
		case 4: {
			// AFTERNOON
			_dayTime = [_duskNum - 5, _duskNum - 2] call BIS_fnc_randomNum;
			//skipTime _dayTime;
			_date set [3, _dayTime];
			setDate _date;	
		};
		case 5: {
			// DUSK			
			//skipTime _duskNum;
			//_date set [3, _duskNum];
			_date set [3, _duskHour];
			//_date set [4, 0];
			setDate _date;		
		};
		case 6: {
			// EVENING
			_dayTime = [_duskNum + 1, _duskNum + 4] call BIS_fnc_randomNum;
			//skipTime _dayTime;
			_date set [3, _dayTime];
			setDate _date;	
		};
		case 7: {
			// MIDNIGHT
			_nightTime1 = [(_duskNum + 5), 24] call BIS_fnc_randomNum;
			_nightTime2 = [0, (_dawnNum - 5)] call BIS_fnc_randomNum;
			_nightTime = selectRandom [_nightTime1, _nightTime2];
			_date set [3, _nightTime];
			setDate _date;
			//skipTime _nightTime;
		};
	};
	diag_log format ["DRO: Set new time as select %1: %2", _time, _date];
	//systemChat format ["DRO: Set new time as select %1: %2", _time, _date];
