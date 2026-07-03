// Migrated from DRO_fnc_checkRouteWater — M3 CfgFunctions migration
params ["_startPos", "_endPos", ["_returnLastLand", false]];
	if (((count _startPos) < 3) || {(count _endPos) < 3}) exitWith { if (_returnLastLand) then {[]} else {false} };
	_dir = _startPos getDir _endPos;
	_checkPos = _startPos;
	_landPos = [];											
	_lastPos = [];
	_lastPosIsWater = false;
	_break = false;
	_return = false;
	while {(_startPos distance _checkPos) < (_startPos distance _endPos)} do {				
		_checkPos = _checkPos getPos [50, _dir];			
		if (surfaceIsWater _checkPos) then {
			if (_lastPosIsWater) then {
				_break = true;
				if (_returnLastLand) then {
					_return = _lastPos;
				} else {
					_return = true;
				};
			} else {
				_lastPosIsWater = true;
			};			
		} else {
			_lastPosIsWater = false;
		};
		if (_break) exitWith {};
		_lastPos = _checkPos;
	};
	_return
