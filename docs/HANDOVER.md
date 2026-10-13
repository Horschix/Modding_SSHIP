# Handover - SSHIP submod

Last updated 13 Oct 2026 (first session, 10-13 Oct). Read this first in a new session. The user's standing rules and the tooling notes are in
`docs/HANDOVER.md` of `Horschix/Modding_DAC-EUR` and apply here too; this file only holds what is SSHIP-specific.
On the PC: `D:\Steam\steamapps\common\Medieval II Total War\mods\sship` (the user allowed writing there, 10 Oct).

## Where things stand - START HERE
Repo `eopData/` and `data/` = what is installed in `mods\sship` (only the files we changed; every write read back
and compared byte for byte). Issue board: https://github.com/Horschix/Modding_SSHIP/issues
- #1 Recruitment costs population - CLOSED, works in game (user, 13 Oct).
- #2 Forts -> outposts, step 1 (test version: free, general only) - CLOSED, works in game after the fix of 13 Oct (user).
- #3 Outposts step 2 (four settler units, 500 settlers, 5000 gold, `TEST = false`) - BUILT and installed 13 Oct, every
  file read back and compared, label "needs test". NEXT STEP: the user's test (see the section below), then read full.log.
Still to watch in play: SSHIP's own scripts with a second settlement in a region over many turns; the outpost's map
model, battle map and buildings; disband refund, save/load and AI blocking of #1.
- Logs: our lines (prefixes `POPREC`, `FORTSETT`) are in `mods\sship\full.log` (about 12 MB; staging often needs
  2-3 tries). `mods\sship\eop.log` is SSHIP's own Lua log. Read the log after every user test, before he restarts.
- A new session starts with no folder connected: ask for `...\Medieval II Total War\mods` (covers SSHIP and EUR).
- Changed SSHIP game files (originals in `backups/`): `data/descr_campaign_db.xml`, `data/descr_cultures.txt` (forts),
  `export_descr_unit.txt` in `data`, `data XII\data`, `data XIII\data`, `data/export_descr_buildings.txt`,
  `data/text/export_units.txt` (settlers); new pictures `#<x>_settlers.tga` / `<x>_settlers_info.tga` in
  `ui/units/mercs` / `ui/unit_info/merc` (not in the repo - rebuilt from `cards.txt` of the tool).
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

## Forts -> outposts (minor settlements) - STEP 1 WORKS, STEP 2 INSTALLED (issues #2, #3)
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
STEP 2 (issue #3): see the section "Settlers" at the end. Research notes from before it was built:
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

## Settlers - outposts step 2 (issue #3), built 13 Oct 2026, NOT yet seen in game
Installed 13 Oct, all 14 files read back (6 text files byte for byte, 8 pictures by size).
- `fort_settlement.lua`: `TEST = false` -> window only while the player's fort holds >= 500 men in settler units
  (`SETTLER_UNITS`), button "Found settlement - 5000 gold" (grey below 5000), settler units removed with
  `unit:kill` until 500 men are gone, population = men removed (min 400), `add_money -5000` via `M2TWEOP.callConsole`.
  Message without a general: "A general must lead the settlers into the fort." Dry-run with a mock: 2 units + 9000
  gold -> founded, 2 units killed, 5000 charged; 1 unit -> no window; 3000 gold -> grey button.
- Tool `docs/tools/add_settlers.py <copy of mods\sship> <OUT>` (refuses files that already have the settlers) adds:
  - 4 units at the END of all three `export_descr_unit.txt` (`data`, `data XII\data`, `data XIII\data` - they differ
    only in AI recruit priorities; 494 -> 498 of 500): Catholic / Orthodox / Muslim / Pagan Settlers, dictionary
    `<X>_Settlers`. Models chosen because the model database has a look for EVERY faction of the group:
    `Peasants` (catholic), `Southern_Peasants` (orthodox), `ME_Spear_Militia` (islam), `EE_Spear_Militia` (pagan).
    soldier 100 (= 250 on huge; SSHIP factor 2.5 like EUR: Scoutatoi 60 -> 150 queued), attack 1, armour 0,
    morale 1 low untrained, cost 300, upkeep 100, `no_custom`, `card_pic_dir mercs`, `info_pic_dir merc`.
  - Groups from `descr_sm_factions.txt` religions: catholic 16 (venice sicily denmark scotland france hre england
    portugal poland spain hungary aragon norway jerusalem pisa papal_states), orthodox 5 (byzantium russia kievan_rus
    serbia georgia), islam 6 (abbasid egypt turks moors zengid rum), pagan 2 (cumans lithuania). Left out: slave
    (heretic) and `symbol` (islam, but not in descr_strat - not on the map).
  - Recruitment: 4 `recruit_pool` lines (2 / 1 / 2 / 0, `requires factions {...} and event_counter is_the_player 1`)
    at the top of the first capability block of all 5 levels of `core_building` and all 5 of `core_castle_building`
    (the wall / town hall buildings - SSHIP has no recruitment there otherwise). Lines marked `;--- Modding_SSHIP #3`.
  - Texts in `text/export_units.txt` (UTF-16): name, short and long description per unit. The game rebuilds
    `export_units.txt.strings.bin` itself because the .txt is newer.
  - Cards (copies, see `cards.txt`): Hunters (catholic), Slav Levies (orthodox), Syrian Auxiliaries (muslim), Woodsmen (pagan).
- Recruiting settlers costs the settlement 250 people (#1); founding gives them back as the outpost's people.
- UNKNOWN until tested: whether the game starts with the unit / building changes in the existing campaign (units were
  appended at the end, so old saves should keep their unit indices) or needs a new one; whether `is_the_player`
  hides them from the AI as intended; the cards; the models in battle.
- If the game does not load: restore the five text files from `backups/2026-10-13_before_settlers/` (keeps the forts
  and the test-free founding only if `TEST` is set back to true).

### First test of the settlers (user, 13 Oct, NEW Byzantine campaign) and fix
- Game starts. The settlers show in the building info of the wall / castle line, but NOT in the recruitment panel.
  Not our population script (no POPREC line in full.log at all - nothing was withheld).
- Cause: SSHIP sets `is_the_player` / `is_the_ai` only in `globalEvents.isPlayer(faction)`, called from
  `onPreFactionTurnStart` (main.lua). When a new campaign is set up the counter is 0, so the pools start at 0 instead of
  the initial 2, and refilled by 0.1 per turn the first unit would have appeared after 10 turns. SSHIP's own
  player-only recruit lines (82 of them) start at 0 anyway.
- FIX installed 13 Oct, read back identical: refill 1 per turn (pool max still 2), in the tool and the building file
  (only the 40 settler lines changed). Expected: settlers recruitable from the player's next turn.
- If they still do not appear after a turn end: check `freeze_recr_pool` / the 64-entry recruitment limit per
  settlement, or give the stock from Lua at the player's turn start.
