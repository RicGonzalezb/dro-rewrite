# DRO ACE Livonia — Refactor Progress Log

---

## M2 — Bug fixes deferidos — 2026-05-16

### Bug #1 (vn_artillery_settings empty arrays)

**Status:** DONE

**Arquivo:** `initServer.sqf`

**Linhas:** 23, 25

**Mudança:**
- Linha 23: `setVariable ["vn_allowed_radio_backpacks", [], true]` → `setVariable ["vn_allowed_radio_backpacks", _vn_allowed_radio_backpacks, true]`
- Linha 25: `setVariable ["vn_allowed_radio_vehicles", [], true]` → `setVariable ["vn_allowed_radio_vehicles", _vn_allowed_radio_vehicles, true]`

**Notas:**
- O bloco `class vn_artillery_settings { ... }` continua comentado em `description.ext`, então `BIS_fnc_getCfgDataArray` retorna `[]` em runtime de qualquer forma — o fix não tem efeito visível hoje.
- Quando o feature SOG PF Radio Support for reabilitado, a config passará a existir e o missionNamespace receberá os arrays corretos em vez de `[]`.
- Fix é safe, sem side effects, não toca em nenhum código marcado "// Migrated from ...".

---

### Bug #2 (revive EH leak + action leak)

**Status:** DONE

**Arquivos modificados:**
- `sunday_revive/reviveFunctions.sqf`

**Estratégia escolhida:**

Após análise completa do código, o problema real é **duplo**:

1. **Event Handler leak (menor do que descrito):** `HandleDamage` e `Killed` já eram removidos via `removeAllEventHandlers` antes de re-adicionar — isso estava correto. Não há `HandleRating` no código atual. Adicionado `DRO_revHandlerIds` (array de `[tipo, id]`) como infraestrutura para tracking de futuros EHs adicionados diretamente (não via `remoteExec`), com limpeza via `removeEventHandler` no início do callback Respawn.

2. **Action leak (o bug real):** `rev_reviveActionAdd` e `rev_dragActionAdd` eram chamados via `remoteExec` a cada respawn SEM remover as ações anteriores. Após 5 respawns, cada jogador próximo via 5 hold actions "Revive" e 5 addActions "Drag" empilhadas.

**Mudanças aplicadas:**

**a) Nova função `rev_removeDragAction`** (adicionada antes de `rev_addReviveToUnit`):
Chamada via `remoteExec` em cada cliente para remover o `addAction` local de drag antes de re-adicionar. Usa o ID salvo em `rev_dragActionID` (já existia).

**b) Callback Respawn em `rev_addReviveToUnit` reescrito:**
- `params ["_newUnit", "_oldUnit"]` em vez de `_this select N` (clareza)
- `removeAllEventHandlers` para HandleDamage e Killed (mantido)
- Loop de limpeza via `DRO_revHandlerIds` (infraestrutura futura)
- `_allPlayers` computado cedo para ser reutilizado na limpeza E no re-add
- Remove hold action antiga: `BIS_fnc_holdActionRemove` antes de chamar `rev_reviveActionAdd`
- Remove drag actions antigas: `remoteExec ["rev_removeDragAction", _allPlayers, false]` antes de chamar `rev_dragActionAdd` (JIP=false — limpeza não precisa persistir para novos joiners)
- Re-add de handlers e ações na sequência correta

**Side effects considerados:**

- O `remoteExec ["rev_removeDragAction", _allPlayers, false]` usa `JIP=false` intencionalmente — novos players que joinam depois do respawn não precisam receber um "cleanup", eles entram limpos e recebem as ações via `JIP=true` dos remoteExecs subsequentes.
- `_allPlayers` calculado como `allPlayers - [_newUnit]` antes dos remoteExecs de limpeza. Players que joinaram entre o último respawn e este são incluídos; players que saíram neste intervalo não recebem o remoteExec (correto, eles não têm a action de qualquer forma).
- `BIS_fnc_holdActionRemove` opera globalmente (hold actions são globais no engine), então um único call a partir da máquina do player é suficiente.
- SP (`else` branch) não tem callback Respawn — sem impacto.

**Pontos de atenção pro teste:**

