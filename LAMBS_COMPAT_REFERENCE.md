# LAMBS Danger FSM — Referência de comportamento p/ compatibilidade "soft"

> Documento de referência para implementar compat opcional com o mod **LAMBS Danger FSM**
> (nk3nny) em missões Arma 3. Baseado no wiki oficial + leitura do código-fonte do mod.
> Objetivo: usar recursos do LAMBS **apenas se o mod estiver carregado**, sem criar dependência.

---

## 1. Fatos base

- **Dependência do mod:** LAMBS exige apenas **CBA** (`requiredAddons[] = {"cba_main"}`). ACE é opcional pra ele. Não força carregamento de nada além de CBA.
- **Classes CfgPatches** (usar para detecção):
  - `lambs_main` — núcleo do mod (presença geral).
  - `lambs_danger` — a danger.fsm (estados de combate, reforço).
  - `lambs_wp` — módulo das funções de waypoint/tarefa (`lambs_wp_fnc_*`).
  - outras: `lambs_suppression`, `lambs_turrets`, `lambs_cover`.
- **Quando o LAMBS "roda":** a danger.fsm dispara quando a **IA está em modo combate**. IA fora de combate não gera os eventos abaixo.
- **Ativação por padrão:** o LAMBS liga sozinho em toda IA elegível quando o mod está carregado. **Não há variável de opt-in para ATIVAR**; existem variáveis para **DESATIVAR** (ver §5).
- **Localidade:** todos os eventos LAMBS são **locais à unidade**. Funções `taskX`/waypoints **devem rodar onde a IA é local e a IA deve permanecer nesse cliente** — quebra com Headless Client + load-balancing dinâmico. Para IA spawnada server-side que fica server-local, executar no servidor é o correto.

---

## 2. Detecção (o "check de existência")

Padrão recomendado: computar flags em cache **uma vez por máquina**, cedo (ex.: `init.sqf`, que roda em servidor + cada cliente + JIP, antes de initServer/initPlayerLocal/start). `CfgPatches` é local à máquina mas **determinístico** (o MP força mods idênticos em todos os clientes), então **não precisa de `publicVariable`** e o JIP funciona automático.

```sqf
DRO_lambsLoaded = isClass (configFile >> "CfgPatches" >> "lambs_main");
DRO_lambsWP     = isClass (configFile >> "CfgPatches" >> "lambs_wp");
```

Cada call site que usa recurso LAMBS lê a global (`if (DRO_lambsLoaded) then { ... }`) — leitura O(1), "checado toda vez". Sem o mod, nada executa; o fluxo vanilla fica intacto.

**Master toggle opcional (param de lobby):** para permitir ligar/desligar a integração no lobby:
```sqf
DRO_lambsCompat = DRO_lambsLoaded && ((["DRO_ParamLambsReinforce", 1] call BIS_fnc_getParamValue) == 1);
```
Assim a integração só age se o param estiver Enabled **E** o mod carregado. Mantenha `DRO_lambsLoaded` cru separado, para gatear recursos que dependem só da presença do mod.

---

## 3. Eventos do LAMBS (são NOTIFICAÇÕES, não comandos)

Os eventos abaixo são **disparados pelo mod** (CBA events, locais à unidade). Você se inscreve via `CBA_fnc_addEventHandler` para **reagir** a eles. **Disparar o evento você mesmo NÃO produz o comportamento** — ex.: emitir `lambs_danger_OnReinforce` só chama seus próprios handlers, não faz IA reforçar.

| Evento | Args | Quando dispara | Precisa de variável? |
|---|---|---|---|
| `lambs_danger_OnContact` | `_unit, _group, _target` | líder faz o 1º contato | não (default-on em combate) |
| `lambs_danger_OnAssess` | `_unit, _group, _enemies` | líder avalia a situação (periódico) | não (default-on em combate) |
| `lambs_main_OnInformationShared` | `_unit, _group, _target, _groups` | unidade compartilha info de inimigo com grupos amigos | não (default-on) — **é o gatilho do reforço** |
| `lambs_danger_OnReinforce` | `_unit, _group, _target` | grupo **inicia** manobra de reforço | **sim** — só dispara em grupo com `enableGroupReinforce` |
| `lambs_main_OnCheckBody` | `_unit, _group, _body` | unidade checa um corpo | não |
| `lambs_danger_OnArtilleryCalled` | `_unit, _group, _gun, _targetPos` | líder chama artilharia | não |
| `lambs_main_OnPanic` | `_unit, _group` | unidade entra em pânico | não |
| `lambs_main_OnFleeing` | `_unit, _group` | unidade entra em fuga | não |

Uso (reagir a um evento):
```sqf
["lambs_danger_OnReinforce", {
    params ["_unit", "_group", "_target"];
    // sua lógica de missão (log, escalar, spawnar onda extra, etc.)
}] call CBA_fnc_addEventHandler;
```
> ⚠️ O wiki é **inconsistente** no nome do evento de reforço: a tabela diz `lambs_danger_OnReinforce`, mas a seção "Reinforcements" escreve `lambs_main_onReinforce`. **Confirme a string exata no código do mod ou via `diag_log` antes de depender dela.**

