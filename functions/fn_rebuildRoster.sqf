// functions/fn_rebuildRoster.sqf
// DRO_fnc_rebuildRoster — M12 "AI squad rework" (Team Planning "+1 AI").
//
// Rebuilds the per-unit rows of the Team Planning "SQUAD LOADOUT" tab
// (nametag / loadout switcher / arsenal button / remove-AI checkbox) from the
// CURRENT synced group (grpNetId). Called once when the lobby dialog first
// opens (from populateLobby.sqf) and again every time the roster changes
// (Add AI / Remove AI / JIP backfill bump), so it must be idempotent: it
// destroys any previously-created row controls before recreating them,
// using the same deterministic per-index IDC scheme start.sqf originally
// used (1200/1300/1500/1700 + index), so nothing leaks and nothing collides.
//
// Client-side only; each client that has the dialog (idd 626262) open runs
// this locally. Callers broadcast via remoteExec (targeting 0, JIP true) so
// every connected client's view stays in sync; clients without the dialog
// open simply exit immediately below.
//
// NOTE: this function does not touch menuSliderArray, the insertion/support
// combo boxes, or the START MISSION button — those are one-time, per-dialog-
// open setup left in populateLobby.sqf. Re-running lbAdd on every rebuild
// would duplicate listbox entries.

disableSerialization;

if (isNull (findDisplay 626262)) exitWith {};

private _display = findDisplay 626262;
private _group = grpNetId call BIS_fnc_groupFromNetId;
if (isNull _group) exitWith {};

private _units = units _group;
private _maxSquad = missionNamespace getVariable ["DRO_maxSquad", 16];
diag_log format ["DRO: rebuildRoster run - units=%1 dialogOpen=%2 maxSquad=%3", count _units, !isNull (findDisplay 626262), _maxSquad];

// --- Destroy previously-created row controls: delete every control that is a child of
// the loadoutGroup (6060), found via allControls + ctrlParentControlsGroup (reliable for
// nested controls, unlike displayCtrl-by-IDC). ---
private _lgGroup = _display displayCtrl 6060;
{
	if (!(isNull (ctrlParentControlsGroup _x)) && {(ctrlParentControlsGroup _x) isEqualTo _lgGroup}) then {
		ctrlDelete _x;
	};
} forEach (allControls _display);

// Flip the per-row IDC base each rebuild so freshly-created controls never reuse an IDC
// still held by an old (end-of-frame-deferred) ctrlDelete — the actual cause of the live
// roster not refreshing (rebuild ran and saw the new unit, but recreate collided).
private _base = if ((uiNamespace getVariable ["DRO_rosterIdcFlip", 0]) == 0) then {
	uiNamespace setVariable ["DRO_rosterIdcFlip", 1]; 0
} else {
	uiNamespace setVariable ["DRO_rosterIdcFlip", 0]; 4000
};

// --- Identify which local player "owns" this dialog instance (same logic
// populateLobby.sqf used, just sourced from the live synced group instead of
// group player, which is equivalent pre-mission-start but more robust) ---
private _dialogPlayer = objNull;
{
	if (isPlayer _x) exitWith { _dialogPlayer = _x; };
} forEach _units;

private _lineSpacing = 2.5 * pixelGridNoUIScale * pixelH;
private _lineHeight = 2.25 * pixelGridNoUIScale * pixelH;

