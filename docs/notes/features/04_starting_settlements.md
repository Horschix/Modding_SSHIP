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
