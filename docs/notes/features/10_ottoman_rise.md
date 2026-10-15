# 10 - Ertugrul and Osman Gazi for Rum (board #10) + fort rules (no board issue)

## Fort rules (15 Oct 2026, installed, read back identical)
- User: 4 units free upkeep in a fort for every faction (engine setting `campaign.freeUpkeepForts`, EOP; if it only
  covers free_upkeep_unit units like settlements do, that is fine); fort price 5000; the AI gets the whole 5000 back
  (it should still build forts).
- `data/descr_cultures.txt`: `fort_cost` 2000 -> 5000 in all five cultures.
- `eopScripts/sship/fort_rules.lua` (log FORTRULE): sets freeUpkeepForts = 4 at map load and every faction turn
  start; snapshot of all fort tiles at each faction turn start, at an AI faction's turn end every fort of that faction
  on a tile that had no fort -> +5000 (captured forts stood there before -> no refund).
- To test: read FORTRULE lines (freeUpkeepForts reads back 4? AI refunds?), check in game whether units in a fort
  show 0 upkeep.

## Ottoman rise (15 Oct 2026) - TEST version installed, read back identical
Decisions (user, 15 Oct): player and AI; Ertugrul spawns next to Konya; standard Rum bodyguard (ME Bodyguard, ME Late
Bodyguard once `late_era` = 1) + 2 Oghuz Horse Archers (EDU type `Turkish Horse Archers`); Osman born naturally;
turns 198 / 252 / 296 as proposed; Seljuk family members keep living and keep Royal_Blood_Rum_Turkish; succession
after Osman left to the game; faction renamed "Ottoman Domain"; no Sogut village.

- `eopScripts/sship/ottoman_rise.lua` (log OTTOMAN). Counters: hx_ott_ertugrul (1/9), hx_ott_osman (1 born,
  2 adult spawned, 3 waiting for adult spawn, 9 skipped), hx_ott_leader (1/9), ottoman_domain (1 = renamed).
  - ERT_TURN 198: spawnArmy (family = true, age 40, label hx_ertugrul) + traits House_of_Osman, GoodCommander,
    GoodCavalryGeneral, MilitaryInclination, LoyaltyStarter, ReligionStarter; marryWife("Halime", 30).
  - BIRTH_TURN 252: Ertugrul (found via characterRecords: shortName Ertugrul + trait) `birthChild("Osman", "", 0,
    true, true)`. Ertugrul dead -> Osman spawns as an adult (16) at ADULT_TURN 284.
  - Coming of age: trait trigger House_of_Osman_CharacterComesOfAge_Father; onCharacterComesOfAge adds the trait if
    missing (father has it, or the boy is Osman).
  - LEADER_TURN 296: `setLeader(osman, true)`, else the oldest living adult House_of_Osman man, else nothing (no
    rename). localizedName set again at every Rum turn start and map load.
  - TEST = true: Ertugrul turn 2, Osman born turn 3 at age 14, adult fallback turn 6, leader turn 8.
- Trait `House_of_Osman` (Command 1, CavalryCommand 1, Authority 1) inserted before Royal_Relation_Turkish in
  `data/export_descr_character_traits.txt`, trigger before Royal_Relation_Turkish_CharacterComesOfAge_Father;
  texts after {Royal_Blood_Rum_Turkish} in `data/text/export_vnvs.txt` (UTF-16 LE). Originals in
  `backups/2026-10-15_before_ottomans/`.
- Custom portraits (user, 15 Oct, installed, read back identical): `data/ui/custom_portraits/ertugrul_gazi` (red
  turban) and `osman_gazi` (blue turban), portrait_young / _old / _dead, 69x96 32-bit TGA (same header as SSHIP's).
  spawnArmy portrait folder + `setPortrait("/data/ui/custom_portraits/<f>/portrait_young.tga")`; child Osman gets his
  at coming of age; re-checked every Rum turn start (log line "portrait ...").
- Open risks to check in the test: does birthChild work without a portrait / does the child show in the family tree;
  does the TEST child (age 14) come of age on schedule; does setLeader update the UI; does the name stick after load.
- After a good test: `TEST = false`.

## Test 1 (15 Oct 2026) and fix 1 (installed, read back identical)
- Ertugrul spawned fine, but was adopted -> user: he must start a new family tree. Now spawnArmy family = false, then
  `rec.isFamily = true` (log line "made a family member (not adopted)" shows isFamily / isFamilyHead / parent).
- Osman not born: EOP log "characterRecord::birthChild: child is too old, create a general and adopt him" (age 14).
  BIRTH_AGE is now always 0; the script checks numberOfChildren and falls back to the adult spawn if no child came.
  TEST cannot show Osman's coming of age (32 turns); the leader step at turn 8 takes Ertugrul then.
- Fort refunds went to slave (rebel forts made by the game) -> rebels excluded.
- Outpost founding bug (fort_settlement.lua): a spy (Abdulkadir Kurdoglu) in the fort never left, the script
  re-ordered him 8 times; next turn the army stepped onto a tile with a hidden enemy, ambush, and the retry orders
  during the pre-battle scroll crashed the game. Fix: founding refused while agents are in the fort ("Move these
  agents out of the fort first"), and onPreBattlePanelOpen stops a running founding.
- golden_horde.lua TEST = false (turns 221 / 361) on the user's word.

## Test 2 (15 Oct 2026): works (user). FINAL installed 15 Oct, read back identical: TEST = false (turns 198 / 252 / 284 / 296).
- 15 Oct: once renamed, the hover texts no longer say Rum: leader "Ottoman Sultan", heir "The Ottoman Prince", settlements "Town - Ottoman Domain" etc., agents "Ottoman ..." (M2TWEOP.setExpandedString for every EMT_RUM_* key of data/text/expanded.txt and {RUM}; set at map load and Rum turn start; log "expanded strings set"). Installed, read back identical.
- 15 Oct: Rum heir name "Valī 'Ahd %S" -> "Shehzade %S" (EMT_RUM_FACTION_HEIR_NAME in data/text/expanded.txt, original in backups/2026-10-15_before_ottomans/data/text/; Seljuk and Ottoman alike). Installed, read back identical. Text files may need the strings.bin cache to be rebuilt if the old text still shows.
