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

## Test 1 (user, 15 Oct): still passive
Rum played passively 12 turns; Byzantium's big army at Kutahya never attacked (they start at war). Findings in
SSHIP's own scripts (no change made yet, waiting for the user's eop.log cut and decisions):
1. `aiSupport.changeAILabel` (called at the player's turn end, only on Very Hard): any neighbour of the player with
   more settlements than `settlementsThreshold` (byzantium 5, rum 6, turks 5, egypt 6, ...) is switched to label
   `difficult` (= Gracul default). With #4's ~600 extra towns every listed faction is far over its threshold from
   turn 1, so on VH they all leave their Gracul label at once.
2. `aiSupport.setFactors`: `setTargetFactionFactor(slave, 6.0)` for every AI faction until turn 50 - built for
   vanilla's few rebel cities; with #4 hundreds of rebel towns make the AI chase rebels instead of the player.
3. EOP AI layer off for turns 1-3 (normal).
Not a cause: `aggressivity.lua` only punishes the conquering faction (warmonger unrest / relations).

## Fix after test 1 (user, 15 Oct 2026) - installed, read back identical
User plays Very Hard (always). Decisions: changeAILabel switched OFF (`do return end` at its top, after the comment);
rebel target factor 6.0 until turn 15, 3.0 until turn 50, then 1.0 (as before). Needs a new campaign? No - both are
read every turn, a running save picks them up; a new campaign is still cleaner for the label (the old save may hold
'difficult' labels: they stay until the next new campaign).

## AI attacks the player's enemies (17 Oct 2026) - installed, read back identical, needs test
Ported from EUR issue #44 (`docs/notes/features/44_ai_attack_fix.md` in Horschix/Modding_DAC-EUR): the engine's
difficulty switch `M2TWEOP.getCampaignDifficulty2().dontAttackAiDefenders` (on Very Hard: AI factions leave alone an
AI faction that is at war with the player and borders him) is switched off at map load, every turn start, `onAiTurn`
and `onCalculateLTGD` (the engine turns it back on before every faction's planning). File `sship/ai_attack_fix.lua`,
`FIX = true`, last require line of `luaPluginScript.lua`; log prefix `AIFIX` (first look = value before any change,
per-turn summary, `AIFIX ltgd` decisions with `[P]` = enemy of the player too, `AIFIX battle` unit lists).
Works in a running save after a game restart. Not proven in EUR yet (second test there inconclusive).
Test: play 5-10 turns at war with an AI neighbour, then `Select-String -Path full.log -Pattern "AIFIX" > hits.txt`.
