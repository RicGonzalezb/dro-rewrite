// Migrated from DRO_fnc_checkAllDeadFleeing — M3 CfgFunctions migration
params ["_checkGroups"];
	_return = false;
	_removeGroups = [];
	{
		_keepGroup = false;
		{
			if (!fleeing _x && alive _x) then {
				_keepGroup = true;
			};
		} forEach (units _x);
		if (!_keepGroup) then {
			_removeGroups pushBack _forEachIndex;
		};
	} forEach _checkGroups;
	{_checkGroups deleteAt _x} forEach _removeGroups;
	if (count _checkGroups == 0) then {_return = true};
	_return
