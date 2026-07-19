# Changelog

All notable changes to the Rewrite are documented here. Dates are the completion
date of the work, not a Workshop release date.

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
