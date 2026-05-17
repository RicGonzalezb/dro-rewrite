// Migrated from DRO_fnc_menuMap — M3 CfgFunctions migration
disableSerialization;
	_map = ((findDisplay 52525) displayCtrl 1200);
	_button = ((findDisplay 52525) displayCtrl 2011);	
	/*
	_worldCenter = (configfile >> "CfgWorlds" >> worldName >> "centerPosition") call BIS_fnc_getCfgData;	
	if (!isNil "_worldCenter") then {
		_map ctrlMapAnimAdd [0, 0.1, _worldCenter];
		ctrlMapAnimCommit _map;
	};
	*/
	if (isNil "mapOpen") then {
		_map ctrlSetPosition [safezoneX + (27 * pixelGridNoUIScale * pixelW), safezoneY + (8 * pixelGridNoUIScale * pixelH), 0, safezoneH - (13 * pixelGridNoUIScale * pixelH)];		
		_map ctrlCommit 0;		
		//_map ctrlMapAnimAdd [0, 1, [worldSize/2, worldSize/2]];
		//ctrlMapAnimCommit _map;		
		_map ctrlSetPosition [safezoneX + (27 * pixelGridNoUIScale * pixelW), safezoneY + (8 * pixelGridNoUIScale * pixelH), safezoneW - (27 * pixelGridNoUIScale * pixelW), safezoneH - (13 * pixelGridNoUIScale * pixelH)];		
		_map ctrlCommit 0.2;
		mapOpen = true;
		_button ctrlSetText "CLOSE MAP";
		_text = composeText ["Select the Area of Operations:", lineBreak, lineBreak, "Click on the map to select the closest AO location.", lineBreak, "Alternatively ALT-click on the map to select an exact custom location."];
		((findDisplay 52525) displayCtrl 1053) ctrlSetStructuredText _text;
		[] spawn {
			disableSerialization;
			{
				_x ctrlSetFade 0;
			} forEach [((findDisplay 52525) displayCtrl 1052), ((findDisplay 52525) displayCtrl 1053)];
			{
				_x ctrlCommit 0.2;
			} forEach [((findDisplay 52525) displayCtrl 1052), ((findDisplay 52525) displayCtrl 1053)];
		};		
		[
			"mapStartSelect",
			"onMapSingleClick",
			{
				playSound "readoutClick";
				deleteMarker "aoSelectMkr";
				aoName = "";
				if (_alt) then {
					markerPlayerStart = createMarker ["aoSelectMkr", _pos];
					markerPlayerStart setMarkerShape "ICON";			
					markerPlayerStart setMarkerType "Select";		
					markerPlayerStart setMarkerAlpha 1;
					markerPlayerStart setMarkerColor "ColorGreen";					
					//_nearLoc = nearestLocation [_pos, ""];					
					_nearLoc = ((nearestLocations [_pos, ["NameLocal", "NameVillage", "NameCity", "NameCityCapital","Airport"], 1000, _pos]) select 0);
					if (isNil "_nearLoc") then {
						aoName = format ["Rural %1", ((configfile >> "CfgWorlds" >> worldName >> "description") call BIS_fnc_getCfgData)];
					} else {
						aoName = format ["Near %1", (text _nearLoc)];
					};	
					//aoName = format ["Near %1", text _nearLoc];
					selectedLocMarker setMarkerColor "ColorPink";
					selectedLocMarker = markerPlayerStart;
					selectedLocMarker setMarkerColor "ColorGreen";
				} else {
					_nearestMarker = [locMarkerArray, _pos] call BIS_fnc_nearestPosition;		
					markerPlayerStart = createMarker ["aoSelectMkr", getMarkerPos _nearestMarker];
					markerPlayerStart setMarkerShape "ICON";			
					markerPlayerStart setMarkerType "mil_dot";		
					markerPlayerStart setMarkerAlpha 0;		
					_loc = nearestLocation [getMarkerPos _nearestMarker, ""];
					aoName = text _loc;
					selectedLocMarker setMarkerColor "ColorPink";		
					selectedLocMarker = _nearestMarker;
					_nearestMarker setMarkerColor "ColorGreen";
				};				
				((findDisplay 52525) displayCtrl 2010) ctrlSetText format ["AO Location: %1", aoName];
				publicVariableServer "markerPlayerStart";
				publicVariable "aoName";
				publicVariableServer "selectedLocMarker";
			},
			[]
		] call BIS_fnc_addStackedEventHandler;
	} else {
		if (mapOpen) then {
			["mapStartSelect", "onMapSingleClick"] call BIS_fnc_removeStackedEventHandler;
			_map ctrlSetPosition [safezoneX + (27 * pixelGridNoUIScale * pixelW), safezoneY + (8 * pixelGridNoUIScale * pixelH), 0, safezoneH - (13 * pixelGridNoUIScale * pixelH)];
			_map ctrlCommit 0.1;
			sleep 0.1;
			_map ctrlSetPosition [safezoneX + (27 * pixelGridNoUIScale * pixelW), safezoneY + (8 * pixelGridNoUIScale * pixelH), 0, 0];		
			_map ctrlCommit 0;
			mapOpen = false;
			_button ctrlSetText "OPEN MAP";
			[] spawn {
				disableSerialization;
				{
					_x ctrlSetFade 1;
				} forEach [((findDisplay 52525) displayCtrl 1052), ((findDisplay 52525) displayCtrl 1053)];
				{
					_x ctrlCommit 0.2;
				} forEach [((findDisplay 52525) displayCtrl 1052), ((findDisplay 52525) displayCtrl 1053)];
			};	
		} else {
			_map ctrlSetPosition [safezoneX + (27 * pixelGridNoUIScale * pixelW), safezoneY + (8 * pixelGridNoUIScale * pixelH), 0, safezoneH - (13 * pixelGridNoUIScale * pixelH)];		
			_map ctrlCommit 0;
			_map ctrlSetPosition [safezoneX + (27 * pixelGridNoUIScale * pixelW), safezoneY + (8 * pixelGridNoUIScale * pixelH), safezoneW - (27 * pixelGridNoUIScale * pixelW), safezoneH - (13 * pixelGridNoUIScale * pixelH)];		
			_map ctrlCommit 0.2;
			mapOpen = true;
			_button ctrlSetText "CLOSE MAP";
			_text = composeText ["Select the Area of Operations:", lineBreak, lineBreak, "Click on the map to select the closest AO location.", lineBreak, "Alternatively ALT-click on the map to select an exact custom location."];
			((findDisplay 52525) displayCtrl 1053) ctrlSetStructuredText _text;
			[] spawn {
				disableSerialization;
				{
					_x ctrlSetFade 0;
				} forEach [((findDisplay 52525) displayCtrl 1052), ((findDisplay 52525) displayCtrl 1053)];
				{
					_x ctrlCommit 0.2;
				} forEach [((findDisplay 52525) displayCtrl 1052), ((findDisplay 52525) displayCtrl 1053)];
			};		
			[
				"mapStartSelect",
				"onMapSingleClick",
				{
					deleteMarker "aoSelectMkr";
					aoName = "";
					playSound "readoutClick";
					if (_alt) then {
						markerPlayerStart = createMarker ["aoSelectMkr", _pos];
						markerPlayerStart setMarkerShape "ICON";			
						markerPlayerStart setMarkerType "Select";		
						markerPlayerStart setMarkerAlpha 1;
						markerPlayerStart setMarkerColor "ColorGreen";
						//_nearLoc = nearestLocation [_pos, ""];					
						_nearLoc = ((nearestLocations [_pos, ["NameLocal", "NameVillage", "NameCity", "NameCityCapital","Airport"], 1000, _pos]) select 0);
						if (isNil "_nearLoc") then {
							aoName = format ["Rural %1", ((configfile >> "CfgWorlds" >> worldName >> "description") call BIS_fnc_getCfgData)];
						} else {
							aoName = format ["Near %1", (text _nearLoc)];
						};					
						selectedLocMarker setMarkerColor "ColorPink";
						selectedLocMarker = markerPlayerStart;
						selectedLocMarker setMarkerColor "ColorGreen";
					} else {
						_nearestMarker = [locMarkerArray, _pos] call BIS_fnc_nearestPosition;		
						markerPlayerStart = createMarker ["aoSelectMkr", getMarkerPos _nearestMarker];
						markerPlayerStart setMarkerShape "ICON";			
						markerPlayerStart setMarkerType "mil_dot";		
						markerPlayerStart setMarkerAlpha 0;		
						_loc = nearestLocation [getMarkerPos _nearestMarker, ""];
						aoName = text _loc;
						selectedLocMarker setMarkerColor "ColorPink";		
						selectedLocMarker = _nearestMarker;
						_nearestMarker setMarkerColor "ColorGreen";
					};				
					((findDisplay 52525) displayCtrl 2010) ctrlSetText format ["AO Location: %1", aoName];
					publicVariableServer "markerPlayerStart";
					publicVariable "aoName";
					publicVariableServer "selectedLocMarker";
				},
				[]
			] call BIS_fnc_addStackedEventHandler;			
		};
	};
