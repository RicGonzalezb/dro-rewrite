// Migrated from DRO_fnc_menuSlider — M3 CfgFunctions migration
disableSerialization;
	params ["_slide", "_display"];
		
	_currentMenu = menuSliderArray select menuSliderCurrent;	
	_selectedMenu = [];
	_menuSliderTarget = 0;
	switch (_slide) do {
		case "LEFT": {
			_menuSliderTarget = if (menuSliderCurrent == 0) then {((count menuSliderArray) - 1)} else {menuSliderCurrent - 1};
			_selectedMenu = menuSliderArray select _menuSliderTarget;
		};
		case "RIGHT": {
			_menuSliderTarget = if (menuSliderCurrent == ((count menuSliderArray) - 1)) then {0} else {menuSliderCurrent + 1};
			_selectedMenu = menuSliderArray select _menuSliderTarget;
		};
	};	
	// Slide current menu out to the left
	{
		if (_forEachIndex != 0) then {
			_thisCtrl = (_display displayCtrl _x);				
			_thisCtrl ctrlSetPosition [-0.4 * safezoneW + safezoneX, (ctrlPosition _thisCtrl) select 1, (ctrlPosition _thisCtrl) select 2, (ctrlPosition _thisCtrl) select 3];
			_thisCtrl ctrlCommit 0.1;
		};
	} forEach _currentMenu;
	sleep 0.1;
	// Slide next menu in from the left
	_leftPos = 0 * pixelGridNoUIScale * pixelW;
	{
		if (_forEachIndex == 0) then {
			_thisCtrl = (_display displayCtrl 1101);
			_thisCtrl ctrlSetText _x;
		} else {
			_thisCtrl = (_display displayCtrl _x);				
			//_thisCtrl ctrlSetPosition [0.01 * safezoneW + safezoneX, (ctrlPosition _thisCtrl) select 1, (ctrlPosition _thisCtrl) select 2, (ctrlPosition _thisCtrl) select 3];
			_thisCtrl ctrlSetPosition [safezoneX, (ctrlPosition _thisCtrl) select 1, (ctrlPosition _thisCtrl) select 2, (ctrlPosition _thisCtrl) select 3];
			_thisCtrl ctrlCommit 0.2;
		};
	} forEach _selectedMenu;			
	menuSliderCurrent = _menuSliderTarget;
