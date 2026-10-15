---------------------------------------------------------------------------------------------------------------------
-- mongol_islam.lua  (Modding_SSHIP, 15 Oct 2026)
-- The Mongols (emerging AI-only faction, pagan) convert to Islam at turn 340 (~1301; Ghazan 1295, Ozbeg 1313).
--   * condition: turn >= CONVERT_TURN, Mongols alive (own at least one settlement)
--   * faction religion -> islam (EOP field factionStruct.religion), script counter mongols_islam = 1
--     (export_descr_buildings: Mongols may then build mosques, no new Tengri temples)
--   * every Tengri temple in a Mongol settlement becomes the matching mosque - at conversion and at every later
--     Mongol turn start (so temples in settlements taken later are converted too)
--   * population religion is NOT touched (shifts naturally)
-- TEST = true: Mongols spawn at TEST_SPAWN_TURN next to Urgench and take it; conversion as soon as they hold a
-- settlement (CONVERT_TURN = 2). Final version: TEST = false.
-- Log prefix: MONGISL (in full.log).
---------------------------------------------------------------------------------------------------------------------
local TEST = false
local CONVERT_TURN = TEST and 2 or 340
local TEST_SPAWN_TURN = 2
local C_DONE = "mongols_islam"          -- 1 = converted (also used in export_descr_buildings)
local C_TEST_SPAWNED = "mongols_islam_test_spawn"

local MI = MongolIslam or {}

local TEMPLE_MAP = {
    tengir_altar     = "small_masjid",
    tengir_sanctuary = "masjid",
    tengir_temple    = "minareted_masjid",
    c_tengir_altar   = "c_small_masjid",
}

local TEST_ARMY = {
    "Merguen Archers", "Merguen Archers", "Disamounted Turhagut", "Disamounted Turhagut", "Disamounted Turhagut",
    "Hoschuchi Lancers", "Hoschuchi Lancers", "Lubchiten Horse Archers", "Lubchiten Horse Archers",
    "Nukeri Horse Archers", "Turhagut Lancers", "Turhagut Lancers", "ME Trebuchet",
}

local EVENT_TITLE = "The Mongols embrace Islam"
local EVENT_BODY = "\nThe Mongol khans of the West have turned to the faith of their Muslim subjects.\n\n"
    .. "In the Ilkhanate, Ghazan Khan converted to Islam in 1295 when he took the throne, and his Mongol nobles followed "
    .. "him. In the Golden Horde, Berke Khan had already become a Muslim, but it was Ozbeg Khan who made Islam the "
    .. "religion of the state in 1313. The shamans of Tengri give way to imams, and the old temples of the steppe "
    .. "become mosques.\n\nGAME: The Mongols are now a Muslim faction. Their Tengri temples have become mosques."

---------------------------------------------------------------------------------------------------------------------
-- helpers (a wrong field name must never crash the game)
---------------------------------------------------------------------------------------------------------------------
local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("MONGISL " .. tostring(text))
    end
end

local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function counter(name)
    local ok, v = pcall(function() return M2TWEOP.getScriptCounter(name) end)
    if ok and type(v) == "number" then return v end
    return 0
end

local function setCounter(name, value)
    local ok, err = pcall(function() M2TWEOP.setScriptCounter(name, value) end)
    if not ok then log("ERROR setScriptCounter " .. name .. ": " .. tostring(err)) end
end

local function turnNow()
    return get(M2TW.campaign, "turnNumber") or -1
end

local function mongols()
    local ok, f = pcall(function() return M2TW.campaign:getFaction("mongols") end)
    if ok then return f end
    return nil
end

local function islamID()
    local ok, id = pcall(function() return M2TWEOP.getReligion("islam") end)
    if ok and type(id) == "number" and id >= 0 then return id end
    return 2  -- descr_religions.txt: catholic 0, orthodox 1, islam 2, pagan 3, heretic 4
end

