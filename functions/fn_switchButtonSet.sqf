// Migrated from DRO_fnc_switchButtonSet — M3 CfgFunctions migration
params ["_table", "_idc", "_index"];
	_optionData = [_table, _idc] call DRO_fnc_switchLookup;	
	diag_log _optionData;
	_varStr = (_optionData select 0);	
	_allValues = (_optionData select 2);
	//diag_log _index;
	missionNamespace setVariable [_varStr, _index, true];
	profileNamespace setVariable [(format ["DRO_%1", _varStr]), _index];
	ctrlSetText [(_idc + 3), (_allValues select _index)];