1. Respawnar 5 vezes seguidas → confirmar que apenas 1 hold action "Revive" e 1 drag action "Drag" aparecem pra cada outro jogador próximo (sem stack).
2. Confirmar que o hold action de revive ainda funciona após respawn (action aparece, timer roda, unit é revivida).
3. Confirmar que drag action ainda funciona após respawn.
4. Testar JIP: jogador novo que entra APÓS um respawn deve ver as actions corretamente (somente 1 de cada).
5. Confirmar que `rev_holdActionID` e `rev_dragActionID` são corretamente atualizados após cada respawn (por `rev_reviveActionAdd` e `rev_dragActionAdd` respectivamente).

---

### Descobertas inesperadas / Issues flagadas para módulos futuros

**[FLAG] `rev_changeLocal` também tem Respawn EH leak (não corrigido neste módulo):**

Função `rev_changeLocal` (linhas ~257-286) adiciona um novo `addEventHandler ["Respawn", ...]` via `remoteExec` cada vez que a localidade de uma unidade AI muda, SEM remover o handler anterior. Se a localidade de uma unidade AI mudar N vezes, haverá N Respawn handlers acumulados. Cada handler adiciona HandleDamage + Killed sem `removeAllEventHandlers`, então o leak de EH existe ali.

Correção recomendada: similar ao que foi feito em `rev_addReviveToUnit` — adicionar `removeAllEventHandlers "Respawn"` (ou tracking por `DRO_revRespawnHandlerId`) antes de re-adicionar o Respawn EH em `rev_changeLocal`. Cuidado: `removeAllEventHandlers "Respawn"` dentro de `rev_changeLocal` não afeta o Respawn EH adicionado por `rev_addReviveToUnit` porque ambos foram adicionados em máquinas/contextos diferentes via `remoteExec`. Requer análise de locality antes de aplicar.

**[OK] `HandleRating`:** Não existe `addEventHandler ["HandleRating"` em nenhum lugar no arquivo. Ponto do task prompt foi verificado e é não-aplicável.

**[OK] Handler `Local` (AI units):** Adicionado uma única vez em `rev_addReviveToUnit` com JIP=true (`[_unit, ["Local", rev_changeLocal]] remoteExec ["addEventHandler", 0, true]`). Correto não remover no respawn — a unidade continua precisando detectar locality changes.

## M3 — CfgFunctions migration — 2026-05-17

### Funções migradas

