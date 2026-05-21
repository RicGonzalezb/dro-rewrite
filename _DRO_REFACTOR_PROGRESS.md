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

---

## M3 hotfix — macro `aliveVeh` ausente em fn_*.sqf — 2026-05-17 (Opus)

### Sintoma

Boot da missão gerou ~60 erros no .rpt:
- `fn_checkVehicleSpawn.sqf:5 — Error Missing )`
- `fn_helicopterCanFly.sqf:5 — Error Missing )`
- Cascata de runtime errors em cache.sqf:26 etc.: `Undefined variable in expression: _object`

### Causa raiz

`#define aliveVeh(none) (none getHitPointDamage "hitHull") < 0.7` estava definido no topo de `sundayFunctions.sqf` (lib original). M3 extraiu o body de `sun_checkVehicleSpawn` e `sun_helicopterCanFly` para `functions/fn_*.sqf` mas NÃO copiou o `#define`. CfgFunctions usa `preprocessFileLineNumbers` que processa cada arquivo isoladamente — o macro fica indefinido, o texto literal `aliveVeh(_vehicle)` chega no compilador, e o parser falha com "Missing )".

Quando a função não compila, calls retornam sem assignment, e variáveis dependentes (como `_object` no cache.sqf) ficam undefined.

### Fix aplicado

Adicionado `#define aliveVeh(none) (none getHitPointDamage "hitHull") < 0.7` no topo de:
- `functions/fn_checkVehicleSpawn.sqf`
- `functions/fn_helicopterCanFly.sqf`

### Lição aprendida (relevante para M5/M6)

Quando extrair funções pra CfgFunctions, sempre verificar se o body usa macros (`#define` no topo da lib original). Copiar os `#define` relevantes pro novo arquivo, OU substituir o uso de macro por código inline.

### Latent bug não corrigido

`fn_checkVehicleSpawn.sqf` linha 6 referencia `_vehicleType` que não está em params nem declarado na função. Era escopo herdado do caller via `#include`. Com CfgFunctions a variável é undefined. **Mas só dispara se `aliveVeh` retornar false** (vehicle hitHull damage >= 0.7), o que não acontece em spawn fresco. Latent — anotar pra M6.

---

## M3 hotfix #2 — fn_spawnEnemyGarrison undefined `_unit` — 2026-05-17 (Opus)

### Sintoma

Errors no .rpt durante geração de inimigos:
- `fn_spawnEnemyGarrison.sqf:19 — Undefined variable in expression: _unit`
- `fn_spawnEnemyGarrison.sqf:23 — Undefined variable in expression: _unit`

### Causa raiz

Bug latente do código original (não causado pelo M3, apenas exposto). `DRO_fnc_spawnGroupWeighted` retorna `grpNull` quando falha (ex: posição inválida, config incompleta). O check `!isNil "_group"` é TRUE pra grpNull (não é nil), passa o guard. Aí `(units grpNull) select 0` retorna nil, e `_unit = nil` "desfaz" a variável. Próxima linha `_unit setUnitPos "UP"` falha com `_unit undefined`.

### Fix aplicado

`fn_spawnEnemyGarrison.sqf` — guard reforçado:
```sqf
// Antes:
if (!isNil "_group") then {
    _unit = ((units _group) select 0);

// Depois:
if (!isNil "_group" && {!isNull _group} && {count (units _group) > 0}) then {
    private _unit = ((units _group) select 0);
```

Adicionado `private` em `_unit` por boa prática (CfgFunctions tem escopo próprio).

### Outras chamadas de `DRO_fnc_spawnGroupWeighted` (anotar pra M6 audit)

Grep `DRO_fnc_spawnGroupWeighted` retornou 74 call sites no M3 report. Cada uma deveria ter guard similar (`!isNull && count units > 0`). Audit do M6 deve verificar todos.


## M3 hotfix #3 — fn_selectRemove empty array crash — 2026-05-19

### Sintoma
`_return` undefined em `fn_selectRemove.sqf` quando chamado com array vazio.
`_index` sem `private` vazava entre chamadas encadeadas no escopo de CfgFunctions.
Cascata: `_thisHouse` undefined em `generateCivilians.sqf:217` → `getPos _thisHouse` falha → `_building` undefined em `BIS_fnc_buildingPositions`.

### Fix aplicado

**`functions/fn_selectRemove.sqf`** — reescrito:
- `params [["_arr", []]]` em vez de `_this select 0`
- Guard `if (_arr isEqualTo []) exitWith { objNull }` para array vazio
- `private _index` e `private _return` — sem vazamento de escopo
- Sem `;` no último `_return` (valor de retorno implícito)
- Mutação por `deleteAt` preservada (comportamento intencional)

**`sunday_system/civilians/generateCivilians.sqf:217`** — adicionado guard:
```sqf
private _thisHouse = [_filteredHouses] call DRO_fnc_selectRemove;
if (isNull _thisHouse) then { continue };
```
Proteção para quando `_numHousesToFill > count _filteredHouses` (loop drena o array antes de terminar).

### Callers auditados (risco de array vazio)

- `generateCivilians.sqf:217` — **GUARDED** (fix aplicado neste hotfix)
- `generateAOLocation.sqf:18` — **SAFE** — já tem `if (_randRoad isEqualType objNull)` após a chamada
- `generateAOLocation.sqf:48` — **SAFE** — mesmo guard acima
- `destroyCommsTower.sqf:49` — **SAFE** — `if (count _objects == 0) exitWith {}` antes da chamada
- `revealIntel.sqf:11` — **SAFE** — loop limitado a 40% de `taskIntel`, não drena totalmente
- `generateEnemies.sqf:40` — **SAFE** — `_numGarrisons` é bounded por `min (count buildings)`
- `generateAO.sqf:61` — **SAFE** — loop limitado por `[1, count _secondaryLocList]`
- `generateAO.sqf:25,35` — **NEEDS GUARD** (baixo risco, não crítico) — while loop sem bound drena `_firstLocList`; se todas as locations estiverem na borda do mapa, poderia esvaziar. `getPos objNull` na condição while falharia. Na prática Livonia tem muitas locations interiores.
- `reinforce.sqf:115` — **NEEDS GUARD** — `_vehType = [enemyGVPool] call DRO_fnc_selectRemove;` sem nenhum guard; `createVehicle [objNull,...]` falharia se pool esvaziar
- `reinforce.sqf:155` — **NEEDS GUARD** — tem `if (!isNil "_vehType")` mas esse guard não captura `objNull` (variável existe, não é nil). Pool pode esvaziar em missões longas com muitos reinforcements.
- `reinforce.sqf:194` — **NEEDS GUARD** — `_vehType = [enemyHeliPool] call DRO_fnc_selectRemove;` sem guard; risco igual ao GVPool
- `objGrouping.sqf:447,456,460` — **SAFE** — `_stringIntros` tem 4 elementos, chamado no máximo 3 vezes

