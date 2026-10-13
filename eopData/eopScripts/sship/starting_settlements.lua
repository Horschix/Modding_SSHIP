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
      rebels = { "Armenians of Celicia", "Armenians of Celicia" } },
}

-- starting garrison by owner faction (user, 13 Oct 2026); rebels use the entry's own list
local GARRISON = {
    byzantium = { "Contaratoi", "Contaratoi" },
    rum       = { "Ahdath Militia", "Ahdath Militia" },
}

local CORE_LEVEL = { [1] = "wooden_pallisade", [2] = "wooden_wall", [3] = "stone_wall",
                     [4] = "large_stone_wall", [5] = "huge_stone_wall" }

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
local UNHINTERLAND_CHAINS = { "hinterland_roads", "hinterland_farms", "hinterland_mines" }
-- TEMPORARY check (13 Oct 2026): what the game lets these settlements build next. Logged once per map load.
local CHECK_SETTS  = {}   -- was { "hxstart_bursa", "Nicaea" }: check done (13 Oct 2026), switched off
local CHECK_CHAINS = { "hinterland_roads", "hinterland_farms", "builders", "water_supply", "hinterland_mines",
                       "temple_orthodox", "market", "city_hall", "port", "barracks", "landowners" }
local EUROPEAN = { northern_european = true, southern_european = true, eastern_european = true }

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

function SS.onMapLoaded(why)
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
    local capital = settlementByName(entry.capital)
    local owner = get(capital, "ownerFaction")
    if owner == nil then log(name .. ": no owner found (capital " .. entry.capital .. ") - skipped"); return end
    local okFree, free = pcall(function() return M2TWEOP.isTileFree(entry.x, entry.y) end)
    local okAdd, sett = pcall(function() return owner:addSettlement(entry.x, entry.y, name, entry.level, false) end)
    if not okAdd or sett == nil then
        log(name .. ": addSettlement failed at " .. entry.x .. "," .. entry.y .. " (" .. tostring(sett)
            .. "), tile free " .. tostring(okFree and free))
        return
    end
    local fid = get(owner, "factionID")
    pcall(function() sett.creatorFactionID = fid end)
    pcall(function() sett.subFactionID = fid end)
    -- the wall building that belongs to the level (none for a village)
    local core = CORE_LEVEL[entry.level]
    local coreNote = "none"
    if core ~= nil then
        local okHas, has = pcall(function() return sett:buildingPresent("core_building") end)
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