---

## 4. Sistema de REFORÇO (opt-in por grupo)

Reforço no LAMBS é **emergente e opt-in por grupo**, não um comando pontual.

```sqf
_group setVariable ["lambs_danger_enableGroupReinforce", true, true];
```

- **Grupo COM a flag:** ao receber um `OnInformationShared` de um aliado no alcance de rádio, **move-se ao contato** (ou a quem pediu ajuda), com reorganização pré-combate (muda formação, dispara sinalizador, empacota/desempacota estáticas). É esse grupo — e só ele — que dispara `OnReinforce`.
- **Grupo SEM a flag** (mesmo recebendo a info): só fica **ciente** (ganha knowsAbout), **permanece na tarefa**. Não se desloca para ajudar.
- **Diferença-chave:** receber a chamada = ficar ciente (todos no alcance); ter a flag = converter ciência em **manobra de reforço**.
- **Limitação:** é **probabilístico** — depende da chamada CHEGAR (ver §6) e do FSM decidir. Não há garantia de timing.
- Aviso do wiki: o reforço **pode sobrescrever waypoints existentes** do grupo conforme o contexto.

### Reforço DIRIGIDO (controle explícito de timing)
Se você precisa **forçar** reforço num momento/posição específicos, **não** use a flag/eventos — chame as `taskX` diretamente no grupo escolhido (ver §7). A flag é para ambiente orgânico; as `taskX` são para controle da missão.

---

## 5. Variáveis de unidade/grupo (do wiki)

| Variável | Alvo | Efeito |
|---|---|---|
| `lambs_danger_enableGroupReinforce` (bool, global) | grupo | grupo responde a chamadas de reforço (§4) |
| `lambs_danger_disableGroupAI` (bool) | grupo | desliga a camada de IA tática do grupo (artilharia, assaltos coordenados, esconder de veículos, remanejar estáticas, comunicação extra-grupo) |
| `lambs_danger_disableAI` (bool) | unidade | desliga o FSM individual (entrar em prédios, estados de reação, pânico, etc.) |
| `lambs_danger_dangerFormation` (string, ex "FILE") | grupo | muda formação no evento 'Contact' |
| `lambs_danger_dangerRadio` (bool) | unidade | estende o alcance de compartilhamento para "rádio" (ver §6) |
| `lambs_danger_isExecutingTactic` (leitura) | grupo | se o grupo executa uma tática de grupo agora |
| `lambs_danger_contact` (leitura) | grupo | duração do estado de contato |
| `lambs_main_currentTarget` / `lambs_main_currentTask` (leitura) | unidade | alvo/tarefa atuais |
| `lambs_main_currentTactic` (leitura) | grupo | tática atual |

> **Nota:** a variável de grupo pré-2.0 `lambs_code` está **defunta/deprecada** — substituída pelos eventos CBA.

---

## 6. Compartilhamento de informação e ALCANCE (crítico p/ reforço)

Fonte: `addons/main/functions/fnc_getShareInformationParams.sqf`.

- Compartilhar info é **nativo** (toda IA em combate). O `OnInformationShared` dispara por padrão, sem variável.
- **Alcance-base por lado:** definido nas Addon Options do LAMBS (CBA settings) — `radioWest` / `radioEast` / `radioGuer`. Todo grupo compartilha dentro desse alcance, mesmo sem rádio.
- **`dangerRadio` NÃO liga o compartilhamento — ele ESTENDE o alcance.** Soma o bônus `radioBackpack` (Addon Option) ao alcance-base e reposiciona a origem do report para a unidade que porta o rádio.
- **Como o mod decide se um grupo "tem rádio de longo alcance":** varre os membros do grupo (a até 150m da unidade que compartilha, vivos, não-player) e procura o **primeiro** que satisfaça QUALQUER:
  1. `_x getVariable ["lambs_danger_dangerRadio", false]` — flag manual do mission maker;
  2. `"b_radiobag_01_" in (toLowerANSI backpack _x)` — mochila-rádio de longo alcance vanilla (`B_RadioBag_01_*`);
  3. `getNumber (configFile >> "CfgVehicles" >> (backpack _x) >> "tf_hasLRradio") == 1` — mochila LR do **TFAR**.
- **Rádio de mão (`ItemRadio`) NÃO conta.** É especificamente mochila de longo alcance.
- **Conclusão prática:** `dangerRadio=true` numa unidade equivale a "finja que ela tem mochila-rádio LR". Grupos cujo loadout não inclui mochila-rádio operam só no alcance-base. Para reforço em **escala de AO**, os **reportantes** precisam de `dangerRadio` (ou mochila-rádio) **E** os **respondentes** precisam de `enableGroupReinforce`.

