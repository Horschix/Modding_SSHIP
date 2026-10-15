---------------------------------------------------------------------------------------------------------------------
-- lost_events.lua  (Modding_SSHIP, 16 Oct 2026)
-- Counters that SSHIP 0.98's buildings / units still wait for, but that only its commented-out campaign scripts
-- (factionsEvolutions.lua, buildings.lua, globalEvents.lua - all inside --[[ ]]) ever set. See note 13.
-- Chosen by the user (16 Oct 2026): everything except the FL right hand, antipope and bishop traits.
--
-- DERIVED counters (set as soon as SSHIP's live event has happened - as in SSHIP's old script):
--   templars_recruitment_enabled  <- ORDER_OMNE_DATUM_OPTIMUM_BULL   (Jerusalem: Templar Sergeant)
--   teutonic_hospital_founded     <- ORDER_TEUTONIC_HOSPITAL_FOUNDED (HRE: income bonus)
--   pisa_sacked_amalfi            <- PISA02_SACK_OF_AMALFI           (Pisa: cathedral wonder levels 6-9)
--   <f>_ostsiedlung_player        <- OSTSIEDLUNG, for a PLAYER hungary / poland / hre (law bonus)
--   poland3_first_tourney_player  <- POLAND3_FIRST_TOURNEY, player poland (tourney fields)
--   serbian3_saint_sava_player    <- SERBIAN3_SAINT_SAVA, player serbia (law bonus)
--   georgian3_shota_rustaveli_player <- GEORGIAN3_SHOTA_RUSTAVELI, player georgia (law bonus; GEORGIAN3 itself is
--                                     also dead in 0.98 - this line only works once that event comes back)
--   <f>_first_coat_of_arms_player <- FIRST_COAT_OF_ARMS, for 15 Catholic factions when PLAYER (jousting lists)
-- TIMED events (SSHIP's own fall-back, random turn chosen once and kept in a counter):
--   FIRST_COAT_OF_ARMS            turn 61-80   (SSHIP: after turn 60, 10% a turn), shown to everyone
--   GEORGIAN8_TATAR_LANCERS_REFORM turn 161-180 (SSHIP: after 160, 10% a turn; its early route - 10 won battles
--                                  against the Mongols while holding Kutaisi and Tbilisi - is not rebuilt),
--                                  shown to Georgia (Naqivchaqari Cavalry)
-- FACTION KILLER: SSHIP's TriumphsOverFaction_<f> traits wait for Ceased_<f> counters that are never set (and the old
--   way was crude: any leader ending his turn after any leader's death got it). Rebuilt with EOP: the faction that
--   took a faction's last settlement is remembered; when that faction dies, its conqueror's faction leader gets
--   10 points of FactionKiller (= the trait's first level "Conqueror", as the old triggers gave).
-- TEST = true: FIRST_COAT_OF_ARMS turn 2, GEORGIAN8 turn 3. Log prefix: LOSTEV (in full.log).
---------------------------------------------------------------------------------------------------------------------
local TEST = true

local TIMED = {
    { name = "FIRST_COAT_OF_ARMS", min = TEST and 2 or 61, max = TEST and 2 or 80, faction = "all" },
    { name = "GEORGIAN8_TATAR_LANCERS_REFORM", min = TEST and 3 or 161, max = TEST and 3 or 180, faction = "georgia" },
}

-- { source counter, target counter, player faction or nil (= any / global) }
local DERIVED = {
    { "ORDER_OMNE_DATUM_OPTIMUM_BULL", "templars_recruitment_enabled" },
    { "ORDER_TEUTONIC_HOSPITAL_FOUNDED", "teutonic_hospital_founded" },
    { "PISA02_SACK_OF_AMALFI", "pisa_sacked_amalfi" },
    { "OSTSIEDLUNG", "hungary_ostsiedlung_player", "hungary" },
    { "OSTSIEDLUNG", "poland_ostsiedlung_player", "poland" },
    { "OSTSIEDLUNG", "hre_ostsiedlung_player", "hre" },
    { "POLAND3_FIRST_TOURNEY", "poland3_first_tourney_player", "poland" },
    { "SERBIAN3_SAINT_SAVA", "serbian3_saint_sava_player", "serbia" },
    { "GEORGIAN3_SHOTA_RUSTAVELI", "georgian3_shota_rustaveli_player", "georgia" },
    { "GEORGIAN8_TATAR_LANCERS_REFORM", "georgian8_tatar_lancers_reform_player", "georgia" },
}
for _, f in ipairs({ "france", "jerusalem", "hre", "england", "scotland", "denmark", "norway", "poland", "hungary",
                     "sicily", "venice", "pisa", "spain", "portugal", "aragon" }) do
    DERIVED[#DERIVED + 1] = { "FIRST_COAT_OF_ARMS", f .. "_first_coat_of_arms_player", f }
end

local KILLER_TRAIT = "FactionKiller"
local KILLER_POINTS = 10

local LE = LostEvents or {}
LE.lastConqueror = LE.lastConqueror or {}   -- [loser faction name] = winner faction name (this session only)

---------------------------------------------------------------------------------------------------------------------
local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("LOSTEV " .. tostring(text))
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

local function turnNow() return get(M2TW.campaign, "turnNumber") or -1 end

local function faction(name)
    local ok, f = pcall(function() return M2TW.campaign:getFaction(name) end)
    if ok then return f end
    return nil
end

local function isPlayerFaction(name)
    return get(faction(name), "isPlayerControlled") == 1
end

local function anyPlayer(names)
    if names == "all" then return true end
    return isPlayerFaction(names)
end

---------------------------------------------------------------------------------------------------------------------
local function runTimed(turn)
    for _, e in ipairs(TIMED) do
        if counter(e.name) == 0 then
            local key = "hx_turn_" .. string.lower(e.name)
            local at = counter(key)
            if at == 0 then
                at = e.min + math.random(0, e.max - e.min)
                setCounter(key, at)
                log(e.name .. " will come at turn " .. at)
            end
            if turn >= at then
                if anyPlayer(e.faction) then
                    local ok, err = pcall(function() M2TW.campaign.execScriptEvent(e.name, "historic", 214, 122, 1, "") end)
                    if not ok then log("ERROR execScriptEvent " .. e.name .. ": " .. tostring(err)) end
                end
                setCounter(e.name, 1)
                log(e.name .. " at turn " .. turn)
            end
        end
    end
end

local function runDerived()
    for _, d in ipairs(DERIVED) do
        local src, dst, fac = d[1], d[2], d[3]
        if counter(src) > 0 and counter(dst) == 0 and (fac == nil or isPlayerFaction(fac)) then
            setCounter(dst, 1)
            log(dst .. " = 1 (" .. src .. " happened" .. (fac and (", player " .. fac) or "") .. ")")
        end
    end
end

---------------------------------------------------------------------------------------------------------------------
-- faction killer
---------------------------------------------------------------------------------------------------------------------
local function onOccupy(eventData)
    local winner, loser = get(eventData, "faction"), get(eventData, "targetFaction")
    local w, l = get(winner, "name"), get(loser, "name")
    if w and l and w ~= l and w ~= "slave" then LE.lastConqueror[l] = w end
end

local function onDied(f)
    local l = get(f, "name")
    if l == nil or l == "slave" then return end
    local w = LE.lastConqueror[l]
    if w == nil then log("faction " .. l .. " died - no conqueror known (rebels or before a reload)"); return end
    local leader = get(faction(w), "leader")
    local rec = get(leader, "characterRecord") or leader
    if rec == nil then log("faction " .. l .. " died - conqueror " .. w .. " has no leader"); return end
    local ok, err = pcall(function() rec:addTraitPoints(KILLER_TRAIT, KILLER_POINTS) end)
    log("faction " .. l .. " destroyed by " .. w .. ": " .. tostring(get(rec, "shortName")) .. " gets " .. KILLER_TRAIT
        .. " +" .. KILLER_POINTS .. (ok and "" or (" ERROR " .. tostring(err))))
end

---------------------------------------------------------------------------------------------------------------------
local lastTurn = -1
local function onTurnStart()
    local turn = turnNow()
    if turn == lastTurn then runDerived(); return end   -- derived ones may come from SSHIP's own turn code
    lastTurn = turn
    runTimed(turn)
    runDerived()
end

local function afterHook(name, fn)
    local previous = _G[name]
    _G[name] = function(...)
        local result = nil
        if previous then result = previous(...) end
        local ok, err = pcall(fn, ...)
        if not ok then log("ERROR after " .. name .. ": " .. tostring(err)) end
        return result
    end
end

if not LE.installed then
    LE.installed = true
    afterHook("onFactionTurnStart", onTurnStart)
    afterHook("onOccupySettlement", onOccupy)
    afterHook("onFactionDied", onDied)
    log("loaded (TEST = " .. tostring(TEST) .. ")")
end

LostEvents = LE
return LE
