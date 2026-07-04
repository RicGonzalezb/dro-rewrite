# Architecture & Maintainer Guide

Technical reference for anyone modifying this mission. It consolidates the project's internal refactor notes (which live in Portuguese in the repo root: `_DRO_REFACTOR_PLAN.md`, `_DRO_REFACTOR_PROGRESS.md`, `_DRO_PRESETS_MAP.md`, `LAMBS_COMPAT_REFERENCE.md`).

## Table of contents

1. [Conventions you must follow](#1-conventions-you-must-follow)
2. [File & folder layout](#2-file--folder-layout)
3. [Init order (boot sequence)](#3-init-order-boot-sequence)
4. [CBA scheduling patterns](#4-cba-scheduling-patterns)
5. [CfgFunctions](#5-cfgfunctions)
6. [The parameter-override system](#6-the-parameter-override-system)
7. [Presets: dual role](#7-presets-dual-role)
8. [Mission generation flow](#8-mission-generation-flow)
9. [ACE & LAMBS soft-compat](#9-ace--lambs-soft-compat)
10. [File-write hazards (read before editing)](#10-file-write-hazards-read-before-editing)
11. [Porting to another map](#11-porting-to-another-map)

---

## 1. Conventions you must follow

- **Comments in English.** All code comments are English. (Project discussion may be in another language, but the code is not.)
- **New globals are prefixed `DRO_`.** Functions are `DRO_fnc_<name>`, per-frame-handler handles are `DRO_<context>PFH`.
- **Use CBA scheduling, never scheduled sleep loops.** No new `spawn { while {true} do { sleep N } }` or `waitUntil { sleep N; cond }`. See §4.
- **Guard against double-init:** `if (!isNil "DRO_xxx") exitWith { ... };` before creating a PFH or one-time global.
- **Do not touch code marked `// Migrated from ...`** — that is the stabilized CBA-migration layer.
- **Never break the vanilla path.** With all override toggles off (default), behavior must be identical to unmodified DRO.

---

## 2. File & folder layout

```
description.ext            Config: params, CfgFunctions, dialogs, respawn, corpse mgmt.
init.sqf                   Legacy aliases (old names -> DRO_fnc_*); early globals.
initServer.sqf            Server-only boot. Runs BEFORE init.sqf.
initPlayerLocal.sqf       Per-client boot: leader UI, lobby, insertion, teardown.
initServer / start.sqf    start.sqf = master orchestrator (launched by initServer).
loadProfile.sqf           Reads ~25 DRO_* settings from profileNamespace, publicVariables them.
loadParams.sqf            Lobby-parameter override (see §6). Runs on server + leader client.
loadProfile / okAO        okAO.sqf = START handler of the pre-generation dialog.
briefing.sqf              Task/briefing text.

functions/                112 CfgFunctions bodies (fn_*.sqf -> DRO_fnc_*).
sunday_system/
  dialogs/                Pre-gen UI (sundayDialog) + Team Planning lobby (DRO_lobbyDialog).
  generate_ao/            AO selection & population data (generateAO.sqf is central).
  generate_enemies/       Enemy population per AO (generateEnemies.sqf is central).
  objectives/             One file per hostile-AO objective + objSelect.sqf (selector).
  objectives_neutral/     Neutral-AO objectives (disarm, fortify, protect civ).
  player_setup/           Faction setup, friendlies, supports, insertion.
  supports/               CAS, artillery, supply, UAV.
  orders/, intel/, civilians/, fnc_lib/ (deprecation stubs)
sunday_revive/            ACE-integrated revive (initRevive, bleedout, reviveFunctions stub).
_archive/                 Dead code kept for rollback (never deleted, moved here).
images/                   UI/loadscreen assets.
```

`fnc_lib/*.sqf` and `generateEnemiesFunctions.sqf` are **deprecation stubs** — the real functions moved to `functions/`. Keep the stubs; they document what used to live there.

---

## 3. Init order (boot sequence)

Arma runs these in a fixed order, and it matters:

1. **`initServer.sqf`** (server only) — runs **before** `init.sqf`. Launches `start.sqf`.
2. **`init.sqf`** (all machines) — legacy aliases + early globals.
3. **`initPlayerLocal.sqf`** (each client) — leader gets the pre-gen UI; others take their unit.
4. **`start.sqf`** (server) — the master generator: waits on `factionsChosen`, builds AOs, enemies, objectives, weather, reinforcement triggers.

Because `initServer.sqf` precedes `init.sqf`, **globals defined in `init.sqf` may not exist when server-side code launched by `initServer` uses them.** The detection flags (`DRO_ace*`, `DRO_lambs*`) have an idempotent fallback at the top of `start.sqf` for this reason. Replicate that pattern for any new global consumed early on the server.

Key synchronization globals:

- **`factionsChosen`** (0→1) — the server's `start.sqf` waits for this before generating. Set by `okAO.sqf` (the pre-gen START button) or by `loadParams.sqf` when factions come from parameters.
- **`lobbyComplete`** (0→1) — starts the mission for everyone once the leader presses START in Team Planning.
- **`topUnit`** — the leader (first player). Only the leader drives the pre-gen UI and the lobby start; a disconnect handler reassigns it.

---

## 4. CBA scheduling patterns

The mission was migrated off scheduled `spawn`/`sleep`/`waitUntil+sleep` onto CBA. Use these:

| Anti-pattern (do NOT use) | CBA replacement |
|---|---|
| `spawn { while {true} do { sleep N; ... } }` | `[{ ... }, N, args] call CBA_fnc_addPerFrameHandler` |
| `spawn { sleep N; oneshot }` | `[code, args, N] call CBA_fnc_waitAndExecute` |
| `waitUntil { sleep N; cond }` | PFH with `if (!cond) exitWith {}` + `removePerFrameHandler` |
| short `waitUntil { cond }` | `[cond, code, args] call CBA_fnc_waitUntilAndExecute` |
| `sleep` in unscheduled context | `CBA_fnc_waitAndExecute` with delay |

**Self-removing PFH (condition watcher):**

```sqf
[{
    params ["_args", "_pfhId"];
    _args params ["_obj"];
    if (isNull _obj) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler };
    if (!desiredCondition) exitWith {};        // keep waiting
    [_pfhId] call CBA_fnc_removePerFrameHandler; // condition met -> stop
    // ... action ...
}, delta, [_obj]] call CBA_fnc_addPerFrameHandler;
```

**Double-init guard:**

```sqf
if (!isNil "DRO_xxxPFH") exitWith {};
DRO_xxxPFH = [ ... ] call CBA_fnc_addPerFrameHandler;
```

Every PFH should either auto-remove (via `removePerFrameHandler` in its body) or be intentionally permanent. Leaking PFHs is the main perf risk.

---

## 5. CfgFunctions

Functions live in `functions/fn_<name>.sqf` and are registered in `description.ext` under:

```cpp
class CfgFunctions {
    class DRO {
        class core {
            file = "functions";
            class <name> {};   // -> DRO_fnc_<name>
            ...
        };
    };
};
```

Each `fn_*.sqf` contains only the function **body** (no wrapping `name = { ... };`). To add a function: create the file, add its `class <name> {};` line, call it as `DRO_fnc_<name>`.

**Macros:** if a function uses a `#define` macro (e.g. `aliveVeh(...)`), the `#define` must be duplicated inside that `fn_*.sqf` — CfgFunctions files don't inherit macros from callers. This has bitten the project before; grep new functions for undefined macros.

Legacy names (`sun_*`, `dro_*`, `rev_*`) still resolve via aliases in `init.sqf` for backward-compat. Prefer `DRO_fnc_*` in all new code.

---

## 6. The parameter-override system

Lets the MP **Parameters** screen replace the in-game pre-generation UI. Implemented in `loadParams.sqf` plus the param block in `description.ext`.

It is split into **three independent spheres**, each with its own toggle — they are not a single master switch:

| Toggle | Global | Sphere |
|---|---|---|
| `DRO_ParamOverride` | `DRO_paramOverrideActive` | Scenario / Environment / Objectives |
| `DRO_ParamUseFactions` | `DRO_paramSkipUI` | Factions (and forces AO = Random, skips pre-gen dialog) |
| `DRO_ParamSkipTeamPlanning` | — | Insertion / Supports (skips Team Planning lobby) |

Design rules:

- **All off (default) ⇒ inert.** `loadParams.sqf` exits early and nothing changes.
- Each toggle acts **only** on its own sphere, enabling mixed combos (e.g. factions via params + scenario via UI). The pre-gen dialog is only fully skipped when the relevant spheres are all param-driven; otherwise it opens **locked per sphere** (tabs disabled via `menuSliderArray`, faction bar via `ctrlEnable`).
- **Where it runs (locality):** `BIS_fnc_getParamValue` is identical on all machines, so `loadParams.sqf` runs **both** on the server (early in `start.sqf`, before it reads `DRO_timeOfDay` and before the `factionsChosen` wait) **and** on the leader client (after `loadProfile.sqf`, so the override wins over profile values). It must be idempotent — running on both machines with deterministic values must not double-apply harmfully, and must never regress `factionsChosen`.

Param values are **static config** — the option lists in `description.ext` are literal and cannot be populated at runtime. `loadParams.sqf` maps param indices to the runtime globals and validates factions against `CfgFactionClasses`, falling back to Random when absent.

---

## 7. Presets: dual role

`missionPreset` is an integer (0=Current, 1=Recon, 2=Sniper, 3=Combined) that plays **two** roles — don't conflate them:

1. **UI-time defaults** — `functions/fn_missionPreset.sqf` adjusts the pre-gen sliders/toggles when you pick a preset (enemy size, stealth, objective count, preferred objectives, time of day).
2. **Run-time branching** — the integer survives into generation and is read directly (`if (missionPreset == N)`) by generators, independent of the sliders.

Consequences for editing:

- **Recon (1) has no runtime branch** — it is the default path. Changing "the default generator logic" also changes preset 0 (Current Settings). To change Recon *only*, add an explicit `if (missionPreset == 1)`.
- **Combined Arms (3)** branches in `generateEnemies.sqf`: caps foot infantry to 1 group (line ~59) and adds APCs + tanks (block ~81–133). Mechanized level is further tunable via `DRO_ParamMechLevel`.
- **Sniper (2)** differences are mostly the `aiMultiplier` (0.5) plus objective branches: HVT is elimination-only (`hvt.sqf`), reactive tasks are HVT-only (`selectReactiveTask.sqf`), preferred objective forced to `["HVT"]`.
- **Preset 0 (Current Settings)** skips `fn_missionPreset` and falls into every default `if (missionPreset == N)` branch. Account for it when adding new preset rules.

Full breakdown lives in `_DRO_PRESETS_MAP.md`.

---

## 8. Mission generation flow

- **AO selection** — `generate_ao/generateAO.sqf` (preset-agnostic). Picks a primary AO (`aoSize = 1200`) from real map locations via `nearestLocations`, plus 1–5 extended AOs when Extended AO is on. Builds each AO's position data sub-array (roads/ground/flat/forest/buildings/helipads) — the raw material everything spawns from.
- **Enemy population** — `generate_enemies/generateEnemies.sqf`, one pass per AO. Counts scale as `base_random * aiMultiplier * sizeMod`. `fn_spawnGroupWeighted.sqf` is the central group factory (74+ call sites) — the right place for group-wide skill / `enableDynamicSimulation` changes.
- **Objective selection** — `objectives/objSelect.sqf` builds a per-AO style pool from geography, filters by `preferredObjectives`, selects with a variety guard (prefer-unused), then `execVM`s the matching objective script.
- **Off-map safety** — spawns are guarded by `DRO_fnc_validPos`; positions failing `findSafePos`/`randomPos` validation are rejected and logged, preventing the classic "HVT/hostage spawned off-map" bug.

---

## 9. ACE & LAMBS soft-compat

- **ACE3** is required. Revive/medical, arsenal, and interaction integrate natively; the custom revive layer (`sunday_revive/`) sits on top of ACE medical and is gated by the Revive parameter.
- **LAMBS Danger** is detected at runtime (`DRO_lambs*` flags). When present: mobile patrols become reinforcement responders (`enableGroupReinforce`), camps broadcast contact (`dangerRadio`), and pursuit tasks are assigned by context (RUSH / HUNT / CREEP). When absent, the mission uses vanilla AI behavior — no hard dependency. See `LAMBS_COMPAT_REFERENCE.md`.

Detection flags have idempotent fallbacks at the top of `start.sqf` because of the init-order issue (§3).

---

## 10. File-write hazards (read before editing)

Learned the hard way during the refactor — these apply to any tool/editor writing into the mission folder over a mount:

- **Writes can silently truncate.** A write tool may cut the tail of a file and still report success, corrupting `description.ext`, `start.sqf`, generators, etc. **Protocol:** write atomically (write to `.new`, `flush` + `fsync`, then `os.replace`), and **verify after every write**: (a) balance of `{}` `()` `[]`, (b) the file's expected last line, (c) zero `\r` (CR) bytes.
- **Brace balance alone is not enough.** A quoting bug can pass brace-balance but break the SQF. Grep the actual edited content, not just delimiters.
- **Diagnose by instrumentation, not guesswork.** Temporary `systemChat` / `diag_log` in a single-player run is the reliable way to see runtime behavior; remove them before committing.
- **Commit often.** Every bad write without a commit is lost work.

---

## 11. Porting to another map

The mission is map-agnostic: it resolves locations from `nearestLocations` and factions from `CfgFactionClasses` at runtime, with no Livonia hardcoding. To port:

1. Copy the mission folder and rename its `.<WorldName>` suffix to the target world (e.g. `...Livonia.Enoch` → `...MyMission.Altis`).
2. Ensure the target map's DLC/mod is loaded (Contact for Livonia; base game for Altis/Stratis).
3. Faction availability follows loaded content — Contact-only factions (LDF, Spetsnaz) won't appear on maps loaded without Contact, and fall back to Random.

Test on at least two maps after any generation change to confirm nothing regressed to map-specific assumptions.
