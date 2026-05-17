// Migrated from DRO_fnc_defineGrid — M3 CfgFunctions migration
params ["_center", "_numPosX", "_numPosY", "_spacing"];	
	_positions = [];
	_totalXSpacing = _spacing * _numPosX;
	_totalYSpacing = _spacing * _numPosY;
	
	_xOrigin = (_center select 0) - (_totalXSpacing/2);
	_yOrigin = (_center select 1) - (_totalYSpacing/2);
	
	_thisX = 0;
	_thisY = 0;
	for "_i" from 0 to (_numPosY - 1) step 1 do {
		for "_j" from 0 to (_numPosX - 1) step 1 do {
			_thisX = _xOrigin + (_spacing * _i) + (_spacing/2);
			_thisY = _yOrigin + (_spacing * _j) + (_spacing/2);			
			_positions pushBack [_thisX, _thisY, 0];
		};
	};
	_positions