### Callers que esperam tipo não-objeto

- `start.sqf:295` — espera `string` (callsign) — **OK** — `callsigns` é array grande de config, não drena
- `generateFriendlies.sqf:105,354` — espera `string` (callsign) — **OK em partidas normais** — `callsigns` é compartilhado; em partidas com muitos jogadores poderia drenar, mas o array é grande o suficiente na prática
- `hvt.sqf:18` — espera `string` (codename) — **OK** — `hvtCodenames` é array grande, uma chamada por objetivo
- `hvtInterrogate.sqf:15` — espera `string` (codename) — **OK** — mesmo acima
- `objGrouping.sqf:447,456,460` — espera `string` (intro) — **OK** — 4 entradas, max 3 chamadas
- `fortify.sqf:46`, `setupPlayersFaction.sqf:656,949` — esperam `string` via `FOBNames` — **OK** — FOBNames é array de config

---

## Smoke test pós-M3 hotfix #3 — 2026-05-19

**Resultado:** ciclo completo de missão (init → objetivos via Zeus → extract). 1 erro + 1 bug de gameplay.

### Bug #1 — selectReactiveTask.sqf:169 — `sleep` em unscheduled context

**Sintoma:** `Error Suspending not allowed in this context` ao completar objetivo de cache (destroy).

**Causa:** `selectReactiveTask.sqf` (= `DRO_fnc_selectReactiveObjective`) contém `sleep 5` na linha 169, mas é chamado via `call` (unscheduled) em `addTaskExtras.sqf:26,43,82`. `sleep` requer scheduled context.

**Antes do M3:** era `compile preprocessFile` e também chamado via `call` — bug latente, provavelmente nunca disparava se algum path anterior usava `spawn`/`execVM`.

**Fix necessário:** trocar `sleep 5; [...] spawn DRO_fnc_sendProgressMessage;` por `[{ [...] spawn DRO_fnc_sendProgressMessage; }, [], 5] call CBA_fnc_waitAndExecute;` — mantém o delay de 5s sem precisar de scheduled context.

**Status:** ✅ DONE — hotfix #4 abaixo.

---

## M3 hotfix #4 — selectReactiveTask sleep em unscheduled context — 2026-05-19

### Sintoma
`Error Suspending not allowed in this context` ao completar objetivo de cache (destroy).

### Fix aplicado
`selectReactiveTask.sqf:169-170` — `sleep 5` + spawn trocados por `CBA_fnc_waitAndExecute` com delay 5s. `_radioDesc` passado via args para o escopo do callback.

### Verificação
- Não há outros `sleep` no arquivo (confirmado).

### Bug #2 (gameplay, não erro de código) — HVT spawn fora do mapa

**Sintoma:** missões de "eliminar HVT" — o grupo do HVT spawna fora da área jogável do mapa, sem waypoints. Ficam parados.

**Possíveis causas:** lógica de posicionamento em `hvt.sqf` ou na geração de posição do reactive task em `selectReactiveTask.sqf` (linhas que calculam `_sizeLarge = _sizeSmall * 1.5` — o multiplicador pode jogar a posição pra fora dos limites do terreno).

**Status:** ⬜ PENDENTE — investigar em módulo futuro. Não é bug de refactor, é bug de gameplay preexistente.

---

## Fase 4 — Enemy Spawn Optimization (2026-05-19)

**Objetivo:** Reduzir frame hitches durante spawn de inimigos via Dynamic Simulation centralizado, frame budgeting em loops, setGroupId para debugging e audit de skill.

---

### 1. Dynamic Simulation — `functions/fn_spawnGroupWeighted.sqf`

**Status: JÁ IMPLEMENTADO antes desta fase.**

Linhas 51-53 já continham:
```sqf
if (_addToDyn && dynamicSim == 0) then {
    _group enableDynamicSimulation true;
};
```

A lógica está correta:
- `dynamicSim == 0` → sistema LIGADO pelo jogador (default) → aplica `enableDynamicSimulation true`
- `dynamicSim == 1` → sistema DESLIGADO pelo jogador → não aplica
- Parâmetro `_addToDyn` (default `true`) permite call-sites desativar pontualmente

**Cobertura:** ~74 call sites passam por esta função, incluindo todos os geradores (generateBunker, generateRoadblock, generateBarrier, generateEmplacement, generateEnemies).

**`fn_spawnEnemyGarrison.sqf`:** Todos os grupos passam por `DRO_fnc_spawnGroupWeighted` (linha 16). As unidades são movidas para o grupo líder via `joinSilent`, mas o grupo líder já recebeu `enableDynamicSimulation true` no momento da criação. ✅ Coberto.

**`fn_spawnEnemyCompound.sqf`:** Arquivo **não existe**. A referência em `start.sqf` linha 99 está comentada (`// [M3 removed]`). `generateCompound.sqf` em `sunday_system/generate_enemies/` é apenas um script de debug que desenha marcadores de bounding box — não spawna inimigos.

---

### 2. setGroupId para debugging — `functions/fn_spawnGroupWeighted.sqf`

**Mudança aplicada** (linha adicionada após `enableDynamicSimulation`, antes de `deleteGroup _tempGroup`):

```sqf
_group setGroupIdGlobal [format ["DRO_enemy_%1", floor random 10000]]; // debug tracking
```

IDs no formato `DRO_enemy_XXXX` aparecem no `.rpt` e no editor de missões, facilitando rastreamento de grupos durante debugging.

---

### 3. Frame Budgeting — `sunday_system/generate_enemies/generateEnemies.sqf`

**Contexto de execução verificado:** `generateEnemies.sqf` é chamado **exclusivamente via `execVM`** em `start.sqf` (linhas 1104 e 1106):
```sqf
_enemyScripts pushBack ([_forEachIndex, "SMALL"] execVM "sunday_system\generate_enemies\generateEnemies.sqf");
_enemyScripts pushBack ([0, "REGULAR"] execVM "sunday_system\generate_enemies\generateEnemies.sqf");
```
→ **Scheduled context confirmado** ✅ — `uiSleep 0` é seguro.

**7 pontos de `uiSleep 0` adicionados:**

