/*
 * DRO_fnc_defineMarkerColors
 *
 * Sets markerColorPlayers/markerColorEnemy (string marker color names)
 * and colorPlayers/colorEnemy (RGBA arrays from profileNamespace) based
 * on playersSide and enemySide.
 *
 * Globals set:   markerColorPlayers (publicVariable), markerColorEnemy (publicVariable),
 *                colorPlayers, colorEnemy
 * Globals read:  playersSide, enemySide
 */

markerColorPlayers = "colorBLUFOR";
colorPlayers = [(profilenamespace getvariable ['Map_BLUFOR_R',0]),(profilenamespace getvariable ['Map_BLUFOR_G',1]),(profilenamespace getvariable ['Map_BLUFOR_B',1]),(profilenamespace getvariable ['Map_BLUFOR_A',0.8])];
switch (playersSide) do {
	case west: {		
		markerColorPlayers = "colorBLUFOR";
		colorPlayers = [(profilenamespace getvariable ['Map_BLUFOR_R',0]),(profilenamespace getvariable ['Map_BLUFOR_G',1]),(profilenamespace getvariable ['Map_BLUFOR_B',1]),(profilenamespace getvariable ['Map_BLUFOR_A',0.8])];
	};
	case east: {		
		markerColorPlayers = "colorOPFOR";
		colorPlayers = [(profilenamespace getvariable ['Map_OPFOR_R',0]),(profilenamespace getvariable ['Map_OPFOR_G',1]),(profilenamespace getvariable ['Map_OPFOR_B',1]),(profilenamespace getvariable ['Map_OPFOR_A',0.8])];
	};
	case resistance: {		
		markerColorPlayers = "colorIndependent";
		colorPlayers = [(profilenamespace getvariable ['Map_Independent_R',0]),(profilenamespace getvariable ['Map_Independent_G',1]),(profilenamespace getvariable ['Map_Independent_B',1]),(profilenamespace getvariable ['Map_Independent_A',0.8])];
	};	
};
publicVariable "markerColorPlayers";

markerColorEnemy = "colorOPFOR";
colorEnemy = [(profilenamespace getvariable ['Map_OPFOR_R',0]),(profilenamespace getvariable ['Map_OPFOR_G',1]),(profilenamespace getvariable ['Map_OPFOR_B',1]),(profilenamespace getvariable ['Map_OPFOR_A',0.8])];
switch (enemySide) do {
	case west: {		
		markerColorEnemy = "colorBLUFOR";
		colorEnemy = [(profilenamespace getvariable ['Map_BLUFOR_R',0]),(profilenamespace getvariable ['Map_BLUFOR_G',1]),(profilenamespace getvariable ['Map_BLUFOR_B',1]),(profilenamespace getvariable ['Map_BLUFOR_A',0.8])];
	};
	case east: {		
		markerColorEnemy = "colorOPFOR";
		colorEnemy = [(profilenamespace getvariable ['Map_OPFOR_R',0]),(profilenamespace getvariable ['Map_OPFOR_G',1]),(profilenamespace getvariable ['Map_OPFOR_B',1]),(profilenamespace getvariable ['Map_OPFOR_A',0.8])];
	};
	case resistance: {		
		markerColorEnemy = "colorIndependent";
		colorEnemy = [(profilenamespace getvariable ['Map_Independent_R',0]),(profilenamespace getvariable ['Map_Independent_G',1]),(profilenamespace getvariable ['Map_Independent_B',1]),(profilenamespace getvariable ['Map_Independent_A',0.8])];
	};	
};
publicVariable "markerColorEnemy";