#### De lib files (→ functions/fn_*.sqf, carregadas via CfgFunctions class core)
- `DRO_fnc_createSimpleObject` (de `dro_createSimpleObject` em sundayFunctions.sqf)
- `DRO_fnc_extendPos` (de `dro_extendPos` em sundayFunctions.sqf)
- `DRO_fnc_selectRemove` (de `dro_selectRemove` em sundayFunctions.sqf)
- `DRO_fnc_getArtilleryRanges` (de `dro_getArtilleryRanges` em sundayFunctions.sqf)
- `DRO_fnc_heliInsertion` (de `dro_heliInsertion` em sundayFunctions.sqf)
- `DRO_fnc_spawnGroupWeighted` (de `dro_spawnGroupWeighted` em sundayFunctions.sqf)
- `DRO_fnc_setSkillAction` (de `dro_setSkillAction` em sundayFunctions.sqf)
- `DRO_fnc_checkAOIndexes` (de `dro_checkAOIndexes` em droFunctions.sqf)
- `DRO_fnc_civDeathHandler` (de `dro_civDeathHandler` em droFunctions.sqf)
- `DRO_fnc_addConstructPoint` (de `dro_addConstructPoint` em droFunctions.sqf)
- `DRO_fnc_addConstructAction` (de `dro_addConstructAction` em droFunctions.sqf)
- `DRO_fnc_sendProgressMessage` (de `dro_sendProgressMessage` em droFunctions.sqf)
- `DRO_fnc_addSabotageAction` (de `dro_addSabotageAction` em droFunctions.sqf)
- `DRO_fnc_missionName` (de `dro_missionName` em droFunctions.sqf)
- `DRO_fnc_addIntel` (de `sun_addIntel` em droFunctions.sqf)
- `DRO_fnc_initLobbyCam` (de `dro_initLobbyCam` em droFunctions.sqf)
- `DRO_fnc_hvtCapture` (de `dro_hvtCapture` em droFunctions.sqf)
- `DRO_fnc_hostageRelease` (de `dro_hostageRelease` em droFunctions.sqf)
- `DRO_fnc_detectPosMP` (de `dro_detectPosMP` em droFunctions.sqf)
- `DRO_fnc_monthSelChange` (de `sun_monthSelChange` em menuFunctions.sqf)
- `DRO_fnc_daySelChange` (de `sun_daySelChange` em menuFunctions.sqf)
- `DRO_fnc_switchButtonSet` (de `sun_switchButtonSet` em menuFunctions.sqf)
- `DRO_fnc_switchLookup` (de `sun_switchLookup` em menuFunctions.sqf)
- `DRO_fnc_switchButtonWeather` (de `sun_switchButtonWeather` em menuFunctions.sqf)
- `DRO_fnc_switchButton` (de `sun_switchButton` em menuFunctions.sqf)
- `DRO_fnc_lobbyReadyButton` (de `sun_lobbyReadyButton` em menuFunctions.sqf)
- `DRO_fnc_clearInsert` (de `sun_clearInsert` em menuFunctions.sqf)
- `DRO_fnc_lobbyMapPreview` (de `sun_lobbyMapPreview` em menuFunctions.sqf)
- `DRO_fnc_lobbyChangeLabel` (de `sun_lobbyChangeLabel` em menuFunctions.sqf)
- `DRO_fnc_lobbyCamTarget` (de `sun_lobbyCamTarget` em menuFunctions.sqf)
- `DRO_fnc_menuSlider` (de `dro_menuSlider` em menuFunctions.sqf)
- `DRO_fnc_menuMap` (de `dro_menuMap` em menuFunctions.sqf)
- `DRO_fnc_callLoadScreen` (de `sun_callLoadScreen` em menuFunctions.sqf)
- `DRO_fnc_randomCam` (de `sun_randomCam` em menuFunctions.sqf)
- `DRO_fnc_clearData` (de `dro_clearData` em menuFunctions.sqf)
- `DRO_fnc_missionPreset` (de `sun_missionPreset` em menuFunctions.sqf)
- `DRO_fnc_inputDaysData` (de `dro_inputDaysData` em menuFunctions.sqf)
- `DRO_fnc_AIListen` (de `rev_AIListen` em reviveFunctions.sqf)
- `DRO_fnc_removeDragAction` (de `rev_removeDragAction` em reviveFunctions.sqf)
- `DRO_fnc_addReviveToUnit` (de `rev_addReviveToUnit` em reviveFunctions.sqf)
- `DRO_fnc_resetAI` (de `rev_resetAI` em reviveFunctions.sqf)
- `DRO_fnc_findFAK` (de `rev_findFAK` em reviveFunctions.sqf)
- `DRO_fnc_changeLocal` (de `rev_changeLocal` em reviveFunctions.sqf)
- `DRO_fnc_reviveUnit` (de `rev_reviveUnit` em reviveFunctions.sqf)
- `DRO_fnc_reviveActionAdd` (de `rev_reviveActionAdd` em reviveFunctions.sqf)
- `DRO_fnc_handleDamage` (de `rev_handleDamage` em reviveFunctions.sqf)
- `DRO_fnc_suicideActionAdd` (de `rev_suicideActionAdd` em reviveFunctions.sqf)
- `DRO_fnc_resetCamera` (de `rev_resetCamera` em reviveFunctions.sqf)
- `DRO_fnc_dragActionAdd` (de `rev_dragActionAdd` em reviveFunctions.sqf)
- `DRO_fnc_drag` (de `rev_drag` em reviveFunctions.sqf)
- `DRO_fnc_handleKilled` (de `rev_handleKilled` em reviveFunctions.sqf)
- `DRO_fnc_AIHeal` (de `rev_AIHeal` em reviveFunctions.sqf)
- `DRO_fnc_unitTaskObjective` (de `dro_unitTaskObjective` em generateEnemiesFunctions.sqf)
- `DRO_fnc_triggerAmbushSpawn` (de `dro_triggerAmbushSpawn` em generateEnemiesFunctions.sqf)
- `DRO_fnc_localBuildingPatrol` (de `dro_localBuildingPatrol` em generateEnemiesFunctions.sqf)
- `DRO_fnc_spawnEnemyGarrison` (de `dro_spawnEnemyGarrison` em generateEnemiesFunctions.sqf)