| Linha | Loop | Propósito |
|-------|------|-----------|
| 28 | `forEach milBuildings` | Yield entre garrison spawns de milBuildings (pode ser grande) |
| 43 | `for "_g" from 1 to _numGarrisons` | Yield entre garrison spawns do AO |
| 77 | `for "_infIndex" from 1 to _numInf` | Yield entre spawns de patrulha de infantaria |
| 172 | `for "_x" from 1 to _numRoadblocks` | Yield entre spawns de roadblock |
| 182 | `for "_x" from 1 to _numBunkers` | Yield entre spawns de bunker |
| 211 | `for "_x" from 1 to _numCamps` (inside forEach) | Yield entre spawns de camp |
| 221 | `for "_x" from 1 to _numEmplacements` | Yield entre spawns de emplacement |

---

### 4. Frame Budgeting — Generate*.sqf individuais — NÃO APLICADO

**Motivo:** Todos os generate*.sqf individuais (generateBunker, generateRoadblock, generateBarrier, generateEmplacement) são chamados via **`call DRO_fnc_*`** de dentro de `generateEnemies.sqf`. Embora na prática sejam executados em scheduled context (herdado do execVM pai), as rules do projeto proíbem `uiSleep`/`sleep` em scripts chamados via `call`.

Além disso, como CfgFunctions, podem tecnicamente ser chamados de qualquer contexto — incluindo unscheduled — em extensões futuras. Manter sem sleep é a opção segura.

**Alternativa se necessário no futuro:** Converter as chamadas `call DRO_fnc_generateBunker` em `spawn DRO_fnc_generateBunker` dentro de `generateEnemies.sqf`, tornando cada gerador explicitamente scheduled e permitindo sleep interno.

---

### 5. `staggeredAttack.sqf` — sem mudanças

**Contexto:** Chamado exclusivamente via `execVM` em `createExtractTask.sqf` (linhas 74, 121, 191, 267) → scheduled ✅

O `sleep _delay` existente (linha 26) é **intencional** — é o delay entre ataques escalonados, não um frame yield acidental. Não requer frame budgeting adicional pois o loop apenas envia grupos para atacar (sem spawn pesado).

---

### 6. Skill Audit

**Resultados:**

- `setSkill` nos geradores (`generate*.sqf`): **Nenhum encontrado.** ✅
- `DRO_fnc_setSkillAction` (`functions/fn_setSkillAction.sqf`): **Sem cap explícito**, mas os valores máximos definidos em todos os casos são bem abaixo de 0.8:

| Skill | Case 0 (max) | Case 1 (max) |
|-------|-------------|-------------|
| aimingAccuracy | 0.1 | 0.2 |
| aimingShake | 0.05 | 0.1 |
| aimingSpeed | 0.16 | 0.2 |
| spotDistance | 0.4 | 0.5 |
| spotTime | 0.5 | 0.5 |
| general | **0.4** | **0.6** |
| courage | 0.3 | 0.4 |
| reloadSpeed | 0.2 | 0.25 |

Nenhum valor excede 0.8. **Cap não é necessário.** A decisão de adicionar cap de skill fica documentada como desnecessária no estado atual.

---

### 7. Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `functions/fn_spawnGroupWeighted.sqf` | Adicionado `setGroupIdGlobal` para debug tracking |
| `sunday_system/generate_enemies/generateEnemies.sqf` | Adicionados 7× `uiSleep 0` em loops de spawn |

### Arquivos Auditados Sem Mudança

| Arquivo | Resultado |
|---------|-----------|
| `functions/fn_spawnGroupWeighted.sqf` | dynamicSim já implementado ✅ |
| `functions/fn_spawnEnemyGarrison.sqf` | Coberto por spawnGroupWeighted ✅ |
| `functions/fn_setSkillAction.sqf` | Sem skill > 0.8 ✅ |
| `sunday_system/generate_enemies/generateBunker.sqf` | call-context: sleep NÃO aplicado |
| `sunday_system/generate_enemies/generateRoadblock.sqf` | call-context: sleep NÃO aplicado |
| `sunday_system/generate_enemies/generateBarrier.sqf` | call-context: sleep NÃO aplicado |
| `sunday_system/generate_enemies/generateEmplacement.sqf` | call-context: sleep NÃO aplicado |
| `sunday_system/generate_enemies/staggeredAttack.sqf` | sleep intencional, sem mudança |
| `sunday_system/generate_enemies/generateCompound.sqf` | Debug-only (sem spawn), sem mudança |


---

## M5 — start.sqf decomposition — 2026-05-20

**Objetivo:** Decompor o `start.sqf` monolítico (1352 linhas) em 7 funções separadas para reduzir tamanho e melhorar legibilidade. Apenas reorganização — sem mudança de comportamento.

**Resultado:** `start.sqf` passou de **1352 → 939 linhas** (redução de 413 linhas / 30%).

---

### Funções extraídas

| Função | Arquivo | Linhas do fn_*.sqf | Linhas removidas do start.sqf |
|---|---|---|---|
| `DRO_fnc_extractFactionData` | `functions/fn_extractFactionData.sqf` | 109 | 99 |
| `DRO_fnc_setupEnemySides` | `functions/fn_setupEnemySides.sqf` | 51 | 40 |
| `DRO_fnc_defineMarkerColors` | `functions/fn_defineMarkerColors.sqf` | 47 | 39 |
| `DRO_fnc_chooseMissionMusic` | `functions/fn_chooseMissionMusic.sqf` | 89 | 79 |
| `DRO_fnc_generatePlayerIdentities` | `functions/fn_generatePlayerIdentities.sqf` | 123 | 106 |
| `DRO_fnc_chooseObjectivesPOWClass` | `functions/fn_chooseObjectivesPOWClass.sqf` | 64 | 52 |
| `DRO_fnc_setupReinforcementTrigger` | `functions/fn_setupReinforcementTrigger.sqf` | 25 | 12 |

**Total extraído: 427 linhas de body + 81 linhas de header/doc = 508 linhas em 7 novos arquivos.**

---

### Globals / variáveis locais — análise

**`fn_extractFactionData`**
- Globals setadas: `availableFactionsData`, `availableFactionsDataNoInf` (ambas publicVariable), `factionDataReady` (via missionNameSpace setVariable)
- Locais contidas dentro: `_availableFactions`, `_unavailableFactions`, `_factionsWithNoInf`, `_factionsWithUnitsFiltered` — usadas apenas internamente ✅

**`fn_setupEnemySides`**
- Globals setadas: `enemySide` (publicVariable)
- Globals lidas: `enemyFaction`, `enemyFactionAdv`, `playersSide`
- Nota: `enemyFactionName` (linha 512 do start.sqf original) permaneceu em start.sqf — não é responsabilidade desta função
- Locais contidas: `_enemySideNum`, `_enemySides`, `_thisSide` ✅
- Nota sobre `sleep 0.01`: mantido conforme original; seguro pois esta função é chamada exclusivamente de start.sqf (scheduled context via execVM)

