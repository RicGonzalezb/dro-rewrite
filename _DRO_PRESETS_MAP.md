# DRO — Mapa dos modos de jogo (Presets): RECON OPS · SNIPER OPS · COMBINED ARMS

> Documento de referência estrutural. Foco: **como cada preset povoa o mapa, calcula/ocupa AOs, e lida com objetivos**.
> Objetivo: ter a estrutura mapeada para começar a alterar a construção desses modos.
> Base: leitura do código em 2026-07-04 (verificar linhas antes de editar — podem mover).

---

## 0. TL;DR — o que muda entre os três

| Eixo | RECON OPS (1) | SNIPER OPS (2) | COMBINED ARMS (3) |
|---|---|---|---|
| **Força inimiga** (`aiMultiplier`) | **x1.0** | **x0.5** (metade) | **x1.25** |
| **Infantaria de patrulha** | normal | normal (x0.5) | **cap de 1 grupo** + blindados |
| **Blindados inimigos** (APC/tanque) | não | não | **sim** (APCs + tanques) |
| **Stealth** | RANDOM | **forçado ON** | forçado OFF (runtime) |
| **Nº de objetivos** | RANDOM (1–3) | **1** | RANDOM (1–3) |
| **Objetivo preferido** | nenhum (qualquer) | **HVT** | nenhum (qualquer) |
| **HVT** | regular ± evidência | **só eliminação, sem evidência** | regular ± evidência |
| **Tarefa reativa** | HVT ou VEHICLE | **só HVT** | HVT ou VEHICLE |
| **Esquadra do player** | padrão | **sniper + spotter** (2 slots) | padrão (4 slots) |
| **Veículos no lobby** | carros + heli | carros + heli | **+APC +tanque +arty** |
| **AI amigo / apoio** | não | não | **sim** (esquadras + comando "Engage") |
| **Time of day (default UI)** | RANDOM | MIDDAY/AFTERNOON | RANDOM |

**Leitura de uma frase:**
- **RECON OPS** = a experiência baseline do DRO (força cheia, stealth possível, objetivo qualquer).
- **SNIPER OPS** = versão enxuta e furtiva: metade dos inimigos, esquadra de 2 (atirador+observador), stealth ligado, foco em caçar HVT.
- **COMBINED ARMS** = batalha aberta: mais inimigos, blindados dos dois lados, AI amigo, sem stealth, menos patrulha de infantaria a pé (substituída por veículos).

---

## 1. Onde o preset vive no código

### 1.1 A global `missionPreset`
É um **índice inteiro** carregado no boot e broadcast:

- `loadProfile.sqf:49-50` — lê do profileNamespace (`DRO_missionPreset`, default `0`) + `publicVariable`.
- `loadParams.sqf:54-55` — se o override de lobby (M9) estiver ativo, sobrescreve via param `DRO_ParamPreset` + `publicVariable`.

Valores: `0` = CURRENT SETTINGS (usa o que estiver nos sliders), `1` = RECON OPS, `2` = SNIPER OPS, `3` = COMBINED ARMS.
(Fonte dos rótulos: `functions/fn_switchLookup.sqf`.)

**Ponto-chave:** `missionPreset` NÃO é só um botão de "aplicar defaults". O valor do índice **sobrevive em runtime** e é consultado diretamente em vários geradores (`if (missionPreset == N)`). Ou seja, o preset tem dois papéis:
1. **UI-time** (`fn_missionPreset.sqf`) — ajusta os sliders/toggles quando você seleciona o preset no diálogo.
2. **Run-time** — ramifica o comportamento dos geradores independentemente dos sliders.

### 1.2 `fn_missionPreset.sqf` — os defaults de UI que cada preset aplica
`functions/fn_missionPreset.sqf` (`DRO_fnc_missionPreset`) roda quando o preset é escolhido no diálogo `sundayDialog` (via `fn_switchButton.sqf:20`, ação `"PRESET"`). Ele mexe nos controles:

| Controle | Significado | RECON (1) | SNIPER (2) | COMBINED (3) |
|---|---|---|---|---|
| slider **2041** / `aiMultiplier` | força inimiga | x1.0 | **x0.5** | **x1.25** |
| **2020** `aoOptionSelect` | Extended AO | Enabled | Enabled | Enabled |
| **2050** `minesEnabled` | Minefields | Disabled | Disabled | Disabled |
| **2060** `civiliansEnabled` | Civilians | Random | Random | Random |
| **2070** `stealthEnabled` | Stealth | Random | **Enabled** | Random |
| **2103** `timeOfDay` | hora | Random | **selectRandom [3,4]** (midday/afternoon) | Random |
| **2106** / **4010** `numObjectives` | nº objetivos | Random | **1** | Random |
| `preferredObjectives` | pool de objetivos | `[]` | **`["HVT"]`** | `[]` |

