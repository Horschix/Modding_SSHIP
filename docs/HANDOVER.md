# Handover - SSHIP submod

Last updated 13 Oct 2026 (first session, 10-13 Oct). Read this first in a new session. The user's standing rules and the tooling notes are in
`docs/HANDOVER.md` of `Horschix/Modding_DAC-EUR` and apply here too; this file only holds what is SSHIP-specific.
On the PC: `D:\Steam\steamapps\common\Medieval II Total War\mods\sship` (the user allowed writing there, 10 Oct).

## Where things stand - START HERE
Repo `eopData/` and `data/` = what is installed in `mods\sship` (only the files we changed; every write read back
and compared byte for byte). Issue board: https://github.com/Horschix/Modding_SSHIP/issues
- #1 Recruitment costs population - CLOSED, works in game (user, 13 Oct).
- #2 Forts -> outposts, step 1 (test version: free, general only) - CLOSED, works in game after the fix of 13 Oct (user).
- #3 Outposts step 2 (four settler units, 500 settlers, 5000 gold, `TEST = false`) - OPEN, NOT built. NEXT STEP.
Still to watch in play: SSHIP's own scripts with a second settlement in a region over many turns; the outpost's map
model, battle map and buildings; disband refund, save/load and AI blocking of #1.
- Logs: our lines (prefixes `POPREC`, `FORTSETT`) are in `mods\sship\full.log` (about 12 MB; staging often needs
  2-3 tries). `mods\sship\eop.log` is SSHIP's own Lua log. Read the log after every user test, before he restarts.
- A new session starts with no folder connected: ask for `...\Medieval II Total War\mods` (covers SSHIP and EUR).
- `luaPluginScript.lua` ends with two require lines: population_recruitment, fort_settlement. Revert = delete the line.

