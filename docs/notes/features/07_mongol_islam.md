# 07 - Mongols convert to Islam (15 Oct 2026)

User's decisions (15 Oct): conversion at turn 340 (timescale 0.5, turn = (year-1132)*2+1 -> ~1301; historic window
Ghazan 1295 = t327 .. Ozbeg 1313 = t363); always (only condition: Mongols alive); Tengri temples become mosques;
population religion shifts naturally (not touched); no player choice (mongols = emerging AI-only faction).

Start religion: `data/descr_sm_factions.txt` line 590 was `islam` (user's April 2026 edit) -> back to `pagan`
(backup of the islam version in `backups/2026-10-15_before_mongol_religion/`). Needs a NEW campaign.

## Files
- `eopData/eopScripts/sship/mongol_islam.lua` (require line at the end of luaPluginScript.lua). Log prefix `MONGISL`.
  After-hook on onFactionTurnStart. Mongol turn start: if counter `mongols_islam` = 0 and turn >= CONVERT_TURN and
  settlementsNum > 0 -> `faction.religion = M2TWEOP.getReligion("islam")` (fallback 2), counter = 1, every Tengri temple
  destroyed and the matching mosque created (tengir_altar->small_masjid, tengir_sanctuary->masjid,
  tengir_temple->minareted_masjid, c_tengir_altar->c_small_masjid), historic event "The Mongols embrace Islam" to
  players. Later Mongol turns: religion re-set if it was lost (save/load), temples in newly taken settlements converted.
- `data/export_descr_buildings.txt`, 11 lines: the 7 mosque levels get
  `factions { mongols, } and event_counter mongols_islam 1 or <old faction list> and <old builders rule>`;
  the 4 Tengri levels get `factions { mongols, } and not event_counter mongols_islam 1 and hidden_resource tartars or
  factions { cumans, } and hidden_resource tartars` (Cumans unchanged). Order chosen so the result is right whether
  the engine reads and/or left to right or with and-before-or.

## Test version (TEST = true)
Turn 2: script spawns one Mongol army (13 units + general) by Urgench and takes it at once (`siegeSettlement(s, true)`,
like SSHIP's Konjikala). Mongol turn start with a settlement (turn 2/3) -> conversion. Check in game: religion pip /
faction religion, imams instead of shamans, mosque buildable in Urgench, Tengri gone, event shown, save + load keeps
islam (log line "religion was ... set again" would show a reset). Final: `TEST = false` -> turn 340, no test spawn.

## Status
- 15 Oct: test version installed, read back identical. Waiting for the user's test (NEW campaign).
- 15 Oct, TEST worked (user): test army sacked Urgench (went rebel), then took Merv turn 10, converted turn 12.
  FINAL installed 15 Oct (TEST = false -> turn 340, no test spawn), read back identical.
