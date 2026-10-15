---------------------------------------------------------------------------------------------------------------------
-- fort_rules.lua  (Modding_SSHIP, 15 Oct 2026) - fort upkeep and price, decided by the user on 15 Oct 2026:
--   * 4 units in a fort have free upkeep, for every faction: the engine's own setting campaign.freeUpkeepForts
--     (EOP). Set at every map load and faction turn start, since it is probably not stored in the save. If the
--     engine treats it like free upkeep in settlements (only units with free_upkeep_unit), that is fine (user).
--   * a fort costs 5000 (fort_cost in data/descr_cultures.txt, all five cultures). The AI gets the whole 5000 back
--     for every fort it builds (user: it should still build them): at the end of an AI faction's turn, every fort of
--     that faction on a tile that had no fort at the start of the turn counts as built (a captured fort stood there
--     before, so it is not refunded). Rebels (slave) get nothing (their forts are game-made, test of 15 Oct).
-- Log prefix FORTRULE. Remove the require line in luaPluginScript.lua to switch the script part off.
---------------------------------------------------------------------------------------------------------------------
local FREE_UPKEEP = 4
local AI_REFUND = 5000

local FR = FortRules or {}

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("FORTRULE " .. tostring(text))
    end
end

local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function setFreeUpkeep(why)
    local c = M2TW.campaign
    if get(c, "freeUpkeepForts") == FREE_UPKEEP then return end
    local before = get(c, "freeUpkeepForts")
    local ok, err = pcall(function() c.freeUpkeepForts = FREE_UPKEEP end)
    log("freeUpkeepForts " .. tostring(before) .. " -> " .. FREE_UPKEEP .. " (" .. why .. "): "
        .. (ok and ("reads back " .. tostring(get(c, "freeUpkeepForts"))) or ("ERROR " .. tostring(err))))
end

-- all forts on the map: { ["x,y"] = fort }
local function allForts()
    local list = {}
    local c = M2TW.campaign
    local n = get(c, "fortsNum") or 0
    for i = 0, n - 1 do
        local ok, fort = pcall(function() return c:getFort(i) end)
        if ok and fort then
            local x, y = get(fort, "xCoord"), get(fort, "yCoord")
            if x and y then list[x .. "," .. y] = fort end
        end
    end
    return list
end

FR.known = FR.known or nil   -- fort tiles at the start of the current faction's turn

local function onTurnStart(eventData)
    setFreeUpkeep("turn start")
    FR.known = {}
    for key in pairs(allForts()) do FR.known[key] = true end
end

local function onTurnEnd(eventData)
    local f = get(eventData, "faction")
    if f == nil or get(f, "isPlayerControlled") == 1 or get(f, "name") == "slave" or FR.known == nil then return end
    local fid = get(f, "factionID")
    local now = allForts()
    for key, fort in pairs(now) do
        if not FR.known[key] and get(get(fort, "ownerFaction"), "factionID") == fid then
            local ok, err = pcall(function() f.money = f.money + AI_REFUND end)
            log(tostring(get(f, "name")) .. " built a fort at " .. key .. " - refund " .. AI_REFUND
                .. (ok and "" or (" ERROR " .. tostring(err))))
        end
    end
    FR.known = nil
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

if not FR.installed then
    FR.installed = true
    afterHook("onFactionTurnStart", onTurnStart)
    afterHook("onFactionTurnEnd", onTurnEnd)
    afterHook("onCampaignMapLoaded", function() setFreeUpkeep("map loaded") end)
    log("loaded (free upkeep " .. FREE_UPKEEP .. ", AI refund " .. AI_REFUND .. ")")
end

FortRules = FR
return FR
