// messageListener.sqf
// Server-side serialized broadcaster for command/radio messages.
//
// Migrated from scheduled `while {true} do { sleep 3 }` to a non-scheduled
// CBA per-frame handler. Behavior preserved:
//   - Pulls one message at a time from dro_messageStack (FIFO).
//   - Only plays if the host has subtitles enabled (getSubtitleOptions).
//   - Serializes playback: waits for the previous subtitle to clear before
//     starting the next one to avoid overlap.
//
// Note: bis_fnc_showsubtitle_subtitle is a client-local variable, so on a
// player-hosted server the host's instance drives the serialization. On a
// true dedicated server it may never appear, so a 15s safety timeout
// releases the lock to prevent the queue from getting permanently stuck.

if (isNil "dro_messageStack") then { dro_messageStack = []; };
if (!isNil "DRO_messageListenerPFH") exitWith {
	diag_log "DRO: messageListener already running, skipping duplicate init";
};

DRO_messagePlaying = false;

DRO_messageListenerPFH = [{
	// Skip while a message is currently being played (lock held)
	if (DRO_messagePlaying) exitWith {};
	// Nothing queued
	if (count dro_messageStack == 0) exitWith {};

	private _thisMessage = dro_messageStack deleteAt 0;
	private _message     = _thisMessage select 0;
	private _playAudio   = _thisMessage select 1;
	diag_log _thisMessage;

	// Honor host's subtitle preference (matches original behavior)
	if !(getSubtitleOptions select 0) exitWith {};

	// Acquire lock and broadcast
	DRO_messagePlaying = true;
	_message remoteExec ["BIS_fnc_EXP_camp_playSubtitles", 0];
	if (_playAudio) then { [] remoteExec ["sun_playSubtitleRadio", 0]; };

	// Wait (non-scheduled) until the subtitle appears AND then disappears
	// on the host, then release the lock so the next message can play.
	[
		{ !isNil "bis_fnc_showsubtitle_subtitle" && {!isNull bis_fnc_showsubtitle_subtitle} },
		{
			[
				{ isNull bis_fnc_showsubtitle_subtitle },
				{ DRO_messagePlaying = false; },
				[],
				30,
				{ DRO_messagePlaying = false; }   // safety: subtitle stuck open
			] call CBA_fnc_waitUntilAndExecute;
		},
		[],
		15,
		{ DRO_messagePlaying = false; }   // safety: subtitle never appeared (e.g. dedicated server)
	] call CBA_fnc_waitUntilAndExecute;
}, 1, []] call CBA_fnc_addPerFrameHandler;

diag_log format ["DRO: messageListener PFH started (id=%1)", DRO_messageListenerPFH];
