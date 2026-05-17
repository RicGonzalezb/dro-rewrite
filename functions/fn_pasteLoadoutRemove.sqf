// Migrated from DRO_fnc_pasteLoadoutRemove — M3 CfgFunctions migration
_target = _this select 0;
	_actionIndex = _target getVariable "loadoutAction";		
	_target removeAction _actionIndex;
