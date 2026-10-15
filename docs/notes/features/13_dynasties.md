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
Also dead, NOT fixed yet, asked the user: GEORGIAN2_GOLDEN_AGE, GEORGIAN3_SHOTA_RUSTAVELI, GEORGIAN4_CROSSBOW_IN_CAUCASUS,
GEORGIAN6_REVIVAL, GEORGIAN7_LAST_UNITED_KINGDOM (Georgia's whole roster progression); ENGLAND2_THOMAS_BECKET,
ENGLAND3_MAGNA_CARTA, ENGLAND5_ENGLISH_ARCHERS (unit swaps); BYZANTIUM7_METEORA (agent limit), BYZANTINE_PANTOKRATOR
(huge cathedral), LIBER_SECRETORUM_TRANSLATED (alchemists' lab), SCOTLAND_FIRST_UPRISING (mangonel, trebuchet),
hildegard_of_bingen / omar_khayyam (health / happiness), grote_mandrenke_coming / netherlands_flood_coming,
mongols_blue_horde_caucasus, mongols_reach_caucasus, the_mongols_emerge (to be double-checked against mongols.lua).
SSHIP's live event table: `historicEvents` in globalEvents.lua (no Georgian or English entries at all).