#### De compile preprocessFile (→ CfgFunctions com file = explícito)
- `DRO_fnc_generateAO` (de `fnc_generateAO` — generate_ao/generateAO.sqf)
- `DRO_fnc_generateAOLoc` (de `fnc_generateAOLoc` — generate_ao/generateAOLocation.sqf)
- `DRO_fnc_generateCampsite` (de `fnc_generateCampsite` — generate_ao/generateCampsite.sqf)
- `DRO_fnc_selectObjective` (de `fnc_selectObjective` — objectives/objSelect.sqf)
- `DRO_fnc_selectReactiveObjective` (de `fnc_selectReactiveObjective` — objectives/selectReactiveTask.sqf)
- `DRO_fnc_defineFactionClasses` (de `fnc_defineFactionClasses` — fnc_lib/defineFactionClasses.sqf)
- `DRO_fnc_generateRoadblock` (de `fnc_generateRoadblock` — generate_enemies/generateRoadblock.sqf)
- `DRO_fnc_generateBunker` (de `fnc_generateBunker` — generate_enemies/generateBunker.sqf)
- `DRO_fnc_generateBarrier` (de `fnc_generateBarrier` — generate_enemies/generateBarrier.sqf)
- `DRO_fnc_generateEmplacement` (de `fnc_generateEmplacement` — generate_enemies/generateEmplacement.sqf)
- `DRO_fnc_spawnEnemyCompound` (de `fnc_spawnEnemyCompound` — generate_enemies/generateCompound.sqf)

**Total: 67 funções migradas**
  - 56 de lib files (sundayFunctions, droFunctions, menuFunctions, reviveFunctions, generateEnemiesFunctions)
  - 11 de compile preprocessFile (generateAO, objectives, enemies_gen, factions)
  - Observação: `dro_selectRemove` e `sun_selectRemove` eram idênticas — fundidas em `DRO_fnc_selectRemove`

### Arquivos criados

