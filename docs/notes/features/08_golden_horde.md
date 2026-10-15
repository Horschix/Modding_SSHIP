# 08 - Cumans become the Golden Horde, Mongols = Ilkhanate (15 Oct 2026)

User's decisions (15 Oct): colours swapped (Cumans <- Mongol gold, Mongols <- Abbasid black, Abbasids <- Cuman
brown); Cumans become the Golden Horde at turn 221 (1242) - AI at once, player by yes/no choice; full Mongol roster
(minus the dhow) plus kept Cuman units (Cuman Horse Militia, Dismounted Cuman Militia, Kasogi, Kasogi Senior Militia,
ladya, EE Spear Militia); Cuman nobles dropped (Behk / Khagan Druzhina + dismounted, Cuman Bodyguard); generals get
Keshikten. Cumans turn Muslim at turn 361 ALWAYS (also when the player said no). Mongols (= Ilkhanate) convert at
327 (Ghazan 1295; was 340). After conversion both get Mutatawwi Warriors, Ahdath Militia, Naffatun, Ghulams,
Dismounted Ghulams; the Cumans also Muslim Settlers instead of Pagan Settlers. Turn = (year - 1132) * 2 + 1.

## Files
- `eopData/eopScripts/sship/golden_horde.lua` (new, require line after mongol_islam). Log prefix `GHORDE`.
  Counters: golden_horde (1 = GH), golden_horde_asked, golden_horde_no, cumans_islam; choice event GOLDEN_HORDE
  (answer = GOLDEN_HORDE_accepted / _declined, like SSHIP's own choice events in main.lua).
  Name "Golden Horde" via factionStruct.localizedName (EUR's eurEvolvingFactions.lua does the same).
  Unit ownership is set by script (eduEntry:setOwnership) - NOT stored in saves, so it is set again at every Cuman
  turn start and on onCampaignMapLoaded. Static EDU ownership left unchanged on purpose: the Mongol lines with
  "or hidden_resource ..." would otherwise let the Cumans recruit Mongol units before the event.
- `mongol_islam.lua`: CONVERT_TURN 327; Muslim units owned by script (same reapply rule); event text Ilkhanate only.
- `data/export_descr_buildings.txt` via `docs/tools/golden_horde_edb.py`: 165 Cuman copies of Mongol-only recruit
  lines (a line with " or " split into one copy per or-part), 72 Muslim-unit copies (donor lines: Mutatawwi = the
  six-faction list, Ahdath = abbasid/zengid, Naffatun = egypt list, Ghulams = turks/rum, Muslim Settlers = turks,
  Cumans only, hx_player_cumans), 7 mosque levels get "factions { cumans, } and event_counter cumans_islam 1 or "
  in front, 4 Tengri levels: Cumans only while not cumans_islam.
- `data/unit_models/battle_models.modeldb` via `docs/tools/bmdb_add_faction.py`: texture records added (cumans for
  7 Mongol models, mongols + cumans for the 6 Muslim models; donor mongols / turks / merc).
- unit cards copied: 16 Mongol cards + infos -> ui/units|unit_info/cumans; naffatun, saracen_militia, ghulams,
  dismounted_ghulams (abbasid) -> mongols + cumans. Mutatawwi and Muslim Settlers use the mercs fallback. Not in the
  repo (binary copies of existing SSHIP files).
- `data/descr_sm_factions.txt` colours; `data/descr_character.txt`: Georgian family member strat model
  aztec_general -> georgia_general (user's bug report).
- Originals: `backups/2026-10-15_before_golden_horde/`.

## Open check for the test
- Mosque line precedence: if Cumans can build a mosque in the test (mongols_islam still 0), the engine reads
  "and" before "or" (otherwise the line would need mongols_islam too).
- Does the renamed faction keep its name after save/load; do new Cuman generals get Keshikten.

## Status
- 15 Oct: TEST version installed (GH turn 2, Islam turn 4), all files read back identical. NEW campaign needed
  (colours, descr_character). Final: `TEST = false` in golden_horde.lua -> 221 / 361.
