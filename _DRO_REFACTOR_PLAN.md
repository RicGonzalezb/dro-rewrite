# DRO ACE Livonia — Refactor Plan & Handoff

**Owner (gerente):** Opus 4.7 session (esta).
**Executores:** sessões Sonnet separadas, uma por módulo.
**Status do projeto:** Fase 1 (CBA migration) substancialmente completa; restam 5 módulos de polimento + 1 etapa de teste manual.

---

## 1. Contexto da missão

Dynamic Recon Ops (DRO) ACE — Livonia. Mission scenario dinâmico/randomizado.
- Linguagem: SQF.
- Dependências runtime: ACE3 + CBA_A3 (garantidos).
- Map-agnóstica (usa `nearestLocations` + `CfgFactionClasses` em runtime, não tem hardcode de Livonia).
- Multiplayer/SP/dedicated server compatível.
- Caminho: `C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\`

**Padrões de código adotados (estabelecidos na Fase 1):**

| Antipadrão (antes) | Padrão CBA (depois) |
|---|---|
| `[] spawn { while {true} do { sleep N; ... } }` | `[{ ... }, N, args] call CBA_fnc_addPerFrameHandler` |
| `[] spawn { sleep N; oneshot }` | `[code, args, N] call CBA_fnc_waitAndExecute` |
| `waitUntil { sleep N; cond }` simples | PFH delta=N com `if (!cond) exitWith {}` + `removePerFrameHandler` |
| `waitUntil { cheap cond }` curto | `[cond, code, args] call CBA_fnc_waitUntilAndExecute` |
| Spawn com playersReady + waitUntil + cleanup | Chain `waitUntilAndExecute` → PFH → callback |
| Globais sem prefixo | Prefixo `DRO_` (ex: `DRO_loadoutSaverPFH`) |
| Função compilada em runtime | (pendente) mover pra `CfgFunctions` no description.ext |
| Multi-call risco | Guard `if (!isNil "DRO_xxx") exitWith { ... }` |

---

## 2. Status: Fase 1 — CBA Migration (CONCLUÍDA)

### Arquivos tocados (com nota breve)

**Core / boot:**
- `initServer.sqf` — fix typo `radio_backpacks` → `radio_vehicles` na linha 24
- `initPlayerLocal.sqf` — loadout saver virou PFH delta=5 (`DRO_loadoutSaverPFH`)
- `start.sqf` — task completion stable-for-6s watcher (`DRO_taskWatcherPFH` + funções `DRO_fnc_*`)
- `sunday_system/messageListener.sqf` — rewrite completo (`DRO_messageListenerPFH`) com safety timeout (corrigiu bug latente em dedi)

**Function libs:**
- `sunday_system/fnc_lib/sundayFunctions.sqf` — C2_Core grpNetId guard PFH (`DRO_c2GrpNetIdGuardPFH`)
- `sunday_system/fnc_lib/droFunctions.sqf` — 5 cases do `dro_civDeathHandler` (1, 3, 5, 6, default)

**Geração / setup:**
- `sunday_system/generate_enemies/generateEnemiesFunctions.sqf` — `dro_unitTaskObjective` PFH delta=5
- `sunday_system/player_setup/setupPlayersFaction.sqf` — resupply (linha 104) + heli insertion chain (linhas 884+)
- `sunday_system/player_setup/generateFriendlies.sqf` — 2 squad assault waiters (ambient + rendezvous)
- `sunday_system/player_setup/addSupports.sqf` — 3 fallback message delays
- `sunday_system/player_setup/teamRespawnPos.sqf` — rewrite completo (`DRO_teamRespawnPosPFH`)

**Objetivos:**
- `sunday_system/objectives/heli.sqf`, `artillery.sqf`, `destroyWreck.sqf`, `vehicle.sqf`, `vehicleSteal.sqf` — vehicle integrity watchers (`#LordShadeAceVeh`)
- `sunday_system/objectives/hvt.sqf`, `pow.sqf`, `objGrouping.sqf` (3 sites), `hvtInterrogate.sqf`, `destroyPowerUnit.sqf` (2), `addTaskExtras.sqf` (4) — task completion listeners
- `sunday_system/objectives_neutral/disarmIED.sqf` (2 + trigger string), `disarmUXO.sqf` (1 + trigger string), `fortify.sqf` (multi-stage), `protectCiv.sqf` (multi-stage)

**Extract / flow:**
- `sunday_system/createExtractTask.sqf` — RENDEZVOUS case grande + HOLD case inner spawn
- `sunday_system/heliExtract.sqf` — loss-of-contact + touchdown + departure chain (PFHs aninhados)
- `sunday_system/orders/insertGroup.sqf` — `#LordShadeDeleteVeh` delete-after-10min
- `sunday_system/supports/supportCASHeli.sqf`, `supportArtyComms.sqf` — menu open delays

**Revive (delicado, requer teste):**
- `sunday_revive/initRevive.sqf` — AI revive listener PFH delta=5 + timeout reset waitAndExecute
- `sunday_revive/bleedout.sqf` — **rewrite completo** (PFH delta=1 pra pp effects + PFH delta=0.1 pro main loop com state via args)
- `sunday_revive/AIReviveListen.sqf` — marcado deprecated/archive (não migrado, dead code)

