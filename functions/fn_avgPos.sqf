// Migrated from DRO_fnc_avgPos — M3 CfgFunctions migration
params ["_positions"];
	_xTotal = 0;
	_yTotal = 0;	
	{	
		_pos = switch (typeName _x) do {
			case "STRING": {getMarkerPos _x};
			case "OBJECT": {getPos _x};
			case "ARRAY": {_x};
			default {_x};
		};
		_xTotal = _xTotal + (_pos select 0);
		_yTotal = _yTotal + (_pos select 1);
	} forEach _positions;
	_numPositions = count _positions;	
	([(_xTotal / _numPositions), (_yTotal / _numPositions), 0]);
