timeOfDay = profileNamespace getVariable ["DRO_timeOfDay", 0];
publicVariable "timeOfDay";
month = profileNamespace getVariable ["DRO_month", 0];
publicVariable "month";
day = profileNamespace getVariable ["DRO_day", 0];
publicVariable "day";
weatherOvercast = profileNamespace getVariable ["DRO_weatherOvercast", "RANDOM"];
publicVariable "weatherOvercast";
animalsEnabled = profileNamespace getVariable ['DRO_animalsEnabled', 0];
publicVariable "animalsEnabled";
aiSkill = profileNamespace getVariable ["DRO_aiSkill", 0];
publicVariable "aiSkill";
aiMultiplier = profileNamespace getVariable ["DRO_aiMultiplier", 1];
publicVariable "aiMultiplier";
numObjectives = profileNamespace getVariable ["DRO_numObjectives", 0];
publicVariable "numObjectives";
preferredObjectives = profileNamespace getVariable ["DRO_objectivePrefs", []];
publicVariable "preferredObjectives";
aoOptionSelect = profileNamespace getVariable ["DRO_aoOptionSelect", 0];
publicVariable "aoOptionSelect";
minesEnabled = profileNamespace getVariable ["DRO_minesEnabled", 0];
publicVariable "minesEnabled";
civiliansEnabled = profileNamespace getVariable ["DRO_civiliansEnabled", 0];
publicVariable "civiliansEnabled";
civiliansAsAgents = profileNamespace getVariable ["DRO_civiliansAsAgents", 0];
publicVariable "civiliansAsAgents";
arsenalEnabled = profileNamespace getVariable ["DRO_arsenalEnabled", 0];
publicVariable "arsenalEnabled";
stealthEnabled = profileNamespace getVariable ["DRO_stealthEnabled", 0];
publicVariable "stealthEnabled";

if (DRO_aceMedical) then {
	reviveDisabled = profileNamespace getVariable ["DRO_reviveDisabled", 3];
	publicVariable "reviveDisabled";
} else {
	reviveDisabled = profileNamespace getVariable ["DRO_reviveDisabled", 0];
	publicVariable "reviveDisabled";
};

// enableGunLights needs a STRING mode; map the stored index (0/1/2) to it so this global
// is never a raw number. Was causing 'enablegunlights: Type Number, expected String' in MP
// when this client publicVariable raced ahead of start.sqf's string conversion.
private _aiwl = profileNamespace getVariable ["DRO_missionAIWeaponLight", 1];
if (_aiwl isEqualType 0) then { _aiwl = ["Auto", "ForceOn", "ForceOFF"] select (_aiwl max 0 min 2); };
missionAIWeaponLight = _aiwl;
publicVariable "missionAIWeaponLight";
staminaDisabled = profileNamespace getVariable ["DRO_staminaDisabled", 0];
publicVariable "staminaDisabled";
missionPreset = profileNamespace getVariable ["DRO_missionPreset", 0];
publicVariable "missionPreset";
insertType = profileNamespace getVariable ["DRO_insertType", 0];
publicVariable "insertType";
randomSupports = profileNamespace getVariable ["DRO_randomSupports", 0];
publicVariable "randomSupports";
customSupports = profileNamespace getVariable ["DRO_supportPrefs", []];
publicVariable "customSupports";
dynamicSim = profileNamespace getVariable ["DRO_dynamicSim", 0];
publicVariable "dynamicSim";
diag_log "DRO: variables loaded from profile";