**UI:**
- `sunday_system/dialogs/initLobbyCam.sqf` — ctrlSetText delay → waitAndExecute

### Bugs corrigidos como side-effect

1. **Typo `radio_vehicles`** em initServer.sqf (linha 24) — recurso SOG PF radio support agora funcionaria se reabilitado.
2. **Subtitle queue stuck em dedi** em messageListener.sqf — adicionado safety timeout que libera o lock mesmo se `bis_fnc_showsubtitle_subtitle` nunca aparecer.
3. **C2_Core grpNetId guard scheduler hog** — original rodava `while {true}` sem sleep, agora roda a cada 1s.

### Bugs identificados mas NÃO corrigidos (vão pra Módulo M2)

1. `initServer.sqf:23-25` — `_vn_allowed_radio_backpacks` é extraído mas o `setVariable` grava array vazio em vez do extraído. Mesma coisa pra `_vn_allowed_radio_vehicles`. Não afeta hoje porque o feature SOG PF está comentado em `description.ext`, mas se reabilitar quebra.
2. `reviveFunctions.sqf:80-100` — event handler leak: `_handlerLocal`, `_handlerDamage`, `_handlerKilled`, `_handlerRespawn` são adicionados via `addEventHandler` em respawn, mas os antigos nunca são removidos. Em múltiplos respawns acumula handlers.

### Sites legitimamente NÃO migrados (não são bugs)

- `AIReviveListen.sqf` — dead code, mantido com header de deprecação
- `supportCASHeliOld.sqf` — dead code, sem callers
- Trechos dentro de `/* ... */` em `droFunctions.sqf:227`, `footPatrol.sqf:155-163`, `disarmIED.sqf:99-105`
- `[args] spawn BIS_fnc_taskSetState` (idiomático, requer scheduled)
- `_x spawn { addEventHandler ... }` (idiomático)

---

## 3. Backlog: 6 módulos

| Módulo | Tipo | Status | Prioridade | Modelo |
|---|---|---|---|---|
| **M1** | Smoke test manual | ✅ DONE (rodou liso) | — | Você, no editor Arma |
| **M2** | Bug fixes deferidos | ✅ DONE (test de revive deferido pro M6/final) | — | Sonnet |
| **M3** | CfgFunctions migration (Fase 2) | ✅ DONE (67 funcs, 695 call sites; smoke test boot recomendado antes de M4) | — | Sonnet |
| **M4** | Higiene de geradores IA (Fase 4) | Próximo | Média | Sonnet |
| **M5** | start.sqf decomposition (Fase 6) | Pendente | Baixa | Sonnet |
| **M6** | Final audit + dead code cleanup + revive test + rev_changeLocal fix + CfgRemoteExec check | Pendente | Baixa | Sonnet |

**Ordem recomendada:** M1 → M2 → M3 → M4 → M5/M6 (paralelo).
Não pular M1. Se M1 revelar regressão, voltar pra Opus antes de M2.

---

## 4. Prompts prontos (copia-cola no Sonnet)

### M1 — Smoke test manual (sem prompt, é você)

Roda missão em editor SP em pelo menos 2 mapas (Livonia + Altis recomendado pra confirmar map-agnostic). Cenário de teste mínimo:

1. **Boot da missão:** entra no lobby, escolhe AO, fecha lobby. Confirma que objetivos spawnam, briefing aparece, câmera de intro roda.
2. **Bleedout/Revive:** deixa o player ser ferido até cair (mais fácil tirando armor). Confirma:
   - Tela escurece progressivamente
   - Suicide action aparece no menu de ação
   - Timer expira corretamente (bleedout default 300s, dá pra reduzir via params)
   - Se reanimado por AI/teammate: tela volta ao normal
3. **Heli insertion** (se mission preset usar heli infil): heli pousa, jogadores desembarcam, heli sobe e some.
4. **Task completion + extract:** completa uma task simples (Destroy Helicopter é rápido — só matar o heli da task). Espera o trigger de extract task aparecer.
5. **Heli extract:** chama heli, espera pousar, embarca, clica "Extract", confirma que heli sai.
6. **Civilian casualty** (se feature ativa): mata um civ. Espera ~2s, confirma mensagem de warning no rádio.

**Output esperado:** lista de issues observadas. Format:
```
[OK] boot/lobby/intro
[OK] bleedout-suicide-action
[FAIL] heli-extract: heli não decolou após eu clicar Extract
       repro: heli pousou, embarquei, ação Extract aparece, cliquei, heli ficou parado
[OK] task-completion-flow
[WARN] civilian-warning: mensagem apareceu mas com delay de ~10s em vez de 2s
```

Traga esse output de volta pro Opus pra triage.

---

### M2 — Bug fixes deferidos