> Nota: preset `0` (CURRENT SETTINGS) não passa por esse switch — mantém o que o jogador ajustou manualmente. Em runtime, `missionPreset==0` não casa com nenhum `if`, então pega o caminho "padrão" (= igual a RECON na maioria das ramificações).

---

## 2. Como o mapa é POVOADO (inimigos)

Arquivo central: **`sunday_system/generate_enemies/generateEnemies.sqf`**.
Chamado por AO em `start.sqf` (~linha 788: `[_AOindex, "REGULAR"] execVM ".../generateEnemies.sqf"`), um script por AOLocation.

### 2.1 Os dois multiplicadores de quantidade
Toda contagem de spawn é `base_aleatória * aiMultiplier * _sizeMod`:

- **`aiMultiplier`** — vem do preset (0.5 / 1.0 / 1.25) ou do slider. É o botão global de "quantos inimigos".
- **`_sizeMod`** (`generateEnemies.sqf:12-16`) — `REGULAR`=1, `SMALL`=0.4. Hoje todas as chamadas usam `"REGULAR"`, então `_sizeMod=1` na prática (o caminho SMALL existe mas está dormente).

### 2.2 O que é spawnado, e a fórmula de cada tipo
Tudo em `generateEnemies.sqf`:

| Elemento | Linha | Fórmula de contagem | Observação |
|---|---|---|---|
| **Garrisons de prédio (1º AO)** | 20-30 | `localBuildingPatrol(8*_sizeMod)` + garrison em `milBuildings` com chance>0.3 | só quando `_AOIndex==0` (varre a área inteira uma vez) |
| **Garrisons extra do AO** | 37-45 | `randInt[4,6] * aiMultiplier * _sizeMod`, cap = nº de prédios | ocupam `buildings` (índice 7 da AOLoc) |
| **Patrulhas de infantaria** | 56-79 | `randInt[1,3] * aiMultiplier * _sizeMod` + `floor(nºplayers/2)` | **COMBINED cap de 1** (linha 59) |
| **APCs (COMBINED)** | 84-107 | `randInt[2,3]` | só `missionPreset==3` |
| **Tanques (COMBINED)** | 108-132 | `randInt[1,3]` | só `missionPreset==3`, com `taskObjective` |
| **Patrulha de carro** | 136-161 | chance>0.4 → `randInt[1,2] * _sizeMod` | todos os presets |
| **Roadblocks** | 166-175 | `randInt[2,3] * aiMultiplier * _sizeMod` | via `AO_POIs` |
| **Bunkers** | 176-185 | `randInt[1,2] * aiMultiplier * _sizeMod` | via `AO_POIs` |
| **Camps** | 186-219 | `randInt[2,4] * aiMultiplier * _sizeMod` | LAMBS `dangerRadio` no líder |
| **Emplacements** | 220-229 | `randInt[1,2] * aiMultiplier * _sizeMod` | via `AO_POIs` |
| **Barrier** | 230-234 | 1 se `_sizeMod>0.5` | via `AO_POIs` |

Tamanho de cada grupo de infantaria também escala com `aiMultiplier` (ex.: linha 70-71: `_minAI`/`_maxAI` derivam de `aiMultiplier`).

### 2.3 As duas ramificações de preset na população
Só **COMBINED ARMS (3)** ramifica aqui:

1. **`generateEnemies.sqf:59`** — `if (missionPreset == 3) then {_numInf = _numInf min 1};`
   → COMBINED reduz patrulhas de infantaria a pé para no máximo 1 grupo por AO. A ideia é substituir infantaria dispersa por presença blindada.

2. **`generateEnemies.sqf:81-133`** — bloco inteiro `if (missionPreset == 3)`:
   → adiciona **APCs** (`eAPCClasses`, randInt[2,3]) e **tanques** (`eTankClasses`, randInt[1,3]), cada um com tripulação (`createVehicleCrew`) e esquadra de reforço embarcada (`groupToVehicle`). Tanques recebem `unitTaskObjective` (patrulha/objetivo).

**RECON (1) e SNIPER (2) não têm ramo próprio aqui** — a diferença entre eles é puramente o `aiMultiplier` (1.0 vs 0.5) que o preset setou. Sniper = mesma composição do recon, metade da quantidade.

