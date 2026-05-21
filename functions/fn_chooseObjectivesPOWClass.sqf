/*
 * DRO_fnc_chooseObjectivesPOWClass
 *
 * Chooses the POW unit class and type for prisoner objectives.
 * 60% chance of a military type (helicrew or engineers, falling back
 * to infantry); 40% chance of a civilian type (journalist or scientist).
 * Also initialises UXOUsed flag.
 *
 * Globals set:   powClass, powType, UXOUsed
 * Globals read:  pInfClasses
 */

powClass = "";
powType = "";
UXOUsed = false;

if (random 1 > 0.4) then {
	_soldierType = [0,2] call BIS_fnc_randomInt;
	if (_soldierType < 2) then {
		switch (_soldierType) do {
			case 0: {
				// Helicopter crew
				_heliCrewClasses = [];
				{
					if (["heli", _x, false] call BIS_fnc_inString) then {
						_heliCrewClasses pushBack _x;
					};
				} forEach pInfClasses;
				if (count _heliCrewClasses > 0) then {
					powClass = selectRandom _heliCrewClasses;
					powType = "HELICREW";
				} else {
					powClass = selectRandom pInfClasses;
					powType = "INFANTRY";
				};				
			};
			case 1: {
				// Engineers
				_engineerClasses = [];
				{
					if (["engineer", _x, false] call BIS_fnc_inString OR ["repair", _x, false] call BIS_fnc_inString) then {
						_engineerClasses pushBack _x;
					};
				} forEach pInfClasses;
				if (count _engineerClasses > 0) then {
					powClass = selectRandom _engineerClasses;
					powType = "ENGINEERS";
				} else {
					powClass = selectRandom pInfClasses;
					powType = "INFANTRY";
				};		
			};				
		};
	} else {
		powClass = selectRandom pInfClasses;
		powType = "INFANTRY";
	};		
} else {
	powClass = selectRandom ["C_journalist_F", "C_scientist_F"];
	powType	= switch (powClass) do {
		case "C_journalist_F": {"JOURNALISTS"};
		case "C_scientist_F": {"SCIENTISTS"};
	};
};
