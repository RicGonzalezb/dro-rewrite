# DRO ACE Livonia — Refactor Plan & Handoff

---

## 0. Cold Start — Leia isto primeiro

**Se você está chegando agora como novo Master (contexto zerado), siga estes passos:**

1. Você é o prompt-mestre (gerente) de um projeto de rewrite/refactor de uma missão scriptada de Arma 3 (SQF). Seu trabalho é: entender o estado atual, planejar os próximos módulos, gerar prompts contextualizados para sessões Sonnet executarem, e validar os resultados.
2. **Leia `_DRO_REFACTOR_PROGRESS.md`** (mesmo diretório deste arquivo). Ele contém o log detalhado de TUDO que foi feito, módulo por módulo, incluindo hotfixes. O status real do projeto está lá — este PLAN.md contém a visão original, que pode estar desatualizada em relação ao progresso.
3. **Tabela rápida de status** (atualize aqui ao completar módulos):

| Módulo | Descrição | Status |
|--------|-----------|--------|
| Fase 1 | CBA migration (spawn/waitUntil → PFH/waitAndExecute) | ✅ DONE |
| M1 | Smoke test manual | ✅ DONE |
| M2 | Bug fixes deferidos (initServer + revive EH leak) | ✅ DONE |
| M3 | CfgFunctions migration (67 funcs, 695 call sites) | ✅ DONE |
| M3 hotfix #1 | Macro `aliveVeh` ausente em fn_*.sqf | ✅ DONE |
| M3 hotfix #2 | fn_spawnEnemyGarrison undefined `_unit` | ✅ DONE |
| M3 hotfix #3 | fn_selectRemove empty array crash + audit 84 callers | ✅ DONE |
| M3 hotfix #4 | selectReactiveTask sleep em unscheduled context | ✅ DONE |
| M4 | Higiene de geradores IA (dynamicSim, uiSleep, skill cap) | ✅ DONE |
| M5 | start.sqf decomposition (1352→939 linhas, 7 funções) | ✅ DONE |
| M6 | Final audit + dead code cleanup + bug fixes | ✅ DONE |
| M7 | Smoke test hotfixes (geradores, reinforce, civis hostis, anti-aglomeração) | ✅ DONE |

4. **Fluxo de trabalho:** você NÃO executa os módulos diretamente — você gera prompts autocontidos para sessões Sonnet, que têm acesso aos arquivos da missão. O prompt deve conter todo o contexto necessário (caminho, regras, o que não tocar, formato de relatório). Após o Sonnet executar, o usuário (Gonza) traz o resultado pra você validar.
5. **O usuário fala português (BR).** Comunique-se em português.

**Caminho da missão:**
`C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\`

**Arquivos-chave:**
- `_DRO_REFACTOR_PLAN.md` — este arquivo (plano geral + prompts dos módulos)
- `_DRO_REFACTOR_PROGRESS.md` — log de progresso (fonte de verdade do que foi feito)
- `functions/` — 98 arquivos fn_*.sqf (migrados no M3)
- `init.sqf` — 110 aliases temporários (nomes legados → DRO_fnc_*)
- `description.ext` — CfgFunctions definido no final
- `start.sqf` — orquestrador master (~1341 linhas, alvo do M5)
- `_archive/fnc_lib_backup_M3/` — backups das libs originais

**Regras universais (todos os módulos):**
- Não toque em código marcado `// Migrated from ...` (Fase 1, estabilizada)
- Prefixo `DRO_` para globais novas, `DRO_fnc_*` para funções CfgFunctions
- Guard contra double-init: `if (!isNil "DRO_xxx") exitWith { ... }`
- Qualquer módulo deve reportar em `_DRO_REFACTOR_PROGRESS.md`
- **Padrões CBA obrigatórios** — o projeto migrou de scheduled spawn/sleep/waitUntil pra CBA. Se encontrar código novo ou código antigo não-migrado, usar:

