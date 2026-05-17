// Migrated from DRO_fnc_moveGroup — M3 CfgFunctions migration
params ["_group", "_pos", "_extendArray", "_posParams"];	
	_extendArray = [];
	{
		_distToLead = (leader _group) distance _x;
		_dirFromLead = [(leader _group), _x] call BIS_fnc_dirTo;
		_extendArray pushBack [_distToLead, _dirFromLead];
	} forEach units _group;	
	(leader _group) setPos _pos;
	{
		_posParams = _extendArray select _forEachIndex;
		_extendPos = _pos getPos [(_posParams select 0), (_posParams select 1)];		
		_x setPos _extendPos;
	} forEach units _group;
