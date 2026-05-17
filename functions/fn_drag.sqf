// Migrated from DRO_fnc_drag — M3 CfgFunctions migration
private ["_target"];
	_target = _this select 0;
	playerDragging = true;
	_target setVariable ["rev_dragged", true, true];
	sleep 0.5;
	player playMoveNow "AcinPknlMstpSrasWrflDnon";
	_target attachTo [player, [0, 1.18, 0.08]];
	[_target, 180] remoteExec ["setDir", 0];
	
	_target enableSimulationGlobal false;	
	_dropID = player addAction ["<img image='\A3\ui_f\data\map\markers\military\end_CA.paa'/>Release", {playerDragging = false; (_this select 0) removeAction (_this select 2);}, [], 10, true, true, "", ""];
		
	while {alive player && !(player getVariable ["rev_downed", false]) && (_target getVariable ["rev_downed", true]) && playerDragging} do {
		sleep 0.2;
	};
	
	_target enableSimulationGlobal true;
				
	if(alive player && !(player getVariable ["rev_downed", false])) then { 
		player playMove "amovpknlmstpsraswrfldnon";
	};
	
	playerDragging = false;	
	detach _target;
	sleep 2;
	_target setVariable ["rev_dragged", false, true];
