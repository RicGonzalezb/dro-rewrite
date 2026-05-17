// Migrated from DRO_fnc_checkIntersect — M3 CfgFunctions migration
params ["_subject", ["_blacklist", objNull]];
	private _object = objNull;
	lineIntersectsSurfaces [ 
		getPosWorld _subject,  
		getPosWorld _subject vectorAdd [0, 0, 20],  
		_subject, _blacklist, true, 1, 'GEOM', 'NONE' 
	] select 0 params ['','','','_object'];
	_return = false;
	if (!isNull _object) then {
		if (_object isKindOf 'House') then {		
			_return = true;
		};
	};
	_return
