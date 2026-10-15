---------------------------------------------------------------------------------------------------------------------
-- building_diag.lua  (Modding_SSHIP, 15 Oct 2026) - TEMPORARY diagnostic, logging only, changes nothing.
-- Bug: a damaged building (Karahisar's small_masjid after a revolt) cannot be repaired - "already in the build
-- queue", greyed out. At every player turn start this logs, for each player settlement with a damaged building
-- (hp < 100): every building (chain, level, hp) and every entry of the build queue.
-- Log prefix: BDIAG (in full.log). Remove the require line in luaPluginScript.lua when the bug is understood.
---------------------------------------------------------------------------------------------------------------------
local BD = BuildingDiag or {}

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("BDIAG " .. tostring(text))
    end
end

local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function call(obj, method)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[method](obj) end)
    if ok then return value end
    return nil
end

local function dumpSettlement(sett, turn)
    local n = get(sett, "buildingsNum") or 0
    local damaged, lines = false, {}
    for i = 0, n - 1 do
        local okB, b = pcall(function() return sett:getBuilding(i) end)
        if okB and b then
            local hp = get(b, "hp")
            if type(hp) == "number" and hp < 100 then damaged = true end
            lines[#lines + 1] = tostring(call(b, "getType")) .. "/" .. tostring(call(b, "getName")) .. " hp " .. tostring(hp)
        end
    end
    if not damaged then return end
    log("turn " .. turn .. " " .. tostring(get(sett, "name")) .. " buildings: " .. table.concat(lines, ", "))
    local q = get(sett, "buildingsQueue")
    local qn = get(q, "numBuildingsInQueue") or 0
    log("  queue entries: " .. qn)
    for i = 0, qn - 1 do
        local okQ, e = pcall(function() return q:getBuildingInQueue(i) end)
        if okQ and e then
            log("  [" .. i .. "] " .. tostring(call(e, "getQueueBuildingType")) .. " / " .. tostring(call(e, "getQueueBuildingName"))
                .. " type " .. tostring(get(e, "constructionType")) .. " level " .. tostring(get(e, "previousLevel"))
                .. "->" .. tostring(get(e, "currentLevel")) .. " turns " .. tostring(get(e, "buildTurnsPassed")) .. "/"
                .. tostring(get(e, "buildTurnsRemaining")) .. " built " .. tostring(get(e, "percentBuilt")) .. "% cost "
                .. tostring(get(e, "buildCost")) .. " existing " .. tostring(get(e, "building") ~= nil))
        end
    end
end

local function onTurnStart(eventData)
    local fac = get(eventData, "faction")
    if get(fac, "isPlayerControlled") ~= 1 then return end
    local turn = get(M2TW.campaign, "turnNumber") or -1
    local n = get(fac, "settlementsNum") or 0
    for i = 0, n - 1 do
        local ok, s = pcall(function() return fac:getSettlement(i) end)
        if ok and s then dumpSettlement(s, turn) end
    end
end

if not BD.installed then
    BD.installed = true
    local previous = _G.onFactionTurnStart
    _G.onFactionTurnStart = function(arg)
        local result = nil
        if previous then result = previous(arg) end
        local ok, err = pcall(onTurnStart, arg)
        if not ok then log("ERROR: " .. tostring(err)) end
        return result
    end
    log("loaded")
end

BuildingDiag = BD
return BD