**Copia tudo abaixo num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO: Uma sessão anterior fez migração CBA completa (Fase 1) usando CBA_fnc_addPerFrameHandler, CBA_fnc_waitAndExecute, e CBA_fnc_waitUntilAndExecute em substituição a scheduled spawn/while/waitUntil+sleep. Código migrado está marcado com comentário "// Migrated from ..." — NÃO toque nesses trechos, são Fase 1 estabilizada.

PADRÕES CBA EM USO:
- PFH: `[{...}, delta, args] call CBA_fnc_addPerFrameHandler`, com `params ["_args", "_pfhId"]` no início do código
- waitAndExecute: `[code, args, delay] call CBA_fnc_waitAndExecute`
- Globais novas com prefixo `DRO_`
- Guard contra double-init: `if (!isNil "DRO_xxx") exitWith { ... }`

TAREFA: Corrigir 2 bugs deferidos.

### Bug #1: initServer.sqf — setVariable de array vazio
Arquivo: initServer.sqf, linhas 22-25
Problema atual:
```sqf
_vn_allowed_radio_backpacks = (missionConfigFile >> "vn_artillery_settings" >> "radio_backpacks") call BIS_fnc_getCfgDataArray;
missionNameSpace setVariable ["vn_allowed_radio_backpacks", [], true];
_vn_allowed_radio_vehicles = (missionConfigFile >> "vn_artillery_settings" >> "radio_vehicles") call BIS_fnc_getCfgDataArray;
missionNameSpace setVariable ["vn_allowed_radio_vehicles", [], true];
```
Os locais `_vn_allowed_radio_backpacks` e `_vn_allowed_radio_vehicles` são extraídos da config mas os `setVariable` gravam `[]` em vez do valor extraído. Corrigir pra:
```sqf
missionNameSpace setVariable ["vn_allowed_radio_backpacks", _vn_allowed_radio_backpacks, true];
missionNameSpace setVariable ["vn_allowed_radio_vehicles", _vn_allowed_radio_vehicles, true];
```

NOTA: O feature SOG PF Radio Support está comentado em `description.ext` (bloco `class vn_artillery_settings { ... }` dentro de `/* */`). Isso não afeta gameplay hoje. Mas o fix é correto e safe.

### Bug #2: reviveFunctions.sqf — event handler leak
Arquivo: sunday_revive/reviveFunctions.sqf, função `rev_addReviveToUnit` (começa na linha ~70 e o callback de Respawn está nas linhas ~80-100).

Problema: dentro do callback do "Respawn" eventHandler, novos `addEventHandler` são adicionados pra HandleDamage, Killed, HandleRating, mas os HANDLERS ANTERIORES dessas mesmas categorias só são removidos pra HandleDamage e Killed via `removeAllEventHandlers`. Falta:
1. Verificar se ratings handler "HandleRating" também precisa de cleanup (provavelmente sim)
2. Remover handlers locais (Local, na linha 47 do initRevive original) se já estavam adicionados
3. Garantir que reviveActionAdd e dragActionAdd não duplicam ações

Estratégia: adicionar `removeAllEventHandlers` para TODOS os EHs no início do callback de respawn, antes de re-adicionar. Também usar `removeAction` se houver IDs de ação gravadas no unitVariable do unit antes do respawn.

Específicamente verificar:
- `_unit getVariable ["DRO_revHandlerIds", []]` — se não existir, criar pra armazenar IDs após cada addEventHandler.
- No callback de Respawn, ler esse array e remover via `removeEventHandler [type, id]` antes de re-adicionar.

Implementação sugerida:
```sqf
// Em rev_addReviveToUnit, ao adicionar EH, salvar ID:
_handlerDamage = _unit addEventHandler ["HandleDamage", rev_handleDamage];
_existingHandlers = _unit getVariable ["DRO_revHandlerIds", []];
_existingHandlers pushBack ["HandleDamage", _handlerDamage];
_unit setVariable ["DRO_revHandlerIds", _existingHandlers, true];

// No callback de Respawn, antes de re-adicionar:
_oldHandlers = (_this select 0) getVariable ["DRO_revHandlerIds", []];
{
    (_this select 0) removeEventHandler [_x select 0, _x select 1];
} forEach _oldHandlers;
(_this select 0) setVariable ["DRO_revHandlerIds", [], true];
// agora re-adiciona limpo
```

Mas atenção: o callback de Respawn é executado via `remoteExec` (no servidor), então pode ter timing issues. Estudar com cuidado antes de aplicar.

REGRAS:
- Não toque em código marcado "// Migrated from ..."
- Não toque em sunday_revive/bleedout.sqf (foi reescrito inteiro na Fase 1, está delicado)
- Teste mental: o que acontece se o player respawnar 5 vezes seguidas? Sem o fix, 5 handlers de HandleDamage acumulados.
- Use prefixo `DRO_` para variáveis novas.

REPORTE DE VOLTA (escreva no fim de _DRO_REFACTOR_PROGRESS.md na raiz da missão; se não existir, crie):
```
## M2 — Bug fixes deferidos — [DATA]

### Bug #1 (vn_artillery_settings empty arrays)
Status: [DONE / SKIPPED / BLOCKED]
Arquivos: initServer.sqf
Linhas: 23, 25
Mudança: setVariable agora salva valor extraído em vez de []

### Bug #2 (revive EH leak)
Status: [DONE / PARTIAL / BLOCKED]
Arquivos: <list>
Estratégia escolhida: <desc>
Side effects considerados: <list>
Pontos de atenção pro teste: <list>

### Descobertas inesperadas
<anything else worth flagging>
```
````

