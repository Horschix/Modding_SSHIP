--[[
    Extra settlements at the start of a new campaign (Horschix/Modding_SSHIP #4, 13 Oct 2026)

    Towns and cities that EU5 has on its 1337 map and that, by Wikipedia, already existed in summer 1132
    (SSHIP's start date) are added as extra (minor) settlements in a region, owned by whoever owns the region's
    main settlement. Rules of the user (13 Oct 2026):
      - EU5 "city" -> level 3 (city, stone_wall), 15000 people
      - EU5 "town" -> level 2 (large town, wooden_wall), 7500 people
      - tile from the real GPS position, projected onto SSHIP's map with 15 known settlements (about 1 tile exact)
      - names by the owner's culture, the same way SSHIP's settlementSituation.lua renames its own settlements:
        a name for the owner's faction first, otherwise for its culture (greek = Greek name, middle_eastern =
        Turkish name, the three European cultures = Latin name)

    WHEN:
      - onNewGameLoaded (a new campaign, first time its data exists): every entry of SETTS is created once.
        Nothing is created in a campaign that was started before this file was installed.
        If a settlement of that internal name already exists, it is skipped (never twice).
      - starter buildings (table STARTER, by level) at creation, and missing ones again at every map load (so an
        existing campaign with Prousa gets them too; a chain that exists is never touched).
      - TEMPORARY check at every map load: CHECK lines with what Prousa and Nicaea may build (remove after the test).
      - names are set again when the map is loaded (a loaded save may not keep them), after a capture and at
        every faction's turn start (covers gifts, rebellions and other owner changes).

    HOW IT IS LOADED: a line at the end of eopData/eopScripts/luaPluginScript.lua
        require('sship.starting_settlements')
    after require('sship.main') (it wraps event functions defined there). Delete the line to switch it off;
    settlements already created stay in the save.
    Nothing here calls M2TWEOP or M2TW while the file is loading. Game-log lines start with STARTSETT
    (in mods\sship\full.log).
]]
local SS = {}

-- internal name = "hxstart_" .. key. capital = internal name of the region's main settlement (owner lookup).
-- names: greek / middle_eastern / european are the culture names; a faction name can be added as a key too.
-- Anatolia (user, 13 Oct 2026). default = name while rebels hold it (SSHIP itself never renames for rebels).
-- Kastamonu and Alanya: their land was opened in the map edit of 13 Oct 2026 (docs/tools/edit_map.py, round 2).
local SETTS = {
    -- region Nicaea (Byzantium)
    { key = "bursa", x = 285, y = 136, capital = "Nicaea", level = 3, population = 15000,
      names = { greek = "Proúsa", middle_eastern = "Bursa", european = "Prusa" } },
    { key = "izmit", x = 290, y = 139, capital = "Nicaea", level = 3, population = 15000,
      names = { greek = "Nikomīdeia", middle_eastern = "İznikomid", european = "Nicomedia" } },
    { key = "kutahya", x = 290, y = 130, capital = "Nicaea", level = 2, population = 7500,       -- GPS tile is mountain
      names = { greek = "Kotýaion", middle_eastern = "Kütahya", european = "Cotyaeum" } },
    { key = "poimanenon", x = 277, y = 131, capital = "Nicaea", level = 1, population = 1000,   -- on Balıkesir's tile
      names = { greek = "Poimanīnon", middle_eastern = "Manyas", european = "Poemanenum" } },
    -- region Smyrna (Byzantium)
    { key = "bergama", x = 272, y = 127, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Pérgamon", middle_eastern = "Bergama", european = "Pergamum" } },
    { key = "manisa", x = 273, y = 124, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Magnīsía", middle_eastern = "Manisa", european = "Magnesia" } },
    { key = "birgi", x = 278, y = 121, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Pyrgíon", middle_eastern = "Birgi", european = "Pyrgion" } },
    { key = "alasehir", x = 281, y = 122, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Philadélpheia", middle_eastern = "Âlâşehir", european = "Philadelphia" } },
    { key = "denizli", x = 286, y = 119, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Laodíkeia", middle_eastern = "Lazkiye", european = "Laodicea" } },
    { key = "milas", x = 276, y = 116, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Mýlasa", middle_eastern = "Milas", european = "Mylasa" } },
    -- region Angora (Rum)
    { key = "afyon", x = 296, y = 125, capital = "Angora", level = 2, population = 7500,
      names = { greek = "Akroinón", middle_eastern = "Karahisar-ı Sâhib", european = "Acroinum" } },
    { key = "uluborlu", x = 294, y = 121, capital = "Angora", level = 2, population = 7500,     -- GPS tile is mountain
      names = { greek = "Sōzópolis", middle_eastern = "Uluborlu", european = "Sozopolis" } },
    -- region Attaleia (Byzantium)
    { key = "alanya", x = 307, y = 110, capital = "Attaleia", level = 2, population = 7500,
      names = { greek = "Kalón Óros", middle_eastern = "Alaiye", european = "Candelore" } },
    -- rebel regions (Danishmend lands, Armenian Cilicia)
    { key = "kastamonu", x = 319, y = 143, capital = "Sinop", level = 2, population = 7500,  -- Danishmend until 1133
      names = { greek = "Kastamōn", middle_eastern = "Kastamonu", european = "Castamon", default = "Kastamonu" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "amasya", x = 335, y = 138, capital = "Sives", level = 3, population = 15000,
      names = { greek = "Amáseia", middle_eastern = "Amasya", european = "Amasea", default = "Amasya" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "niksar", x = 343, y = 138, capital = "Sives", level = 2, population = 7500,
      names = { greek = "Neokaisáreia", middle_eastern = "Niksar", european = "Neocaesarea", default = "Niksar" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ladik", x = 333, y = 140, capital = "Sives", level = 2, population = 7500,
      names = { greek = "Laodíkeia Pontikī", middle_eastern = "Lâdik", european = "Laodicea Pontica", default = "Lâdik" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "bafra", x = 335, y = 145, capital = "Sinop", level = 2, population = 7500,
      names = { greek = "Gadilōn", middle_eastern = "Bafra", european = "Gadilon", default = "Bafra" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "elbistan", x = 344, y = 121, capital = "Malatya", level = 2, population = 7500,
      names = { greek = "Plastentía", middle_eastern = "Elbistan", european = "Plastentia", default = "Plastentía" },
      rebels = { "Armenians of Celicia", "Ahdath Militia" } },
    { key = "tarsus", x = 328, y = 112, capital = "Sis", level = 2, population = 7500,
      names = { greek = "Tarsós", middle_eastern = "Tarsus", european = "Tarsus", default = "Tarson" },
      rebels = { "Armenians of Celicia", "Armenians of Celicia" } },    -- Caucasus (13 Oct 2026): EU5 Van / Ganja / Gladzor + user-approved extras; one name for every culture
    { key = "van", x = 391, y = 122, capital = "Tabriz", level = 3, population = 15000,  -- moved 13 Oct: low-mountain tile not reachable in game
      names = { greek = "Van", middle_eastern = "Van", european = "Van", default = "Van" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ganja", x = 411, y = 138, capital = "Tbilisi", ownerFrom = "Ani", level = 1, population = 1000,  -- EU5 town; Seljuk until 1138, starts Georgian (user)
      names = { greek = "Ganja", middle_eastern = "Ganja", european = "Ganja", default = "Ganja" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "gori", x = 395, y = 149, capital = "Tbilisi", level = 1, population = 1000,  -- GPS tile 396,148 is river
      names = { greek = "Gori", middle_eastern = "Gori", european = "Gori", default = "Gori" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "dmanisi", x = 397, y = 143, capital = "Tbilisi", level = 1, population = 1000,
      names = { greek = "Dmanisi", middle_eastern = "Dmanisi", european = "Dmanisi", default = "Dmanisi" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "telavi", x = 404, y = 146, capital = "Tbilisi", level = 1, population = 1000,  -- GPS tile dense forest
      names = { greek = "Telavi", middle_eastern = "Telavi", european = "Telavi", default = "Telavi" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sukhumi", x = 374, y = 155, capital = "Kutaisi", ownerFrom = "Ani", level = 1, population = 1000,
      names = { greek = "Sukhumi", middle_eastern = "Sukhumi", european = "Sukhumi", default = "Sukhumi" },
      rebels = { "georgian light spearmen", "georgian light spearmen" } },
    { key = "artanuji", x = 381, y = 142, capital = "Kutaisi", ownerFrom = "Ani", level = 1, population = 1000,
      names = { greek = "Art'anuji", middle_eastern = "Art'anuji", european = "Art'anuji", default = "Art'anuji" },
      rebels = { "georgian light spearmen", "georgian light spearmen" } },
    { key = "akhaltsikhe", x = 387, y = 145, capital = "Kutaisi", level = 1, population = 1000,  -- GPS tile 388,146 is river
      names = { greek = "Akhaltsikhe", middle_eastern = "Akhaltsikhe", european = "Akhaltsikhe", default = "Akhaltsikhe" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kars", x = 389, y = 137, capital = "Ani", level = 2, population = 7500,
      names = { greek = "Kars", middle_eastern = "Kars", european = "Kars", default = "Kars" },
      rebels = { "Armenian Archers", "Armenian Archers" } },
    { key = "dvin", x = 399, y = 133, capital = "Ani", level = 2, population = 7500,  -- Shaddadids
      names = { greek = "Dvin", middle_eastern = "Dvin", european = "Dvin", default = "Dvin" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "nakhchivan", x = 402, y = 127, capital = "Ani", level = 2, population = 7500,  -- GPS tile 403,128 is river
      names = { greek = "Nakhchivan", middle_eastern = "Nakhchivan", european = "Nakhchivan", default = "Nakhchivan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ahlat", x = 380, y = 126, capital = "Erzurum", level = 2, population = 7500,  -- moved 13 Oct: low-mountain tile not reachable in game
      names = { greek = "Ahlat", middle_eastern = "Ahlat", european = "Ahlat", default = "Ahlat" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "manzikert", x = 383, y = 128, capital = "Erzurum", level = 2, population = 7500,
      names = { greek = "Malazgirt", middle_eastern = "Malazgirt", european = "Malazgirt", default = "Malazgirt" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "erzincan", x = 361, y = 135, capital = "Erzurum", level = 2, population = 7500,  -- moved 13 Oct: low-mountain tile not reachable in game
      names = { greek = "Erzincan", middle_eastern = "Erzincan", european = "Erzincan", default = "Erzincan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "bayburt", x = 366, y = 136, capital = "Erzurum", level = 2, population = 7500,  -- Saltukids
      names = { greek = "Bayburt", middle_eastern = "Bayburt", european = "Bayburt", default = "Bayburt" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "shamakhi", x = 425, y = 137, capital = "Baku", level = 2, population = 7500,  -- moved 13 Oct: low-mountain tile not reachable in game
      names = { greek = "Shamakhi", middle_eastern = "Shamakhi", european = "Shamakhi", default = "Shamakhi" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "shaki", x = 416, y = 140, capital = "Baku", level = 2, population = 7500,  -- GPS tile dense forest
      names = { greek = "Shaki", middle_eastern = "Shaki", european = "Shaki", default = "Shaki" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "barda", x = 416, y = 136, capital = "Baku", level = 2, population = 7500,
      names = { greek = "Barda", middle_eastern = "Barda", european = "Barda", default = "Barda" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "beylagan", x = 419, y = 132, capital = "Baku", level = 2, population = 7500,
      names = { greek = "Beylagan", middle_eastern = "Beylagan", european = "Beylagan", default = "Beylagan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    -- Upper Mesopotamia (13 Oct 2026): EU5 Amid / Mardin / Nusaybin + user-approved extras
    { key = "amid", x = 366, y = 119, capital = "Hasankeyf", level = 3, population = 15000,  -- EU5 city; Inalids
      names = { greek = "Ámida", middle_eastern = "Amid", european = "Amida", default = "Amid" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "mardin", x = 370, y = 115, capital = "Hasankeyf", level = 2, population = 7500,  -- EU5 town; Artuqid seat
      names = { greek = "Mardē", middle_eastern = "Mardin", european = "Mardin", default = "Mardin" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "mayyafariqin", x = 372, y = 121, capital = "Hasankeyf", level = 2, population = 7500,  -- Marwanid capital, Artuqid from 1118
      names = { greek = "Martyrópolis", middle_eastern = "Mayyafariqin", european = "Martyropolis", default = "Mayyafariqin" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tikrit", x = 391, y = 96, capital = "Mosul", ownerFrom = "Hasankeyf", level = 2, population = 7500,  -- Seljuk governor in 1132 -> starts rebel (user)
      names = { greek = "Tikrit", middle_eastern = "Tikrit", european = "Tikrit", default = "Tikrit" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kharput", x = 359, y = 124, capital = "Erzurum", level = 2, population = 7500,  -- Artuqid town (user)
      names = { greek = "Charpetē", middle_eastern = "Harput", european = "Harput", default = "Harput" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "nusaybin", x = 374, y = 113, capital = "Ar_Raqqah", level = 2, population = 7500,  -- EU5 city, level 2 (user)
      names = { greek = "Nísibis", middle_eastern = "Nusaybin", european = "Nisibis", default = "Nusaybin" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "harran", x = 358, y = 112, capital = "Ar_Raqqah", level = 2, population = 7500,
      names = { greek = "Kárrhai", middle_eastern = "Harran", european = "Carrhae", default = "Harran" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ras_ayn", x = 366, y = 112, capital = "Ar_Raqqah", level = 2, population = 7500,
      names = { greek = "Rhésaina", middle_eastern = "Ras al-Ayn", european = "Resaina", default = "Ras al-Ayn" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "samosata", x = 352, y = 117, capital = "Edessa", level = 2, population = 7500,  -- County of Edessa; moved 1 west off the river (user)
      names = { greek = "Samósata", middle_eastern = "Samsat", european = "Samosata", default = "Samsat" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tell_bashir", x = 351, y = 112, capital = "Edessa", level = 2, population = 7500,  -- County of Edessa
      names = { greek = "Telbésar", middle_eastern = "Tell Bashir", european = "Turbessel", default = "Tell Bashir" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "cizre", x = 381, y = 115, capital = "Mosul", level = 2, population = 7500,
      names = { greek = "Bezabdē", middle_eastern = "Cizre", european = "Bezabde", default = "Cizre" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sinjar", x = 379, y = 108, capital = "Mosul", level = 2, population = 7500,
      names = { greek = "Síngara", middle_eastern = "Sinjar", european = "Singara", default = "Sinjar" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "erbil", x = 393, y = 107, capital = "Mosul", level = 2, population = 7500,
      names = { greek = "Árbēla", middle_eastern = "Erbil", european = "Arbela", default = "Erbil" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "rahba", x = 369, y = 99, capital = "Mosul", level = 2, population = 7500,  -- Zengi's governor from 1127
      names = { greek = "Al-Rahba", middle_eastern = "Al-Rahba", european = "Rahaba", default = "Al-Rahba" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    -- Syria and the Levant (13 Oct 2026): no EU5 towns beyond SSHIP's own; user-approved extras, small ones skipped.
    -- arabic = name for egypt / abbasid / moors; middle_eastern = Turkish; default (rebels) = Arabic
    { key = "tartus", x = 337, y = 100, capital = "Tripoli", level = 2, population = 7500,  -- County of Tripoli; 1 north (user)
      names = { greek = "Antárados", middle_eastern = "Tartus", arabic = "Tartus", european = "Tortosa", default = "Tartus" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "beirut", x = 334, y = 91, capital = "Tripoli", level = 2, population = 7500,  -- Kingdom of Jerusalem; steep coast - route checked by DUMP
      names = { greek = "Bērytós", middle_eastern = "Beyrut", arabic = "Bayrut", european = "Baruth", default = "Bayrut" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tyre", x = 332, y = 86, capital = "Acre", level = 3, population = 15000,  -- Kingdom of Jerusalem since 1124; level 3 (user)
      names = { greek = "Týros", middle_eastern = "Sur", arabic = "Sur", european = "Tyrus", default = "Sur" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "jaffa", x = 328, y = 77, capital = "Jerusalem", level = 2, population = 7500,  -- Kingdom of Jerusalem
      names = { greek = "Ióppē", middle_eastern = "Yafa", arabic = "Yafa", european = "Joppe", default = "Yafa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "marash", x = 344, y = 115, capital = "Edessa", level = 2, population = 7500,  -- Lordship of Marash
      names = { greek = "Germaníkeia", middle_eastern = "Maraş", arabic = "Mar'ash", european = "Marasch", default = "Mar'ash" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ayntab", x = 347, y = 113, capital = "Edessa", level = 2, population = 7500,  -- County of Edessa
      names = { greek = "Doulíchē", middle_eastern = "Ayıntap", arabic = "'Ayntab", european = "Hatab", default = "'Ayntab" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "manbij", x = 351, y = 109, capital = "Aleppo", level = 2, population = 7500,  -- Zengids
      names = { greek = "Hierápolis", middle_eastern = "Menbiç", arabic = "Manbij", european = "Hierapolis", default = "Manbij" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "hama", x = 343, y = 100, capital = "Aleppo", level = 3, population = 15000,  -- Zengi since 1130; level 3 (user)
      names = { greek = "Epipháneia", middle_eastern = "Hama", arabic = "Hamah", european = "Hamah", default = "Hamah" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "homs", x = 342, y = 97, capital = "Damascus", level = 3, population = 15000,  -- emir Khirkhan -> rebels; level 3 (user)
      names = { greek = "Émesa", middle_eastern = "Humus", arabic = "Hims", european = "La Chamelle", default = "Hims" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "bosra", x = 341, y = 81, capital = "Damascus", level = 2, population = 7500,  -- Burids -> rebels
      names = { greek = "Bóstra", middle_eastern = "Busra", arabic = "Busra", european = "Bostrum", default = "Busra" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    -- North Africa, Egypt to Morocco (user, 13 Oct 2026): 32 towns; garrison Ahdath Militia everywhere (user)
    { key = "rosetta", x = 297, y = 71, capital = "Damietta", level = 2, population = 7500,  -- Fatimid Egypt
      names = { greek = "Bolbitínē", middle_eastern = "Reşid", arabic = "Rashid", european = "Rosetta", default = "Rashid" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "mahalla", x = 302, y = 68, capital = "Damietta", level = 2, population = 7500,  -- Fatimid Egypt
      names = { greek = "Mahallá", middle_eastern = "Mahalle-i Kübra", arabic = "al-Mahalla al-Kubra", european = "Mehalla", default = "al-Mahalla al-Kubra" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "faiyum", x = 298, y = 56, capital = "Cairo", level = 2, population = 7500,  -- moved (user, 13 Oct); Fatimid Egypt
      names = { greek = "Arsinóē", middle_eastern = "Feyyum", arabic = "al-Fayyum", european = "Fayum", default = "al-Fayyum" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "asyut", x = 301, y = 40, capital = "Cairo", level = 3, population = 15000,  -- moved (user, 13 Oct); EU5 city
      names = { greek = "Lykópolis", middle_eastern = "Asyut", arabic = "Asyut", european = "Lycopolis", default = "Asyut" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "aswan", x = 313, y = 18, capital = "Qus", level = 2, population = 7500,  -- Fatimid Egypt
      names = { greek = "Syḗnē", middle_eastern = "Asvan", arabic = "Aswan", european = "Syene", default = "Aswan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "barqa", x = 226, y = 79, capital = "Alexandria", ownerFrom = "Tarabulus", level = 2, population = 7500,  -- Alexandria region; Arab tribes in 1132 -> rebels (user)
      names = { greek = "Bárkē", middle_eastern = "Berka", arabic = "Barqa", european = "Barca", default = "Barqa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ajdabiya", x = 221, y = 66, capital = "Tarabulus", level = 2, population = 7500,  -- rebels
      names = { greek = "Ajdabiya", middle_eastern = "Ecdabiye", arabic = "Ajdabiya", european = "Agedabia", default = "Ajdabiya" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kairouan", x = 148, y = 102, capital = "Al-Mahdiya", level = 2, population = 7500,  -- moved (user, 13 Oct); EU5 town; Zirid lands -> rebels
      names = { greek = "Kairouán", middle_eastern = "Kayrevan", arabic = "al-Qayrawan", european = "Cairoan", default = "al-Qayrawan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sousse", x = 153, y = 103, capital = "Al-Mahdiya", level = 2, population = 7500,  -- rebels (user added)
      names = { greek = "Hadrýmēton", middle_eastern = "Sus", arabic = "Susa", european = "Susa", default = "Susa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sfax", x = 152, y = 94, capital = "Al-Mahdiya", level = 2, population = 7500,  -- moved (user, 13 Oct); rebels
      names = { greek = "Táphrouros", middle_eastern = "Sefakus", arabic = "Safaqus", european = "Sfax", default = "Safaqus" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "gabes", x = 149, y = 89, capital = "Al-Mahdiya", level = 2, population = 7500,  -- Banu Jami -> rebels
      names = { greek = "Tákapē", middle_eastern = "Kabis", arabic = "Qabis", european = "Capes", default = "Qabis" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "gafsa", x = 139, y = 93, capital = "Tunis", level = 2, population = 7500,  -- rebels
      names = { greek = "Kápsa", middle_eastern = "Kafsa", arabic = "Qafsa", european = "Capsa", default = "Qafsa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "bejaia", x = 114, y = 110, capital = "Algiers", level = 3, population = 15000,  -- EU5 city; Hammadid capital -> rebels
      names = { greek = "Saldaí", middle_eastern = "Bicaye", arabic = "Bijaya", european = "Bugia", default = "Bijaya" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "constantine", x = 125, y = 107, capital = "Algiers", level = 3, population = 15000,  -- EU5 city; Hammadids -> rebels
      names = { greek = "Kōnstantínē", middle_eastern = "Kostantine", arabic = "Qusantina", european = "Constantina", default = "Qusantina" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "annaba", x = 133, y = 111, capital = "Algiers", level = 3, population = 15000,  -- EU5 city; Hammadids -> rebels
      names = { greek = "Hippṓn", middle_eastern = "Annabe", arabic = "Buna", european = "Bona", default = "Buna" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "qala", x = 112, y = 102, capital = "Algiers", level = 2, population = 7500,  -- old Hammadid capital -> rebels
      names = { greek = "Qal'a", middle_eastern = "Kale-i Beni Hammad", arabic = "Qal'at Bani Hammad", european = "Kalaa", default = "Qal'at Bani Hammad" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "biskra", x = 118, y = 96, capital = "Algiers", level = 2, population = 7500,  -- rebels
      names = { greek = "Ouéskera", middle_eastern = "Biskara", arabic = "Biskra", european = "Vescera", default = "Biskra" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "oran", x = 72, y = 103, capital = "Tlemcen", level = 3, population = 15000,  -- EU5 city; Almoravids
      names = { greek = "Ouahrán", middle_eastern = "Vehran", arabic = "Wahran", european = "Orano", default = "Wahran" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tenes", x = 86, y = 108, capital = "Tlemcen", level = 2, population = 7500,  -- Almoravids
      names = { greek = "Kartennas", middle_eastern = "Tenes", arabic = "Tanas", european = "Tenez", default = "Tanas" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "cherchell", x = 93, y = 109, capital = "Tlemcen", level = 2, population = 7500,  -- EU5 town; Almoravids
      names = { greek = "Kaisáreia", middle_eastern = "Şerşel", arabic = "Sharshal", european = "Cesarea", default = "Sharshal" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tahert", x = 86, y = 100, capital = "Tlemcen", level = 2, population = 7500,  -- EU5 town; Almoravids
      names = { greek = "Tahert", middle_eastern = "Tihert", arabic = "Tahart", european = "Tiaret", default = "Tahart" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "meknes", x = 36, y = 91, capital = "Fes", level = 3, population = 15000,  -- EU5 city; Almoravids
      names = { greek = "Miknás", middle_eastern = "Miknas", arabic = "Miknasa", european = "Mequinez", default = "Miknasa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sale", x = 26, y = 89, capital = "Fes", level = 2, population = 7500,  -- for EU5 Rabat (founded 1150); Almoravids
      names = { greek = "Sála", middle_eastern = "Sela", arabic = "Sala", european = "Salé", default = "Sala" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "taza", x = 46, y = 93, capital = "Fes", level = 2, population = 7500,  -- EU5 town; Almoravids
      names = { greek = "Táza", middle_eastern = "Taza", arabic = "Taza", european = "Tazza", default = "Taza" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ceuta", x = 39, y = 103, capital = "Fes", level = 1, population = 1000,  -- 38,104 refused by the engine (strait crossing) -> 39,103; level 1 (user); Almoravids
      names = { greek = "Septon", middle_eastern = "Sebte", arabic = "Sabta", european = "Septa", default = "Sabta" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tangier", x = 35, y = 102, capital = "Fes", level = 2, population = 7500,  -- moved (user, 13 Oct); Almoravids (user added)
      names = { greek = "Tíngis", middle_eastern = "Tanca", arabic = "Tanja", european = "Tingis", default = "Tanja" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "azemmour", x = 16, y = 84, capital = "Marrakesh", level = 2, population = 7500,  -- EU5 town; Almoravids
      names = { greek = "Azamór", middle_eastern = "Azemmur", arabic = "Azammur", european = "Azamor", default = "Azammur" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "safi", x = 12, y = 77, capital = "Marrakesh", level = 2, population = 7500,  -- moved (user, 13 Oct); coast squeezed - 4 tiles inland; Almoravids
      names = { greek = "Saphí", middle_eastern = "Safi", arabic = "Asfi", european = "Saffi", default = "Asfi" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "taroudant", x = 10, y = 67, capital = "Marrakesh", level = 2, population = 7500,  -- for EU5 Tidsi (Sous); Almoravids
      names = { greek = "Taroudánt", middle_eastern = "Tarudant", arabic = "Tarudant", european = "Tarudant", default = "Tarudant" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "suez", x = 311, y = 62, capital = "Cairo", level = 1, population = 1000,  -- al-Qulzum; tier 1, 1 north (user)
      names = { greek = "Klýsma", middle_eastern = "Süveyş", arabic = "al-Qulzum", european = "Clisma", default = "al-Qulzum" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "melilla", x = 54, y = 99, capital = "Fes", level = 1, population = 1000,  -- Almoravids; tier 1 (user)
      names = { greek = "Rhyssádeiron", middle_eastern = "Melile", arabic = "Mliliya", european = "Melilla", default = "Mliliya" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    -- LOWER MESOPOTAMIA + PERSIA (13 Oct 2026): 34 towns after the user removed 10 (+ Gladzor in the Caucasus); doubtful ones level 1 (user), Hamadan / Alamut region towns Seljuk (user),
    -- big ones level 3 (user); Urmia moved to open ground (user); Lahijan added after map round 4 (Gilan coast opened)
    { key = "kufa", x = 399, y = 78, capital = "Baghdad", level = 3, population = 15000,  -- Abbasid; Mazyadid area
      names = { greek = "Koúfa", middle_eastern = "Kûfe", arabic = "al-Kufa", european = "Cufa", default = "al-Kufa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "hilla", x = 398, y = 82, capital = "Baghdad", level = 3, population = 15000,  -- Mazyadid capital (founded 1101)
      names = { greek = "Chílla", middle_eastern = "Hille", arabic = "al-Hilla", european = "Hilla", default = "al-Hilla" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "hulwan", x = 404, y = 95, capital = "Baghdad", level = 1, population = 1000,  -- in decline
      names = { greek = "Chála", middle_eastern = "Hulvan", arabic = "Hulwan", european = "Chala", default = "Hulwan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kirkuk", x = 395, y = 102, capital = "Mosul", level = 2, population = 7500,  -- Zengids
      names = { greek = "Karká", middle_eastern = "Kerkük", arabic = "Karkhini", european = "Carcha", default = "Karkhini" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ramhormoz", x = 434, y = 70, capital = "Basra", level = 2, population = 7500,
      names = { greek = "Ramormízd", middle_eastern = "Râmhürmüz", arabic = "Ramhurmuz", european = "Ramormuz", default = "Ramhormoz" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "arrajan", x = 438, y = 64, capital = "Basra", level = 1, population = 1000,  -- in decline
      names = { greek = "Arragán", middle_eastern = "Ercan", arabic = "Arrajan", european = "Argan", default = "Arrajan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "shushtar", x = 429, y = 77, capital = "Al_Wasit", level = 2, population = 7500,
      names = { greek = "Soústar", middle_eastern = "Şuşter", arabic = "Tustar", european = "Tostar", default = "Shushtar" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kermanshah", x = 415, y = 92, capital = "Hamadan", ownerFrom = "Isfahan", level = 3, population = 15000,  -- EU5 city; Seljuk (user)
      names = { greek = "Kirmasín", middle_eastern = "Kirmanşah", arabic = "Qirmisin", european = "Chermesin", default = "Kermanshah" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "nahavand", x = 421, y = 92, capital = "Hamadan", ownerFrom = "Isfahan", level = 2, population = 7500,  -- Seljuk (user)
      names = { greek = "Laodíkeia", middle_eastern = "Nihavend", arabic = "Nihawand", european = "Laodicea", default = "Nahavand" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "borujerd", x = 430, y = 91, capital = "Hamadan", ownerFrom = "Isfahan", level = 2, population = 7500,  -- Seljuk (user)
      names = { greek = "Bouroutzérd", middle_eastern = "Burucird", arabic = "Burujird", european = "Borugerd", default = "Borujerd" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "qom", x = 444, y = 96, capital = "Ray", level = 3, population = 15000,  -- EU5 city
      names = { greek = "Koúm", middle_eastern = "Kum", arabic = "Qumm", european = "Com", default = "Qom" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "jurjan", x = 472, y = 114, capital = "Ray", level = 3, population = 15000,  -- big city (user: level 3)
      names = { greek = "Gourgán", middle_eastern = "Cürcan", arabic = "Jurjan", european = "Hyrcania", default = "Gorgan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "damghan", x = 468, y = 105, capital = "Ray", level = 2, population = 7500,
      names = { greek = "Hekatómpylos", middle_eastern = "Damgan", arabic = "Damghan", european = "Hecatompylos", default = "Damghan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "semnan", x = 463, y = 99, capital = "Ray", level = 2, population = 7500,
      names = { greek = "Semnán", middle_eastern = "Simnan", arabic = "Simnan", european = "Semnan", default = "Semnan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kashan", x = 449, y = 91, capital = "Yazd", level = 2, population = 7500,
      names = { greek = "Kasán", middle_eastern = "Kâşan", arabic = "Qashan", european = "Cascian", default = "Kashan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "qazvin", x = 436, y = 105, capital = "Alamut", ownerFrom = "Ray", level = 2, population = 7500,  -- Seljuk (user)
      names = { greek = "Kasbín", middle_eastern = "Kazvin", arabic = "Qazwin", european = "Casvin", default = "Qazvin" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "zanjan", x = 427, y = 109, capital = "Alamut", ownerFrom = "Ray", level = 2, population = 7500,  -- Seljuk (user)
      names = { greek = "Zantzán", middle_eastern = "Zencan", arabic = "Zanjan", european = "Zengian", default = "Zanjan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "lahijan", x = 434, y = 115, capital = "Alamut", level = 2, population = 7500,  -- Gilan, rebels; coast opened from both sides (map round 4, user)
      names = { greek = "Lachitzán", middle_eastern = "Lâhican", arabic = "Lahijan", european = "Lahigian", default = "Lahijan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "maragheh", x = 410, y = 111, capital = "Tabriz", level = 3, population = 15000,  -- Ahmadilis, rebels; level 3 (user)
      names = { greek = "Marágha", middle_eastern = "Merâga", arabic = "al-Maragha", european = "Maraga", default = "Maragheh" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "khoy", x = 403, y = 124, capital = "Tabriz", level = 2, population = 7500,  -- rebels
      names = { greek = "Choḯ", middle_eastern = "Hoy", arabic = "Khuway", european = "Coy", default = "Khoy" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "miyaneh", x = 416, y = 115, capital = "Tabriz", level = 2, population = 7500,  -- rebels
      names = { greek = "Miáne", middle_eastern = "Miyane", arabic = "Mayanij", european = "Miana", default = "Miyaneh" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "ardabil", x = 428, y = 126, capital = "Tabriz", level = 3, population = 15000,  -- rebels; 4-5 tiles NE of the real spot; level 3 (user)
      names = { greek = "Artabíl", middle_eastern = "Erdebil", arabic = "Ardabil", european = "Ardevil", default = "Ardabil" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "urmia", x = 396, y = 118, capital = "Tabriz", level = 2, population = 7500,  -- rebels; moved ~6 tiles W (lake shore is low mountain), user ok
      names = { greek = "Ourmía", middle_eastern = "Urmiye", arabic = "Urmiya", european = "Urmia", default = "Urmia" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sabzevar", x = 489, y = 111, capital = "Neyshabur", level = 2, population = 7500,  -- Bayhaq
      names = { greek = "Sabzabár", middle_eastern = "Sebzevar", arabic = "Sabzawar", european = "Sabzevar", default = "Sabzevar" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "turshiz", x = 495, y = 98, capital = "Neyshabur", level = 2, population = 7500,
      names = { greek = "Tourshíz", middle_eastern = "Türşiz", arabic = "Turaythith", european = "Tursiz", default = "Turshiz" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "qaen", x = 498, y = 87, capital = "Neyshabur", level = 2, population = 7500,
      names = { greek = "Kaín", middle_eastern = "Kayin", arabic = "Qa'in", european = "Cain", default = "Qaen" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "tabas", x = 490, y = 92, capital = "Neyshabur", level = 2, population = 7500,
      names = { greek = "Tabás", middle_eastern = "Tabes", arabic = "Tabas", european = "Tabas", default = "Tabas" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "fasa", x = 468, y = 51, capital = "Shiraz", level = 2, population = 7500,
      names = { greek = "Fása", middle_eastern = "Fesa", arabic = "Fasa", european = "Fasa", default = "Fasa" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "firuzabad", x = 459, y = 49, capital = "Shiraz", level = 2, population = 7500,
      names = { greek = "Gór", middle_eastern = "Firuzâbâd", arabic = "Jur", european = "Gor", default = "Firuzabad" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "abarkuh", x = 463, y = 70, capital = "Shiraz", level = 2, population = 7500,
      names = { greek = "Abarkoúh", middle_eastern = "Ebergûh", arabic = "Abarquh", european = "Abarcu", default = "Abarkuh" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sirjan", x = 475, y = 61, capital = "Shiraz", level = 2, population = 7500,
      names = { greek = "Sirtzán", middle_eastern = "Sircan", arabic = "al-Sirjan", european = "Sirgian", default = "Sirjan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "hormuz", x = 488, y = 41, capital = "Kerman", level = 3, population = 15000,  -- EU5 city (old Hormuz, mainland); Kerman Seljuks = rebels
      names = { greek = "Harmózeia", middle_eastern = "Hürmüz", arabic = "Hurmuz", european = "Ormus", default = "Hormuz" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "bam", x = 501, y = 55, capital = "Kerman", level = 2, population = 7500,  -- rebels
      names = { greek = "Bám", middle_eastern = "Bem", arabic = "Bam", european = "Bam", default = "Bam" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "jiroft", x = 493, y = 48, capital = "Kerman", level = 2, population = 7500,  -- rebels; west bank of the river
      names = { greek = "Tziróft", middle_eastern = "Cîruft", arabic = "Jiruft", european = "Camadi", default = "Jiroft" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    -- ARABIA, STEPPE, VOLGA (14 Oct 2026, user: all proposed + optional ones; towns founded after 1132 = level 1 / 500)
    { key = "medina", x = 365, y = 23, capital = "Mecca", level = 2, population = 7500,  -- EU5 town; Egypt
      names = { greek = "Iathrippa", middle_eastern = "Medine", arabic = "al-Madina", european = "Medina", default = "al-Madina" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "jeddah", x = 358, y = 5, capital = "Mecca", level = 2, population = 7500,  -- EU5 town, Mecca's port, map edge
      names = { greek = "Tzidda", middle_eastern = "Cidde", arabic = "Judda", european = "Gedda", default = "Judda" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "muscat", x = 496, y = 13, capital = "Al_Ahsa", level = 2, population = 7500,  -- Oman port (user, 14 Oct); coast is mountains on SSHIP's map, so 3-4 tiles inland; rebels
      names = { greek = "Moskha", middle_eastern = "Maskat", arabic = "Masqat", european = "Mascate", default = "Masqat" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "qatif", x = 435, y = 37, capital = "Al_Ahsa", level = 2, population = 7500,  -- EU5 town; rebels
      names = { greek = "Katif", middle_eastern = "Katif", arabic = "al-Qatif", european = "Catif", default = "al-Qatif" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sudak", x = 329, y = 170, capital = "Chersonesos", level = 2, population = 7500,  -- EU5 town; Byzantium
      names = { greek = "Sougdaía", middle_eastern = "Suğdak", arabic = "Sudaq", european = "Soldaia", default = "Sougdaía" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "kerch", x = 336, y = 171, capital = "Chersonesos", level = 2, population = 7500,  -- EU5 town; 3 tiles from the strait (Ceuta lesson)
      names = { greek = "Bósporos", middle_eastern = "Kerç", arabic = "Karsh", european = "Vosporo", default = "Bósporos" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "kursk", x = 338, y = 218, capital = "Chernigov", ownerFrom = "Aktobe", level = 2, population = 7500,  -- EU5 town; Cumans (user, 14 Oct)
      names = { greek = "Koúrsk", middle_eastern = "Kursk", arabic = "Kursk", european = "Kursk", default = "Kursk" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "bilyar", x = 442, y = 241, capital = "Bulgar", level = 3, population = 15000,  -- largest Volga Bulgar city; rebels
      names = { greek = "Bilár", middle_eastern = "Bilär", arabic = "Bilyar", european = "Biliar", default = "Bilär" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "kazan", x = 434, y = 247, capital = "Bulgar", level = 1, population = 1000,  -- EU5 town, founding disputed; rebels
      names = { greek = "Kazán", middle_eastern = "Kazan", arabic = "Qazan", european = "Casan", default = "Qazan" },
      rebels = { "Ahdath Militia", "Ahdath Militia" } },
    { key = "sarai", x = 407, y = 195, capital = "Saqsin", ownerFrom = "Aktobe", level = 1, population = 500,  -- 1330s - founded later; Cumans (user, 14 Oct; Saqsin itself moved to the Cumans in descr_strat)
      names = { greek = "Sarái", middle_eastern = "Saray-ı Cedid", arabic = "Saray al-Jadid", european = "Sarai", default = "Saray al-Jadid" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    -- Russia / Rus' (user, 14 Oct 2026): Russian names for Novgorod, Kievan Rus and rebels, Polish for Poland,
    -- Lithuanian for Lithuania, Latin for other Europeans, Greek, Turkish. Garrison EE Spear Militia.
    { key = "tver", x = 335, y = 255, capital = "Novgorod", level = 1, population = 500,  -- EU5 city, founded c. 1135
      names = { russia = "Tver'", kievan_rus = "Tver'", poland = "Twer", lithuania = "Tverė", european = "Tveria", greek = "Tvéri", middle_eastern = "Tver", default = "Tver'" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "moscow", x = 347, y = 248, capital = "Rustov", ownerFrom = "Suzdal", level = 1, population = 500,  -- EU5 city, first mentioned 1147; stays Kievan Rus (user, 14 Oct)
      names = { russia = "Moskva", kievan_rus = "Moskva", poland = "Moskwa", lithuania = "Maskva", european = "Moscovia", greek = "Moschóbion", middle_eastern = "Moskova", default = "Moskva" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "vologda", x = 358, y = 271, capital = "Rustov", level = 1, population = 500,  -- EU5 town, first mentioned 1147
      names = { russia = "Vologda", kievan_rus = "Vologda", poland = "Wołogda", lithuania = "Vologda", european = "Vologda", greek = "Vológda", middle_eastern = "Vologda", default = "Vologda" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "beloozero", x = 343, y = 278, capital = "Rustov", level = 2, population = 7500,  -- existed 1132
      names = { russia = "Beloozero", kievan_rus = "Beloozero", poland = "Białe Jezioro", lithuania = "Baltežeris", european = "Bieloosero", greek = "Belóozero", middle_eastern = "Akgöl", default = "Beloozero" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "murom", x = 379, y = 247, capital = "Suzdal", level = 2, population = 7500,  -- existed 1132
      names = { russia = "Murom", kievan_rus = "Murom", poland = "Murom", lithuania = "Muromas", european = "Muroma", greek = "Moúrom", middle_eastern = "Murom", default = "Murom" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "nizhny", x = 392, y = 253, capital = "Ryazan", level = 1, population = 500,  -- EU5 town, founded 1221; rebels
      names = { russia = "Nizhnii Novgorod", kievan_rus = "Nizhnii Novgorod", poland = "Niżny Nowogród", lithuania = "Žemutinis Naugardas", european = "Novogardia Inferior", greek = "Kato Nóvgorod", middle_eastern = "Aşağı Novgorod", default = "Nizhnii Novgorod" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "pronsk", x = 367, y = 237, capital = "Ryazan", level = 1, population = 1000,  -- first mentioned 1131; rebels
      names = { russia = "Pronsk", kievan_rus = "Pronsk", poland = "Prońsk", lithuania = "Pronskas", european = "Pronscum", greek = "Prónsk", middle_eastern = "Pronsk", default = "Pronsk" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "minsk", x = 275, y = 234, capital = "Polotsk", level = 2, population = 7500,  -- EU5 town; rebels
      names = { russia = "Menesk", kievan_rus = "Menesk", poland = "Mińsk", lithuania = "Minskas", european = "Minsca", greek = "Mínsk", middle_eastern = "Minsk", default = "Menesk" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "vitebsk", x = 295, y = 242, capital = "Polotsk", level = 2, population = 7500,  -- existed 1132; rebels
      names = { russia = "Vitebsk", kievan_rus = "Vitebsk", poland = "Witebsk", lithuania = "Vitebskas", european = "Vitebscum", greek = "Vítebsk", middle_eastern = "Vitebsk", default = "Vitebsk" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "brest", x = 250, y = 221, capital = "Goroden", level = 2, population = 7500,  -- Berestye, existed 1132; rebels
      names = { russia = "Berest'e", kievan_rus = "Berest'e", poland = "Brześć", lithuania = "Brastas", european = "Bresta", greek = "Berestíe", middle_eastern = "Brest", default = "Berest'e" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "lutsk", x = 262, y = 212, capital = "Volodymyr", level = 2, population = 7500,  -- existed 1132
      names = { russia = "Luchesk", kievan_rus = "Luchesk", poland = "Łuck", lithuania = "Luckas", european = "Luceoria", greek = "Loútsk", middle_eastern = "Lutsk", default = "Luchesk" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "lviv", x = 255, y = 206, capital = "Volodymyr", level = 1, population = 500,  -- EU5 town, founded c. 1250
      names = { russia = "L'vov", kievan_rus = "L'vov", poland = "Lwów", lithuania = "Lvovas", european = "Leopolis", greek = "Leontópolis", middle_eastern = "İlbav", default = "L'vov" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "przemysl", x = 245, y = 205, capital = "Halych", level = 2, population = 7500,  -- existed 1132; rebels
      names = { russia = "Peremyshl'", kievan_rus = "Peremyshl'", poland = "Przemyśl", lithuania = "Pšemislis", european = "Premislia", greek = "Peremýsl", middle_eastern = "Peremişl", default = "Peremyshl'" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "starodub", x = 317, y = 225, capital = "Chernigov", level = 2, population = 7500,  -- existed 1132; rebels
      names = { russia = "Starodub", kievan_rus = "Starodub", poland = "Starodub", lithuania = "Starodubas", european = "Starodubum", greek = "Starodoúb", middle_eastern = "Starodub", default = "Starodub" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "toropets", x = 305, y = 252, capital = "Smolensk", level = 1, population = 1000,  -- first mention disputed (doubtful)
      names = { russia = "Toropets", kievan_rus = "Toropets", poland = "Toropiec", lithuania = "Toropecas", european = "Toropecia", greek = "Torópets", middle_eastern = "Toropets", default = "Toropets" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    -- BALKANS + GREECE (user, 14 Oct 2026): EU5 1337 towns + extras that existed in 1132. Tiles by docs/tools/place.py.
    -- SSHIP's own "Nis" stands on Belgrade's site (SSHIP already shows it as Belograd); the real Nis is hxstart_nis.
    -- Rhodes is a castle (user). Levels: Athens / Thebes 3, Branicevo 1 (bishopric fortress), the rest 2.
    { key = "athens", x = 248, y = 120, capital = "Corinth", level = 3, population = 15000,
      names = { greek = "Athēnai", european = "Athenae", middle_eastern = "Atina", serbia = "Atina", hungary = "Athén", default = "Athēnai" } },
    { key = "thebes", x = 245, y = 121, capital = "Corinth", level = 3, population = 15000,
      names = { greek = "Thēbai", european = "Thebae", middle_eastern = "İstife", serbia = "Teba", hungary = "Théba", default = "Thēbai" } },
    { key = "patras", x = 233, y = 120, capital = "Corinth", level = 2, population = 7500,
      names = { greek = "Patrai", european = "Patrae", middle_eastern = "Ballibadra", serbia = "Patras", hungary = "Patrasz", default = "Patrai" } },
    { key = "kalamata", x = 235, y = 113, capital = "Corinth", level = 2, population = 7500,
      names = { greek = "Kalamai", european = "Calamata", middle_eastern = "Kalamata", serbia = "Kalamata", hungary = "Kalamata", default = "Kalamai" } },
    { key = "monemvasia", x = 241, y = 112, capital = "Corinth", level = 2, population = 7500,
      names = { greek = "Monembasia", european = "Malvasia", middle_eastern = "Menekşe", serbia = "Monemvasija", hungary = "Monemvaszia", default = "Monembasia" } },
    { key = "larissa", x = 239, y = 132, capital = "Thessalonica", level = 2, population = 7500,
      names = { greek = "Larissa", european = "Larissa", middle_eastern = "Yenişehir", serbia = "Larisa", hungary = "Larissza", default = "Larissa" } },
    { key = "ohrid", x = 230, y = 145, capital = "Thessalonica", level = 2, population = 7500,
      names = { greek = "Achris", european = "Ochrida", middle_eastern = "Ohri", serbia = "Ohrid", hungary = "Ohrid", default = "Ohrid" } },
    { key = "serres", x = 248, y = 141, capital = "Thessalonica", level = 2, population = 7500,
      names = { greek = "Serrai", european = "Serrae", middle_eastern = "Siroz", serbia = "Ser", hungary = "Szérrész", default = "Serrai" } },
    { key = "ioannina", x = 225, y = 132, capital = "Arta", level = 2, population = 7500,
      names = { greek = "Iōannina", european = "Ioannina", middle_eastern = "Yanya", serbia = "Janjina", hungary = "Janina", default = "Iōannina" } },
    { key = "valona", x = 219, y = 137, capital = "Durazzo", level = 2, population = 7500,
      names = { greek = "Aulōn", european = "Avlona", middle_eastern = "Avlonya", serbia = "Valona", hungary = "Valona", default = "Aulōn" } },
    { key = "skopje", x = 233, y = 148, capital = "Ras", level = 2, population = 7500,
      names = { greek = "Skopia", european = "Scupi", middle_eastern = "Üsküp", serbia = "Skoplje", hungary = "Szkopje", default = "Skoplje" } },
    { key = "nis", x = 237, y = 156, capital = "Sredets", level = 2, population = 7500,
      names = { greek = "Naïssos", european = "Naissus", middle_eastern = "Niş", serbia = "Niš", hungary = "Nis", default = "Niš" } },
    { key = "plovdiv", x = 256, y = 150, capital = "Sredets", level = 2, population = 7500,
      names = { greek = "Philippoupolis", european = "Philippopolis", middle_eastern = "Filibe", serbia = "Plovdiv", hungary = "Filippopol", default = "Plovdiv" } },
    { key = "branicevo", x = 235, y = 166, capital = "Nis", level = 1, population = 1000, rebels = { "Spear Militia", "Spear Militia" },
      names = { greek = "Branitzova", european = "Branicevum", middle_eastern = "Braniçevo", serbia = "Braničevo", hungary = "Barancs", default = "Braničevo" } },
    { key = "vidin", x = 244, y = 161, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Bidinē", european = "Bononia", middle_eastern = "Vidin", serbia = "Bdin", hungary = "Bodony", default = "Bdin" } },
    { key = "cherven", x = 265, y = 160, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Tzerbenon", european = "Cerven", middle_eastern = "Çerven", serbia = "Červen", hungary = "Cserven", default = "Červen" } },
    { key = "drastar", x = 274, y = 163, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Dristra", european = "Durostorum", middle_eastern = "Silistre", serbia = "Drastar", hungary = "Szilisztra", default = "Drastar" } },
    { key = "shumen", x = 271, y = 157, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Soumen", european = "Sumen", middle_eastern = "Şumnu", serbia = "Šumen", hungary = "Sumen", default = "Šumen" } },
    { key = "varna", x = 277, y = 157, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Barna", european = "Varna", middle_eastern = "Varna", serbia = "Varna", hungary = "Várna", default = "Varna" } },
    { key = "sliven", x = 267, y = 153, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Stilbnos", european = "Stilbnum", middle_eastern = "İslimye", serbia = "Sliven", hungary = "Szliven", default = "Sliven" } },
    { key = "anchialos", x = 274, y = 152, capital = "Tarnovo", level = 2, population = 7500,
      names = { greek = "Anchialos", european = "Anchialus", middle_eastern = "Ahyolu", serbia = "Anhialo", hungary = "Ankhialosz", default = "Anchialos" } },
    { key = "gallipoli", x = 270, y = 135, capital = "Adrianople", level = 2, population = 7500,
      names = { greek = "Kallipolis", european = "Callipolis", middle_eastern = "Gelibolu", serbia = "Galipolj", hungary = "Gallipoli", default = "Kallipolis" } },
    { key = "mosynopolis", x = 260, y = 142, capital = "Adrianople", level = 2, population = 7500,
      names = { greek = "Mosynopolis", european = "Mosynopolis", middle_eastern = "Gümülcine", serbia = "Mosinopolj", hungary = "Moszinopolisz", default = "Mosynopolis" } },
    { key = "kotor", x = 213, y = 152, capital = "Skadar", level = 2, population = 7500, rebels = { "Spear Militia", "Spear Militia" },
      names = { greek = "Dekatera", european = "Catarum", middle_eastern = "Kotor", serbia = "Kotor", hungary = "Kotor", default = "Kotor" } },
    { key = "rhodes", x = 278, y = 106, capital = "Smyrna", level = 2, population = 7500, castle = true,
      names = { greek = "Rhodos", european = "Rhodus", middle_eastern = "Rodos", serbia = "Rodos", hungary = "Rodosz", default = "Rhodos" } },
}

-- starting garrison by owner faction (user, 13 Oct 2026); rebels use the entry's own list
local GARRISON = {
    byzantium = { "Contaratoi", "Contaratoi" },
    rum       = { "Ahdath Militia", "Ahdath Militia" },
    georgia   = { "georgian light spearmen", "georgian light spearmen" },   -- cheapest local (user, 13 Oct)
    zengid    = { "Shurtah Militia", "Shurtah Militia" },     -- cheapest militia (user, 13 Oct)
    jerusalem = { "Spear Militia", "Spear Militia" },         -- user, 13 Oct
    egypt     = { "Ahdath Militia", "Ahdath Militia" },       -- North Africa (user, 13 Oct)
    moors     = { "Ahdath Militia", "Ahdath Militia" },       -- North Africa (user, 13 Oct)
    turks     = { "Ahdath Militia", "Ahdath Militia" },       -- Persia: cheapest militia (13 Oct)
    abbasid   = { "Shurtah Militia", "Shurtah Militia" },     -- Iraq: cheapest militia (13 Oct)
    cumans    = { "EE Spear Militia", "EE Spear Militia" },   -- steppe: cheapest militia (14 Oct)
    russia    = { "EE Spear Militia", "EE Spear Militia" },   -- Rus: cheapest militia (14 Oct)
    kievan_rus = { "EE Spear Militia", "EE Spear Militia" },  -- Rus: cheapest militia (14 Oct)
    serbia    = { "Spear Militia", "Spear Militia" },          -- Balkans: cheapest militia (14 Oct)
}

local CORE_LEVEL = { [1] = "wooden_pallisade", [2] = "wooden_wall", [3] = "stone_wall",
                     [4] = "large_stone_wall", [5] = "huge_stone_wall" }
-- castles (entry field castle = true; Rhodes, user 14 Oct 2026)
local CORE_CASTLE = { [1] = "motte_and_bailey", [2] = "wooden_castle", [3] = "castle", [4] = "fortress", [5] = "citadel" }

-- Starter buildings per settlement level (user, 13 Oct 2026): SSHIP's chains hang on roads -> builders1 (temples,
-- water, port, town hall, mines ...), farms2 needs builders1. A settlement added by script starts with walls only,
-- and the player of an EXTRA settlement could not build farms or roads in the test (EUR has its own minor_farms /
-- minor_roads chains for that reason). { chain, level } - a chain that is already there is left alone.
local STARTER = {
    [1] = { { "hinterland_roads", "roads" }, { "hinterland_farms", "farms1" }, { "builders", "builders1" } },
    [2] = { { "hinterland_roads", "roads" }, { "hinterland_farms", "farms1" }, { "builders", "builders1" },
            { "water_supply", "water1_wells" } },
    [3] = { { "hinterland_roads", "roads" }, { "hinterland_farms", "farms2" }, { "builders", "builders2" },
            { "water_supply", "water1_wells" } },
}
-- Hinterland chains (roads, farms, mines): the build menu of an EXTRA settlement hides chains with
-- edbEntry.isHinterland = 1. Experiment A (flag 0 for the whole game) made them buildable but the map road
-- Nicaea - Prousa - Smyrna disappeared (user, 13 Oct 2026). So the flag is now 0 ONLY while the player has an
-- extra settlement selected (its build menu is open) and back to its original value otherwise.
-- AI-held extra settlements therefore cannot build these chains (they keep the starter buildings).
local UNHINTERLAND = true
local UNHINTERLAND_CHAINS = { "hinterland_roads", "hinterland_farms", "hinterland_mines", "hinterland_castle_roads" }
-- TEMPORARY check (13 Oct 2026): what the game lets these settlements build next. Logged once per map load.
local CHECK_SETTS  = {}   -- was { "hxstart_bursa", "Nicaea" }: check done (13 Oct 2026), switched off
local CHECK_CHAINS = { "hinterland_roads", "hinterland_farms", "builders", "water_supply", "hinterland_mines",
                       "temple_orthodox", "market", "city_hall", "port", "barracks", "landowners" }
local EUROPEAN = { northern_european = true, southern_european = true, eastern_european = true }
local ARABIC = { egypt = true, abbasid = true, moors = true }   -- Arab dynasties get the arabic name (user, 13 Oct 2026)

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("STARTSETT " .. tostring(text))
    end
end

-- a wrong field name must never crash the game
local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function settlementByName(name)
    local campaign = get(M2TW, "campaign")
    local ok, sett = pcall(function() return campaign:getSettlementByName(name) end)
    if ok then return sett end
    return nil
end

local function cultureOf(faction)
    local ok, name = pcall(function() return M2TWEOP.getCultureName(faction.cultureID) end)
    if ok and type(name) == "string" then return name end
    return nil
end

-- the name an owner should show, or nil (rebels and unknown cultures keep the current name)
local function nameFor(entry, faction)
    local fname = get(faction, "name")
    if fname == nil then return nil end
    if fname == "slave" then return entry.names.default end
    if entry.names[fname] then return entry.names[fname] end
    if ARABIC[fname] and entry.names.arabic then return entry.names.arabic end
    local culture = cultureOf(faction)
    if culture == nil then return nil end
    if entry.names[culture] then return entry.names[culture] end
    if EUROPEAN[culture] then return entry.names.european end
    return nil
end

local function applyName(entry, sett, why)
    local wanted = nameFor(entry, get(sett, "ownerFaction"))
    if wanted == nil or get(sett, "localizedName") == wanted then return end
    local ok = pcall(function() sett.localizedName = wanted end)
    log("name " .. tostring(get(sett, "name")) .. " -> " .. wanted .. " (" .. tostring(why) .. ", owner "
        .. tostring(get(get(sett, "ownerFaction"), "name")) .. "): " .. tostring(ok))
end

function SS.refreshNames(why)
    for i = 1, #SETTS do
        local sett = settlementByName("hxstart_" .. SETTS[i].key)
        if sett ~= nil then applyName(SETTS[i], sett, why) end
    end
end

-- adds the starter buildings of the entry's level that are missing (never touches a chain that exists)
local function giveStarter(entry, sett, why)
    local list = STARTER[entry.level]
    if list == nil then return end
    if entry.castle then   -- castles have their own roads chain (hinterland_castle_roads, first level c_roads)
        local castleList = {}
        for i = 1, #list do
            if list[i][1] == "hinterland_roads" then castleList[i] = { "hinterland_castle_roads", "c_roads" }
            else castleList[i] = list[i] end
        end
        list = castleList
    end
    local done = {}
    for i = 1, #list do
        local chain, level = list[i][1], list[i][2]
        local okHas, has = pcall(function() return sett:buildingPresent(chain) end)
        if not (okHas and has) then
            local okB, errB = pcall(function() sett:createBuilding(level) end)
            local okNow, now = pcall(function() return sett:buildingPresent(chain) end)
            done[#done + 1] = level .. " " .. ((okB and okNow and now) and "ok" or ("FAILED " .. tostring(errB)))
        end
    end
    if #done > 0 then
        log("starter buildings " .. tostring(get(sett, "name")) .. " (" .. tostring(why) .. "): " .. table.concat(done, ", "))
    end
end

-- TEMPORARY: logs the buildings and, per chain, which levels the game would let the settlement build
local function checkBuildable(name)
    local sett = settlementByName(name)
    if sett == nil then return end
    local have = {}
    local n = get(sett, "buildingsNum") or 0
    for i = 0, n - 1 do
        local okB, b = pcall(function() return sett:getBuilding(i) end)
        if okB and b ~= nil then
            local okT, t = pcall(function() return b:getType() end)
            local okN, nm = pcall(function() return b:getName() end)
            have[#have + 1] = tostring(okT and t) .. "/" .. tostring(okN and nm)
        end
    end
    log("CHECK " .. name .. " (minor " .. tostring(get(sett, "isMinorSettlement")) .. ", level " .. tostring(get(sett, "level"))
        .. ") has: " .. table.concat(have, ", "))
    for i = 1, #CHECK_CHAINS do
        local chain = CHECK_CHAINS[i]
        local okE, e = pcall(function() return EDB.getBuildingByName(chain) end)
        if okE and e ~= nil then
            local count = get(e, "buildingLevelCount") or 0
            local res = {}
            for lv = 0, count - 1 do
                local okC, can = pcall(function() return sett:canConstructBuilding(e, lv) end)
                res[#res + 1] = lv .. "=" .. (okC and tostring(can) or "err")
            end
            log("CHECK " .. name .. " " .. chain .. " (hinterland " .. tostring(get(e, "isHinterland")) .. ", farm "
                .. tostring(get(e, "isFarm")) .. "): " .. table.concat(res, " "))
        else
            log("CHECK " .. chain .. ": no EDB entry")
        end
    end
end

local flagEntries = nil     -- { entry, original value } read once per game session
local flagsCleared = false

local function hinterlandEntries()
    if flagEntries ~= nil then return flagEntries end
    flagEntries = {}
    for i = 1, #UNHINTERLAND_CHAINS do
        local okE, e = pcall(function() return EDB.getBuildingByName(UNHINTERLAND_CHAINS[i]) end)
        if okE and e ~= nil then
            local v = get(e, "isHinterland")
            if v == 0 then v = 1 end    -- a save loaded after the old experiment: the chains are hinterland chains
            flagEntries[#flagEntries + 1] = { entry = e, value = v, chain = UNHINTERLAND_CHAINS[i] }
        end
    end
    return flagEntries
end

-- clear = true: flag 0 (extra settlement selected); false: original value. Only written when it changes.
function SS.setHinterlandFlags(clear, why)
    if not UNHINTERLAND then return end
    local list = hinterlandEntries()
    local res = {}
    for i = 1, #list do
        local want = clear and 0 or list[i].value
        if get(list[i].entry, "isHinterland") ~= want then
            local ok = pcall(function() list[i].entry.isHinterland = want end)
            res[#res + 1] = list[i].chain .. "=" .. want .. (ok and "" or " FAILED")
        end
    end
    flagsCleared = clear
    if #res > 0 and why ~= "selection" then log("hinterland flags (" .. tostring(why) .. "): " .. table.concat(res, ", ")) end
end

-- called every frame: is an extra settlement of the player selected?
local function extraSelected()
    local sett = get(get(M2TW, "selectionInfo"), "selectedSettlement")
    if sett == nil then return false end
    local minor = get(sett, "isMinorSettlement")
    if not (minor == true or minor == 1) then return false end
    return get(get(sett, "ownerFaction"), "isPlayerControlled") == 1
end

function SS.draw()
    local want = extraSelected()
    if want ~= flagsCleared then
        SS.setHinterlandFlags(want, "selection")
        if not SS.selectionLogged then
            SS.selectionLogged = true
            log("hinterland flags follow the selection (first switch: " .. tostring(want) .. ")")
        end
    end
end

-------------------------------------------------------------------------
-- TEMPORARY terrain dump (13 Oct 2026): what the ENGINE blocks. Logged once per game session at map load.
-------------------------------------------------------------------------
local DUMP = true
local DUMP_BOXES = {}   -- Anatolia boxes done; Caucasus and Upper Mesopotamia needed no map edit
local DUMP_PATHS = {    -- Balkans + Lycian coast (14 Oct 2026)
    { "Milas-Attaleia coast", 276, 116, 297, 114 }, { "Corinth-Monemvasia", 242, 118, 241, 112 }, { "Corinth-Patras", 242, 118, 233, 120 },
    { "Ras-Skopje", 231, 153, 233, 148 }, { "Sredets-Nis", 247, 152, 237, 156 }, { "Nis(Belgrade)-Branicevo", 228, 168, 235, 166 },
    { "Tarnovo-Drastar", 262, 156, 274, 163 }, { "Skadar-Kotor", 218, 149, 213, 152 }, { "Durazzo-Valona", 218, 142, 219, 137 },
    { "Thessalonica-Ohrid", 243, 139, 230, 145 }, { "Arta-Ioannina", 228, 128, 225, 132 },
}
local GROUND_LETTER = { [0]="0", "1", "2", "w", "M", "L", "h", "D", "s", "S", "~", "~", "~", "c", "#", "~" }
local dumped = false

function SS.dumpTerrain()
    if not DUMP or dumped then return end
    dumped = true
    local costs = {}
    for gt = 0, 15 do
        local ok, c = pcall(function() return M2TWEOP.getGroundTypeMoveCost(gt) end)
        costs[#costs + 1] = gt .. "=" .. tostring(ok and c)
    end
    log("DUMP move costs: " .. table.concat(costs, " "))
    for b = 1, #DUMP_BOXES do
        local name, x0, x1, y0, y1 = unpack(DUMP_BOXES[b])
        log("DUMP box " .. name .. " x " .. x0 .. "-" .. x1 .. " (ground letter, then ! = cliff, r = river, H = height/10)")
        for y = y1, y0, -1 do
            local g, h = {}, {}
            for x = x0, x1 do
                local okT, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
                if okT and tile ~= nil then
                    local gt = get(tile, "groundType")
                    local mark = (get(tile, "hasCliff") == true and "!") or (get(tile, "hasRiver") == true and "r") or "."
                    g[#g + 1] = (GROUND_LETTER[gt] or "?") .. mark
                    local hv = get(tile, "height")
                    h[#h + 1] = type(hv) == "number" and string.format("%2d", math.floor(hv / 10)) or "??"
                else
                    g[#g + 1] = "??"; h[#h + 1] = "??"
                end
            end
            log("DUMP " .. name .. " y" .. y .. " G " .. table.concat(g, " "))
            log("DUMP " .. name .. " y" .. y .. " H " .. table.concat(h, " "))
        end
    end
    for i = 1, #DUMP_PATHS do
        local name, fx, fy, tx, ty = unpack(DUMP_PATHS[i])
        local okP, path = pcall(function() return M2TW.stratMap.getMovePath(fx, fy, tx, ty) end)
        if okP and path ~= nil then
            local n = get(path, "totalTiles") or 0
            local pts = {}
            for k = 0, n - 1 do
                local okC, c = pcall(function() return path:getPathCoords(k) end)
                if okC and c ~= nil then pts[#pts + 1] = tostring(get(c, "xCoord")) .. "," .. tostring(get(c, "yCoord")) end
            end
            log("DUMP path " .. name .. ": tiles " .. tostring(n) .. ", cost " .. tostring(get(path, "totalCost"))
                .. " : " .. table.concat(pts, " "))
        else
            log("DUMP path " .. name .. ": none (" .. tostring(path) .. ")")
        end
    end
end

function SS.onMapLoaded(why)
    local okD, errD = pcall(SS.dumpTerrain)
    if not okD then log("ERROR dump: " .. tostring(errD)) end
    local okH, errH = pcall(SS.setHinterlandFlags, false, why)
    if not okH then log("ERROR hinterland flags: " .. tostring(errH)) end
    SS.refreshNames(why)
    for i = 1, #SETTS do
        local sett = settlementByName("hxstart_" .. SETTS[i].key)
        if sett ~= nil then
            local ok, err = pcall(giveStarter, SETTS[i], sett, why)
            if not ok then log("ERROR starter " .. SETTS[i].key .. ": " .. tostring(err)) end
        end
    end
    for i = 1, #CHECK_SETTS do
        local ok, err = pcall(checkBuildable, CHECK_SETTS[i])
        if not ok then log("ERROR check " .. CHECK_SETTS[i] .. ": " .. tostring(err)) end
    end
end

local function giveGarrison(entry, sett, owner)
    local list = (get(owner, "name") == "slave") and entry.rebels or GARRISON[get(owner, "name")]
    if list == nil then log("no garrison for owner " .. tostring(get(owner, "name"))); return end
    local okA, army = pcall(function() return sett:createArmyInSettlement() end)
    if not okA or army == nil then log("garrison: createArmyInSettlement failed " .. tostring(army)); return end
    local res = {}
    for i = 1, #list do
        local okU, unit = pcall(function() return army:createUnit(list[i], 0, 0, 0) end)
        res[#res + 1] = list[i] .. " " .. ((okU and unit ~= nil) and "ok" or ("FAILED " .. tostring(unit)))
    end
    log("garrison " .. tostring(get(sett, "name")) .. ": " .. table.concat(res, ", "))
end

local function createOne(entry)
    local name = "hxstart_" .. entry.key
    if settlementByName(name) ~= nil then log(name .. " exists already - skipped"); return end
    -- ownerFrom (optional): take the owner from this settlement instead (e.g. a rebel-held one)
    local capital = settlementByName(entry.ownerFrom or entry.capital)
    local owner = get(capital, "ownerFaction")
    if owner == nil then log(name .. ": no owner found (capital " .. entry.capital .. ") - skipped"); return end
    local okFree, free = pcall(function() return M2TWEOP.isTileFree(entry.x, entry.y) end)
    local okAdd, sett = pcall(function() return owner:addSettlement(entry.x, entry.y, name, entry.level, entry.castle == true) end)
    if not okAdd or sett == nil then
        log(name .. ": addSettlement failed at " .. entry.x .. "," .. entry.y .. " (" .. tostring(sett)
            .. "), tile free " .. tostring(okFree and free))
        return
    end
    local fid = get(owner, "factionID")
    pcall(function() sett.creatorFactionID = fid end)
    pcall(function() sett.subFactionID = fid end)
    -- the wall building that belongs to the level (none for a village)
    local core = (entry.castle and CORE_CASTLE or CORE_LEVEL)[entry.level]
    local coreNote = "none"
    if core ~= nil then
        local okHas, has = pcall(function() return sett:buildingPresent(entry.castle and "core_castle_building" or "core_building") end)
        if okHas and has then
            coreNote = "already there"
        else
            local okB, errB = pcall(function() sett:createBuilding(core) end)
            coreNote = core .. " " .. tostring(okB) .. (okB and "" or (" " .. tostring(errB)))
        end
    end
    local okW, errW = pcall(giveGarrison, entry, sett, owner)
    if not okW then log("ERROR garrison " .. name .. ": " .. tostring(errW)) end
    local okG, errG = pcall(giveStarter, entry, sett, "created")
    if not okG then log("ERROR starter " .. name .. ": " .. tostring(errG)) end
    local okP = pcall(function() sett.settlementStats.population = entry.population end)
    pcall(function() sett.populationSize = entry.population end)
    applyName(entry, sett, "created")
    log("created " .. name .. " at " .. entry.x .. "," .. entry.y .. " for " .. tostring(get(owner, "name"))
        .. ", level " .. entry.level .. " (reads " .. tostring(get(sett, "level")) .. "), walls " .. coreNote
        .. ", population set " .. tostring(okP) .. " -> " .. tostring(get(get(sett, "settlementStats"), "population"))
        .. ", minor " .. tostring(get(sett, "isMinorSettlement")) .. ", region " .. tostring(get(sett, "regionID"))
        .. ", name " .. tostring(get(sett, "localizedName")))
end

function SS.createAll()
    log("new campaign: creating " .. #SETTS .. " settlement(s)")
    for i = 1, #SETTS do
        local ok, err = pcall(createOne, SETTS[i])
        if not ok then log("ERROR " .. SETTS[i].key .. ": " .. tostring(err)) end
    end
end

local function afterHook(name, fn, why)
    local previous = _G[name]
    _G[name] = function(arg)
        local result = nil
        if previous then result = previous(arg) end
        local ok, err = pcall(fn, why)
        if not ok then log("ERROR after " .. name .. ": " .. tostring(err)) end
        return result
    end
end

if not SS.installed then
    SS.installed = true
    afterHook("onNewGameLoaded", SS.createAll, "new game")
    afterHook("onCampaignMapLoaded", SS.onMapLoaded, "map loaded")
    afterHook("onGeneralCaptureSettlement", SS.refreshNames, "captured")
    afterHook("onPreFactionTurnStart", SS.refreshNames, "turn start")
    -- restore the flags before every faction's turn (the AI and the turn end never see them cleared)
    afterHook("onPreFactionTurnStart", function(why) SS.setHinterlandFlags(false, why) end, "turn start")
    local previous = _G["draw"]
    _G["draw"] = function(pDevice)
        if previous then previous(pDevice) end
        local ok, err = pcall(SS.draw)
        if not ok and not SS.drawErrorLogged then
            SS.drawErrorLogged = true
            log("ERROR in draw: " .. tostring(err))
        end
    end
end

StartingSettlements = SS
SS.SETTS = SETTS

return SS
