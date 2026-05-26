// Migrated from DRO_fnc_sendProgressMessage — M3 CfgFunctions migration
params ["_message", ["_sender", "Command"], ["_data", []], ["_playAudio", true]];
// Guard: ensure dro_messageStack exists (may not be initialized yet on this client)
if (isNil "dro_messageStack") then { dro_messageStack = []; };
	//sleep (random [1, 2, 1.5]);
	/*
	if (!isNil "bis_fnc_showsubtitle_subtitle") then {
		waitUntil {sleep (random [2, 3, 2.5]); isNull bis_fnc_showsubtitle_subtitle};
	};
	*/
	if (typeName _sender == "OBJECT") then {
		_sender = name _sender;
	};
	switch (_message) do {
		case "HOSTILECIVS": {
			dro_messageStack pushBack [
				[
					[_sender, "This is a reminder to check your targets, we believe that some of the civilian population may react with hostility to your presence. Move carefully and assess any contact as a potential threat.", 0],
					[_sender, "Even though you're going into a situation with unknown combatants hold fire until you see clear signs of hostile intent. Civilian casualties are still considered unacceptable.", 10]
				],
				_playAudio
			];			
		};
		case "AMBUSH": {
			dro_messageStack pushBack [
				[
					[_sender, "Command here, looks like your activities have been noticed, we show enemies moving to investigate.", 0],
					[_sender, "Find cover, hold and defend your position.", 7]
				],
				_playAudio
			];				
		};
		case "AMBUSHOP": {
			dro_messageStack pushBack [
				[
					[_sender, "Heads up, we're showing incoming enemies headed to your position. Good thing you got that OP set up in time.", 0],
					[_sender, "Take cover and defend the OP.", 7]
				],
				_playAudio
			];			
		};
		case "AMBUSHCIV": {	
			dro_messageStack pushBack [
				[
					[_sender, (format ["Just as we expected, enemy forces are moving to your position now.", (_data select 0)]), 0],
					[_sender, (format ["Take cover and protect %1!", (_data select 0)]), 7]
				],
				_playAudio
			];			
		};
		case "PROTECT_CIV_MEET": {
			dro_messageStack pushBack [
				[
					[_sender, (format ["Are you %1? We know of a threat to your life and we're here to keep you safe.", (_data select 0)]), 0],
					[_sender, (format ["Keep your head down and we'll do the rest.", (_data select 0)]), 7],
					[(_data select 0), (format ["You got it, I'll try and stay out of your way.", (_data select 0)]), 12]
				],
				_playAudio
			];				
		};
		case "PROTECT_CIV_CLEAR": {	
			dro_messageStack pushBack [
				[
					[_sender, (format ["That should be the last of them, I suggest you leave the area as soon as possible.", (_data select 0)]), 0],
					[(_data select 0), (format ["Thank God you arrived when you did. Don't worry, I've got no intention of sticking around.", (_data select 0)]), 7]				
				],
				_playAudio
			];					
		};
		case "BRIEFING": {	
			_greeting = (format ["Good day %1, Command here.", playerCallsign]);
			_hour = (date select 3);
			if (_hour >= 0 && _hour < 8) then {
				_greeting = (format ["Good morning %1, Command here.", playerCallsign]);
			} else {
				if (_hour >= 8 && _hour < 18) then {
					_greeting = (format ["Good day %1, Command here.", playerCallsign]);
				} else {
					if (_hour >= 18) then {
						_greeting = (format ["Good evening %1, Command here.", playerCallsign]);
					};
				};
			};
			_sendOff = selectRandom [
				format ["Good luck out there, stay alert and let's ensure %1 is a success.", (missionNameSpace getVariable ["mName", "the operation"])],
				format ["%1 will be an important mission for us, we're looking to you for a clean execution. Good luck.", (missionNameSpace getVariable ["mName", "the operation"])],
				format ["Keep your head on a swivel and take your time. We don't want any mistakes today.", (missionNameSpace getVariable ["mName", "the operation"])]
			];
			dro_messageStack pushBack [
				[
					[_sender, _greeting, 0],
					[_sender, "We've prepared a full briefing which is available under your briefing notes.", 6],
					[_sender, _sendOff, 14]
				],
				_playAudio
			];
		};
		case "TASK_SUCCEED": {
			diag_log "DRO: TASK_SUCCEED called";
			if (({_x call BIS_fnc_taskCompleted} count taskIDs) < (count taskIDs)) then {				
				_phrases = if (isNil "oneTaskCompleted") then {
					oneTaskCompleted = true;
					[(format ["Good job %1, keep the momentum up.", playerCallsign]), "Good work. Let's keep it moving.", (format ["Good work %1, maintain your pace and let's finish the job.", playerCallsign])];				
				} else {
					if (oneTaskCompleted) then {
						[(format ["Another one down, %1. You're doing well.", playerCallsign]), (format ["Good job again %1. Keep it moving.", playerCallsign]), (format ["Alright %1, stay frosty.", playerCallsign]), (format ["Good work %1, maintain your pace and let's finish the job.", playerCallsign])];
					};
				};
				dro_messageStack pushBack [
					[
						[_sender, (selectRandom _phrases), 0]			
					],
					_playAudio
				];
			};		
		};
		case "REACTIVE_TASK": {	
			dro_messageStack pushBack [
				[
					[_sender, (_data select 0), 0]			
				],
				_playAudio
			];			
		};
		case "FRIENDLY_START": {
			_phrase = selectRandom [
				(format ["%1, this is %2. We're beginning our move now.", playerCallsign, _sender]),
				(format ["%1, %2 here. We're going to begin our assault.", playerCallsign, _sender]),
				(format ["%1, we're heading to our objective now. See you on the other side.", playerCallsign])
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0]			
				],
				_playAudio
			];
		};
		case "REVEAL_INTEL": {			
			if (count (_data select 1) > 0) then {
				dro_messageStack pushBack [
					[
						[_sender, (_data select 0), 0],
						[_sender, (_data select 1), 6]		
					],
					_playAudio
				];				
			} else {
				dro_messageStack pushBack [
					[
						[_sender, (_data select 0), 0]		
					],
					_playAudio
				];				
			};			
		};		
		case "END_LEAVE": {			
			_phrase = selectRandom [
				(format ["Alright %1, time to get yourselves out of there.", playerCallsign]),
				(format ["That's everything %1. Get clear of the AO.", playerCallsign])				
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0]		
				],
				_playAudio
			];				
		};
		case "END_RTB": {			
			_phrase = selectRandom [
				(format ["Alright %1, get yourselves back to %2.", playerCallsign, markerText "campMkr"]),
				(format ["That's everything %1, return to %2 ASAP.", playerCallsign, markerText "campMkr"])
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0]		
				],
				_playAudio
			];				
		};
		case "END_RENDEZVOUS": {
			if (isNil "friendlySquad") exitWith {};
			_phrase = selectRandom [
				(format ["Alright %1, rendezvous with %2 then make your way out of the AO.", playerCallsign, groupId friendlySquad]),
				(format ["That's everything %1, rendezvous with %2 before you leave the AO.", playerCallsign, groupId friendlySquad])
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0]		
				],
				_playAudio
			];				
		};
		case "END_RENDEZVOUS_FAIL": {
			if (isNil "friendlySquad") exitWith {};
			_phrase = selectRandom [
				(format ["We've lost contact with %1! Proceed to extraction and we'll send a recovery team to find them.", groupId friendlySquad])
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0]		
				],
				_playAudio
			];			
		};
		case "END_HOLD": {
			if (isNil "holdAO" || {count holdAO < 6}) exitWith {};
			_phrase = selectRandom [
				(format ["Alright %1, we need you to assist taking and holding %2. All units are go and the command has been given to secure the area.", playerCallsign, (text (holdAO select 5))]),
				(format ["Tasking complete %1. Your orders are now to assist the push to take and hold %2. All units are moving to secure the area.", playerCallsign, (text (holdAO select 5))])
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0],		
					[_sender, "However, if you're too damaged to assist in the assault then pull out and extract from the AO.", 8]		
				],
				_playAudio
			];			
		};
		case "OBSERVE_SUCCEED": {			
			_phrase = selectRandom [
				(format ["Alright %1, %2", playerCallsign, (_data select 0)]),
				(format ["Good spotting %1, %2", playerCallsign, (_data select 0)]),
				(format ["Nice work %1, %2", playerCallsign, (_data select 0)])
			];
			dro_messageStack pushBack [
				[
					[_sender, _phrase, 0]		
				],
				_playAudio
			];			
		};
	};
