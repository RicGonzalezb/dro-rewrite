// ============================================================
// loadParams.sqf — DRO M9: Lobby Param Override
// Roda no SERVIDOR (start.sqf, apos init das variaveis) e no
// CLIENT topUnit (initPlayerLocal.sqf, apos loadProfile.sqf).
// Params sao deterministicos: rodar em ambas as maquinas e
// idempotente — todos os valores vem de BIS_fnc_getParamValue
// que retorna o mesmo resultado em qualquer maquina.
//
// Globals novos: DRO_paramOverrideActive, DRO_paramSkipUI
// Prefixo DRO_ em todos os globais conforme padrao do projeto.
// ============================================================

// Sempre inicializa os dois flags (cobertura do caso override=OFF)
DRO_paramOverrideActive = false;
DRO_paramSkipUI = false;

// ----- Sai imediatamente se override esta desligado -----
if ((["DRO_ParamOverride", 0] call BIS_fnc_getParamValue) != 1) exitWith {
	// M9 hotfix #2: broadcast do estado OFF para nao sobrar valor stale (true)
	// de uma run anterior com override ON num servidor que nao reiniciou a VM.
	publicVariable "DRO_paramOverrideActive";
	publicVariable "DRO_paramSkipUI";
	diag_log "DRO M9: param override OFF — usando UI/profile normal.";
};

// =========================================================
// Override ATIVO — sobrescrever globais a partir dos params
// =========================================================
DRO_paramOverrideActive = true;
publicVariable "DRO_paramOverrideActive";
diag_log "DRO M9: param override ACTIVE — aplicando parametros do lobby.";

// Helper local: valida classname em CfgFactionClasses
private _fnc_validateFaction = {
	params ["_cn"];
	if (_cn isEqualTo "") exitWith { false };
	(configFile >> "CfgFactionClasses" >> _cn) call BIS_fnc_getCfgIsClass
};

// Mapa indice->classname para faccoes de combate (player/enemy)
private _combatFactionMap = [
	"RANDOM",    // 0 = RANDOM (tratado especialmente abaixo)
	"BLU_F",     // 1 = NATO
	"BLU_T_F",   // 2 = NATO (Pacific)
	"OPF_F",     // 3 = CSAT
	"OPF_T_F",   // 4 = CSAT (Pacific)
	"IND_F",     // 5 = AAF
	"IND_G_F",   // 6 = FIA
	"IND_L_F",   // 7 = LDF (Contact/Livonia)
	"OPF_R_F"    // 8 = Russia/Vrana (Contact)
];

// Mapa para faccoes avancadas (indice 0 = vazio = NONE)
private _advFactionMap = [
	"",          // 0 = None
	"BLU_F",
	"BLU_T_F",
	"OPF_F",
	"OPF_T_F",
	"IND_F",
	"IND_G_F",
	"IND_L_F",
	"OPF_R_F"
];

// Mapa para faccoes civis
private _civFactionMap = [
	"",          // 0 = Default (missao escolhe)
	"CIV_F",     // 1 = Civilians
	"CIV_IDAP_F" // 2 = IDAP
];

// ---- 1. Mission Preset ----
missionPreset = ["DRO_ParamPreset", 0] call BIS_fnc_getParamValue;
publicVariable "missionPreset";

// ---- 2. Extended AO (aoOptionSelect) ----
aoOptionSelect = ["DRO_ParamExtendedAO", 0] call BIS_fnc_getParamValue;
publicVariable "aoOptionSelect";

// ---- 3. AI Skill ----
aiSkill = ["DRO_ParamAISkill", 0] call BIS_fnc_getParamValue;
publicVariable "aiSkill";

