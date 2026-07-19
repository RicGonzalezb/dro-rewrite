# Player Guide — Dynamic Recon Ops (Rewrite)

This guide covers how to configure and play the mission. For how the mission works under the hood, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Table of contents

1. [How a mission plays out](#1-how-a-mission-plays-out)
2. [Game modes (presets)](#2-game-modes-presets)
3. [Configuring the mission — two ways](#3-configuring-the-mission--two-ways)
4. [Lobby parameters reference](#4-lobby-parameters-reference)
5. [Insertion types](#5-insertion-types)
6. [Objectives](#6-objectives)
7. [Factions](#7-factions)
8. [Revive & medical](#8-revive--medical)
9. [Supports](#9-supports)
10. [Co-op notes](#10-co-op-notes)

---

## 1. How a mission plays out

1. **Lobby.** Optionally set parameters (Parameters screen). In co-op, one player is the **leader** (first slot).
2. **Pre-generation UI.** After launch the leader gets an in-game screen to choose the Area of Operations, factions, and scenario settings — unless you skipped it via parameters (see §3).
3. **Team Planning.** Pick your loadout from the ACE Arsenal. The leader presses **START MISSION**.
4. **Insertion.** You arrive by helicopter, HALO drop, ground vehicle, boat, or already on-site ("None").
5. **Execution.** Locate and complete your objective(s) in the generated AO(s). Enemies patrol, garrison buildings, and (with LAMBS) reinforce and hunt.
6. **Extraction.** After objectives are done, an extraction task appears. Reach the extraction point / call the helicopter and leave.

Each run randomizes the AO location, enemy composition, objectives, weather, and time of day within the limits you set.

---

## 2. Game modes (presets)

Choose a mode in the pre-generation UI or via the **Game Mode** parameter.

| Axis | Recon Ops | Sniper Ops | Combined Arms |
|---|---|---|---|
| Enemy force multiplier | **x1.0** | **x0.5** (half) | **x1.25** |
| Foot infantry patrols | normal | normal (halved) | **capped at 1 group** + armor |
| Enemy armor (APC/tank) | no | no | **yes** |
| Stealth | Random | **forced ON** | forced OFF |
| Number of objectives | Random (1–3) | **1** | Random (1–3) |
| Preferred objective | any | **HVT** | any |
| Your squad | standard | **sniper + spotter** (2 slots) | standard (4 slots) |
| Lobby vehicles | cars + heli | cars + heli | **+ APC + tank + artillery** |
| Friendly AI / support | no | no | **yes** ("Engage" command) |

**One-line summary**

- **Recon Ops** — the baseline experience: full enemy strength, stealth possible, any objective.
- **Sniper Ops** — lean and stealthy: half the enemies, a 2-man marksman team, stealth on, focus on hunting an HVT (elimination only, no evidence sub-task).
- **Combined Arms** — open battle: more enemies, armor on both sides, friendly AI, no stealth, fewer foot patrols (replaced by vehicles).

There is also a hidden **Current Settings** mode used when you configure everything by hand rather than picking a preset; it behaves like Recon Ops in most respects.

---

## 3. Configuring the mission — two ways

The mission can be configured **in-game** (the pre-generation UI) or **entirely from the lobby Parameters screen**. This is controlled by three independent override toggles, each governing its own "sphere":

| Toggle (lobby parameter) | Sphere it controls | Default |
|---|---|---|
| **Override Scenario / Environment / Objectives parameters** | game mode, enemy size, civilians, stealth, revive, weather, time, objective types, etc. | Disabled |
| **Override FACTIONS parameters** | player / enemy / civilian factions | Disabled |
| **Skip Team Planning lobby** | insertion type + supports, and skips the loadout lobby | Disabled |

Key behaviors:

- With **all toggles Disabled (the default), nothing changes** — you configure everything through the in-game UI exactly as vanilla DRO.
- Turning a toggle **On** makes that sphere read from lobby parameters instead of the UI. You can mix: e.g. factions from parameters but scenario settings from the in-game UI.
- If **Override Factions** is On, the mission uses the parameter factions and the AO location is forced to **Random** (no map pick).
- If **Skip Team Planning** is On, insertion and supports come from parameters and the Team Planning loadout lobby is skipped.

This lets a server host pre-bake a full mission from the Parameters screen so players drop straight in, or lets players keep the full in-game control — or anything in between.

---

## 4. Lobby parameters reference

All values below are the in-mission defaults. Parameters only take effect when the relevant override toggle (§3) is enabled; otherwise the in-game UI wins.

### Control

| Parameter | Options | Default |
|---|---|---|
| Override Scenario / Environment / Objectives | Disabled / Enabled | Disabled |
| Override FACTIONS | Disabled / Enabled | Disabled |
| Skip Team Planning lobby | Disabled / Enabled | Disabled |

### Scenario

| Parameter | Options | Default |
|---|---|---|
| Game Mode | Recon Ops / Sniper Ops / Combined Arms | Recon Ops |
| Extended AO | Enabled / Disabled | Enabled |
| AI Skill | Normal / Hard / Custom | Custom |
| Enemy Force Size | x0.5 / x0.8 / x1.0 / x1.2 / x1.5 / x1.7 | x1.0 |
| Enemy Mechanized | Default (per mode) / None / Low / Standard / High | Default |
| Minefields | Disabled / Enabled | Disabled |
| Civilians | Random / Enabled / Enabled & Hostile / Disabled | Random |
| Civilians as Agents | Enabled / Disabled | Enabled |
| Arsenal | Enabled / Disabled | Enabled |
| Stealth | Random / Enabled / Disabled | Random |
| Revive | 300s / 120s / 60s / Disabled | Disabled |
| Stamina | Enabled / Disabled | Enabled |
| Dynamic Simulation | Enabled / Disabled | Enabled |

### Environment

| Parameter | Options | Default |
|---|---|---|
| Time of Day | Random / Dawn / Morning / Midday / Afternoon / Dusk / Evening / Midnight | Random |
| Weather | Random / Clear / Light / Overcast / Storm | Random |
| Month | Random / January … December | Random |
| Day | Random / 1 … 31 | Random |
| Animals | Enabled / Disabled | Enabled |

### Objectives

| Parameter | Options | Default |
|---|---|---|
| No. of Objectives | Random / 1 … 5 | Random |
| Obj: Eliminate HVT | Disabled / Enabled | Disabled |
| Obj: Rescue Hostage | Disabled / Enabled | **Enabled** |
| Obj: Retrieve Intel | Disabled / Enabled | **Enabled** |
| Obj: Destroy Cache | Disabled / Enabled | Disabled |
| Obj: Destroy Asset | Disabled / Enabled | Disabled |
| Obj: Steal Vehicle | Disabled / Enabled | Disabled |
| Obj: Clear Area | Disabled / Enabled | Disabled |
| Obj: Fortify | Disabled / Enabled | Disabled |
| Obj: Disarm | Disabled / Enabled | Disabled |
| Obj: Protect Civilian | Disabled / Enabled | Disabled |

If no objective type is enabled, the mission falls back to its full pool. Enabling specific types restricts generation to those (subject to what each AO's geography allows).

### Insertion & Supports

These apply when **Skip Team Planning** is enabled.

| Parameter | Options | Default |
|---|---|---|
| Insertion Type | Random / Ground / Air - HALO / Air - Helicopter / None / Sea - Boat | Random |
| Support: Supply Drop | Disabled / Enabled | Disabled |
| Support: Artillery | Disabled / Enabled | Disabled |
| Support: CAS | Disabled / Enabled | Disabled |
| Support: UAV | Disabled / Enabled | Disabled |

### Factions

Player, Enemy, Civilian, and three "advanced" (secondary) faction slots per side. Index 0 is **Random**; other indices map to vanilla factions plus optional mod/DLC factions. The mission validates each choice against the loaded content and falls back to Random if a faction isn't present. See §7.

---

## 5. Insertion types

| Type | What happens |
|---|---|
| **Ground** | You start in vehicles and drive to the AO. |
| **Air - HALO** | High-altitude jump; open your chute and land near the AO. |
| **Air - Helicopter** | A helicopter flies you in, lands, you disembark, and it departs. |
| **Sea - Boat** | A piloted boat runs you to shore and drops you at the waterline. If you set a custom insertion point in Team Planning it is respected; unreachable points trigger a warning. |
| **None** | No transport — players stay at the staging area / start on-site. Crossing boats remain as ambient. |

With **Random**, the mission picks a suitable type for the generated AO (a coastal AO can produce a sea insert).

---

## 6. Objectives

Objectives are chosen based on each AO's geography and whether it is hostile or neutral.

**Hostile-AO objectives**

- **Eliminate HVT** — kill a high-value target. May include an evidence/intel sub-task (except in Sniper Ops, which is elimination-only).
- **Rescue Hostage (POW)** — free a captured friendly and extract them.
- **Retrieve Intel** — recover documents/laptop from the AO.
- **Destroy Cache / Destroy Asset** — demolish a weapons cache, wreck, vehicle, mortar, or artillery piece.
- **Steal Vehicle** — capture an enemy vehicle and bring it out.
- **Clear Area (Clear LZ)** — eliminate all enemies in the zone.

**Neutral-AO objectives**

- **Disarm** — defuse IEDs / UXO.
- **Fortify** — build up an OP / blockade.
- **Protect Civilian** — defend civilians from a threat.

**Reactive tasks** — after clearing an objective, a dynamic follow-up may appear (a new HVT, or a vehicle target). Sniper Ops keeps these HVT-themed.

---

## 7. Factions

The mission ships a curated faction list spanning vanilla Arma 3 factions (NATO, CSAT, AAF, FIA, CTRG, Gendarmerie, and Pacific/Woodland variants), plus a long list of common community and DLC factions that resolve **only if the corresponding content is loaded**.

- **Player / Enemy** parameters offer non-civilian factions. If player and enemy resolve to the same side, the mission auto-resolves the conflict.
- **Civilian** parameter offers civilian-side factions only (e.g. Civilians, IDAP).
- **Advanced** slots (3 per side) let you mix additional factions into the player or enemy force. `None` leaves the slot empty.
- Any faction that isn't present in the loaded game falls back to Random, so missing content never hard-breaks generation.

If you play with only the base game and CBA, stick to the vanilla faction entries; the other entries activate automatically if you load the mods/DLC they belong to.

---

## 8. Revive & medical

The mission has its own revive layer. When ACE3 is loaded it integrates with ACE interaction; without ACE it works on its own. The **Revive** parameter controls the incapacitation/bleedout window:

- **300s / 120s / 60s** — you can be revived by a teammate within that window.
- **Disabled** (default) — no custom revive timer; incapacitation follows the base game (or ACE, if ACE is present).

When down, screen effects darken progressively and a self-give-up action is available. A teammate (or AI) can stabilize and revive you within the timer. Arsenal loadouts work as normal; ACE interaction is used when ACE is present.

---

## 9. Supports

Optional fire-support and logistics, enabled per mission (via Team Planning, or via parameters when Skip Team Planning is on):

- **Supply Drop** — request a crate of gear.
- **Artillery** — call indirect fire.
- **CAS** — close air support run.
- **UAV** — reconnaissance drone.

Combined Arms additionally gives the leader a **Friendly Engage** command to direct friendly AI squads.

---

## 10. Co-op notes

- The **leader** is the first player slot. Only the leader sees the pre-generation UI and presses **START MISSION**; other players customize their gear via the "Open Arsenal" scroll action and wait.
- Any player can reopen **Team Planning** via the scroll action, but only the leader can start.
- If the leader disconnects before the mission starts, leadership transfers to another player, who receives the UI and the start button (multiplayer only).
- Press **ESC** to leave the planning interface; a hint reminds you how to reopen it.