### 2.4 Comportamento pós-spawn (patrulhamento)
`generateEnemies.sqf:240-305` — grupos móveis (`_patrolGroups`) recebem waypoints de rota entre posições de viagem coletadas (`_availableTravelPositions` + `travelPosPOIMil`). Grupos ancorados (garrisons, camps) ficam presos. LAMBS: patrulhas móveis viram *responders* de reforço (`enableGroupReinforce`), camps viram *broadcasters* (`dangerRadio`). **Isso é preset-agnóstico.**

---

## 3. Como os AOs são CALCULADOS e OCUPADOS

Arquivo central: **`sunday_system/generate_ao/generateAO.sqf`**.
**Importante: a geração de AO é 100% preset-agnóstica** — nenhum `missionPreset` aqui. Os três modos calculam AO igual. O que varia por preset é a *densidade de inimigos* (seção 2), não a *geografia*.

### 3.1 Seleção do AO primário (`generateAO.sqf:12-58`)
- `aoSize = 1200` (fixo, hardcoded na linha 12).
- Se não há marcador custom (`aoSelectMkr` vazio): pega uma `nearestLocations` aleatória do mapa inteiro entre tipos `NameLocal/Village/City/CityCapital/Airport/Strategic/StrongpointArea`, rejeitando as coladas na borda do mapa ou a <700m do `logicStartPos`.
- Se há marcador custom (jogador escolheu no mapa): usa a location mais próxima do clique.
- Guard anti-loop-infinito (linha 40-42, fix de 2026-07-03): se o pool drenar, cai pra `nearestLocation`.

### 3.2 AOs secundários (`generateAO.sqf:61-75`)
- Só se **`aoOptionSelect == 0`** ("Extended AO" ligado — que TODOS os presets ligam via UI).
- `nearestLocations` num raio de 2800m do centro, filtradas por distância > `aoSize*0.4`.
- Adiciona **1 a 5** locations secundárias (`size` fixo 1200 cada), pulando as <1000m do `logicStartPos`.

### 3.3 Estrutura de dados `AOLocations`
Cada elemento de `AOLocations` é um array:

```
[0] = centro (pos)
[1] = tamanho (1200)
[2] = dados de posição (sub-array, ver abaixo)   ← gerado por DRO_fnc_generateAOLoc
[3] = "ROUTE" ou dado de água (checkRouteWater)
[4] = neutral flag (0 = hostil, 1 = neutro/civil)
[5] = location (nearestLocation)
[6] = trigger
```

O sub-array `[2]` (dados de posição) é indexado assim (fonte: `generateAO.sqf:339-352`):
```
0 = roads close       5 = flat pos far
1 = roads far         6 = forest
2 = ground pos close  7 = buildings
3 = ground pos far    8 = helipads
4 = flat pos close
```
**Esses índices são a "matéria-prima" de onde tudo é spawnado** — tanto inimigos (garrisons usam [7], camps usam [6]/[9]) quanto objetivos (seção 4). Ao alterar a construção, é aqui que se decide "o que cabe onde".

### 3.4 AO neutro vs hostil (`generateAO.sqf:230-297`)
- `_neutralChance` = 1 se `neutralTasksChosen`, 0 se `noNeutralTasksChosen`, senão `count AOLocations * 0.08`.
- Cada AO sorteia: se vira **neutro** (`[4]=1`), recebe objetivos civis (DISARM, FORTIFY, PROTECTCIV); se **hostil** (`[4]=0`), recebe objetivos de combate. Depois do primeiro neutro, `_neutralChance` zera (no máx. 1 neutro).
- POIs do AO (`AO_POIs`, linha 116-119): sorteia 2-4 tipos de `AO_POITypes` (MARKET, HOUSE, e os militares ROADBLOCK/BUNKER/CAMP/EMPLACEMENT/BARRIER consumidos pelo generateEnemies).

### 3.5 "Destroy city" ambiental (`generateAO.sqf:299-331`)
Chance 15% (`_destroyChance > 0.85`) de um AO nascer parcialmente destruído (crateras, wrecks, `BIS_fnc_destroyCity`). Cosmético, preset-agnóstico.

---

## 4. Como os OBJETIVOS são escolhidos e tratados