| Antipadrão (NÃO usar) | Padrão CBA (usar) |
|---|---|
| `[] spawn { while {true} do { sleep N; ... } }` | `[{ ... }, N, args] call CBA_fnc_addPerFrameHandler` |
| `[] spawn { sleep N; oneshot }` | `[code, args, N] call CBA_fnc_waitAndExecute` |
| `waitUntil { sleep N; cond }` | PFH com `if (!cond) exitWith {}` + `removePerFrameHandler` |
| `waitUntil { cond }` curto | `[cond, code, args] call CBA_fnc_waitUntilAndExecute` |
| `sleep` em unscheduled context | `CBA_fnc_waitAndExecute` com delay |

- Ver Seção 5 deste documento para templates completos com exemplos de código.

**Procedimento de trabalho:**
- **Módulos planejados (M4, M5, M6...):** o prompt pro Sonnet fica NESTE arquivo, na seção do módulo. O Master atualiza o prompt aqui conforme o projeto evolui. O Gonza copia daqui e cola no Sonnet. Após execução, o Sonnet appenda o relatório em `_DRO_REFACTOR_PROGRESS.md`.
- **Fixes cirúrgicos (hotfixes avulsos):** o Master gera o prompt direto no chat (NÃO atualiza este arquivo). O Sonnet aplica o fix e appenda o relatório em `_DRO_REFACTOR_PROGRESS.md`. O Master depois atualiza a tabela de status acima se necessário.
- Resumindo: este PLAN.md contém os prompts "vivos" dos módulos pendentes. O PROGRESS.md contém o log de tudo que foi feito.

---

**Owner (gerente):** sessão Master atual (Opus).
**Executores:** sessões Sonnet separadas, uma por módulo.
**Status do projeto:** veja tabela acima.

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

**Cola tudo entre as marcas ```````` num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO:
- Fase 1 (CBA migration) e M3 (CfgFunctions migration) já estão concluídas e estabilizadas.
- Código marcado "// Migrated from ..." NÃO deve ser tocado — é da Fase 1.
- Todas as funções agora usam nomes `DRO_fnc_*` (ex: `DRO_fnc_spawnGroupWeighted`, `DRO_fnc_setSkillAction`). Aliases legados existem em `init.sqf` mas estão depreciados — use SEMPRE o nome `DRO_fnc_*`.
- O arquivo `sunday_system/generate_enemies/generateEnemiesFunctions.sqf` é um STUB de deprecação — NÃO mexa nele. Funções reais estão em `functions/fn_*.sqf`.
- Padrão CBA: `CBA_fnc_waitAndExecute` em vez de `sleep` em unscheduled context; `CBA_fnc_addPerFrameHandler` em vez de `while {true} do { sleep N }`.

TAREFA: Otimizar os scripts de geração de inimigos pra reduzir frame hitches durante o spawn e durante o gameplay.

### Arquivos alvo

- `sunday_system/generate_enemies/generateEnemies.sqf`
- `sunday_system/generate_enemies/generateCompound.sqf`
- `sunday_system/generate_enemies/generateBunker.sqf`
- `sunday_system/generate_enemies/generateRoadblock.sqf`
- `sunday_system/generate_enemies/generateBarrier.sqf`
- `sunday_system/generate_enemies/generateEmplacement.sqf`
- `sunday_system/generate_enemies/staggeredAttack.sqf`

Também auditar: `functions/fn_spawnGroupWeighted.sqf`, `functions/fn_spawnEnemyGarrison.sqf`, `functions/fn_spawnEnemyCompound.sqf` — esses são as funções CfgFunctions que os geradores chamam. Não alterar a lógica deles, apenas verificar se o grupo retornado já recebe dynamicSim (provavelmente não).

### Mudanças a aplicar

**1. Dynamic Simulation per grupo**

Em cada lugar onde um grupo é criado (via `createGroup` + `createUnit`, ou via `DRO_fnc_spawnGroupWeighted` que retorna grupo), adicionar logo após:
```sqf
if (dynamicSim != 1) then {
    _spawnedSquad enableDynamicSimulation true;
};
```

