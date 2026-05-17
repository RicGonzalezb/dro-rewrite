// teamRespawnPos.sqf
// Maintains the "respawn" marker at a safe position behind the player group's
// recent movement (~200m from current average position, away from enemies).
//
// Migrated from `while {true} do { sleep 10; ... }` to a CBA per-frame handler
// with 10s delta. The list of saved positions is passed as PFH args so it
// persists across ticks without keeping a scheduled thread alive.

markerRespawnTeam = createMarker ["respawn", (getPos (leader (grpNetId call BIS_fnc_groupFromNetId)))];
markerRespawnTeam setMarkerShape "ICON";
markerRespawnTeam setMarkerColor "ColorGreen";
markerRespawnTeam setMarkerType "mil_flag";
markerRespawnTeam setMarkerAlpha 0;
respawnTeam = [missionNamespace, "respawn", "Team"] call BIS_fnc_addRespawnPosition;

if (!isNil "DRO_teamRespawnPosPFH") exitWith {
	diag_log "DRO: teamRespawnPos PFH already running, skipping duplicate init";
};

DRO_teamRespawnPosPFH = [{
	params ["_args"];
	_args params ["_savedPositions"];

	private _unitPositions = [];
	private _group = grpNetId call BIS_fnc_groupFromNetId;
	private _playerGroupUnique = ((units _group + ([] call CBA_fnc_players)) arrayIntersect (units _group + ([] call CBA_fnc_players)));
	{
		private _leadPos = getPos (leader _group);
		if (alive _x && ((_x distance _leadPos) < 200)) then {
			_unitPositions pushBack (getPos _x);
		};
	} forEach _playerGroupUnique;

	if (count _unitPositions > 0) then {
		private _avgPos = [_unitPositions] call DRO_fnc_avgPos;

		// Save the current average position if a significant distance change has occurred
		if (count _savedPositions > 0) then {
			if ((_avgPos distance (_savedPositions select (count _savedPositions - 1))) > 50) then {
				_savedPositions pushBack _avgPos;
			};
		} else {
			_savedPositions pushBack _avgPos;
		};

		// Only keep the last 30 positions
		if (count _savedPositions > 30) then {
			_savedPositions deleteAt 0;
		};

		// Filter: at least 160m from team center AND 160m from nearest enemy
		private _usablePositions = [];
		{
			if (_x distance _avgPos > 160) then {
				private _enemy = (leader _group) findNearestEnemy _x;
				if ((_enemy distance _x) > 160) then {
					_usablePositions pushBack _x;
				};
			};
		} forEach _savedPositions;

		if (count _usablePositions > 0) then {
			// Pick the position closest to the ideal 200m distance from team avg
			private _current = _usablePositions select 0;
			private _desiredDist = 200;
			{
				private _thisDistance = _avgPos distance _x;
				private _selectedDistance = _current distance _avgPos;
				if (abs (_desiredDist - _thisDistance) < abs (_desiredDist - _selectedDistance)) then {
					_current = _x;
				};
			} forEach _usablePositions;
			markerRespawnTeam setMarkerPos _current;
		} else {
			// No safe saved position — fall back to a point 200m behind team avg, away from AO center
			private _dir = [trgAOC, _avgPos] call BIS_fnc_dirTo;
			private _spawnPos = [_avgPos, 200, _dir] call BIS_fnc_relPos;
			markerRespawnTeam setMarkerPos _spawnPos;
		};
	} else {
		// No live units near leader — fallback to a random player position
		private _dir = [trgAOC, (getPos (selectRandom _playerGroupUnique))] call BIS_fnc_dirTo;
		private _spawnPos = [(getPos (selectRandom _playerGroupUnique)), 200, _dir] call BIS_fnc_relPos;
		markerRespawnTeam setMarkerPos _spawnPos;
	};
	diag_log format ["DRO: Team Respawn position: %1", (getMarkerPos "respawn")];
}, 10, [[]]] call CBA_fnc_addPerFrameHandler;