**`fn_defineMarkerColors`**
- Globals setadas: `markerColorPlayers` (publicVariable), `markerColorEnemy` (publicVariable), `colorPlayers`, `colorEnemy`
- Globals lidas: `playersSide`, `enemySide`
- Nota: `colorPlayers` e `colorEnemy` NÃO têm publicVariable no código original — comportamento preservado ✅

**`fn_chooseMissionMusic`**
- Globals setadas: `musicMain`, `musicExtract`, `musicMainVNHeli`, `musicVNExtract`
- Globals lidas: `timeOfDay`, `worldName`
- Locais contidas: todos os `_musicArray*` — não usados após a função ✅
- `FOBNames` (linha seguinte no start.sqf) ficou em start.sqf — não é parte desta função ✅

**`fn_generatePlayerIdentities`**
- Globals setadas: `nameLookup` (publicVariable), `pFacesArray`, `eFacesArray`, `initArsenal` (publicVariable)
- Globals lidas: `pGenericNames`, `pIdentityTypes`, `eIdentityTypes`, `playersSide`, `playerGroup`
- Locais contidas: `_speakersArray`, `_firstNames`, `_lastNames`, `_firstName`, `_lastName`, `_speaker`, `_face` — mantidos locais conforme instrução ✅

**`fn_chooseObjectivesPOWClass`**
- Globals setadas: `powClass`, `powType`, `UXOUsed`
- Globals lidas: `pInfClasses`
- `powJoinTasks = []` permaneceu em start.sqf (inicialização separada, não é responsabilidade desta função) ✅
- Locais contidas: `_soldierType`, `_heliCrewClasses`, `_engineerClasses` ✅

**`fn_setupReinforcementTrigger`**
- Globals setadas: nenhuma — trigger é objeto local
- Globals lidas: `AOLocations`, `centerPos`, `enemySide`, `enemyCommsActive`, `stealthActive`, `grpNetId`
- `_trgReinf` é local dentro da função ✅

---

### Arquivos modificados

- **`description.ext`** — 7 novas classes adicionadas em `class core` (bloco `// M5 — start.sqf decomposition`)
- **`start.sqf`** — 7 blocos substituídos por `call DRO_fnc_*` comentados
- **`init.sqf`** — NÃO modificado (funções novas, sem aliases legados)

### Posições das chamadas no start.sqf pós-patch

| Linha | Chamada |
|---|---|
| 116 | `call DRO_fnc_extractFactionData;` |
| 417 | `call DRO_fnc_setupEnemySides;` |
| 420 | `call DRO_fnc_defineMarkerColors;` |
| 497 | `call DRO_fnc_chooseMissionMusic;` |
| 510 | `call DRO_fnc_generatePlayerIdentities;` |
| 542 | `call DRO_fnc_chooseObjectivesPOWClass;` |
| 898 | `call DRO_fnc_setupReinforcementTrigger;` |

### Restrições verificadas

- ✅ Nenhum código marcado `// Migrated from ...` foi tocado
- ✅ Ordem de execução preservada (calls nas posições exatas dos blocos originais)
- ✅ Sem aliases em `init.sqf`
- ✅ Sem `#define` macros necessários nessas seções (nenhuma usa macros do topo do start.sqf)
- ✅ Variáveis locais que só eram usadas dentro da seção continuam locais nas funções
- ✅ `sleep 0.01` em `fn_setupEnemySides` preservado; seguro pois só chamado de scheduled context

### Pontos de atenção para testes

1. **Boot da missão** — verificar no .rpt que as 7 novas funções são compiladas sem erro (sem `Undefined variable` ou `Missing )`)
2. **`fn_generatePlayerIdentities`** — usa `remoteExec ["DRO_fnc_setNameMP", 0, true]` (JIP=true). Se a missão usar `CfgRemoteExec` em modo strict, confirmar que `DRO_fnc_setNameMP` já está na whitelist (era `remoteExec` antes do M3, deve já estar)
3. **`fn_setupEnemySides`** — `sleep 0.01` requer scheduled context; confirmado que start.sqf roda via execVM ✅
4. **`fn_chooseObjectivesPOWClass`** — `UXOUsed = false` migrou para dentro da função (estava na linha seguinte a `powType = ""`). Sem impacto funcional — era inicializado antes de qualquer uso.
5. **`fn_extractFactionData`** — seção mais pesada (configClasses loop). Medir tempo via `diag_log` se necessário; o `_scriptStartTime` de `start.sqf` já mede o bloco subsequente (defineFactionClasses).

### Nota sobre meta de linhas

A meta era 400–700 linhas. Com as 7 extrações desta fase, start.sqf chegou a **939 linhas**. As 939 linhas restantes incluem: seções de AO setup, lobby/player setup (~100 linhas de lógica de loadout), geração de objetivos, civilian setup, enemy generation, weather, briefing, sequencing — cada qual candidata a extração futura se a meta de 400–700 for necessária.

---

## M6 — Final Audit, Dead Code Cleanup e Bug Fixes — 2026-05-20

**Objetivo:** Auditoria de integridade final, correção de bugs pendentes, cleanup de dead code. Último módulo do refactor.

---

### PARTE 1 — Verificações de integridade

#### 1.1. EH handlers do revive — ✅ OK

`functions/fn_addReviveToUnit.sqf` usa `DRO_fnc_handleDamage` e `DRO_fnc_handleKilled` em **todos** os pontos de adição:
- Linha 15: `remoteExec ["addEventHandler", _unit, true]` via array `["HandleDamage", DRO_fnc_handleDamage]`
- Linha 16: idem para `["Killed", DRO_fnc_handleKilled]`
- Linha 42–43: `_newUnit addEventHandler ["HandleDamage", DRO_fnc_handleDamage]` e `["Killed", DRO_fnc_handleKilled]` (dentro do callback Respawn)
- Linhas 53–54: branch SP (singleplayer)

Nenhuma referência aos nomes legados `rev_handleDamage` / `rev_handleKilled`. ✅

#### 1.2. briefingJIP — ✅ OK

`briefing.sqf` linha 132: `//[_briefingString] remoteExec ["DRO_fnc_briefingJIP", 0, true];` — **comentada** ✅

Path JIP ativo (linha 135):
```sqf
[briefingString, {player createDiaryRecord ["Diary", ["Briefing", _this]]}] remoteExec ["call", 0, true];
```
Não usa `DRO_fnc_briefingJIP` nem o alias `sun_briefingJIP`. O alias existe em `init.sqf` como retrocompatibilidade mas não é necessário para o path ativo. JIP funciona via `remoteExec ["call", ...]` que já inclui `briefingString` publicado. ✅