A global `dynamicSim` é setada em `start.sqf` via parâmetros da missão:
- `dynamicSim == 0` → sistema LIGADO (default) → aplicar per-group
- `dynamicSim == 1` → sistema DESLIGADO pelo jogador → NÃO aplicar

Aplique em TODOS os grupos sem exceção (infantaria, veículos, AA, artilharia — tudo). O jogador controla o toggle e assume a responsabilidade.

**ONDE aplicar:** o melhor ponto é DENTRO de `fn_spawnGroupWeighted.sqf`, logo antes do return, pois ~74 call sites passam por ali. Se o grupo é criado por `fn_spawnGroupWeighted`, marcar lá centraliza a lógica. Para grupos criados FORA dessa função (direto com `createGroup`), marcar no local.

Verificar também `fn_spawnEnemyGarrison.sqf` e `fn_spawnEnemyCompound.sqf` — esses criam grupos internamente e podem não passar por `spawnGroupWeighted`.

**2. Frame budgeting em forEach loops grandes**

Nos arquivos `generate*.sqf`, dentro de loops onde muitas unidades/grupos são spawnados em sequência, adicionar `uiSleep 0` (ou `sleep 0.001`) entre iterações pra liberar o frame:

```sqf
{
    // spawn one group
    _group = ...;
    // ...setup...

    uiSleep 0; // liberar frame entre iterações
} forEach _spawnPoints;
```

CUIDADO — `uiSleep`/`sleep` SÓ funciona em scheduled context (dentro de `spawn` ou `execVM`). ANTES de adicionar, verificar se o script roda em scheduled context:
- Se é chamado via `execVM` ou `spawn` → OK, pode usar `uiSleep 0`
- Se é chamado via `call` → NÃO pode usar sleep. Nesse caso, NÃO adicionar — anotar no relatório.

Para verificar: grep por quem chama o arquivo (ex: `grep -rn "generateEnemies" --include="*.sqf"`) e ver se usa `execVM`/`spawn` ou `call`.

**3. setGroupId pra debugging**

Em cada grupo criado nos geradores, adicionar ID pra rastreamento no .rpt:
```sqf
_spawnedSquad setGroupIdGlobal [format ["DRO_enemy_%1", floor random 10000]];
```

Isso é OPCIONAL e de baixa prioridade. Se complicar demais, skip e anote.

**4. Skill audit**

Verificar se algum gerador seta `setSkill` acima de 0.8. Se encontrar, NÃO alterar — apenas listar no relatório com o valor atual. A decisão de cap é do gerente.

Verificar também se `DRO_fnc_setSkillAction` (em `functions/fn_setSkillAction.sqf`) já faz cap de skill. Se sim, documentar.

### REGRAS

- NÃO toque em código marcado "// Migrated from ..." (Fase 1).
- NÃO toque em `start.sqf` (orquestrador master).
- NÃO toque em `generateEnemiesFunctions.sqf` (stub de deprecação, tem PFH da Fase 1).
- NÃO toque em `bleedout.sqf`, `fortify.sqf`, `protectCiv.sqf`, `heliExtract.sqf`, `setupPlayersFaction.sqf`.
- ABRA cada arquivo alvo e leia inteiro antes de aplicar mudanças. Entenda o flow.
- Use `DRO_fnc_*` para nomes de funções, NUNCA os nomes legados.
- Se encontrar `sleep` em contexto que pareça unscheduled, NÃO corrija neste módulo — apenas anote no relatório.

### REPORTE DE VOLTA (append em _DRO_REFACTOR_PROGRESS.md):