#### functions/ (98 arquivos fn_*.sqf)
- `functions/fn_AIHeal.sqf`
- `functions/fn_AIListen.sqf`
- `functions/fn_addArsenal.sqf`
- `functions/fn_addConstructAction.sqf`
- `functions/fn_addConstructPoint.sqf`
- `functions/fn_addIntel.sqf`
- `functions/fn_addResetAction.sqf`
- `functions/fn_addReviveToUnit.sqf`
- `functions/fn_addSabotageAction.sqf`
- `functions/fn_assignTask.sqf`
- `functions/fn_avgPos.sqf`
- `functions/fn_backpackFix.sqf`
- `functions/fn_briefingJIP.sqf`
- `functions/fn_callLoadScreen.sqf`
- `functions/fn_changeLocal.sqf`
- `functions/fn_checkAOIndexes.sqf`
- `functions/fn_checkAllDeadFleeing.sqf`
- `functions/fn_checkIntersect.sqf`
- `functions/fn_checkRouteWater.sqf`
- `functions/fn_checkVehicleSpawn.sqf`
- `functions/fn_civDeathHandler.sqf`
- `functions/fn_clearData.sqf`
- `functions/fn_clearInsert.sqf`
- `functions/fn_createSimpleObject.sqf`
- `functions/fn_createVehicleCrew.sqf`
- `functions/fn_daySelChange.sqf`
- `functions/fn_defineGrid.sqf`
- `functions/fn_detectPosMP.sqf`
- `functions/fn_drag.sqf`
- `functions/fn_dragActionAdd.sqf`
- `functions/fn_extendPos.sqf`
- `functions/fn_extractIdentities.sqf`
- `functions/fn_findFAK.sqf`
- `functions/fn_findRoadRoute.sqf`
- `functions/fn_findWallPositions.sqf`
- `functions/fn_getArtilleryRanges.sqf`
- `functions/fn_getCfgSide.sqf`
- `functions/fn_getCfgUnitSide.sqf`
- `functions/fn_getRoadDir.sqf`
- `functions/fn_getTrueCargo.sqf`
- `functions/fn_getUnitPositionId.sqf`
- `functions/fn_goat.sqf`
- `functions/fn_groupToVehicle.sqf`
- `functions/fn_handleDamage.sqf`
- `functions/fn_handleKilled.sqf`
- `functions/fn_heliInsertion.sqf`
- `functions/fn_helicopterCanFly.sqf`
- `functions/fn_hostageRelease.sqf`
- `functions/fn_hvtCapture.sqf`
- `functions/fn_initLobbyCam.sqf`
- `functions/fn_inputDaysData.sqf`
- `functions/fn_jipNewUnit.sqf`
- `functions/fn_loadoutCompat.sqf`
- `functions/fn_lobbyCamTarget.sqf`
- `functions/fn_lobbyChangeLabel.sqf`
- `functions/fn_lobbyMapPreview.sqf`
- `functions/fn_lobbyReadyButton.sqf`
- `functions/fn_localBuildingPatrol.sqf`
- `functions/fn_loopSounds.sqf`
- `functions/fn_menuMap.sqf`
- `functions/fn_menuSlider.sqf`
- `functions/fn_missionName.sqf`
- `functions/fn_missionPreset.sqf`
- `functions/fn_monthSelChange.sqf`
- `functions/fn_moveGroup.sqf`
- `functions/fn_moveInCargo.sqf`
- `functions/fn_newUnit.sqf`
- `functions/fn_newUnits.sqf`
- `functions/fn_pasteLoadoutAdd.sqf`
- `functions/fn_pasteLoadoutRemove.sqf`
- `functions/fn_playRadioRandom.sqf`
- `functions/fn_playSubtitleRadio.sqf`
- `functions/fn_randomCam.sqf`
- `functions/fn_randomTime.sqf`
- `functions/fn_removeDragAction.sqf`
- `functions/fn_removeEnemyNVG.sqf`
- `functions/fn_replaceSimpleObject.sqf`
- `functions/fn_resetAI.sqf`
- `functions/fn_resetCamera.sqf`
- `functions/fn_reviveActionAdd.sqf`
- `functions/fn_reviveUnit.sqf`
- `functions/fn_selectRemove.sqf`
- `functions/fn_sendProgressMessage.sqf`
- `functions/fn_setNameMP.sqf`
- `functions/fn_setPlayerGroup.sqf`
- `functions/fn_setSkillAction.sqf`
- `functions/fn_spawnEnemyGarrison.sqf`
- `functions/fn_spawnGroupWeighted.sqf`
- `functions/fn_stringCommaList.sqf`
- `functions/fn_suicideActionAdd.sqf`
- `functions/fn_supplyBox.sqf`
- `functions/fn_switchButton.sqf`
- `functions/fn_switchButtonSet.sqf`
- `functions/fn_switchButtonWeather.sqf`
- `functions/fn_switchLookup.sqf`
- `functions/fn_triggerAmbushSpawn.sqf`
- `functions/fn_unitTaskObjective.sqf`
- `functions/fn_waypointCheck.sqf`

#### Outros arquivos criados/modificados
- `description.ext` — bloco `CfgFunctions` adicionado ao final (109 classes: 98 core + 11 compile-preprocessFile)
- `init.sqf` — criado com 110 aliases temporários (legados → DRO_fnc_*)
- `_archive/fnc_lib_backup_M3/` — cópias dos 5 lib files originais
- Stubs de deprecação em: sundayFunctions.sqf, droFunctions.sqf, menuFunctions.sqf, reviveFunctions.sqf, generateEnemiesFunctions.sqf

### Call sites atualizados

- **357** substituições de `sun_*` → `DRO_fnc_*`
- **233** substituições de `dro_*` → `DRO_fnc_*`
- **61** substituições de `rev_*` → `DRO_fnc_*`
- **3** substituições de `chz_*` → `DRO_fnc_*`
- **41** substituições de `fnc_*` → `DRO_fnc_*` (compile preprocessFile)
- **Total: 695 call sites** em 166 arquivos

Top 10 por volume de substituições:
  - `sun_selectRemove` → `DRO_fnc_selectRemove`: 84x
  - `dro_spawnGroupWeighted` → `DRO_fnc_spawnGroupWeighted`: 74x
  - `dro_extendPos` → `DRO_fnc_extendPos`: 40x
  - `dro_createSimpleObject` → `DRO_fnc_createSimpleObject`: 38x
  - `sun_switchButtonSet` → `DRO_fnc_switchButtonSet`: 29x
  - `sun_switchButton` → `DRO_fnc_switchButton`: 27x
  - `sun_createVehicleCrew` → `DRO_fnc_createVehicleCrew`: 21x
  - `fnc_selectObjective` → `DRO_fnc_selectObjective`: 20x
  - `sun_getTrueCargo` → `DRO_fnc_getTrueCargo`: 20x
  - `sun_groupToVehicle` → `DRO_fnc_groupToVehicle`: 20x

