// Migrated from DRO_fnc_removeDragAction — M3 CfgFunctions migration
private _unit = _this select 0;
	private _DRO_oldDragId = _unit getVariable ["rev_dragActionID", -1];
	if (_DRO_oldDragId >= 0) then {
		_unit removeAction _DRO_oldDragId;
		_unit setVariable ["rev_dragActionID", -1, false]; // reset locally only
	};
