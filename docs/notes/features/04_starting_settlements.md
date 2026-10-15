# Starting settlements - towns that existed in 1132 (issue #4), TEST with Prousa installed 13 Oct 2026

Moved out of `docs/HANDOVER.md` on 13 Oct 2026 (unchanged). Read only when working on this issue.
User wish: towns and cities of EU5's 1337 start that already existed at SSHIP's start (summer 1132) become extra
(minor) settlements from the start of a NEW campaign. Each one checked on Wikipedia. Anatolia first (test area),
other game regions later. The candidate list and every decision are in issue #4.
- Rules (user): EU5 city -> level 3 + `stone_wall`, 15000 people; EU5 town -> level 2 + `wooden_wall`, 7500 people.
  Poimanenon (Manyas): tier 1, 1000 people, on Balıkesir's tile (39.647 N, 27.888 E - tile still to compute).
- Names: Greek (greek culture), Turkish (middle_eastern), Latin (the three European cultures), faction-specific
  names possible - the same rule as SSHIP's `settlementSituation.updateName` (which only knows its own settlements
  and logs a harmless warning for ours). EU5 sources: `game/main_menu/localization/english/location_names/`
  (`location_names_l_english.yml` = the Turkish base names, `location_names_greek_l_english.yml`).
- Placement: GPS (Wikipedia, same as Google Maps) -> SSHIP tile with an affine fit on 15 SSHIP settlements
  (residual <= 2 tiles) plus inverse-distance correction. Settlement tiles of SSHIP = black pixels of
  `map_regions.tga` (510 x 288, y flipped). Tiles checked on `map_ground_types.tga` / `map_heights.tga` (2x+1 size).
  Prousa = 285,136 (plain at the north foot of Uludağ, which is at 286-291,134-135); Poimanenon GPS = 277,134.
- Alanya and Kastamonu: impassable land on SSHIP's map (user) - needs ground type / height edits and a rebuilt
  map.rwm before they can be added.
- Script `eopData/eopScripts/sship/starting_settlements.lua` (log prefix `STARTSETT`) + FOURTH require line of
  `luaPluginScript.lua`. Table `SETTS` (key, x, y, capital = region's main settlement for the owner, level,
  population, names). `onNewGameLoaded`: creates each entry once with `owner:addSettlement` (skips a name that
  exists), adds the wall building, sets population and the name. Names applied again at map load, after a
  capture and at every faction's turn start (a save may not keep localizedName - unknown).
  Internal names `hxstart_<key>`. Mock dry run OK (create, no double, Greek/Turkish/Latin, rebels keep the name).
- UNKNOWN until tested: does addSettlement at level 3 work at new-game time; walls created or already there;
  population accepted; the city model / battle map; name survives save/load; SSHIP's scripts with 2+ settlements
  in a region (same open point as the outposts).
- FIRST TEST (user, 13 Oct, new Byzantine campaign): WORKS - log: level 3, walls "already there" (addSettlement
  adds the core building itself), population 15000, name Proúsa. PROBLEM: very little buildable, no farm.
- Cause found: SSHIP's chains hang on roads -> builders1 (30 chains need builders: temples, water, port, town hall,
  mines, ...); farms2 needs builders1. The new town had walls only. The player could not build farms / roads in it
  although their first levels need no building: EUR shows why - it has separate chains `minor_farms` / `minor_roads`
  (marker building `minor_sett`, given by script) because extra settlements do not build the hinterland chains;
  the engine flags chains with `edbEntry.isHinterland`.
- FIX installed 13 Oct, read back identical (user agreed): STARTER table - level 3: roads, farms2, builders2,
  water1_wells; level 2: roads, farms1, builders1, water1_wells; level 1: roads, farms1, builders1. Given at creation
  and missing ones at every map load (works in the existing campaign). TEMPORARY CHECK lines at every map load:
  buildings of Prousa and Nicaea and `canConstructBuilding` per level for 11 chains (remove CHECK_SETTS / the call
  after the test). Open: can the player UPGRADE roads / farms in Prousa? If not -> EUR-style minor chains.
- SECOND TEST (user, 13 Oct): more buildable now. CHECK lines: canConstructBuilding allows paved roads, highways and
  farms up to farms6 in Prousa (mines blocked in Nicaea too - no resource), yet the build menu shows none of them:
  the engine hides chains with `edbEntry.isHinterland` in extra settlements.
