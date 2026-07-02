// ACE mod detection — computed once per machine at earliest common entry point.
// CfgPatches is machine-local but deterministic (MP enforces identical mods),
// so no publicVariable is needed; JIP clients compute their own on connect.
DRO_aceLoaded  = isClass (configFile >> "CfgPatches" >> "ace_main");
DRO_aceMedical = isClass (configFile >> "CfgPatches" >> "ace_medical");
DRO_aceArsenal = isClass (configFile >> "CfgPatches" >> "ace_arsenal");
DRO_aceFatigue = isClass (configFile >> "CfgPatches" >> "ace_advanced_fatigue");

// LAMBS Danger detection — soft compatibility (used only if the mod is loaded).
// Same rationale/locality as the ACE flags above: CfgPatches is machine-local
// but deterministic across MP clients, so no publicVariable / JIP handling needed.
// DRO_lambsLoaded = core mod present; DRO_lambsWP = waypoint/task module that
// provides lambs_wp_fnc_* (taskGarrison/taskPatrol/taskDefend/taskCQB/etc.).
DRO_lambsLoaded = isClass (configFile >> "CfgPatches" >> "lambs_main");
DRO_lambsWP     = isClass (configFile >> "CfgPatches" >> "lambs_wp");
// Master toggle for our LAMBS integration (lobby param DRO_ParamLambsReinforce, default Enabled).
// Active only when the param is Enabled AND the mod is actually loaded.
DRO_lambsCompat = DRO_lambsLoaded && ((["DRO_ParamLambsReinforce", 1] call BIS_fnc_getParamValue) == 1);

// =====================================================================
// LEGACY ALIASES — mantidos para retrocompatibilidade com eventuais
// scripts externos ou mods que referenciem os nomes antigos (sun_*,
// dro_*, rev_*, fnc_*, chz_*). Todas as funções reais estão em
// CfgFunctions como DRO_fnc_*. Remover estes aliases somente após
// confirmar que nenhum código externo depende dos nomes legados.
// Criados no M3 (CfgFunctions migration) — 2026-05-17
// =====================================================================
// Note: CfgFunctions loads DRO_fnc_* BEFORE this runs, so
// these assignments are always valid at init.sqf execution time.