```
## M4 — Higiene de geradores IA — [DATA]

### Arquivos modificados
- generateEnemies.sqf: <mudanças>
- generateCompound.sqf: <mudanças>
- generateBunker.sqf: <mudanças>
- generateRoadblock.sqf: <mudanças>
- generateBarrier.sqf: <mudanças>
- generateEmplacement.sqf: <mudanças>
- staggeredAttack.sqf: <mudanças>
- fn_spawnGroupWeighted.sqf: <mudanças, se aplicável>
- fn_spawnEnemyGarrison.sqf: <mudanças, se aplicável>
- fn_spawnEnemyCompound.sqf: <mudanças, se aplicável>

### Mudanças por categoria
- enableDynamicSimulation true: N grupos cobertos (N centralizado em spawnGroupWeighted + N direto nos geradores)
- uiSleep 0 em forEach: N loops cobertos (listar quais)
- Loops onde NÃO aplicou uiSleep (unscheduled context): <lista>
- setGroupId: N grupos (ou SKIPPED)

### Skill audit
- fn_setSkillAction.sqf: <faz cap? qual valor?>
- Valores de setSkill encontrados nos geradores: <lista com arquivo:linha:valor>

### Descobertas inesperadas
- <sleeps em unscheduled context encontrados>
- <qualquer outro antipadrão>
- <qualquer bug latente encontrado>
```
````

---

### M5 — start.sqf decomposition (Fase 6 parcial)

**Cola tudo entre as marcas ```````` num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO:
- Fase 1 (CBA migration), M3 (CfgFunctions migration) e M4 (AI gen hygiene) já estão concluídas.
- Código marcado "// Migrated from ..." NÃO deve ser tocado — é da Fase 1.
- Todas as funções usam nomes `DRO_fnc_*`. Aliases legados existem em `init.sqf` mas estão depreciados.
- CfgFunctions está definido no final de `description.ext` — novas funções extraídas devem ser adicionadas lá.
- Funções ficam em `functions/fn_<name>.sqf` e são registradas como `class <name> {};` dentro de `class core { file = "functions"; ... }` no CfgFunctions.

TAREFA: Decompor o `start.sqf` (1352 linhas) em funções separadas pra reduzir tamanho e melhorar legibilidade. Apenas reorganizar — NÃO mudar comportamento.

### Estado atual

`start.sqf` é o orquestrador master da missão. Faz tudo: extração de facções, escolha de AO, geração de objetivos, civis, inimigos, clima, briefing, trigger de reforços, etc. É monolítico e difícil de navegar.

### Seções a extrair

As linhas abaixo foram verificadas no arquivo atual (pós-M3/M4). Leia o `start.sqf` inteiro antes de começar — confirme que as linhas batem.

1. **`fn_extractFactionData`** — linhas ~115-210. Coleta facções com unidades via CfgFactionClasses, filtra, popula `availableFactionsData` e `availableFactionsDataNoInf`, faz `publicVariable` de ambas.
   - Globals que seta: `availableFactionsData`, `availableFactionsDataNoInf`
   - Globals que lê: nenhuma (usa configFile)

2. **`fn_setupEnemySides`** — linhas ~513-552. Determina `enemySide` a partir de `enemyFaction`, resolve conflito se `playersSide == enemySide`, configura `sideFriendship` entre enemy sides.
   - Globals que seta: `enemySide` (publicVariable)
   - Globals que lê: `enemyFaction`, `playersSide`

3. **`fn_defineMarkerColors`** — linhas ~554-592. Setup de `markerColorPlayers`/`markerColorEnemy` e `colorPlayers`/`colorEnemy` baseado nas sides.
   - Globals que seta: `markerColorPlayers`, `markerColorEnemy`, `colorPlayers`, `colorEnemy` (todas publicVariable)
   - Globals que lê: `playersSide`, `enemySide`

4. **`fn_chooseMissionMusic`** — linhas ~668-746. Define arrays de música (day/night/extract + variantes VN), escolhe tracks baseado em timeOfDay e worldName.
   - Globals que seta: `musicMain`, `musicExtract`, `musicMainVNHeli`, `musicVNExtract`
   - Globals que lê: `timeOfDay`, `worldName`