---

## 7. Funções de waypoint / tarefa (`lambs_wp_fnc_*`)

Módulo `lambs_wp`. **Executar onde a IA é local** (ver §1). Chamáveis via `call` ou `spawn` conforme o exemplo.

| Função | Efeito | Assinatura resumida |
|---|---|---|
| `taskGarrison` | ocupa posições de prédio + estáticas num raio; estático até gatilho | `[grp, pos/obj, range, area, teleport, sortByHeight, exitCond, subPatrol]` |
| `taskPatrol` | patrulha dinâmica simples (infantaria) | `[grp, pos, range(200), wpCount(4), area, dynamic, dynReinforce, teleport]` |
| `taskDefend` | defende posição a partir de prédios/cobertura; não sai da área | `[grp, pos, range(75), area, teleport, useTreesRocks, ambush, subPatrol]` |
| `taskCamp` | comportamento de acampamento (patrulhas, estáticas, garrison parcial) | `[grp, pos, range(50), area, teleport, partialPatrol]` |
| `taskCQB` | limpa prédios metodicamente num raio | `[grp, pos, range(50), delay(21), area, isWaypoint]` |
| `taskRush` | corre agressivo até players no alcance (entra em prédios) | `[grp, range(500), delay(15), area, center, onlyPlayers]` |
| `taskHunt` | patrulha LRRP que fecha no player mais próximo | `[grp, range(500), delay, area, center, onlyPlayers, dynReinforce, flare]` |
| `taskCreep` | stalk furtivo até os players | `[grp, range(500), delay, area, center, onlyPlayers]` |
| `taskAssault` | assalto/rush a uma posição (com opção de retirada forçada) | `[unit, dest, forcedRetreat, distThreshold(10), updateCycle(2), isWaypoint]` |
| `taskArtillery` | ataque de artilharia numa posição | `[artUnit, targetPos, caller, rounds(3-7), dispersion(100), skipCheck]` |
| `taskArtilleryRegister` | registra unidades como peças de artilharia | `[grp/unit]` |
| `taskReset` | reseta unidades (cancela garrison/waypoints/animações) | `[grp, softReset, resetWaypointsInSoft]` |

Exemplos:
```sqf
[bob, bob, 50] call lambs_wp_fnc_taskGarrison;
[bob, getPos angryJoe] spawn lambs_wp_fnc_taskAssault;
[bob, 500] spawn lambs_wp_fnc_taskHunt;
```

Parâmetro **`area`** (quando presente): `[a, b, angle, isRectangle, c]` — meia-largura X, meia-largura Y, ângulo, é retângulo?, meia-altura Z (definição de área padrão do Arma).

---

## 8. Receita de compat "soft" (resumo aplicável)

1. **Detecção** em `init.sqf`: `DRO_lambsLoaded` / `DRO_lambsWP` (+ opcional `DRO_lambsCompat` com param de lobby).
2. **Gatear TODA chamada LAMBS** por essas flags (`if (DRO_lambsCompat) then { ... }`). Sem o mod → nada executa, vanilla intacto.
3. **Responders (móveis):** nos grupos que devem responder ao reforço (ex.: patrulhas), setar `enableGroupReinforce=true`. Ponto de inserção ideal = choke point único onde todos os grupos-alvo passam.
4. **Broadcasters (ancorados):** nos grupos que fazem 1º contato e ficam presos a objetivo/POI (guarnições, camps, checkpoints), setar `dangerRadio=true` **no líder** — para o alarme alcançar os responders distantes. (Só no líder é suficiente; se o líder morre, o grupo perde o broadcaster — aceitável.)
5. **Não dar rádio a grupos móveis** se quiser preservar gameplay de recon/stealth (patrulhas mudas = abatíveis em silêncio; tocar num objetivo guarnecido escala).
6. **Reforço dirigido** (timing específico): usar `taskRush`/`taskAssault`/`taskHunt` diretamente, não a flag.
7. **Localidade:** setVariable e taskX no lado onde a IA é local (servidor, para IA server-local). Cuidado com HC + load-balancing.
8. **Alcance:** conferir `radioWest/East/Guer` + `radioBackpack` nas Addon Options — definem se o reforço alcança o AO.

---

## 9. Armadilhas conhecidas

- Não "forçar" reforço disparando `OnReinforce` — é notificação, não comando.
- `enableGroupReinforce` sozinho não basta: sem alcance de chamada (proximidade ou `dangerRadio`), o grupo nunca é convocado.
- Nome do evento de reforço divergente no wiki — **confirmar no código**.
- `taskX` em contexto de IA não-local (ou que migra de owner) quebra.
- Valores de alcance são Addon Options do usuário — não assumir; validar in-game.

---

*Fontes: wiki oficial nk3nny/LambsDanger (Home, Event handlers, variables, waypoints) + `addons/main/functions/fnc_getShareInformationParams.sqf` e `addons/main/XEH_PREP.hpp`.*
