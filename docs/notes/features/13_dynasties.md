# 13 - Dynasties: Ayyubids / Mamluks / Eretnids + the lost Muslim army reforms (16 Oct 2026)

## Finding
SSHIP 0.98's faction evolutions (`eopData/eopScripts/sship/factionsEvolutions.lua`) are ONE big Lua comment
(`--[[ ... ]]`, lines 13-4655) and `campaign_script.txt` no longer has them -> their counters are never set.
Only part was ported to the live table `historicEvents` in `globalEvents.lua` (turn windows min/max).
Dead counters that still gate content (scan of every commented block in every SSHIP Lua file vs. EDB / traits):
- FIXED HERE: ayyubids_rise, first_mamluks, mamluks_established, mamluks_rise (Egypt: Ghulams instead of Fari,
  Amir's Guard, Mamluk Archers, Mamluks, Dism. Mamluk Archers, Al Haqa, Tabardariyya); zengids_rise,
  first_mamluks_zengid, mamluks_established_zengid, zengid_evolution; abbasids_rise, first_mamluks_abbasid,
  mamluks_established_abbasid (Abtal, Caliph's Guard, Jaridah, Ghulams, Mamluk units); fatimid_evolution
  (SSHIP's Royal_Blood_Mamluk adoption trait).
- FIXED 16 Oct by `lost_events.lua` (log LOSTEV, TEST = true: coat of arms turn 2, Tatar Lancers turn 3; final
  61-80 / 161-180 random, kept in counters hx_turn_<event>): everything below EXCEPT trusted_ally / right_hand,
  Antipope, AppointBishop, StripBishop (user: leave those). Ceased_<f> rebuilt as: conqueror of a faction's last
  settlement -> his faction leader +10 FactionKiller when onFactionDied fires.
- WAS DEAD: GEORGIAN8_TATAR_LANCERS_REFORM (Naqivchaqari Cavalry);
  templars_recruitment_enabled (Jerusalem's Templar Sergeant); teutonic_hospital_founded (HRE income bonus);
  pisa_sacked_amalfi (Pisa's cathedral wonder levels 6-8); <faction>_first_coat_of_arms_player (jousting lists,
  13 factions); poland3_first_tourney_player (tourney fields); hre/hungary/poland_ostsiedlung_player,
  serbian3_saint_sava_player, georgian3_shota_rustaveli_player (law bonuses); traits: Ceased_<faction>
  (TriumphsOverFaction_<x>), trusted_ally / right_hand (FL right hand), Antipope, AppointBishop, StripBishop.

## Decisions (user, 16 Oct 2026)
- Colours: Egypt <-> Abbasids swapped (Egypt now brown 115/52/23, Abbasids green 22/149/63) - descr_sm_factions.
- Egypt: turn 79 (1171) "Ayyubid Sultanate" + ayyubids_rise; 119 first_mamluks; 237 (1250) "Mamluk Sultanate" +
  mamluks_established + mamluks_rise. Renames only at these turns. AI always; player yes/no each time (NO keeps the
  name, the units come anyway).
- Zengids: reform 29 (1146), first Mamluks 79, established 129. Abbasids: reform 51 (1157), 111, 151.
- Eretnids from turn 409 (1335): Sivas (Sives_Province) to the Zengids unless a human player (not zengid) holds it
  or it is a crusade target (retried every turn); Eretna spawns (ME (Late) Bodyguard, label hx_eretna), becomes
  leader; all Zengid settlements outside Anatolia to the rebels with garrison, generals / family outside Anatolia
  (land only) switch to the rebels with their armies; name "Eretnids". Player Zengids: yes/no (NO = never).
  Anatolia = Nicaea, Smyrna, Attaleia, Konya, Angora, Sinop, Trebizond, Caesarea, Sives, Sis, Malatya provinces
  (Constantinople, Antioch, Erzurum, Edessa, Hasankeyf count as outside).

## Files
- `eopData/eopScripts/sship/dynasties.lua` (new, log prefix DYNAST), require line at the end of luaPluginScript.
  Counters: hx_egypt_name (0/1/2), hx_egypt_asked1/2, hx_eretnids (1 done, 8 asked, 9 declined); choice events
  HX_AYYUBIDS / HX_MAMLUKS / HX_ERETNIDS. Names via localizedName, re-applied at turn start and map load.
- `data/descr_sm_factions.txt` colours.
- TEST = true installed 16 Oct (read back identical): Zengid/Abbasid reform 2, first Mamluks 3, established 4;
  Ayyubids 3, Egypt first Mamluks 4, Mamluks 5, Eretnids 6. NEW campaign (colours).
  Mock-tested in the session (player yes/no, AI, Sivas blocked by a player, rebels).

## To check in the test
- DYNAST lines in full.log; names in the faction list / diplomacy; recruitment of Ghulams, Mamluk units, Abtal.
- Eretnids at turn 6: Sivas changes owner, Eretna in Sivas as leader, Mosul / Aleppo / Raqqah rebel with
  garrisons, Zengid generals there turn rebel; save/load keeps the names.

## Second scan (16 Oct, descr_events comment lines stripped - the first scan counted ';;;;;;' lines as live)
FIXED 16 Oct (user: "all of them"), lost_events.lua round 2 - was dead: GEORGIAN2_GOLDEN_AGE, GEORGIAN3_SHOTA_RUSTAVELI, GEORGIAN4_CROSSBOW_IN_CAUCASUS,
GEORGIAN6_REVIVAL, GEORGIAN7_LAST_UNITED_KINGDOM (Georgia's whole roster progression); ENGLAND2_THOMAS_BECKET,
ENGLAND3_MAGNA_CARTA, ENGLAND5_ENGLISH_ARCHERS (unit swaps); BYZANTIUM7_METEORA (agent limit), BYZANTINE_PANTOKRATOR
(huge cathedral), LIBER_SECRETORUM_TRANSLATED (alchemists' lab), SCOTLAND_FIRST_UPRISING (mangonel, trebuchet),
hildegard_of_bingen / omar_khayyam (health / happiness), grote_mandrenke_coming / netherlands_flood_coming,
mongols_blue_horde_caucasus, mongols_reach_caucasus, the_mongols_emerge (to be double-checked against mongols.lua).
SSHIP's live event table: `historicEvents` in globalEvents.lua (no Georgian or English entries at all).

## Round 2 rules (lost_events.lua, TEST = true installed 16 Oct, read back identical)
- Georgia at SSHIP's fall-back turns (its early routes needed buildings / marriages / crowned FL - not rebuilt):
  GEORGIAN2 130, GEORGIAN3 210, GEORGIAN4 290, GEORGIAN6 350, GEORGIAN7 600 (GEORGIAN5_REVIVAL_ALLOWED skipped,
  it only gated GEORGIAN6). England ("after X, 40% a turn"): Becket 71-77, Magna Carta 161-167, Archers 301-307.
- BYZANTINE_PANTOKRATOR and omar_khayyam turn 3 for everyone (SSHIP only set them for an Orthodox / Muslim player);
  BYZANTIUM7_METEORA 85; LIBER_SECRETORUM_TRANSLATED 60-90 (own text); SCOTLAND_FIRST_UPRISING 51-70 (our choice).
- Mirrors: hildegard_of_bingen = SSHIP's great-people counter hildegard_von_bingen_in; the_mongols_emerge once any
  mongols_invasion_stage_N is set; mongols_blue_horde_caucasus + mongols_reach_caucasus once a Mongol army is near
  tile 440,194 (mongols.lua only shows the message there).
- Floods: REMOVED by the user 16 Oct (code taken out; netherlands_flood_coming / grote_mandrenke_coming stay 0, so
  riverport5 keeps its bonus as before). Was: own step counters hx_flood_nl / hx_flood_gm (10% a player turn with a riverport5; floods at 8 / 12 steps),
  damage as SSHIP (player-owned Ghent, Utrecht / + London, Norwich, Bremen, Ribe); the EDB counters
  netherlands_flood_coming / grote_mandrenke_coming are 1 only for 10 turns after the flood (riverport5 bonus off) -
  SSHIP kept them at 1+ all game, which may have meant no bonus ever (if EDB reads "X 1" as ">= 1").
- TEST turns: Becket / Golden Age 2, Magna Carta / Rustaveli / Pantokrator / Omar 3, Archers / Crossbow / Meteora 4,
  Revival / Liber / Scotland 5, Last United Kingdom 6; floods 100% (NL after 3, Mandrenke after 4, recovery 3).

## Test 1 (user, 16 Oct, Georgia campaign to turn 7) and final turns
- full.log: all DYNAST / LOSTEV steps of turns 2-6 fired, no errors; Egypt renamed Ayyubid (3) and Mamluk (5), reads
  back. The Eretnids were NOT reached (log ends in Georgia's turn 6, before the Zengid turn).
- 16 Oct: TEST = false in dynasties.lua and lost_events.lua (historical turns); dynasties.lua has ERETNID_TEST = true
  (Eretnids at turn 6 only) until the user has seen them work - then set ERETNID_TEST = false (-> turn 409).
- Same install: starting_settlements.lua - Sukhumi 374,155 -> 373,155; Artanuji 381,142 -> 382,141; Ganja 411,138 ->
  411,139 (all were on low-mountain tiles and unreachable). Script only, NEW campaign, map.rwm stays.

## Test 2 (user, 16 Oct): Eretnids work. Fix installed 16 Oct (read back identical):
- Hover strings (settlement types, agents, leader / heir titles, faction name key) for Egypt (Ayyubid / Mamluk
  Sultanate, "Sultan") and Zengids (Eretnids, "Eretnid Sultan") via M2TWEOP.setExpandedString, as ottoman_rise.lua;
  originals read at the first event call (never at file level) and put back when the level is 0; set at every map
  load and Egypt / Zengid turn start. Log line "hover strings <faction> level N".
- Eretnid question / message rewritten with more history (Abu Sa'id's death, Kose Peygamber, coins, title of Sultan).
- ERETNID_TEST = false -> Eretnids at turn 409. Everything in dynasties.lua and lost_events.lua is FINAL now.