5. **`fn_generatePlayerIdentities`** — linhas ~758-863. Extrai nomes/voices/faces de CfgWorlds/CfgVoice/CfgFaces, gera 24 identidades, aplica via remoteExec `DRO_fnc_setNameMP`.
   - Globals que seta: `nameLookup` (publicVariable), `pFacesArray`, `eFacesArray`, `initArsenal`
   - Globals que lê: `pGenericNames`, `pIdentityTypes`, `eIdentityTypes`, `playersSide`, `playerGroup`
   - CUIDADO: usa `_speakersArray` e `_firstNames`/`_lastNames` como locais — manter dentro da função.

6. **`fn_chooseObjectivesPOWClass`** — linhas ~894-945. Escolhe classe de POW (helicrew, engineers, journalists, etc) baseado em facção.
   - Globals que seta: `powClass`, `powType`
   - Globals que lê: `pFaction`, `pInfClasses`, config classes

7. **`fn_setupReinforcementTrigger`** — linhas ~1300-1311. Cria trigger de reforço baseado em presença de jogadores vs inimigos.
   - Globals que seta: nenhuma (trigger é local)
   - Globals que lê: `AOLocations`, `centerPos`, `enemySide`, `enemyCommsActive`, `stealthActive`, `grpNetId`

### Como extrair

Para CADA seção:

1. Criar `functions/fn_<name>.sqf` com o body extraído do start.sqf
2. Adicionar `class <name> {};` no bloco `class core { file = "functions"; ... }` do CfgFunctions em `description.ext`
3. No `start.sqf`, substituir o bloco extraído por `call DRO_fnc_<name>;` com um comentário indicando o que faz
4. NÃO adicionar aliases em `init.sqf` — essas funções são novas, não têm nomes legados

Exemplo de como o start.sqf deve ficar após extração:
```sqf
// --- Faction data extraction ---
call DRO_fnc_extractFactionData;

// ... código intermediário que NÃO foi extraído ...

// --- Enemy side setup ---
call DRO_fnc_setupEnemySides;

// --- Marker colors ---
call DRO_fnc_defineMarkerColors;
```

### Restrições

