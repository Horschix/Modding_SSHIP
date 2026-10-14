# 06 Campaign AI: Gracul AI from SS 6.3 (Oct 2026)

User wanted the aggressive, backstabbing AI of SSHIP 0.94 back (0.98 AI almost never attacks).
Source: `mods\SS6.3\data\campaign\sub\AiGracul\` (SS 6.3 setup option "Gracul AI", 10/10 aggression/backstabs).
Originals backed up in `backups/2026-10-15_before_gracul/`.

Why 0.98 was tame (three layers):
1. `descr_campaign_ai_db.xml` = Piter AI + Macaras; trusted-ally thresholds so low (-0.25 / -1.0) that nearly
   everyone counted as a trusted ally -> no invasions.
2. EOP AI (`aiSupport.lua`, enabled from turn 4) had `nonBorderFactor = 0` -> never attacks non-neighbours.
3. WIP loop in `changeAILabel()` reset every AI faction to label `default` every turn.

Installed 15 Oct 2026 (user decisions: Gracul; keep EOP AI with nonBorderFactor 0.5; remove the reset loop):
- `data/descr_campaign_ai_db.xml` = Gracul file, plus: label `mongols` = SSHIP's own Z3n Mongols block (tuned for
  SSHIP's Mongol scripts; Gracul's was `mongols_faction`), and label `difficult` = copy of Gracul `default`
  (aiSupport.lua switches big factions to it on Very Hard).
- Kept SSHIP's `descr_diplomacy.xml` and `descr_faction_standing.txt` (Gracul's only know SS 6.3 factions).
- `descr_strat.txt` ai_labels: catholic (14 factions), scots (scotland), islam (abbasid, egypt, turks, moors,
  zengid, rum), pagan (cumans, lithuania), byzantium_faction (byzantium), default (russia, kievan_rus, serbia,
  georgia), unchanged papal_faction / mongols / slave_faction.
- `aiSupport.lua`: reset loop removed; switching back from `difficult` restores the strat label (table
  `stratLabels`); `nonBorderFactor` 0 -> 0.5 in the enabled branch (turn > 3).
Not changed: forced peace on ruler death of small factions (internationalAffairs.lua), pacifying dead factions
(diplomacy.lua), Byzantium-Rum peace on turn 2.
Status: installed, read back identical. Needs a new campaign and 20-30 turns of play by the user.
