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
      names = { greek = "Nikomīdeia", middle_eastern = "Iznikomid", european = "Nicomedia" } },
    { key = "kutahya", x = 290, y = 130, capital = "Nicaea", level = 2, population = 7500,       -- GPS tile is mountain
      names = { greek = "Kotýaion", middle_eastern = "Kütahya", european = "Cotyaeum" } },
    { key = "poimanenon", x = 278, y = 130, capital = "Nicaea", level = 1, population = 1000,   -- on Balıkesir's tile; moved 277,131 -> 278,130 (user, 14 Oct, Romania fix 1)
      names = { greek = "Poimanīnon", middle_eastern = "Manyas", european = "Poemanenum" } },
    -- region Smyrna (Byzantium)
    { key = "bergama", x = 272, y = 127, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Pérgamon", middle_eastern = "Bergama", european = "Pergamum" } },
    { key = "manisa", x = 273, y = 124, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Magnīsía", middle_eastern = "Manisa", european = "Magnesia" } },
    { key = "birgi", x = 276, y = 122, capital = "Smyrna", level = 2, population = 7500,  -- moved 278,121 -> 276,122 (user, 14 Oct, Romania fix 1)
      names = { greek = "Pyrgíon", middle_eastern = "Birgi", european = "Pyrgion" } },
    { key = "alasehir", x = 281, y = 122, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Philadélpheia", middle_eastern = "Âlâşehir", european = "Philadelphia" } },
    { key = "denizli", x = 286, y = 119, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Laodíkeia", middle_eastern = "Lazkiye", european = "Laodicea" } },
    { key = "milas", x = 276, y = 116, capital = "Smyrna", level = 2, population = 7500,
      names = { greek = "Mýlasa", middle_eastern = "Milas", european = "Mylasa" } },
    -- region Angora (Rum)
    { key = "afyon", x = 296, y = 125, capital = "Angora", level = 2, population = 7500,
      names = { greek = "Akroinón", middle_eastern = "Karahisar-i Sâhib", european = "Acroinum" } },
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
    { key = "mardin", x = 369, y = 115, capital = "Hasankeyf", level = 2, population = 7500,  -- EU5 town; Artuqid seat; moved 370,115 -> 369,115 (user, 14 Oct, Romania fix 1)
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
      names = { greek = "Doulíchē", middle_eastern = "Ayintap", arabic = "'Ayntab", european = "Hatab", default = "'Ayntab" },
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
      names = { greek = "Syēnē", middle_eastern = "Asvan", arabic = "Aswan", european = "Syene", default = "Aswan" },
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
      names = { greek = "Hippōn", middle_eastern = "Annabe", arabic = "Buna", european = "Bona", default = "Buna" },
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
      names = { greek = "Kaisáreia", middle_eastern = "Serşel", arabic = "Sharshal", european = "Cesarea", default = "Sharshal" },
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
      names = { greek = "Soústar", middle_eastern = "Suşter", arabic = "Tustar", european = "Tostar", default = "Shushtar" },
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
    { key = "khoy", x = 403, y = 123, capital = "Tabriz", level = 2, population = 7500,  -- rebels; moved 403,124 -> 403,123 (user, 14 Oct, Romania fix 1)
      names = { greek = "Choï", middle_eastern = "Hoy", arabic = "Khuway", european = "Coy", default = "Khoy" },
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
      names = { greek = "Sougdaía", middle_eastern = "Sugdak", arabic = "Sudaq", european = "Soldaia", default = "Sougdaía" },
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
      names = { greek = "Sarái", middle_eastern = "Saray-i Cedid", arabic = "Saray al-Jadid", european = "Sarai", default = "Saray al-Jadid" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    -- Russia / Rus' (user, 14 Oct 2026): Russian names for Novgorod, Kievan Rus and rebels, Polish for Poland,
    -- Lithuanian for Lithuania, Latin for other Europeans, Greek, Turkish. Garrison EE Spear Militia.
    { key = "tver", x = 335, y = 255, capital = "Novgorod", level = 1, population = 500,  -- EU5 city, founded c. 1135
      names = { russia = "Tver'", kievan_rus = "Tver'", poland = "Twer", lithuania = "Tvere", european = "Tveria", greek = "Tvéri", middle_eastern = "Tver", default = "Tver'" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "moscow", x = 347, y = 248, capital = "Rustov", ownerFrom = "Suzdal", level = 1, population = 500,  -- EU5 city, first mentioned 1147; stays Kievan Rus (user, 14 Oct)
      names = { russia = "Moskva", kievan_rus = "Moskva", poland = "Moskwa", lithuania = "Maskva", european = "Moscovia", greek = "Moschóbion", middle_eastern = "Moskova", default = "Moskva" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "vologda", x = 358, y = 271, capital = "Rustov", level = 1, population = 500,  -- EU5 town, first mentioned 1147
      names = { russia = "Vologda", kievan_rus = "Vologda", poland = "Wołogda", lithuania = "Vologda", european = "Vologda", greek = "Vológda", middle_eastern = "Vologda", default = "Vologda" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "beloozero", x = 343, y = 278, capital = "Rustov", level = 2, population = 7500,  -- existed 1132
      names = { russia = "Beloozero", kievan_rus = "Beloozero", poland = "Białe Jezioro", lithuania = "Baltezeris", european = "Bieloosero", greek = "Belóozero", middle_eastern = "Akgöl", default = "Beloozero" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "murom", x = 379, y = 247, capital = "Suzdal", level = 2, population = 7500,  -- existed 1132
      names = { russia = "Murom", kievan_rus = "Murom", poland = "Murom", lithuania = "Muromas", european = "Muroma", greek = "Moúrom", middle_eastern = "Murom", default = "Murom" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "nizhny", x = 392, y = 253, capital = "Ryazan", level = 1, population = 500,  -- EU5 town, founded 1221; rebels
      names = { russia = "Nizhnii Novgorod", kievan_rus = "Nizhnii Novgorod", poland = "Nizny Nowogród", lithuania = "Zemutinis Naugardas", european = "Novogardia Inferior", greek = "Kato Nóvgorod", middle_eastern = "Aşagi Novgorod", default = "Nizhnii Novgorod" },
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
      names = { russia = "Berest'e", kievan_rus = "Berest'e", poland = "Brzesc", lithuania = "Brastas", european = "Bresta", greek = "Berestíe", middle_eastern = "Brest", default = "Berest'e" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "lutsk", x = 262, y = 212, capital = "Volodymyr", level = 2, population = 7500,  -- existed 1132
      names = { russia = "Luchesk", kievan_rus = "Luchesk", poland = "Luck", lithuania = "Luckas", european = "Luceoria", greek = "Loútsk", middle_eastern = "Lutsk", default = "Luchesk" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "lviv", x = 255, y = 206, capital = "Volodymyr", level = 1, population = 500,  -- EU5 town, founded c. 1250
      names = { russia = "L'vov", kievan_rus = "L'vov", poland = "Lwów", lithuania = "Lvovas", european = "Leopolis", greek = "Leontópolis", middle_eastern = "Ilbav", default = "L'vov" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "przemysl", x = 245, y = 205, capital = "Halych", level = 2, population = 7500,  -- existed 1132; rebels
      names = { russia = "Peremyshl'", kievan_rus = "Peremyshl'", poland = "Przemysl", lithuania = "Pšemislis", european = "Premislia", greek = "Peremýsl", middle_eastern = "Peremişl", default = "Peremyshl'" },
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
      names = { greek = "Thēbai", european = "Thebae", middle_eastern = "Istife", serbia = "Teba", hungary = "Théba", default = "Thēbai" } },
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
    { key = "nis", x = 237, y = 155, capital = "Sredets", level = 2, population = 7500,  -- moved 237,156 -> 237,155 (user, 14 Oct, Romania fix 1)
      names = { greek = "Naïssos", european = "Naissus", middle_eastern = "Niş", serbia = "Niš", hungary = "Nis", default = "Niš" } },
    { key = "plovdiv", x = 256, y = 150, capital = "Sredets", level = 2, population = 7500,
      names = { greek = "Philippoupolis", european = "Philippopolis", middle_eastern = "Filibe", serbia = "Plovdiv", hungary = "Filippopol", default = "Plovdiv" } },
    { key = "branicevo", x = 235, y = 166, capital = "Nis", level = 1, population = 1000, rebels = { "Spear Militia", "Spear Militia" },
      names = { greek = "Branitzova", european = "Branicevum", middle_eastern = "Braniçevo", serbia = "Branicevo", hungary = "Barancs", default = "Branicevo" } },
    { key = "vidin", x = 245, y = 164, capital = "Tarnovo", level = 2, population = 7500,  -- moved 244,161 -> 245,164 (user, 14 Oct, Romania fix 1); Bulgarian rebels: Tarnovo itself is rebel now (user, 14 Oct)
      names = { greek = "Bidinē", european = "Bononia", middle_eastern = "Vidin", serbia = "Bdin", hungary = "Bodony", default = "Bdin" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "cherven", x = 265, y = 160, capital = "Tarnovo", level = 2, population = 7500,  -- Bulgarian rebels: Tarnovo itself is rebel now (user, 14 Oct)
      names = { greek = "Tzerbenon", european = "Cerven", middle_eastern = "Çerven", serbia = "Cerven", hungary = "Cserven", default = "Cerven" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "drastar", x = 274, y = 163, capital = "Tarnovo", level = 2, population = 7500,  -- Bulgarian rebels: Tarnovo itself is rebel now (user, 14 Oct)
      names = { greek = "Dristra", european = "Durostorum", middle_eastern = "Silistre", serbia = "Drastar", hungary = "Szilisztra", default = "Drastar" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "shumen", x = 271, y = 157, capital = "Tarnovo", ownerFrom = "Adrianople", level = 2, population = 7500,  -- stays Byzantine via ownerFrom (Tarnovo rebel, 14 Oct)
      names = { greek = "Soumen", european = "Sumen", middle_eastern = "Sumnu", serbia = "Šumen", hungary = "Sumen", default = "Šumen" } },
    { key = "varna", x = 277, y = 156, capital = "Tarnovo", ownerFrom = "Adrianople", level = 2, population = 7500,  -- moved 277,157 -> 278,156 (user, 14 Oct, Romania fix 1); stays Byzantine via ownerFrom (Tarnovo rebel, 14 Oct); 1 west again -> 277,156 (user, 14 Oct)
      names = { greek = "Barna", european = "Varna", middle_eastern = "Varna", serbia = "Varna", hungary = "Várna", default = "Varna" } },
    { key = "sliven", x = 267, y = 153, capital = "Tarnovo", ownerFrom = "Adrianople", level = 2, population = 7500,  -- moved 267,153 -> 267,154 (user, 14 Oct, Romania fix 1); stays Byzantine via ownerFrom (Tarnovo rebel, 14 Oct); 1 south again -> 267,153 (user, 14 Oct)
      names = { greek = "Stilbnos", european = "Stilbnum", middle_eastern = "Islimye", serbia = "Sliven", hungary = "Szliven", default = "Sliven" } },
    { key = "anchialos", x = 276, y = 151, capital = "Tarnovo", ownerFrom = "Adrianople", level = 2, population = 7500,  -- moved 274,152 -> 276,151 (user, 14 Oct, Romania fix 1); stays Byzantine via ownerFrom (Tarnovo rebel, 14 Oct)
      names = { greek = "Anchialos", european = "Anchialus", middle_eastern = "Ahyolu", serbia = "Anhialo", hungary = "Ankhialosz", default = "Anchialos" } },
    { key = "gallipoli", x = 270, y = 138, capital = "Adrianople", level = 2, population = 7500,  -- moved 270,135 -> 270,138 (user, 14 Oct, Romania fix 1)
      names = { greek = "Kallipolis", european = "Callipolis", middle_eastern = "Gelibolu", serbia = "Galipolj", hungary = "Gallipoli", default = "Kallipolis" } },
    { key = "mosynopolis", x = 260, y = 142, capital = "Adrianople", level = 2, population = 7500,
      names = { greek = "Mosynopolis", european = "Mosynopolis", middle_eastern = "Gümülcine", serbia = "Mosinopolj", hungary = "Moszinopolisz", default = "Mosynopolis" } },
    { key = "kotor", x = 213, y = 152, capital = "Skadar", level = 2, population = 7500, rebels = { "Spear Militia", "Spear Militia" },
      names = { greek = "Dekatera", european = "Catarum", middle_eastern = "Kotor", serbia = "Kotor", hungary = "Kotor", default = "Kotor" } },
    { key = "rhodes", x = 278, y = 106, capital = "Smyrna", level = 2, population = 7500, castle = true,
      names = { greek = "Rhodos", european = "Rhodus", middle_eastern = "Rodos", serbia = "Rodos", hungary = "Rodosz", default = "Rhodos" } },
    -- POLAND + BALTIC (14 Oct 2026)
    { key = "gniezno", x = 204, y = 223, capital = "Poznan", level = 3, population = 15000,  -- archbishopric seat
      names = { hre = "Gnesen", lithuania = "Gniezna", russia = "Gnezdno", kievan_rus = "Gnezdno", european = "Gnesna", greek = "Gnézno", middle_eastern = "Gniezno", default = "Gniezno" } },
    { key = "kalisz", x = 208, y = 218, capital = "Poznan", level = 2, population = 7500,  -- existed 1132 (Calisia)
      names = { hre = "Kalisch", lithuania = "Kališas", european = "Calisia", greek = "Kálisz", middle_eastern = "Kalisz", default = "Kalisz" } },
    { key = "wloclawek", x = 219, y = 224, capital = "Poznan", level = 2, population = 7500,  -- castellany seat
      names = { hre = "Leslau", lithuania = "Vloclavekas", european = "Wladislavia", greek = "Vlotslávek", middle_eastern = "Wloclawek", default = "Włocławek" } },
    { key = "torun", x = 213, y = 226, capital = "Poznan", level = 1, population = 500,  -- founded 1233
      names = { hre = "Thorn", lithuania = "Torune", european = "Thorunium", greek = "Toroún", middle_eastern = "Torun", default = "Toruń" } },
    { key = "czersk", x = 233, y = 220, capital = "Plock", level = 1, population = 1000,  -- doubtful
      names = { hre = "Tschersk", lithuania = "Cerskas", european = "Czersca", greek = "Tsersk", middle_eastern = "Czersk", default = "Czersk" } },
    { key = "warsaw", x = 230, y = 222, capital = "Plock", level = 1, population = 500,  -- user 14 Oct (Jazdow / Warsaw, tile 1 west of GPS: spacing to Czersk)
      names = { hre = "Warschau", lithuania = "Varšuva", russia = "Varshava", kievan_rus = "Varshava", european = "Varsovia", greek = "Varsovía", middle_eastern = "Varşova", poland = "Warszawa", denmark = "Warschau", default = "Warszawa" } },
    { key = "sandomierz", x = 236, y = 211, capital = "Krakow", level = 2, population = 7500,  -- existed 1132
      names = { hre = "Sandomir", lithuania = "Sandomiras", russia = "Sudomir", kievan_rus = "Sudomir", european = "Sandomiria", greek = "Sandomír", middle_eastern = "Sandomierz", default = "Sandomierz" } },
    { key = "lublin", x = 241, y = 215, capital = "Krakow", level = 1, population = 1000,  -- first named 1198
      names = { hre = "Lublin", lithuania = "Liublinas", russia = "Lyublin", kievan_rus = "Lyublin", european = "Lublinum", greek = "Lúblin", middle_eastern = "Lublin", default = "Lublin" } },
    { key = "opole", x = 207, y = 210, capital = "Wroclaw", level = 2, population = 7500,  -- EU5 town
      names = { hre = "Oppeln", lithuania = "Opole", european = "Oppolia", greek = "Opóle", middle_eastern = "Opole", default = "Opole" } },
    { key = "legnica", x = 194, y = 214, capital = "Wroclaw", level = 2, population = 7500,  -- existed 1132
      names = { hre = "Liegnitz", lithuania = "Lignica", european = "Legnicia", greek = "Légnitsa", middle_eastern = "Legnica", default = "Legnica" } },
    { key = "glogow", x = 192, y = 218, capital = "Wroclaw", level = 2, population = 7500,  -- existed 1132; moved 1 NW (user, 15 Oct)
      names = { hre = "Glogau", lithuania = "Glogovas", european = "Glogovia", greek = "Glogóv", middle_eastern = "Glogow", default = "Głogów" } },
    { key = "raciborz", x = 211, y = 206, capital = "Olomoc", level = 2, population = 7500,  -- existed 1132; rebels (Olomouc region); moved 1 SE (user, 15 Oct)
      names = { poland = "Racibórz", hre = "Ratibor", lithuania = "Raciburas", european = "Ratibora", greek = "Ratibór", middle_eastern = "Raciborz", default = "Racibórz" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "slupsk", x = 200, y = 237, capital = "Gdansk", level = 2, population = 7500,  -- existed 1132
      names = { hre = "Stolp", denmark = "Stolp", lithuania = "Slupskas", european = "Stolpa", greek = "Slúpsk", middle_eastern = "Slupsk", default = "Słupsk" } },
    { key = "wolin", x = 184, y = 231, capital = "Szczecin", level = 2, population = 7500,  -- existed 1132; rebels; moved 1 east (user, 15 Oct)
      names = { poland = "Wolin", hre = "Wollin", denmark = "Wollin", lithuania = "Volinas", european = "Julinum", greek = "Voulin", middle_eastern = "Wolin", default = "Wolin" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "kolobrzeg", x = 188, y = 234, capital = "Szczecin", level = 2, population = 7500,  -- existed 1132; rebels
      names = { poland = "Kołobrzeg", hre = "Kolberg", denmark = "Kolberg", lithuania = "Kolobzegas", european = "Colberga", greek = "Kolóbzeg", middle_eastern = "Kolobrzeg", default = "Kołobrzeg" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "wolgast", x = 176, y = 234, capital = "Szczecin", level = 2, population = 7500,  -- EU5 town; rebels
      names = { poland = "Wołogoszcz", hre = "Wolgast", denmark = "Wolgast", lithuania = "Volgastas", european = "Wolgastum", greek = "Volgast", middle_eastern = "Wolgast", default = "Wolgast" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "stralsund", x = 170, y = 237, capital = "Lubeck", level = 1, population = 500,  -- EU5 town, founded 1234; rebels; moved 1 west, 2 north (user tested unit movement there, 15 Oct)
      names = { poland = "Stralsund", hre = "Stralsund", denmark = "Stralsund", lithuania = "Štralzundas", european = "Stralesundum", greek = "Stralzoúnd", middle_eastern = "Stralsund", default = "Stralsund" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "kaunas", x = 246, y = 238, capital = "Kernave", level = 1, population = 500,  -- EU5 town, first named 1361
      names = { poland = "Kowno", russia = "Kovno", kievan_rus = "Kovno", hre = "Kauen", lithuania = "Kaunas", european = "Cauna", greek = "Kaoúnas", middle_eastern = "Kaunas", default = "Kaunas" } },
    { key = "vilnius", x = 253, y = 240, capital = "Kernave", level = 1, population = 500,  -- EU5 town, first named 1323
      names = { poland = "Wilno", russia = "Vilno", kievan_rus = "Vilno", hre = "Wilna", lithuania = "Vilnius", european = "Vilna", greek = "Vílnios", middle_eastern = "Vilnius", default = "Vilnius" } },
    { key = "tartu", x = 270, y = 265, capital = "Kolyvan", level = 2, population = 7500,  -- EU5 town; rebels
      names = { russia = "Yuryev", kievan_rus = "Yuryev", hre = "Dorpat", denmark = "Dorpat", poland = "Dorpat", lithuania = "Tartu", european = "Tarbatum", greek = "Tártou", middle_eastern = "Tartu", default = "Tartu" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "koknese", x = 260, y = 252, capital = "Riga", level = 1, population = 1000,  -- hillfort; rebels
      names = { russia = "Kukonos", kievan_rus = "Kukonos", hre = "Kokenhusen", poland = "Koknese", lithuania = "Koknese", european = "Kokenhusa", greek = "Koknese", middle_eastern = "Koknese", default = "Koknese" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "jersika", x = 265, y = 250, capital = "Polotsk", level = 1, population = 1000,  -- hillfort; rebels
      names = { russia = "Gertsike", kievan_rus = "Gertsike", hre = "Gerzike", poland = "Jersika", lithuania = "Jersike", european = "Gercica", greek = "Jersika", middle_eastern = "Jersika", default = "Jersika" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },

    -- Hungary + Croatia (15 Oct 2026): EU5 transdanubia/north+south_alfold/slovakia/croatia/slavonia/slovenia/bosnia areas
    { key = "buda", x = 216, y = 185, capital = "Szekesfehervar", level = 3, population = 15000,  -- EU5 city; moved 5 east of Szekesfehervar (user, 15 Oct)
      names = { hungary = "Buda", hre = "Ofen", european = "Buda", greek = "Voúda", middle_eastern = "Budin", default = "Buda" } },
    { key = "pest", x = 218, y = 185, capital = "Szekesfehervar", level = 1, population = 500,  -- 2 east of Buda (user, 15 Oct)
      names = { hungary = "Pest", hre = "Pesth", european = "Pest", greek = "Pésti", middle_eastern = "Peşt", default = "Pest" } },
    { key = "pecs", x = 211, y = 178, capital = "Szekesfehervar", level = 2, population = 7500,
      names = { hungary = "Pécs", hre = "Fünfkirchen", european = "Quinque Ecclesiae", greek = "Pétsvár", middle_eastern = "Peçuy", default = "Pécs" } },
    { key = "sopron", x = 202, y = 188, capital = "Szekesfehervar", level = 2, population = 7500,
      names = { hungary = "Sopron", hre = "Ödenburg", european = "Scarbantia", greek = "Sopróni", middle_eastern = "Sopron", default = "Sopron" } },
    { key = "szeged", x = 226, y = 179, capital = "Varad", level = 2, population = 7500,
      names = { hungary = "Szeged", hre = "Segedin", european = "Partiscum", greek = "Séged", middle_eastern = "Seged", default = "Szeged" } },
    { key = "bratislava", x = 203, y = 194, capital = "Esztergom", level = 2, population = 7500,  -- moved 2 west, 1 north (user, 15 Oct)
      names = { hungary = "Pozsony", hre = "Pressburg", european = "Posonium", greek = "Presburg", middle_eastern = "Pojon", default = "Pozsony" } },
    { key = "kosice", x = 234, y = 197, capital = "Esztergom", level = 2, population = 7500,  -- moved 1 west, 1 north (user, 15 Oct)
      names = { hungary = "Kassa", hre = "Kaschau", european = "Cassovia", greek = "Kásia", middle_eastern = "Koşa", default = "Kassa" } },
    { key = "krupina", x = 221, y = 194, capital = "Esztergom", level = 2, population = 7500,  -- user asked 221,195 (2 west); no open tile there, snapped to 221,194 (15 Oct)
      names = { hungary = "Korpona", hre = "Karpfen", european = "Korponia", greek = "Korpóna", middle_eastern = "Korpona", default = "Korpona" } },
    { key = "knin", x = 192, y = 164, capital = "Zagreb", ownerFrom = "Zara", level = 2, population = 7500,  -- Dalmatia; rebels (user, 15 Oct); moved 194,163 -> 192,164 (user, 14 Oct, Romania fix 1)
      names = { hungary = "Knin", hre = "Tenin", european = "Tininium", greek = "Knin", middle_eastern = "Knin", default = "Knin" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "rijeka", x = 181, y = 173, capital = "Freiberg", ownerFrom = "Zara", level = 2, population = 7500,  -- Istria/Kvarner; rebels. User asked 1 SW (181,173); relief 50 there, snapped to 181,174 (15 Oct); moved 181,174 -> 181,173 (user, 14 Oct, Romania fix 1)
      names = { hungary = "Fiume", hre = "Sankt Veit am Pflaum", european = "Tarsatica", greek = "Ríjeka", middle_eastern = "Riyeka", default = "Rijeka" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "trieste", x = 176, y = 175, capital = "Venice", ownerFrom = "Verona", level = 2, population = 7500,  -- Istria/Friuli; rebels. Requested tile is Venice_Province, not unassigned - moved there, no map edit needed (15 Oct)
      names = { hungary = "Trieszt", hre = "Triest", european = "Tergeste", greek = "Triésti", middle_eastern = "Tirieste", default = "Trieste" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    -- Romania: Transylvania, Partium, Banat, Wallachia, Moldavia, Danube mouth, Dobruja (user, 14 Oct 2026)
    { key = "cluj", x = 249, y = 183, capital = "Gyulafehervar", level = 2, population = 7500,  -- EU5 town; Kolozs county castle, 11th c.
      names = { hungary = "Kolozsvár", hre = "Klausenburg", european = "Claudiopolis", greek = "Klaudiópolis", middle_eastern = "Kaloşvar", default = "Cluj" } },
    { key = "satu_mare", x = 245, y = 189, capital = "Gyulafehervar", level = 1, population = 1000,  -- county castle, size doubtful
      names = { hungary = "Szatmár", hre = "Sathmar", european = "Zathmarium", greek = "Satmári", middle_eastern = "Satmar", default = "Satmar" } },
    { key = "arad", x = 233, y = 178, capital = "Varad", level = 2, population = 7500,  -- royal assembly 1131, chapter
      names = { hungary = "Arad", hre = "Arad", european = "Aradinum", greek = "Arád", middle_eastern = "Arad", default = "Arad" } },
    { key = "timisoara", x = 233, y = 175, capital = "Varad", level = 1, population = 1000,  -- Banat; castle first named 1212
      names = { hungary = "Temesvár", hre = "Temeschburg", european = "Temesvarinum", greek = "Temesvári", middle_eastern = "Temeşvar", default = "Timişoara" } },
    { key = "sibiu", x = 253, y = 177, capital = "Gyulafehervar", level = 1, population = 500,  -- late (Saxons after 1147)
      names = { hungary = "Nagyszeben", hre = "Hermannstadt", european = "Cibinium", greek = "Kibínion", middle_eastern = "Sibin", default = "Sibiu" } },
    { key = "brasov", x = 263, y = 177, capital = "Gyulafehervar", level = 1, population = 500,  -- EU5 town; late (1211)
      names = { hungary = "Brassó", hre = "Kronstadt", european = "Corona", greek = "Stefanópolis", middle_eastern = "Braşov", default = "Braşov" } },
    { key = "bistrita", x = 256, y = 186, capital = "Gyulafehervar", level = 1, population = 500,  -- late (Saxon)
      names = { hungary = "Beszterce", hre = "Bistritz", european = "Bistricium", greek = "Bistrítsa", middle_eastern = "Bistriçe", default = "Bistrita" } },
    { key = "sighisoara", x = 258, y = 179, capital = "Gyulafehervar", level = 1, population = 500,  -- late (1280)
      names = { hungary = "Segesvár", hre = "Schäßburg", european = "Castrum Sex", greek = "Sigisoára", middle_eastern = "Seşvar", default = "Sighişoara" } },
    { key = "craiova", x = 251, y = 165, capital = "Severin", level = 1, population = 500,  -- Wallachia; late; rebels
      names = { hungary = "Krajova", hre = "Krajowa", european = "Craiova", greek = "Kraïóva", middle_eastern = "Kirayova", default = "Craiova" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "arges", x = 254, y = 170, capital = "Severin", level = 1, population = 500,  -- Wallachia; late; rebels
      names = { hungary = "Argyas", hre = "Argisch", european = "Argesium", greek = "Argési", middle_eastern = "Arciş", default = "Curtea de Argeş" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "bucharest", x = 266, y = 165, capital = "Severin", level = 1, population = 500,  -- EU5 town; late (1459); rebels
      names = { hungary = "Bukarest", hre = "Bukarest", european = "Bucarestium", greek = "Voukourésti", middle_eastern = "Bükreş", default = "Bucureşti" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "braila", x = 278, y = 172, capital = "Severin", level = 1, population = 500,  -- late (1368); rebels
      names = { hungary = "Brajla", hre = "Brailen", european = "Braila", greek = "Proïlabon", middle_eastern = "Ibrail", default = "Braila" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "suceava", x = 268, y = 189, capital = "Halych", level = 1, population = 500,  -- EU5 town; late (1388); rebels
      names = { hungary = "Szucsáva", hre = "Suczawa", poland = "Suczawa", kievan_rus = "Suchava", russia = "Suchava", european = "Sucevia", greek = "Soútsava", middle_eastern = "Suçava", default = "Suceava" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "hotin", x = 271, y = 196, capital = "Halych", level = 1, population = 1000,  -- Rus' fortress; rebels
      names = { hungary = "Hotin", hre = "Chotin", poland = "Chocim", kievan_rus = "Khotin", russia = "Khotin", european = "Hotinum", greek = "Chotíni", middle_eastern = "Hotin", default = "Hotin" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "barlad", x = 277, y = 178, capital = "Iasi", level = 1, population = 1000,  -- Berladniks c. 1140; Cumans (user)
      names = { cumans = "Berlad", kievan_rus = "Berlad'", russia = "Berlad'", hungary = "Barlád", hre = "Berlad", european = "Berladum", greek = "Berládi", middle_eastern = "Berlad", default = "Bârlad" } },
    { key = "cetatea_alba", x = 293, y = 178, capital = "Iasi", ownerFrom = "Severin", level = 2, population = 7500,  -- Tyras/Belgorod; rebels (user)
      names = { cumans = "Akkerman", kievan_rus = "Belgorod", russia = "Belgorod", hungary = "Dnyeszterfehérvár", hre = "Weißenburg", european = "Album Castrum", greek = "Asprókastron", middle_eastern = "Akkerman", default = "Cetatea Alba" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "chilia", x = 287, y = 173, capital = "Iasi", level = 1, population = 1000,  -- Byzantine site; Cumans (user); moved 288,175 -> 287,173 (user, 14 Oct, Romania fix 1)
      names = { cumans = "Kili", kievan_rus = "Kiliya", russia = "Kiliya", hungary = "Kilia", hre = "Kilia", european = "Licostomum", greek = "Chilía", middle_eastern = "Kili", default = "Chilia" } },
    { key = "isaccea", x = 283, y = 171, capital = "Tarnovo", level = 2, population = 7500,  -- Vicina, Byzantine Danube port; names by owner (user); moved 282,172 -> 283,171 (user, 14 Oct, Romania fix 1); Bulgarian rebels: Tarnovo itself is rebel now (user, 14 Oct)
      names = { cumans = "Vicina", kievan_rus = "Vichina", russia = "Vichina", hungary = "Vicina", hre = "Vicina", european = "Vicina", greek = "Bitzína", middle_eastern = "Isakça", default = "Isaccea" },
      rebels = { "EE Spear Militia", "EE Spear Militia" } },
    { key = "constanta", x = 283, y = 163, capital = "Tarnovo", ownerFrom = "Adrianople", level = 2, population = 7500,  -- EU5 town; Byzantine; moved 282,164 -> 283,163 (user, 14 Oct, Romania fix 1); stays Byzantine via ownerFrom (Tarnovo rebel, 14 Oct)
      names = { hungary = "Konstanca", hre = "Konstanza", european = "Constantia", greek = "Konstantía", middle_eastern = "Köstence", default = "Constanta" } },
    -- Iberia (14 Oct 2026): Castile-Leon (spain), aragon, portugal, moors; owner = real 1132 owner
    { key = "salamanca", x = 31, y = 138, capital = "Valladolid", level = 2, population = 7500,  -- EU5 town; resettled 1102; on the former Ciudad Rodrigo tile (user, 14 Oct, Iberia fix 1); SSHIP's own "Salamanca" renamed Valladolid
      names = { spain = "Salamanca", portugal = "Salamanca", aragon = "Salamanca", arabic = "Shalamanka", european = "Salmantica", default = "Salamanca" } },
    { key = "segovia", x = 46, y = 142, capital = "Burgos", level = 2, population = 7500,  -- EU5 town; resettled 1088
      names = { spain = "Segovia", portugal = "Segóvia", aragon = "Segòvia", arabic = "Shaqubiya", european = "Segovia", default = "Segovia" } },
    { key = "zamora", x = 37, y = 145, capital = "Leon", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Zamora", portugal = "Zamora", aragon = "Zamora", arabic = "Samura", european = "Ocellodurum", default = "Zamora" } },
    { key = "santander", x = 51, y = 157, capital = "Burgos", level = 1, population = 1000,  -- EU5 town; small port (fuero 1187)
      names = { spain = "Santander", portugal = "Santander", aragon = "Santander", arabic = "Shant Andar", european = "Portus Victoriae", default = "Santander" } },
    { key = "oviedo", x = 31, y = 158, capital = "Leon", level = 2, population = 7500,  -- EU5 town; tight tile (5 open neighbours)
      names = { spain = "Oviedo", portugal = "Oviedo", aragon = "Oviedo", arabic = "Ubiyadu", european = "Ovetum", default = "Oviedo" } },
    { key = "lugo", x = 23, y = 155, capital = "Leon", level = 1, population = 1000,  -- extra; bishopric
      names = { spain = "Lugo", portugal = "Lugo", aragon = "Lugo", arabic = "Luk", european = "Lucus Augusti", default = "Lugo" } },
    { key = "talavera", x = 43, y = 134, capital = "Toledo", level = 2, population = 7500,  -- extra; Castilian since 1083
      names = { spain = "Talavera", portugal = "Talavera", aragon = "Talavera", arabic = "Talabira", european = "Caesarobriga", default = "Talavera" } },
    { key = "calatayud", x = 66, y = 143, capital = "Zaragoza", level = 2, population = 7500,  -- EU5 town; Aragonese since 1120
      names = { spain = "Calatayud", portugal = "Calatayud", aragon = "Calataiud", arabic = "Qalat Ayyub", european = "Bilbilis", default = "Calatayud" } },
    { key = "huesca", x = 74, y = 149, capital = "Zaragoza", level = 2, population = 7500,  -- EU5 town; Aragonese since 1096
      names = { spain = "Huesca", portugal = "Huesca", aragon = "Osca", arabic = "Washqa", european = "Osca", default = "Huesca" } },
    { key = "girona", x = 97, y = 148, capital = "Barcelona", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Gerona", portugal = "Girona", aragon = "Girona", arabic = "Jarunda", european = "Gerunda", default = "Girona" } },
    { key = "tarragona", x = 86, y = 143, capital = "Zaragoza", level = 1, population = 1000,  -- EU5 town; resettled from 1129
      names = { spain = "Tarragona", portugal = "Tarragona", aragon = "Tarragona", arabic = "Tarrakuna", european = "Tarraco", default = "Tarragona" } },
    { key = "soria", x = 59, y = 145, capital = "Burgos", ownerFrom = "Zaragoza", level = 1, population = 1000,  -- extra; resettled 1119 by Aragon, Aragonese in 1132
      names = { spain = "Soria", portugal = "Sória", aragon = "Sòria", arabic = "Suriya", european = "Soria", default = "Soria" } },
    { key = "viseu", x = 21, y = 138, capital = "Coimbra", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Viseo", portugal = "Viseu", aragon = "Viseu", arabic = "Bazu", european = "Viseum", default = "Viseu" } },
    { key = "porto", x = 16, y = 143, capital = "Coimbra", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Oporto", portugal = "Porto", aragon = "Port", arabic = "Burtuqal", european = "Portus Cale", default = "Porto" } },
    { key = "braga", x = 17, y = 146, capital = "Coimbra", level = 2, population = 7500,  -- extra; archbishopric
      names = { spain = "Braga", portugal = "Braga", aragon = "Braga", arabic = "Braqara", european = "Bracara Augusta", default = "Braga" } },
    { key = "guimaraes", x = 20, y = 144, capital = "Coimbra", level = 2, population = 7500,  -- extra; court of Afonso Henriques
      names = { spain = "Guimarães", portugal = "Guimarães", aragon = "Guimarães", arabic = "Gimaranish", european = "Vimaranes", default = "Guimarães" } },
    { key = "malaga", x = 45, y = 111, capital = "Granada", level = 3, population = 15000,  -- EU5 city
      names = { spain = "Málaga", portugal = "Málaga", aragon = "Màlaga", arabic = "Malaqa", european = "Malaca", default = "Málaga" } },
    { key = "almeria", x = 62, y = 113, capital = "Granada", level = 2, population = 7500,  -- EU5 town; port
      names = { spain = "Almería", portugal = "Almeria", aragon = "Almeria", arabic = "al-Mariya", european = "Portus Magnus", default = "Almería" } },
    { key = "jaen", x = 50, y = 120, capital = "Cordoba", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Jaén", portugal = "Jaén", aragon = "Jaén", arabic = "Jayyan", european = "Aurgi", default = "Jaén" } },
    { key = "orihuela", x = 72, y = 122, capital = "Murcia", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Orihuela", portugal = "Orihuela", aragon = "Oriola", arabic = "Uryula", european = "Orcelis", default = "Orihuela" } },
    { key = "caceres", x = 32, y = 130, capital = "Badajoz", level = 2, population = 7500,  -- EU5 town
      names = { spain = "Cáceres", portugal = "Cáceres", aragon = "Càceres", arabic = "Qazris", european = "Castra Caecilia", default = "Cáceres" } },
    { key = "evora", x = 20, y = 124, capital = "Lisbon", level = 2, population = 7500,  -- EU5 town; Muslim until 1165
      names = { spain = "Évora", portugal = "Évora", aragon = "Èvora", arabic = "Yabura", european = "Ebora", default = "Évora" } },
    { key = "santarem", x = 15, y = 129, capital = "Lisbon", level = 2, population = 7500,  -- EU5 town; Muslim until 1147
      names = { spain = "Santarén", portugal = "Santarém", aragon = "Santarem", arabic = "Shantarin", european = "Scallabis", default = "Santarém" } },
    { key = "lleida", x = 82, y = 145, capital = "Zaragoza", ownerFrom = "Valencia", level = 2, population = 7500,  -- EU5 town; Muslim until 1149
      names = { spain = "Lérida", portugal = "Lérida", aragon = "Lleida", arabic = "Larida", european = "Ilerda", default = "Lleida" } },
    { key = "tortosa", x = 81, y = 140, capital = "Zaragoza", ownerFrom = "Valencia", level = 2, population = 7500,  -- EU5 town; Muslim until 1148
      names = { spain = "Tortosa", portugal = "Tortosa", aragon = "Tortosa", arabic = "Turtusha", european = "Dertosa", default = "Tortosa" } },
    { key = "cuenca", x = 61, y = 134, capital = "Toledo", ownerFrom = "Valencia", level = 2, population = 7500,  -- EU5 town; Muslim until 1177
      names = { spain = "Cuenca", portugal = "Cuenca", aragon = "Conca", arabic = "Qunka", european = "Conca", default = "Cuenca" } },
    { key = "morella", x = 76, y = 141, capital = "Zaragoza", ownerFrom = "Valencia", level = 1, population = 1000,  -- EU5 town; Muslim until 1232
      names = { spain = "Morella", portugal = "Morella", aragon = "Morella", arabic = "Muriala", european = "Morella", default = "Morella" } },
    { key = "beja", x = 22, y = 120, capital = "Silves", level = 2, population = 7500,  -- extra
      names = { spain = "Beja", portugal = "Beja", aragon = "Beja", arabic = "Baja", european = "Pax Julia", default = "Beja" } },
    { key = "niebla", x = 31, y = 115, capital = "Sevilla", level = 2, population = 7500,  -- extra; former taifa seat
      names = { spain = "Niebla", portugal = "Niebla", aragon = "Niebla", arabic = "Labla", european = "Ilipla", default = "Niebla" } },
    { key = "algeciras", x = 39, y = 107, capital = "Sevilla", level = 2, population = 7500,  -- extra; port; moved 38,107 -> 39,107 (user, 14 Oct, Iberia fix 1)
      names = { spain = "Algeciras", portugal = "Algeciras", aragon = "Algesires", arabic = "al-Jazira al-Khadra", european = "Iulia Traducta", default = "Algeciras" } },
    { key = "denia", x = 77, y = 125, capital = "Murcia", level = 2, population = 7500,  -- extra; port, former taifa seat
      names = { spain = "Denia", portugal = "Dénia", aragon = "Dénia", arabic = "Daniya", european = "Dianium", default = "Denia" } },
    { key = "bilbao", x = 63, y = 157, capital = "Pamplona", ownerFrom = "Burgos", level = 1, population = 500,  -- added (user, 14 Oct, Iberia fix 1); founded 1300 -> 1/500; Biscay under Castile; moved 7 east, 1 north (user, 14 Oct, Italy fix 1)
      names = { spain = "Bilbao", portugal = "Bilbau", aragon = "Bilbao", arabic = "Bilbaw", european = "Bilbaum", default = "Bilbo" } },
    -- ITALY + ISLANDS (user, 14 Oct 2026): all proposed + optional towns, Malta (Mdina), Bonifacio (Corsica)
    { key = "messina", x = 188, y = 120, capital = "Palermo", level = 3, population = 15000,  -- EU5 city; owner sicily; moved 1 south (user, 14 Oct, Italy fix 1)
      names = { sicily = "Messina", papal_states = "Messina", venice = "Messina", pisa = "Messina", hre = "Messina", european = "Messana", greek = "Messíni", arabic = "Massina", middle_eastern = "Mesina", default = "Messina" } },
    { key = "salerno", x = 186, y = 140, capital = "Naples", ownerFrom = "Palermo", level = 2, population = 7500,  -- EU5 town; Roger II's since 1127; owner sicily
      names = { sicily = "Salerno", papal_states = "Salerno", venice = "Salerno", pisa = "Salerno", hre = "Salern", european = "Salernum", greek = "Salérno", arabic = "Salirnu", middle_eastern = "Salerno", default = "Salerno" } },
    { key = "syracuse", x = 186, y = 111, capital = "Palermo", level = 2, population = 7500,  -- EU5 town; owner sicily; moved 1 SW (user, 14 Oct, Italy fix 1)
      names = { sicily = "Siracusa", papal_states = "Siracusa", venice = "Siracusa", pisa = "Siracusa", hre = "Syrakus", european = "Syracusae", greek = "Syrakoúsai", arabic = "Saraqusa", middle_eastern = "Sirakuza", default = "Siracusa" } },
    { key = "taranto", x = 202, y = 138, capital = "Bari", level = 2, population = 7500,  -- EU5 town; owner sicily
      names = { sicily = "Taranto", papal_states = "Taranto", venice = "Taranto", pisa = "Taranto", hre = "Tarent", european = "Tarentum", greek = "Táras", arabic = "Tarant", middle_eastern = "Taranto", default = "Taranto" } },
    { key = "padova", x = 163, y = 172, capital = "Verona", level = 3, population = 15000,  -- EU5 city; owner slave; moved 1 west (user, 14 Oct, Italy fix 1)
      names = { sicily = "Padova", papal_states = "Padova", venice = "Padova", pisa = "Padova", hre = "Padua", european = "Patavium", greek = "Patávion", arabic = "Badwa", middle_eastern = "Padova", default = "Padova" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "pavia", x = 144, y = 171, capital = "Milan", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Pavia", papal_states = "Pavia", venice = "Pavia", pisa = "Pavia", hre = "Pavia", european = "Papia", greek = "Papía", arabic = "Babiya", middle_eastern = "Pavya", default = "Pavia" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "cremona", x = 150, y = 171, capital = "Milan", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Cremona", papal_states = "Cremona", venice = "Cremona", pisa = "Cremona", hre = "Cremona", european = "Cremona", greek = "Kremóna", arabic = "Krimuna", middle_eastern = "Kremona", default = "Cremona" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "lucca", x = 156, y = 160, capital = "Florence", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Lucca", papal_states = "Lucca", venice = "Lucca", pisa = "Lucca", hre = "Lucca", european = "Luca", greek = "Loúka", arabic = "Lukka", middle_eastern = "Lukka", default = "Lucca" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "siena", x = 159, y = 155, capital = "Florence", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Siena", papal_states = "Siena", venice = "Siena", pisa = "Siena", hre = "Siena", european = "Sena", greek = "Siéna", arabic = "Siyena", middle_eastern = "Siyena", default = "Siena" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "brescia", x = 154, y = 173, capital = "Verona", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Brescia", papal_states = "Brescia", venice = "Brescia", pisa = "Brescia", hre = "Brescia", european = "Brixia", greek = "Bríxia", arabic = "Brisha", middle_eastern = "Breşa", default = "Brescia" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "parma", x = 153, y = 167, capital = "Genoa", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Parma", papal_states = "Parma", venice = "Parma", pisa = "Parma", hre = "Parma", european = "Parma", greek = "Párma", arabic = "Barma", middle_eastern = "Parma", default = "Parma" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "ferrara", x = 164, y = 167, capital = "Bologna", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Ferrara", papal_states = "Ferrara", venice = "Ferrara", pisa = "Ferrara", hre = "Ferrara", european = "Ferraria", greek = "Ferrára", arabic = "Farrara", middle_eastern = "Ferrara", default = "Ferrara" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "mantova", x = 157, y = 169, capital = "Verona", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Mantova", papal_states = "Mantova", venice = "Mantova", pisa = "Mantova", hre = "Mantua", european = "Mantua", greek = "Mantoúa", arabic = "Mantuwa", middle_eastern = "Mantova", default = "Mantova" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "perugia", x = 167, y = 155, capital = "Rome", level = 3, population = 15000,  -- EU5 city; owner papal_states
      names = { sicily = "Perugia", papal_states = "Perugia", venice = "Perugia", pisa = "Perugia", hre = "Perugia", european = "Perusia", greek = "Peroúsia", arabic = "Biruja", middle_eastern = "Peruja", default = "Perugia" } },
    { key = "ascoli", x = 176, y = 154, capital = "Ancona", level = 3, population = 15000,  -- EU5 city; owner slave
      names = { sicily = "Ascoli", papal_states = "Ascoli", venice = "Ascoli", pisa = "Ascoli", hre = "Ascoli", european = "Asculum", greek = "Áskoulon", arabic = "Askuli", middle_eastern = "Askoli", default = "Ascoli" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "capua", x = 181, y = 142, capital = "Naples", level = 2, population = 7500,  -- extra; principality capital; owner slave
      names = { sicily = "Capua", papal_states = "Capua", venice = "Capua", pisa = "Capua", hre = "Capua", european = "Capua", greek = "Kapýi", arabic = "Qabuwa", middle_eastern = "Kapua", default = "Capua" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "turin", x = 133, y = 170, capital = "Milan", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Torino", papal_states = "Torino", venice = "Torino", pisa = "Torino", hre = "Turin", european = "Taurinum", greek = "Tavrínon", arabic = "Turinu", middle_eastern = "Torino", default = "Torino" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "modena", x = 157, y = 165, capital = "Florence", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Modena", papal_states = "Modena", venice = "Modena", pisa = "Modena", hre = "Modena", european = "Mutina", greek = "Moutína", arabic = "Mudina", middle_eastern = "Modena", default = "Modena" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "ravenna", x = 167, y = 163, capital = "Bologna", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Ravenna", papal_states = "Ravenna", venice = "Ravenna", pisa = "Ravenna", hre = "Raben", european = "Ravenna", greek = "Rabénna", arabic = "Rafinna", middle_eastern = "Ravenna", default = "Ravenna" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "vicenza", x = 160, y = 173, capital = "Verona", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Vicenza", papal_states = "Vicenza", venice = "Vicenza", pisa = "Vicenza", hre = "Vicenza", european = "Vicetia", greek = "Bikétia", arabic = "Fichensa", middle_eastern = "Viçenza", default = "Vicenza" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "treviso", x = 166, y = 176, capital = "Verona", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Treviso", papal_states = "Treviso", venice = "Treviso", pisa = "Treviso", hre = "Tarvis", european = "Tarvisium", greek = "Tarbísion", arabic = "Tarfiz", middle_eastern = "Treviso", default = "Treviso" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "trani", x = 196, y = 142, capital = "Bari", level = 2, population = 7500,  -- extra; major Apulian port; owner sicily
      names = { sicily = "Trani", papal_states = "Trani", venice = "Trani", pisa = "Trani", hre = "Trani", european = "Turenum", greek = "Tránion", arabic = "Tarani", middle_eastern = "Trani", default = "Trani" } },
    { key = "gaeta", x = 176, y = 144, capital = "Rome", ownerFrom = "Naples", level = 2, population = 7500,  -- EU5 town; independent duchy until 1135; owner slave; moved 1 north (user, 14 Oct, Italy fix 1)
      names = { sicily = "Gaeta", papal_states = "Gaeta", venice = "Gaeta", pisa = "Gaeta", hre = "Gaeta", european = "Caieta", greek = "Kaiéti", arabic = "Ghayta", middle_eastern = "Gaeta", default = "Gaeta" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "trapani", x = 168, y = 118, capital = "Palermo", level = 2, population = 7500,  -- EU5 town; owner sicily
      names = { sicily = "Trapani", papal_states = "Trapani", venice = "Trapani", pisa = "Trapani", hre = "Trapani", european = "Drepanum", greek = "Drépanon", arabic = "Itrabinish", middle_eastern = "Trapani", default = "Trapani" } },
    { key = "girgenti", x = 177, y = 115, capital = "Palermo", level = 2, population = 7500,  -- EU5 town; owner sicily; moved 2 east (user, 14 Oct, Italy fix 1)
      names = { sicily = "Girgenti", papal_states = "Girgenti", venice = "Girgenti", pisa = "Girgenti", hre = "Girgenti", european = "Agrigentum", greek = "Akrágas", arabic = "Kirkint", middle_eastern = "Kirkint", default = "Girgenti" } },
    { key = "viterbo", x = 166, y = 149, capital = "Rome", level = 2, population = 7500,  -- EU5 town; owner papal_states; moved 1 south (user, 14 Oct, Italy fix 1)
      names = { sicily = "Viterbo", papal_states = "Viterbo", venice = "Viterbo", pisa = "Viterbo", hre = "Viterbo", european = "Viterbium", greek = "Biterbo", arabic = "Fitirbu", middle_eastern = "Viterbo", default = "Viterbo" } },
    { key = "arezzo", x = 163, y = 157, capital = "Florence", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Arezzo", papal_states = "Arezzo", venice = "Arezzo", pisa = "Arezzo", hre = "Arezzo", european = "Arretium", greek = "Arrétion", arabic = "Arizzu", middle_eastern = "Arezzo", default = "Arezzo" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "spoleto", x = 170, y = 152, capital = "Rome", level = 2, population = 7500,  -- EU5 town; owner papal_states; moved 1 west (user, 14 Oct, Italy fix 1)
      names = { sicily = "Spoleto", papal_states = "Spoleto", venice = "Spoleto", pisa = "Spoleto", hre = "Spoleto", european = "Spoletium", greek = "Spolítion", arabic = "Isbuliti", middle_eastern = "Spoleto", default = "Spoleto" } },
    { key = "como", x = 142, y = 177, capital = "Milan", level = 2, population = 7500,  -- extra; destroyed by Milan 1127, rebuilt; owner slave
      names = { sicily = "Como", papal_states = "Como", venice = "Como", pisa = "Como", hre = "Como", european = "Comum", greek = "Kómon", arabic = "Kumu", middle_eastern = "Komo", default = "Como" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "sassari", x = 139, y = 139, capital = "Cagliari", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Sassari", papal_states = "Sassari", venice = "Sassari", pisa = "Sassari", hre = "Sassari", european = "Sassaris", greek = "Sássari", arabic = "Sasari", middle_eastern = "Sassari", default = "Sassari" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "oristano", x = 139, y = 133, capital = "Cagliari", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Oristano", papal_states = "Oristano", venice = "Oristano", pisa = "Oristano", hre = "Oristano", european = "Aristianis", greek = "Aristiáni", arabic = "Uristanu", middle_eastern = "Oristano", default = "Oristano" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "lecce", x = 208, y = 134, capital = "Bari", level = 2, population = 7500,  -- EU5 town; owner sicily
      names = { sicily = "Lecce", papal_states = "Lecce", venice = "Lecce", pisa = "Lecce", hre = "Lecce", european = "Lupiae", greek = "Loupíai", arabic = "Litshi", middle_eastern = "Leçe", default = "Lecce" } },
    { key = "foggia", x = 190, y = 144, capital = "Bari", level = 2, population = 7500,  -- EU5 town; owner sicily
      names = { sicily = "Foggia", papal_states = "Foggia", venice = "Foggia", pisa = "Foggia", hre = "Foggia", european = "Fovea", greek = "Fógia", arabic = "Fujja", middle_eastern = "Foca", default = "Foggia" } },
    { key = "lanciano", x = 182, y = 149, capital = "Ancona", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Lanciano", papal_states = "Lanciano", venice = "Lanciano", pisa = "Lanciano", hre = "Lanciano", european = "Anxanum", greek = "Ánxanon", arabic = "Lanshanu", middle_eastern = "Lançano", default = "Lanciano" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "asti", x = 137, y = 169, capital = "Genoa", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Asti", papal_states = "Asti", venice = "Asti", pisa = "Asti", hre = "Asti", european = "Hasta", greek = "Ásti", arabic = "Asti", middle_eastern = "Asti", default = "Asti" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "savona", x = 138, y = 165, capital = "Genoa", level = 2, population = 7500,  -- EU5 town; owner slave; moved 1 west (user, 14 Oct, Italy fix 1)
      names = { sicily = "Savona", papal_states = "Savona", venice = "Savona", pisa = "Savona", hre = "Savona", european = "Savo", greek = "Saóna", arabic = "Safuna", middle_eastern = "Savona", default = "Savona" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "novara", x = 140, y = 173, capital = "Milan", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Novara", papal_states = "Novara", venice = "Novara", pisa = "Novara", hre = "Novara", european = "Novaria", greek = "Nobária", arabic = "Nufara", middle_eastern = "Novara", default = "Novara" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "volterra", x = 155, y = 156, capital = "Pisa", ownerFrom = "Florence", level = 2, population = 7500,  -- EU5 town; bishop city, not Pisan; owner slave
      names = { sicily = "Volterra", papal_states = "Volterra", venice = "Volterra", pisa = "Volterra", hre = "Volterra", european = "Volaterrae", greek = "Ouolatérrai", arabic = "Fultirra", middle_eastern = "Volterra", default = "Volterra" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "urbino", x = 167, y = 159, capital = "Bologna", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Urbino", papal_states = "Urbino", venice = "Urbino", pisa = "Urbino", hre = "Urbino", european = "Urbinum", greek = "Ourbínon", arabic = "Urbinu", middle_eastern = "Urbino", default = "Urbino" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "prato", x = 160, y = 161, capital = "Florence", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { sicily = "Prato", papal_states = "Prato", venice = "Prato", pisa = "Prato", hre = "Prato", european = "Pratum", greek = "Práto", arabic = "Bratu", middle_eastern = "Prato", default = "Prato" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "tivoli", x = 172, y = 147, capital = "Rome", level = 2, population = 7500,  -- EU5 town; owner papal_states
      names = { sicily = "Tivoli", papal_states = "Tivoli", venice = "Tivoli", pisa = "Tivoli", hre = "Tivoli", european = "Tibur", greek = "Tíbour", arabic = "Tibuli", middle_eastern = "Tivoli", default = "Tivoli" } },
    { key = "aquila", x = 176, y = 150, capital = "Ancona", level = 1, population = 500,  -- founded 1254; owner slave
      names = { sicily = "L'Aquila", papal_states = "L'Aquila", venice = "L'Aquila", pisa = "L'Aquila", hre = "Aquila", european = "Aquila", greek = "Ákyla", arabic = "Akila", middle_eastern = "Akila", default = "L'Aquila" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "matera", x = 197, y = 138, capital = "Bari", level = 2, population = 7500,  -- EU5 town; owner sicily
      names = { sicily = "Matera", papal_states = "Matera", venice = "Matera", pisa = "Matera", hre = "Matera", european = "Matheola", greek = "Matéra", arabic = "Matira", middle_eastern = "Matera", default = "Matera" } },
    { key = "potenza", x = 191, y = 136, capital = "Bari", level = 2, population = 7500,  -- EU5 town; owner sicily
      names = { sicily = "Potenza", papal_states = "Potenza", venice = "Potenza", pisa = "Potenza", hre = "Potenza", european = "Potentia", greek = "Potentía", arabic = "Butinsa", middle_eastern = "Potensa", default = "Potenza" } },
    { key = "catanzaro", x = 200, y = 127, capital = "Reggio", level = 2, population = 7500,  -- EU5 town; owner sicily; moved 1 NE (user, 14 Oct, Italy fix 1)
      names = { sicily = "Catanzaro", papal_states = "Catanzaro", venice = "Catanzaro", pisa = "Catanzaro", hre = "Catanzaro", european = "Catacium", greek = "Katantzárion", arabic = "Qatansar", middle_eastern = "Katanzaro", default = "Catanzaro" } },
    { key = "udine", x = 172, y = 176, capital = "Venice", ownerFrom = "Verona", level = 1, population = 1000,  -- castle in 1132; re-added as rebels, 2 south of its first tile (user, 14 Oct, Italy fix 2); Venice_Province like Trieste
      names = { sicily = "Udine", papal_states = "Udine", venice = "Udine", pisa = "Udine", hre = "Weiden", european = "Utinum", greek = "Oúdine", arabic = "Udini", middle_eastern = "Udine", default = "Udine" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },
    { key = "malta", x = 181, y = 104, capital = "Palermo", level = 1, population = 1000, castle = true,  -- Malta, castle (user, 14 Oct, Italy fix 1); Mdina; size doubtful; Malta tiles are woodland; owner sicily
      names = { default = "Malta", european = "Malta", greek = "Malta", arabic = "Malta", middle_eastern = "Malta" } },
    { key = "bonifacio", x = 144, y = 145, capital = "Cagliari", level = 1, population = 1000,  -- castle town, founded 828; owner slave
      names = { sicily = "Bonifacio", papal_states = "Bonifacio", venice = "Bonifacio", pisa = "Bonifacio", hre = "Bonifacio", european = "Bonifacium", greek = "Bonifátsio", arabic = "Bunifasyu", middle_eastern = "Bonifacio", default = "Bonifacio" },
      rebels = { "Urban Spear Militia", "Urban Spear Militia" } },    -- France (14 Oct 2026): EU5 #France block, user: hre-territory towns owned by hre; French names, Latin for european
    { key = "amiens", x = 94, y = 203, capital = "Paris", level = 2, population = 7500,  -- EU5 town; owner france
      names = { france = "Amiens", england = "Amiens", hre = "Amiens", european = "Ambianum", default = "Amiens" } },
    { key = "chartres", x = 88, y = 194, capital = "Paris", level = 2, population = 7500,  -- EU5 town; Blois-Champagne, vassal; owner france
      names = { france = "Chartres", england = "Chartres", hre = "Chartres", european = "Carnutum", default = "Chartres" } },
    { key = "chalons", x = 107, y = 198, capital = "Rheims", level = 2, population = 7500,  -- EU5 town; owner france
      names = { france = "Châlons", england = "Châlons", hre = "Châlons", european = "Catalaunum", default = "Châlons" } },
    { key = "laon", x = 100, y = 201, capital = "Rheims", level = 2, population = 7500,  -- EU5 town; royal; owner france; moved 1 south 2 west (user, 14 Oct, France fix 1)
      names = { france = "Laon", england = "Laon", hre = "Laon", european = "Laudunum", default = "Laon" } },
    { key = "blois", x = 87, y = 188, capital = "Orleans", level = 2, population = 7500,  -- EU5 town; owner france
      names = { france = "Blois", england = "Blois", hre = "Blois", european = "Blesae", default = "Blois" } },
    { key = "bourges", x = 94, y = 184, capital = "Orleans", level = 2, population = 7500,  -- EU5 town; royal since 1101; owner france
      names = { france = "Bourges", england = "Bourges", hre = "Bourges", european = "Bituricae", default = "Bourges" } },
    { key = "caen", x = 74, y = 199, capital = "Rouen", level = 2, population = 7500,  -- EU5 town; Normandy; owner england
      names = { france = "Caen", england = "Caen", hre = "Caen", european = "Cadomum", default = "Caen" } },
    { key = "cherbourg", x = 66, y = 202, capital = "Rouen", level = 1, population = 1000,  -- EU5 town, small in 1132 -> 1/1000; owner england
      names = { france = "Cherbourg", england = "Cherbourg", hre = "Cherbourg", european = "Caesaris Burgus", default = "Cherbourg" } },
    { key = "tours", x = 82, y = 186, capital = "Angers", level = 3, population = 15000,  -- EU5 city; Touraine Angevin; owner england
      names = { france = "Tours", england = "Tours", hre = "Tours", european = "Turones", default = "Tours" } },
    { key = "nantes", x = 65, y = 185, capital = "Rennes", level = 2, population = 7500,  -- EU5 town; Brittany; owner slave
      names = { france = "Nantes", england = "Nantes", hre = "Nantes", european = "Namnetes", default = "Nantes" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "angouleme", x = 78, y = 173, capital = "Poitiers", level = 2, population = 7500,  -- EU5 town; Aquitaine; owner slave
      names = { france = "Angoulême", england = "Angoulême", hre = "Angoulême", european = "Engolisma", default = "Angoulême" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "la_rochelle", x = 71, y = 177, capital = "Poitiers", level = 1, population = 1000,  -- EU5 town; charter c. 1137 -> 1/1000; owner slave
      names = { france = "La Rochelle", england = "La Rochelle", hre = "La Rochelle", european = "Rupella", default = "La Rochelle" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "agen", x = 82, y = 164, capital = "Bordeaux", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { france = "Agen", england = "Agen", hre = "Agen", european = "Aginnum", default = "Agen" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "perigueux", x = 82, y = 171, capital = "Bordeaux", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { france = "Périgueux", england = "Périgueux", hre = "Périgueux", european = "Petrocorii", default = "Périgueux" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "tarbes", x = 78, y = 158, capital = "Bordeaux", level = 1, population = 1000,  -- EU5 town, small in 1132 -> 1/1000; Bigorre; owner slave
      names = { france = "Tarbes", england = "Tarbes", hre = "Tarbes", european = "Tarba", default = "Tarbes" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "bayonne", x = 68, y = 158, capital = "Pamplona", level = 2, population = 7500,  -- EU5 town; Labourd; Pamplona region; owner slave
      names = { france = "Bayonne", england = "Bayonne", hre = "Bayonne", european = "Baiona", default = "Bayonne" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "albi", x = 93, y = 162, capital = "Toulouse", level = 2, population = 7500,  -- EU5 town; Trencavel; owner slave
      names = { france = "Albi", england = "Albi", hre = "Albi", european = "Albiga", default = "Albi" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "cahors", x = 86, y = 164, capital = "Toulouse", level = 2, population = 7500,  -- EU5 town; owner slave
      names = { france = "Cahors", england = "Cahors", hre = "Cahors", european = "Cadurcum", default = "Cahors" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "carcassonne", x = 94, y = 157, capital = "Toulouse", level = 2, population = 7500,  -- EU5 town; Trencavel; owner slave
      names = { france = "Carcassonne", england = "Carcassonne", hre = "Carcassonne", european = "Carcaso", default = "Carcassonne" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "narbonne", x = 99, y = 157, capital = "Toulouse", level = 3, population = 15000,  -- EU5 city; viscounty; owner slave
      names = { france = "Narbonne", england = "Narbonne", hre = "Narbonne", european = "Narbo", default = "Narbonne" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "montpellier", x = 103, y = 160, capital = "Toulouse", level = 3, population = 15000,  -- EU5 city; Guilhem lords; 1 west of GPS for spacing; owner slave
      names = { france = "Montpellier", england = "Montpellier", hre = "Montpellier", european = "Mons Pessulanus", default = "Montpellier" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "rodez", x = 96, y = 166, capital = "Clermont", level = 2, population = 7500,  -- EU5 town; Rouergue; owner slave
      names = { france = "Rodez", england = "Rodez", hre = "Rodez", european = "Ruteni", default = "Rodez" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "le_puy", x = 108, y = 173, capital = "Lyon", level = 2, population = 7500,  -- EU5 town; Lyon_Province -> hre (user, 14 Oct); moved 1 NW (user, 14 Oct, France fix 1)
      names = { france = "Le Puy", england = "Le Puy", hre = "Le Puy", european = "Anicium", default = "Le Puy" } },
    { key = "autun", x = 107, y = 182, capital = "Dijon", level = 2, population = 7500,  -- EU5 town; Burgundy; owner slave; moved 1 SW (user, 14 Oct, France fix 1)
      names = { france = "Autun", england = "Autun", hre = "Autun", european = "Augustodunum", default = "Autun" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "arras", x = 96, y = 207, capital = "Ghent", level = 3, population = 15000,  -- EU5 city; Flanders; owner slave; moved 1 west (user, 14 Oct, France fix 1)
      names = { france = "Arras", england = "Arras", hre = "Arras", european = "Atrebatum", default = "Arras" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "calais", x = 91, y = 212, capital = "Ghent", level = 1, population = 500,  -- replaces Saint-Omer, 2 NW of its tile (user, 14 Oct, France fix 1); village, charter 1181 -> 1/500; owner slave
      names = { france = "Calais", england = "Calais", hre = "Calais", european = "Caletum", default = "Calais" },
      rebels = { "Spear Militia", "Spear Militia" } },
    { key = "besancon", x = 121, y = 186, capital = "Lyon", level = 2, population = 7500,  -- EU5 town; County of Burgundy; owner hre
      names = { france = "Besançon", england = "Besançon", hre = "Bisanz", european = "Vesontio", default = "Besançon" } },
    { key = "valence", x = 112, y = 169, capital = "Lyon", level = 2, population = 7500,  -- EU5 town; Kingdom of Arles; owner hre
      names = { france = "Valence", england = "Valence", hre = "Valence", european = "Valentia", default = "Valence" } },
    { key = "avignon", x = 112, y = 163, capital = "Arles", level = 2, population = 7500,  -- EU5 town; Provence; owner hre
      names = { france = "Avignon", england = "Avignon", hre = "Avignon", european = "Avenio", default = "Avignon" } },
    { key = "marseille", x = 117, y = 159, capital = "Arles", level = 3, population = 15000,  -- EU5 city; Provence; owner hre
      names = { france = "Marseille", england = "Marseille", hre = "Marseille", european = "Massilia", default = "Marseille" } },
    { key = "sisteron", x = 119, y = 165, capital = "Arles", level = 1, population = 1000,  -- EU5 town, small in 1132 -> 1/1000; Provence; owner hre
      names = { france = "Sisteron", england = "Sisteron", hre = "Sisteron", european = "Segustero", default = "Sisteron" } },
    -- British Isles (14 Oct 2026): EU5 # britain / # ireland blocks only (user: 'just A'); English names for england /
    -- scotland, Irish Gaelic default for the Irish rebel towns, Latin for european; Irish garrison 2 Irish Kerns (user)
    { key = "coventry", x = 67, y = 223, capital = "Lincoln", level = 2, population = 7500,  -- EU5 town; owner england
      names = { england = "Coventry", scotland = "Coventry", european = "Conventria", default = "Coventry" } },
    { key = "oxford", x = 68, y = 217, capital = "London", level = 2, population = 7500,  -- EU5 town; owner england
      names = { england = "Oxford", scotland = "Oxford", european = "Oxonia", default = "Oxford" } },
    { key = "cambridge", x = 79, y = 221, capital = "Norwich", level = 2, population = 7500,  -- EU5 town; owner england
      names = { england = "Cambridge", scotland = "Cambridge", european = "Cantabrigia", default = "Cambridge" } },
    { key = "salisbury", x = 64, y = 213, capital = "Bristol", level = 2, population = 7500,  -- EU5 'salisbury'; tile of Old Sarum (New Sarum founded 1220); owner england
      names = { england = "Salisbury", scotland = "Salisbury", european = "Sarisberia", default = "Salisbury" } },
    { key = "colchester", x = 84, y = 219, capital = "Norwich", level = 2, population = 7500,  -- EU5 town; owner england
      names = { england = "Colchester", scotland = "Colchester", european = "Colecestria", default = "Colchester" } },
    { key = "lynn", x = 83, y = 223, capital = "Norwich", level = 1, population = 1000,  -- EU5 town; Bishop's Lynn founded c.1100, small -> 1/1000; 3 east of GPS for spacing; owner england
      names = { england = "Lynn", scotland = "Lynn", european = "Lenna", default = "Lynn" } },
    { key = "boston", x = 77, y = 228, capital = "Lincoln", level = 1, population = 1000,  -- EU5 town; small in 1132 -> 1/1000; owner england
      names = { england = "Boston", scotland = "Boston", european = "Villa Sancti Botulfi", default = "Boston" } },
    { key = "perth", x = 55, y = 251, capital = "Edinburgh", level = 2, population = 7500,  -- EU5 town; burgh by c.1127; owner scotland
      names = { england = "Perth", scotland = "Perth", european = "Perthum", default = "Perth" } },
    { key = "berwick", x = 64, y = 246, capital = "Edinburgh", level = 2, population = 7500,  -- EU5 town; burgh c.1120; owner scotland
      names = { england = "Berwick", scotland = "Berwick", european = "Berwicum", default = "Berwick" } },
    { key = "inverness", x = 48, y = 259, capital = "Aberdeen", level = 1, population = 1000,  -- EU5 town; castle, burgh later -> 1/1000; owner scotland
      names = { england = "Inverness", scotland = "Inverness", european = "Invernessia", default = "Inverness" } },
    { key = "cork", x = 17, y = 219, capital = "Dublin", level = 2, population = 7500,  -- EU5 town; Norse town; owner slave
      names = { england = "Cork", scotland = "Cork", european = "Corcagia", default = "Corcaigh" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
    { key = "waterford", x = 26, y = 221, capital = "Dublin", level = 2, population = 7500,  -- EU5 town; Norse town; owner slave
      names = { england = "Waterford", scotland = "Waterford", european = "Waterfordia", default = "Port Láirge" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
    { key = "wexford", x = 31, y = 222, capital = "Dublin", level = 2, population = 7500,  -- EU5 town; Norse town; owner slave
      names = { england = "Wexford", scotland = "Wexford", european = "Wexfordia", default = "Loch Garman" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
    { key = "limerick", x = 16, y = 224, capital = "Dublin", level = 2, population = 7500,  -- EU5 town; Norse town, O'Brien seat; owner slave
      names = { england = "Limerick", scotland = "Limerick", european = "Limericum", default = "Luimneach" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
    { key = "galway", x = 11, y = 227, capital = "Dublin", level = 1, population = 1000,  -- EU5 town; fort of 1124, small -> 1/1000; owner slave
      names = { england = "Galway", scotland = "Galway", european = "Galvia", default = "Gaillimh" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
    { key = "new_ross", x = 27, y = 225, capital = "Dublin", level = 1, population = 500,  -- EU5 town; founded c.1200 -> 1/500; owner slave
      names = { england = "New Ross", scotland = "New Ross", european = "Rossa Nova", default = "Ros Mhic Thriúin" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
    { key = "sligo", x = 17, y = 236, capital = "Dublin", level = 1, population = 500,  -- EU5 town; founded 1245 -> 1/500; owner slave
      names = { england = "Sligo", scotland = "Sligo", european = "Sligonia", default = "Sligeach" },
      rebels = { "Irish Kerns", "Irish Kerns" } },
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
    poland    = { "EE Spear Militia", "EE Spear Militia" },   -- Poland + Baltic: cheapest militia (14 Oct)
    lithuania = { "EE Spear Militia", "EE Spear Militia" },   -- Poland + Baltic: cheapest militia (14 Oct)
    hungary   = { "EE Spear Militia", "EE Spear Militia" },   -- hungary has no "Spear Militia" ownership in export_descr_unit.txt, only EE (user caught it, 15 Oct)
    hre       = { "Spear Militia", "Spear Militia" },         -- Hungary + Croatia: cheapest militia (user, 15 Oct); hre IS in Spear Militia's ownership list, verified
    spain     = { "Spear Militia", "Spear Militia" },         -- Iberia: cheapest spear militia (14 Oct)
    portugal  = { "Spear Militia", "Spear Militia" },         -- Iberia (14 Oct)
    aragon    = { "Spear Militia", "Spear Militia" },         -- Iberia (14 Oct)
    sicily = { "Urban Spear Militia", "Urban Spear Militia" },   -- Italy: no plain Spear Militia for Italian factions (user, 14 Oct)
    papal_states = { "Urban Spear Militia", "Urban Spear Militia" },   -- Italy: no plain Spear Militia for Italian factions (user, 14 Oct)
    venice = { "Urban Spear Militia", "Urban Spear Militia" },   -- Italy: no plain Spear Militia for Italian factions (user, 14 Oct)
    france  = { "Spear Militia", "Spear Militia" },          -- France: cheapest spear militia (14 Oct)
    england = { "Spear Militia", "Spear Militia" },          -- France (Normandy, Anjou) (14 Oct)
    scotland = { "Spear Militia", "Spear Militia" },         -- British Isles: cheapest spear militia (14 Oct)
    pisa = { "Urban Spear Militia", "Urban Spear Militia" },   -- Italy: no plain Spear Militia for Italian factions (user, 14 Oct)
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
local DUMP_PATHS = {    -- Balkans + Lycian coast, Poland + Baltic (14 Oct 2026)
    { "Milas-Attaleia coast", 276, 116, 297, 114 }, { "Corinth-Monemvasia", 242, 118, 241, 112 }, { "Corinth-Patras", 242, 118, 233, 120 },
    { "Ras-Skopje", 231, 153, 233, 148 }, { "Sredets-Nis", 247, 152, 237, 155 }, { "Nis(Belgrade)-Branicevo", 228, 168, 235, 166 },
    { "Tarnovo-Drastar", 262, 156, 274, 163 }, { "Skadar-Kotor", 218, 149, 213, 152 }, { "Durazzo-Valona", 218, 142, 219, 137 },
    { "Thessalonica-Ohrid", 243, 139, 230, 145 }, { "Arta-Ioannina", 229, 128, 225, 132 },
    { "Poznan-Gniezno", 198, 222, 204, 223 }, { "Poznan-Torun", 198, 222, 213, 226 }, { "Plock-Warsaw", 226, 224, 230, 222 },
    { "Krakow-Sandomierz", 218, 208, 236, 211 }, { "Krakow-Lublin", 218, 208, 241, 215 }, { "Wroclaw-Opole", 199, 214, 207, 210 }, { "Wroclaw-Legnica", 199, 214, 194, 214 },
    { "Szczecin-Wolin", 180, 231, 184, 231 }, { "Szczecin-Wolgast", 180, 231, 176, 234 }, { "Gdansk-Slupsk", 212, 235, 200, 237 },
    { "Kernave-Kaunas", 250, 242, 246, 238 }, { "Kolyvan-Tartu", 255, 273, 270, 265 }, { "Riga-Koknese", 253, 256, 260, 252 },
    { "Polotsk-Jersika", 282, 244, 265, 250 }, { "Lubeck-Stralsund", 155, 233, 170, 237 },
    { "Szekesfehervar-Buda", 211, 185, 216, 185 }, { "Buda-Pest", 216, 185, 218, 185 },
    { "Esztergom-Bratislava", 226, 194, 203, 194 },
    { "Esztergom-Kosice", 226, 194, 234, 197 }, { "Esztergom-Krupina", 226, 194, 221, 194 },
    { "Szekesfehervar-Pecs", 211, 185, 211, 178 }, { "Szekesfehervar-Sopron", 211, 185, 202, 188 },
    { "Varad-Szeged", 236, 183, 226, 179 }, { "Zagreb-Knin", 193, 175, 192, 164 },
    { "Freiberg-Rijeka", 180, 182, 181, 173 }, { "Rijeka-Trieste", 181, 173, 176, 175 },
    -- Romania (14 Oct 2026)
    { "Gyulafehervar-Cluj", 249, 179, 249, 183 }, { "Gyulafehervar-Sibiu", 249, 179, 253, 177 }, { "Gyulafehervar-Brasov", 249, 179, 263, 177 },
    { "Gyulafehervar-Bistrita", 249, 179, 256, 186 }, { "Gyulafehervar-SatuMare", 249, 179, 245, 189 }, { "Sibiu-Sighisoara", 253, 177, 258, 179 },
    { "Varad-Arad", 236, 183, 233, 178 }, { "Varad-Timisoara", 236, 183, 233, 175 },
    { "Severin-Craiova", 264, 168, 251, 165 }, { "Severin-Arges", 264, 168, 254, 170 },
    { "Severin-Bucharest", 264, 168, 266, 165 }, { "Severin-Braila", 264, 168, 278, 172 },
    { "Halych-Suceava", 262, 200, 268, 189 }, { "Halych-Hotin", 262, 200, 271, 196 },
    { "Iasi-Barlad", 277, 185, 277, 178 }, { "Iasi-CetateaAlba", 277, 185, 293, 178 }, { "Iasi-Chilia", 277, 185, 287, 173 },
    { "Drastar-Isaccea", 274, 163, 283, 171 }, { "Drastar-Constanta", 274, 163, 283, 163 },
    -- Iberia (14 Oct 2026)
    { "Valladolid-salamanca", 35, 140, 31, 138 },
    { "Burgos-segovia", 51, 150, 46, 142 },
    { "Leon-zamora", 37, 152, 37, 145 },
    { "Burgos-santander", 51, 150, 51, 157 },
    { "Leon-oviedo", 37, 152, 31, 158 },
    { "Leon-lugo", 37, 152, 23, 155 },
    { "Toledo-talavera", 49, 134, 43, 134 },
    { "Zaragoza-calatayud", 71, 145, 66, 143 },
    { "Zaragoza-huesca", 71, 145, 74, 149 },
    { "Barcelona-girona", 92, 144, 97, 148 },
    { "Zaragoza-tarragona", 71, 145, 86, 143 },
    { "Burgos-soria", 51, 150, 59, 145 },
    { "Coimbra-viseu", 18, 135, 21, 138 },
    { "Coimbra-porto", 18, 135, 16, 143 },
    { "Coimbra-braga", 18, 135, 17, 146 },
    { "Coimbra-guimaraes", 18, 135, 20, 144 },
    { "Granada-malaga", 51, 114, 45, 111 },
    { "Granada-almeria", 51, 114, 62, 113 },
    { "Cordoba-jaen", 43, 119, 50, 120 },
    { "Murcia-orihuela", 69, 121, 72, 122 },
    { "Badajoz-caceres", 28, 126, 32, 130 },
    { "Lisbon-evora", 11, 125, 20, 124 },
    { "Lisbon-santarem", 11, 125, 15, 129 },
    { "Zaragoza-lleida", 71, 145, 82, 145 },
    { "Zaragoza-tortosa", 71, 145, 81, 140 },
    { "Toledo-cuenca", 49, 134, 61, 134 },
    { "Zaragoza-morella", 71, 145, 76, 141 },
    { "Silves-beja", 19, 114, 22, 120 },
    { "Sevilla-niebla", 36, 114, 31, 115 },
    { "Sevilla-algeciras", 36, 114, 39, 107 },
    { "Murcia-denia", 69, 121, 77, 125 },
    { "Burgos-bilbao", 51, 150, 63, 157 },
    -- Italy + islands (14 Oct 2026)
    { "Venice-udine", 168, 173, 172, 176 },
    { "Palermo-messina", 173, 119, 188, 120 },
    { "Naples-salerno", 182, 139, 186, 140 },
    { "Palermo-syracuse", 173, 119, 186, 111 },
    { "Bari-taranto", 199, 141, 202, 138 },
    { "Verona-padova", 157, 172, 163, 172 },
    { "Milan-pavia", 144, 174, 144, 171 },
    { "Milan-cremona", 144, 174, 150, 171 },
    { "Florence-lucca", 160, 158, 156, 160 },
    { "Florence-siena", 160, 158, 159, 155 },
    { "Verona-brescia", 157, 172, 154, 173 },
    { "Genoa-parma", 142, 166, 153, 167 },
    { "Bologna-ferrara", 161, 166, 164, 167 },
    { "Verona-mantova", 157, 172, 157, 169 },
    { "Rome-perugia", 169, 146, 167, 155 },
    { "Ancona-ascoli", 174, 159, 176, 154 },
    { "Naples-capua", 182, 139, 181, 142 },
    { "Milan-turin", 144, 174, 133, 170 },
    { "Florence-modena", 160, 158, 157, 165 },
    { "Bologna-ravenna", 161, 166, 167, 163 },
    { "Verona-vicenza", 157, 172, 160, 173 },
    { "Verona-treviso", 157, 172, 166, 176 },
    { "Bari-trani", 199, 141, 196, 142 },
    { "Rome-gaeta", 169, 146, 176, 144 },
    { "Palermo-trapani", 173, 119, 168, 118 },
    { "Palermo-girgenti", 173, 119, 177, 115 },
    { "Rome-viterbo", 169, 146, 166, 149 },
    { "Florence-arezzo", 160, 158, 163, 157 },
    { "Rome-spoleto", 169, 146, 170, 152 },
    { "Milan-como", 144, 174, 142, 177 },
    { "Cagliari-sassari", 142, 129, 139, 139 },
    { "Cagliari-oristano", 142, 129, 139, 133 },
    { "Bari-lecce", 199, 141, 208, 134 },
    { "Bari-foggia", 199, 141, 190, 144 },
    { "Ancona-lanciano", 174, 159, 182, 149 },
    { "Genoa-asti", 142, 166, 137, 169 },
    { "Genoa-savona", 142, 166, 138, 165 },
    { "Milan-novara", 144, 174, 140, 173 },
    { "Pisa-volterra", 153, 159, 155, 156 },
    { "Bologna-urbino", 161, 166, 167, 159 },
    { "Florence-prato", 160, 158, 160, 161 },
    { "Rome-tivoli", 169, 146, 172, 147 },
    { "Ancona-aquila", 174, 159, 176, 150 },
    { "Bari-matera", 199, 141, 197, 138 },
    { "Bari-potenza", 199, 141, 191, 136 },
    { "Reggio-catanzaro", 192, 120, 200, 127 },
    { "Palermo-malta", 173, 119, 181, 104 },
    { "Cagliari-bonifacio", 142, 129, 144, 145 },
    -- France (14 Oct 2026)
    { "Paris-amiens", 94, 198, 94, 203 },
    { "Paris-chartres", 94, 198, 88, 194 },
    { "Rheims-chalons", 105, 201, 107, 198 },
    { "Rheims-laon", 105, 201, 100, 201 },
    { "Orleans-blois", 91, 190, 87, 188 },
    { "Orleans-bourges", 91, 190, 94, 184 },
    { "Rouen-caen", 85, 202, 74, 199 },
    { "Rouen-cherbourg", 85, 202, 66, 202 },
    { "Angers-tours", 73, 187, 82, 186 },
    { "Rennes-nantes", 66, 192, 65, 185 },
    { "Poitiers-angouleme", 80, 180, 78, 173 },
    { "Poitiers-la_rochelle", 80, 180, 71, 177 },
    { "Bordeaux-agen", 72, 169, 82, 164 },
    { "Bordeaux-perigueux", 72, 169, 82, 171 },
    { "Bordeaux-tarbes", 72, 169, 78, 158 },
    { "Pamplona-bayonne", 66, 153, 68, 158 },
    { "Toulouse-albi", 88, 159, 93, 162 },
    { "Toulouse-cahors", 88, 159, 86, 164 },
    { "Toulouse-carcassonne", 88, 159, 94, 157 },
    { "Toulouse-narbonne", 88, 159, 99, 157 },
    { "Toulouse-montpellier", 88, 159, 103, 160 },
    { "Clermont-rodez", 98, 176, 96, 166 },
    { "Lyon-le_puy", 113, 174, 108, 173 },
    { "Dijon-autun", 115, 186, 107, 182 },
    { "Ghent-arras", 103, 211, 96, 207 },
    { "Ghent-calais", 103, 211, 91, 212 },
    { "Lyon-besancon", 113, 174, 121, 186 },
    { "Lyon-valence", 113, 174, 112, 169 },
    { "Arles-avignon", 110, 160, 112, 163 },
    { "Arles-marseille", 110, 160, 117, 159 },
    { "Turin-Valais pass", 133, 170, 128, 178 }, { "Turin-Lake Geneva", 133, 170, 129, 180 }, { "Turin-Lyon", 133, 170, 113, 174 },
    { "Arles-sisteron", 110, 160, 119, 165 },
    -- British Isles (14 Oct 2026)
    { "Lincoln-coventry", 74, 228, 67, 223 },
    { "London-oxford", 77, 216, 68, 217 },
    { "Norwich-cambridge", 87, 224, 79, 221 },
    { "Bristol-salisbury", 58, 215, 64, 213 },
    { "Norwich-colchester", 87, 224, 84, 219 },
    { "Norwich-lynn", 87, 224, 83, 223 },
    { "Lincoln-boston", 74, 228, 77, 228 },
    { "Edinburgh-perth", 57, 248, 55, 251 },
    { "Edinburgh-berwick", 57, 248, 64, 246 },
    { "Aberdeen-inverness", 61, 256, 48, 259 },
    { "Dublin-cork", 32, 229, 17, 219 },
    { "Dublin-waterford", 32, 229, 26, 221 },
    { "Dublin-wexford", 32, 229, 31, 222 },
    { "Dublin-limerick", 32, 229, 16, 224 },
    { "Dublin-galway", 32, 229, 11, 227 },
    { "Dublin-new_ross", 32, 229, 27, 225 },
    { "Dublin-sligo", 32, 229, 17, 236 },
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