### 4.1 Quantos objetivos (`start.sqf:565-595`)
- `_numObjs` = `numObjectives`, ou `randInt[1,3]` se `numObjectives==0`.
- SNIPER seta `numObjectives=1` via UI → sempre 1 objetivo.
- Loop: 1º objetivo sempre no AO índice 0; os demais em AOs aleatórios (`start.sqf:588-595`), cada um via `DRO_fnc_selectObjective` (= `objSelect.sqf`).
- Guard de timeout de 90s (linha 600-604) evita travar na câmera se um objetivo não puder ser colocado.

### 4.2 O seletor de objetivos (`sunday_system/objectives/objSelect.sqf`)
Fluxo (preset-agnóstico na maior parte):

1. **Constrói pools de estilo por AO** (linhas 37-179): pra cada AOLocation, olha quais posições existem (`[2]` sub-índices) e monta listas de objetivos possíveis:
   - AO **neutro** (`[4]==1`): DISARM (IED/UXO), FORTIFY (OP/BLOCKADE), PROTECTCIV.
   - AO **hostil** (`[4]==0`): VEHICLE, VEHICLESTEAL, WRECK, HVT (OUTSIDE/INSIDE/OUTSIDETRAVEL), CLEARLZ, ARTY, MORTAR, HELI, CACHE, CACHEBUILDING, INTEL, POW.
   - Todos ganham RECONFOOT como fallback.
2. **Aplica `preferredObjectives`** (linhas 184-213): se o pool preferido não é vazio, filtra os estilos disponíveis pela preferência. **É AQUI que o preset SNIPER (`preferredObjectives=["HVT"]`) força HVT.**
3. **Seleciona** (linhas 217-246): prioriza estilo preferido no AO pedido → preferido em qualquer AO → qualquer estilo no AO pedido → qualquer estilo em qualquer AO → failsafe `RECON`.
4. **Dispara** o script do objetivo (`switch`, linhas 251-354): cada caso faz `execVM` do `.sqf` correspondente em `objectives/` ou `objectives_neutral/`.

### 4.3 Ramificações de preset nos objetivos
| Local | Linha | Efeito |
|---|---|---|
| `objSelect.sqf` | 254 | SNIPER (2): HVT sempre `HVTREGULAR` (nunca interrogação). Outros: chance (hoje travada em regular por `random 1 > 999`) + removem OUTSIDETRAVEL do pool. |
| `hvt.sqf` | 16 | SNIPER (2): `_evidenceChance=0` → HVT é **só eliminação**, sem subtarefa de evidência/intel. Outros: `random 1` (pode ter evidência). |
| `selectReactiveTask.sqf` | 4 | SNIPER (2): tarefa reativa só pode ser `["HVT"]`. Outros: `["HVT","VEHICLE"]`. |

**Tarefa reativa** = objetivo dinâmico de follow-up gerado depois (ex.: quando o AO é limpo, aparece novo alvo). SNIPER mantém o tema "caça ao HVT" também nas reativas.

RECON e COMBINED não ramificam nos objetivos — usam o pool completo (`preferredObjectives=[]`), qualquer estilo que a geografia do AO permitir.

---

## 5. Efeitos colaterais fora de mapa/objetivo (contexto)

Não são o foco, mas afetam a "sensação" de cada modo e podem interagir com alterações:

| Efeito | Arquivo:linha | Preset |
|---|---|---|
| **Esquadra do player vira sniper+spotter** | `start.sqf:352-...` | SNIPER (2): filtra classes por role Marksman/SpecialOperative |
| **Slots de AI jogáveis** | `populateLobby.sqf:229` | SNIPER: cap índice 1 (2 unidades). Outros: índice 3 (4 unidades) |
| **Veículos disponíveis no lobby** | `populateLobby.sqf:134` | COMBINED: +APC/tanque/arty/heli. Outros: só carro+heli |
| **Stealth em runtime** | `start.sqf:796-802` | COMBINED nunca stealth (=2). RECON/SNIPER: se RANDOM e time≥3, sorteia [1,2] |
| **AI amigo (esquadras)** | `start.sqf:849,856` + `generateFriendlies.sqf:79-93` | COMBINED (3): spawna friendlies com carros de torre/APC/tanque |
| **Comando "Friendly Engage"** | `setupPlayersFaction.sqf:1194` | COMBINED (3): adiciona item de comm menu ao líder |

---

## 6. Mapa de arquivos — onde mexer para alterar a construção

Ordenado por relevância pro teu foco (povoamento / AO / objetivos):

