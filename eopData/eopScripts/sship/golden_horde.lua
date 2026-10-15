---------------------------------------------------------------------------------------------------------------------
-- golden_horde.lua  (Modding_SSHIP, 15 Oct 2026)
-- The Cumans become the Golden Horde, and later turn Muslim. Decided by the user on 15 Oct 2026:
--   * GH_TURN 221 (1242, Batu returns from the west, Sarai founded): AI Cumans become the Golden Horde at once;
--     a player Cuman faction gets a yes/no question. YES (or AI) ->
--       - faction name "Golden Horde" (factionStruct.localizedName, as EUR's eurEvolvingFactions.lua does);
--         set again at every Cuman turn start and map load, since the engine may reset it on load
--       - the Mongol roster (ownership set by script, recruit lines in export_descr_buildings carry
--         "factions { cumans, } and event_counter golden_horde 1"); the dhow is left out (the ladya stays)
--       - Keshikten Bodyguard becomes the general's bodyguard; the Cuman nobles (Behk / Khagan Druzhina and their
--         dismounted versions, Cuman Bodyguard) can no longer be recruited
--       - kept from the old roster: Cuman Horse Militia, Dismounted Cuman Militia, Kasogi, Kasogi Senior Militia,
--         ladya, EE Spear Militia, siege engines
--     NO -> nothing changes (the conversion to Islam still comes).
--   * ISLAM_TURN 361 (Ozbeg Khan, 1313; user's turn): always, for player and AI: faction religion islam, counter
--     cumans_islam = 1, Tengri temples become mosques (also in settlements taken later), Muslim units owned:
--     Muslim Settlers (instead of Pagan Settlers), Mutatawwi Warriors, Ahdath Militia, Naffatun, Ghulams,
--     Dismounted Ghulams.
-- Unit ownership set by script is not stored in the save -> applied again at every Cuman turn start and map load.
-- TEST = true: GH_TURN 2, ISLAM_TURN 4. Log prefix: GHORDE (in full.log).
---------------------------------------------------------------------------------------------------------------------
local TEST = true
local GH_TURN = TEST and 2 or 221
local ISLAM_TURN = TEST and 4 or 361

local C_GH = "golden_horde"            -- 1 = the Cumans are the Golden Horde (also used in export_descr_buildings)
local C_ASKED = "golden_horde_asked"   -- 1 = the player was asked / the AI decision was made
local C_DECLINED = "golden_horde_no"   -- 1 = the player said no
local C_ISLAM = "cumans_islam"         -- 1 = converted (also used in export_descr_buildings)
local EVENT = "GOLDEN_HORDE"           -- choice event; the answer comes as counter GOLDEN_HORDE_accepted / _declined

local GH_NAME = "Golden Horde"

local MONGOL_ROSTER = {
    "ME Peasant Archers", "Kashtim Thralls", "Hoshiga Horse Archers", "Hoschuchi Lancers", "Khorchi Horse Archers",
    "Turhagut Lancers", "Lubchiten Horse Archers", "Khabutu Archers", "Disamounted Turhagut",
    "Sibiryaki Junior Militia", "Sibiryaki Senior Militia", "Merguen Archers", "Dismounted Khorchi Archers",
    "AS Rocket Launcher", "Nukeri Horse Archers", "ME Trebuchet", "ME Bombard", "Keshikten Bodyguard",
}
local DROPPED_AT_GH = { "Behk Druzhina", "Khagan Druzhina", "Dismounted Khagan Druzhina", "Dismounted Bekh Druzhina",
                        "Cuman Bodyguard" }
local ISLAM_UNITS = { "Muslim Settlers", "Mutatawwi Warriors", "Ahdath Militia", "Naffatun", "Ghulams",
                      "Dismounted Ghulams" }
local DROPPED_AT_ISLAM = { "Pagan Settlers" }

local TEMPLE_MAP = {
    tengir_altar     = "small_masjid",
    tengir_sanctuary = "masjid",
    tengir_temple    = "minareted_masjid",
    c_tengir_altar   = "c_small_masjid",
}

local Q_TITLE = "The Golden Horde"
local Q_BODY = "\nBatu Khan has returned from the lands of the Franks and Magyars. On the lower Volga his men raise a new "
    .. "capital, Sarai, and the steppe from the Irtysh to the Danube now answers to the house of Jochi.\n\n"
    .. "The Kipchak clans make up most of his host. Their beys may bow to the Khan and become the Golden Horde - "
    .. "the Ulus of Jochi - or keep to their own ways.\n\n"
    .. "YES: the Cumans become the Golden Horde. They recruit the Mongol roster and keep their Kipchak horse "
    .. "militia, Kasogi, ladya and militia; the old Cuman nobles (druzhina) leave the roster, and new generals "
    .. "ride with Keshikten guards.\n\nNO: the Cumans stay as they are."
local GH_TITLE = "The Golden Horde"
local GH_BODY = "\nBatu Khan has returned from the west and founded Sarai on the lower Volga. The Kipchak steppe is now "
    .. "the Ulus of Jochi - the Golden Horde.\n\nGAME: The Cumans are now the Golden Horde and recruit the Mongol roster."
local ISL_TITLE = "The Golden Horde embraces Islam"
local ISL_BODY = "\nBerke Khan had already become a Muslim, but it was Ozbeg Khan who made Islam the religion of the "
    .. "Golden Horde in 1313. The shamans of Tengri give way to imams, and the old temples of the steppe become "
    .. "mosques.\n\nGAME: The Golden Horde (Cumans) is now a Muslim faction. Tengri temples have become mosques; "
    .. "Muslim Settlers, Mutatawwi Warriors, Ahdath Militia, Naffatun and Ghulams can be recruited."

local GH = GoldenHorde or {}

---------------------------------------------------------------------------------------------------------------------
-- helpers (a wrong field name must never crash the game)
---------------------------------------------------------------------------------------------------------------------
local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("GHORDE " .. tostring(text))
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

local function cumans()
    local ok, f = pcall(function() return M2TW.campaign:getFaction("cumans") end)
    if ok then return f end
    return nil
end

local function islamID()
    local ok, id = pcall(function() return M2TWEOP.getReligion("islam") end)
    if ok and type(id) == "number" and id >= 0 then return id end
    return 2
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

local function event(name, title, body)
    local factions = playerFactionNames()
    if #factions == 0 then return end
    local ok, err = pcall(function() M2TW.campaign.historicEvent(name, title, body, false, -1, -1, factions) end)
    if not ok then log("ERROR historicEvent " .. name .. ": " .. tostring(err)) end
end

-- unit ownership by script; returns how many entries changed
local function setOwnership(f, list, value)
    local fid = get(f, "factionID")
    if fid == nil then return 0 end
    local changed, missing = 0, {}
    for _, u in ipairs(list) do
        local okE, e = pcall(function() return M2TWEOPDU.getEduEntryByType(u) end)
        if okE and e then
            local okH, has = pcall(function() return e:hasOwnership(fid) end)
            if not (okH and has == value) then
                local okS = pcall(function() e:setOwnership(fid, value) end)
                if okS then changed = changed + 1 else missing[#missing + 1] = u .. " (set failed)" end
            end
        else
            missing[#missing + 1] = u
        end
    end
    if #missing > 0 then log("ownership: not found " .. table.concat(missing, ", ")) end
    return changed
end

local function applyName(f)
    if get(f, "localizedName") == GH_NAME then return end
    local ok, err = pcall(function() f.localizedName = GH_NAME end)
    log("name -> " .. GH_NAME .. ": " .. (ok and ("reads back " .. tostring(get(f, "localizedName"))) or ("ERROR " .. tostring(err))))
end

-- everything that is not stored in the save (name, unit ownership) - safe to call again and again
local function applyState(f, why)
    if f == nil then return end
    local n = 0
    if counter(C_GH) == 1 then
        applyName(f)
        n = n + setOwnership(f, MONGOL_ROSTER, true) + setOwnership(f, DROPPED_AT_GH, false)
    end
    if counter(C_ISLAM) == 1 then
        n = n + setOwnership(f, ISLAM_UNITS, true) + setOwnership(f, DROPPED_AT_ISLAM, false)
    end
    if n > 0 then log("state applied (" .. why .. "): " .. n .. " ownership changes") end
end

---------------------------------------------------------------------------------------------------------------------
-- Golden Horde
---------------------------------------------------------------------------------------------------------------------
local function become(f, why)
    if counter(C_GH) == 1 then return end
    setCounter(C_GH, 1)
    applyState(f, "golden horde")
    local okB, bg = pcall(function() return M2TWEOPDU.findGeneralUnit(f.factionID) end)
    log("BECAME THE GOLDEN HORDE at turn " .. turnNow() .. " (" .. why .. "); general unit now "
        .. tostring(okB and get(bg, "eduType") or "?"))
    event("GOLDEN_HORDE_FOUNDED", GH_TITLE, GH_BODY)
end

local function ask(f)
    setCounter(C_ASKED, 1)
    if get(f, "isPlayerControlled") == 1 then
        local ok, err = pcall(function()
            M2TW.campaign.historicEvent(EVENT, Q_TITLE, Q_BODY, true, -1, -1, { "cumans" })
        end)
        log("question to player Cumans" .. (ok and " shown" or (" FAILED: " .. tostring(err))))
    else
        become(f, "AI")
    end
end

---------------------------------------------------------------------------------------------------------------------
-- Islam
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
    for i = 0, (get(f, "settlementsNum") or 0) - 1 do
        local ok, s = pcall(function() return f:getSettlement(i) end)
        if ok and s then total = total + convertTemples(s) end
    end
    return total
end

local function setIslam(f)
    local id = islamID()
    local ok, err = pcall(function() f.religion = id end)
    local now = get(f, "religion")
    log("faction religion set to " .. tostring(id) .. ", reads back " .. tostring(now) .. (ok and "" or (" ERROR " .. tostring(err))))
    return now == id
end

local function convert(f)
    local okSet = setIslam(f)
    setCounter(C_ISLAM, 1)
    applyState(f, "islam")
    local temples = convertAllTemples(f)
    log("CONVERTED at turn " .. turnNow() .. " (" .. temples .. " temples, religion ok = " .. tostring(okSet) .. ")")
    event("GOLDEN_HORDE_ISLAM", ISL_TITLE, ISL_BODY)
end

---------------------------------------------------------------------------------------------------------------------
-- hooks
---------------------------------------------------------------------------------------------------------------------
local function onTurnStart(eventData)
    local f = get(eventData, "faction")
    if get(f, "name") ~= "cumans" then return end
    if (get(f, "settlementsNum") or 0) == 0 and (get(f, "numOfCharacters") or 0) == 0 then return end
    local turn = turnNow()
    applyState(f, "turn start")
    if counter(C_ASKED) == 0 and turn >= GH_TURN then ask(f) end
    if counter(C_ISLAM) == 0 then
        if turn >= ISLAM_TURN then convert(f) end
        return
    end
    if get(f, "religion") ~= islamID() then
        log("religion was " .. tostring(get(f, "religion")) .. " after conversion - set again")
        setIslam(f)
    end
    local n = convertAllTemples(f)
    if n > 0 then log("turn " .. turn .. ": " .. n .. " more temples converted") end
end

local function onCounter(eventData)
    local name = get(eventData, "eventCounter")
    if name == EVENT .. "_accepted" and counter(name) > 0 then
        setCounter(name, 0)
        become(cumans(), "player said yes")
    elseif name == EVENT .. "_declined" and counter(name) > 0 then
        setCounter(name, 0)
        setCounter(C_DECLINED, 1)
        log("player Cumans declined - they stay Cumans")
    end
end

local function onMapLoaded()
    applyState(cumans(), "map loaded")
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

if not GH.installed then
    GH.installed = true
    afterHook("onFactionTurnStart", onTurnStart)
    afterHook("onEventCounter", onCounter)
    afterHook("onCampaignMapLoaded", onMapLoaded)
    log("loaded (TEST = " .. tostring(TEST) .. ", golden horde turn " .. GH_TURN .. ", islam turn " .. ISLAM_TURN .. ")")
end

GoldenHorde = GH
return GH