#### 1.3. CfgRemoteExec — ✅ AUSENTE (default)

`description.ext` não contém `class CfgRemoteExec`. A missão usa o **default do engine** (tudo permitido). Nenhuma whitelist necessária. As funções `DRO_fnc_setNameMP`, `DRO_fnc_randomTime`, `DRO_fnc_briefingJIP`, `DRO_fnc_changeLocal`, `DRO_fnc_civDeathHandler` podem ser chamadas via `remoteExec` sem restrição. ✅

Se CfgRemoteExec for adicionado futuramente em modo strict (`mode = 2`), adicionar essas 5 funções à whitelist conforme flagado no M3.

#### 1.4. Macros em fn_*.sqf — ✅ OK

Grep de `aliveVeh(` em `functions/`:
- `fn_checkVehicleSpawn.sqf:8` — tem `#define aliveVeh` na linha 4 ✅
- `fn_helicopterCanFly.sqf:8` — tem `#define aliveVeh` na linha 4 ✅

M5 (7 novas funções extraídas de start.sqf): grep de `#define` retornou vazio — nenhuma das 7 usa macros. ✅

Nenhum outro `#define` ou macro customizado encontrado em nenhum `fn_*.sqf`. ✅

#### 1.5. Latent bug fn_checkVehicleSpawn.sqf — ✅ CORRIGIDO

**Problema:** `_vehicleType` não estava nos params (era variável de escopo herdada via `#include` no original). Com CfgFunctions, o arquivo compila isolado — `_vehicleType` ficava undefined, gerando erro silencioso no path de recreate.

**Fix aplicado** (`functions/fn_checkVehicleSpawn.sqf`):
```sqf
params [["_vehicle", objNull], ["_vehicleType", ""]];
```
Adicionado também guard antes do recreate:
```sqf
if (_vehicleType isEqualTo "") exitWith { _vehicle = objNull };
```

**Contexto:** nenhum dos 7 callers ativos (`artillery.sqf`, `cache.sqf`, `cacheBuilding.sqf`, `heli.sqf`, `vehicle.sqf`, `vehicleSteal.sqf`, `searchHouses.sqf`) passa `_vehicleType` — todos chamam `[_vehicle] call DRO_fnc_checkVehicleSpawn`. O path de recreate é portanto **dead path na prática** (nenhum caller fornece o tipo). O guard formaliza isso: se `_vehicleType` for vazio (default), a função retorna `objNull` em vez de travar com undefined variable. O comportamento observável é idêntico ao anterior (callers já tratavam `objNull` de retorno).

#### 1.6. Guards de DRO_fnc_spawnGroupWeighted — ✅ CORRIGIDO (críticos)

**Contexto:** `DRO_fnc_spawnGroupWeighted` retorna `nil` se `_pos` for array vazio, e pode retornar `grpNull` em falha de `createGroup`. O guard `if (!isNil "_group")` não captura `grpNull`.

**Call sites auditados e corrigidos:**

