// Migrated from DRO_fnc_setNameMP — M3 CfgFunctions migration
params ["_unit", "_firstName", "_lastName", "_speaker", "_face"];	
	_unit setName [format ["%1 %2", _firstName, _lastName], _firstName, _lastName];
	_unit setNameSound _lastName;
	//_unit setSpeaker _speaker;
	_playerList = [] call CBA_fnc_players;
	if (_unit in _playerList) then {
		_unit setName (profileName);
		_unit setSpeaker "ACE_NoVoice";
	} else {
		_unit setSpeaker _speaker;
	};
	_unit setFace _face;