---

### M3 — CfgFunctions migration (Fase 2)

**Copia tudo abaixo num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO: Uma Fase 1 (CBA migration) foi feita antes — código migrado tem comentário "// Migrated from ..." e usa CBA_fnc_addPerFrameHandler / waitAndExecute / waitUntilAndExecute. Não toque nesses trechos.

TAREFA: Migrar function libraries de `#include` runtime compile pra `CfgFunctions` no description.ext.

### Estado atual

Em `start.sqf` e `initPlayerLocal.sqf`, várias libs são incluídas via `#include`:
```
#include "sunday_system/fnc_lib/sundayFunctions.sqf"
#include "sunday_system/fnc_lib/droFunctions.sqf"
#include "sunday_revive/reviveFunctions.sqf"
#include "sunday_system/fnc_lib/menuFunctions.sqf"
#include "sunday_system/generate_enemies/generateEnemiesFunctions.sqf"
```

Cada arquivo define múltiplas funções como `sun_*`, `dro_*`, `rev_*`. O problema: essas funções só ficam disponíveis depois do `#include` rodar, que acontece em runtime. Isso atrasa o boot e dificulta autocomplete em editors externos.

### Objetivo

Migrar pra CfgFunctions. As funções viram carregadas automaticamente pelo engine antes do mission init, com nomes tipo `DRO_fnc_<originalName>` (sem o prefixo `sun_`/`dro_`/`rev_`).

### Passos

1. **Inventariar todas as funções definidas nos 5 arquivos lib.** Cada bloco `name = { ... };` no top-level é uma função.

2. **Criar estrutura de arquivos em `functions/`:**
```
functions/
  fn_<originalName>.sqf
  ...
```
Cada arquivo contém só o body da função (sem o `name = {` envolvendo, e sem o `};` final). Renomear a função pra remover o prefixo legado:
- `sun_extractIdentities` → `fn_extractIdentities.sqf`
- `dro_civDeathHandler` → `fn_civDeathHandler.sqf`
- `rev_addReviveToUnit` → `fn_addReviveToUnit.sqf`
- etc.

3. **Adicionar bloco `CfgFunctions` ao `description.ext`:**
```cpp
class CfgFunctions {
    class DRO {
        class core {
            file = "functions";
            class extractIdentities {};
            class civDeathHandler {};
            class addReviveToUnit {};
            // ... uma class por função
        };
    };
};
```
Cada função fica disponível como `DRO_fnc_extractIdentities`, etc.

4. **Substituir todas as chamadas pelo nome novo.** Grep -r pelo prefixo legado e renomear:
- `call sun_extractIdentities` → `call DRO_fnc_extractIdentities`
- `[...] spawn sun_xxx` → `[...] spawn DRO_fnc_xxx`
- `remoteExec ["sun_xxx", ...]` → `remoteExec ["DRO_fnc_xxx", ...]`

5. **Remover os `#include` antigos** em `start.sqf` e `initPlayerLocal.sqf`. Manter o `#include "sunday_system\fnc_lib\objectsLibrary.sqf"` só se ele tiver código de execução (não funções) — verificar.

6. **Manter alias temporários (opcional, recomendado pra rollback fácil):**
No `init.sqf` (criar se não existir):
```sqf
sun_extractIdentities = DRO_fnc_extractIdentities;
dro_civDeathHandler = DRO_fnc_civDeathHandler;
// ...etc
```
Isso permite que código não-atualizado ainda chame os nomes velhos. Remover esses aliases num módulo futuro depois que tudo for renomeado.

### Arquivos a inventariar

- `sunday_system/fnc_lib/sundayFunctions.sqf` (funções `sun_*`)
- `sunday_system/fnc_lib/droFunctions.sqf` (funções `dro_*`)
- `sunday_system/fnc_lib/menuFunctions.sqf` (funções de menu)
- `sunday_revive/reviveFunctions.sqf` (funções `rev_*`)
- `sunday_system/generate_enemies/generateEnemiesFunctions.sqf` (geradores de IA)

### Atenção: mudanças do M2 que afetam este módulo

- Em `sunday_revive/reviveFunctions.sqf` foi adicionada uma nova função `rev_removeDragAction` (M2). Inclua na migração junto com as outras `rev_*`.
- Foi adicionada uma global de infraestrutura `DRO_revHandlerIds` (array por unidade, via setVariable). Não migrar — é uma variável, não função.

### REGRAS

- Não delete os arquivos lib antigos ainda — comente o conteúdo deles ou move pra `_archive/`.
- Não toque em código marcado "// Migrated from ..." (Fase 1).
- Não toque em bleedout.sqf, fortify.sqf, protectCiv.sqf, heliExtract.sqf, setupPlayersFaction.sqf (mid-flow refactors da Fase 1).
- Funções que são compiladas via `compile preprocessFile` em start.sqf (linhas ~87-99) também migram pra CfgFunctions.