sun_extractIdentities = DRO_fnc_extractIdentities;
sun_waypointCheck = DRO_fnc_waypointCheck;
sun_loopSounds = DRO_fnc_loopSounds;
sun_briefingJIP = DRO_fnc_briefingJIP;
sun_checkAllDeadFleeing = DRO_fnc_checkAllDeadFleeing;
sun_getCfgSide = DRO_fnc_getCfgSide;
sun_getCfgUnitSide = DRO_fnc_getCfgUnitSide;
sun_findWallPositions = DRO_fnc_findWallPositions;
sun_checkIntersect = DRO_fnc_checkIntersect;
sun_getRoadDir = DRO_fnc_getRoadDir;
sun_findRoadRoute = DRO_fnc_findRoadRoute;
sun_createVehicleCrew = DRO_fnc_createVehicleCrew;
sun_getTrueCargo = DRO_fnc_getTrueCargo;
sun_checkVehicleSpawn = DRO_fnc_checkVehicleSpawn;
sun_stringCommaList = DRO_fnc_stringCommaList;
sun_helicopterCanFly = DRO_fnc_helicopterCanFly;
sun_checkRouteWater = DRO_fnc_checkRouteWater;
sun_assignTask = DRO_fnc_assignTask;
sun_setPlayerGroup = DRO_fnc_setPlayerGroup;
sun_newUnit = DRO_fnc_newUnit;
sun_newUnits = DRO_fnc_newUnits;
chz_loadoutCompat = DRO_fnc_loadoutCompat;
sun_jipNewUnit = DRO_fnc_jipNewUnit;
sun_addResetAction = DRO_fnc_addResetAction;
sun_randomTime = DRO_fnc_randomTime;
sun_supplyBox = DRO_fnc_supplyBox;
sun_groupToVehicle = DRO_fnc_groupToVehicle;
sun_moveGroup = DRO_fnc_moveGroup;
sun_defineGrid = DRO_fnc_defineGrid;
sun_replaceSimpleObject = DRO_fnc_replaceSimpleObject;
sun_removeEnemyNVG = DRO_fnc_removeEnemyNVG;
sun_getUnitPositionId = DRO_fnc_getUnitPositionId;
sun_avgPos = DRO_fnc_avgPos;
sun_selectRemove = DRO_fnc_selectRemove;
sun_backpackFix = DRO_fnc_backpackFix;
sun_addArsenal = DRO_fnc_addArsenal;
sun_pasteLoadoutAdd = DRO_fnc_pasteLoadoutAdd;
sun_pasteLoadoutRemove = DRO_fnc_pasteLoadoutRemove;
sun_moveInCargo = DRO_fnc_moveInCargo;
sun_playSubtitleRadio = DRO_fnc_playSubtitleRadio;
sun_playRadioRandom = DRO_fnc_playRadioRandom;
sun_setNameMP = DRO_fnc_setNameMP;
sun_goat = DRO_fnc_goat;
sun_addIntel = DRO_fnc_addIntel;
sun_monthSelChange = DRO_fnc_monthSelChange;
sun_daySelChange = DRO_fnc_daySelChange;
sun_switchButtonSet = DRO_fnc_switchButtonSet;
sun_switchLookup = DRO_fnc_switchLookup;
sun_switchButtonWeather = DRO_fnc_switchButtonWeather;
sun_switchButton = DRO_fnc_switchButton;
sun_lobbyReadyButton = DRO_fnc_lobbyReadyButton;
sun_clearInsert = DRO_fnc_clearInsert;
sun_lobbyMapPreview = DRO_fnc_lobbyMapPreview;
sun_lobbyChangeLabel = DRO_fnc_lobbyChangeLabel;
sun_lobbyCamTarget = DRO_fnc_lobbyCamTarget;
sun_callLoadScreen = DRO_fnc_callLoadScreen;
sun_randomCam = DRO_fnc_randomCam;
sun_missionPreset = DRO_fnc_missionPreset;
dro_checkAOIndexes = DRO_fnc_checkAOIndexes;
dro_civDeathHandler = DRO_fnc_civDeathHandler;
dro_addConstructPoint = DRO_fnc_addConstructPoint;
dro_addConstructAction = DRO_fnc_addConstructAction;
dro_sendProgressMessage = DRO_fnc_sendProgressMessage;
dro_addSabotageAction = DRO_fnc_addSabotageAction;
dro_missionName = DRO_fnc_missionName;
dro_initLobbyCam = DRO_fnc_initLobbyCam;
dro_hvtCapture = DRO_fnc_hvtCapture;
dro_hostageRelease = DRO_fnc_hostageRelease;
dro_detectPosMP = DRO_fnc_detectPosMP;
dro_createSimpleObject = DRO_fnc_createSimpleObject;
dro_extendPos = DRO_fnc_extendPos;
dro_selectRemove = DRO_fnc_selectRemove;
dro_getArtilleryRanges = DRO_fnc_getArtilleryRanges;
dro_heliInsertion = DRO_fnc_heliInsertion;
dro_spawnGroupWeighted = DRO_fnc_spawnGroupWeighted;
dro_setSkillAction = DRO_fnc_setSkillAction;
dro_menuSlider = DRO_fnc_menuSlider;
dro_menuMap = DRO_fnc_menuMap;
dro_clearData = DRO_fnc_clearData;
dro_inputDaysData = DRO_fnc_inputDaysData;
rev_AIListen = DRO_fnc_AIListen;
rev_removeDragAction = DRO_fnc_removeDragAction;
rev_addReviveToUnit = DRO_fnc_addReviveToUnit;
rev_resetAI = DRO_fnc_resetAI;
rev_findFAK = DRO_fnc_findFAK;
rev_changeLocal = DRO_fnc_changeLocal;
rev_reviveUnit = DRO_fnc_reviveUnit;
rev_reviveActionAdd = DRO_fnc_reviveActionAdd;
rev_handleDamage = DRO_fnc_handleDamage;
rev_suicideActionAdd = DRO_fnc_suicideActionAdd;
rev_resetCamera = DRO_fnc_resetCamera;
rev_dragActionAdd = DRO_fnc_dragActionAdd;
rev_drag = DRO_fnc_drag;
rev_handleKilled = DRO_fnc_handleKilled;
rev_AIHeal = DRO_fnc_AIHeal;
dro_unitTaskObjective = DRO_fnc_unitTaskObjective;
dro_triggerAmbushSpawn = DRO_fnc_triggerAmbushSpawn;
dro_localBuildingPatrol = DRO_fnc_localBuildingPatrol;
dro_spawnEnemyGarrison = DRO_fnc_spawnEnemyGarrison;
fnc_generateAO = DRO_fnc_generateAO;
fnc_generateAOLoc = DRO_fnc_generateAOLoc;
fnc_generateCampsite = DRO_fnc_generateCampsite;
fnc_selectObjective = DRO_fnc_selectObjective;
fnc_selectReactiveObjective = DRO_fnc_selectReactiveObjective;
fnc_defineFactionClasses = DRO_fnc_defineFactionClasses;
fnc_generateRoadblock = DRO_fnc_generateRoadblock;
fnc_generateBunker = DRO_fnc_generateBunker;
fnc_generateBarrier = DRO_fnc_generateBarrier;
fnc_generateEmplacement = DRO_fnc_generateEmplacement;
fnc_spawnEnemyCompound = DRO_fnc_spawnEnemyCompound;

diag_log "DRO M3: Legacy aliases assigned.";