{
	private _x2 = _x;
	_x2 setVariable ["unitLoadoutIDC", (1200 + _base + _forEachIndex)];
	_x2 setVariable ["unitArsenalIDC", (1300 + _base + _forEachIndex)];
	_x2 setVariable ["unitDeleteIDC", (1500 + _base + _forEachIndex)];
	_x2 setVariable ["unitNameTagIDC", (1700 + _base + _forEachIndex)];

	// Create nametag
	private _nameControl = _display ctrlCreate ["DRONameButton", (_x2 getVariable "unitNameTagIDC"), (_display displayCtrl 6060)];
	_nameControl ctrlSetPosition [4.75 * pixelGridNoUIScale * pixelW, ((_forEachIndex) * _lineSpacing), 15.25 * pixelGridNoUIScale * pixelW, _lineHeight];
	if (isPlayer _x2) then {
		_nameControl ctrlSetText (format ["%1:", (name _x2)]);
	} else {
		_nameControl ctrlSetText (format ["%1 (AI):", (name _x2)]);
	};
	_nameControl ctrlSetEventHandler ["ButtonClick", (format ["[objectFromNetId '%1'] call DRO_fnc_lobbyCamTarget", netId _x2])];
	_nameControl ctrlCommit 0;

	// Create loadout switcher
	if ((player == _x2) OR ((player == _dialogPlayer) && (!isPlayer _x2))) then {
		private _loadoutControl = _display ctrlCreate ["DROLoadoutSwitch", (_x2 getVariable "unitLoadoutIDC"), (_display displayCtrl 6060)];
		_loadoutControl ctrlSetPosition [20 * pixelGridNoUIScale * pixelW, ((_forEachIndex) * _lineSpacing), 15.25 * pixelGridNoUIScale * pixelW, _lineHeight];
		_loadoutControl ctrlSetEventHandler ["LBSelChanged", (format ["_nil=[objectFromNetId '%1', _this]ExecVM 'sunday_system\player_setup\switchUnitLoadout.sqf'", netId _x2])];
		_loadoutControl ctrlCommit 0;
	} else {
		private _loadoutControl = _display ctrlCreate ["sundayText", (_x2 getVariable "unitLoadoutIDC"), (_display displayCtrl 6060)];
		_loadoutControl ctrlSetPosition [20 * pixelGridNoUIScale * pixelW, ((_forEachIndex) * _lineSpacing), 15.25 * pixelGridNoUIScale * pixelW, _lineHeight];
		_loadoutControl ctrlSetBackgroundColor [0.1,0.1,0.1,1];
		_loadoutControl ctrlSetTextColor [1,1,1,0.5];
		private _factionClass = ((configfile >> "CfgVehicles" >> (_x2 getVariable "unitClass") >> "faction") call BIS_fnc_getCfgData);
		private _class = format ["%1 - %2", ((configfile >> "CfgVehicles" >> (_x2 getVariable "unitClass") >> "displayName") call BIS_fnc_getCfgData), ((configfile >> "CfgFactionClasses" >> _factionClass >> "displayName") call BIS_fnc_getCfgData)];
		_loadoutControl ctrlSetText _class;
		_loadoutControl ctrlCommit 0;
	};

	// Create VA button (skip entirely when the Arsenal toggle is disabled)
	if ((missionNamespace getVariable ["arsenalEnabled", 0]) != 1) then {
		private _VAControl = _display ctrlCreate ["DROVAButton", (_x2 getVariable "unitArsenalIDC"), (_display displayCtrl 6060)];
		_VAControl ctrlSetPosition [35.25 * pixelGridNoUIScale * pixelW, ((_forEachIndex) * _lineSpacing), 2.25 * pixelGridNoUIScale * pixelW, _lineHeight];
		_VAControl ctrlSetEventHandler ["ButtonClick", (format ["private _u=objectFromNetId '%1'; if (!isNull _u) then {_nil=[_u]ExecVM 'sunday_system\dialogs\openArsenal.sqf'}", netId _x2])];
		_VAControl ctrlCommit 0;
	};

	// Create remove-AI checkbox — AI rows only; humans NEVER get this control.
	if (!isPlayer _x2) then {
		private _deleteControl = _display ctrlCreate ["DROCheckBoxRemove", (_x2 getVariable "unitDeleteIDC"), (_display displayCtrl 6060)];
		_deleteControl ctrlSetPosition [2.5 * pixelGridNoUIScale * pixelW, ((_forEachIndex) * _lineSpacing), 2.25 * pixelGridNoUIScale * pixelW, _lineHeight];
		_deleteControl ctrlSetEventHandler ["CheckBoxesSelChanged", (format ["_nil=[objectFromNetId '%1', _this]ExecVM 'sunday_system\dialogs\removeAI.sqf'", netId _x2])];
		_deleteControl ctrlCommit 0;
		if (player != topUnit) then { ctrlEnable [(_x2 getVariable "unitDeleteIDC"), false]; };
	};
} forEach _units;

// --- Populate loadout listbox contents + restore current selection (only
// for units this client is authoritative over: self, or any AI when this
// client is the dialog-owning player) ---
{
	private _thisUnit = _x;
	if ((player == _thisUnit) OR ((player == _dialogPlayer) && (!isPlayer _thisUnit))) then {
		private _thisLB = (_thisUnit getVariable "unitLoadoutIDC");
		lbClear _thisLB;
		{
			private _index = lbAdd [_thisLB, format ["%1 - %2", (_x select 1), (_x select 2)]];
			lbSetData [_thisLB, _index, (_x select 0)];
		} forEach unitList;

		if ((_thisUnit getVariable "unitChoice") isEqualType "") then {
			if ((_thisUnit getVariable "unitChoice") == "CUSTOM") then {
				private _index = lbAdd [_thisLB, "Custom Loadout"];
				lbSetData [_thisLB, _index, "CUSTOM"];
				lbSetCurSel [_thisLB, _index];
			} else {
				for "_i" from 1 to (lbSize _thisLB) do {
					private _className = lbData [_thisLB, (_i - 1)];
					if ((_thisUnit getVariable "unitChoice") == _className) then {
						lbSetCurSel [_thisLB, (_i - 1)];
					};
				};
			};
		};
	};
} forEach _units;

// --- Non-dialog-owning clients: disable everything on rows other than their own ---
if (player != _dialogPlayer) then {
	{
		if (_x != player) then {
			ctrlEnable [(_x getVariable "unitArsenalIDC"), false];
			if (!isPlayer _x) then { ctrlEnable [(_x getVariable "unitDeleteIDC"), false]; };
		};
	} forEach _units;
};

// --- "+1 AI" button: text + enable/show state. Leader-only action; button is
// hidden entirely for non-leaders (mirrors the START MISSION button hiding
// pattern already used for leader-only controls). ---
private _addAICtrl = _display displayCtrl 1602;
if (!isNull _addAICtrl) then {
	if (player != topUnit) then {
		_addAICtrl ctrlShow false;
		_addAICtrl ctrlEnable false;
	} else {
		_addAICtrl ctrlShow true;
		_addAICtrl ctrlSetText format ["Add +1 AI team member (%1/%2)", count _units, _maxSquad];
		_addAICtrl ctrlEnable ((count _units) < _maxSquad);
	};
};

// Newly ctrlCreate'd row controls start FADED (invisible). populateLobby.sqf reveals them
// on dialog-open via a ctrlSetFade 0 pass over allControls; a live rebuild (Add/Remove AI)
// must do the same or the new rows never appear — THE cause of the roster not refreshing
// live (rebuild ran and created the controls, but they stayed invisible).
{
	_x ctrlSetFade 0;
	_x ctrlCommit 0;
} forEach (allControls _display);