### REPORTE DE VOLTA (append em _DRO_REFACTOR_PROGRESS.md):

```
## M3 — CfgFunctions migration — [DATA]

### Funções migradas
- DRO_fnc_extractIdentities (de sun_extractIdentities)
- DRO_fnc_... (etc)
total: N funções

### Arquivos criados
functions/fn_*.sqf (lista)

### Call sites atualizados
- N call sites de `sun_*` → `DRO_fnc_*`
- N call sites de `dro_*` → `DRO_fnc_*`
- etc

### Aliases adicionados
init.sqf — aliases temporários pros nomes legados (lista)

### Pontos de atenção
- <qualquer função com lógica complexa que pode ter quebrado>
- <funções remoteExec'd que precisam estar em CfgRemoteExec se mission settings forem strict>
```
````

---

### M4 — Higiene de geradores de IA (Fase 4)

**Copia tudo abaixo num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO: Uma Fase 1 (CBA migration) foi feita antes — código migrado tem comentário "// Migrated from ..." e usa CBA_fnc_addPerFrameHandler / waitAndExecute / waitUntilAndExecute. Não toque nesses trechos.

TAREFA: Otimizar os scripts de geração de inimigos pra reduzir frame hitches durante o spawn da missão e durante o gameplay.

ATENÇÃO — mudanças do M3 que afetam este módulo:
- Funções de geração de IA foram migradas pra CfgFunctions. Use os NOMES NOVOS:
  - `DRO_fnc_spawnGroupWeighted` (era `dro_spawnGroupWeighted`)
  - `DRO_fnc_unitTaskObjective` (era `dro_unitTaskObjective`)
  - `DRO_fnc_triggerAmbushSpawn` (era `dro_triggerAmbushSpawn`)
  - `DRO_fnc_localBuildingPatrol` (era `dro_localBuildingPatrol`)
  - `DRO_fnc_spawnEnemyGarrison` (era `dro_spawnEnemyGarrison`)
  - `DRO_fnc_spawnEnemyCompound` (era `fnc_spawnEnemyCompound`)
  - `DRO_fnc_generateBunker`, `DRO_fnc_generateRoadblock`, `DRO_fnc_generateBarrier`, `DRO_fnc_generateEmplacement`
- O arquivo `sunday_system/generate_enemies/generateEnemiesFunctions.sqf` agora é um STUB (lib original arquivada). NÃO mexa nele — todas as funções estão em `functions/fn_*.sqf` agora.
- Aliases legados (sun_*, dro_*, fnc_*) ainda funcionam via init.sqf mas estão depreciados — sempre prefira o nome `DRO_fnc_*`.

### Problema

Os arquivos em `sunday_system/generate_enemies/` spawnam dezenas de unidades em forEach loops síncronos. Cada `createUnit` é caro. Quando o forEach tem 50+ unidades, a engine engasga.

Adicionalmente, depois de spawnar, as unidades ficam ATIVAS em todo o mapa — mesmo as que estão a 2km dos jogadores. `enableDynamicSimulation` pode reduzir CPU dessas unidades distantes.

### Arquivos alvo

- `sunday_system/generate_enemies/generateEnemies.sqf`
- `sunday_system/generate_enemies/generateCompound.sqf`
- `sunday_system/generate_enemies/generateBunker.sqf`
- `sunday_system/generate_enemies/generateRoadblock.sqf`
- `sunday_system/generate_enemies/generateBarrier.sqf`
- `sunday_system/generate_enemies/generateEmplacement.sqf`
- `sunday_system/generate_enemies/staggeredAttack.sqf`

### Mudanças a aplicar

**1. Dynamic Simulation per grupo**

Em cada lugar onde um grupo é criado (`createGroup` ou `dro_spawnGroupWeighted` retorna grupo), adicionar logo após:
```sqf
if (dynamicSim != 1) then {
    _spawnedSquad enableDynamicSimulation true;
};
```

A condição checa a global `dynamicSim` (set em start.sqf:228) — se for 1 significa que dynamicSim system foi DESABILITADO globalmente, e não devemos forçar per-group. Se for 0 (default), aplicamos.

OBS: confirmar o nome real da global. Em start.sqf:228 tem `if (dynamicSim == 1) then { enableDynamicSimulationSystem false; };` — então se dynamicSim==1 = disabled, dynamicSim==0 = enabled.

**2. Frame budgeting em forEach loops grandes**

Em `generateEnemies.sqf`, dentro de loops `forEach AOLocations` ou similar onde muitas unidades são spawnadas, adicionar `uiSleep 0` (ou `sleep 0.001`) entre iterações pra liberar o frame:

```sqf
{
    // spawn one group
    _group = ...;
    // ...

    uiSleep 0; // liberar frame
} forEach _spawnPoints;
```

CUIDADO: o script onde aplicar precisa estar em scheduled context (ou seja, dentro de spawn/execVM). Não funciona dentro de PFH.

**3. setGroupId + setVariable cleanup**