### #includes removidos

**start.sqf** (4 #includes comentados + 11 compile preprocessFile comentados):
- `// [M3 removed] #include "sunday_system\fnc_lib\sundayFunctions.sqf"`
- `// [M3 removed] #include "sunday_system\fnc_lib\droFunctions.sqf"`
- `// [M3 removed] #include "sunday_revive\reviveFunctions.sqf"`
- `// [M3 removed] #include "sunday_system\generate_enemies\generateEnemiesFunctions.sqf"`
- `// [M3 removed]` — todas as linhas `fnc_* = compile preprocessFile ...`

**initPlayerLocal.sqf** (4 #includes comentados):
- `// [M3 removed] #include "sunday_system\fnc_lib\sundayFunctions.sqf"`
- `// [M3 removed] #include "sunday_system\fnc_lib\droFunctions.sqf"`
- `// [M3 removed] #include "sunday_revive\reviveFunctions.sqf"`
- `// [M3 removed] #include "sunday_system\fnc_lib\menuFunctions.sqf"`

**objectsLibrary.sqf**: mantido intacto — é data puro (arrays), não funções.

### Aliases adicionados

`init.sqf` — 110 aliases temporários mapeando todos os nomes legados para `DRO_fnc_*`.
Exemplos:
- `sun_selectRemove = DRO_fnc_selectRemove;`
- `dro_civDeathHandler = DRO_fnc_civDeathHandler;`
- `rev_addReviveToUnit = DRO_fnc_addReviveToUnit;`
- `fnc_generateAO = DRO_fnc_generateAO;`
- *(+ 106 outros — ver init.sqf)*

### Pontos de atenção

1. **`DRO_fnc_handleDamage` / `DRO_fnc_handleKilled`** — funções de revive com lógica de ACE. São chamadas via `addEventHandler`. Verificar se os event handlers foram atualizados para o nome novo (9 substituições em initRevive.sqf e fn_addReviveToUnit.sqf — confirmar).

2. **`DRO_fnc_changeLocal`** — usa `remoteExec` internamente. Se a missão usar `CfgRemoteExec` em modo strict, adicionar `"DRO_fnc_changeLocal"` à whitelist.

3. **`DRO_fnc_setNameMP`** e **`DRO_fnc_randomTime`** — chamadas via `remoteExec ["...", 0, true]` em start.sqf (persistidas em JIP). Confirmar que o nome novo está na CfgRemoteExec se aplicável.

4. **`DRO_fnc_briefingJIP`** — era chamada via `remoteExec ["sun_briefingJIP", 0, true]` (JIP). A linha está comentada em briefing.sqf mas verificar se a lógica JIP foi migrada corretamente.

5. **`dro_selectRemove` / `sun_selectRemove`** — eram idênticas. Fundidas em `DRO_fnc_selectRemove` (84 call sites — a mais usada do codebase). Sem risco funcional.

6. **`chz_loadoutCompat`** — prefixo `chz_` incomum (provavelmente de uma versão anterior). Alias adicionado em init.sqf. Verificar se existe código externo (scripts de loadout, etc.) que ainda use `chz_loadoutCompat`.

7. **`DRO_fnc_clearData`** / **`DRO_fnc_missionPreset`** — 16 substituições cada, geradas em dialogsMainMenu.hpp (dialogs). Testar UI do lobby para confirmar callbacks ainda funcionam.

8. **CfgRemoteExec**: se a missão usar whitelist de remoteExec, as seguintes funções aparecem em `remoteExec` no codebase e precisam ser adicionadas:
   - `DRO_fnc_setNameMP`
   - `DRO_fnc_randomTime`  
   - `DRO_fnc_briefingJIP`
   - `DRO_fnc_changeLocal`
   - `DRO_fnc_civDeathHandler`

9. **`generateCompound.sqf`** mapeado para `DRO_fnc_spawnEnemyCompound` — nome do arquivo não corresponde ao nome da função. Documentado na CfgFunctions com `file = ` explícito. OK.