// ---- 4. Enemy Force Size (aiMultiplier) ----
// Param value e aiMultiplier*10 (ex: 10 -> x1.0, 5 -> x0.5).
// Replica escala de okAO.sqf: ajuste por playableUnits quando < 1.25.
aiMultiplier = (["DRO_ParamEnemySize", 10] call BIS_fnc_getParamValue) / 10;
if (aiMultiplier < 1.25) then {
	if (count playableUnits > 8) then {
		aiMultiplier = (aiMultiplier * (1 + ((count playableUnits * 0.28) / 10)));
	};
};
publicVariable "aiMultiplier";

// ---- 5. Minefields ----
minesEnabled = ["DRO_ParamMines", 0] call BIS_fnc_getParamValue;
publicVariable "minesEnabled";

// ---- 6. Civilians ----
civiliansEnabled = ["DRO_ParamCivilians", 0] call BIS_fnc_getParamValue;
publicVariable "civiliansEnabled";

// ---- 7. Civilians as Agents ----
civiliansAsAgents = ["DRO_ParamCivAgents", 0] call BIS_fnc_getParamValue;
publicVariable "civiliansAsAgents";

// ---- 8. Stealth ----
stealthEnabled = ["DRO_ParamStealth", 0] call BIS_fnc_getParamValue;
publicVariable "stealthEnabled";

// ---- 9. Revive ----
reviveDisabled = ["DRO_ParamRevive", 3] call BIS_fnc_getParamValue;
publicVariable "reviveDisabled";

// ---- 10. Stamina ----
staminaDisabled = ["DRO_ParamStamina", 0] call BIS_fnc_getParamValue;
publicVariable "staminaDisabled";

// ---- 11. Dynamic Simulation ----
dynamicSim = ["DRO_ParamDynSim", 0] call BIS_fnc_getParamValue;
publicVariable "dynamicSim";

// ---- 12. Time of Day ----
// NOTA: start.sqf linha ~34 le timeOfDay do server profileNamespace antes desta
// funcao ser chamada. start.sqf trata esse caso separadamente (ver REQ 4).
timeOfDay = ["DRO_ParamTimeOfDay", 0] call BIS_fnc_getParamValue;
publicVariable "timeOfDay";

// ---- 13. Weather ----
// 0=Random, 1=Clear(0.0), 2=Light(0.3), 3=Overcast(0.7), 4=Storm(1.0)
private _weatherParam = ["DRO_ParamWeather", 0] call BIS_fnc_getParamValue;
weatherOvercast = switch (_weatherParam) do {
	case 0: {"RANDOM"};
	case 1: {0.0};
	case 2: {0.3};
	case 3: {0.7};
	case 4: {1.0};
	default {"RANDOM"};
};
publicVariable "weatherOvercast";

// ---- 14. Month ----
month = ["DRO_ParamMonth", 0] call BIS_fnc_getParamValue;
publicVariable "month";

// ---- 15. Day ----
day = ["DRO_ParamDay", 0] call BIS_fnc_getParamValue;
publicVariable "day";

// ---- 16. Animals ----
animalsEnabled = ["DRO_ParamAnimals", 0] call BIS_fnc_getParamValue;
publicVariable "animalsEnabled";

// ---- 17. Number of Objectives ----
numObjectives = ["DRO_ParamNumObjectives", 0] call BIS_fnc_getParamValue;
publicVariable "numObjectives";

