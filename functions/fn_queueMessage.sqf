// functions/fn_queueMessage.sqf
// DRO_fnc_queueMessage — push a pre-built command/radio message onto the SERVER-side
// dro_messageStack. That stack and its broadcaster (messageListener.sqf) exist ONLY on
// the server (both init in start.sqf, which runs server-side); the broadcaster then
// remoteExec's the subtitle to every client. Scripts that run on a CLIENT — the comm-menu
// support/extract expressions in description.ext (heliExtract, heliDrop, supportArtyComms,
// supportCASHeli) — must route their pushes here. Calling this from a client re-routes to
// the server (2); calling it on the server pushes directly. Safe to call from anywhere.
//
// _message shape: [ [[sender, text, offsetSeconds], ...], playAudio ]
params ["_message"];
if (!isServer) exitWith { _message remoteExec ["DRO_fnc_queueMessage", 2]; };
if (isNil "dro_messageStack") then { dro_messageStack = []; };
dro_messageStack pushBack _message;
