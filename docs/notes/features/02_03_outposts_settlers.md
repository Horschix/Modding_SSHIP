# Forts -> outposts (minor settlements) - BOTH STEPS WORK (issues #2, #3, closed)

Moved out of `docs/HANDOVER.md` on 13 Oct 2026 (unchanged). Read only when working on this issue.
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

## First test of step 1 (user, 13 Oct; logs read) and fix
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

# Settlers - outposts step 2 (issue #3), built 13 Oct 2026, WORKS (user, 13 Oct, fourth test)
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
  - Recruitment (CHANGED 13 Oct, see "Third test" below): one `recruit_pool` line PER FACTION (29), 2 / 1 / 2 / 0,
    `requires factions { <f>, } and event_counter hx_player_<f> 1` - first version used is_the_player and failed.
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

## First test of the settlers (user, 13 Oct, NEW Byzantine campaign) and fix
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

## Second test of the settlers (user, 13 Oct, after the refill fix): still not in the recruitment panel
- User started ANOTHER new Byzantine campaign (eop.log: "NEW GAME CREATED" 16:16) and played one turn: settlers still
  missing. `is_the_player` is set for byzantium at its pre-turn (seen in eop.log). No POPREC / settler lines in full.log.
- The game also crashed when closed. full.log ends with the normal shutdown lines (trigger statistics), eop.log with
  "Scroll closed" lines - nothing points at our scripts. Watch whether it repeats.
- Suspect: the engine keeps at most 64 recruitment capabilities per settlement (LuaDocs: getRecruitmentCapability
  "max 64!") and SSHIP's lists are long - lines past 64 may be dropped.
- CHECK installed 13 Oct, read back identical: `eopData\eopScripts\sship\settler_check.lua` + a THIRD require line in
  `luaPluginScript.lua` (marked TEMPORARY). For each player settlement selected / recruitment panel opened (once per
  turn) it logs `SETTCHK` lines: is_the_player, number of capabilities and pools, the settler capability and stock if
  present, and the last 5 capabilities. Changes nothing. Remove the require line after the diagnosis.

## Third test (user, 13 Oct; SETTCHK lines read) - cause found and fixed
- User: still no settlers; 1-10 recruitment entries per settlement (so NOT the 64 limit). SETTCHK for Constantinople,
  Nicaea, Adrianople, Tarnovo, Thessalonica, Sredets: `is_the_player 1`, settler capability present as entry 0
  ("Orthodox Settlers initial 2 refill 1 max 2"), but NO recruitment pool for it - pools 11 for 12 capabilities in
  Constantinople, etc. So the unit is in the list but never gets any stock.
- Cause (inference from that): the engine fills the stock at a faction's turn start BEFORE SSHIP sets is_the_player in
  onPreFactionTurnStart, i.e. while the counter still holds the previous (AI) faction's 0. The building info and the
  check read the counter later, when it is 1. SSHIP's own 82 positive `is_the_player 1` recruit lines (Smolensk
  Infantry etc., all also needing faction_size_small and a leap-year counter) probably never get stock either -
  not checked, not ours.
- FIX installed 13 Oct, all three files read back identical: per-faction counters `hx_player_<faction>` (1 for the
  player's faction, 0 for the others; only written when the value changes, logged as `FORTSETT counters (...)`), set in
  `fort_settlement.lua` after SSHIP's onCampaignMapLoaded, onNewGameStart and onPreFactionTurnStart. They do not flip
  during the turn order, so they are right whenever the engine fills the stock. Building file: 29 lines per level
  (each faction only its own settler type), 290 + 10 marker lines. Mock: counters set, SSHIP's hook still called,
  founding dry run unchanged. settler_check.lua now also logs hx_player_<owner>.
- Expected: settlers in the recruitment panel from the first player turn after loading (stock 2, then +1 per turn).
- STILL TO DO after the next test: remove settler_check.lua's require line if the settlers work.

## Fourth test (user, 13 Oct): WORKS
- "It works as intended now, but only at turn 2 which is fine." Turn 1 of a new campaign has no settler stock: the
  stock is filled at turn start, and on a new game the counters are only set afterwards (map loaded). Accepted.
- Issue #3 closed. settler_check.lua still loaded (leftover above).
