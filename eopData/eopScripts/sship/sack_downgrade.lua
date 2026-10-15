---------------------------------------------------------------------------------------------------------------------
-- sack_downgrade.lua  (Modding_SSHIP, 15 Oct 2026) - a captured settlement can lose a level.
-- User's design (15 Oct 2026):
--   * Sack: 25% chance the settlement drops one level. Exterminate: always drops one level.
--   * Lowest levels: a town (level 1) can fall to a village; a village cannot drop; a castle stops at motte and
--     bailey (the game has no castle below it).
--   * When the settlement drops, every building that can be replaced drops one level too (a tier-1 building stays
--     standing - there is nothing below it). Never touched: wonders, guilds, convert_to_*, hidden helper buildings.
--     A building keeps its damage (hp) when it is rebuilt one level lower.
--   * Player and AI alike. A message goes to the player when he sacks / exterminates or is the one sacked.
--   * Population is left to whatever the sack itself leaves.
-- TEST = true: a sack ALWAYS drops a level (to see it in one siege). Set TEST = false for the 25% chance.
-- Log prefix SACKDOWN. Remove the require line in luaPluginScript.lua to switch it off.
---------------------------------------------------------------------------------------------------------------------
local SD = SackDowngrade or {}

local TEST = true
local SACK_CHANCE = TEST and 1.0 or 0.25
local EXTERMINATE_CHANCE = 1.0

local CITY_NAMES   = { [0] = "a village", [1] = "a town", [2] = "a large town", [3] = "a city", [4] = "a large city",
                       [5] = "a huge city" }
local CASTLE_NAMES = { [1] = "a motte and bailey", [2] = "a wooden castle", [3] = "a castle", [4] = "a fortress",
                       [5] = "a citadel" }

-- chains that are never knocked down (cannot be rebuilt by normal means)
local function isProtected(chain)
    if chain == nil then return true end
    return chain:find("^wonder") ~= nil or chain == "holy_sepulchre" or chain:find("^guild_") ~= nil
        or chain:find("^convert_to_") ~= nil or chain == "hidden_temporary_buildings"
end

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("SACKDOWN " .. tostring(text))
    end
end

local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function call(obj, method, ...)
    if obj == nil then return nil end
    local args = { ... }
    local ok, value = pcall(function() return obj[method](obj, unpack(args)) end)
    if ok then return value end
    return nil
end

local function turnNow() return get(M2TW.campaign, "turnNumber") or 0 end

---------------------------------------------------------------------------------------------------------------------
-- which settlement was taken: the capturing general stands in it (regionID alone is not enough - #4 put several
-- settlements into many regions)
---------------------------------------------------------------------------------------------------------------------
local function findSettlement(eventData)
    local record = get(eventData, "character")
    local char = get(record, "character")
    local sett = get(char, "settlement")
    if sett ~= nil then return sett, "general" end
    local x, y = get(char, "xCoord"), get(char, "yCoord")
    if x ~= nil and y ~= nil then
        local okT, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
        sett = okT and get(tile, "settlement") or nil
        if sett ~= nil then return sett, "tile" end
    end
    local rid = get(eventData, "regionID")
    if rid ~= nil then
        local okR, region = pcall(function() return M2TW.stratMap.getRegion(rid) end)
        if okR and region ~= nil and (get(region, "settlementCount") or 1) <= 1 then
            sett = get(region, "settlement")
            if sett ~= nil then return sett, "region" end
        end
    end
    return nil, "not found"
end

---------------------------------------------------------------------------------------------------------------------
-- one building down one level: destroy it and build the level below; if that fails, put the old level back
---------------------------------------------------------------------------------------------------------------------
local function buildingLevelName(entry, index)
    local okL, lvl = pcall(function() return entry:getBuildingLevel(index) end)
    return okL and get(lvl, "name") or nil
end

local function lowerBuilding(sett, b)
    local entry = get(b, "edbEntry")
    local chain = get(entry, "name") or call(b, "getType")
    local idx = get(b, "level")
    if chain == nil or idx == nil then return "?" end
    local oldName = call(b, "getName") or buildingLevelName(entry, idx) or "?"
    if isProtected(chain) then return nil end
    if idx < 1 then return nil end                      -- tier 1: stays standing
    local newName = buildingLevelName(entry, idx - 1)
    if newName == nil then return oldName .. " FAILED (no lower level)" end
    local hp = get(b, "hp")
    local okD, errD = pcall(function() sett:destroyBuilding(chain, false) end)
    if not okD then return oldName .. " FAILED destroy " .. tostring(errD) end
    local okC, errC = pcall(function() sett:createBuilding(newName) end)
    local now = call(sett, "buildingPresent", chain)
    if okC and now ~= nil then
        if hp ~= nil and hp < 100 then pcall(function() now.hp = hp end) end
        return oldName .. " -> " .. newName
    end
    pcall(function() sett:createBuilding(oldName) end)  -- put it back rather than lose it
    return oldName .. " FAILED create " .. newName .. " " .. tostring(errC) .. ", restored "
        .. tostring(call(sett, "buildingPresent", chain) ~= nil)
end

