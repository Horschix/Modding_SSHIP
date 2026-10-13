# Handover - SSHIP submod

Last updated 13 Oct 2026 (handover slimmed to save usage; first session 10-13 Oct). Read this file first in a new
session - it is deliberately short and self-contained. Feature detail lives in `docs/notes/features/` and is read ONLY
when a task needs it: `01_population_recruitment.md` (#1), `02_03_outposts_settlers.md` (#2, #3),
`04_starting_settlements.md` (#4). The full tooling notes are in `docs/HANDOVER.md` of `Horschix/Modding_DAC-EUR`,
section "How the tooling behaves" - look there only when a tool misbehaves.
On the PC: `D:\Steam\steamapps\common\Medieval II Total War\mods\sship` (the user allowed writing there, 10 Oct).

## Start of a session
1. Add the repo (`Horschix/Modding_SSHIP`), clone it to `/home/claude/modding_sship`, then run
   `bash docs/tools/session_setup.sh` ONCE: builds Lua 5.1, prints the current state and the open issues.
2. Ask for PC folder access only when the task needs the PC (`...\Medieval II Total War\mods` covers SSHIP and EUR).
3. Open the feature note of the issue being worked on - not the others.

## Working efficiently (user's wish, 13 Oct 2026 - keep in force)
The user's plan has a usage limit. Every tool call re-reads the whole conversation, so long chats and many small
calls are what burn it.
- One issue (for #4: one region) per chat. When it is installed and documented, say so and suggest a new chat.
- Ask ALL open questions of a plan in ONE message; invite the user to answer them (and add extras) in one reply.
- Model: suggest Sonnet for routine work (board and handover updates, small data-file edits, installs of already-built
  files) and Opus for engine debugging, Lua scripting, map work and tricky design. Claude cannot switch the model
  itself - the user picks it in the model selector. Do not spawn subagents (each starts cold and costs more).
- Verify once per install, as a batch (standing rule 6).
- Logs: `full.log` is about 12 MB - never stage it whole. Ask the user to cut it on the PC first, e.g. in PowerShell
  `Select-String -Path full.log -Pattern "POPREC|FORTSETT|SETTCHK" > hits.txt` or `Get-Content full.log -Tail 3000 > tail.txt`.
  Read logs in the session with grep / tail, never in full.
- Maps (#4): agree the town list, coordinates and passes as a text table first; render one check image at the end.
- Never print big files, listings or diffs into the conversation - search them with grep / scripts and show the result.
- Keep this file short: new detail goes into the feature note; only status, rules and the issue list stay here.

## Standing rules (1-4 and 6 set by the user, 5 learned the hard way in EUR - keep in force)
1. On the PC only touch `D:\Steam\steamapps\common\Medieval II Total War`; here: `mods\sship` (allowed 10 Oct).
2. Name the solution before coding. For anything with design choices: give an overview, wait for the go-ahead.
3. Copy every original file into this repo (`backups/`) before changing it for the first time.
4. Go step by step (one feature at a time; test version first where it helps).
5. Scripts must never call `M2TWEOP.*` / `M2TW.*` at file level (only inside event functions).
6. (13 Oct 2026, to save usage) Every written file is still read back and compared byte for byte, but ONCE per install:
   commit all changed files of one install in one batch, wait, re-stage them in one call and compare them all in one
   `cmp` loop. Not after every single write.

## Where things stand - START HERE
Repo `eopData/` and `data/` = what is installed in `mods\sship` (only the files we changed; every write read back
and compared byte for byte). Issue board: https://github.com/Horschix/Modding_SSHIP/issues
- #1 Recruitment costs population - CLOSED, works in game (user, 13 Oct).
- #2 Forts -> outposts, step 1 (test version: free, general only) - CLOSED, works in game after the fix of 13 Oct (user).
- #3 Outposts step 2 (four settler units, 500 settlers, 5000 gold, `TEST = false`) - CLOSED 13 Oct, works as intended
  (user). Settlers recruitable from turn 2 of a new campaign - accepted by the user.
- #4 Settlements that existed in 1132 - ANATOLIA DONE, WORKS (user, 13 Oct): 20 towns, starter buildings, garrisons,
  names by culture, roads / farms buildable in them, map edits (Nicaea moved, Sinop's port, passes, Kastamonu and the
  south coast opened). Engine confirmed all 7 test routes (getMovePath, 13 Oct). Kept OPEN for the other regions
  (user: "we will add the settlements for other game regions later"). Details: `docs/notes/features/04_starting_settlements.md`.
CAUCASUS DONE, WORKS (user, 13 Oct, test 2): 20 towns, all reachable after moving 5 off low-mountain tiles; Georgia's
  region towns level 1; Ganja, Sukhumi, Artanuji start as rebels (entry field `ownerFrom`); downgrades confirmed.
UPPER MESOPOTAMIA DONE (user moved on, 13 Oct): 14 towns.
SYRIA AND THE LEVANT DONE (user, 13 Oct): 10 towns. New name key `arabic` (egypt / abbasid / moors).
NORTH AFRICA DONE (user, 13 Oct): 31 towns.
LOWER MESOPOTAMIA + PERSIA DONE (user, 14 Oct): 34 towns.
ARABIA + STEPPE + VOLGA installed 14 Oct, fix 1 read back identical: 10 towns; Saqsin moved to the Cumans in descr_strat (Siberia: nothing on the map). No map edit.
  Waiting for the user's test in a new campaign (DUMP has 9 routes; read STARTSETT lines in full.log).
  THEN: the user picks the next region for #4 (same method: EU5 07_cities_and_buildings.txt + Wikipedia check,
  GPS projection, map_regions / ground / heights check, corridors with ramped heights where terrain blocks).
  LESSON from the Caucasus: avoid low-mountain tiles for towns (non-mountain ground, 3x3 relief <= 60, >= 3 open
  neighbours) - the BFS model is too lenient there and getMovePath is unreliable on long routes.
DUMP stays on as the route checker (settler_check.lua deleted by the user, 14 Oct).
Still to watch in play: SSHIP's own scripts with extra settlements in a region over many turns (Nicaea region has
five); the outpost's map model, battle map and buildings; disband refund, save/load and AI blocking of #1; whether a
farm / road queued in an extra settlement finishes after the hinterland flag is restored at turn start.
- Logs: our lines (prefixes `POPREC`, `FORTSETT`) are in `mods\sship\full.log` (about 12 MB; staging often needs
  2-3 tries). `mods\sship\eop.log` is SSHIP's own Lua log. Read the log after every user test, before he restarts.
- A new session starts with no folder connected: ask for `...\Medieval II Total War\mods` (covers SSHIP and EUR).
- Map files changed for #4 (originals in `backups/2026-10-13_before_map/`, rebuilt by `docs/tools/edit_map.py`):
  `data/world/maps/base/map_regions.tga`, `map_ground_types.tga`, `map_heights.tga`, `map_features.tga`, `campaign/imperial_campaign/
  descr_strat.txt`, `descr_events.txt`. After any map change the user must delete `map.rwm` (session cannot delete).
- Changed SSHIP game files (originals in `backups/`): `data/descr_campaign_db.xml`, `data/descr_cultures.txt` (forts),
  `export_descr_unit.txt` in `data`, `data XII\data`, `data XIII\data`, `data/export_descr_buildings.txt`,
  `data/text/export_units.txt` (settlers); new pictures `#<x>_settlers.tga` / `<x>_settlers_info.tga` in
  `ui/units/mercs` / `ui/unit_info/merc` (not in the repo - rebuilt from `cards.txt` of the tool).
- `luaPluginScript.lua` ends with three require lines: population_recruitment, fort_settlement and
  starting_settlements (#4). Revert = delete the line. `fort_settlement.lua` also sets the counters `hx_player_<faction>` that the
  settler recruit lines need - removing it stops settler recruitment too.

## Tooling
- `docs/tools/session_setup.sh` builds Lua 5.1 (`/home/claude/.tools/lua51`); syntax-check every Lua file with it.
- The session cannot create repos or delete branches on GitHub; the user does that by hand.
- EUR note of 10 Oct: a turn-end crash in EUR came right after two `onRemoveFromUnitQueue` events (cause open, trace
  lines added there). SSHIP runs the same population code - read the log before a restart if SSHIP crashes at turn end.