- NÃO mudar o comportamento — apenas reorganizar.
- NÃO toque em código marcado "// Migrated from ..." (Fase 1 / CBA).
- Manter a ORDEM DE EXECUÇÃO exata. A posição do `call` no start.sqf deve ser onde o bloco original estava.
- Variáveis que eram locais (`_var`) e são usadas APÓS a seção extraída precisam virar globais ou ser retornadas pela função. Documentar cada caso.
- Variáveis que eram locais e só eram usadas DENTRO da seção extraída continuam locais na nova função — sem mudança.
- Se uma seção usa `#define` macros do topo do start.sqf, copiar o `#define` pro novo arquivo (lição do M3 hotfix #1).
- ABRA o start.sqf inteiro e leia antes de extrair. As linhas indicadas acima são aproximadas — confirme visualmente.

### Objetivo final

`start.sqf` deve ficar significativamente menor e legível como uma sequência de chamadas de alto nível. Meta: ~400-700 linhas (de 1352).

### REPORTE DE VOLTA (append em _DRO_REFACTOR_PROGRESS.md):

```
## M5 — start.sqf decomposition — [DATA]

### Funções extraídas
- DRO_fnc_extractFactionData (linhas X-Y → fn_extractFactionData.sqf)
- DRO_fnc_setupEnemySides (linhas X-Y → fn_setupEnemySides.sqf)
- (etc, uma por linha)

### CfgFunctions
- N classes adicionadas ao bloco `class core` em description.ext

### start.sqf antes/depois
- Antes: 1352 linhas
- Depois: N linhas

### Variáveis que mudaram de escopo
- `_var` era local, agora global porque: <motivo>
- (listar TODAS — mesmo que zero)

### Macros copiados
- <macro> copiado para fn_<name>.sqf (ou: nenhum macro necessário)

### Pontos de atenção
- <qualquer função que tem dependência implícita não-óbvia em globals>
- <qualquer trecho que NÃO foi extraído e o motivo>
```
````

---

### M6 — Final audit + cleanup

**Cola tudo entre as marcas ```````` num novo prompt Sonnet:**

````
Você está trabalhando na missão Dynamic Recon Ops ACE - Livonia para Arma 3.

CAMINHO DA MISSÃO:
C:\Users\SujoG\Documents\Arma 3 - Other Profiles\R%2e%20Gonzalez\mpmissions\Dynamic Recon Ops ACE - Livonia.Enoch\

CONTEXTO:
- Todo o refactor foi feito em módulos anteriores: Fase 1 (CBA migration), M2 (bug fixes), M3 (CfgFunctions — 67 funções, 695 call sites), M3 hotfixes #1-#4, M4 (AI gen hygiene), M5 (start.sqf decomposition — 7 funções extraídas, 1352→939 linhas).
- Código marcado "// Migrated from ..." NÃO deve ser tocado — é da Fase 1.
- Todas as funções usam nomes `DRO_fnc_*`. Aliases legados em `init.sqf`.
- CfgFunctions no final de `description.ext`. Funções em `functions/fn_*.sqf`.
- Para contexto completo do que foi feito, leia `_DRO_REFACTOR_PROGRESS.md` na raiz da missão.

TAREFA: Auditoria final, cleanup de dead code, e correção de bugs pendentes. Este é o ÚLTIMO módulo do refactor.

---

### PARTE 1 — Verificações de integridade

**1.1. EH handlers do revive**
Verificar que `addEventHandler ["HandleDamage", ...]` e `["Killed", ...]` em `functions/fn_addReviveToUnit.sqf` apontam para os nomes CfgFunctions (`DRO_fnc_handleDamage`, `DRO_fnc_handleKilled`), NÃO para os nomes legados (`rev_handleDamage`, `rev_handleKilled`).

**1.2. briefingJIP**
Em `briefing.sqf`, verificar se a linha `remoteExec ["sun_briefingJIP", 0, true]` está comentada E se o path de JIP briefing ainda funciona (o alias `sun_briefingJIP = DRO_fnc_briefingJIP` em init.sqf cobre, mas confirmar que a chamada ativa usa o nome novo ou o alias).

**1.3. CfgRemoteExec**
Verificar se `description.ext` contém `class CfgRemoteExec` com `mode = 2`. Se SIM, adicionar à whitelist:
- `DRO_fnc_setNameMP`, `DRO_fnc_randomTime`, `DRO_fnc_briefingJIP`, `DRO_fnc_changeLocal`, `DRO_fnc_civDeathHandler`
Se NÃO tem CfgRemoteExec (esperado) → anotar no relatório que usa default (tudo permitido).

**1.4. Macros em fn_*.sqf**
Verificar que toda função em `functions/` que usa um macro tem o `#define` no próprio arquivo:
```bash
grep -rn "aliveVeh\(" functions/
grep -rn "^#define" functions/
```
M3 hotfix #1 já cobriu `fn_checkVehicleSpawn.sqf` e `fn_helicopterCanFly.sqf`. Verificar se M5 (7 funções novas) introduziu problema similar. Também grepar por QUALQUER outro macro usado sem `#define` local.

**1.5. Latent bug em fn_checkVehicleSpawn.sqf**
Linha 6 usa `_vehicleType` não declarado em params. Só dispara se hitHull >= 0.7 (raro em spawn fresco). Fix: adicionar `params [["_vehicle", objNull], ["_vehicleType", ""]]` no topo. Se a lógica de recreate for confirmadamente dead-path, remover o bloco inteiro.

**1.6. Guards de DRO_fnc_spawnGroupWeighted**
A função retorna `grpNull` em falha (não nil). M3 hotfix #2 corrigiu `fn_spawnEnemyGarrison.sqf`. Auditar os outros call sites:
```bash
grep -rn "DRO_fnc_spawnGroupWeighted" --include="*.sqf"
```
Cada call site que usa `units _group` na sequência DEVE ter guard: `if (!isNull _group && {count (units _group) > 0}) then { ... }`. Listar no relatório os que precisam de guard e corrigir os mais críticos (geradores de inimigos, objetivos). Call sites em código comentado ou archive → ignorar.

**1.7. Guards de DRO_fnc_selectRemove**
M3 hotfix #3 identificou 3 call sites em `reinforce.sqf` (linhas ~115, ~155, ~194) que precisam de guard contra array vazio (retorno `objNull`). Corrigir: adicionar `if (isNull _vehType) exitWith {}` ou similar após cada chamada. Também verificar `generateAO.sqf:25,35` (risco baixo mas flagged).

---

### PARTE 2 — Audit de antipadrões

**2.1. Antipadrões remanescentes**
```bash
grep -rn "while {true}" --include="*.sqf"
grep -rn "spawn {" --include="*.sqf" | grep -i "sleep"
grep -rnE "waitUntil\s*\{[^}]*sleep" --include="*.sqf"
```
Para cada match, classificar:
- Dentro de comentário `//` ou `/* */` → OK, ignorar
- Dentro de `_archive/` → OK, ignorar
- Código ativo real → FLAG pra revisão (listar no relatório)

**2.2. PFH guards (double-init)**
```bash
grep -rn "DRO_.*PFH" --include="*.sqf"
grep -rn 'if (!isNil "DRO_' --include="*.sqf"
```
Cada PFH (`DRO_xxxPFH`) deve ter guard `if (!isNil "DRO_xxxPFH") exitWith { ... }` antes da criação. Listar os que NÃO têm.

**2.3. removePerFrameHandler em PFHs auto-removentes**
```bash
grep -rn "addPerFrameHandler" --include="*.sqf"
```
Cada PFH deve ter `removePerFrameHandler` no body (auto-removente) OU ser forever (sem exit). Listar possíveis leaks.

---

### PARTE 3 — Dead code cleanup

**3.1. Mover para `_archive/`** (NÃO deletar — manter rollback possível):

- `sunday_revive/AIReviveListen.sqf` — dead code confirmado na Fase 1 (única referência comentada em initRevive.sqf:120)
- `sunday_system/supports/supportCASHeliOld.sqf` — dead code confirmado na Fase 1 (sem callers)

Adicionar header em cada arquivo movido:
```sqf
// ARCHIVED — não está em uso. Movido em [DATA] durante M6 final audit.
```

**3.2. Lib stubs**
Os 5 stubs de deprecação (`sundayFunctions.sqf`, `droFunctions.sqf`, `menuFunctions.sqf`, `reviveFunctions.sqf`, `generateEnemiesFunctions.sqf`) — MANTER como estão. São inofensivos e servem de documentação do que existia ali. NÃO deletar.

**3.3. Aliases em init.sqf**
MANTER os 110 aliases. Adicionar header explicativo no topo do bloco de aliases:
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

---

### PARTE 4 — Bug pendente: rev_changeLocal EH leak

**Arquivo:** `functions/fn_changeLocal.sqf` (migrado de `rev_changeLocal` em reviveFunctions.sqf)

**Problema:** cada vez que a localidade de uma unidade AI muda, `fn_changeLocal` adiciona um novo `addEventHandler ["Respawn", ...]` via remoteExec SEM remover o anterior. N mudanças de localidade = N Respawn handlers acumulados. Cada handler interno adiciona HandleDamage + Killed sem cleanup → leak duplo.

**Fix recomendado:**
Antes de adicionar o novo Respawn EH, remover o anterior via tracking por setVariable:
```sqf
// No início do fn_changeLocal, antes de adicionar novo Respawn EH:
private _oldRespawnId = _unit getVariable ["DRO_revRespawnHandlerId", -1];
if (_oldRespawnId >= 0) then {
    _unit removeEventHandler ["Respawn", _oldRespawnId];
};

// Após adicionar:
private _newId = _unit addEventHandler ["Respawn", { ... }];
_unit setVariable ["DRO_revRespawnHandlerId", _newId, true];
```

**CUIDADO de locality:** o Respawn EH em `fn_changeLocal` é adicionado via `remoteExec` na máquina que ganhou localidade da unidade. O Respawn EH em `fn_addReviveToUnit` é adicionado diferentemente (no servidor). Verificar que `removeEventHandler` no `fn_changeLocal` só remove o handler que ELE adicionou, não o do `fn_addReviveToUnit`. O tracking via `DRO_revRespawnHandlerId` garante isso (cada um rastreia seu próprio ID).

Se a análise de locality mostrar que é mais seguro NÃO corrigir agora, documentar no relatório com o motivo e deixar como NOTED.

---

### PARTE 5 — Cleanup de TODO/FIXME

```bash
grep -rnE "TODO|FIXME|XXX|HACK" --include="*.sqf"
```
Para cada match:
- Se trivial e seguro: resolver agora
- Se relevante mas complexo: anotar no relatório como NOTED
- Se obsoleto (referência a algo já corrigido): remover o comentário

---

### REGRAS

- NÃO toque em código marcado "// Migrated from ..." (Fase 1).
- NÃO toque em `bleedout.sqf` (reescrito inteiro na Fase 1, delicado).
- NÃO delete arquivos — mova para `_archive/`.
- Use `DRO_fnc_*` para nomes de funções.
- LEIA cada arquivo inteiro antes de modificar.
- Se encontrar algo que não tem certeza se deve corrigir, NÃO corrija — anote no relatório.

### REPORTE DE VOLTA (append em _DRO_REFACTOR_PROGRESS.md):

```
## M6 — Final audit + cleanup — [DATA]

### PARTE 1 — Verificações de integridade
- 1.1 EH handlers revive: [OK / FIXED — detalhes]
- 1.2 briefingJIP: [OK / FIXED — detalhes]
- 1.3 CfgRemoteExec: [NÃO EXISTE (default) / WHITELISTED]
- 1.4 Macros em fn_*.sqf: [OK — N macros verificados / FIXED — detalhes]
- 1.5 fn_checkVehicleSpawn.sqf: [FIXED / NOTED — motivo]
- 1.6 spawnGroupWeighted guards: N call sites auditados, N precisam fix, N corrigidos
- 1.7 selectRemove guards (reinforce.sqf): [FIXED / NOTED]

### PARTE 2 — Audit de antipadrões
- while {true} reais (não-comentário): N (lista ou "0")
- spawn+sleep reais: N (lista ou "0")
- waitUntil+sleep reais: N (lista ou "0")
- PFHs com guard: N / total N. Sem guard: <lista ou "nenhum">
- PFHs auto-removentes OK: N. Possíveis leaks: <lista ou "nenhum">

### PARTE 3 — Dead code cleanup
- AIReviveListen.sqf: MOVED to _archive/
- supportCASHeliOld.sqf: MOVED to _archive/
- Lib stubs: MANTIDOS
- Aliases init.sqf: MANTIDOS + header adicionado

### PARTE 4 — rev_changeLocal EH leak
- Status: [FIXED / NOTED — motivo]
- Se FIXED: estratégia usada, side effects considerados
- Se NOTED: análise de locality, motivo pra não corrigir agora

### PARTE 5 — TODO/FIXME cleanup
- arquivo.sqf:LINHA — descrição — [RESOLVED / NOTED / REMOVED]
- (etc)

### Estado final do projeto
- Fase 1 (CBA migration): ✅
- M2 (bug fixes): ✅
- M3 (CfgFunctions): ✅ + 4 hotfixes
- M4 (AI gen hygiene): ✅
- M5 (start.sqf decomposition): ✅
- M6 (final audit): ✅
- Bugs de gameplay pendentes: HVT spawn fora do mapa (não é bug de refactor)
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