// ---- 18. Preferred Objectives ----
// Replica logica dos botoes em dialogsMainMenu.hpp.
// DRO_ParamObjAsset adiciona todos os 5 sub-tipos de "Destroy Asset"
// (MORTAR/WRECK/VEHICLE/ARTY/HELI) — identico ao botao 2204 da UI.
preferredObjectives = [];
if ((["DRO_ParamObjHVT",     0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "HVT" };
if ((["DRO_ParamObjPOW",     0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "POW" };
if ((["DRO_ParamObjIntel",   0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "INTEL" };
if ((["DRO_ParamObjCache",   0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "CACHE" };
if ((["DRO_ParamObjAsset",   0] call BIS_fnc_getParamValue) == 1) then {
	// Espelha o botao 2204 que agrupa MORTAR/WRECK/VEHICLE/ARTY/HELI
	preferredObjectives pushBackUnique "MORTAR";
	preferredObjectives pushBackUnique "WRECK";
	preferredObjectives pushBackUnique "VEHICLE";
	preferredObjectives pushBackUnique "ARTY";
	preferredObjectives pushBackUnique "HELI";
};
if ((["DRO_ParamObjSteal",   0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "VEHICLESTEAL" };
if ((["DRO_ParamObjClear",   0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "CLEARLZ" };
if ((["DRO_ParamObjFortify", 0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "FORTIFY" };
if ((["DRO_ParamObjDisarm",  0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "DISARM" };
if ((["DRO_ParamObjProtect", 0] call BIS_fnc_getParamValue) == 1) then { preferredObjectives pushBackUnique "PROTECTCIV" };
publicVariable "preferredObjectives";

// Replica logica de neutralTasksChosen / noNeutralTasksChosen de okAO.sqf
neutralTasksChosen = false;
noNeutralTasksChosen = false;
if (("FORTIFY" in preferredObjectives) || ("DISARM" in preferredObjectives) || ("PROTECTCIV" in preferredObjectives)) then {
	neutralTasksChosen = true;
} else {
	if (count preferredObjectives > 0) then {
		noNeutralTasksChosen = true;
	};
};

diag_log format ["DRO M9: preferredObjectives = %1", preferredObjectives];
diag_log format ["DRO M9: neutralTasksChosen=%1 noNeutralTasksChosen=%2", neutralTasksChosen, noNeutralTasksChosen];

// ---- 19. AO Location ----
// Sempre forcado para RANDOM: nao setar customPos nem aoName.
// O usuario nao tem como escolher AO pelo lobby de todos os modos.

// =========================================================
// Faccoes — somente se DRO_ParamUseFactions == 1
// =========================================================
if ((["DRO_ParamUseFactions", 0] call BIS_fnc_getParamValue) == 1) then {

	DRO_paramSkipUI = true;
	publicVariable "DRO_paramSkipUI";
	diag_log "DRO M9: DRO_ParamUseFactions=1 — faccoes via params, UI sera pulada.";

	// M9 fix: resolver faccoes UMA vez, somente no servidor (selectRandom diverge
	// entre server e client em RANDOM). Cliente recebe os classnames via publicVariable.
	if (isServer && {(missionNameSpace getVariable ["factionsChosen", 0]) == 0}) then {
	// ---- Player Faction ----
	private _pfIdx = ["DRO_ParamPlayerFaction", 0] call BIS_fnc_getParamValue;
	private _pfCN  = _combatFactionMap select _pfIdx;
	if (_pfCN isEqualTo "RANDOM" || { !([_pfCN] call _fnc_validateFaction) }) then {
		// Resolve RANDOM/invalido: escolhe aleatoriamente entre faccoes validas (indices 1..8).
		// Nao usa availableFactionsData — esta variavel nao existe ainda quando loadParams roda.
		private _validCombat = (_combatFactionMap select [1, (count _combatFactionMap) - 1]) select { [_x] call _fnc_validateFaction };
		_pfCN = if (count _validCombat > 0) then { selectRandom _validCombat } else { "BLU_F" };
	};
	playersFaction = _pfCN;
	publicVariable "playersFaction";
	diag_log format ["DRO M9: playersFaction = %1 (param indice %2)", playersFaction, _pfIdx];

	// ---- Enemy Faction ----
	private _efIdx = ["DRO_ParamEnemyFaction", 0] call BIS_fnc_getParamValue;
	private _efCN  = _combatFactionMap select _efIdx;
	if (_efCN isEqualTo "RANDOM" || { !([_efCN] call _fnc_validateFaction) }) then {
		// Resolve RANDOM/invalido: escolhe aleatoriamente entre faccoes validas (indices 1..8).
		// NOTA: player e enemy podem cair na mesma faccao/side — fn_setupEnemySides trata playersSide==enemySide.
		private _validCombat = (_combatFactionMap select [1, (count _combatFactionMap) - 1]) select { [_x] call _fnc_validateFaction };
		_efCN = if (count _validCombat > 0) then { selectRandom _validCombat } else { "OPF_F" };
	};
	enemyFaction = _efCN;
	publicVariable "enemyFaction";
	diag_log format ["DRO M9: enemyFaction = %1 (param indice %2)", enemyFaction, _efIdx];

	// ---- Civilian Faction ----
	private _cfIdx = ["DRO_ParamCivFaction", 0] call BIS_fnc_getParamValue;
	private _cfCN  = _civFactionMap select _cfIdx;
	if (_cfCN isEqualTo "" || { !([_cfCN] call _fnc_validateFaction) }) then {
		// Default (0) ou classname invalido: usa CIV_F se existir, senao primeira civil valida do mapa.
		if (["CIV_F"] call _fnc_validateFaction) then {
			_cfCN = "CIV_F";
		} else {
			private _validCiv = (_civFactionMap select [1, (count _civFactionMap) - 1]) select { [_x] call _fnc_validateFaction };
			_cfCN = if (count _validCiv > 0) then { _validCiv select 0 } else { "CIV_F" };
		};
	};
	civFaction = _cfCN;
	publicVariable "civFaction";
	diag_log format ["DRO M9: civFaction = %1 (param indice %2)", civFaction, _cfIdx];

	// ---- Advanced Factions (Player) ----
	// Indices 0=None(""), 1-8=classnames. Valida existencia antes de aplicar.
	private _advP1CN = _advFactionMap select (["DRO_ParamPlayerAdv1", 0] call BIS_fnc_getParamValue);
	private _advP2CN = _advFactionMap select (["DRO_ParamPlayerAdv2", 0] call BIS_fnc_getParamValue);
	private _advP3CN = _advFactionMap select (["DRO_ParamPlayerAdv3", 0] call BIS_fnc_getParamValue);
	if (!([_advP1CN] call _fnc_validateFaction)) then { _advP1CN = "" };
	if (!([_advP2CN] call _fnc_validateFaction)) then { _advP2CN = "" };
	if (!([_advP3CN] call _fnc_validateFaction)) then { _advP3CN = "" };
	// playersFactionAdv armazena classname strings (como okAO.sqf via lbData)
	playersFactionAdv = [_advP1CN, _advP2CN, _advP3CN];
	publicVariable "playersFactionAdv";

	// ---- Advanced Factions (Enemy) ----
	private _advE1CN = _advFactionMap select (["DRO_ParamEnemyAdv1", 0] call BIS_fnc_getParamValue);
	private _advE2CN = _advFactionMap select (["DRO_ParamEnemyAdv2", 0] call BIS_fnc_getParamValue);
	private _advE3CN = _advFactionMap select (["DRO_ParamEnemyAdv3", 0] call BIS_fnc_getParamValue);
	if (!([_advE1CN] call _fnc_validateFaction)) then { _advE1CN = "" };
	if (!([_advE2CN] call _fnc_validateFaction)) then { _advE2CN = "" };
	if (!([_advE3CN] call _fnc_validateFaction)) then { _advE3CN = "" };
	enemyFactionAdv = [_advE1CN, _advE2CN, _advE3CN];
	publicVariable "enemyFactionAdv";

	diag_log format ["DRO M9: playersFactionAdv = %1", playersFactionAdv];
	diag_log format ["DRO M9: enemyFactionAdv = %1", enemyFactionAdv];

	// Destrava o servidor (replica missionNameSpace setVariable de okAO.sqf).
	// Guard: nao regredir se factionsChosen ja foi setado.
	if ((missionNameSpace getVariable ["factionsChosen", 0]) == 0) then {
		missionNameSpace setVariable ["factionsChosen", 1, true];
		diag_log "DRO M9: factionsChosen = 1 (set by loadParams — faccoes via param).";
	};
	};
};

diag_log "DRO M9: loadParams.sqf completo.";
