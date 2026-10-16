---------------------------------------------------------------------------------------------------------------------
-- dynasties.lua  (Modding_SSHIP, 16 Oct 2026)
-- New dynasties for Egypt and the Zengids, and the Muslim army reforms that SSHIP 0.98 lost.
--
-- WHY: SSHIP 0.98 moved its faction evolutions into factionsEvolutions.lua, but that whole file is still a Lua
-- comment and the old campaign_script.txt no longer has them. So the counters that export_descr_buildings waits for
-- were never set: Egypt, Zengids and Abbasids could never recruit Ghulams, Mamluks, Amir's Guard, Mamluk Archers,
-- Tabardariyya, Abtal, Caliph's Guard, Jaridah. This script sets those counters at historical turns
-- (turn = (year - 1132) * 2 + 1), for player and AI, whatever the player answers to a rename question.
--
-- Decided by the user (16 Oct 2026):
--   EGYPT   turn  79 (1171, Saladin ends the Fatimid caliphate): ayyubids_rise (+ fatimid_evolution for SSHIP's
--                      Mamluk adoption trait); faction renamed "Ayyubid Sultanate"
--           turn 119 (1191, SSHIP's own 40 turns later): first_mamluks
--           turn 237 (1250, Turanshah murdered): mamluks_established + mamluks_rise; renamed "Mamluk Sultanate"
--           Each rename: AI always, a player Egypt gets a yes/no question (NO = keeps its current name).
--   ZENGIDS turn  29 (1146, Nur ad-Din): zengids_rise + zengid_evolution; first_mamluks_zengid 79, established 129
--           (SSHIP's own +50 / +100).
--   ABBASIDS turn 51 (1157, siege of Baghdad): abbasids_rise; first_mamluks_abbasid 111, established 151
--           (SSHIP's own +60 / +100).
--   ERETNIDS from turn 409 (1335, death of the Ilkhan Abu Sa'id), at a Zengid turn start while the Zengids live:
--           Sivas goes to the Zengids (garrison converted) unless a human player other than the Zengids holds it or
--           it is a crusade target (then: tried again every turn); Eretna spawns there and becomes faction leader;
--           every Zengid settlement outside Anatolia goes to the rebels with its garrison, and every Zengid general
--           or family member outside Anatolia (admirals at sea excepted) switches to the rebels with his army;
--           the faction is renamed "Eretnids". A player Zengid faction is asked first (NO = nothing happens, ever).
--           Anatolia = the regions below (today's Turkey west of the Euphrates, with Cilicia).
-- Names (localizedName) are not stored in the save -> set again at every turn start and map load.
-- TEST = true: everything in the first turns (see below). Log prefix: DYNAST (in full.log).
---------------------------------------------------------------------------------------------------------------------
local TEST = false
-- ERETNID_TEST = true: only the Eretnids come early (turn 6) - their part was not reached in test 1 (16 Oct).
local ERETNID_TEST = true

local T = TEST and {
    ayyubid = 3, egypt_fm = 4, mamluk = 5,
    zengid = 2, zengid_fm = 3, zengid_est = 4,
    abbasid = 2, abbasid_fm = 3, abbasid_est = 4,
    eretnid = 6,
} or {
    ayyubid = 79, egypt_fm = 119, mamluk = 237,
    zengid = 29, zengid_fm = 79, zengid_est = 129,
    abbasid = 51, abbasid_fm = 111, abbasid_est = 151,
    eretnid = 409,
}
if ERETNID_TEST then T.eretnid = 6 end

local NAME_AYYUBID = "Ayyubid Sultanate"
local NAME_MAMLUK = "Mamluk Sultanate"
local NAME_ERETNID = "Eretnids"

-- our own state counters (all start at 0)
local C_EGYPT_NAME = "hx_egypt_name"       -- 0 Fatimids, 1 Ayyubids, 2 Mamluks
local C_EGYPT_ASK1 = "hx_egypt_asked1"     -- 1 = the turn-79 step is done (asked / AI decided)
local C_EGYPT_ASK2 = "hx_egypt_asked2"     -- 1 = the turn-237 step is done
local C_ERET = "hx_eretnids"               -- 0 not yet, 1 done, 8 asked (waiting for the answer), 9 player said no
local Q_AYYUBID = "HX_AYYUBIDS"            -- choice events; answers come as <name>_accepted / _declined
local Q_MAMLUK = "HX_MAMLUKS"
local Q_ERETNID = "HX_ERETNIDS"

local ANATOLIA = {
    Nicaea_Province = true, Smyrna_Province = true, Attaleia_Province = true, Konya_Province = true,
    Angora_Province = true, Sinop_Province = true, Trebizond_Province = true, Caesarea_Province = true,
    Sives_Province = true, Sis_Province = true, Malatya_Province = true,
}
local SIVAS_REGION = "Sives_Province"

-- counter steps: { turn key, faction shown the message, counters to set, message title, message body }
local STEPS = {
    { "zengid", "zengid", { "zengids_rise", "zengid_evolution" }, "The Zengids Rise in Syria",
      "\nNur ad-Din, son of Zengi, rules from Aleppo. He reforms the army around a core of professional cavalry.\n\n"
      .. "GAME: Abtal Cavalry, Caliph's Guard, Jaridah Cavalry and Ghulams can now be recruited." },
    { "zengid_fm", "zengid", { "first_mamluks_zengid" }, "The first Mamluks",
      "\nThe atabegs buy and train slave soldiers of their own.\n\nGAME: Amir's Guard and Mamluk Archers can now be recruited." },
    { "zengid_est", "zengid", { "mamluks_established_zengid" }, "The Mamluks established",
      "\nThe Mamluk regiments are now the backbone of the army.\n\nGAME: Mamluks and Dismounted Mamluk Archers can now be recruited." },
    { "abbasid", "abbasid", { "abbasids_rise" }, "The Abbasids Rise again in Mesopotamia",
      "\nCaliph al-Muqtafi has held Baghdad against the Seljuks. After centuries under foreign masters the Caliphate "
      .. "has its own army again.\n\nGAME: Abtal Cavalry, Caliph's Guard, Jaridah Cavalry and Ghulams can now be recruited." },
    { "abbasid_fm", "abbasid", { "first_mamluks_abbasid" }, "The first Mamluks",
      "\nThe Caliph buys and trains slave soldiers of his own.\n\nGAME: Mamluk Archers can now be recruited." },
    { "abbasid_est", "abbasid", { "mamluks_established_abbasid" }, "The Mamluks established",
      "\nThe Mamluk regiments are now the backbone of the army.\n\nGAME: Mamluks and Dismounted Mamluk Archers can now be recruited." },
    { "ayyubid", "egypt", { "ayyubids_rise", "fatimid_evolution" }, nil, nil },   -- message comes with the rename
    { "egypt_fm", "egypt", { "first_mamluks" }, "The first Mamluks",
      "\nThe Sultan's own slave regiments grow in number.\n\nGAME: Amir's Guard and Mamluk Archers can now be recruited." },
    { "mamluk", "egypt", { "mamluks_established", "mamluks_rise" }, nil, nil },    -- message comes with the rename
}

local AYY_Q = "\nIn 1169 Shirkuh's nephew Salah ad-Din Yusuf ibn Ayyub became vizier of Egypt. Two years later he ended "
    .. "the Fatimid caliphate: the Friday prayer is said again in the name of the Abbasid Caliph, and Egypt is ruled "
    .. "by the house of Ayyub.\n\nThe army is reformed in any case: Fari Lancers and Horse Archers give way to Ghulams.\n\n"
    .. "YES: the faction is renamed Ayyubid Sultanate.\nNO: the faction keeps its name."
local AYY_T = "The Ayyubids Rise in Egypt"
local AYY_B = "\nSalah ad-Din has ended the Fatimid caliphate. Egypt is ruled by the house of Ayyub.\n\n"
    .. "GAME: Egypt is now the Ayyubid Sultanate. Ghulams replace the Fari cavalry."
local MAM_Q = "\nThe Bahri Mamluks have murdered Sultan Turanshah, the last Ayyubid of Egypt. Their commander Aybak "
    .. "marries the widow Shajar al-Durr and takes the throne: the slaves have become the masters.\n\n"
    .. "The Mamluk regiments are now established in any case (Mamluks, Dismounted Mamluk Archers, Al Haqa Infantry, "
    .. "Tabardariyya).\n\nYES: the faction is renamed Mamluk Sultanate.\nNO: the faction keeps its name."
local MAM_T = "The Mamluks Rise in Egypt"
local MAM_B = "\nThe Bahri Mamluks have murdered Turanshah, the last Ayyubid sultan of Egypt, and taken the throne.\n\n"
    .. "GAME: Egypt is now the Mamluk Sultanate. Mamluks, Dismounted Mamluk Archers, Al Haqa Infantry and "
    .. "Tabardariyya can be recruited."
local ERE_Q = "\nThe Ilkhan Abu Sa'id has died without an heir and the Ilkhanate falls apart. Its governor in Anatolia, "
    .. "the Uyghur general Eretna, makes himself master of Sivas and Kayseri. Our nobles offer him the throne.\n\n"
    .. "YES: Sivas becomes ours, Eretna becomes faction leader and the faction is renamed Eretnids. Every settlement, "
    .. "general and army outside Anatolia goes over to the rebels.\nNO: nothing changes."
local ERE_T = "The Eretnids"
local ERE_B = "\nThe Ilkhanate has fallen apart. Eretna, its governor in Anatolia, rules from Sivas and founds a new "
    .. "dynasty.\n\nGAME: The Zengids are now the Eretnids. Their lands outside Anatolia have gone over to the rebels."

local DY = Dynasties or {}

---------------------------------------------------------------------------------------------------------------------
-- helpers (a wrong field name must never crash the game)
---------------------------------------------------------------------------------------------------------------------
local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("DYNAST " .. tostring(text))
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

local function alive(f) return f ~= nil and (get(f, "settlementsNum") or 0) > 0 end
local function isPlayer(f) return get(f, "isPlayerControlled") == 1 end

local function playerFactionNames()
    local names = {}
    local n = get(M2TW.campaign, "numberOfFactions") or 0
    for i = 0, n - 1 do
        local ok, f = pcall(function() return M2TW.campaign:getFactionByID(i) end)
        if ok and f and get(f, "isPlayerControlled") == 1 then names[#names + 1] = f.name end
    end
    return names
end

-- message to the given player factions (all players when nil)
local function event(name, title, body, factions)
    factions = factions or playerFactionNames()
    if #factions == 0 then return end
    local ok, err = pcall(function() M2TW.campaign.historicEvent(name, title, body, false, -1, -1, factions) end)
    if not ok then log("ERROR historicEvent " .. name .. ": " .. tostring(err)) end
end

local function ask(name, title, body, factionName)
    local ok, err = pcall(function() M2TW.campaign.historicEvent(name, title, body, true, -1, -1, { factionName }) end)
    log("question " .. name .. " to player " .. factionName .. (ok and " shown" or (" FAILED: " .. tostring(err))))
    return ok
end

local function regionName(id)
    if id == nil then return nil end
    local ok, r = pcall(function() return M2TW.stratMap.getRegion(id) end)
    if ok then return get(r, "regionName") end
    return nil
end

local function tileRegionName(x, y)
    local ok, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
    if not ok or tile == nil then return nil end
    return regionName(get(tile, "regionID"))
end

local function applyName(f, name)
    if f == nil or name == nil or get(f, "localizedName") == name then return end
    local ok, err = pcall(function() f.localizedName = name end)
    log("name " .. tostring(get(f, "name")) .. " -> " .. name .. ": "
        .. (ok and ("reads back " .. tostring(get(f, "localizedName"))) or ("ERROR " .. tostring(err))))
end

local function egyptName()
    local n = counter(C_EGYPT_NAME)
    if n == 1 then return NAME_AYYUBID elseif n == 2 then return NAME_MAMLUK end
    return nil
end

-- names are not stored in the save
local function applyNames()
    applyName(faction("egypt"), egyptName())
    if counter(C_ERET) == 1 then applyName(faction("zengid"), NAME_ERETNID) end
end

---------------------------------------------------------------------------------------------------------------------
-- counter steps (reforms) - global counters, set even when the faction is dead (a re-emerged faction gets them)
---------------------------------------------------------------------------------------------------------------------
local function runSteps(turn)
    for _, s in ipairs(STEPS) do
        local key, facName, counters, title, body = s[1], s[2], s[3], s[4], s[5]
        if turn >= T[key] and counter(counters[1]) == 0 then
            for _, c in ipairs(counters) do setCounter(c, 1) end
            log("step " .. key .. " at turn " .. turn .. ": " .. table.concat(counters, ", ") .. " = 1")
            local f = faction(facName)
            if title and alive(f) and isPlayer(f) then event("HX_STEP_" .. key, title, body, { facName }) end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------
-- Egypt renames
---------------------------------------------------------------------------------------------------------------------
local function renameEgypt(level, why)
    local f = faction("egypt")
    if counter(C_EGYPT_NAME) >= level then return end
    setCounter(C_EGYPT_NAME, level)
    applyName(f, egyptName())
    log("EGYPT renamed " .. egyptName() .. " at turn " .. turnNow() .. " (" .. why .. ")")
    if not alive(f) then return end
    if level == 1 then event("HX_AYYUBIDS_DONE", AYY_T, AYY_B) else event("HX_MAMLUKS_DONE", MAM_T, MAM_B) end
end

local function egyptStep(f, level)
    local askC = level == 1 and C_EGYPT_ASK1 or C_EGYPT_ASK2
    if counter(askC) ~= 0 then return end
    setCounter(askC, 1)
    if not alive(f) then log("Egypt rename " .. level .. ": Egypt not alive - name kept for a re-emergence"); renameEgypt(level, "faction dead"); return end
    if isPlayer(f) then
        if level == 1 then ask(Q_AYYUBID, AYY_T, AYY_Q, "egypt") else ask(Q_MAMLUK, MAM_T, MAM_Q, "egypt") end
    else
        renameEgypt(level, "AI")
    end
end

---------------------------------------------------------------------------------------------------------------------
-- Eretnids
---------------------------------------------------------------------------------------------------------------------
local function sivas()
    local okR, r = pcall(function() return M2TW.stratMap:getRegionByName(SIVAS_REGION) end)
    local s = okR and get(r, "settlement") or nil
    if s == nil then
        local ok, s2 = pcall(function() return M2TW.stratMap:getSettlement("Sives") end)
        if ok then s = s2 end
    end
    return s
end

-- nil when Sivas can be taken now, otherwise the reason
local function sivasBlocked(s)
    if s == nil then return "Sivas not found" end
    local owner = get(s, "faction")
    if owner and get(owner, "name") ~= "zengid" and isPlayer(owner) then return "held by player " .. tostring(owner.name) end
    local okC, target = pcall(function() return M2TW.campaign.crusade.targetSettlement end)
    if okC and target ~= nil and get(target, "regionID") == get(s, "regionID") then return "crusade target" end
    return nil
end

local function spawnTile(sett)
    local sx, sy, region = sett.xCoord, sett.yCoord, get(sett, "regionID")
    for r = 1, 3 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local x, y = sx + dx, sy + dy
                    local okT, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
                    local okF, free = pcall(function() return M2TWEOP.isTileFree(x, y) end)
                    if okT and tile and get(tile, "isLand") == 1 and get(tile, "regionID") == region and okF and free then
                        return x, y
                    end
                end
            end
        end
    end
    return sx + 1, sy
end

local function eduIndex(unitType)
    local ok, idx = pcall(function() return M2TWEOPDU.getEduIndexByType(unitType) end)
    if ok then return idx end
    return nil
end

local function spawnEretna(f, s)
    local bgType = counter("late_era") == 1 and "ME Late Bodyguard" or "ME Bodyguard"
    local bg = eduIndex(bgType)
    if bg == nil then log("ERROR unit type not found: " .. bgType); return nil end
    local x, y = spawnTile(s)
    local ok, army = pcall(function()
        return f:spawnArmy("Eretna", "", characterType.named_character, "hx_eretna", "", x, y, 45, true, 31, bg, 3, 0, 0)
    end)
    if not ok or army == nil then log("ERROR spawnArmy Eretna: " .. tostring(army)); return nil end
    local rec = get(get(army, "leader"), "characterRecord")
    for _, t in ipairs({ { "MilitaryInclination", 1 }, { "LoyaltyStarter", 1 }, { "ReligionStarter", 1 } }) do
        pcall(function() rec:addTrait(t[1], t[2]) end)
    end
    pcall(function() rec.isFamily = true end)
    -- into Sivas, so he stands in his capital
    local okM, errM = pcall(function() army:moveTactical(s.xCoord, s.yCoord, true) end)
    log("spawned Eretna (" .. bgType .. ") at " .. x .. "," .. y .. ", family " .. tostring(get(rec, "isFamily"))
        .. ", move into Sivas " .. (okM and "ok" or ("ERROR " .. tostring(errM))))
    return rec
end

local function becomeEretnids(f, why)
    local s = sivas()
    local blocked = sivasBlocked(s)
    if blocked then log("Eretnids wait: " .. blocked); return false end
    local rebels = faction("slave")
    -- 1) Sivas
    local owner = get(s, "faction")
    if get(owner, "name") ~= "zengid" then
        local ok, err = pcall(function() s:changeOwner(f, true) end)
        log("Sivas from " .. tostring(get(owner, "name")) .. " to zengid: " .. (ok and "ok" or ("ERROR " .. tostring(err))))
        if not ok then return false end
    end
    pcall(function() f:setCapital(s) end)
    -- 2) Eretna, faction leader
    local rec = spawnEretna(f, s)
    if rec then
        local ok, err = pcall(function() f:setLeader(rec, true) end)
        log("setLeader Eretna: " .. (ok and ("ok, isLeader = " .. tostring(rec:isLeader())) or ("ERROR " .. tostring(err))))
    end
    -- 3) settlements outside Anatolia to the rebels (garrison converted)
    local outside = {}
    for i = 0, (get(f, "settlementsNum") or 0) - 1 do
        local ok, st = pcall(function() return f:getSettlement(i) end)
        if ok and st and not ANATOLIA[regionName(get(st, "regionID")) or ""] then outside[#outside + 1] = st end
    end
    local nS = 0
    for _, st in ipairs(outside) do
        local ok, err = pcall(function() st:changeOwner(rebels, true) end)
        if ok then nS = nS + 1 else log("ERROR changeOwner " .. tostring(get(st, "name")) .. ": " .. tostring(err)) end
    end
    -- 4) generals / family members outside Anatolia to the rebels with their armies (admirals stay)
    local movers = {}
    for i = 0, (get(f, "numOfCharacters") or 0) - 1 do
        local ok, ch = pcall(function() return f:getCharacter(i) end)
        if ok and ch then
            local typ = get(ch, "characterType")
            local isGeneral = typ == characterType.named_character or typ == characterType.general
            local reg = tileRegionName(get(ch, "xCoord") or -1, get(ch, "yCoord") or -1)
            if isGeneral and get(ch, "characterRecord") ~= rec and reg and not ANATOLIA[reg] then
                local okT, tile = pcall(function() return M2TW.stratMap.getTile(ch.xCoord, ch.yCoord) end)
                if okT and get(tile, "isLand") == 1 then movers[#movers + 1] = ch end
            end
        end
    end
    local nC = 0
    for _, ch in ipairs(movers) do
        local who = tostring(get(get(ch, "characterRecord"), "shortName"))
        local ok, err = pcall(function() ch:switchFaction(rebels, true, true) end)
        if ok then nC = nC + 1 else log("ERROR switchFaction " .. who .. ": " .. tostring(err)) end
    end
    setCounter(C_ERET, 1)
    applyName(f, NAME_ERETNID)
    log("ERETNIDS at turn " .. turnNow() .. " (" .. why .. "): " .. nS .. "/" .. #outside .. " settlements and "
        .. nC .. "/" .. #movers .. " generals to the rebels, Zengid settlements left " .. tostring(get(f, "settlementsNum")))
    event("HX_ERETNIDS_DONE", ERE_T, ERE_B)
    return true
end

local function eretnidStep(f)
    local st = counter(C_ERET)
    if st ~= 0 then return end
    if isPlayer(f) then
        if sivasBlocked(sivas()) then log("Eretnid question waits: " .. tostring(sivasBlocked(sivas()))); return end
        setCounter(C_ERET, 8)
        ask(Q_ERETNID, ERE_T, ERE_Q, "zengid")
    else
        becomeEretnids(f, "AI")
    end
end

---------------------------------------------------------------------------------------------------------------------
-- hooks
---------------------------------------------------------------------------------------------------------------------
local function onTurnStart(eventData)
    local f = get(eventData, "faction")
    local name = get(f, "name")
    local turn = turnNow()
    runSteps(turn)
    if name == "egypt" then
        if turn >= T.ayyubid then egyptStep(f, 1) end
        if turn >= T.mamluk then egyptStep(f, 2) end
        applyName(f, egyptName())
    elseif name == "zengid" and alive(f) then
        if turn >= T.eretnid then eretnidStep(f) end
        if counter(C_ERET) == 1 then applyName(f, NAME_ERETNID) end
    end
end

local function onCounter(eventData)
    local name = get(eventData, "eventCounter")
    if name == nil or counter(name) == 0 then return end
    if name == Q_AYYUBID .. "_accepted" then setCounter(name, 0); renameEgypt(1, "player said yes")
    elseif name == Q_MAMLUK .. "_accepted" then setCounter(name, 0); renameEgypt(2, "player said yes")
    elseif name == Q_AYYUBID .. "_declined" or name == Q_MAMLUK .. "_declined" then
        setCounter(name, 0); log("player Egypt declined " .. name .. " - name kept")
    elseif name == Q_ERETNID .. "_accepted" then
        setCounter(name, 0)
        if not becomeEretnids(faction("zengid"), "player said yes") then
            setCounter(C_ERET, 0)   -- Sivas got blocked in between: ask again next turn
        end
    elseif name == Q_ERETNID .. "_declined" then
        setCounter(name, 0); setCounter(C_ERET, 9); log("player Zengids declined the Eretnids - nothing happens")
    end
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

if not DY.installed then
    DY.installed = true
    afterHook("onFactionTurnStart", onTurnStart)
    afterHook("onEventCounter", onCounter)
    afterHook("onCampaignMapLoaded", applyNames)
    log("loaded (TEST = " .. tostring(TEST) .. ", ERETNID_TEST = " .. tostring(ERETNID_TEST) .. ", Ayyubids " .. T.ayyubid .. ", Mamluks " .. T.mamluk
        .. ", Eretnids " .. T.eretnid .. ")")
end

Dynasties = DY
return DY