---------------------------------------------------------------------------------------------------------------------
-- the settlement itself: level - 1 and the wall building of the new level
---------------------------------------------------------------------------------------------------------------------
local function lowerSettlement(sett)
    local level = get(sett, "level")
    local castle = get(sett, "isCastle") == 1 or get(sett, "isCastle") == true
    if level == nil then return false, "level unreadable" end
    if level <= 0 then return false, "village, cannot drop" end
    if castle and level <= 1 then return false, "motte and bailey, cannot drop" end
    local coreChain = castle and "core_castle_building" or "core_building"
    local core = call(sett, "buildingPresent", coreChain)
    local coreNote = "no wall building"
    if core ~= nil then
        local entry = get(core, "edbEntry")
        local idx = get(core, "level")
        local hp = get(core, "hp")
        local oldName = call(core, "getName") or "?"
        local okD = pcall(function() sett:destroyBuilding(coreChain, false) end)
        if idx ~= nil and idx >= 1 then
            local newName = buildingLevelName(entry, idx - 1)
            local okC = newName ~= nil and pcall(function() sett:createBuilding(newName) end)
            local now = call(sett, "buildingPresent", coreChain)
            if okC and now ~= nil then
                if hp ~= nil and hp < 100 then pcall(function() now.hp = hp end) end
                coreNote = oldName .. " -> " .. tostring(newName)
            else
                pcall(function() sett:createBuilding(oldName) end)
                return false, "wall " .. oldName .. " could not be lowered (destroy " .. tostring(okD) .. ")"
            end
        else
            coreNote = oldName .. " removed (town -> village)"
        end
    end
    local okL, errL = pcall(function() sett.level = level - 1 end)
    if not okL then return false, "level write failed " .. tostring(errL) end
    return true, "level " .. level .. " -> " .. tostring(get(sett, "level")) .. ", walls " .. coreNote
end

local function lowerAll(sett)
    local n = get(sett, "buildingsNum") or 0
    -- collect first: destroying / creating changes the building list
    local list = {}
    for i = 0, n - 1 do
        local okB, b = pcall(function() return sett:getBuilding(i) end)
        if okB and b ~= nil then
            local entry = get(b, "edbEntry")
            local core = get(entry, "isCoreBuilding")
            local chain = get(entry, "name") or call(b, "getType")
            if not (core == 1 or core == true) and chain ~= "core_building" and chain ~= "core_castle_building" then
                list[#list + 1] = chain
            end
        end
    end
    local done = {}
    for _, chain in ipairs(list) do
        local b = call(sett, "buildingPresent", chain)
        if b ~= nil then
            local result = lowerBuilding(sett, b)
            if result ~= nil then done[#done + 1] = result end
        end
    end
    return done
end

---------------------------------------------------------------------------------------------------------------------
-- message for the player(s) involved
---------------------------------------------------------------------------------------------------------------------
local function tell(sett, how, attacker, defender, newLevel, castle)
    local factions = {}
    for _, f in ipairs({ attacker, defender }) do
        if f ~= nil and get(f, "isPlayerControlled") == 1 then factions[#factions + 1] = get(f, "name") end
    end
    if #factions == 0 then return end
    local name = get(sett, "localizedName") or get(sett, "name") or "The settlement"
    local now = (castle and CASTLE_NAMES or CITY_NAMES)[newLevel] or ("level " .. tostring(newLevel))
    local title = (how == "exterminate") and "A City Laid Waste" or "A City Despoiled"
    local body = "\nThe " .. (how == "exterminate" and "slaughter" or "sack") .. " of " .. name
        .. " has left it a shadow of its former self - it is now " .. now .. ".\n\n"
        .. "Its walls and many of its buildings have been brought down a level."
    local x, y = get(sett, "xCoord") or -1, get(sett, "yCoord") or -1
    local ok, err = pcall(function() M2TW.campaign.historicEvent("HX_SACK_DOWNGRADE", title, body, false, x, y, factions) end)
    if not ok then log("could not show the message: " .. tostring(err)) end
end

---------------------------------------------------------------------------------------------------------------------
-- the events (a capture can fire more than one: a settlement drops at most once per capture)
---------------------------------------------------------------------------------------------------------------------
SD.done = SD.done or {}

local function onCapture(eventData, how, chance)
    local sett, via = findSettlement(eventData)
    if sett == nil then log(how .. ": settlement not found (region " .. tostring(get(eventData, "regionID")) .. ")") return end
    local name = get(sett, "name") or "?"
    local key = name .. "@" .. turnNow()
    if SD.done[key] then log(how .. " " .. name .. ": already lowered this capture") return end
    local roll = math.random()
    local attacker, defender = get(eventData, "faction"), get(eventData, "targetFaction")
    local head = how .. " " .. name .. " (via " .. via .. ") by " .. tostring(get(attacker, "name")) .. " from "
        .. tostring(get(defender, "name")) .. ", level " .. tostring(get(sett, "level")) .. ", population "
        .. tostring(get(sett, "populationSize")) .. ", roll " .. string.format("%.2f", roll) .. " / " .. chance
    if roll >= chance then log(head .. ": no drop") return end
    local castle = get(sett, "isCastle") == 1 or get(sett, "isCastle") == true
    local ok, note = lowerSettlement(sett)
    if not ok then log(head .. ": no drop - " .. note) return end
    SD.done[key] = true
    local done = lowerAll(sett)
    log(head .. ": DROPPED, " .. note .. "; buildings (" .. #done .. "): " .. table.concat(done, ", "))
    tell(sett, how, attacker, defender, get(sett, "level"), castle)
end

local function afterHook(name, fn)
    local previous = _G[name]
    _G[name] = function(arg)
        local result = nil
        if previous then result = previous(arg) end
        local ok, err = pcall(fn, arg)
        if not ok then log("ERROR after " .. name .. ": " .. tostring(err)) end
        return result
    end
end

if not SD.installed then
    SD.installed = true
    afterHook("onSackSettlement", function(e) onCapture(e, "sack", SACK_CHANCE) end)
    afterHook("onExterminatePopulation", function(e) onCapture(e, "exterminate", EXTERMINATE_CHANCE) end)
    afterHook("onFactionTurnStart", function() SD.done = {} end)
    log("installed, sack chance " .. SACK_CHANCE .. ", exterminate " .. EXTERMINATE_CHANCE .. (TEST and " (TEST)" or ""))
end

SackDowngrade = SD
return SD
