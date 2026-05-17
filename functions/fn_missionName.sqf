// Migrated from DRO_fnc_missionName — M3 CfgFunctions migration
_missionNameType = selectRandom ["OneWord", "DoubleWord", "TwoWords"];
	_taskBasedList = [];
	{
		_title = (((_x call BIS_fnc_taskDescription) select 1) select 0);
		if ((["hvt", _title, false] call BIS_fnc_inString)) then {
			_taskBasedList = ["Priest", "Ghost", "King", "Duke", "Baron", "Viper", "Snake", "Lion", "Tiger", "Bishop", "Apollo", "Jupiter", "Poseidon", "Odin", "Valhalla", "Anubis", "Osiris", "Reaper", "Ahriman", "Malsumis"];
		} else {
			if ((["cache", _title, false] call BIS_fnc_inString)) then {
				_taskBasedList = ["Pillar", "Hoard", "Nest", "Trove", "Gold", "Fortune", "Emerald", "Opal", "Iron", "Steel", "Pearl", "Oyster", "Fountain", "Egg"];
			} else {
				if ((["intel", _title, false] call BIS_fnc_inString)) then {
					_taskBasedList = ["Scribe", "Papyrus", "Tome", "Mind", "Book", "Codex", "Atlas", "Scroll", "Source", "Abacus", "Mentor", "Oracle", "Sphinx"];
				} else {
					if ((["helicopter", _title, false] call BIS_fnc_inString)) then {
						_taskBasedList = ["Falcon", "Pheasant", "Goose", "Grouse", "Buzzard", "Albatross", "Condor", "Turkey", "Pelican", "Gnat", "Moth"];
					} else {
						if ((["artillery", _title, false] call BIS_fnc_inString) || (["destroy aa", _title, false] call BIS_fnc_inString)) then {
							_taskBasedList = ["Hammer", "Maul", "Lance", "Grip", "Drill"];
						} else {
							if ((["captive", _title, false] call BIS_fnc_inString)) then {
								_taskBasedList = ["Lamb", "Artemis", "Hermes", "Exodus", "Cage", "Bond", "Lock", "Leash", "Shackle", "Tether", "Snare", "Diplomat"];
							} else {
								if ((["observe", _title, false] call BIS_fnc_inString)) then {
									_taskBasedList = ["Vigil", "Lens", "Tower", "Hunter", "Night", "Archer", "Track", "Seer", "Eye", "Spy"];
								};
							};
						};
					};
				};
			};			
		};		
	} forEach taskIDs;
	
	_missionName = switch (_missionNameType) do {
		case "OneWord": {
			_nameArray = if (count _taskBasedList > 0) then {
				_taskBasedList				
			} else {
				["Garrotte", "Castle", "Tower", "Sword", "Moat", "Traveller", "Headwind", "Fountain", "Taskmaster", "Tulip", "Carnation", "Gaunt", "Goshawk", "Jasper", "Flashbulb", "Banker", "Piano", "Rook", "Knight", "Bishop", "Pyrite", "Granite", "Hearth", "Staircase"];
			};			
			format ["Operation %1", selectRandom _nameArray];
		};
		case "DoubleWord": {
			_name1Array = ["Dust", "Swamp", "Red", "Green", "Black", "Gold", "Silver", "Lion", "Bear", "Dog", "Tiger", "Eagle", "Fox", "North", "Moon", "Watch", "Under", "Key", "Court", "Palm", "Fire", "Fast", "Light", "Blind", "Spite", "Smoke", "Castle"];
			_name2Array = ["bowl", "catcher", "fisher", "claw", "house", "master", "man", "fly", "market", "cap", "wind", "break", "cut", "tree", "woods", "fall", "force", "storm", "blade", "knife", "cut", "cutter", "taker", "torch"];
			format ["Operation %1%2", selectRandom _name1Array, selectRandom _name2Array];
		};
		case "TwoWords": {		
			_name1Array = ["Awoken", "Warning", "Wakeful", "Bonded", "Sweeping", "Watching", "Bladed", "Crushing", "Arcane", "Midnight", "Fallen", "Turbulent", "Nesting", "Daunting", "Dogged", "Darkened", "Shallow", "Blank", "Absent", "Parallel", "Restless"];					
			_name2Array = if (count _taskBasedList > 0) then {
				_taskBasedList
			} else {
				["Sky", "Moon", "Sun", "Hand", "Monk", "Priest", "Viper", "Snake", "Boon", "Cannon", "Market", "Rook", "Knight", "Bishop", "Command", "Mirror", "Spider", "Charter", "Court", "Hearth"]
			};		
			format ["Operation %1 %2", selectRandom _name1Array, selectRandom _name2Array];
		};
	};
	_missionName