Pra ajudar a debugging, em cada grupo criado, setar um ID identificável:
```sqf
_spawnedSquad setGroupId [format ["DRO_enemy_%1", floor random 10000]];
```

Não obrigatório, mas útil pra rastrear grupos no .rpt.

**4. Skill cap**

Verificar se algum gerador seta `setSkill` muito alto. AI muito skilled em IA distante consome mais CPU. Cap em 0.6-0.8 pra equilibrar.

### REGRAS

- Não toque em código marcado "// Migrated from ..." (Fase 1).
- Não toque em start.sqf (orquestrador master).
- Não toque em generateEnemiesFunctions.sqf — esse já foi tocado na Fase 1 e tem PFH delicado.
- Antes de mudar, ABRA o arquivo, leia inteiro pra entender o flow. Não aplique cegamente.
- Teste mental: spawn 60 unidades, qual o tempo total antes/depois?

### REPORTE DE VOLTA (append em _DRO_REFACTOR_PROGRESS.md):

```
## M4 — Higiene de geradores IA — [DATA]

### Arquivos modificados
- generateEnemies.sqf: +dynamicSim per group, +uiSleep entre forEach iters
- generateCompound.sqf: ...
- (etc)

### Mudanças por categoria
- enableDynamicSimulation true: N grupos cobertos
- uiSleep 0 em forEach: N loops cobertos
- setGroupId: N grupos

### Pontos de atenção
- <qualquer grupo onde dynSim pode quebrar IA (ex: AA stations precisam disparar de longe)>
- <qualquer alteração de skill cap>
```
````

---

### M5 — start.sqf decomposition (Fase 6 parcial)

**Copia tudo abaixo num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO: Uma Fase 1 (CBA migration) foi feita antes — código migrado tem comentário "// Migrated from ..." e usa CBA_fnc_addPerFrameHandler / waitAndExecute / waitUntilAndExecute. Não toque nesses trechos. Se M3 (CfgFunctions migration) já tiver sido feito, use os nomes `DRO_fnc_*`; senão use os nomes legados (`sun_*`, `dro_*`, `rev_*`). Pra saber qual: grepar pelo nome legado — se ainda aparecer em call sites, M3 ainda não rolou.

TAREFA: Decompor o `start.sqf` (1341 linhas) em funções separadas pra reduzir tamanho e melhorar legibilidade.

### Estado atual

`start.sqf` é o orquestrador master da missão. Faz tudo: extração de facções, escolha de AO, geração de objetivos, civis, inimigos, clima, briefing, trigger de reforços, etc. É difícil de navegar.

### Seções a extrair

Identificar as seções e extrair pra funções separadas (em `functions/` ou no padrão CfgFunctions de M3):

1. **`fn_extractFactionData`** — linhas ~115-213. Coleta facções com unidades, filtra, popula `availableFactionsData` e `availableFactionsDataNoInf`.

2. **`fn_setupEnemySides`** — linhas ~511-552. Determina `enemySide`, configura sideFriend entre enemy sides.

3. **`fn_defineMarkerColors`** — linhas ~554-592. Setup de `markerColorPlayers`/`Enemy` e `colorPlayers`/`Enemy` baseado nas sides.

4. **`fn_chooseMissionMusic`** — linhas ~665-746. Escolhe playlist de música (day/night/extract + variantes VN).

5. **`fn_generatePlayerIdentities`** — linhas ~756-863. Setup de faces, voices, names pros players.

6. **`fn_chooseObjectivesPOWClass`** — linhas ~895-945. Escolhe classe de POW (helicrew, engineers, journalists, etc).

7. **`fn_setupReinforcementTrigger`** — linhas ~1299-1311. Cria o trigger de reforço.

Cada uma vira uma função separada chamada de start.sqf:
```sqf
call DRO_fnc_extractFactionData;
call DRO_fnc_setupEnemySides;
call DRO_fnc_defineMarkerColors;
// etc
```

### Restrições

- Variáveis usadas pelas seções extraídas viram globais missionNamespace (já são, na maioria) OU retornadas pela função.
- Não mudar o comportamento — apenas reorganizar.
- Não toque em código marcado "// Migrated from ..." (Fase 1 / CBA).
- Manter o ordem de execução exata.

### Objetivo final

`start.sqf` deve ter ~400-600 linhas após decomposição, fácil de ler como uma sequência de chamadas.

### REPORTE DE VOLTA:

```
## M5 — start.sqf decomposition — [DATA]

### Funções extraídas
- DRO_fnc_extractFactionData (linhas X-Y → fn_extractFactionData.sqf)
- (etc)

### start.sqf antes/depois
- Antes: 1341 linhas
- Depois: N linhas

### Variáveis globais expostas (publicVariable)
<lista — qualquer que era local antes da extração e virou global>

### Pontos de atenção
<qualquer função que tem dependência implícita não-óbvia em globals>
```
````

---

### M6 — Final audit + cleanup

