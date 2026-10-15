# Handover - SSHIP submod

Last updated 14 Oct 2026, Romania done (handover slimmed to save usage; first session 10-13 Oct). Read this file first in a new
session - it is deliberately short and self-contained. Feature detail lives in `docs/notes/features/` and is read ONLY
when a task needs it: `01_population_recruitment.md` (#1), `02_03_outposts_settlers.md` (#2, #3),
`04_starting_settlements.md` (#4), `05_historic_invasions.md` (#5), `07_mongol_islam.md` (#7). The full tooling notes are in `docs/HANDOVER.md` of `Horschix/Modding_DAC-EUR`,
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
- Campaign AI (15 Oct 2026): Gracul AI installed; test 1 passive -> FIX installed 15 Oct: VH label switch OFF,
  slave target factor 6 (<15) / 3 (<50) / 1; awaiting test 2. See note 06. Karahisar repair bug: TEMPORARY
  `building_diag.lua` (log prefix BDIAG, require line at the end of luaPluginScript) installed 15 Oct. Details: `docs/notes/features/06_campaign_ai.md`.
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
ARABIA + STEPPE + VOLGA DONE (user moved on, 14 Oct): 10 towns; Saqsin moved to the Cumans in descr_strat.
RUSSIA + MUSCAT installed 14 Oct, read back identical: 15 Rus' towns (Tver, Moscow [ownerFrom Suzdal = Kievan Rus],
  Vologda, Beloozero, Murom, Nizhny, Pronsk, Minsk, Vitebsk, Brest, Lutsk, Lviv, Przemysl, Starodub, Toropets) + Muscat (Oman);
  Rostov moved to Novgorod in descr_strat; Jeddah moved to 358,5; Khaybar removed. Pskov = SSHIP's "Pleskov" (name kept).
  CAMPAIGN TEST 14 Oct (Rum, turn 17): towns work, AI takes rebel towns, BUT AI civil wars - cause = SSHIP's
  internalAffairs.lua counted every settlement over 10 as +10 revolt points; now 2.5 (installed 14 Oct, see note end).
  Offered, not taken (yet): Pskov-region towns, Tartu / Otepaa, Koknese / Jersika, Sohar, Julfar, Qatar.
BALKANS + GREECE DONE, WORKS (user, 14 Oct): 25 towns, Rhodes a castle, Lycian coast corridor.
POLAND + BALTIC DONE, WORKS (user, 15 Oct): 22 towns (fix 1: Krakow and Szczecin moved, map round 6, new campaign).
HUNGARY + CROATIA installed 15 Oct, fix 1 + fix 2 installed 15 Oct (read back identical): 11 towns (Buda 3/15000 +
  Pest 1/500; Pecs, Sopron, Szeged, Bratislava, Kosice, Krupina 2/7500, owner hungary; Knin, Rijeka, Trieste 2/7500,
  rebels via ownerFrom - Trieste sits on real Venice_Province territory, no map edit needed there). GARRISON.hungary
  fixed to EE Spear Militia (plain Spear Militia isn't ownable by hungary - user caught it in testing); hre/serbia
  confirmed fine as-is. MAP ROUND 7 (edit_map.py CITY_MOVES): Zagreb's own settlement moved 193,177 -> 193,175 (user
  tested first) - governor + plague event position moved with it by hand, NOT via edit_map.py's regenerated
  descr_strat/descr_events output (CAUTION note added to the tool: it always rebuilds those two files from the pre-
  map-edit backup, which would revert every other #4 round's direct descr_strat.txt edits since). map.rwm deleted
  again; NEW campaign. Still open: "Eger" - not a vanilla SSHIP settlement and not an EU5 ranked town either; need
  the user to say where to place it. See `docs/notes/features/04_starting_settlements.md` for full detail.
ROMANIA installed 14 Oct, read back identical (script only, NEW campaign): 20 towns in Transylvania, Partium, Banat,
  Wallachia, Moldavia, Danube mouth, Dobruja - see the feature note. User tests it together with Hungary + Croatia
  fix 2 and the Eger question. FIX 1 installed 14 Oct (read back identical): Eger dropped (= SSHIP's Esztergom);
  map.rwm had not been rebuilt (older than map_regions.tga) - cause of "Zagreb not moved"; names transliterated to
  SSHIP's glyphs; our Targoviste removed (SSHIP's Severin is Targoviste); Tarnovo + Cherven/Drastar/Vidin/Isaccea to
  Bulgarian rebels; 14 script moves + MAP ROUND 8 (Iasi, Ragusa, Arta). User: delete map.rwm, NEW campaign.
  FIX 2 installed 14 Oct (read back identical): Varna 1 west (277,156), Sliven 1 south (267,153). ROMANIA DONE
  (user moved on to the next region, 14 Oct).
IBERIA installed 14 Oct, read back identical (script only, NEW campaign, map.rwm stays): 44 towns (spain 11, aragon 8,
  portugal 4, moors 21; Lleida / Tortosa / Cuenca / Morella moors via ownerFrom Valencia)). FIX 1 installed 14 Oct (read
  back identical): 13 removed, Bilbao added, Algeciras 1 east, SSHIP's Salamanca renamed Valladolid (text file) and our
  Salamanca on 31,138, Isaccea priest moved -> 32 towns. IBERIA DONE (user, 14 Oct).
ITALY + ISLANDS installed 14 Oct, read back identical (script only, NEW campaign, map.rwm stays): 55 towns incl.
  Mdina (Malta) and Bonifacio (Corsica) - see the feature note. Malta works. FIX 1 installed 14 Oct
  (read back identical): 8 removed, 10 moved, Malta a castle, Reggio moved (MAP ROUND 9), Italian garrisons = Urban Spear
  Militia -> 47 towns; fix 2: Udine back as rebels (48). User: delete map.rwm, NEW campaign. ITALY DONE (user, 14 Oct).
FRANCE installed 14 Oct, read back identical (script only, NEW campaign, map.rwm stays): 34 towns (france 7,
  england 3, hre 6 incl. Le Puy, rebels 18) - see the feature note. FIX 1 installed 14 Oct (read back identical):
  Sens, Nimes, Perpignan removed; Saint-Omer -> Calais; 4 moves; MAP ROUND 10 = Alpine pass Turin - Aosta - Great
  St Bernard - Valais (Lake Geneva) -> 31 towns. User: delete map.rwm, NEW campaign. Waiting for the user's test.
BRITISH ISLES installed 14 Oct, read back identical (script only, NEW campaign, map.rwm stays): 17 EU5 towns
  (england 7, scotland 3, Irish rebels 7 with Irish Kerns) - see the feature note. FIX 1 installed 14 Oct (read back
  identical): Lynn removed; Exeter, Cardiff, Lancaster, Glasgow, Downpatrick added -> 21 towns. Waiting for the user's test.
  Install tip: use a NEW output file name per install (a reused one re-sent an old cached copy).
HRE installed 14 Oct, read back identical (script only, NEW campaign, map.rwm stays): 51 towns (hre 36, rebels 15) -
  see the feature note. FIX 1 installed 14 Oct (read back identical): 4 removed, 4 moved, Amsterdam + Marburg added -> 49.
  Waiting for the user's test.
  SCANDINAVIA + GAP ROUND + bigger starter pack were installed by another session but NOT committed until 15 Oct
  (taken from the PC). 15 Oct: Marburg 193,181 -> 195,180 (Hungarian region tile, owner from Freiberg = hre), Ljubljana
  (Laibach) added 185,176 level 1 / 1000, owner hre - read back identical, NEW campaign.
  Same method (EU5 07_cities_and_buildings.txt + Wikipedia check,
  GPS projection, map_regions / ground / heights check, corridors with ramped heights where terrain blocks).
  LESSON from the Caucasus: avoid low-mountain tiles for towns (non-mountain ground, 3x3 relief <= 60, >= 3 open
  neighbours) - the BFS model is too lenient there and getMovePath is unreliable on long routes.
#7 Mongols convert to Islam (turn 340) - test worked, FINAL installed 15 Oct (read back identical); Mongols start pagan. Detail: `docs/notes/features/07_mongol_islam.md`.
#5 Historic invasion armies - OPEN. Fourth Crusade TEST version installed 15 Oct (read back identical):
  `historic_invasions.lua` + require line; Zara stage turn 2, Constantinople stage turn 5 while `TEST = true`
  (final 140 / 145). Test 1: Constantinople works; Zara failed (Dandolo 90 died) - FIX 1 installed 15 Oct
  (age 65 + fallback army search). FINAL turns (140/145, TEST = false) installed 15 Oct on the user's word. Detail: `docs/notes/features/05_historic_invasions.md`.
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
- Changed SSHIP game files (originals in `backups/`): `eopData/eopScripts/sship/internalAffairs.lua` (civil war), `data/descr_campaign_db.xml`, `data/descr_cultures.txt` (forts),
  `export_descr_unit.txt` in `data`, `data XII\data`, `data XIII\data`, `data/export_descr_buildings.txt`,
  `data/text/export_units.txt` (settlers); new pictures `#<x>_settlers.tga` / `<x>_settlers_info.tga` in
  `ui/units/mercs` / `ui/unit_info/merc` (not in the repo - rebuilt from `cards.txt` of the tool).
- `luaPluginScript.lua` ends with five require lines: population_recruitment, fort_settlement,
  starting_settlements (#4), historic_invasions (#5) and mongol_islam (#7). Revert = delete the line. `fort_settlement.lua` also sets the counters `hx_player_<faction>` that the
  settler recruit lines need - removing it stops settler recruitment too.

## Tooling
- `docs/tools/session_setup.sh` builds Lua 5.1 (`/home/claude/.tools/lua51`); syntax-check every Lua file with it.
- The session cannot create repos or delete branches on GitHub; the user does that by hand.
- EUR note of 10 Oct: a turn-end crash in EUR came right after two `onRemoveFromUnitQueue` events (cause open, trace
  lines added there). SSHIP runs the same population code - read the log before a restart if SSHIP crashes at turn end.