### Povoamento de inimigos
- **`sunday_system/generate_enemies/generateEnemies.sqf`** — orquestrador da população por AO. **Principal ponto de edição** pra mudar quantidades, composição, e as regras de COMBINED (linhas 59, 81-133).
- `functions/fn_spawnGroupWeighted.sqf` — cria cada grupo ponderado (74+ call sites passam aqui). Ponto central pra tamanho/skill/dynamicSim de grupo.
- `functions/fn_spawnEnemyGarrison.sqf` — garrison de prédio.
- `sunday_system/generate_enemies/generate{Roadblock,Bunker,Barrier,Emplacement,Compound}.sqf` — POIs militares individuais.
- `sunday_system/generate_enemies/staggeredAttack.sqf` — ondas/reforço.

### Cálculo e ocupação de AO
- **`sunday_system/generate_ao/generateAO.sqf`** — seleção do AO, secundários, dados de posição, neutro/hostil. **Ponto de edição** pra mudar tamanho (`aoSize`, linha 12), nº de secundários (linha 66), raio de busca (2800m, linha 62), chance neutra (linha 236).
- `functions/fn_generateAOLoc.sqf` (`DRO_fnc_generateAOLoc`) — gera o sub-array `[2]` de posições (roads/ground/flat/forest/buildings/helipads). Onde se define "o que existe onde".
- `sunday_system/generate_ao/{generateCampsite,generateMarket,findGarrisonBuildings,generateMinefield}.sqf` — elementos de AO.

### Objetivos
- **`sunday_system/objectives/objSelect.sqf`** — seletor mestre + ramos de preset (254). **Ponto de edição** pra mudar o pool por AO, pesos, e prioridade de preferidos.
- `sunday_system/objectives/selectReactiveTask.sqf` — tarefas reativas (ramo preset 4).
- `sunday_system/objectives/*.sqf` — um arquivo por tipo de objetivo (hvt, pow, intel, cache, heli, vehicle, artillery, clearArea, etc.).
- `sunday_system/objectives_neutral/*.sqf` — objetivos de AO neutro (disarmIED, disarmUXO, fortify, protectCiv, blockade).

### Onde o preset é definido/aplicado
- `functions/fn_missionPreset.sqf` — defaults de UI por preset (a "tabela" da seção 1.2). **Editar aqui muda os defaults que o preset aplica.**
- `loadProfile.sqf` / `loadParams.sqf` — carregam a global `missionPreset`.
- `functions/fn_switchLookup.sqf` — rótulos/value-sets dos toggles.

---

## 7. Notas para futuras alterações

1. **Dois lugares por mudança de preset.** Se você quer que um preset mude comportamento, decida se é (a) um *default de UI* (mexe em `fn_missionPreset.sqf`) ou (b) uma *regra de runtime* (mexe no gerador com `if (missionPreset == N)`). SNIPER e COMBINED usam ambos; não esqueça de sincronizar.

2. **RECON é o baseline.** Como RECON não ramifica em runtime, "mudar o recon" = mudar a lógica default dos geradores (afeta também o preset 0/CURRENT SETTINGS). Se quiser mexer só no recon sem afetar CURRENT SETTINGS, terá que adicionar um `if (missionPreset == 1)` explícito onde hoje não existe.

3. **`aiMultiplier` é a alavanca de densidade.** A diferença de "quantidade de inimigos" entre presets é quase toda ele (0.5/1.0/1.25). Pra rebalancear volume sem tocar composição, ajuste os valores de slider em `fn_missionPreset.sqf` (2041).

4. **Geografia é comum aos três.** Se a meta é fazer um preset "ocupar o mapa" de forma diferente (ex.: sniper com AOs menores e mais espalhados), isso exige adicionar ramificação de preset em `generateAO.sqf` — que hoje NÃO existe. É a maior lacuna se você quiser diferenciar os modos geograficamente.

5. **Cuidado com o preset 0.** `CURRENT SETTINGS` não passa por `fn_missionPreset` e cai no caminho default de todo `if (missionPreset == N)`. Qualquer regra nova precisa considerar o que acontece com `missionPreset==0`.

6. **Hazard de escrita (do PROGRESS):** o mount trunca arquivos na escrita — usar escrita atômica verificada (balanço de chaves + cauda + zero CR) ao editar qualquer gerador. Estes `.md` não entram no git por padrão (`git add -f`).

---

*Documento gerado na sessão de onboarding do Master (2026-07-04). Próximo passo: escolher qual eixo alterar primeiro (densidade, composição, geografia ou objetivos) e abrir o(s) arquivo(s) da seção 6.*
