# Dynamic Recon Ops: Rewrite

Built on the legendary **Dynamic Recon Ops** by **mbrdmn** — one of the most-played dynamic mission frameworks in the Arma 3 community. This Rewrite keeps everything that made DRO great, rebuilds it under the hood for stability, hardens the existing systems, and adds full lobby-side configuration plus modern AI and ACE support.

Every op is procedurally generated: a fresh Area of Operations, enemy layout, objectives, weather, and time of day, every single time. Insert by helicopter, HALO, ground, or boat; hunt an HVT, rescue a hostage, retrieve intel, destroy a cache, or clear a town — solo or in co-op.

> **Status:** Feature-complete and stabilized. A community rewrite of Dynamic Recon Ops — see [Credits & attribution](#credits--attribution).

---

## What's new in this Rewrite

**Rebuilt engine, smoother play**

- Full migration to CBA scheduling (per-frame handlers) — fewer frame hitches during spawns and steadier performance in long sessions.
- Hardened for multiplayer and dedicated servers: init-order fixes, event-handler leak fixes, and locality fixes.
- Faster boot via engine-loaded functions (CfgFunctions).

**Configure the whole mission from the lobby**

- New parameter-override system: set scenario, environment, objectives, factions, insertion, and supports straight from the MP **Parameters** screen.
- Optionally skip the in-game setup UI entirely — hosts can pre-bake a mission so players drop straight in.
- Three independent override spheres, so you can mix (e.g. factions via parameters, everything else via the in-game UI).

**Squad AI on your terms**

- No AI teammates by default — your squad starts with just you and any human players.
- The leader adds AI one at a time with a **+1 AI** button in Team Planning; the roster updates live and any AI can be removed individually.
- AI added this way carries a proper identity (name, face, voice) and persists through insertion into the mission.

**Smarter battlefield population**

- Reworked enemy population across the AO — patrol corridors and seeded adjacent areas make the battlespace feel connected instead of clumped.
- Objective variety guard so multi-objective ops spread across different task types.
- Off-map spawn protection — no more objectives or hostages generated outside the playable area.

**More ways to insert**

- Added **Sea (Boat)** insertion — a piloted boat runs you to shore, respecting your chosen insertion point.
- Added **None** (start on-site) so you continue the mission directly from the staging area — especially immersive for customized DRO scenarios.

**Mechanized vehicles overhaul**

- Now available for every game mode (Recon Ops / Sniper Ops / Combined Arms), each with its own density cap.
- Enemy mechanized forces (APCs and tanks) via a mission budget instead of endless linear growth.
- New mechanized **density level** parameter (None / Low / Standard / High).

**Optional soft-compat**

- **ACE3** — new Arsenal toggle; arsenal and interaction integrate with ACE when it's loaded, and fall back cleanly without it.
- **LAMBS Danger** — context-aware pursuit, reinforcement responders, and radio-driven escalation when present.

**Refined & fixed**

- The classic DRO game modes (Recon / Sniper / Combined Arms) reviewed and fixed.
- Civilian system fixes and improvements, including a performance-friendly **agent mode** and a fix for the optional hostile-civilian setting.
- Leader-centric Team Planning lobby with a disconnect-handover safeguard.
- Numerous bug fixes across revive, objectives, and spawn logic — including a hostage-extraction task that could deadlock and never complete, and intel pickups that could damage nearby buildings.

---

## Requirements

**Required**

- **Arma 3**
- **CBA_A3** — Community Base Addons

**Optional (soft-compatible — detected at runtime, runs fine without them)**

- **ACE3** — arsenal and interaction integration.
- **LAMBS Danger** — smarter enemy AI.

The scenario is **map-agnostic**: it resolves locations and factions from the running game at runtime rather than hardcoding a terrain, so it can be ported to other maps by copying the mission folder onto a different world (see the architecture doc). Faction options that belong to content you don't have loaded simply fall back to Random.

---

## Game modes

- **Recon Ops** — the baseline experience: full enemy strength, stealth possible, any objective.
- **Sniper Ops** — lean and stealthy: half the enemies, a 2-man marksman team, focus on hunting an HVT.
- **Combined Arms** — open battle: armor on both sides, friendly AI, no stealth.

---

## Quick start

1. Install **CBA_A3**, then launch Arma 3 with it enabled (ACE3 and LAMBS Danger are optional).
2. Load the scenario (from the Workshop once published, or place this folder in your `mpmissions\` for local play).
3. In the lobby, leave everything on defaults or open **Parameters** to configure the mission (see the [Player Guide](docs/PLAYER_GUIDE.md)).
4. Launch. Configure your AO and factions in the in-game pre-generation UI (or skip it via lobby parameters), pick your loadout in **Team Planning**, and start the mission.

---

## Documentation

| Doc | Audience | What's in it |
|---|---|---|
| **[Player Guide](docs/PLAYER_GUIDE.md)** | Players | Game modes, every lobby parameter, insertion types, objective types, factions, revive, supports, and the parameter-override system. |
| **[Architecture](docs/ARCHITECTURE.md)** | Developers / maintainers | Folder layout, init order, CBA & CfgFunctions conventions, the 3-sphere override system, preset internals, ACE/LAMBS soft-compat, and file-write hazards. |
| **[Publishing to Steam Workshop](docs/PUBLISHING_STEAM.md)** | Maintainer | Pre-flight checklist and step-by-step packing/upload via the Arma 3 Publisher. |

Release history is in the [Changelog](CHANGELOG.md).

---

## Credits & attribution

Original **Dynamic Recon Ops** by **mbrdmn**. All original design credit belongs to the original author. This Rewrite is a community modification that adds the CBA rebuild, lobby-parameter override system, additional insertion types, combined-arms overhaul, ACE3 and LAMBS Danger soft-compat, and numerous fixes to the existing systems.

Please review [LICENSE](LICENSE) before redistributing — publishing a derivative of another author's Workshop content carries attribution obligations.

---

## Contributing / maintaining

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first. Two hard rules:

- **Code comments are written in English.**
- The mission uses **CBA scheduling** (per-frame handlers / `waitAndExecute`) — never introduce `spawn { while {true} do { sleep } }` patterns in new code.
