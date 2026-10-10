--[[
    Recruitment costs population - SSHIP version
    (ported 10 Oct 2026 from the EUR script, Horschix/Modding_DAC-EUR issue #5;
    the EUR original is in that repo: eopData/eopScripts/eur/campaign/population_recruitment.lua)

    RULES
      Queue a unit            -> the settlement loses the unit's soldiers (1:1)
      Cancel it               -> the settlement gets back what was taken
      Retrain a unit          -> only the missing soldiers are taken
      Disband a unit (player) -> its current soldiers go to a settlement:
                                   standing in one of your settlements -> that one
                                   elsewhere in a region whose main settlement
                                   is yours                            -> the main one
                                   foreign region, at sea, on a ship   -> lost
      Too few people          -> the unit is greyed out in the recruitment
                                 panel (its stock is withheld, see BLOCKING)
      "Too few" means the settlement would fall below
          PLAYER_MINIMUM  for the player
          AI_MINIMUM      for every AI faction

    NUMBERS
      Soldiers are counted WITHOUT officers at every step (Orc Host = 240,
      although the queue and the unit card say 243). Unit types have 0-3
      officers; leaving them out everywhere keeps queue, cancel and disband
      in balance.

    FREE (never charged, blocked or refunded)
      agents, ships, generals' bodyguards and SSHIP's script-only
      "Garrison ..." units (Garrison spear, sword, archers, crossbowmen).
      Siege engines and elephants cost their crew like any other unit.

    HOW IT IS LOADED
      Last lines of eopData/eopScripts/luaPluginScript.lua:
          require('sship.population_recruitment')
      It must come AFTER require('sship.main'): the script wraps event
      functions that SSHIP's main.lua defines, including the two save/load
      functions.

    SAVEGAMES
      Withheld stock and the charges of queued units are stored with each save
      (file populationRecruitment.lua inside the EOP save data).

    REMOVE
      Delete the require line. Stock that is withheld at that moment stays
      away in old saves until it refills by itself.
]]

local PR = {}

------------------------------------------------------------------------
-- Settings
------------------------------------------------------------------------
local PLAYER_MINIMUM = 400     -- provisional technical minimum for the player
local AI_MINIMUM     = 1000    -- AI settlements never recruit below this
local LOG_PLAYER     = true    -- log every change in player settlements
local LOG_AI         = false   -- same for AI settlements (large log)

-- Unit types that cost no people, besides the rules in isExempt(). Lower
-- case, exact type names from export_descr_unit.txt. Empty for SSHIP.
local EXEMPT_TYPES = {}

local CATEGORY_SHIP = 4        -- unitCategory enum of the engine

local SAVE_FILE = "populationRecruitment.lua"

------------------------------------------------------------------------
-- State that goes into the savegame
------------------------------------------------------------------------
-- parked[settlementName][eduIndex]  = stock withheld from that unit
-- charges[settlementName]           = list of { key = "...", men = n }
--                                     for the entries now in the queue
local state = { parked = {}, charges = {} }

local function resetState()
    state = { parked = {}, charges = {} }
end

------------------------------------------------------------------------
-- Safe helpers (a wrong field name must never crash the game)
------------------------------------------------------------------------
local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function path(obj, ...)
    local keys = { ... }
    for i = 1, #keys do
        obj = get(obj, keys[i])
        if obj == nil then return nil end
    end
    return obj
end

local function s(value)
    if value == nil then return "nil" end
    return tostring(value)
end