## Recruitment costs population (10 Oct 2026) - how it works
User wish: port the population cost for recruitment from EUR (Modding_DAC-EUR issue #5) to SSHIP.
Minimums stay 400 (player) / 1000 (AI) - user decision.
- INSTALLED 10 Oct, read back and compared byte for byte. WORKS in game (user, 13 Oct: queue / cancel seen in the log):
  `eopData\eopScripts\sship\population_recruitment.lua` (log prefix `POPREC`, lands in `mods\sship\full.log`) and one
  `require('sship.population_recruitment')` line at the END of `eopData\eopScripts\luaPluginScript.lua`
  (after `require('sship.main')`, which defines the event and save/load functions the script wraps).
- Revert: delete the require line (original loader in `backups/2026-10-10_original/`).
- Rules (same as EUR): queue = minus the unit's soldiers 1:1, cancel = refund, retraining = only the missing men,
  too few people = unit greyed out, player disband = men back to the settlement, state saved with the savegame.
- Differences to the EUR script (all else is comments): EXEMPT_TYPES is empty; garrison rule is a name that STARTS
  with "garrison " (SSHIP's `Garrison spear / sword / archers / crossbowmen`, in no recruit_pool of the building
  file = script-only). Free: ships, agents, bodyguards, those four. Elephants and siege cost their crew.
- Findings: SSHIP runs on the same M2TWEOP, its LuaDocs list every function used; SSHIP's own Lua uses none of the
  queue / trained / disbanded events (`populationCap.lua` is an unfinished army cap). 199 settlements start with
  800-101000 people (median 7900; 3 below 1000, 13 below 1500); units 20-80 soldiers in the unit file.
- NOT checked: whether SSHIP scripts disband or replace PLAYER units (would refund men never charged); whether an
  existing SSHIP save loads cleanly (state simply starts empty). Passes `loadfile` with the session's Lua 5.1.

## Tooling found on 10 Oct
- A Lua 5.1 can be built in the session (see the EUR handover): `git clone --depth 1 --branch v5.1.1 https://github.com/lua/lua`,
  `gcc -w -o lua51 $(ls *.c | grep -v "luac.c\|print.c") -lm`. Both our scripts pass `loadfile`.
- The session cannot create repos or delete branches on GitHub; the user does that by hand.
- EUR note of 10 Oct: a turn-end crash in EUR came right after two `onRemoveFromUnitQueue` events (cause open, trace
  lines added there). SSHIP runs the same population code - read the log before a restart if SSHIP crashes at turn end.

## Forts -> outposts (minor settlements) - STEP 1 of 2 WORKS (issues #2, #3)
User wish: port EUR's "fort upgradable to a minor settlement" (Modding_DAC-EUR #35). Decisions: two steps; fort
price 2000; founding an outpost costs 5000 in the final version; settlers = FOUR units, one each for catholic,
muslim, orthodox and pagan factions (numbers as in EUR unless he says otherwise: 250 men on his unit size, cost 300,
upkeep 100, 500 men needed, player only).
STEP 1 = TEST VERSION, INSTALLED 10 Oct (fix 13 Oct), WORKS in game (user, 13 Oct):
- `data\descr_campaign_db.xml`: `can_build_forts` false -> true (`destroy_empty_forts` was already true: empty forts
  vanish). `data\descr_cultures.txt`: `fort_cost` 20000 -> 2000 (5 cultures). Originals in `backups/2026-10-10_original/data/`.
  SSHIP's starting map has no forts. The AI may build forts now too (`allow_enemy_forts` stays false).
- `eopData\eopScripts\sship\fort_settlement.lua` (log prefix `FORTSETT`) + a second require line at the end of
  `luaPluginScript.lua`. `TEST = true` at the top: FREE and NO settlers - a general standing in one of the player's
  forts gets the window "Found an outpost" (draggable) with the button "Found settlement (test, free)". The army
  steps out, fort -> town `hxsett_<x>_<y>` shown as "Outpost of <region>", army walks back in.
- Changes against the EUR script: player found through `M2TW.campaign:getPlayerFaction(0)`; factions iterated with
  `numberOfFactions` / `getFactionByOrder` (SSHIP's docs have no `stratmap.game.getFactionsCount`); no `minor_sett`
  marker building (not in SSHIP); only the player's OWN forts count; window uses SSHIP's `SCREEN` size; EUR's
  starting-fort block and fort-button override dropped. Dry-run against a mocked game in the session: full
  sequence ran (step out, fort deleted, settlement added, walk in).
- STILL OPEN after the working test: does SSHIP cope LONG-TERM with a second settlement in a region? SSHIP's own Lua loops over
  settlements in about 50 places and none checks `isMinorSettlement`. Read `mods\sship\full.log` for Lua errors. Also unreported: map model, battle map, what can be built in the outpost. The fort
  changes worked in the user's existing Byzantine campaign (no new campaign was needed).
STEP 2 (issue #3, not built): four settler units + recruit lines + `TEST = false`.
- 494 of 500 unit slots are used in `data\export_descr_unit.txt` - four fit.
- `data XII\data` and `data XIII\data` hold their OWN `export_descr_unit.txt` (era variants, swapped in by the
  launcher presumably): the settler units must go into all three files.
- Player-only recruit lines: SSHIP's building file already uses `event_counter is_the_player 1` (2228 times).
- SSHIP peasant units are split by culture (`Peasants`, `Southern_Peasants`, `EE_Peasants`, ...): candidate models.
- Unit names prepared in the script: Catholic / Orthodox / Muslim / Pagan Settlers.

### First test of step 1 (user, 13 Oct; logs read) and fix
- Game starts; population cost works (POPREC lines: queue / cancel in Constantinople correct); fort building works.
- LOGS: our lines (`M2TWEOP.logGame`) go to `mods\sship\full.log` (12 MB, staging needed 2-3 tries), NOT to `eop.log`
  (SSHIP's own Lua log) and not to `logs\system.log.txt`. 
- Founding failed: log `moveTactical false/no army, moveToTile true/nil`. In SSHIP's engine a general standing in a
  fort has `character.army == nil` (the troops are the fort's army). `character:moveToTile` moved him once, but not
  onto the chosen tile, so the script (which waited for exactly that tile) gave up after 12 s; once he did not move at all.
- FIX installed 13 Oct, read back identical, dry-run against a mock that copies this behaviour: the order goes to
  `tile.fort.army:moveTactical` when the character has no army; if he is still in the fort after 3 s the next free
  land tile beside it is tried (straight neighbours first, `isLand`, no cliff); success = nobody left on the fort tile,
  wherever he stands; walking back in uses whoever of them stands within 2 tiles.
- Unrelated: SSHIP's own building file logs many "Script Error ... export_descr_buildings.txt, at line 44774" at start -
  not ours (that file is untouched).
- RESULT (user, 13 Oct): "it works" - founding from inside the fort now goes through. Issues #1 and #2 closed.