local function playerFactionNames()
    local names = {}
    local n = get(M2TW.campaign, "numberOfFactions") or 0
    for i = 0, n - 1 do
        local ok, f = pcall(function() return M2TW.campaign:getFactionByID(i) end)
        if ok and f and get(f, "isPlayerControlled") == 1 then names[#names + 1] = f.name end
    end
    return names
end

---------------------------------------------------------------------------------------------------------------------
-- Tengri temples -> mosques
---------------------------------------------------------------------------------------------------------------------
local function convertTemples(sett)
    local found = {}
    local n = get(sett, "buildingsNum") or 0
    for i = 0, n - 1 do
        local okB, b = pcall(function() return sett:getBuilding(i) end)
        if okB and b then
            local okT, chain = pcall(function() return b:getType() end)
            local okN, level = pcall(function() return b:getName() end)
            if okT and okN and TEMPLE_MAP[level] then found[#found + 1] = { chain = chain, level = level } end
        end
    end
    for _, t in ipairs(found) do
        local okD, errD = pcall(function() sett:destroyBuilding(t.chain, false) end)
        local okC, errC = pcall(function() sett:createBuilding(TEMPLE_MAP[t.level]) end)
        log("temple " .. tostring(get(sett, "name")) .. ": " .. t.level .. " -> " .. TEMPLE_MAP[t.level]
            .. ((okD and okC) and "" or (" ERROR " .. tostring(errD) .. " / " .. tostring(errC))))
    end
    return #found
end

local function convertAllTemples(f)
    local total = 0
    local n = get(f, "settlementsNum") or 0
    for i = 0, n - 1 do
        local ok, s = pcall(function() return f:getSettlement(i) end)
        if ok and s then total = total + convertTemples(s) end
    end
    return total
end

---------------------------------------------------------------------------------------------------------------------
-- conversion
---------------------------------------------------------------------------------------------------------------------
local function setIslam(f)
    local id = islamID()
    local ok, err = pcall(function() f.religion = id end)
    local now = get(f, "religion")
    log("faction religion set to " .. tostring(id) .. ", reads back " .. tostring(now)
        .. (ok and "" or (" ERROR " .. tostring(err))))
    return now == id
end

local function convert(f)
    local okSet = setIslam(f)
    setCounter(C_DONE, 1)
    local temples = convertAllTemples(f)
    log("CONVERTED at turn " .. turnNow() .. " (" .. (get(f, "settlementsNum") or 0) .. " settlements, "
        .. temples .. " temples converted, religion ok = " .. tostring(okSet) .. ")")
    local factions = playerFactionNames()
    if #factions > 0 then
        local ok, err = pcall(function()
            M2TW.campaign.historicEvent("MONGOLS_EMBRACE_ISLAM", EVENT_TITLE, EVENT_BODY, false, -1, -1, factions)
        end)
        if not ok then log("ERROR historicEvent: " .. tostring(err)) end
    end
end

---------------------------------------------------------------------------------------------------------------------
-- TEST only: Mongols spawn next to Urgench and take it at once (as SSHIP's own first wave does at Konjikala)
---------------------------------------------------------------------------------------------------------------------
local function testSpawn()
    local f = mongols()
    if f == nil then log("TEST ERROR: no mongols faction"); return end
    local okS, sett = pcall(function() return M2TW.stratMap:getSettlement("Urgench") end)
    if not okS or sett == nil then log("TEST ERROR: Urgench not found"); return end
    local okE, bg = pcall(function() return M2TWEOPDU.getEduIndexByType("Keshikten Bodyguard") end)
    local okT, x, y = pcall(function() return M2TW.stratMap.findValidTileNearTile(500, 147, characterType.named_character) end)
    if not okT then x, y = 500, 147 end
    local okA, army = pcall(function()
        return f:spawnArmy("random_name", "", characterType.named_character, "", "", x, y, 30, true, 31, bg, 3, 0, 0)
    end)
    if not okA or army == nil then log("TEST ERROR spawnArmy: " .. tostring(army)); return end
    local made = 0
    for _, u in ipairs(TEST_ARMY) do
        if pcall(function() army:createUnit(u, 2, 0, 0) end) then made = made + 1 end
    end
    log("TEST army spawned at " .. tostring(x) .. "," .. tostring(y) .. " with " .. made .. " units")
    local owner = get(get(sett, "ownerFaction"), "name")
    if owner ~= "mongols" then
        local okG, errG = pcall(function() army:siegeSettlement(sett, true) end)
        log("TEST siege of Urgench (owner " .. tostring(owner) .. ", take at once) "
            .. (okG and "started" or ("FAILED " .. tostring(errG))) .. "; mongols now hold "
            .. tostring(get(f, "settlementsNum")) .. " settlements")
    end
end

---------------------------------------------------------------------------------------------------------------------
-- turn start
---------------------------------------------------------------------------------------------------------------------
local function onTurnStart(eventData)
    local fac = get(eventData, "faction")
    local turn = turnNow()

    if TEST and turn >= TEST_SPAWN_TURN and counter(C_TEST_SPAWNED) == 0 then
        setCounter(C_TEST_SPAWNED, 1)
        testSpawn()
    end

    if get(fac, "name") ~= "mongols" then return end
    local settlements = get(fac, "settlementsNum") or 0

    if counter(C_DONE) == 0 then
        if turn >= CONVERT_TURN and settlements > 0 then
            convert(fac)
        elseif TEST then
            log("turn " .. turn .. ": not yet (" .. settlements .. " settlements)")
        end
        return
    end

    -- already converted: keep the religion (e.g. after loading a save) and convert temples in newly taken settlements
    if get(fac, "religion") ~= islamID() then
        log("religion was " .. tostring(get(fac, "religion")) .. " after conversion - set again")
        setIslam(fac)
    end
    local n = convertAllTemples(fac)
    if n > 0 then log("turn " .. turn .. ": " .. n .. " more temples converted") end
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

if not MI.installed then
    MI.installed = true
    afterHook("onFactionTurnStart", onTurnStart)
    log("loaded (TEST = " .. tostring(TEST) .. ", convert turn " .. CONVERT_TURN .. ")")
end

MongolIslam = MI
return MI
