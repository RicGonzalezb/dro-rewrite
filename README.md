# Dynamic Recon Ops — Rewrite (Livonia)

A dynamic, randomized special-operations scenario for **Arma 3**, built on **CBA** scheduling, with an expanded pre-game configuration system and optional soft-compatibility for **ACE3** and **LAMBS Danger**.

Every playthrough generates a fresh Area of Operations, enemy layout, objectives, weather, and time of day. Insert by helicopter, HALO, ground, or boat; hunt an HVT, rescue a hostage, destroy a cache, or clear a town — solo or in co-op.

> **Status:** Feature-complete and stabilized. This repository is a heavily refactored community rewrite of Dynamic Recon Ops. See [Credits & attribution](#credits--attribution).

---

## Requirements

**Required**

- **Arma 3**
- **CBA_A3** — Community Base Addons

**Optional (soft-compatible — the mission detects them at runtime and runs fine without them)**

- **ACE3** — when present, the mission integrates with ACE interaction and arsenal.
- **LAMBS Danger** — improves enemy reactions, reinforcement, and radio behavior.

The scenario is **map-agnostic**: it resolves locations and factions from the running game at runtime rather than hardcoding a specific terrain, so it can be ported to other maps by copying the mission folder onto a different world (see the architecture doc) as also all objects present on Eden Editor. Faction options that belong to content you don't have loaded simply fall back to Random.

---

## Quick start

1. Install **CBA_A3**, then launch Arma 3 with it enabled (ACE3 and LAMBS Danger are optional).
2. Load the scenario (from the Workshop once published, or place this folder in `...\Arma 3\MPMissions\` / your profile's `mpmissions\` for local play).
3. In the lobby, either leave everything on defaults or open **Parameters** to configure the mission (see the [Player Guide](docs/PLAYER_GUIDE.md)).
4. Launch. Configure your Area of Operations and factions in the in-game **pre-generation UI** (or skip it entirely via lobby parameters), pick your loadout in **Team Planning**, and start the mission.

**Game modes:** *Recon Ops* (baseline), *Sniper Ops* (lean, stealth-focused, 2-man team), *Combined Arms* (armor on both sides, friendly AI, open battle). Details in the Player Guide.

---

## Documentation

| Doc | Audience | What's in it |
|---|---|---|
| **[Player Guide](docs/PLAYER_GUIDE.md)** | Players | Game modes, every lobby parameter, insertion types, objective types, factions, revive, supports, and the parameter-override system. |
| **[Architecture](docs/ARCHITECTURE.md)** | Developers / maintainers | Folder layout, init order, CBA & CfgFunctions conventions, the 3-sphere override system, preset internals, ACE/LAMBS soft-compat, and the file-write hazards to know before editing. |
| **[Publishing to Steam Workshop](docs/PUBLISHING_STEAM.md)** | Maintainer | Pre-flight checklist and step-by-step packing/upload via the Arma 3 Publisher. |

---

## Features at a glance

- **Randomized AO generation** — primary + up to 5 extended AOs, resolved from real map locations each run.
- **Three game modes** with distinct force composition, stealth behavior, and objective focus.
- **10+ objective types** — Eliminate HVT, Rescue Hostage, Retrieve Intel, Destroy Cache/Asset, Steal Vehicle, Clear Area, plus neutral-AO tasks (Disarm IED/UXO, Fortify, Protect Civilian).
- **Five insertion types** — Ground, Air (HALO), Air (Helicopter), Sea (Boat), or None.
- **Full lobby-parameter override** — configure scenario, environment, objectives, factions, insertion, and supports from the MP Parameters screen and optionally skip the in-game UI entirely.
- **Built-in revive** with configurable bleedout and arsenal loadouts; integrates with ACE interaction when ACE is present.
- **LAMBS Danger soft-compat** — context-aware pursuit, reinforcement, and radio-driven escalation when the mod is present.
- **Curated faction list** — vanilla factions plus any loaded faction mods, validated against loaded content at runtime.

---

## Credits & attribution

This project is a community modification of **Dynamic Recon Ops**, originally created by **mbrdmn**. All original design credit belongs to the original author.

This rewrite adds a CBA-based scheduling rewrite, the lobby-parameter override system, additional insertion types, mechanized/combined-arms balancing, ACE3 and LAMBS Danger soft-compat, and numerous fixes.

Please review [LICENSE](LICENSE) before redistributing. Publishing a derivative of another author's Workshop content carries attribution obligations — see the note in the license file.

---

## Contributing / maintaining

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first. Two hard rules that will save you pain:

- **Code comments are written in English.**
- The mission uses **CBA scheduling** (per-frame handlers / `waitAndExecute`) — never introduce `spawn { while {true} do { sleep } }` patterns in new code.
