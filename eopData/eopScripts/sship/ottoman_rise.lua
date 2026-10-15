---------------------------------------------------------------------------------------------------------------------
-- ottoman_rise.lua  (Modding_SSHIP, 15 Oct 2026) - Ertugrul Gazi and Osman Gazi for Rum. Decided by the user on
-- 15 Oct 2026, for player and AI Rum alike:
--   * ERT_TURN 198 (1231, the Kayi settle at Sogut): Ertugrul Gazi (family member, age 40, wife Halime) appears next
--     to Konya (else next to Rum's capital) with the standard Rum bodyguard (ME Bodyguard, ME Late Bodyguard once
--     late_era is set) and 2 Oghuz Horse Archers (type "Turkish Horse Archers"). He carries the new trait
--     House_of_Osman.
--   * BIRTH_TURN 252 (1258): Osman is born as Ertugrul's son in the family tree (characterRecord:birthChild) and
--     grows up naturally; at 16 he comes of age and inherits House_of_Osman (trait trigger
--     House_of_Osman_CharacterComesOfAge_Father, the script adds it too if it is missing).
--     If Ertugrul is dead by then, Osman instead appears as an adult (16) at ADULT_TURN 284 next to Konya/capital.
--   * LEADER_TURN 296 (1280, Ertugrul's death): Osman becomes faction leader (factionStruct:setLeader); if he is
--     dead, the oldest living man of the House of Osman. The faction is renamed "Ottoman Domain" (localizedName, set
--     again at every Rum turn start and map load). Succession after that is left to the game (user).
--   * The Seljuk family members stay alive with their trait (user).
--   * Rum dead (no settlement) at a step -> that step and the rest are skipped.
-- New trait House_of_Osman (+1 Command, +1 cavalry command, +1 Authority) in export_descr_character_traits.txt,
-- texts in text/export_vnvs.txt.
-- TEST = true: Ertugrul turn 2, Osman born turn 3 at age 14 (comes of age a few turns later), leader turn 8.
-- Log prefix OTTOMAN.
---------------------------------------------------------------------------------------------------------------------
local TEST = true
local ERT_TURN    = TEST and 2 or 198
local BIRTH_TURN  = TEST and 3 or 252
local BIRTH_AGE   = TEST and 14 or 0
local ADULT_TURN  = TEST and 6 or 284
local LEADER_TURN = TEST and 8 or 296

local TRAIT = "House_of_Osman"
local NAME = "Ottoman Domain"
local C_ERT    = "hx_ott_ertugrul"   -- 1 spawned, 9 skipped
local C_OSMAN  = "hx_ott_osman"      -- 1 born as a child, 2 adult spawned, 3 waiting for the adult spawn, 9 skipped
local C_LEADER = "hx_ott_leader"     -- 1 done, 9 skipped
local C_DOMAIN = "ottoman_domain"    -- 1 = Rum is the Ottoman Domain

local OR = OttomanRise or {}

---------------------------------------------------------------------------------------------------------------------
-- helpers (a wrong field name must never crash the game)
---------------------------------------------------------------------------------------------------------------------
local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("OTTOMAN " .. tostring(text))
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

local function rum()
    local ok, f = pcall(function() return M2TW.campaign:getFaction("rum") end)
    if ok then return f end
    return nil
end

local function alive(f) return f ~= nil and (get(f, "settlementsNum") or 0) > 0 end

local function traitLevel(rec, trait)
    local ok, v = pcall(function() return rec:getTraitLevel(trait) end)
    if ok and type(v) == "number" then return v end
    return 0
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

local function event(name, title, body, x, y)
    local factions = playerFactionNames()
    if #factions == 0 then return end
    local ok, err = pcall(function() M2TW.campaign.historicEvent(name, title, body, false, x or -1, y or -1, factions) end)
    if not ok then log("ERROR historicEvent " .. name .. ": " .. tostring(err)) end
end

-- Konya if Rum holds it, else Rum's capital, else any Rum settlement
local function homeSettlement(f)
    local ok, konya = pcall(function() return M2TW.stratMap:getSettlement("Konya") end)
    if ok and konya and get(get(konya, "ownerFaction"), "factionID") == get(f, "factionID") then return konya end
    local cap = get(f, "capital")
    if cap then return cap end
    local okS, s = pcall(function() return f:getSettlement(0) end)
    if okS then return s end
    return nil
end

-- a free land tile next to the settlement (same region), else the game's own search
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
    local ok, x, y = pcall(function() return M2TW.stratMap.findValidTileNearTile(sx, sy, characterType.named_character) end)
    if ok and x then return x, y end
    return sx + 1, sy
end

local function eduIndex(unitType)
    local ok, idx = pcall(function() return M2TWEOPDU.getEduIndexByType(unitType) end)
    if ok then return idx end
    return nil
end

-- every character record of Rum (also children, wives, the dead)
local function records(f)
    local list = {}
    local n = get(f, "characterRecordNum") or 0
    for i = 0, n - 1 do
        local ok, rec = pcall(function() return f:getCharacterRecord(i) end)
        if ok and rec then list[#list + 1] = rec end
    end
    return list
end

local function isLivingMan(rec)
    return get(rec, "isAlive") == true and get(rec, "isMale") == true and get(rec, "isFamily") == true
end

local function findErtugrul(f)
    for _, rec in ipairs(records(f)) do
        if get(rec, "shortName") == "Ertugrul" and traitLevel(rec, TRAIT) > 0 and isLivingMan(rec) then return rec end
    end
    return nil
end

local function isOsman(rec)
    if get(rec, "shortName") ~= "Osman" then return false end
    return traitLevel(rec, TRAIT) > 0 or get(get(rec, "parent"), "shortName") == "Ertugrul"
end

local function findOsman(f)
    for _, rec in ipairs(records(f)) do
        if isOsman(rec) and isLivingMan(rec) and get(rec, "isChild") ~= true then return rec end
    end
    return nil
end

-- the oldest living adult man of the House of Osman
local function oldestOfHouse(f)
    local best = nil
    for _, rec in ipairs(records(f)) do
        if isLivingMan(rec) and get(rec, "isChild") ~= true and traitLevel(rec, TRAIT) > 0 then
            if best == nil or (get(rec, "age") or 0) > (get(best, "age") or 0) then best = rec end
        end
    end
    return best
end

-- spawns a Rum family general with his army; returns the army or nil
local function spawnGeneral(f, name, name2, label, age, extraUnits, traits)
    local sett = homeSettlement(f)
    if sett == nil then log("ERROR no Rum settlement to spawn " .. name); return nil end
    local x, y = spawnTile(sett)
    local bgType = counter("late_era") == 1 and "ME Late Bodyguard" or "ME Bodyguard"
    local bg = eduIndex(bgType)
    if bg == nil then log("ERROR unit type not found: " .. bgType); return nil end
    local ok, army = pcall(function()
        return f:spawnArmy(name, name2, characterType.named_character, label, "", x, y, age, true, 31, bg, 2, 0, 0)
    end)
    if not ok or army == nil then log("ERROR spawnArmy " .. name .. ": " .. tostring(army)); return nil end
    local made = 0
    for _, u in ipairs(extraUnits) do
        local okU, err = pcall(function() army:createUnit(u[1], u[2], 0, 0) end)
        if okU then made = made + 1 else log("ERROR createUnit " .. u[1] .. ": " .. tostring(err)) end
    end
    local rec = get(get(army, "leader"), "characterRecord")
    for _, t in ipairs(traits) do
        local okT, err = pcall(function() rec:addTrait(t[1], t[2]) end)
        if not okT then log("ERROR addTrait " .. t[1] .. ": " .. tostring(err)) end
    end
    log("spawned " .. name .. " (" .. bgType .. " + " .. made .. " units) at " .. x .. "," .. y .. " next to "
        .. tostring(get(sett, "name")) .. ", family = " .. tostring(get(rec, "isFamily")) .. ", "
        .. TRAIT .. " = " .. traitLevel(rec, TRAIT))
    return army, rec, x, y
end

---------------------------------------------------------------------------------------------------------------------
-- the steps
---------------------------------------------------------------------------------------------------------------------
local function applyName(f)
    if counter(C_DOMAIN) ~= 1 or f == nil or get(f, "localizedName") == NAME then return end
    local ok, err = pcall(function() f.localizedName = NAME end)
    log("name -> " .. NAME .. ": " .. (ok and ("reads back " .. tostring(get(f, "localizedName"))) or ("ERROR " .. tostring(err))))
end

local function stepErtugrul(f)
    local army, rec, x, y = spawnGeneral(f, "Ertugrul", "Ertugrul Gazi", "hx_ertugrul", 40,
        { { "Turkish Horse Archers", 1 }, { "Turkish Horse Archers", 1 } },
        { { TRAIT, 1 }, { "GoodCommander", 1 }, { "GoodCavalryGeneral", 1 }, { "MilitaryInclination", 1 },
          { "LoyaltyStarter", 1 }, { "ReligionStarter", 1 } })
    if army == nil then setCounter(C_ERT, 9); return end
    local okW, err = pcall(function() rec:marryWife("Halime", 30) end)
    log("wife Halime: " .. (okW and "ok" or ("ERROR " .. tostring(err))))
    setCounter(C_ERT, 1)
    event("OTTOMAN_ERTUGRUL", "Ertugrul Gazi",
        "\nA band of Oghuz Turks of the Kayi clan, fleeing the Mongols in the east, has come to the Sultan's court at "
        .. "Konya. Their chief, Ertugrul Gazi, offers his sword in return for land on the Byzantine frontier around "
        .. "Sogut.\n\nGAME: Ertugrul Gazi joins the Rum family with his Kayi horsemen. His line carries the trait "
        .. "'Of the House of Osman'.", x, y)
end

local function stepBirth(f)
    local ert = findErtugrul(f)
    if ert == nil then
        log("Ertugrul is dead or not found at turn " .. turnNow() .. " - Osman will appear as an adult at turn " .. ADULT_TURN)
        setCounter(C_OSMAN, 3)
        return
    end
    local ok, err = pcall(function() ert:birthChild("Osman", "", BIRTH_AGE, true, true) end)
    if not ok then
        log("ERROR birthChild: " .. tostring(err) .. " - Osman will appear as an adult at turn " .. ADULT_TURN)
        setCounter(C_OSMAN, 3)
        return
    end
    local n = get(ert, "numberOfChildren")
    log("Osman born to Ertugrul (age " .. BIRTH_AGE .. "), Ertugrul now has " .. tostring(n) .. " children")
    setCounter(C_OSMAN, 1)
    event("OTTOMAN_OSMAN_BORN", "A son for Ertugrul",
        "\nIn the tents of the Kayi at Sogut, Ertugrul Gazi's wife has borne him a son. They name him Osman.\n\n"
        .. "GAME: Osman will come of age at 16 and inherit 'Of the House of Osman'.")
end

local function stepAdult(f)
    local army, rec, x, y = spawnGeneral(f, "Osman", "Osman Gazi", "hx_osman", 16, {},
        { { TRAIT, 1 }, { "MilitaryInclination", 1 }, { "LoyaltyStarter", 1 }, { "ReligionStarter", 1 } })
    setCounter(C_OSMAN, army and 2 or 9)
end

local function stepLeader(f)
    local rec = findOsman(f)
    local who = "Osman"
    if rec == nil then rec = oldestOfHouse(f); who = "oldest of the House" end
    if rec == nil then
        log("no living adult man of the House of Osman at turn " .. turnNow() .. " - no new leader, no new name")
        setCounter(C_LEADER, 9)
        return
    end
    local ok, err = pcall(function() f:setLeader(rec, true) end)
    log("setLeader " .. tostring(get(rec, "shortName")) .. " (" .. who .. "): "
        .. (ok and ("ok, isLeader = " .. tostring(rec:isLeader())) or ("ERROR " .. tostring(err))))
    if not ok then setCounter(C_LEADER, 9); return end
    setCounter(C_LEADER, 1)
    setCounter(C_DOMAIN, 1)
    applyName(f)
    event("OTTOMAN_DOMAIN", "The Domain of Osman",
        "\nErtugrul Gazi is gone. His son Osman, bey of Sogut, now leads the Turks of Rum. The frontier warriors flock "
        .. "to his banner, and the realm becomes the Domain of Osman - the Ottoman state.\n\n"
        .. "GAME: " .. tostring(get(rec, "shortName")) .. " is the new faction leader; Rum is now the Ottoman Domain.")
end

---------------------------------------------------------------------------------------------------------------------
-- hooks
---------------------------------------------------------------------------------------------------------------------
local function onTurnStart(eventData)
    local f = get(eventData, "faction")
    if get(f, "name") ~= "rum" then return end
    applyName(f)
    local turn = turnNow()
    local function skipAll(why)
        log("Rum is dead at turn " .. turn .. " - " .. why .. " skipped")
    end
    if counter(C_ERT) == 0 and turn >= ERT_TURN then
        if alive(f) then stepErtugrul(f) else setCounter(C_ERT, 9); skipAll("Ertugrul") end
    end
    if counter(C_ERT) == 1 and counter(C_OSMAN) == 0 and turn >= BIRTH_TURN then
        if alive(f) then stepBirth(f) else setCounter(C_OSMAN, 9); skipAll("Osman") end
    end
    if counter(C_OSMAN) == 3 and turn >= ADULT_TURN then
        if alive(f) then stepAdult(f) else setCounter(C_OSMAN, 9); skipAll("Osman (adult)") end
    end
    if counter(C_ERT) == 1 and counter(C_LEADER) == 0 and turn >= LEADER_TURN then
        if alive(f) then stepLeader(f) else setCounter(C_LEADER, 9); skipAll("Osman as leader") end
    end
end

-- Osman (or any son of the House) comes of age: make sure he has the trait
local function onComesOfAge(eventData)
    local char = get(eventData, "character")
    local rec = get(char, "characterRecord") or char
    if get(get(rec, "faction"), "name") ~= "rum" then return end
    local father = get(rec, "parent")
    if traitLevel(rec, TRAIT) == 0 and (traitLevel(father, TRAIT) > 0 or isOsman(rec)) then
        pcall(function() rec:addTrait(TRAIT, 1) end)
    end
    if isOsman(rec) then log("Osman came of age at turn " .. turnNow() .. ", " .. TRAIT .. " = " .. traitLevel(rec, TRAIT)) end
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

if not OR.installed then
    OR.installed = true
    afterHook("onFactionTurnStart", onTurnStart)
    afterHook("onCharacterComesOfAge", onComesOfAge)
    afterHook("onCampaignMapLoaded", function() applyName(rum()) end)
    log("loaded (TEST = " .. tostring(TEST) .. ", Ertugrul " .. ERT_TURN .. ", Osman born " .. BIRTH_TURN
        .. ", leader " .. LEADER_TURN .. ")")
end

OttomanRise = OR
return OR
