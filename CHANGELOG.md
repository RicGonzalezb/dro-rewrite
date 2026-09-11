# Changelog

All notable changes to the Rewrite are documented here. Dates are the completion
date of the work, not a Workshop release date.

## [1.1.2] — 2026-09-10 — Insertion, sides & compatibility fixes

### Fixed
- **Insertion could place the squad at map origin `[0,0,0]`.** Ground/FOB, HALO,
  and helicopter insertions now use a robust position search with progressive
  fallbacks; when no valid point exists they fall back to the staging area (or a
  real on-map position) instead of the map corner. The HALO search also no longer
  blacklists the very AO it is trying to drop into.
- **Enemies could be non-hostile to the player** when their faction resolved to a
  side friendly to yours by default (e.g. BLUFOR player vs INDEPENDENT enemy).
  Enemy hostility is now forced explicitly, server-side and broadcast.
- **A joining player could miss their initial loadout** on dedicated servers and
  show the wrong class; the roster now self-heals the local player's loadout.
- **Civilians never received vests or headgear** (pre-existing bugs) and could
  lose their identity or leak as orphaned entities in agent mode.
- **DRO remote calls could be silently blocked** when another mod set a strict
  remote-exec whitelist; DRO functions are now self-whitelisted without touching
  the shared policy.

### Changed
- Civilian **agent mode** now bypasses the BIS Civilian Presence Module cleanly
  (no forced unit→agent conversion), removing a source of orphaned entities and
  giving agents proper identities.

## [1.1.1] — 2026-07-26 — Dedicated-server & balance fixes

### Fixed
- **Team Planning could crash on dedicated servers** with multiple players
  (undefined faction class when a player hadn't changed loadout).
- **Radio messages (intel, fire support, extraction) only showed locally on
  dedicated servers** and could throw an undefined-variable error — they now
  route to the server and reach the whole team.
- **Boat insertion could drop a solo player in the water** while the boat left
  with only the pilot; players are now reliably boarded before departure.
- **Enemy armor turned into "Eliminate vehicle" tasks in Recon/Sniper Ops** — a
  regression from the mechanized redesign. Armor is ambient again outside
  Combined Arms.
- **Budgeted armor could silently fail to spawn** for factions that don't tag
  their vehicles the vanilla way; the vehicle pool now falls back by priority so
  the intended count still appears.

### Changed
- **Rebalanced mechanized armor.** New per-level totals that scale more gently
  with the number of AOs (no more ~14 vehicles on High/6-AO), and the enemy car
  patrol now follows the Mechanized level ("None" means no armor at all).

## [1.1.0] — 2026-07-19 — AI Squad Roster & stability

### Added
- **AI Squad Roster.** The squad no longer auto-fills with AI teammates. The team
  leader adds AI on demand with a **+1 AI** button in Team Planning; the roster
  updates live, and any AI can be removed individually. AI added this way carries
  a proper identity (name, face, voice) and persists through insertion into the
  mission. Maximum squad size is read from the mission `Header` (16).
- **Orphan-entity janitor.** A periodic sweep plus Zeus-deletion and kill hooks
  that clean up empty groups left behind when units are removed.

### Fixed
- **Hostage (POW) extraction could never complete.** The extraction watcher
  compared against the original hostage roster, so if a POW was removed the task
  deadlocked and never finished.
- **Retrieving intel from a body could destroy nearby buildings.** The helper
  meant to create decorative props was creating full physics objects, which got
  violently ejected when spawned inside wall geometry.
- **Severe log spam** (`Object not found`) caused by empty groups surviving unit
  deletion while waypoint loops and LAMBS kept driving them.
- **Mission start before factions finished loading** cascaded into boot errors.
  Start is now blocked with a "factions are still loading" prompt.
- **Crash when an AO had no valid infantry spawn positions** — a random pick over
  an empty pool returned nil and broke enemy generation.
- Task markers and destinations jumping to map origin when the tracked object was
  deleted.
- Group cleanup removing the wrong group when two groups died on the same tick.
- Revive network calls firing at zero targets when the downed unit was the only
  player on the server (log noise).
- Civilian spawn/despawn leaving stale join-in-progress messages queued.

### Changed
- Squad AI is now **opt-in** (`disabledAI = 1`) — a deliberate departure from the
  original auto-fill behaviour.

## [1.0.0] — 2026-07-04 — The Rewrite

Baseline of this community rewrite of Dynamic Recon Ops.

### Added
- Lobby **parameter-override system**: configure scenario, environment,
  objectives, factions, insertion, and supports from the MP Parameters screen,
  with the option to skip the in-game setup UI entirely. Three independent
  override spheres allow mixing lobby and in-game configuration.
- **Sea (Boat)** and **None** insertion types alongside Ground, HALO, and
  Helicopter.
- **Combined-arms overhaul**: enemy APCs and tanks allocated from a mission
  budget instead of growing linearly, with per-mode armor profiles and a
  **Mechanized level** parameter (None / Low / Standard / High).
- **ACE3 soft-compat** (optional): Arsenal toggle, arsenal and interaction
  integration when ACE is loaded.
- **LAMBS Danger soft-compat** (optional): context-aware pursuit, reinforcement
  responders, and radio-driven escalation.
- Leader-centric Team Planning lobby with a disconnect-handover safeguard.
- Objective variety guard so multi-objective operations spread across task types.

### Changed
- **Full migration to CBA scheduling** (per-frame handlers) replacing scheduled
  sleep loops — fewer frame hitches during spawns and steadier performance.
- Functions moved to engine-loaded `CfgFunctions` for faster boot.
- Reworked AO enemy population with patrol corridors and seeded adjacent areas.

### Fixed
- Off-map spawn protection: objectives, hostages, and reinforcements can no
  longer be generated outside the playable area.
- Event-handler leaks and locality bugs in the revive system.
- Numerous multiplayer and dedicated-server init-order issues.
