// Migrated from DRO_fnc_loopSounds — M3 CfgFunctions migration
params ["_pos", "_type", "_condition"];
	_sounds = switch (_type) do {
		case "BASE_RADIO": {
			[
				["A3\Sounds_F\sfx\UI\uav\UAV_01.wss", 4],
				["A3\Sounds_F\sfx\UI\uav\UAV_02.wss", 10],
				["A3\Sounds_F\sfx\UI\uav\UAV_03.wss", 5],
				["A3\Sounds_F\sfx\UI\uav\UAV_04.wss", 7],
				["A3\Sounds_F\sfx\UI\uav\UAV_05.wss", 7],
				["A3\Sounds_F\sfx\UI\uav\UAV_06.wss", 17],
				["A3\Sounds_F\sfx\UI\uav\UAV_07.wss", 10],
				["A3\Sounds_F\sfx\UI\uav\UAV_08.wss", 1],
				["A3\Sounds_F\sfx\UI\uav\UAV_09.wss", 1]
			]
		};
	};
	while {({(_x distance _pos) < 100} count units (grpNetId call BIS_fnc_groupFromNetId)) > 0} do {
		//sleep 3;
		_thisSound = (selectRandom _sounds);
		playSound3D [(_thisSound select 0), _pos, false, (getPosASL _pos), 2, (random [0.8, 1, 1]), 0];
		sleep (_thisSound select 1);
	};