**Copia tudo abaixo num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO: Vários módulos de refactor foram feitos antes (CBA migration + bug fixes + CfgFunctions + AI gen hygiene + start.sqf decomp). Código migrado tem comentário "// Migrated from ...". Para ver o histórico do que foi feito por outras sessões, leia `_DRO_REFACTOR_PROGRESS.md` na raiz da missão (esse SIM pode/deve ser lido — é o log de progresso).

TAREFA: Auditoria final e cleanup de dead code.

### Verificações herdadas do M3 (CfgFunctions)

1. **Smoke test de boot:** confirmar que missão inicia sem `Error undefined variable` — lobby, faction picker, AO gen, intro, briefing devem rodar limpo.

2. **EH handlers do revive:** verificar que `addEventHandler ["HandleDamage", DRO_fnc_handleDamage]` e `["Killed", DRO_fnc_handleKilled]` em `fn_addReviveToUnit.sqf` apontam pros nomes novos (não pros legados `rev_*`).

3. **`briefingJIP`:** a linha `remoteExec ["sun_briefingJIP", 0, true]` em `briefing.sqf` foi comentada anteriormente. Verificar se algum JIP briefing path foi quebrado pelo M3 (deve estar OK porque o alias existe, mas confirmar).

4. **CfgRemoteExec whitelist (se aplicável):** se a missão tem `class CfgRemoteExec` em `description.ext` com `mode = 2`, adicionar à whitelist:
   - `DRO_fnc_setNameMP`
   - `DRO_fnc_randomTime`
   - `DRO_fnc_briefingJIP`
   - `DRO_fnc_changeLocal`
   - `DRO_fnc_civDeathHandler`
   Hoje a missão NÃO tem `CfgRemoteExec` definido em `description.ext` — usa default (tudo permitido). Mas se um dia adicionar restrição, precisa whitelistar.

5. **Aliases em `init.sqf`:** decidir se mantém os 110 aliases (`sun_x = DRO_fnc_x` etc.) ou remove. Recomendado MANTER até confirmar que nenhum scripts/mod externo usa nomes legados. Se mantiver, adicionar header explicando o porquê.

6. **Arquivos lib stub:** `sundayFunctions.sqf`, `droFunctions.sqf`, `menuFunctions.sqf`, `reviveFunctions.sqf`, `generateEnemiesFunctions.sqf` foram convertidos em stubs de deprecação no M3 (originais em `_archive/fnc_lib_backup_M3/`). Decidir se: (a) manter stubs vazios pra retrocompat, (b) deletar, (c) restaurar do archive (não recomendado).

### Audit pass

1. **Grep por antipadrões remanescentes:**
```
grep -r "while {true}" --include="*.sqf"
grep -r "spawn { sleep" --include="*.sqf"
grep -rE "waitUntil\s*\{[^}]*sleep" --include="*.sqf"
```
Para cada match, verificar se é:
- Documentação de migração (comentário) → OK, deixar
- Dentro de `/* */` → OK, deixar
- Código real → flag pra revisão

2. **Verificar duplicate PFH guards.** Greps:
```
grep -r "DRO_.*PFH" --include="*.sqf"
grep -r "if (!isNil \"DRO_" --include="*.sqf"
```
Confirmar que cada PFH tem o guard contra double-init.

3. **Verificar que removePerFrameHandler está em todos os PFHs auto-removentes.** Grep:
```
grep -r "addPerFrameHandler" --include="*.sqf"
```
Cada match deve ter um `removePerFrameHandler` correspondente no body OU ser um PFH que roda forever (sem condição de exit).

### Dead code cleanup

Confirmar que estes arquivos podem ser deletados ou movidos pra _archive/:

1. **`sunday_revive/AIReviveListen.sqf`** — confirmado dead na Fase 1 (única referência está comentada em initRevive.sqf:120).
   Decisão: deletar OU mover pra `_archive/`.

2. **`sunday_system/supports/supportCASHeliOld.sqf`** — confirmado dead na Fase 1 (sem callers).
   Mesma decisão.

### Bug pendente herdado do M2

**`rev_changeLocal` em `sunday_revive/reviveFunctions.sqf` (linhas ~257-286) tem Respawn EH leak.**

Padrão: cada vez que a localidade de uma unidade AI muda, `rev_changeLocal` adiciona um novo `addEventHandler ["Respawn", ...]` via remoteExec SEM remover o handler anterior. N mudanças de localidade = N handlers acumulados. Cada handler interno também adiciona HandleDamage + Killed sem `removeAllEventHandlers`, então leak duplo.

Estratégia recomendada (análoga ao que M2 fez em `rev_addReviveToUnit`):
- Adicionar `removeAllEventHandlers "Respawn"` (ou tracking via setVariable como `DRO_revRespawnHandlerId`) antes de re-adicionar o Respawn EH em `rev_changeLocal`.
- Cuidado de locality: `removeAllEventHandlers "Respawn"` em `rev_changeLocal` não conflita com o Respawn EH adicionado por `rev_addReviveToUnit` apenas se ambos foram adicionados na mesma máquina via mesmo padrão de remoteExec. Verificar antes de aplicar.

### Validação do M2 (revive action leak) — pendente