-- M2TWEOP does not exist yet while this file is loaded at game start
local function rawLog(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("POPREC " .. tostring(text))
    end
end

local function isPlayerFaction(faction)
    return get(faction, "isPlayerControlled") == 1
end

local function log(sett, text)
    local player = isPlayerFaction(get(sett, "ownerFaction"))
    if (player and LOG_PLAYER) or (not player and LOG_AI) then rawLog(text) end
end

local function minimumFor(sett)
    if isPlayerFaction(get(sett, "ownerFaction")) then return PLAYER_MINIMUM end
    return AI_MINIMUM
end

------------------------------------------------------------------------
-- Unit sizes (soldiers without officers)
------------------------------------------------------------------------
-- soldiers of a full unit = floor(soldiers in the unit file * size factor).
-- The factor depends on the unit-size setting. It is learned from real units
-- (trained, disbanded, retrained); 2.5 (huge) is assumed until the first one.
local fullSoldiers = {}        -- fullSoldiers[eduIndex], seen on a real unit
local sizeFactor = 2.5
local factorSeen = false

local function isBodyguard(edu)
    return get(edu, "generalUnit") == true or get(edu, "generalUnit") == 1
        or string.find(string.lower(s(get(edu, "eduType"))), "bodyguard", 1, true) ~= nil
end

local function isExempt(edu)
    if edu == nil then return true end
    local category = get(edu, "category")
    if category == CATEGORY_SHIP then return true end
    local name = string.lower(s(get(edu, "eduType")))
    if EXEMPT_TYPES[name] then return true end
    if string.sub(name, 1, 9) == "garrison " then return true end
    return isBodyguard(edu)
end

local function learnFromUnit(unit)
    local edu = get(unit, "eduEntry")
    local index, full = get(edu, "index"), get(unit, "soldierCountStratMapMax")
    local base = get(edu, "soldierCount")
    if type(full) ~= "number" or full <= 0 or isBodyguard(edu) then return end
    if type(index) == "number" then fullSoldiers[index] = full end
    if type(base) == "number" and base > 0 then
        -- floor() hides part of the factor, so the largest ratio seen is the best
        local ratio = full / base
        if not factorSeen or ratio > sizeFactor then sizeFactor = ratio end
        factorSeen = true
    end
end

-- soldiers of a full unit of this type; nil if unknown
local function soldiersFor(edu)
    local index, base = get(edu, "index"), get(edu, "soldierCount")
    if type(index) == "number" and fullSoldiers[index] then return fullSoldiers[index] end
    if type(base) ~= "number" then return nil end
    return math.floor(base * sizeFactor + 0.0001)
end

------------------------------------------------------------------------
-- Population
------------------------------------------------------------------------
local function population(sett)
    return path(sett, "settlementStats", "population")
end

-- returns the amount really applied (0 if nothing was changed)
local function changePopulation(sett, delta, why)
    local stats = get(sett, "settlementStats")
    local before = get(stats, "population")
    if stats == nil or type(before) ~= "number" or delta == 0 then return 0 end
    if delta < 0 and before + delta < minimumFor(sett) then
        log(sett, s(get(sett, "name")) .. ": NOT charged (" .. why .. "), "
            .. s(before) .. " " .. s(delta) .. " would fall below " .. s(minimumFor(sett)))
        return 0
    end
    local ok = pcall(function() stats.population = before + delta end)
    log(sett, s(get(sett, "name")) .. ": " .. why .. " " .. s(before)
        .. (delta >= 0 and " +" or " ") .. s(delta) .. " = " .. s(population(sett))
        .. (ok and "" or " WRITE FAILED"))
    return ok and delta or 0
end

------------------------------------------------------------------------
-- Charges of the entries in the queue
------------------------------------------------------------------------
local function rememberCharge(settName, key, men)
    state.charges[settName] = state.charges[settName] or {}
    table.insert(state.charges[settName], { key = key, men = men })
end

-- fromEnd = true for a cancel (newest first), false for a finished unit
local function takeCharge(settName, key, fromEnd)
    local list = state.charges[settName]
    if list == nil then return nil end
    local first, last, step = 1, #list, 1
    if fromEnd then first, last, step = #list, 1, -1 end
    for i = first, last, step do
        if list[i].key == key then
            return table.remove(list, i).men
        end
    end
    return nil
end

-- what a queue entry costs: key (to find it again on cancel), men
local function costOf(item)
    local recruitType = get(item, "recruitType")
    local edu = get(item, "eduEntry")
    if recruitType == 0 then
        if isExempt(edu) then return nil end
        local men = soldiersFor(edu)
        if men == nil then return nil end
        return "unit:" .. s(get(edu, "eduType")), men
    elseif recruitType == 3 then
        local unit = get(item, "retrainingUnit")
        local unitEdu = get(unit, "eduEntry") or edu
        if unit == nil or isExempt(unitEdu) then return nil end
        learnFromUnit(unit)
        local full, now = get(unit, "soldierCountStratMapMax"), get(unit, "soldierCountStratMap")
        if type(full) ~= "number" or type(now) ~= "number" then return nil end
        local missing = full - now
        if missing < 0 then missing = 0 end
        return "retrain:" .. s(get(unitEdu, "eduType")), missing
    end
    return nil        -- agents, ships
end

------------------------------------------------------------------------
-- BLOCKING: grey out units the settlement has too few people for
------------------------------------------------------------------------
-- The game keeps a stock ("pool") per unit and settlement. Below 1 the unit
-- is greyed out and cannot be queued. If the population is too small for a
-- unit, its whole units of stock are taken away and remembered in
-- state.parked; they are handed back when there are enough people again.
--
-- justQueued: EDU index of the unit that was queued a moment ago. The game
-- takes 1 from that unit's stock only AFTER the "added to queue" event, so
-- that 1 must be left alone (otherwise a cancel hands out a free one).
local function maxPool(sett, eduIndex)
    local n = get(sett, "recruitmentCapabilityNum") or 0
    for i = 0, n - 1 do
        local ok, cap = pcall(function() return sett:getRecruitmentCapability(i) end)
        if ok and cap ~= nil and get(cap, "eduIndex") == eduIndex then
            return get(cap, "maxSize")
        end
    end
    return nil
end

local function refreshBlocking(sett, justQueued)
    if sett == nil then return end
    local name = get(sett, "name")
    local people = population(sett)
    if type(name) ~= "string" or type(people) ~= "number" then return end

    local free = people - minimumFor(sett)
    local store = state.parked[name] or {}
    local present = {}
    local poolCount = get(sett, "recruitmentPoolCount") or 0
    for i = 0, poolCount - 1 do
        local ok, pool = pcall(function() return sett:getSettlementRecruitmentPool(i) end)
        local eduIndex = ok and get(pool, "eduIndex") or nil
        local stock = ok and get(pool, "availablePool") or nil
        if type(eduIndex) == "number" and type(stock) == "number" then
            present[eduIndex] = true
            local okE, edu = pcall(function() return M2TWEOPDU.getEduEntry(eduIndex) end)
            if not okE then edu = nil end
            local men = nil
            if edu ~= nil and not isExempt(edu) then men = soldiersFor(edu) end
            local held = store[eduIndex] or 0
            if men ~= nil and men > free then
                local owed = (eduIndex == justQueued) and 1 or 0
                local whole = math.floor(stock - owed)
                if whole >= 1 and pcall(function() pool.availablePool = stock - whole end) then
                    store[eduIndex] = held + whole
                    log(sett, name .. ": BLOCK " .. s(get(edu, "eduType")) .. " (needs " .. s(men)
                        .. ", free " .. s(free) .. "), stock withheld " .. s(store[eduIndex]))
                end
            elseif held > 0 then
                local back = stock + held
                local cap = maxPool(sett, eduIndex)
                if type(cap) == "number" and cap >= 1 and back > cap then back = cap end
                if pcall(function() pool.availablePool = back end) then
                    store[eduIndex] = nil
                    log(sett, name .. ": UNBLOCK " .. s(get(edu, "eduType")) .. ", stock " .. s(back))
                end
            end
        end
    end
    -- forget stock of units this settlement can no longer build at all
    for eduIndex in pairs(store) do
        if not present[eduIndex] then store[eduIndex] = nil end
    end
    if next(store) ~= nil then state.parked[name] = store else state.parked[name] = nil end
end

------------------------------------------------------------------------
-- Event handlers
------------------------------------------------------------------------
function PR.onAddedToTrainingQueue(eventData)
    local sett = get(eventData, "settlement")
    if sett == nil then return end
    -- the entry just added is the last one (index starts at 0)
    local count = get(sett, "unitInQueueCount") or 0
    local ok, item = pcall(function() return sett:getUnitInQueue(count - 1) end)
    if not ok or item == nil then return end
    local key, men = costOf(item)
    if key ~= nil then
        local applied = changePopulation(sett, -men, "queued " .. key)
        -- remember what was really taken, so a cancel returns exactly that
        rememberCharge(s(get(sett, "name")), key, -applied)
    end
    local justQueued = nil
    if get(item, "recruitType") == 0 then justQueued = path(item, "eduEntry", "index") end
    refreshBlocking(sett, justQueued)
end

-- fires only when an entry is cancelled; receives the queue entry itself
function PR.onRemoveFromUnitQueue(item)
    local sett = get(item, "settlement")
    if sett == nil then return end
    local key = costOf(item)
    if key ~= nil then
        local men = takeCharge(s(get(sett, "name")), key, true)
        if men ~= nil and men > 0 then
            changePopulation(sett, men, "cancelled " .. key)
        end
    end
    refreshBlocking(sett, nil)
end

function PR.onUnitTrained(eventData)
    local unit = get(eventData, "playerUnit")
    learnFromUnit(unit)
    -- the unit left the queue for good: its remembered charge is used up
    local sett = get(eventData, "settlement")
    if sett ~= nil then
        takeCharge(s(get(sett, "name")), "unit:" .. s(path(unit, "eduEntry", "eduType")), false)
    end
end

function PR.onUnitDisbanded(eventData)
    local unit = get(eventData, "playerUnit")
    learnFromUnit(unit)
    local faction = get(eventData, "faction")
    if not isPlayerFaction(faction) then return end
    local edu = get(unit, "eduEntry") or get(eventData, "eduEntry")
    local men = get(unit, "soldierCountStratMap")
    if type(men) ~= "number" or men <= 0 or isExempt(edu) then return end
    local army = get(unit, "army")
    if army == nil or get(army, "shipArmy") ~= nil then return end

    local target = nil
    local x, y = get(army, "xCoord"), get(army, "yCoord")
    local okT, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
    if not okT then tile = nil end
    local here = get(tile, "settlement")
    if here ~= nil and get(here, "ownerFaction") == faction then
        target = here
    else
        local regionID = get(tile, "regionID") or get(army, "regionID")
        local okR, region = pcall(function() return M2TW.stratMap.getRegion(regionID) end)
        if okR and region ~= nil and get(region, "isSea") ~= true then
            for i = 0, (get(region, "settlementCount") or 0) - 1 do
                local okS, sett = pcall(function() return region:getSettlement(i) end)
                if okS and sett ~= nil and get(sett, "isMinorSettlement") ~= true
                    and get(sett, "ownerFaction") == faction then
                    target = sett
                    break
                end
            end
        end
    end
    if target == nil then
        if LOG_PLAYER then
            rawLog("disbanded " .. s(get(edu, "eduType")) .. " (" .. s(men)
                .. ") outside your regions: men are lost")
        end
        return
    end
    changePopulation(target, men, "disbanded " .. s(get(edu, "eduType")))
    refreshBlocking(target, nil)
end

function PR.onSettlementTurnStart(eventData)
    local sett = get(eventData, "settlement")
    if sett == nil then return end
    -- nothing queued any more: no charge can still be open here
    if (get(sett, "unitInQueueCount") or 0) == 0 then
        state.charges[s(get(sett, "name"))] = nil
    end
    refreshBlocking(sett, nil)
end

local function refreshFromEvent(eventData)
    refreshBlocking(get(eventData, "settlement"), nil)
end
PR.onSettlementSelected   = refreshFromEvent
PR.onSettlementPanelOpen  = refreshFromEvent
PR.onRecruitmentPanelOpen = refreshFromEvent

function PR.onNewGameStart()
    resetState()
end

------------------------------------------------------------------------
-- Savegames
------------------------------------------------------------------------
local function saveState(savefiles)
    if type(persistence) ~= "table" or type(savefiles) ~= "table" then return end
    local file = M2TWEOP.getPluginPath() .. SAVE_FILE
    persistence.store(file, state)
    savefiles[#savefiles + 1] = file
end

local function loadState(paths)
    resetState()
    if type(persistence) ~= "table" or type(paths) ~= "table" then return end
    for _, file in pairs(paths) do
        if type(file) == "string" and string.find(file, SAVE_FILE, 1, true) then
            local loaded = persistence.load(file)
            if type(loaded) == "table" then
                state.parked  = type(loaded.parked) == "table" and loaded.parked or {}
                state.charges = type(loaded.charges) == "table" and loaded.charges or {}
            end
        end
    end
    rawLog("state loaded")
end

------------------------------------------------------------------------
-- Installer: SSHIP's own code keeps running first, then ours
------------------------------------------------------------------------
local function wrap(hookName, method)
    local previous = _G[hookName]
    _G[hookName] = function(arg)
        if previous then previous(arg) end
        local ok, err = pcall(method, arg)
        if not ok then rawLog("ERROR in " .. hookName .. ": " .. tostring(err)) end
    end
end

function PR.install()
    if PR.installed then return end
    PR.installed = true
    local names = {
        "onAddedToTrainingQueue", "onRemoveFromUnitQueue",
        "onUnitTrained", "onUnitDisbanded", "onSettlementTurnStart",
        "onSettlementSelected", "onSettlementPanelOpen", "onRecruitmentPanelOpen",
        "onNewGameStart",
    }
    for i = 1, #names do wrap(names[i], PR[names[i]]) end

    -- SSHIP's save function returns its list of files; ours is added to it.
    local previousSave = _G.onCreateSaveFile
    _G.onCreateSaveFile = function()
        local savefiles = previousSave and previousSave() or {}
        if type(savefiles) ~= "table" then savefiles = {} end
        local ok, err = pcall(saveState, savefiles)
        if not ok then rawLog("ERROR while saving: " .. tostring(err)) end
        return savefiles
    end
    local previousLoad = _G.onLoadSaveFile
    _G.onLoadSaveFile = function(paths)
        if previousLoad then previousLoad(paths) end
        local ok, err = pcall(loadState, paths)
        if not ok then rawLog("ERROR while loading: " .. tostring(err)) end
    end
end

PR.install()

PopulationRecruitment = PR
return PR