- EXPERIMENT A installed 13 Oct, read back identical (user's choice): `UNHINTERLAND = true` sets isHinterland 0 for
  hinterland_roads / hinterland_farms / hinterland_mines at every map load (log line "hinterland flags"). Affects ALL
  settlements - watch roads / farm fields on the map and the AI. If it fails or has side effects: option B =
  proxy chains ("Expand farms" etc.) only for settlements with a marker building; on completion the script removes
  the proxy and raises the real hinterland building one level (keeps the 34 requirement lines that point at
  farms / roads levels working).
- EXPERIMENT A: WORKS (user, 13 Oct) - roads / farms buildable in Prousa. Build CHECK switched off (CHECK_SETTS = {}).
- ALL ANATOLIA installed 13 Oct, read back identical, mock OK (18 towns): Nicaea region (Byz): Prousa 285,136 (3),
  Nikomedeia 292,139 (3), Kotyaion 290,130 (2; GPS tile mountain), Poimanenon 277,131 (1, 1000, Balıkesir's tile);
  Smyrna region (Byz): Pergamon 272,127, Magnesia 273,123, Pyrgion 278,121, Philadelpheia 281,122, Laodikeia
  (Denizli) 286,119, Mylasa 276,115; Angora region (Rum): Akroinon (Afyon) 296,125, Sozopolis (Uluborlu) 294,121
  (GPS tile mountain); rebel regions: Amasya 335,138 (3) / Niksar 343,138 / Ladik 333,140 (Sives), Bafra 335,145
  (Sinop), Elbistan 344,121 (Malatya), Tarsus 328,112 (Sis). Alanya / Kastamonu left out (terrain).
- Garrison at creation (user): byzantium 2 Contaratoi, rum 2 Ahdath Militia (`createArmyInSettlement` + `createUnit`).
  Rebels (my choice, not yet confirmed by the user): Danishmend towns 2 Ahdath Militia, Tarsus 2 Armenians of
  Celicia, Elbistan 1 Armenians of Celicia + 1 Ahdath Militia. Rebel-held towns show `names.default`.
- THIRD TEST (user, 13 Oct): all 18 in. Wishes: move Nicaea / Nikomedeia and Smyrna / Magnesia apart, Magnesia and
  Mylasa off the river, Sinop's port away from Bafra, passes to Karahisar (Afyon) from Kutahya and Nicaea. Also: the
  map road Nicaea - Prousa - Smyrna was gone (blamed on experiment A: isHinterland 0 for the whole game).
- MAP EDIT installed 13 Oct, all 6 files read back identical. Tool `docs/tools/edit_map.py
  backups/2026-10-13_before_map <OUT>` (writes each TGA in its original format: regions RLE 32 bit bottom-up,
  ground types RLE 24 bit bottom-up, heights uncompressed 24 bit TOP-DOWN; its writer reproduces the untouched
  originals byte for byte). Changes: Nicaea's city pixel 291,137 -> 290,136 (map_regions), Ioannis Axouchos in
  descr_strat and the event position in descr_events moved with it (only references found in descr_*, campaign_script
  and SSHIP's Lua); Sinop's port pixel 335,146 -> 330,149; ground 291,130 / 291,129 / 292,129 (Kutahya pass) and
  293,131 / 293,130 (Nicaea pass) from low mountains (98,65,65) to hills, heights there smoothed (5x5 mean).
  Copies of the installed files in repo `data/world/maps/`. map.rwm must be DELETED by the user (session cannot
  delete) - the game rebuilds it; NEW campaign needed.
- Ground type colours (TWC lesson 2): 64,64,64 impassable; 196,128,128 mountains high; 98,65,65 mountains low;
  128,128,64 hills; 0,0,0 wilderness; 255,255,255 beach; 0,128,0 / 0,64,0 forest; 96,160,64 / 101,124,0 / 0,128,128
  fertility; 64,0,0 / 128,0,0 / 196,0,0 water. Rivers: map_features.tga (510x288) blue 0,0,255, crossings 0,255,255.
  Ports: white pixels in map_regions; sea colour 41,140,233.
- Script: Nikomedeia 290,139, Magnesia 273,124, Mylasa 276,116 (no river). isHinterland is now 0 ONLY while the player
  has one of his extra settlements selected (draw hook), restored otherwise and before every faction's turn ->
  AI-held extra settlements cannot build roads / farms / mines (they keep the starter pack). Open: does a queued farm /
  road in an extra settlement still finish when the flag is back to 1 at turn end? Did the road come back?
- FOURTH TEST (user, 13 Oct): campaign start dropped back to the main menu. full.log: descr_strat line 12768 (Sinop)
  "Settlement specifies port, but this region is not allowed a port" + "could not create settlement". Cause: the port
  pixel was put on a SEA tile (330,149). A port pixel must be a COASTAL LAND tile (all 119 SSHIP ports are on land
  ground types, with sea beside them). FIX installed 13 Oct, read back identical: port -> 331,146 (coast, sea north),
  old port tile 335,146 -> Sinop region colour 255,255,176 (it is land). Checked: all 119 ports land + sea + region
  beside, no city pixel on water. map.rwm must be deleted AGAIN (it was rebuilt with the bad port).
  LESSON: after any map_regions edit run that port / city check.
- FIFTH TEST (user, 13 Oct): works. Asked whether roads can lead to the extra settlements: NO - map roads only join
  region capitals (and ports), computed when map.rwm is built; M2TWEOP can read roads (campaign:getRoad, tile.road)
  but not create them. User rejected placing towns on the existing roads; splitting regions is out (SSHIP uses 199 of
  about 200 regions). Left as is.
- MAP ROUND 2 installed 13 Oct, read back identical (edit_map.py rebuilt from the same originals): Kastamonu belt
  x 312-327 y 141-147: all 21 impassable tiles -> dense forest, valley 318-320 x 142-144 + 319,141 + row 143 x 321-325
  -> hills; south coast 304,111 / 305,110 / 306,110 / 307,110 / 308,110 / row 109 x 308-321 -> hills; Konya -> Alanya
  310,112 / 309,112 / 309,111 / 308,111 -> hills (user's wish). Heights of all pass tiles smoothed (5x5 mean, up to 4
  rounds until the steepest step <= 12; coast tiles end at 18-22 because of the slope to the sea - normal: passable
  coast tiles of the area reach 17 at the 90th and 34 at the 99th percentile). Ports / cities checked again.
- SIXTH TEST (user, 13 Oct): Kastamonu -> Angora works; -> Nikomedeia and -> Sinop do not; wishes: a pass straight
  north to the coast, the Konya - Alanya pass lower, the Alanya - Tarsus pass along the coastline.
- ENGINE DUMP (temporary, DUMP = true in starting_settlements.lua, once per session at map load; lines
  `STARTSETT DUMP ...` in full.log): move cost per ground type, per tile ground / cliff / river / height for the boxes
  x 286-336 y 135-151 and x 294-334 y 103-121, and stratMap.getMovePath for 7 routes. FINDINGS:
  * move costs: lowFert 10, medFert 11, highFert 11, wilderness 12, HIGH MOUNTAINS 999, low mountains 15, hills 14,
    DENSE FOREST 999 (!), woodland 13, swamp 20, impassable 999. So round 2's "impassable -> dense forest" opened nothing.
  * engine-like rules that reproduce all 7 results: 8 directions, no diagonal step between two blocked tiles, river
    tiles blocked except crossings (map_features 0,255,255), height steps of 38 (tile.height/10) pass, 60+ fail;
    getMovePath also seems to give up on long detours. Model: /tmp scripts of the session (eng.py) - not kept.
  * tile.height/10 = 2.393 * grey of the tile's CENTRE pixel in map_heights.tga (exact, 1018 tiles).
- MAP ROUND 3 installed 13 Oct, read back identical: edit_map.py CORRIDORS = chains of hill tiles with the heights
  ramped evenly (whole 3x3 block per tile): Kastamonu-Sinop (row 143 x 320-327, then 327,144-147; 177 -> 14),
  Kastamonu-north coast (319,144-148; 177 -> 45), Kastamonu-Nikomedeia (row 143 x 318-304; 177 -> 2, then the
  existing coast lowland), Konya-Alanya (310,117-112, 309,112, 309,111, 308,111, 308,110; 177 -> 93, much lower than
  the old 200-300), Alanya-Tarsus along the shore (308,109 309,108 310,107 311-315,106 316-320,107 321,108
  322,108; 93 -> 2). Round 2's row-109 corridor dropped (inland tiles back to original). Model check of the new map:
  all 7 routes pass, steepest step 24-38. The former impassable tiles of the Kastamonu belt are dense forest =
  still blocked (only the corridors cross the belt).
- Script: Alanya / Kalón Óros 307,110 (Attaleia, Byz, 2 Contaratoi), Kastamonu / Kastamōn 319,143 (Sinop, rebels,
  2 Ahdath Militia) - 20 towns now. map.rwm to be deleted, new campaign.
- Revert: delete the fourth require line (settlements already created stay in that save).
- SEVENTH TEST (user, 13 Oct): "Works now." Engine dump after round 3: all 7 routes found by getMovePath -
  Kastamonu-Sinop 15 tiles (it prefers the north pass and the coast), -Angora 13, -Nikomedeia 30, -north coast 5,
  Alanya-Tarsus 22 along the shore, Konya-Alanya 9, Attaleia-Alanya 11. Anatolia finished; #4 stays open for the
  other regions.
- CAUCASUS installed 13 Oct, read back identical (2 files, no map edit, map.rwm stays). EU5 has only 5 towns here
  (Van city, Tbilisi city, Gladzor, Ganja, Ani); Tbilisi / Ani are SSHIP capitals. User added 17 extras (all existed
  1132, my list): 20 towns. Levels: Van 3, Gladzor 1 / 1000 (user), all others 2 / 7500. One name for every culture
  (EU5 has no Armenian / Georgian names for them). Georgia garrison 2 georgian light spearmen (user); rebels
  2 Ahdath Militia, Kars / Gladzor 2 Armenian Archers. Ganja starts Georgian (user). Tiles moved off river / dense
  forest: Gori 395,149, Telavi 404,146, Akhaltsikhe 387,145, Nakhchivan 402,127, Shaki 416,140; Ahlat 381,125 (GPS
  tile behind a 60+ height step at Lake Van). Model (BFS, engine rules above) reaches all 20 from their capitals.
  DUMP_BOXES = {}, DUMP_PATHS = 8 Caucasus routes. settler_check require line removed (user); the file
  sship/settler_check.lua is still on the PC (unused, session cannot delete). Wikipedia check not done per town -
  checked against known history only.
- CAUCASUS TEST 1 (user, 13 Oct): all 20 created (log OK); Erzincan, Ahlat, Gladzor, Shamakhi, Van NOT reachable -
  all five were on low-mountain tiles (Ganja, Sukhumi, Artanuji are too and work - cause not fully clear; my BFS
  model said all reachable, so the model is too lenient here). getMovePath returned 0 tiles for 5 of 8 routes incl.
  ones that work in play - not usable as proof for long routes. FIX installed 13 Oct, read back identical: moved to
  open, gentle tiles (non-mountain ground, 3x3 relief <= 60, >= 3 open neighbours): Van 391,122 (hills), Ahlat 380,126,
  Erzincan 361,135, Gladzor 401,132, Shamakhi 425,137. User: the 7 towns in Georgia's two regions (Tbilisi, Kutaisi)
  are level 1 / 1000. NOTE: the commit tool reused a cached upload of the same output path once - always commit
  from a NEW output folder name and re-check the size.
- Rebel owners (user, 13 Oct), installed, read back identical: new optional entry field `ownerFrom` (owner taken from
  that settlement instead of `capital`). Ganja, Sukhumi, Artanuji: ownerFrom = "Ani" (rebel-held) -> start as rebels,
  level 1 / 1000. Garrisons: Ganja 2 Ahdath Militia, Sukhumi / Artanuji 2 georgian light spearmen (my choice -
  Christian towns). Georgia keeps Gori, Dmanisi, Telavi, Akhaltsikhe (level 1).
- CAUCASUS TEST 2 (user, 13 Oct): the five moved towns (Van, Ahlat, Erzincan, Gladzor, Shamakhi) are reachable now;
  the level downgrades (Georgia's towns, the three rebel towns) work. Caucasus finished; #4 stays open for the next region.
- UPPER MESOPOTAMIA installed 13 Oct, read back identical (1 file, no map edit). EU5 jazira_area has Amid (city), Urfa
  (= SSHIP Edessa), Mardin, Kozluk (towns), Mosul (= SSHIP), Nusaybin (city). Kozluk dropped (no 1132 evidence).
  Extras checked on Wikipedia / known history (user: must have been town-sized): Mayyafariqin, Harran, Ras al-Ayn,
  Saruj, Samosata, Tell Bashir, Cizre, Sinjar, Erbil, Al-Rahba, Tikrit, Kharput (user). Left out: Siirt (centre only
  14th c.), Arzan, Dara, Balis, Qarqisiya, Balad; Anah and Birecik (user: no; Birecik is next to Tell Bashir).
  SSHIP's Hasankeyf settlement already stands for Hasankeyf (rebel region of Amid / Mardin / Mayyafariqin).
  Tiles (fit on 15 SSHIP settlements, IDW): Amid 366,119 (3, 15000), Mardin 370,115, Mayyafariqin 372,121 (Hasankeyf,
  rebels); Kharput 359,124 (Erzurum, rebels); Nusaybin 374,113 (2, user), Harran 358,112, Ras al-Ayn 366,112 (Ar Raqqah,
  Zengids); Saruj 353,113, Samosata 353,117, Tell Bashir 351,112 (Edessa, Jerusalem); Cizre 381,115, Sinjar 379,108,
  Erbil 393,107, Al-Rahba 369,99 (Mosul, Zengids); Tikrit 391,96 (Mosul region, ownerFrom Hasankeyf = rebels, user).
  All level 2 / 7500 except Amid. All on open ground (hills, fertile, sparse forest, or black = wilderness, which is
  passable - SSHIP's Tayma stands on it), 3x3 relief <= 25. Garrisons: Zengids 2 Shurtah Militia, Jerusalem 2 Spear
  Militia (user), rebels 2 Ahdath Militia. Names: EU5 names for Muslim owners, Latin for Jerusalem (Turbessel,
  Sororgia, Carrhae ...), Greek for Byzantium. DUMP_PATHS = 8 Mesopotamia routes (getMovePath unreliable on long ones).
- Mesopotamia fix (user, 13 Oct), read back identical: Saruj (Sororgia) removed; Samosata 353,117 -> 352,117 (was on a
  river; new tile sparse forest, relief 9). 14 towns.
- MESOPOTAMIA TEST 1 log (user, 13 Oct, before the Saruj / Samosata fix): all 15 created with the right owner, level,
  population, garrison and name (Tikrit rebel, Nusaybin 2, Turbessel / Sororgia Latin). Reachability still to report.
- MESOPOTAMIA: user moved on to the next region (13 Oct) - taken as test passed, Upper Mesopotamia done.
- SYRIA AND THE LEVANT installed 13 Oct, read back identical (1 file, no map edit, map.rwm stays). EU5 has only
  Antioch, Aleppo, Damascus, Jerusalem, Acre here - all SSHIP settlements already, so all 19 towns are extras.
  Fit: affine on 14 SSHIP settlements (Jerusalem, Acre, Tripoli, Antioch, Damascus, Aleppo, Edessa, Ar Raqqah, Ascalon,
  Al Aqaba, Lefkosia, Sis, Hasankeyf, Tayma) + IDW. SSHIP's coast is compressed (Acre - Tripoli 14 tiles), so towns keep
  Chebyshev distance >= 2 to every settlement and were set by hand on open, non-river, non-low-mountain tiles.
  Tiles: Antioch region (Franks): Latakia 336,102, Ma'arrat 342,103; Tripoli region: Tartus 337,99, Jubail 336,95,
  Beirut 334,91 (Lebanese coast steep, land relief 87 - watch the DUMP route); Acre region: Sidon 333,88, Tyre 332,86 (3),
  Caesarea 329,80, Tiberias 332,81; Jerusalem region: Nablus 331,77, Jaffa 328,77, Ramla 328,75; Edessa region (Franks):
  Marash 344,115, Ayntab 347,113; Aleppo region (Zengids): Manbij 351,109, Hama 343,100 (3); Damascus region (rebels):
  Homs 342,97 (3), Baalbek 342,93, Bosra 341,81. Level 2 / 7500, Tyre / Homs / Hama level 3 / 15000 (user).
  Skipped (user: no small ones): Harim, Hebron, Banias; left out for spacing / size: Jableh, Valania, Apamea, Shaizar,
  al-Bab, Haifa, Gaza (ruined until 1149), Amman, Palmyra, Salamiyya, Kilis, Safed.
  Names (user): Latin (crusader forms) + Greek + Turkish (middle_eastern) + Arabic. New name key `arabic`, used for the
  factions in table ARABIC (egypt, abbasid, moors); default (rebels) = Arabic. Garrisons as before (Jerusalem Spear
  Militia, Zengids Shurtah Militia, rebels Ahdath Militia). DUMP_PATHS = 8 Levant routes. Waiting for the user's test.
- LEVANT TEST 1 (user, 13 Oct): all 19 work but too crowded. Removed (user): Ramla, Caesarea, Tiberias, Nablus, Sidon,
  Baalbek, Jubail ("Gitzelbekk" read as Gibelet), Latakia, Ma'arrat. Tortosa 337,99 -> 337,100 (1 north). 10 towns left:
  Tortosa, Beirut, Tyre (3), Jaffa, Marash, Ayntab, Manbij, Hama (3), Homs (3), Bosra. Installed, read back identical
  (the commit tool reused the cached upload again on the same output path - fresh folder fixed it).
- LEVANT: marked done (user, 13 Oct).
- NORTH AFRICA, Egypt to Morocco, installed 13 Oct, read back identical (1 file, no map edit, map.rwm stays). EU5 lists
  (north_africa areas): cities Mahdia, Marrakesh, Rabat, Annaba, Bejaia, Fez, Meknes, Constantine, Sijilmasa, Tlemcen,
  Tunis, Oran, Alexandria, Asyut, Cairo, Damietta, Mansoura, Qus; towns Algiers, Kairouan, Azemmour, Noul Lamta, Cherchell,
  Tahert, Taza, Tidsi, Tripoli. Out: Mansoura (founded 1219), Rabat -> Salé (Ribat al-Fath 1150), Tidsi -> Taroudant,
  Noul Lamta (map edge), Aghmat (2 tiles from Marrakesh), Damanhur, Msila, Setif, Bizerte, Beja, Tozeur, Suez, Zawila;
  optional ones the user did not take: Tinnis, Sirt, Miliana. User added Sousse and Tangier. 32 towns.
  Fit: affine on 19 settlements (N Africa + Granada, Murcia, Palermo, Chandax, Lefkosia, Ascalon, Aqaba) + IDW; then the
  nearest open tile (not sea / impassable / mountain, relief <= 30, >= 5 open neighbours, >= 2 tiles from any
  settlement). Moroccan Atlantic coast is compressed: Salé, Azemmour moved 2-3 tiles, Safi 4 tiles inland.
  Tiles: Damietta reg (Egypt): Rosetta 297,71, Mahalla 302,68, Bilbeis 304,64; Cairo: Faiyum 299,56, Bahnasa 297,50,
  Asyut 301,41 (3); Qus: Akhmim 305,36, Aswan 313,18; Alexandria reg: Barqa 226,79 (ownerFrom Tarabulus = rebels, user);
  Tarabulus: Ajdabiya 221,66; Al-Mahdiya: Kairouan 149,102, Sousse 153,103, Sfax 153,95, Gabes 149,89; Tunis: Gafsa 139,93;
  Algiers (rebels): Bejaia 114,110 (3), Constantine 125,107 (3), Annaba 133,111 (3), Qal'at Bani Hammad 112,102, Biskra
  118,96; Tlemcen (Moors): Oran 72,103 (3), Tenes 86,108, Cherchell 93,109, Tahert 86,100; Fes (Moors): Meknes 36,91 (3),
  Salé 26,89, Taza 46,93, Ceuta 38,104, Tangier 36,103; Marrakesh (Moors): Azemmour 16,84, Safi 11,77, Taroudant 10,67.
  Levels: EU5 cities 3 / 15000, all others 2 / 7500 (user). Garrison Ahdath Militia x2 everywhere (user; GARRISON egypt,
  moors added). Names: arabic (= default) + Latin + Greek + Turkish. All 32 reachable from their capitals in the
  BFS model. DUMP_PATHS = 8 North Africa routes. Check image rendered. Waiting for the user's test.
- NORTH AFRICA fix 1 (user, 13 Oct), installed, read back identical: removed Akhmim, Bahnasa, Bilbeis; moved Faiyum
  298,56, Asyut 301,40, Kairouan 148,102, Tangier 35,102, Safi 12,77, Sfax 152,94; added level 1 / 1000: Suez
  (al-Qulzum) 311,61 (Cairo), Melilla 54,99 (Fes). Ceuta 38,104 was NOT seen in game (user) -> set to level 1; cause
  open - check the log (STARTSETT ceuta) after the next test. 31 towns.
- NORTH AFRICA TEST 2 log (user, 13 Oct): all created except Ceuta - "addSettlement failed at 38,104 (nil), tile free
  true", DUMP Fes-Ceuta 0 tiles. 38,104 is the promontory at the Gibraltar strait crossing (37,105 beach links to
  Spain) - the engine refuses it. LESSON: keep towns off strait / land-bridge crossing tiles. Fix installed, read back
  identical: Ceuta -> 39,103 (fertile, 4 from Tangier); Suez 1 north -> 311,62 (user).
- NORTH AFRICA TEST 3 (user, 13 Oct): all fine - North Africa done.
- LOWER MESOPOTAMIA + PERSIA installed 13 Oct, read back identical (1 file, no map edit, map.rwm stays). EU5 (iraq_arabi,
  persia_region, western_khorasan): 21 towns - 10 are SSHIP settlements, Zaranj / Kabul / Ghazni / Quetta off the map,
  Soltaniyeh founded 1305, Rasht too small; taken: Kermanshah, Qom, Hormuz (old, mainland) level 3, Astarabad. 39 extras
  (known history, not checked page by page). Fit: affine on 17 SSHIP settlements + IDW (Merv residual -11, map edge).
  Tiles: nearest open tile (no mountain / dense forest / swamp 0,255,128 / river / beach, relief <= 30, a few 36),
  >= 4 from new towns, >= 3 from any settlement; BFS (step < 60) from each capital reaches all.
  Baghdad: Kufa 399,78 (3), Hilla 398,82 (3), Samarra 393,93 (1), Hulwan 404,95 (1); Mosul: Kirkuk 395,102; Basra: Ahvaz
  428,71, Ramhormoz 434,70, Arrajan 438,64 (1); Al_Wasit: Shushtar 429,77, Dezful 425,79 (1); Hamadan (ownerFrom Isfahan =
  Seljuk, user): Kermanshah 415,92 (3), Dinavar 417,97, Nahavand 421,92, Borujerd 430,91; Ray: Qom 444,96 (3), Astarabad
  467,113, Jurjan 472,114 (3), Damghan 468,105, Semnan 463,99; Yazd: Kashan 449,91; Alamut (ownerFrom Ray, user): Saveh
  440,100, Qazvin 436,105, Zanjan 427,109; Tabriz (rebels): Maragheh 410,111 (3), Khoy 403,124, Miyaneh 416,115, Ardabil
  428,126 (3; 4-5 NE of GPS), Urmia 396,118 (user wanted it; west lake shore all low mountain, moved ~6 W, BFS 20 from
  Tabriz); Neyshabur: Sabzevar 489,111, Esfarayen 493,109, Turshiz 495,98, Qaen 498,87, Tabas 490,92; Shiraz: Kazerun
  455,61, Fasa 468,51, Darab 473,55, Firuzabad 459,49, Siraf 458,45 (1), Abarkuh 463,70, Sirjan 475,61; Kerman (rebels):
  Hormuz 488,41 (3), Bam 501,55, Jiroft 493,48 (west of the river). Others level 2 / 7500; level 1 = the doubtful ones (user).
  Left out: Lahijan (Gilan coast 433-434,114-115 is a closed 3-tile pocket), Amol / Sari (dense forest + swamp), Marand,
  Tus (relief 67 next to Merv), Khorramabad (Zagros too steep), Bistam, Istakhr, Jahrom, Hit, Anbar, Sarakhs.
  Names: default Persian (Arabic in Iraq), arabic for abbasid, Turkish for turks / zengid, Greek + Latin (Harmozeia /
  Ormus, Hekatompylos, Laodikeia = Nahavand, Camadi = Jiroft). GARRISON turks 2 Ahdath Militia, abbasid 2 Shurtah Militia.
  DUMP_PATHS = 8 Persia routes. Waiting for the user's test (new campaign).
- MAP ROUND 4 (user, 13 Oct: open the Gilan coast from both sides, add Lahijan), installed, all 4 files read back
  identical. edit_map.py now also writes map_features.tga (original added to backups/2026-10-13_before_map) with
  CROSSINGS: rivers 432,115 and 435,115 -> crossings (0,255,255). CORRIDORS: Ardabil-Gilan coast 428,122-117, 429,116,
  430,115 (impassable / low mountain / dense forest -> hills, heights 7 -> 14 h10 = coastal flat); Gilan coast-Alamut
  436,113, 437,112-110, 436,110 (swamp / low mountain -> hills, 14 -> 203, step 31.5). Model: Alamut -> Lahijan 9 tiles,
  Tabriz -> Lahijan 30, also with steps < 40. Lahijan 434,115 (Alamut region, rebels, level 2) back in: 44 towns.
  DUMP_PATHS + Alamut-Lahijan, Ardabil-Lahijan. map.rwm must be deleted (user), new campaign.
- PERSIA TEST 1 (user, 13 Oct): removed Darab, Kazerun, Siraf, Esfarayen, Astarabad, Saveh, Dinavar, Ahvaz, Dezful,
  Samarra, and Gladzor in the Caucasus. Installed, read back identical: 34 towns in this region. DUMP Shiraz-Siraf ->
  Shiraz-Firuzabad.
- PERSIA: approved (user, 14 Oct). settler_check.lua deleted on the PC (user).
- ARABIA + STEPPE + VOLGA (+ Siberia) installed 14 Oct, read back identical (1 file, no map edit, map.rwm stays). EU5
  (arabia_region, steppes_region, ural_region, west_siberia_region). User: take all proposed + optional; towns founded
  after 1132 as level 1 / 500; skip Theodoro (2 tiles from Chersonesos) and Al-Hajr (Najd impassable on SSHIP).
  Not possible: Chimgi-Tura (Siberia, GPS tile x 546 = east of the map), Aden / Taizz / Taif (south of the map edge).
  Left out: Ar-Rabadha (ruined 930, not "founded later"), Tana (= Azaq). Fit: affine + IDW (Arabia on 11 settlements,
  steppe on 17); Crimea is compressed - set by hand (relief 67 there = sea slope, normal).
  Tiles: Mecca (Egypt): Medina 365,23 (2), Jeddah 361,1 (2, map edge), Khaybar 360,29 (1 / 1000); Al_Ahsa (rebels):
  al-Qatif 435,37 (2); Chersonesos (Byz): Sudak 329,170 (2), Kaffa 333,172 (1 / 500), Kerch 336,171 (2; 3 tiles from
  the strait); Chernigov (rebels): Kursk 338,218 (2); Bulgar (rebels): Bilyar 442,241 (3), Kazan 434,247 (1 / 1000),
  Juketau 448,244 (1 / 1000); Saqsin (rebels): Astrakhan 424,182 (1 / 500), Sarai al-Jadid 407,195 (1 / 500); Aktobe
  (Cumans): Saraychik 449,187 (1 / 500). 14 towns. BFS (swamp passable) reaches all from their capitals.
  Garrisons: Arabs / Bulgars 2 Ahdath Militia, Crimea Byz 2 Contaratoi, Kursk / steppe rebels 2 EE Spear Militia,
  new GARRISON cumans = 2 EE Spear Militia. DUMP_PATHS = 9 routes of this region. Waiting for the user's test.
- ARABIA/STEPPE fix 1 (user, 14 Oct), installed, both files read back identical: removed Kaffa (Theodosia), Astrakhan
  (Xacitarxan), Saraychik, Juketau. Kursk and Sarai al-Jadid start Cuman (ownerFrom = "Aktobe"). SAQSIN given to the
  Cumans in descr_strat: its settlement block moved from the slave section to the end of the cumans settlements, and its
  governor Turgut (was "sub_faction cumans" under slave, same army) moved to the cumans characters after Yesugatai.
  10 towns. NEW campaign needed; map.rwm can stay (no map image change). Watch SSHIP scripts that expect Saqsin rebel.
- ARABIA/STEPPE: user moved on to Russia (14 Oct) - taken as passed.
- RUSSIA installed 14 Oct, read back identical (1 file, no map edit, map.rwm stays). EU5 russian_region + ruthenia_region
  towns; Novgorod, Pskov, Smolensk, Polotsk, Kyiv, Chernihiv, Rostov, Grodno are SSHIP settlements. Fit: affine on 19
  settlements (Novgorod ... Plock, Bulgar; residuals up to 9 - SSHIP's Rus is distorted) + IDW; nearest open tile
  (no mountain / dense forest / swamp / river / beach, relief <= 30, >= 3 from any settlement, >= 7 open neighbours).
  User removed: Staraya Ladoga, Staraya Russa, Gomel, Terebovlia, Yaroslavl ("don't add Rostov" read as Yaroslavl - 3 tiles
  from Rostov; CONFIRM), Pinsk (Pripet marsh, no open tile). Left out for spacing: Izborsk, Vyshgorod, Belgorod, Lyubech, Kolomna.
  Tiles: Novgorod reg (russia): Tver 335,255 (1/500), Torzhok 328,257 (1/1000); Rustov (kievan_rus): Moscow 347,248 (1/500),
  Vologda 358,271 (1/500), Beloozero 343,278; Suzdal: Vladimir 364,249, Murom 379,247; Ryazan (rebels): Nizhny 392,253
  (1/500), Pronsk 367,237 (1/1000); Polotsk (rebels): Minsk 275,234, Vitebsk 295,242; Goroden (rebels): Brest 250,221;
  Volodymyr: Lutsk 262,212, Lviv 255,206 (1/500); Halych (rebels): Przemysl 245,205; Chernigov (rebels): Novgorod-Seversky
  320,222, Starodub 317,225; Smolensk: Toropets 305,252 (1/1000), Bryansk 327,230 (1/1000); Pereyaslav: Poltava 330,203
  (1/500). Others level 2 / 7500. Moscow / Tver: founded-after rule (1/500), user did not object. All reachable in the BFS model.
  Names (user): Russian for russia / kievan_rus / rebels, Polish for poland, Lithuanian for lithuania, Latin, Greek, Turkish.
  GARRISON russia / kievan_rus = 2 EE Spear Militia (rebels too). DUMP_PATHS = 9 Russia routes. Waiting for the user's test.
- RUSSIA fix 1 (user, 14 Oct), installed, both files read back identical: removed Vladimir ("Suzdal" read as Vladimir, the
  town 3 tiles from Suzdal - CONFIRM), Bryansk (Debryansk), Torzhok (Novyi Torg), Poltava (Ltava), Novgorod-Seversky, and
  Khaybar (Arabia). ROSTOV given to Novgorod (russia) in descr_strat: settlement block moved from kievan_rus to the end of
  the russia settlements, governor Volodar + army moved to the russia characters (campaign_script has no Rostov
  reference). So Beloozero and Vologda (region Rustov) start Novgorodian; Moscow ownerFrom = "Suzdal" -> stays Kievan Rus (user, 14 Oct). Jeddah 361,1 -> 358,5 (user: 4 up,
  3 west; low fertile, reachable from Mecca in 6). 14 Russia towns. NEW campaign; map.rwm can stay.
  PROPOSED, not installed: Pskov area (Izborsk 279,259; Porkhov; Velikiye Luki; Tartu / Otepaa in Kolyvan region;
  Koknese / Jersika in Riga region) and Oman / Gulf (Sohar 482,18, Julfar 478,29, Muscat 496,13 (inland, relief 45),
  Qatar 446,31; Bahrain has no island on SSHIP's map; Abu Dhabi founded 1761).
- MUSCAT added 14 Oct (user: anywhere in the area), read back identical: 496,13 (Al_Ahsa region, rebels, level 2 / 7500, 2 Ahdath Militia; coast is mountains, so 3-4 tiles inland). DUMP + AlAhsa-Muscat.
- PSKOV REGION towns REVERTED 14 Oct (user meant Pskov itself; SSHIP names it "Pleskov" in imperial_campaign_regions_and_settlement_names.txt). Back to 14 Russia towns + Muscat.
- COUNT correction: Russia has 15 towns (20 minus Vladimir, Bryansk, Torzhok, Poltava, Novgorod-Seversky), not 14.

## Campaign test 14 Oct 2026 (user, Rum, to turn 17) - AI loses half its land in civil wars
- Works: minor settlements, AI armies (Byzantium, Rum) march on REBEL minor settlements. Not seen: AI attacking
  faction-held minor settlements. Campaign slower, user likes that. Rebel end turn much longer now.
- Problem: civil wars for Moors, Byzantium, Rum (Byzantium lost about half).
- CAUSE FOUND (SSHIP `eopScripts/sship/internalAffairs.lua`, not ours): `countRevoltPoints` adds
  `settlNumberFactor * 10` with `settlNumberFactor = settlementsNum - 10` before turn 50 (-11 / -12 ... later).
  Every extra settlement = +10 points; threshold 20, AI bonus -35. Byzantium with ~20 extra towns is ~+200 ->
  from turn 6 the AI gets `civilWarRise` with 33 % per turn (no warning for the AI). In `civilWarRise` every
  settlement without a governor counts governor loyalty 0 -> roll + distance > 50 = goes to the rebels. Our towns
  never have governors, so they (and many big ones) flip. This also explains the slow rebel turn (far more rebel
  settlements and armies).
- Starter pack note: builders1 IS SSHIP's "Logging Camp" (section header in export_descr_buildings) and is already
  in STARTER for every level. Proposed additions: barracks town_watch (+1 law), level-1 temple of the owner's religion
  (small_church / small_church_o / small_masjid; pagan chains temple_dievas etc.).
- Proposed fix (waiting for the user's choice): wrap `countRevoltPoints` from our script and subtract 10 per
  hxstart_ settlement the faction owns (or count each as a fraction); optionally make hxstart_ towns harder to lose
  in `civilWarRise`. Asked the user for a log cut: `InternalA: the total rebelion points|Civil war begins|STARTSETT|ERROR`.
- CONFIRMED by eop.log (14 Oct): Byzantium settlNumberFactor 150 (25 settlements), total 79 points; civil wars
  moors, turks, byzantium x2; rebelled: 41 settlements incl. many hxstart_. Only error lines: SSHIP's own
  `shortcut waypoint_display::show_waypoints does not exist` (2130x, not ours). full.log (59 MB) could not be staged.
- Player: same countRevoltPoints, but warnings for 5-8 turns before the war, difficulty relief 0/10/20, no -35.
- FIX installed 14 Oct, read back identical (user's choice: modify SSHIP's script, every settlement counts the same,
  a quarter): `internalAffairs.lua` new `local SETTL_POINTS = 2.5` (was 10) used in the formula, the debug line and
  the player's warning text. Original in `backups/2026-10-14_before_civilwar/`. Byzantium now ~ -33 instead of 79.
- Starter pack (barracks town_watch + level-1 temple): user's idea, not built yet - waiting for his answer.

## BALKANS + GREECE (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Tools now in the repo: `docs/tools/setts.py` (SSHIP settlement tiles / regions / owners -> all_setts.txt; needs
  descr_regions.txt staged), `docs/tools/place.py <file "name lat lon">` (affine fit on 15 anchors + IDW, nearest
  open tile: fertile / hills / woodland / wilderness, no river, relief <= 30, >= 3 from SSHIP settlements, >= 7 open
  neighbours). SSHIP's "Nis" (228,168) sits where Belgrade is (residual 10) and Severin (264,168) far east - both
  left out of the fit.
- Proposed (26): Corinth reg: Athens 248,120 (EU5 city), Thebes 245,121, Patras 233,120, Kalamata 235,113,
  Monemvasia 241,112; Thessalonica reg: Larissa 239,132, Ohrid 231,144, Berroia 239,139, Serres 246,141; Arta reg:
  Ioannina 226,131; Durazzo reg: Valona 219,137; Ras reg (serbia): Skopje 233,148; Sredets reg: Nis 237,156,
  Plovdiv 257,150; Nis reg (rebels): Branicevo 235,166; Tarnovo reg: Vidin 244,161, Cherven 265,160, Drastar 274,163,
  Shumen 271,157, Varna 277,157, Sliven 267,153, Anchialos 274,152; Adrianople reg: Gallipoli 270,135,
  Mosynopolis 260,142; Skadar reg (rebels): Kotor 213,152; Smyrna reg: Rhodes 278,106 (island of 11 tiles).
  Left out: Belgrade (= SSHIP's Nis tile), Ruse / Targovishte (not towns before the 14th c.), Chalkis / Nauplia /
  Kastoria / Prizren (spacing), Corfu (no island on SSHIP's map), Croatia / Dalmatia (later with Hungary).
- User (14 Oct): "rename SSHIP Nis to Belgrade, add real Nis, add all others, Rhodes as a castle, open the coast
  Milas - Antalya". SSHIP's Nis already shows "Belograd" (text file {Nis}Belograd, settlementSituation names
  Belograd / Singidunum / Lándorfejérvár) - nothing changed there; internal name stays Nis (scripts use it).
  "All others" read as the 26 proposed towns (not the left-out ones). Open questions took the proposed defaults:
  Athens 3, Thebes 3, Branicevo 1 / 1000, rest 2 / 7500; Skopje stays Serbian (Ras region); names greek / european
  / middle_eastern + serbia + hungary + default (Slavic in Bulgaria / Serbia, Greek elsewhere); GARRISON serbia =
  2 Spear Militia, rebels (Branicevo, Kotor) 2 Spear Militia.
- Script: entry field `castle = true` -> addSettlement(..., true), core from CORE_CASTLE (level 2 = wooden_castle),
  starter roads = hinterland_castle_roads / c_roads (builders, farms, water have no city/castle limit);
  hinterland_castle_roads added to UNHINTERLAND_CHAINS. DUMP_PATHS = 11 Balkans / Lycia routes.
- MAP ROUND 5 (edit_map.py "Lycian coast"): 22 tiles 280,112 -> row 111 (281-287) -> row 110 (287-297) -> 297,111-113
  set to hills, heights ramped 60 -> 79 h10. Only map_ground_types.tga and map_heights.tga installed (edit_map's
  descr_strat output is OLD - never install it, the repo's descr_strat has later edits). BFS model: Milas - Attaleia
  23 steps. map.rwm must be deleted by the user; NEW campaign.
- BALKANS fix 1 (user, 14 Oct), installed, read back identical: Berroia removed; Ohrid 230,145, Serres 248,141,
  Ioannina 225,132, Plovdiv 256,150 (all open tiles). 25 towns. Script only - map.rwm and the new campaign as before.
  Note: the first commit wrote a stale copy (same output name re-used); a new file name fixed it - always cmp.

## POLAND + BALTIC (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Balkans + Greece confirmed tested, all fine (user, 14 Oct). Script only - no map edit, map.rwm stays; NEW campaign.
- EU5 (07_cities_and_buildings.txt + definitions.txt, read from `D:\Steam\steamapps\common\Europa Universalis V\game`) has only 16
  towns in central_poland / greater_poland / lesser_poland / mazovia / silesia / pomerania / prussia / lithuania / samogitia /
  baltic areas; 9 are already SSHIP settlements (Krakow, Poznan, Plock, Wroclaw, Gdansk, Szczecin, Kolyvan, Riga, Kernave...).
- Tool: `docs/tools/place.py` now takes `-a <anchor file>` (default = Balkan anchors); `docs/tools/anchors_poland_baltic.txt`
  (21 SSHIP settlements with GPS, residuals <= 3 except Plock 6.4 and Kernave -6.0). Same open-tile rules as before.
- User: "add all", Gniezno level 3, late-founded towns 1 / 500, Racibórz rebels, names as proposed, garrison EE Spear Militia.
  22 towns added (the 4 spacing drops Trakai, Kruszwica, Stargard, Otepaa stay out): Gniezno 204,223 (3); Kalisz 208,218;
  Wloclawek 219,224; Torun 213,226 (1/500); Leczyca 220,221; Czersk 233,220 (1/1000); Sandomierz 236,211; Lublin 241,215 (1/1000);
  Opole 207,210; Legnica 193,214; Glogow 193,217; Slupsk 200,237; Kaunas 246,238 (1/500); Vilnius 253,240 (1/500);
  rebels: Raciborz 210,207 (Olomoc region); Wolin 183,231, Kolobrzeg 188,234, Wolgast 176,234 (Szczecin region);
  Stralsund 171,235 (Lubeck region, 1/500); Tartu 270,265 (Kolyvan); Koknese 260,252 (Riga, 1/1000); Jersika 265,250 (Polotsk, 1/1000).
  Names: Polish / Lithuanian / Russian for those factions, German for hre + denmark (Thorn, Wollin, Kolberg, Dorpat ...), Latin,
  Greek, Turkish; `default` (rebels) = local name. GARRISON poland + lithuania = 2 EE Spear Militia (rebels: own list).
  DUMP_PATHS +14 routes (Poland / Baltic). 200 entries in SETTS, no duplicate tiles.
- POLAND + BALTIC fix 1 (user, 14 Oct), installed, 4 files read back identical (map_regions.tga, starting_settlements.lua,
  descr_strat.txt, descr_events.txt): Lancicia = Leczyca removed (21 towns left + Warsaw = 22); Legnica 193,214 -> 194,214;
  SSHIP's own Krakow city pixel 224,208 -> 218,208 (6 west; governor Boleslaw Piast moved too) and Szczecin 180,230 -> 180,231
  (1 north; tile is SWAMP, relief 0 - watch it; Warcislaw + event position moved) = MAP ROUND 6 in edit_map.py (CITY_MOVES,
  only these 4 pixels differ). WARSAW added 230,222 (Plock region, Poland), level 1 / 500; GPS tile 231,222 is 2 from Czersk, so 1 west.
  DUMP routes: Plock-Warsaw, Wroclaw-Legnica, Krakow / Szczecin starts updated. map.rwm MUST be deleted again; NEW campaign.
- POLAND + BALTIC confirmed tested, all fine (user, 15 Oct).

## HUNGARY + CROATIA (15 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Script only - no map edit, map.rwm stays; NEW campaign.
- EU5 (07_cities_and_buildings.txt + definitions.txt) has only 15 towns in transdanubia / north_alfold / south_alfold /
  slovakia / croatia / slavonia / slovenia / bosnia areas; 4 already SSHIP settlements (Zagreb, Esztergom, Dubrovnik,
  Szekesfehervar) and Buda/Pest share one tile at this resolution - Pest dropped.
- `docs/tools/anchors_hungary_croatia.txt`: 10 anchors (Esztergom, Vienna, Szekesfehervar, Varad, Gyulafehervar, Zagreb,
  Zara, Vrhbosna, Ragusa, Ras), residuals <= 4.7 except Esztergom (9.5, 3.0). Transylvania/Wallachia/Moldavia (Romania)
  left for a later region, same as Croatia/Dalmatia was held back from the Balkans round.
- User (15 Oct): garrison hungary + hre = 2 Spear Militia (new owner factions for #4); Knin/Rijeka/Trieste start as
  rebels; levels/population standard (EU5 city -> 3/15000, town -> 2/7500).
- 10 towns added: Buda 224,190 (3/15000, Esztergom region); Pecs 211,178, Sopron 202,188 (Szekesfehervar region);
  Szeged 226,179 (Varad region); Bratislava 205,193, Kosice 235,196, Krupina 223,195 (Esztergom region) - all hungary,
  2/7500. Rebels (`ownerFrom`, since their region's own owner isn't rebel): Knin 194,163 (Zagreb region, ownerFrom
  Zara), Rijeka 182,174 and Trieste 178,176 (Freiberg/hre region, ownerFrom Zara / Verona) - all 2/7500, garrison
  2 Spear Militia (entry's own `rebels` list, not GARRISON.hungary/hre).
  Names: hungary (Magyar) + hre (German) + european (Latin) + greek + middle_eastern + default, same table style as
  earlier rounds; e.g. Buda/hre "Ofen", Bratislava hungary "Pozsony"/hre "Pressburg", Kosice hungary "Kassa"/hre "Kaschau".
  New GARRISON entries: hungary, hre = 2 Spear Militia each (first time either faction owns a #4 settlement).
  DUMP_PATHS +11 routes (Esztergom/Szekesfehervar/Varad/Zagreb/Freiberg hubs to the new towns, plus Rijeka-Trieste).
- HUNGARY + CROATIA fix 1 (user's in-game check, 15 Oct), installed, read back identical:
  - GARRISON.hungary -> EE Spear Militia (export_descr_unit.txt: hungary has no ownership of plain "Spear Militia",
    only EE Spear Militia; hre and serbia both verified as IS in Spear Militia's ownership list, left unchanged).
    Knin/Rijeka/Trieste rebel garrison switched to EE Spear Militia too for consistency.
  - Pest added: 218,185, level 1 / 500, 2 tiles east of the new Buda, capital Szekesfehervar.
  - Buda moved 216,185 (5 east of Szekesfehervar) - now in the Szekesfehervar region, not Esztergom; capital field
    updated to match.
  - Bratislava 203,194 (2 west, 1 north); Kosice 234,197 (1 west, 1 north); Krupina: asked 221,195 (2 west), no open
    tile there (3x3 neighbours only 4) - snapped to 221,194.
  - Rijeka: asked 1 SW (181,173) - relief 50 there (cliff), snapped to 181,174 (net: 1 west of original). Trieste:
    asked 2W/1S (176,175) - off the region map there, snapped to 178,175 (net: 1 south of original). Both still rebel,
    ownerFrom unchanged.
  - Stralsund: asked 1W/2N (170,237) - no open tile within 8 of that target (nearest valid snap lands back on its own
    current tile, 171,235) - NOT moved; flagged to the user, no other input yet.
  - Poland + Baltic (existing entries): Wolin 184,231 (1 east), Glogow 192,218 (1 NW), Raciborz 211,206 (1 SE).
  - Not yet applied - need the user's input: Zagreb "2 down" (existing SSHIP settlement, not a script entry - would
    need a map edit like the Krakow/Szczecin moves, not just a lua coordinate change) and Eger "2 east 1 north" (not
    one of our placed towns - looks like a new addition but no base position was given).
  - DUMP_PATHS coordinates updated to match (Szekesfehervar-Buda, Buda-Pest, Esztergom-Bratislava/Kosice/Krupina,
    Freiberg-Rijeka/Trieste, Rijeka-Trieste, Szczecin-Wolin).
- HUNGARY + CROATIA fix 2 (user, 15 Oct), installed, read back identical:
  - MAP ROUND 7 in edit_map.py (CITY_MOVES): Zagreb's city pixel 193,177 -> 193,175 (2 south, user tested unit
    movement there first). Governor Saul Arpadhazi (descr_strat.txt) and the black_death_2 plague event position
    (descr_events.txt) moved with it - applied as isolated text replaces on the CURRENT files, not edit_map.py's
    regenerated output (which rebuilds descr_strat/descr_events from the 13 Oct pre-map backup and would silently
    revert every other #4 round's direct descr_strat.txt edits since - Rostov->Novgorod, Saqsin->Cumans, etc).
    edit_map.py now has a CAUTION comment about this; only the 4 TGA map files are safe to take from it wholesale.
    map.rwm must be deleted again; NEW campaign.
  - Trieste: the originally requested tile (176,175) checked out as real Venice_Province territory (color
    13,198,117, confirmed in descr_regions.txt/descr_strat.txt), not unassigned space - place.py's region check
    just didn't have Venice in its anchor list. No map edit needed; moved there, capital = Venice, still a rebel
    (ownerFrom Verona unchanged).
  - Stralsund moved to the originally requested 170,237 (1 west, 2 north) - user confirmed by moving a unit there
    in-game; place.py's neighbour-count heuristic was too conservative for this tile.
  - Still open: Eger - user thought it might already be a vanilla SSHIP settlement, but it isn't (no Eger_Province,
    no Eger settlement) and it's not in the EU5 city/town rank list either (only a plain "location"). Need the
    user to say where to place it if they still want it added.
- THEN: the user picks the next region for #4 (same method).

## ROMANIA (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Hungary + Croatia fix 2 and Eger: user will check them in the same next test. Script only - no map edit, map.rwm
  stays; NEW campaign.
- EU5 (07_cities_and_buildings.txt, carpathian section; definitions.txt transylvania / wallachia / moldavia / south_alfold
  areas + bulgaria_area north_dobruja): Cluj, Brasov, Iasi (already SSHIP), Suceava, Targoviste, Campulung, Bucharest,
  Ismail, Constanta. Scope (user): Transylvania, Partium, Banat, Wallachia, Moldavia, Danube mouth / Black Sea coast.
- `docs/tools/anchors_romania.txt`: 14 SSHIP settlements, residuals <= 3.2 except Esztergom (8.1, 3.4) and
  Szekesfehervar (-4.4). SSHIP's "Severin" (264,168) sits in central Wallachia, not at real Turnu Severin - not an anchor.
- User: add all as proposed; levels as proposed; late towns 1 / 500; Barlad + Chilia Cumans, Cetatea Alba rebels
  (ownerFrom Severin); Vicina/Isaccea named by owner (greek Bitzina, european Vicina, turkish Isakca, default Isaccea).
- 20 towns: hungary (EE Spear Militia): Cluj 249,183 (2/7500), Satu Mare 245,189 (1/1000), Arad 233,178 (2/7500),
  Timisoara 233,175 (1/1000), Sibiu 253,177, Brasov 263,177, Bistrita 256,186, Sighisoara 258,179 (all 1/500);
  rebels (EE Spear Militia): Severin region Craiova 251,165, Curtea de Arges 254,170, Targoviste 261,166, Bucharest 266,165,
  Braila 278,172 (all 1/500); Halych region Suceava 268,189 (1/500), Hotin 271,196 (1/1000); Cetatea Alba 293,178 (2/7500,
  Iasi region, ownerFrom Severin); cumans: Barlad 277,178, Chilia 288,175 (1/1000); byzantium (Contaratoi): Isaccea/Vicina
  282,172, Constanta 282,164 (2/7500).
- Dropped for spacing: Turda, Dabaca (Cluj), Cenad (Szeged), Galati (Braila), Siret, Baia (Suceava), Ismail, Tulcea
  (Isaccea); Campulung (only open Severin-region tile lies south of Arges); Caransebes, Tighina (late, minor).
- Names: hungary / hre / european (Latin) / greek / middle_eastern, plus poland, kievan_rus, russia, cumans where they fit;
  default = Romanian (rebels). DUMP_PATHS +20 routes (Romania block).
- THEN: user's test (Hungary + Croatia fix 2, Eger, Romania), then the next region.
- ROMANIA fix 1 (user's test, 14 Oct), installed, read back identical (4 files):
  - Eger: dropped - it is SSHIP's own Esztergom (shown as "Eger" in imperial_campaign_regions_and_settlement_names.txt).
  - Zagreb / Rijeka "not moved": PC files were all identical to the repo, but map.rwm (mtime 1792000195230) was OLDER
    than map_regions.tga (1792001786583) - the game kept the stale map. Rijeka now on the asked tile 181,173 (relief 50,
    Zara region). User must delete map.rwm again.
  - Blank names: the font lacks Romanian comma letters (s/t with comma) and a-breve. All names in SETTS transliterated to
    SSHIP's own glyph set (s-comma -> s-cedilla as SSHIP's "Targovishte" uses; t-comma, a-breve, c-caron, Turkish dotless/
    dotted i, g-breve, Polish/Lithuanian letters -> plain letters): 49 names changed.
  - Our Targoviste removed: SSHIP's own "Severin" settlement (264,168) IS Targoviste (localised name) - duplicate.
  - Tarnovo -> rebels (region rebel type already Bulgarian_Rebels): settlement block moved to the slave section of
    descr_strat; garrison general "Boris" (sub_faction serbia, name from serbia's list) with 2 Bulgarian Brigands, 2 Slav
    Levies, Vlach Axemen, 2 Vlach Archers; Konstantinos Angelos (family tree) moved to Triadica (247,152).
    Rebels with it: Cherven (Tzerbenon), Drastar ("Prista" = Dristra, assumed), Vidin ("Bidize" = Bidine), Isaccea
    ("Bitina" = Bitzina) - EE Spear Militia. Shumen, Varna, Sliven, Anchialos, Constanta stay Byzantine (ownerFrom Adrianople).
  - Moves (script): Gallipoli 270,138; Poimanenon 278,130; Birgi (Pyrgion) 276,122; Mardin 369,115; Khoy 403,123;
    Isaccea 283,171; Chilia 287,173 (swamp); Constanta 283,163; Varna 278,156; Anchialos 276,151 (beach tile); Sliven 267,154;
    Vidin 245,164; Nis 237,155 (now Ras region tile, owner still from Sredets); Knin 192,164.
  - MAP ROUND 8 (edit_map.py CITY_MOVES, only map_regions.tga changed - 6 pixels): SSHIP's Iasi ("Siret") 276,185 -> 277,185,
    Ragusa 208,153 -> 207,154, Arta 228,128 -> 229,128; characters Sevinch, Dobrica Perovic, Andronikos Imerios and the
    Iasi event position moved by hand in the current descr_strat/descr_events.
  - DUMP_PATHS coordinates updated; NEW campaign + delete map.rwm.
  - Fix 2 (user, 14 Oct): Varna back 1 west (277,156), Sliven back 1 south (267,153); installed, read back identical.

## IBERIA (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Script only - no map edit, map.rwm stays; NEW campaign. Backup of the script before: `backups/2026-10-14_before_iberia/`.
- EU5 `# Iberia` block: 9 cities + 45 towns; 17 are SSHIP's own settlements (Barcelona, Cordoba, Granada, Lisbon, Sevilla,
  Toledo, Valencia, Valladolid, Badajoz, Burgos, Coimbra, Leon, Murcia, Palma, Pamplona, Zaragoza, Santiago).
- `docs/tools/anchors_iberia.txt`: 18 SSHIP settlements (+ Bordeaux, Toulouse), residuals <= 1.8. SSHIP's Valladolid
  (35,140) sits ~7 tiles west of the real town (between Zamora and Salamanca) - NOT an anchor; Salamanca / Medina lie east of it.
- User: "yes lets start" = all proposed defaults. 44 towns, owner = real 1132 owner, levels EU5 city 3/15000, town
  2/7500, small / resettled 1/1000; garrison spain / portugal / aragon = 2 Spear Militia (new GARRISON lines), moors Ahdath.
  spain: Alcala 54,137, Ciudad Rodrigo 31,138 (1), Medina del Campo 42,143 (1), Salamanca 38,142, Segovia 46,142 (Burgos reg),
  Zamora 37,145, Santander 51,157 (1), Oviedo 31,158 (tight tile, 5 open neighbours), Lugo 23,155 (1), Astorga 35,149 (1),
  Talavera 43,134. aragon: Calatayud 66,143, Huesca 74,149, Tudela 66,147, Girona 97,148, Tarragona 86,143 (1),
  Soria 59,145 (1, Burgos reg, ownerFrom Zaragoza), Barbastro 77,148 (1), Vic 93,147 (1). portugal: Viseu 21,138,
  Porto 16,143, Braga 17,146, Guimaraes 20,144. moors: Malaga 45,111 (3), Almeria 62,113, Ecija 41,116, Jaen 50,120,
  Jerez 35,110, Jativa 74,128, Orihuela 72,122, Caceres 32,130, Evora 20,124, Santarem 15,129, Faro 22,115, Beja 22,120,
  Niebla 31,115, Algeciras 38,107 (4 from Ceuta), Denia 77,125, Lorca 65,118, Merida 32,126 (1); ownerFrom Valencia
  (Muslim in 1132 inside Christian regions): Lleida 82,145, Tortosa 81,140, Cuenca 61,134 (Toledo reg), Morella 76,141 (1).
- Dropped for spacing: Ronda, Guadalajara, Castellon (plain town 1251), Cervera, Mertola, Baeza, Cadiz, Avila, Tarazona,
  Huelva; also Teruel (1171), Coria, Ibiza / Menorca (no open land tile).
- Names: keys spain (Castilian), portugal, aragon (Catalan / Aragonese), arabic (moors), european (Latin), default = local
  Romance name. Only Latin-1 letters (a-tilde, accents) - no glyphs outside SSHIP's font. DUMP_PATHS +44 (Iberia block).
- IBERIA fix 1 (user, 14 Oct), installed, 3 files read back identical:
  - Removed 13: Jerez, Ecija, Faro, Merida, Lorca, Jativa, Vic, Barbastro, Tudela, Alcala, Astorga, Medina del Campo,
    Ciudad Rodrigo (+ their DUMP routes).
  - SSHIP's own "Valladolid" settlement was displayed as "Salamanca" (text file) -> renamed: {Valladolid}Valladolid and
    {Valladolid_Province}Valladolid in `data/text/imperial_campaign_regions_and_settlement_names.txt` (UTF-16; original in
    `backups/2026-10-14_before_iberia/data/text/`; the game rebuilds .strings.bin since the .txt is newer). SSHIP's
    settlementSituation.lua already names it Valladolid for every culture. Our Salamanca moved to 31,138 (old Ciudad Rodrigo tile).
  - Algeciras ("Gibraltar" to the user) 38,107 -> 39,107.
  - Bilbao added 56,156 (Pamplona region, ownerFrom Burgos = spain), 1/500 (founded 1300); default name Bilbo.
  - Romania leftover: SSHIP's Byzantine priest Kosmas Attikos stood on Isaccea's tile 283,171 (rebel town) -> 282,164 next
    to Constanta (descr_strat.txt).
  - Iberia now 32 towns; 262 entries in SETTS. NEW campaign; map.rwm stays (no map edit).

## ITALY + ISLANDS (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Script only - no map edit, map.rwm stays; NEW campaign. Backup: `backups/2026-10-14_before_italy/`.
- EU5 `#Italy` block: 24 cities + 61 towns; 13 are SSHIP's own. Anchors `docs/tools/anchors_italy.txt` (17, residuals <= 2.4).
  Placement: ok() of place.py with >= 4 open neighbours (coastal towns), 4-tile spacing between new towns, 3 to others.
- User: "add all" = 34 core + 19 optional + Bonifacio (Corsica, 144,145, part of Cagliari_Province) + Malta (Mdina 181,104;
  Malta = 3 woodland tiles of Palermo_Province, relief 28 - should be passable; user: if not, make it passable). 55 towns:
  sicily 18, papal_states 4, hre 1 (Udine), rebels 32 (north Italy communes, Sardinia, Corsica, Capua, Gaeta ownerFrom Naples,
  Volterra ownerFrom Florence); Salerno ownerFrom Palermo (sicily). Levels: EU5 city 3/15000, town 2/7500 (+ Capua, Trani);
  L'Aquila, Villa di Chiesa (Iglesias) 1/500 (late); Udine, Mdina, Bonifacio 1/1000. Garrison 2 Spear Militia (sicily,
  papal_states, venice, pisa, rebels).
- Names: Italian for sicily / papal_states / venice / pisa / rebels, German hre, Latin european, Greek, Arabic, Turkish.
- Not placeable: Amalfi, Chioggia, Piacenza, Bergamo, Lodi, Monza, Pistoia, Rimini, Imola, Cesena, Reggio Emilia, Macerata,
  Benevento, Mazara, Crotone, Trento, Alessandria, Manfredonia. DUMP_PATHS +55 (Italy block). Check image `italy_check.png`.
- ITALY fix 1 (user's test, 14 Oct), installed, 4 files read back identical:
  - Malta works -> now a castle (castle = true), named "Malta" for every owner.
  - Removed 8: Cefalu, Modica, Catania, Brindisi, Melfi, Pesaro, Udine ("Weiden" = its hre name), Villa di Chiesa (Iglesias).
  - Moves (script): Girgenti 177,115; Syracuse 186,111; Messina 188,120; Catanzaro 200,127; Gaeta 176,144; Spoleto 170,152;
    Viterbo 166,149; Padua 163,172; Savona 138,165 (relief 32); Bilbao (Iberia) 63,157 (7 east, 1 north, still Pamplona region).
  - MAP ROUND 9 (edit_map.py CITY_MOVES, only map_regions.tga changed - 2 pixels): SSHIP's Reggio ("Regium") 191,120 ->
    192,120 (hills, relief 45); Tancredi Guiskard (descr_strat) and the event position (descr_events) moved by hand.
  - Garrisons: plain Spear Militia is NOT ownable by sicily / papal_states / venice / pisa (all three export_descr_unit.txt)
    -> GARRISON for those four and the Italian rebel lists = 2 Urban Spear Militia.
  - 47 Italian towns. map.rwm must be deleted (was older than the new map_regions.tga); NEW campaign.
  - Fix 2 (user, 14 Oct): Udine re-added as rebels (ownerFrom Verona) on 172,176 (Venice_Province, 2 south of its first tile), 1/1000, Urban Spear Militia; installed, read back identical -> 48 towns.

## FRANCE (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- Italy confirmed done (user, 14 Oct). Script only - no map edit, map.rwm stays; NEW campaign. Backup: `backups/2026-10-14_before_france/`.
- EU5 `#France` block: 13 cities + 49 towns; 15 are SSHIP's own. Anchors `docs/tools/anchors_france.txt` (20, residuals <= 1.5).
- 34 towns: france 7 (Amiens, Chartres, Sens, Chalons, Laon, Blois, Bourges), england 3 (Caen, Cherbourg, Tours),
  hre 6 (Besancon "Bisanz" for hre, Valence, Avignon, Marseille, Sisteron, Le Puy - user: towns in hre territory owned by hre),
  rebels 18 (Nantes; Angouleme, La Rochelle, Agen, Perigueux, Tarbes, Bayonne; Albi, Cahors, Carcassonne, Narbonne,
  Montpellier [1 west of GPS for spacing], Nimes, Perpignan; Rodez; Autun; Arras, Saint-Omer).
- Levels: EU5 city 3/15000 (Tours, Narbonne, Montpellier, Arras, Marseille); small in 1132 1/1000 (Cherbourg, La Rochelle,
  Tarbes, Sisteron); rest 2/7500. Garrison 2 Spear Militia (GARRISON france / england added; rebels list per entry).
- Names: French for france / england / hre / rebels, Latin for `european`. Only Latin-1 accents.
- Not added (spacing <= 2 tiles to a bigger neighbour; taken as accepted, user only answered the ownership question):
  Aix, Beauvais, Beziers, Montauban, Saint-Flour, Montbrison, Provins, Vienne. Left for the HRE round: Metz, Strasbourg,
  Colmar, Mulhouse (Trier / Basel provinces). DUMP_PATHS +34 (France block). Check image `france_check.png`.
- FRANCE fix 1 (user, 14 Oct), installed, 3 files read back identical:
  - Removed: Sens, Nimes, Perpignan. Saint-Omer replaced by Calais 91,212 (2 NW of its tile; coastal, 5 open neighbours;
    village until the 1181 charter -> 1/500, rebels). Moves: Arras 96,207 (1 W), Laon 100,201 (1 S 2 W), Autun 107,182 (1 SW),
    Le Puy 108,173 (1 NW, 6 open neighbours). -> 31 French towns.
  - MAP ROUND 10 (edit_map.py CORRIDORS "Turin-Aosta-Valais"; only map_ground_types / map_heights changed, 11 tiles):
    Turin 133,170 -> 132,170 -> 132,171 ... 130,174 (Aosta) -> 129,175-177 (Great St Bernard) -> 128,177 -> Valais hills
    128,178 at the east end of Lake Geneva; hills, heights ramped 31 -> 225 h10 (steps about 16). Diff against the
    installed maps: only those pixels. DUMP_PATHS: Turin-Valais pass, Turin-Lake Geneva (129,180), Turin-Lyon.
  - map.rwm must be deleted; NEW campaign.

## BRITISH ISLES (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- France not yet confirmed by the user when this round started. Script only - no map edit, map.rwm stays; NEW campaign.
  Backup: `backups/2026-10-14_before_british_isles/`.
- EU5 `# britain` + `# ireland` blocks: 1 city + 25 towns; 8 are SSHIP's own (London, Edinburgh, York, Bristol, Lincoln,
  Norwich, Aberdeen, Dublin). Anchors `docs/tools/anchors_british_isles.txt` (11 incl. Rouen, Ghent; residuals <= 2.1).
- User: "just A" = only the EU5 towns (17); proposed extras (Winchester, Exeter, Canterbury, Chester, Gloucester, Durham,
  Carlisle, Cardiff, Pembroke, Roxburgh, Stirling, Armagh + 15 optional Midland / Irish / Scottish places) NOT added.
- england 7: Coventry 67,223 (Lincoln reg), Oxford 68,217 (London), Cambridge 79,221, Colchester 84,219 (Norwich) 2/7500;
  Salisbury 64,213 (Bristol; tile = Old Sarum) 2/7500; Lynn 83,223 (3 E of GPS for spacing), Boston 77,228 1/1000.
  scotland 3: Perth 55,251, Berwick 64,246 (Edinburgh) 2/7500; Inverness 48,259 (Aberdeen) 1/1000.
  rebels 7 (Dublin reg): Cork 17,219, Waterford 26,221, Wexford 31,222, Limerick 16,224 2/7500; Galway 11,227 1/1000;
  New Ross 27,225, Sligo 17,236 1/500 (late).
- Garrison: GARRISON.scotland = 2 Spear Militia (new; scotland is in its ownership list); england as before;
  Irish rebel towns 2 Irish Kerns (user; ownership all).
- Names: English for england / scotland, Latin for european, default = English (Britain) / Irish Gaelic (Ireland:
  Corcaigh, Port Láirge, Loch Garman, Luimneach, Gaillimh, Ros Mhic Thriúin, Sligeach). DUMP_PATHS +17.
- BRITISH ISLES fix 1 (user, 14 Oct), installed, read back identical:
  - Lynn removed. Added: Exeter 52,210 (Bristol reg, england, 2/7500); Cardiff 54,216 (Caernarvon reg, ownerFrom London =
    england, 1/1000, default name Caerdydd); Lancaster 58,235 (York reg, england, 1/1000 - user wanted a town in the
    Liverpool / Manchester area, both founded later); Glasgow 48,248 (Edinburgh reg, scotland, 1/1000); Downpatrick 36,237
    (Dublin reg, rebels, 1/1000, Dún Pádraig, Irish Kerns - Ulster town). -> 21 towns. DUMP_PATHS updated.
  - CAUTION (tooling): device_commit_files re-sent an OLD cached upload when the staged output path was reused - the
    first fix-1 write put the previous version back. Use a NEW output file name for every install, then read back.

## HOLY ROMAN EMPIRE (14 Oct 2026) - INSTALLED, read back identical, waiting for the user's test
- User: "build it" = all proposed defaults. Script only - no map edit, map.rwm stays; NEW campaign.
  Backup: `backups/2026-10-14_before_hre/`. Anchors `docs/tools/anchors_hre.txt` (21; SSHIP's "Hamburg" settlement
  is Magdeburg (Magideberc), its "Freiberg" is Carinthia; residuals <= 3.6, Brandenburg worst).
- EU5 `#Germany` + `#Low Countries` + Metz / Strasbourg / Colmar / Mulhouse from `#France`: 95 towns, 20 already on the
  map. 76 candidates -> greedy by importance, 4 tiles to new towns, 3 to existing -> 50 + Leipzig (1 E of GPS) = 51.
- hre 36 (incl. Hamburg, Halle, Zerbst, Leipzig, Freiberg/Saxony via ownerFrom "Hamburg" = Magdeburg; Geneva, Bern in
  Lyon region), rebels 15 (Bruges, Tournai, Antwerp, Namur, Mons, Groningen, Deventer, Dordrecht; Brno, Plzen, Kutna Hora,
  Gorlitz [Wroclaw region, ownerFrom Prague]; Wismar, Kiel, Berlin, Wittenberg). Garrison 2 Spear Militia (hre + rebels;
  ownership verified).
- Levels: EU5 cities 3/15000 (Hamburg, Mainz, Augsburg, Erfurt, Bruges, Metz); towns 2/7500; small in 1132 1/1000 (Leipzig,
  Graz, Freiburg, Zerbst, Gorlitz, Plzen, Melk, Kempten, Oettingen, Stuttgart, Gottingen, Dordrecht, Ravensburg); founded
  later 1/500 (Wismar, Berlin, Kiel, Innsbruck, Bern, Freiberg, Wittenberg, Klagenfurt, Landau, Kutna Hora, Dusseldorf).
- Names: hre German, european Latin, default local (Dutch / French / German, Czech without hacek), france / england /
  poland where they differ. Latin-1 only.
- Dropped for spacing: Worms, Liege, Ypres, Brussels, Maastricht, Middelburg, Dortmund, Soest, Osnabruck, Brunswick,
  Luneburg, Konstanz, Colmar, Mulhouse, Wetzlar, Rothenburg, Zutphen, Memmingen, Munich, Rostock, Heidelberg,
  's-Hertogenbosch, Zwolle, The Hague, Amsterdam, Beeskow, Sint-Niklaas. DUMP_PATHS +51 (HRE block).
- HRE fix 1 (user, 14 Oct), installed, read back identical:
  - Removed: Dordrecht, Tournai, Landau, Kempten. Moves: Mons 105,207 (1 S), Bruges 98,212 (2 W), Luxembourg 120,201
    (2 W; hre name Luxemburg instead of Lützelburg), Bern 131,182 (1 S).
  - Added: Amsterdam 112,222 (GPS tile, wood in marsh, 2 tiles from SSHIP's Utrecht 114,220; rebels, 1/500) - no wider
    land tile there; Marburg (Maribor) 193,181 (Carinthia region, north of the Drava river, hre, 1/1000).
  - 49 HRE towns. NEW campaign; map.rwm stays.

## HRE fix 2 (user, 15 Oct 2026)
- Marburg (maribor) 193,181 -> 195,180 (2 east, 1 south). The tile lies in the Hungarian (Szekesfehervar) region; the
  owner still comes from Freiberg (hre).
- Ljubljana (key ljubljana) added at 185,176, level 1, 1000 people, owner hre (capital Freiberg); GPS tile 184,177,
  moved 1 east for room to Klagenfurt (3 tiles). Names: hre/hungary Laibach, european Labacum, default Ljubljana.
- Installed 15 Oct together with #5 fix 1, read back identical. The installed file already held Scandinavia, the gap
  round and the bigger starter pack (from another session, not committed before) - now committed.
- Open bug reported in the same test: Karahisar's small_masjid damaged by a revolt on turn 2 could not be repaired
  ("already in queue", repair timer 0). Cause not found in the log; workaround proposed (auto-repair), waiting for
  the user's go-ahead and whether repair works in SSHIP's own settlements.

## Venice + Cuman villages (user, 15 Oct 2026)
- Udine and Trieste now start as venice (ownerFrom Verona removed; owner = Venice). Trieste got a venice name "Trieste".
  Garrison = GARRISON.venice (Urban Spear Militia x4).
- Three Cuman villages, level 1 / 500, capital (= owner) Azaq, where Kherson, Zaporizhzhia and Donetsk are today:
  kherson 313,181 (GPS tile), zaporizhzhia 334,191 (GPS 331,189 is dense forest -> nearest open tile), donetsk 351,191
  (GPS tile). Anchors: docs/tools/anchors_ukraine.txt. Route checks Azaq -> each added. Modern names (none existed in 1132).
- Installed 15 Oct, read back identical. Script only: NEW campaign, map.rwm stays.
- Karahisar mosque: in the new test the mosque was not damaged (BDIAG turns 1-2: small_masjid hp 100, builders2
  present; wells 66 and town_watch 53 damaged and repairable). small_masjid needs builders1 min level, a town and a
  Muslim faction - all met, so the requirements are not the cause. Not reproduced; BDIAG stays on for the next test.

## Cuman villages fix + Volterra (user, 15 Oct 2026)
- kherson 313,181 -> 309,182; zaporizhzhia 334,191 -> 324,188; donetsk 351,191 -> 351,193. MAP ROUND 11 (applied to the
  INSTALLED TGAs, see CAUTION 2 in edit_map.py - the PC had uncommitted gap-round map edits, now committed): Dnieper
  crossing 325,189 (map_features), 84 dense forest tiles in x 318-341 / y 181-194 -> forest (map_ground_types).
- Volterra starts Pisan (ownerFrom Florence removed). Cuman faction garrison Kasogi instead of EE Spear Militia.
- Installed 15 Oct, read back identical. map.rwm must be deleted; NEW campaign.
