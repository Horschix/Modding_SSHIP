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
-- ROUND 2 (user, 16 Oct: "all of them"): Georgia 2/3/4/6/7, England 2/3/5, Pantokrator, Omar Khayyam, Meteora,
--   Liber Secretorum, Scotland's first uprising (timed, see TIMED); Hildegard, the Mongol invasion and the Mongols in
--   the Caucasus (mirrors of live counters, see runMirrors). Floods removed by the user (16 Oct). Details in note 13.
-- TEST = true: timed events at turns 2-6.
-- Log prefix: LOSTEV (in full.log).
---------------------------------------------------------------------------------------------------------------------
local TEST = true

local CATHOLIC = { "france", "jerusalem", "hre", "england", "scotland", "denmark", "norway", "poland", "hungary", "sicily",
                   "venice", "pisa", "spain", "portugal", "aragon", "papal_states" }
local ORTHODOX = { "byzantium", "russia", "kievan_rus", "georgia", "serbia" }
local MUSLIM = { "egypt", "abbasid", "zengid", "turks", "rum", "moors" }
local CAUCASUS = { "georgia", "jerusalem", "byzantium", "turks", "cumans", "abbasid", "rum", "zengid", "kievan_rus" }

-- name = counter (and SSHIP historic_events.txt entry unless title/body are given); show = who sees the message
-- (players only; "all" = every player); turn = random turn in min..max, chosen once and kept in hx_turn_<name>.
local function W(name, minT, maxT, testT, show, title, body)
    return { name = name, min = TEST and testT or minT, max = TEST and testT or maxT, show = show, title = title, body = body }
end
local TIMED = {
    W("FIRST_COAT_OF_ARMS", 61, 80, 2, "all"),                  -- SSHIP: after 60, 10% a turn
    W("GEORGIAN8_TATAR_LANCERS_REFORM", 161, 180, 3, { "georgia" }),   -- SSHIP fall-back after 160
    -- Georgia: SSHIP's fall-back turns (its earlier routes needed buildings / marriages / crowned ruler)
    W("GEORGIAN2_GOLDEN_AGE", 130, 130, 2, CAUCASUS),
    W("GEORGIAN3_SHOTA_RUSTAVELI", 210, 210, 3, CAUCASUS),
    W("GEORGIAN4_CROSSBOW_IN_CAUCASUS", 290, 290, 4, CAUCASUS),
    W("GEORGIAN6_REVIVAL", 350, 350, 5, CAUCASUS),
    W("GEORGIAN7_LAST_UNITED_KINGDOM", 600, 600, 6, CAUCASUS),
    -- England: SSHIP "after turn X, 40% a turn" -> X+1 .. X+7 (Becket 1170 = turn 77, Magna Carta 1215 = 167)
    W("ENGLAND2_THOMAS_BECKET", 71, 77, 2, CATHOLIC),
    W("ENGLAND3_MAGNA_CARTA", 161, 167, 3, CATHOLIC),
    W("ENGLAND5_ENGLISH_ARCHERS", 301, 307, 4, CATHOLIC),
    -- turn-3 info events of SSHIP (were shown only to an Orthodox / Muslim player - now set for everyone)
    W("BYZANTINE_PANTOKRATOR", 3, 3, 3, ORTHODOX),
    W("omar_khayyam", 3, 3, 3, MUSLIM),
    W("BYZANTIUM7_METEORA", 85, 85, 4, ORTHODOX),               -- descr_events note: turn 85
    W("LIBER_SECRETORUM_TRANSLATED", 60, 90, 5, CATHOLIC,       -- EDB note: 60-90, no SSHIP text
      "The Secrets of Alchemy",
      "\nIn Spain and Italy the Latins translate the alchemical works of the Arabs - the Liber Secretorum of al-Razi "
      .. "among them.\n\nGAME: Catholic factions can build the alchemists' laboratory."),
    W("SCOTLAND_FIRST_UPRISING", 51, 70, 5, { "scotland" }),    -- no SSHIP timing known; our choice
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
local function playersIn(show)
    local list = {}
    local n = get(M2TW.campaign, "numberOfFactions") or 0
    for i = 0, n - 1 do
        local ok, f = pcall(function() return M2TW.campaign:getFactionByID(i) end)
        if ok and f and get(f, "isPlayerControlled") == 1 then
            local wanted = show == "all"
            if type(show) == "table" then for _, s in ipairs(show) do if s == f.name then wanted = true end end end
            if wanted then list[#list + 1] = f.name end
        end
    end
    return list
end

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
                local who = playersIn(e.show)
                if #who > 0 then
                    local ok, err
                    if e.title then
                        ok, err = pcall(function() M2TW.campaign.historicEvent(e.name, e.title, e.body, false, -1, -1, who) end)
                    else
                        ok, err = pcall(function() M2TW.campaign.execScriptEvent(e.name, "historic", 214, 122, 1, "") end)
                    end
                    if not ok then log("ERROR message " .. e.name .. ": " .. tostring(err)) end
                end
                setCounter(e.name, 1)
                log(e.name .. " at turn " .. turn .. " (shown to " .. (#who > 0 and table.concat(who, ",") or "nobody") .. ")")
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
-- mirrors of live SSHIP counters under the names the EDB uses
---------------------------------------------------------------------------------------------------------------------
local MONGOL_CAUCASUS_TILE = { 440, 194 }   -- the tile SSHIP's mongols.lua watches for the Blue Horde message

local function runMirrors()
    -- Hildegard: SSHIP's great-people counter (1 while she lives, turns 0-93)
    local h = counter("hildegard_von_bingen_in")
    if counter("hildegard_of_bingen") ~= h then setCounter("hildegard_of_bingen", h); log("hildegard_of_bingen = " .. h) end
    -- the Mongol invasion has begun (mongols.lua sets stage 1, later 2, 3)
    if counter("the_mongols_emerge") == 0 and (counter("mongols_invasion_stage_1") + counter("mongols_invasion_stage_2")
            + counter("mongols_invasion_stage_3")) > 0 then
        setCounter("the_mongols_emerge", 1); log("the_mongols_emerge = 1")
    end
    -- a Mongol army in the Caucasus (mongols.lua only shows the message, it sets no counter)
    if counter("mongols_blue_horde_caucasus") == 0 then
        local okF, m = pcall(function() return M2TW.campaign:getFaction("mongols") end)
        local okT, tile = pcall(function() return M2TW.stratMap.getTile(MONGOL_CAUCASUS_TILE[1], MONGOL_CAUCASUS_TILE[2]) end)
        if okF and m and okT and tile then
            local okN, near = pcall(function() return tile:factionHasArmyNearTile(m.factionID) end)
            if okN and near == true then
                setCounter("mongols_blue_horde_caucasus", 1)
                setCounter("mongols_reach_caucasus", 1)
                log("Mongols in the Caucasus: mongols_blue_horde_caucasus, mongols_reach_caucasus = 1")
            end
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
local function onTurnStart(eventData)
    local turn = turnNow()
    if turn == lastTurn then runMirrors(); runDerived(); return end   -- SSHIP's own turn code may set sources later
    lastTurn = turn
    runTimed(turn)
    runMirrors()
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
