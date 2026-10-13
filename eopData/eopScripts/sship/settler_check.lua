--[[
    TEMPORARY CHECK (13 Oct 2026, Modding_SSHIP #3): why the settler units do not show in the recruitment panel.
    Logs (prefix SETTCHK, in mods\sship\full.log) for every PLAYER settlement that is selected or whose
    recruitment panel opens, once per settlement and turn:
      - the counter is_the_player at that moment,
      - how many recruitment capabilities the settlement has (the engine keeps at most 64),
      - whether a settler unit is among them (with its pool numbers), and the stock (pool) of the settler units,
      - the unit types at the END of the capability list (to see what got cut off).
    Changes nothing in the game. Remove the require line in luaPluginScript.lua when done.
]]
local SC = { done = {} }
local SETTLERS = { "Catholic Settlers", "Orthodox Settlers", "Muslim Settlers", "Pagan Settlers" }

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then M2TWEOP.logGame("SETTCHK " .. tostring(text)) end
end
local function get(obj, key)
    if obj == nil then return nil end
    local ok, v = pcall(function() return obj[key] end)
    if ok then return v end
    return nil
end
local function typeName(index)
    local ok, edu = pcall(function() return M2TWEOPDU.getEduEntry(index) end)
    return ok and tostring(get(edu, "eduType")) or ("#" .. tostring(index))
end

function SC.check(sett, why)
    if sett == nil then return end
    local owner = get(sett, "ownerFaction")
    if get(owner, "isPlayerControlled") ~= 1 then return end
    local turn = get(get(M2TW, "campaign"), "turnNumber") or -1
    local key = tostring(get(sett, "name")) .. "/" .. tostring(turn)
    if SC.done[key] then return end
    SC.done[key] = true

    local settlerIdx = {}
    for i = 1, #SETTLERS do
        local ok, idx = pcall(function() return M2TWEOPDU.getEduIndexByType(SETTLERS[i]) end)
        if ok and type(idx) == "number" then settlerIdx[idx] = SETTLERS[i] end
        log("unit file: " .. SETTLERS[i] .. " index " .. tostring(ok and idx or "ERROR " .. tostring(idx)))
    end
    local counter = "?"
    pcall(function() counter = M2TWEOP.getScriptCounter("is_the_player") .. ", hx_player_" .. tostring(get(owner, "name"))
        .. " " .. M2TWEOP.getScriptCounter("hx_player_" .. tostring(get(owner, "name"))) end)
    local caps = get(sett, "recruitmentCapabilityNum") or -1
    local pools = get(sett, "recruitmentPoolCount") or -1
    log(why .. ": " .. key .. " owner " .. tostring(get(owner, "name")) .. ", is_the_player " .. tostring(counter)
        .. ", capabilities " .. tostring(caps) .. " (max 64), pools " .. tostring(pools))
    local found, tail = false, {}
    for i = 0, caps - 1 do
        local ok, cap = pcall(function() return sett:getRecruitmentCapability(i) end)
        local idx = ok and get(cap, "eduIndex") or nil
        if settlerIdx[idx] then
            found = true
            log("  capability " .. i .. ": " .. settlerIdx[idx] .. " initial " .. tostring(get(cap, "initialSize"))
                .. " refill " .. tostring(get(cap, "replenishRate")) .. " max " .. tostring(get(cap, "maxSize")))
        end
        if i >= caps - 5 then tail[#tail + 1] = i .. "=" .. typeName(idx) end
    end
    if not found then log("  NO settler capability in this settlement") end
    log("  last capabilities: " .. table.concat(tail, ", "))
    for i = 0, pools - 1 do
        local ok, pool = pcall(function() return sett:getSettlementRecruitmentPool(i) end)
        local idx = ok and get(pool, "eduIndex") or nil
        if settlerIdx[idx] then log("  pool: " .. settlerIdx[idx] .. " stock " .. tostring(get(pool, "availablePool"))) end
    end
end

local function wrap(name)
    local previous = _G[name]
    _G[name] = function(eventData)
        if previous then previous(eventData) end
        local ok, err = pcall(SC.check, get(eventData, "settlement"), name)
        if not ok then log("ERROR " .. tostring(err)) end
    end
end
wrap("onSettlementSelected")
wrap("onRecruitmentPanelOpen")
wrap("onSettlementPanelOpen")

SettlerCheck = SC
return SC
