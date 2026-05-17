// Migrated from DRO_fnc_switchButton — M3 CfgFunctions migration
params ["_table", "_idc", ["_change", true], ["_action", "NONE"]];	
	_optionData = [_table, _idc] call DRO_fnc_switchLookup;
	//diag_log "Called DRO_fnc_switchButton";
	
	_varStr = (_optionData select 0);
	_currentIndex = (_optionData select 1);	
	_allValues = (_optionData select 2);
	_newIndex = if (_change) then {
		if (_currentIndex == ((count _allValues) - 1)) then {0} else {_currentIndex + 1}
	} else {
		_currentIndex
	};
	if (_newIndex > ((count _allValues) - 1)) then {_newIndex = 0};
	missionNamespace setVariable [_varStr, _newIndex, true];
	profileNamespace setVariable [(format ["DRO_%1", _varStr]), _newIndex];
	ctrlSetText [(_idc + 3), (_allValues select _newIndex)];
	if (_change) then {
		if (_action == "NONE") exitWith {};
		if (_action == "PRESET") exitWith {[_newIndex] call DRO_fnc_missionPreset};
		if (_action == "TIME") exitWith {[_newIndex] remoteExec ['DRO_fnc_randomTime', 0, true]};
	};
	diag_log format ["Switched: %1 to %2", _optionData, _newIndex];
