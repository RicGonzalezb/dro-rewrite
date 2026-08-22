# Steam Workshop description — Dynamic Recon Ops: Rewrite

Ready-to-paste Workshop description (Steam BBCode) + a short summary for the
small description field.

--------------------------------------------------------------------------------
STEAM BBCODE (paste into the Workshop item description)
--------------------------------------------------------------------------------

[h1]Dynamic Recon Ops: Rewrite[/h1]

[i]Built on the legendary Dynamic Recon Ops by mbrdmn — one of the most-played
dynamic mission frameworks in the Arma 3 community. This Rewrite keeps everything
that made DRO great, rebuilds it under the hood for stability, hardens the
existing systems, and adds full lobby-side configuration plus modern AI and ACE
support.[/i]

[b]Every op is procedurally generated:[/b] a fresh Area of Operations, enemy
layout, objectives, weather, and time of day, every single time. Insert by
helicopter, HALO, ground, or boat; hunt an HVT, rescue a hostage, retrieve
intel, destroy a cache, or clear a town — solo or in co-op.

[hr][/hr]

[h1]What's new in this Rewrite[/h1]

[b]⚙ Rebuilt engine, smoother play[/b]
[list]
[*]Full migration to CBA scheduling (per-frame handlers) — fewer frame hitches during spawns and steadier performance in long sessions.
[*]Hardened for multiplayer and dedicated servers: init-order fixes, event-handler leak fixes, and locality fixes.
[*]Faster boot via engine-loaded functions (CfgFunctions).
[/list]

[b]🎛 Configure the whole mission from the lobby[/b]
[list]
[*]New Parameter Override system: set scenario, environment, objectives, factions, insertion and supports straight from the MP [b]Parameters[/b] screen.
[*]Optionally [b]skip the in-game setup UI entirely[/b] — hosts can pre-bake a mission so players drop straight in.
[*]Three independent override spheres, so you can mix (e.g. factions via parameters, everything else via the in-game UI).
[/list]

[b]🧑‍🤝‍🧑 Squad AI on your terms[/b]
[list]
[*]No AI teammates by default — your squad starts with just you and any human players.
[*]The leader adds AI one at a time with a [b]+1 AI[/b] button in Team Planning; the roster updates live and any AI can be removed individually.
[*]AI added this way carries a proper identity and persists through insertion into the mission.
[/list]

[b]🗺 Smarter battlefield population[/b]
[list]
[*]Reworked enemy population across the AO — patrol corridors and seeded adjacent areas make the battlespace feel connected instead of clumped.
[*]Objective variety guard so multi-objective ops spread across different task types.
[*]Off-map spawn protection — no more objectives or hostages generated outside the playable area.
[/list]

[b]🚁 More ways to insert[/b]
[list]
[*]Added [b]Sea (Boat)[/b] insertion — a piloted boat runs you to shore, respecting your chosen insertion point.
[*]Added [b]None[/b] (start on-site) so you continue the mission directly from the staging area — especially immersive for customized DRO scenarios.
[/list]

[b]💥 Mechanized vehicles overhaul[/b]
[list]
[*]Now available for every game mode (Recon Ops / Sniper Ops / Combined Arms), each with its own density cap.
[*]Enemy mechanized forces (APCs and tanks) via a mission budget instead of endless linear growth.
[*]New mechanized [b]density level[/b] parameter (None / Low / Standard / High).
[/list]

[b]🧠 Smarter AI — optional LAMBS Danger[/b]
[list]
[*]When LAMBS is loaded: context-aware pursuit, reinforcement responders, and radio-driven escalation.
[*]Fully soft-compatible — runs fine without it.
[/list]

[b]🩹 ACE3 support — optional[/b]
[list]
[*]New Arsenal toggle; the arsenal integrates with ACE when ACE is loaded.
[*]Works with ACE interaction when present, and falls back cleanly without it.
[/list]

[b]🔧 Refined & fixed[/b]
[list]
[*]The classic DRO game modes (Recon / Sniper / Combined Arms) reviewed and fixed.
[*]Civilian system fixes and improvements, including a performance-friendly [b]agent mode[/b] and a fix for the optional hostile-civilian setting.
[*]Leader-centric Team Planning lobby with a disconnect-handover safeguard.
[*]Numerous bug fixes across revive, objectives, and spawn logic — including a hostage-extraction task that could deadlock and never complete, and intel pickups that could damage nearby buildings.
[/list]

[hr][/hr]

[h1]Requirements[/h1]
[list]
[*][b]Required:[/b] CBA_A3
[*][b]Optional (soft-compatible):[/b] ACE3, LAMBS Danger
[/list]

[h1]Game modes[/h1]
The classic DRO modes, refined in this Rewrite:
[list]
[*][b]Recon Ops[/b] — the baseline experience: full enemy strength, stealth possible, any objective.
[*][b]Sniper Ops[/b] — lean and stealthy: half the enemies, a 2-man marksman team, focus on hunting an HVT.
[*][b]Combined Arms[/b] — open battle: armor on both sides, friendly AI, no stealth.
[/list]

[h1]Credits[/h1]
Original Dynamic Recon Ops by [b]mbrdmn[/b]. All original design credit belongs to
the original author. This Rewrite is a community modification; see the repository
for details and licensing.

--------------------------------------------------------------------------------
SHORT SUMMARY (plain text — for the small description / social copy)
--------------------------------------------------------------------------------

Dynamic Recon Ops: Rewrite — the beloved procedural recon mission by mbrdmn,
rebuilt on CBA for stability and hardened throughout, with full lobby-side
configuration, sea insertion, smarter AO population, a combined-arms overhaul,
and optional ACE3 + LAMBS Danger support. Requires CBA_A3; ACE3 and LAMBS
optional. Solo or co-op.
