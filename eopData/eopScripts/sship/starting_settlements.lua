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
local SETTS = {
    {
        key = "bursa", x = 285, y = 136, capital = "Nicaea", level = 3, population = 15000,
        names = { greek = "Proúsa", middle_eastern = "Bursa", european = "Prusa" },
    },
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
-- TEMPORARY check (13 Oct 2026): what the game lets these settlements build next. Logged once per map load.
local CHECK_SETTS  = { "hxstart_bursa", "Nicaea" }
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
    if fname == nil or fname == "slave" then return nil end
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

function SS.onMapLoaded(why)
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
end

StartingSettlements = SS
SS.SETTS = SETTS

return SS
