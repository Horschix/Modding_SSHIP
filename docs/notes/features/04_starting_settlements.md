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