Não foi testado em editor. Plano: rodar smoke test rápido:
1. Spawnar teammate AI próximo do player
2. Matar player + respawn 3-4 vezes
3. Aproximar do AI ferido e abrir menu de ação
4. Confirmar: só 1 "Revive" (hold action) e 1 "Drag" (addAction), sem stack

Se aparecer stack, o fix do M2 falhou — voltar pra Opus.

Se mover pra `_archive/`, criar a pasta na raiz e adicionar header em cada arquivo:
```
// ARCHIVED — não está em uso. Movido em [data] por [motivo].
```

### Cleanup de TODO/FIXME comments

Grep:
```
grep -rE "TODO|FIXME|XXX|HACK" --include="*.sqf"
```
Listar todos. Cada um vira um item pra triage:
- Resolver agora (se trivial)
- Anotar em `_DRO_REFACTOR_PROGRESS.md` como pendente
- Remover se obsoleto

### REPORTE DE VOLTA (FINAL):

```
## M6 — Final audit + cleanup — [DATA]

### Antipadrões verificados (esperado: 0 reais)
- while {true} reais: N (lista)
- spawn { sleep N }: N (lista)
- waitUntil + sleep: N (lista)

### PFH guards
- PFHs com guard: N / total N
- PFHs sem guard (precisa fix): <lista>

### removePerFrameHandler coverage
- PFHs auto-removentes corretos: N
- Possíveis leaks: <lista>

### Dead code
- AIReviveListen.sqf: [DELETED / MOVED to _archive / KEPT]
- supportCASHeliOld.sqf: [DELETED / MOVED to _archive / KEPT]

### TODOs encontrados
- arquivo.sqf:LINHA — descrição — [RESOLVED / NOTED / REMOVED]
- (etc)

### Estado final do projeto
Fase 1: CBA migration ✅
Fase 2 (M3): CfgFunctions ✅/✗
Fase 4 (M4): IA gen hygiene ✅/✗
Fase 6 (M5): start.sqf decomp ✅/✗
Fase 6 (M6): final audit ✅
```
````

---

## 5. Convenções de código (referência rápida pros executores)

### Naming
- Globais novas: prefixo `DRO_`
- Funções (CfgFunctions): `DRO_fnc_<name>`
- PFH handles: `DRO_<contexto>PFH`
- State arrays in PFH: `_state = [...]` (mutado via `set`)

### Pattern templates

**Self-removing PFH (condition watcher):**
```sqf
[{
    params ["_args", "_pfhId"];
    _args params ["_obj", "_extraData"];
    if (isNull _obj) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler };
    if (!desiredCondition) exitWith {};
    [_pfhId] call CBA_fnc_removePerFrameHandler;
    // ... cleanup code ...
}, delta, [_obj, _extraData]] call CBA_fnc_addPerFrameHandler;
```

**One-shot delayed action:**
```sqf
[{
    params ["_arg1"];
    // action
}, [_arg1], delaySeconds] call CBA_fnc_waitAndExecute;
```

**Wait for condition then execute:**
```sqf
[
    { condition },
    {
        params ["_arg1"];
        // action
    },
    [_arg1],
    timeoutSeconds,  // optional
    {
        // optional timeout fallback
    }
] call CBA_fnc_waitUntilAndExecute;
```

**Long-running PFH (chain):**
```sqf
DRO_myFlowPFH = [{
    params ["_args", "_pfhId"];
    _args params ["_state"];
    _state params ["_phase", "_data"];
    switch (_phase) do {
        case "init": { /* ... */; _state set [0, "waiting"] };
        case "waiting": { /* ... */; _state set [0, "done"] };
        case "done": { [_pfhId] call CBA_fnc_removePerFrameHandler };
    };
}, 1, [["init", _initialData]]] call CBA_fnc_addPerFrameHandler;
```

### Double-init guard
```sqf
if (!isNil "DRO_xxx") exitWith {
    diag_log "DRO: xxx already running, skipping";
};
DRO_xxx = [...] call CBA_fnc_addPerFrameHandler;
```

---

## 6. Template de relatório consolidado (pra trazer de volta pro Opus)

Quando você (Gonza) tiver completado vários módulos via Sonnet, traga pro Opus o arquivo `_DRO_REFACTOR_PROGRESS.md` consolidado e cole nele a estrutura:

```
# Relatório consolidado — sessão [DATA]

## Módulos completados desde último contato com Opus
- [x] M1 smoke test
- [x] M2 bug fixes
- [ ] M3 CfgFunctions (em andamento)
- ...

## Issues novas descobertas
<lista, com arquivo:linha quando aplicável>

## Decisões tomadas
- AIReviveListen.sqf foi: [deletado / arquivado / mantido]
- (etc)

## Próximo módulo recomendado
<seu palpite, ou peça ajuda pro Opus pra decidir>

## Pergunta pro Opus
<qualquer coisa que travou ou que precisa decisão de arquitetura>
```

Opus vai ler isso e atualizar o plan + recomendar próximo passo.

---

**Fim do plano.** Boa sorte. Quando voltar com resultados, traga o `_DRO_REFACTOR_PROGRESS.md` completo.