| Arquivo | Linha | Guard anterior | Guard corrigido | Status |
|---------|-------|---------------|-----------------|--------|
| `fn_spawnEnemyGarrison.sqf` | 16 | `!isNil && !isNull && count > 0` | — | ✅ já corrigido (M3 hotfix #2) |
| `fn_localBuildingPatrol.sqf` | 14, 26 | `!isNil` | `!isNil && !isNull` | ✅ corrigido M6 |
| `fn_triggerAmbushSpawn.sqf` | 24 | `waitUntil {!isNil}` + nenhum | Guard direto `isNil \|\| isNull → exitWith` | ✅ corrigido M6 |
| `reinforce.sqf` | 81 | `!isNil` | `!isNil && !isNull` | ✅ corrigido M6 |
| `reinforce.sqf` | 123 | `!isNil` | `!isNil && !isNull` | ✅ corrigido M6 |
| `reinforce.sqf` | 203 | `!isNil` | `!isNil && !isNull` | ✅ corrigido M6 |

**Call sites restantes auditados (risco aceitável, não corrigidos):**

Os demais call sites nos arquivos `generate*.sqf`, `objectives/*.sqf`, `generateFriendlies.sqf` e `selectReactiveTask.sqf` seguem o padrão: após `_spawnedSquad = [...] call DRO_fnc_spawnGroupWeighted`, usam o grupo para waypoints, behaviorSet ou joinSilent sem guard explícito. Analisando o retorno real da função:
- `grpNull` só ocorre se `createGroup` falhar (limite de grupos do engine, extremamente raro)
- `nil` só ocorre se `_pos` for array vazio (mas todos esses call sites calculam `_pos` via `BIS_fnc_findSafePos` ou posições de editor, que raramente retornam `[]`)
- Operações como `_group setBehaviour`, `addWaypoint [_group, ...]`, `units grpNull` (retorna `[]`) são seguras ou falham silenciosamente

Estes call sites foram marcados como **NOTED** — risco baixo, não crítico para gameplay. Podem ser hardened em manutenção futura se necessário.

#### 1.7. Guards de DRO_fnc_selectRemove em reinforce.sqf — ✅ CORRIGIDO

Três call sites corrigidos:

**Linha ~115 (CARTRANSPORT — `enemyGVPool`):**
```sqf
_vehType = [enemyGVPool] call DRO_fnc_selectRemove;
// M6: selectRemove retorna objNull se pool vazio; guard antes de createVehicle.
if (isNull _vehType) exitWith {};
_reinfVeh = createVehicle [_vehType, _spawnPos, [], 0, "NONE"];
```
Antes: sem guard → `createVehicle [objNull, ...]` falhava se pool esvaziar.

**Linha ~155 (CAR — `enemyGVTPool`):**
```sqf
if (!isNil "_vehType" && {!isNull _vehType}) then {
```
Antes: `if (!isNil "_vehType")` — não capturava `objNull`.

**Linha ~194 (HELI — `enemyHeliPool`):**
```sqf
_vehType = [enemyHeliPool] call DRO_fnc_selectRemove;
// M6: selectRemove retorna objNull se pool vazio; guard antes de createVehicle.
if (isNull _vehType) exitWith {};
_reinfVeh = createVehicle [_vehType, _spawnPos, [], 0, "FLY"];
```
Antes: sem guard → `createVehicle [objNull, ...]` falhava se pool esvaziar.

**`generateAO.sqf:25,35`** — auditado, risco baixo (Livonia tem muitas locations interiores, loop raramente drena). **NOTED**, não corrigido.

---

### PARTE 2 — Audit de antipadrões

#### 2.1. Antipadrões remanescentes — ✅ LIMPO

**`while {true}` ativo:**
- `sunday_revive/AIReviveListen.sqf:12` — dead code, arquivado em M6 (ver Parte 3). Nunca executado.
- Todos os demais matches (`fn_newUnits.sqf`, `initPlayerLocal.sqf`, `initRevive.sqf`, `messageListener.sqf`, `teamRespawnPos.sqf`) são **comentários de migração** (`// Migrated from ...`). ✅

**`spawn { ... sleep ... }` ativo:**
- `disarmIED.sqf:104`: `[(getVariable 'IED')] spawn {sleep (random[0, 2, 3]); setDamage 1;}` dentro de string de `setTriggerStatements`. Contexto: trigger statements executam em scheduled context → `spawn + sleep` é correto e intencional aqui. ✅
- Todos os demais matches são **comentários de migração**. ✅

**`waitUntil { sleep }` ativo:**
- `fn_sendProgressMessage.sqf:6` — dentro de bloco `/* ... */`. Comentado. ✅
- Demais matches são comentários de migração. ✅

**Resultado:** zero antipadrões em código ativo. ✅

#### 2.2. PFH guards (double-init) — ✅ TODOS GUARDADOS

| PFH | Arquivo | Guard | Status |
|-----|---------|-------|--------|
| `DRO_c2GrpNetIdGuardPFH` | `fn_newUnits.sqf` | `if (isNil "DRO_c2GrpNetIdGuardPFH") then {` | ✅ |
| `DRO_loadoutSaverPFH` | `initPlayerLocal.sqf` | `if (isNil "DRO_loadoutSaverPFH") then {` | ✅ |
| `DRO_taskWatcherPFH` | `start.sqf` | Sem guard explícito — start.sqf é execVM server-only, roda uma vez. Re-criação na linha 934 é intencional (stability recheck falhou, reinicia o watcher). | ✅ |
| `DRO_aiReviveListenPFH` | `initRevive.sqf` | `if (isNil "DRO_aiReviveListenPFH") then {` | ✅ |
| `DRO_messageListenerPFH` | `messageListener.sqf` | `if (!isNil "DRO_messageListenerPFH") exitWith {` | ✅ |
| `DRO_teamRespawnPosPFH` | `teamRespawnPos.sqf` | `if (!isNil "DRO_teamRespawnPosPFH") exitWith {` | ✅ |

#### 2.3. removePerFrameHandler em PFHs — ✅ SEM LEAKS

Todos os PFHs com `_pfhId` têm `CBA_fnc_removePerFrameHandler` no body. Os PFHs "forever" (sem exit condition) são por design contínuos e não requerem remoção. Nenhum leak identificado. ✅

---

### PARTE 3 — Dead code cleanup

#### 3.1. Arquivamento — ✅ CONCLUÍDO

**`sunday_revive/AIReviveListen.sqf`**
- Cópia arquivada em `_archive/AIReviveListen.sqf` com header:
  ```sqf
  // ARCHIVED — não está em uso. Movido em 2026-05-20 durante M6 final audit.
  ```
- Original mantido no local (shell não tem permissão de `rm` no workspace do usuário). Original já tinha header `// DEPRECATED` da Fase 1. Dead code confirmado — única referência (`initRevive.sqf:120`) está comentada.

**`sunday_system/supports/supportCASHeliOld.sqf`**
- Cópia arquivada em `_archive/supportCASHeliOld.sqf` com header ARCHIVED.
- Original mantido com header adicionado:
  ```sqf
  // ARCHIVED — não está em uso. Cópia em _archive/supportCASHeliOld.sqf (M6 final audit, 2026-05-20).
  ```
- Dead code confirmado — sem callers ativos.

#### 3.2. Lib stubs — ✅ MANTIDOS

Os 5 stubs de deprecação (`sundayFunctions.sqf`, `droFunctions.sqf`, `menuFunctions.sqf`, `reviveFunctions.sqf`, `generateEnemiesFunctions.sqf`) foram mantidos sem modificação. São documentação viva do que existia nesses arquivos e não causam efeito runtime.

#### 3.3. Aliases em init.sqf — ✅ HEADER ADICIONADO

Substituído o header antigo (que mencionava "Remove in M4") pelo header permanente conforme especificação:
```sqf
// =====================================================================
// LEGACY ALIASES — mantidos para retrocompatibilidade com eventuais
// scripts externos ou mods que referenciem os nomes antigos (sun_*,
// dro_*, rev_*, fnc_*, chz_*). Todas as funções reais estão em
// CfgFunctions como DRO_fnc_*. Remover estes aliases somente após
// confirmar que nenhum código externo depende dos nomes legados.
// Criados no M3 (CfgFunctions migration) — 2026-05-17
// =====================================================================
```
Os 110 aliases foram mantidos intactos.

---

### PARTE 4 — Bug fn_changeLocal EH leak — NOTED

**Problema:** `fn_changeLocal` adiciona um novo `addEventHandler ["Respawn", ...]` via `remoteExec ["addEventHandler", _unit, true]` na máquina dona da unidade cada vez que a localidade muda, sem remover o anterior. N mudanças de localidade = N Respawn EHs acumulados naquela máquina.

**Análise de locality:**

A abordagem de tracking via `DRO_revRespawnHandlerId` (recomendada no task spec) esbarra em um problema de **IDs locais por máquina**:

- O EH é adicionado via `remoteExec` na máquina dona atual. O ID retornado é local a essa máquina.
- A variável `setVariable [..., true]` é broadcast global — todas as máquinas leem o mesmo valor.
- Quando a localidade muda para a Máquina B, ela lê o ID que a Máquina A escreveu. Tentar `removeEventHandler` com esse ID na Máquina B pode:
  - Não fazer nada (ID não existe na Máquina B) → EH da Máquina A nunca é removido
  - Remover o EH errado (se a Máquina B coincidentemente tem um EH com o mesmo ID numérico mas de outro tipo)
  - Potencialmente remover o Respawn EH adicionado por `fn_addReviveToUnit` se os IDs coincidirem

**Fix correto (futuro):** usar uma variável por máquina, como `DRO_revRespawnHandlerId_` + `str netId thisMachine` ou `DRO_revRespawnHandlerId_` + `str ([] call BIS_fnc_netId)`. Isso garante que cada máquina leia e sobrescreva apenas o seu próprio ID.

**Por que não corrigir agora:**
1. Requer criar uma variável de nome dinâmico por máquina — mais invasivo
2. O "Local" EH que dispara `fn_changeLocal` é adicionado no servidor (`remoteExec ["addEventHandler", 0, true]`), mas executa no servidor, não na máquina que ganhou localidade — a lógica de qual máquina executa o que precisa ser re-verificada com testes
3. O bug só manifesta com muitas mudanças de localidade de AIs (cenário relativamente raro em DRO)
4. O risco de introduzir uma regressão (remover o EH errado) é maior que o risco de deixar o leak

**Status: NOTED — deixado para manutenção futura.**

---

### PARTE 5 — Cleanup de TODO/FIXME — ✅ LIMPO

```bash
grep -rnE "TODO|FIXME|XXX|HACK" --include="*.sqf" | grep -v "_archive"
```
**Zero matches.** O codebase está completamente livre de TODO/FIXME/XXX/HACK em arquivos `.sqf` ativos. ✅

---

### Arquivos modificados no M6

| Arquivo | Mudança |
|---------|---------|
| `functions/fn_checkVehicleSpawn.sqf` | Fix 1.5: `_vehicleType` adicionado aos params; guard para vehicleType vazio |
| `functions/fn_localBuildingPatrol.sqf` | Fix 1.6: guard de grpNull reforçado (`!isNil && !isNull`) |
| `functions/fn_triggerAmbushSpawn.sqf` | Fix 1.6: `waitUntil` substituído por guard direto `isNil \|\| isNull → exitWith` |
| `sunday_system/reinforce.sqf` | Fix 1.6+1.7: 3× guards de spawnGroupWeighted reforçados; 2× guards de selectRemove adicionados (GVPool, HeliPool); 1× guard de selectRemove reforçado (GVTPool) |
| `init.sqf` | Fix 3.3: header de aliases substituído pelo header permanente |
| `sunday_system/supports/supportCASHeliOld.sqf` | Fix 3.1: header ARCHIVED adicionado |
| `_archive/AIReviveListen.sqf` | Criado: cópia arquivada com header ARCHIVED |
| `_archive/supportCASHeliOld.sqf` | Criado: cópia arquivada com header ARCHIVED |

### Arquivos auditados sem modificação

| Arquivo | Resultado |
|---------|-----------|
| `functions/fn_addReviveToUnit.sqf` | EH names corretos ✅ |
| `briefing.sqf` | briefingJIP comentado, path ativo correto ✅ |
| `description.ext` | Sem CfgRemoteExec — default ✅ |
| `functions/fn_helicopterCanFly.sqf` | `#define aliveVeh` presente ✅ |
| `functions/fn_changeLocal.sqf` | EH leak documentado como NOTED — não corrigido |
| `sunday_revive/AIReviveListen.sqf` | Dead code — arquivado |
| `sunday_system/messageListener.sqf` | PFH com guard ✅ |
| `sunday_system/player_setup/teamRespawnPos.sqf` | PFH com guard ✅ |
| `sunday_revive/initRevive.sqf` | PFH com guard ✅ |
| `sunday_system/objectives_neutral/disarmIED.sqf:104` | `spawn {sleep}` em trigger statement — intencional ✅ |
| `functions/fn_sendProgressMessage.sqf` | `waitUntil {sleep}` dentro de `/* */` — comentado ✅ |
| Todos fn_*.sqf de M5 | Sem macros ✅ |

### Pontos de atenção para testes

1. **`fn_checkVehicleSpawn`** — path de recreate agora retorna `objNull` (via `exitWith`) quando `_vehicleType` é vazio. Callers já testavam `objNull` como retorno — sem impacto funcional.
2. **`fn_triggerAmbushSpawn`** — `waitUntil` removido (era no-op síncrono). Verificar que ambushes ainda disparam corretamente.
3. **`reinforce.sqf`** — os 3 `exitWith` nos cases de reinforcement abortam o case atual sem interromper o loop principal (`for "_i" from 1 to _numReinforcements`). Verificar que missões longas com pools vazios não geram spam de reforços sem veículos.
4. **`fn_changeLocal` EH leak** — continua presente. Em testes, monitorar no .rpt se AI units com muitas trocas de localidade acumulam múltiplos Respawn handlers via `diag_log`.

### Status final do refactor

**Todas as 6 fases do refactor DRO ACE Livonia estão completas:**

| Fase | Descrição | Status |
|------|-----------|--------|
| Fase 1 | CBA migration (while→PFH, spawn→CBA_fnc_waitAndExecute) | ✅ |
| M2 | Bug fixes deferidos (vn_artillery, revive EH/action leak) | ✅ |
| M3 | CfgFunctions migration (67 funções, 695 call sites) + hotfixes #1–#4 | ✅ |
| M4 | AI gen hygiene (dynamicSim, setGroupId, frame budgeting, skill audit) | ✅ |
| M5 | start.sqf decomposition (7 funções, 1352→939 linhas) | ✅ |
| M6 | Final audit, dead code cleanup, bug fixes | ✅ |
| M7 | Smoke test pós-M6 — hotfixes | ✅ |

---

## M7 — Smoke test pós-M6 hotfixes — 2026-05-20

### Contexto

Smoke test após M6 revelou 2 bugs de runtime + 1 issue visual (heli extract menu ausente).

### Bug #1 — `_guardUnit` undefined em geradores de IA

**Sintoma:** `Undefined variable in expression: _guardunit` em `generateBunker.sqf:38,42` e `generateEmplacement.sqf:20,26`.

**Causa:** `DRO_fnc_spawnGroupWeighted` retornava `grpNull` (posição inválida ou limite de grupos). O guard `waitUntil {!isNil "_guardGroup"}` passava `grpNull` (não é nil). `(units grpNull) select 0` retornava nil, deixando `_guardUnit` undefined.

**Fix aplicado — 4 geradores corrigidos preventivamente:**

| Arquivo | Pontos corrigidos | Guard anterior | Guard novo |
|---------|-------------------|---------------|------------|
| `generateBunker.sqf` | 3 (forEach + 2 switch cases) | `waitUntil {!isNil}` / `if (!isNil)` | `isNil \|\| isNull \|\| count units == 0` → `continue` / skip |
| `generateEmplacement.sqf` | 1 (for loop) | `waitUntil {!isNil}` | `isNil \|\| isNull \|\| count units == 0` → `continue` |
| `generateRoadblock.sqf` | 1 (forEach) | `waitUntil {!isNil}` | `isNil \|\| isNull \|\| count units == 0` → `continue` |
| `generateBarrier.sqf` | 3 (guardTowers + 2 patrol spawns) | `if (!isNil)` | `!isNil && !isNull` (+ `count units > 0` no guardTowers) |

### Bug #2 — `isNull` em String no reinforce.sqf

**Sintoma:** `Error isnull: Type String, expected Object` em `reinforce.sqf:118` ao destruir objetivos.

**Causa:** O guard do M6 usava `if (isNull _vehType) exitWith {}`, mas os pools de veículos (`enemyGVPool`, `enemyGVTPool`, `enemyHeliPool`) contêm **strings** (classnames). `isNull` não aceita string — gera erro de tipo. `DRO_fnc_selectRemove` retorna `objNull` quando pool vazio, ou string quando tem elementos.

**Fix aplicado — 3 cases corrigidos:**

| Case | Pool | Guard anterior (M6) | Guard novo (M7) |
|------|------|---------------------|-----------------|
| CARTRANSPORT | `enemyGVPool` | `isNull _vehType` | `_vehType isEqualTo objNull \|\| _vehType isEqualTo ""` |
| CAR | `enemyGVTPool` | `!isNil && !isNull` | `!(_vehType isEqualTo objNull) && !(_vehType isEqualTo "")` |
| HELI | `enemyHeliPool` | `isNull _vehType` | `_vehType isEqualTo objNull \|\| _vehType isEqualTo ""` |

### Bug #3 — Heli extract menu ausente

**Sintoma:** Menu de suporte "Helicopter Extract" não apareceu no 0-0-X ao iniciar extração.

**Diagnóstico:** Adicionado `diag_log` em `createExtractTask.sqf` para capturar `pHeliClasses`, `_numPassengers`, `_heliTransports`, `extractHeliUsed`. No segundo smoke test (com bugs 1 e 2 corrigidos), o menu apareceu normalmente.

**Conclusão:** Efeito cascata dos erros nos geradores. Com os erros resolvidos, o flow de extração funcionou corretamente. `diag_log` diagnóstico mantido para futuros testes.

### Smoke test #2 (pós-fix geradores + reinforce)

Ciclo completo de missão (init → geração de objetivos → destruição de caches → extração com heli) rodou **sem erros de código DRO no .rpt**. Heli extract apareceu normalmente. Únicos erros observados foram do mod TFAR (`fnc_loadoutReplaceProcess.sqf` — bug interno do mod, não relacionado à missão).

---

### Bug #4 — Civis hostis spawnando com opção "enable" (sem hostile)

**Sintoma:** Civis hostis apareciam mesmo com `civiliansEnabled == 1` (enable, sem hostile).

**Causa:** Dois pontos setavam `hostileCivsEnabled` com 50% aleatório:
- `start.sqf:66` — `hostileCivsEnabled = if (random 1 > 0.5) then {true} else {false}` (pré-set antes da lógica de civis)
- `generateCivilians.sqf:26` — quando `civiliansEnabled == 1`, ainda tinha 50% de chance de habilitar hostis

**Fix aplicado:**
- `start.sqf:66` — `hostileCivsEnabled = false` (inicialização limpa, valor real definido em generateCivilians.sqf)
- `generateCivilians.sqf:26` — simplificado para `hostileCivsEnabled = (civiliansEnabled == 2)`. Opção 1 = sem hostis, opção 2 = com hostis.

### Bug #5 — Civis aglomerados em spawn points (dentro de prédios)

**Sintoma:** Múltiplos civis spawnando no mesmo ponto/prédio, visível no Zeus.

**Causas identificadas:**
1. Loop de casas (linhas 221-229) spawnava até 3 hostis por posição de building (loop `for` aninhado desnecessário)
2. Civis de área aberta usavam `selectRandom _civPositions` que podia repetir a mesma posição
3. Safe spot capacity hardcoded em 3 — cada ponto atraía até 3 civis do engine
4. Área do módulo principal `ModuleCivilianPresence_F` era `AOSize/2` — restringia a distribuição

**Fixes aplicados:**

| Mudança | Arquivo | Detalhe |
|---------|---------|---------|
| Max 1 hostil por building position | `generateCivilians.sqf:221-227` | Loop `for` removido, agora 50% chance de 1 civ por posição |
| Filtro de distância mínima 30m | `generateCivilians.sqf:250-265` | Posições embaralhadas e filtradas — posições a <30m são descartadas |
| Acesso sequencial (sem repetição) | `generateCivilians.sqf` (4 cases do switch) | `selectRandom` trocado por acesso indexado a posições filtradas |
| Safe spot capacity 3→1 | `generateCivilians.sqf:141-152` | `#capacity` agora usa parâmetro (default 1) em vez de hardcoded 3 |
| Área do módulo principal ampliada | `generateCivilians.sqf:411` | `AOSize/2` → `AOSize*0.75` (50% mais área de distribuição) |
| Guard contra _posCount==0 | `generateCivilians.sqf:269-271` | Evita `mod 0` (divisor zero) que matava o script inteiro |

### Smoke test #3 (final)

Missão completa sem erros. Civis spawnando espalhados. Hostis respeitando parâmetro. Extração funcionando.

### Arquivos modificados no M7

| Arquivo | Mudança |
|---------|---------|
| `sunday_system/generate_enemies/generateBunker.sqf` | Guard spawnGroupWeighted (3 pontos) |
| `sunday_system/generate_enemies/generateEmplacement.sqf` | Guard spawnGroupWeighted (1 ponto) |
| `sunday_system/generate_enemies/generateRoadblock.sqf` | Guard spawnGroupWeighted (1 ponto) |
| `sunday_system/generate_enemies/generateBarrier.sqf` | Guard spawnGroupWeighted (3 pontos) |
| `sunday_system/reinforce.sqf` | isNull→isEqualTo objNull (3 cases) |
| `start.sqf` | hostileCivsEnabled init = false |
| `sunday_system/civilians/generateCivilians.sqf` | Hostis fix + anti-aglomeração (6 mudanças) |

### Status final do projeto

| Fase | Descrição | Status |
|------|-----------|--------|
| Fase 1 | CBA migration (while→PFH, spawn→CBA_fnc_waitAndExecute) | ✅ |
| M2 | Bug fixes deferidos (vn_artillery, revive EH/action leak) | ✅ |
| M3 | CfgFunctions migration (67 funções, 695 call sites) + hotfixes #1–#4 | ✅ |
| M4 | AI gen hygiene (dynamicSim, setGroupId, frame budgeting, skill audit) | ✅ |
| M5 | start.sqf decomposition (7 funções, 1352→939 linhas) | ✅ |
| M6 | Final audit, dead code cleanup, bug fixes | ✅ |
| M7 | Smoke test hotfixes (geradores, reinforce, civis) | ✅ |

### Pendências conhecidas (não críticas)

- **`fn_changeLocal` EH leak** — NOTED no M6. Leak lento em cenário raro (AI trocando localidade muitas vezes). Fix requer variável por máquina, risco de regressão > risco do leak. Decisão: manter como está.
- **HVT spawn fora do mapa** — bug de gameplay preexistente, não do refactor.
- **`generateAO.sqf:25,35`** — while loop sem bound, risco baixo.
