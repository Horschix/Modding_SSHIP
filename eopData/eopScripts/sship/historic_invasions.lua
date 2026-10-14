--[[
    Historic invasion armies for SSHIP's historic events (Horschix/Modding_SSHIP, 15 Oct 2026)

    FIRST EVENT: the Fourth Crusade (SSHIP's crusade event of turn 140 = 1202). Decided by the user (15 Oct 2026):
      - two stages, one combined stack each (Venetians + crusaders):
          stage 1, turn 140: Enrico Dandolo's army appears at Zara and besieges it
          stage 2, turn 145: Bonifacio del Monferrato's army appears at Constantinople and besieges it
      - player is Venice: SSHIP's yes/no question is asked with a new text. YES = excommunicated at once, then the
        Zara army (turn 140) and the Constantinople army (turn 145) appear under the player's control; the player
        attacks himself. NO = nothing happens. (SSHIP's instant takeover of Constantinople is replaced.)
      - AI Venice: excommunicated when the Zara attack begins. Each army sits one turn in the siege (builds siege
        equipment), then it is forced to assault at Venice's next turn start (repeated for up to 6 turns while
        the town is not taken and the general lives).
      - war is declared on the owner of the target (rebels are always at war).
      - conditions: Venice exists; Zara is skipped if Venice already holds it; Constantinople only if an orthodox
        faction other than Venice holds it.
      - the two armies keep their crusader units when SSHIP's crusade cleanup runs (general label hx4c_...).

    HOW IT HOOKS IN (no SSHIP file is changed):
      - replaces crusades.historicCalltoHolyWar with a wrapper (SSHIP's own function still runs, except the
        turn-140 branch for a PLAYER Venice, which is rebuilt here with the new question text)
      - replaces crusades.veniceSacksConstantinople (called by main.lua when the player answers YES)
      - replaces crusades.disbandCrusadeUnits with a copy that skips our labelled generals
      - runs after onEventCounter (NO answer) and onFactionTurnStart (forced assault)
    Loaded by a line at the end of eopData/eopScripts/luaPluginScript.lua, after require('sship.main'):
        require('sship.historic_invasions')
    Delete the line to switch it off. Nothing here calls M2TWEOP or M2TW while the file is loading.
    Game-log lines start with HXINV (in mods\sship\full.log). State lives in script counters (saved with the game).
]]
local HI = {}

---------------------------------------------------------------------------------------------------------------------
-- settings
---------------------------------------------------------------------------------------------------------------------
-- TEST = true: stage 1 at turn 2, stage 2 at turn 5, no crusade call and no war with Hungary at the test turn.
-- Final version: TEST = false (turns 140 and 145).
local TEST = true
local ZARA_TURN = TEST and 2 or 140
local CONST_TURN = TEST and 5 or 145
local ASSAULT_WINDOW = 6 -- forced assault tried at Venice's turn start from spawn turn + 1 up to spawn turn + 6

-- script counters (stored value = turn + 1, so 0 always means "not yet")
local C_STATE = "HXINV_4C_STATE"           -- 0 not started, 1 running (stage 1 done or skipped), 2 stage 2 done, 9 cancelled
local C_ZARA = "HXINV_4C_ZARA_SPAWN"
local C_CONST = "HXINV_4C_CONST_SPAWN"

local LABEL_ZARA = "hx4c_zara"
local LABEL_CONST = "hx4c_const"
local LABEL_PREFIX = "hx4c_"

-- unit list: { unit type, experience }. 19 units + the general = a full stack.
local STACKS = {
    zara = {
        settlement = "Zara", label = LABEL_ZARA, counter = C_ZARA,
        name = "Enrico", name2 = "Enrico Dandolo", age = 65, bodyguard = "SE Bodyguard", bodyguardExp = 4,
        traits = { { "Intelligent", 3 }, { "GoodCommander", 1 }, { "NaturalMilitarySkill", 2 }, { "Military_Edu", 2 } },
        units = {
            { "Venetian Heavy Infantry", 3 }, { "Venetian Heavy Infantry", 1 }, { "Venetian Heavy Infantry", 0 },
            { "Pavise Crossbow Militia", 2 }, { "Pavise Crossbow Militia", 0 },
            { "Venetian Archers", 1 }, { "Venetian Archers", 0 },
            { "Italian MAA", 2 }, { "Italian MAA", 0 },
            { "Pavise Spear Militia", 1 }, { "Pavise Spear Militia", 0 },
            { "Crusader Knights", 3 }, { "Crusader Knights", 1 },
            { "Dismounted Crusader Knights", 2 }, { "Dismounted Crusader Knights", 0 },
            { "Crusader Sergeants", 2 }, { "Crusader Sergeants", 0 },
            { "NE Trebuchet", 1 }, { "NE Trebuchet", 0 },
        },
    },
    const = {
        settlement = "Constantinople", label = LABEL_CONST, counter = C_CONST,
        name = "Bonifacio", name2 = "Bonifacio del Monferrato", age = 52, bodyguard = "SE Bodyguard", bodyguardExp = 4,
        traits = { { "MilitaryInclination", 2 }, { "GoodCommander", 2 }, { "NaturalMilitarySkill", 2 }, { "VictorVirtue", 1 } },
        units = {
            { "Crusader Knights", 5 }, { "Crusader Knights", 2 }, { "Crusader Knights", 0 },
            { "Dismounted Crusader Knights", 3 }, { "Dismounted Crusader Knights", 1 },
            { "Crusader Sergeants", 3 }, { "Crusader Sergeants", 0 },
            { "Feudal Knights", 2 }, { "Feudal Knights", 0 },
            { "Dismounted Feudal Knights", 1 },
            { "Venetian Heavy Infantry", 4 }, { "Venetian Heavy Infantry", 2 }, { "Venetian Heavy Infantry", 0 },
            { "Pavise Crossbow Militia", 3 }, { "Pavise Crossbow Militia", 1 },
            { "Venetian Archers", 2 }, { "Venetian Archers", 0 },
            { "NE Trebuchet", 1 }, { "NE Trebuchet", 0 },
        },
    },
}

---------------------------------------------------------------------------------------------------------------------
-- texts
---------------------------------------------------------------------------------------------------------------------
local CHOICE_TITLE = "Fourth Crusade 1202"
local CHOICE_BODY = "\n HISTORICAL BACKGROUND:\n   Pope Innocent III called a new crusade to win back Jerusalem. The crusaders hired Venice's fleet but could not pay the enormous price. Doge Enrico Dandolo, blind and over ninety years old, offered a bargain: the debt would wait if the crusaders first took Zara on the Dalmatian coast, a Christian city that had gone over to the King of Hungary. Zara fell in November 1202 and the Pope excommunicated the Venetians for it. A Byzantine pretender, Alexios Angelos, then promised money, troops and the union of the Churches if the crusade put his father back on the throne. In June 1203 the fleet anchored before Constantinople; in April 1204 the city was stormed and plundered, and a Latin Empire was founded on its ruins.\n\n GAME STRATEGY: Do you take the crusaders into Venice's service? If you accept, Venice is excommunicated at once. A Venetian and crusader army led by Enrico Dandolo appears before Zara now, and a second army under Bonifacio del Monferrato lands before Constantinople a few turns later - the rest is up to you. If you decline, nothing happens."

local function zaraNewsBody(ownerName)
    return "\n   Doge Enrico Dandolo and the crusaders in Venice's pay have landed before Zara, held by "
        .. ownerName .. ". The Pope has excommunicated Venice for turning a crusade against a Christian city."
end
local function constNewsBody(ownerName)
    return "\n   The Venetian fleet carrying the crusade of Bonifacio del Monferrato has anchored before Constantinople, held by "
        .. ownerName .. ". The crusaders have come to put a Byzantine pretender on the throne - and to take their pay from the richest city of Christendom."
end
local ATTACKED_TITLE = "The Fourth Crusade attacks!"

---------------------------------------------------------------------------------------------------------------------
-- helpers (a wrong field name must never crash the game)
---------------------------------------------------------------------------------------------------------------------
local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("HXINV " .. tostring(text))
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

local function faction(name)
    local ok, f = pcall(function() return M2TW.campaign:getFaction(name) end)
    if ok then return f end
    return nil
end

local function alive(f)
    return f ~= nil and (get(f, "settlementsNum") or 0) > 0
end

local function settlement(name)
    local ok, s = pcall(function() return M2TW.stratMap:getSettlement(name) end)
    if ok then return s end
    return nil
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

local function isPlayer(f)
    return f ~= nil and get(f, "isPlayerControlled") == 1
end

local function event(name, title, body, x, y, factions)
    if factions == nil or #factions == 0 then return end
    local ok, err = pcall(function()
        M2TW.campaign.historicEvent(name, title, body, false, x or -1, y or -1, factions)
    end)
    if not ok then log("ERROR historicEvent " .. name .. ": " .. tostring(err)) end
end

local function declareWar(f1, f2)
    if f1 == nil or f2 == nil or f1 == f2 or f2.name == "slave" then return end
    local ok, err = pcall(function()
        if M2TW.campaign:checkDipStance(dipRelType.war, f1, f2) == false then
            M2TW.campaign:setDipStance(dipRelType.war, f1, f2)
            log("war declared: " .. f1.name .. " - " .. f2.name)
        end
    end)
    if not ok then log("ERROR war " .. tostring(f1.name) .. " - " .. tostring(f2.name) .. ": " .. tostring(err)) end
end

-- the same penalties SSHIP gives in veniceSacksConstantinople
local function excommunicate(venice)
    local ok, err = pcall(function()
        venice.isExcommunicated = true
        local rep = venice:getFactionStanding(venice)
        venice:setFactionStanding(venice, rep - 0.5)
        local papal = faction("papal_states")
        if papal then
            local rel = papal:getFactionStanding(venice)
            papal:setFactionStanding(venice, rel - 0.5)
        end
    end)
    log("Venice excommunicated" .. (ok and "" or (" - ERROR " .. tostring(err))))
end

-- a free land tile next to the settlement, in the settlement's own region (keeps Constantinople's army on the
-- European shore); falls back to the game's own search
local function spawnTile(sett)
    local sx, sy, region = sett.xCoord, sett.yCoord, get(sett, "regionID")
    for r = 1, 3 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local x, y = sx + dx, sy + dy
                    local okT, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
                    local okF, free = pcall(function() return M2TWEOP.isTileFree(x, y) end)
                    if okT and tile and get(tile, "isLand") == 1 and get(tile, "regionID") == region
                        and okF and free then
                        return x, y
                    end
                end
            end
        end
    end
    local ok, x, y = pcall(function()
        return M2TW.stratMap.findValidTileNearTile(sx, sy, characterType.named_character)
    end)
    if ok then return x, y end
    return sx + 1, sy
end

local function eduIndex(unitType)
    local ok, idx = pcall(function() return M2TWEOPDU.getEduIndexByType(unitType) end)
    if ok then return idx end
    return nil
end

local function spawnStack(venice, key)
    local spec = STACKS[key]
    local sett = settlement(spec.settlement)
    if sett == nil then log("ERROR settlement not found: " .. spec.settlement); return nil end
    local x, y = spawnTile(sett)
    local bg = eduIndex(spec.bodyguard)
    if bg == nil then log("ERROR unit type not found: " .. spec.bodyguard); return nil end
    local ok, army = pcall(function()
        return venice:spawnArmy(spec.name, spec.name2, characterType.named_character, spec.label, "",
            x, y, spec.age, false, 31, bg, spec.bodyguardExp, 0, 0)
    end)
    if not ok or army == nil then log("ERROR spawnArmy " .. key .. ": " .. tostring(army)); return nil end
    local made = 0
    for i = 1, #spec.units do
        local u = spec.units[i]
        local okU, err = pcall(function() army:createUnit(u[1], u[2], 0, 0) end)
        if okU then made = made + 1 else log("ERROR createUnit " .. u[1] .. ": " .. tostring(err)) end
    end
    local leader = get(army, "leader")
    local record = get(leader, "characterRecord")
    if record then
        for i = 1, #spec.traits do
            pcall(function() record:addTrait(spec.traits[i][1], spec.traits[i][2]) end)
        end
    end
    log("spawned " .. key .. " army at " .. x .. "," .. y .. " (" .. made .. " units + general) next to "
        .. spec.settlement .. " (" .. sett.xCoord .. "," .. sett.yCoord .. ")")
    setCounter(spec.counter, turnNow() + 1)
    return army, sett, leader
end

-- the AI begins the siege at once and may not move away this turn; the assault is forced later
local function startAISiege(army, sett, leader)
    local ok, err = pcall(function() army:siegeSettlement(sett, false) end)
    log("siege of " .. sett.name .. (ok and " started" or (" FAILED: " .. tostring(err))))
    pcall(function() leader.movePoints = 0 end)
end

local function announce(key, sett, owner, venice)
    local ownerName = get(owner, "name") == "slave" and "rebels" or (get(get(owner, "factionRecord"), "localizedName") or get(owner, "name") or "?")
    local body = key == "zara" and zaraNewsBody(ownerName) or constNewsBody(ownerName)
    local title = key == "zara" and "The crusade turns on Zara" or "The crusade before Constantinople"
    local attacked, others = {}, {}
    for _, name in ipairs(playerFactionNames()) do
        if owner and name == owner.name then attacked[#attacked + 1] = name
        elseif name ~= venice.name then others[#others + 1] = name end
    end
    event("SCRIPTED_INVASION_INFO", ATTACKED_TITLE, body, sett.xCoord, sett.yCoord, attacked)
    event("CRUSADE", title, body, sett.xCoord, sett.yCoord, others)
end

---------------------------------------------------------------------------------------------------------------------
-- the two stages
---------------------------------------------------------------------------------------------------------------------
local function stageZara()
    local venice = faction("venice")
    if not alive(venice) then setCounter(C_STATE, 9); log("4th crusade cancelled: Venice does not exist"); return end
    setCounter(C_STATE, 1)
    if not isPlayer(venice) then excommunicate(venice) end -- the player was excommunicated when he accepted
    local sett = settlement("Zara")
    local owner = get(sett, "ownerFaction")
    if sett == nil or owner == nil or owner.name == "venice" then
        log("stage Zara skipped: Venice already holds Zara (or Zara not found)")
        return
    end
    declareWar(venice, owner)
    local army, s, leader = spawnStack(venice, "zara")
    if army == nil then return end
    if not isPlayer(venice) then startAISiege(army, s, leader) end
    announce("zara", s, owner, venice)
end

local function stageConstantinople()
    setCounter(C_STATE, 2)
    local venice = faction("venice")
    if not alive(venice) then log("stage Constantinople skipped: Venice does not exist"); return end
    local sett = settlement("Constantinople")
    local owner = get(sett, "ownerFaction")
    if sett == nil or owner == nil or owner.name == "venice" or get(owner, "religion") ~= 1 then
        log("stage Constantinople skipped: owner " .. tostring(get(owner, "name")) .. " is Venice or not orthodox")
        return
    end
    declareWar(venice, owner)
    local army, s, leader = spawnStack(venice, "const")
    if army == nil then return end
    if not isPlayer(venice) then startAISiege(army, s, leader) end
    announce("const", s, owner, venice)
end

---------------------------------------------------------------------------------------------------------------------
-- hooks
---------------------------------------------------------------------------------------------------------------------
-- player Venice at the Zara turn: SSHIP's turn-140 branch rebuilt with the new question
local function askPlayerVenice(crusades)
    local turn = turnNow()
    if not TEST then
        local jerusalem = settlement("Jerusalem")
        local owner = get(jerusalem, "ownerFaction")
        local crusadeOn = get(get(M2TW.campaign, "crusade"), "targetSettlement") ~= nil
        if not crusadeOn and owner and get(owner, "religion") ~= 0 then
            pcall(function() crusades.calltoHolyWar("Jerusalem", "crusade") end)
            log("crusade on Jerusalem called (SSHIP's turn-" .. turn .. " rule)")
        end
        declareWar(faction("venice"), faction("hungary"))
    end
    local ok, err = pcall(function()
        M2TW.campaign.historicEvent("CONSTANTINOPLE_SACK_CRUSADE", CHOICE_TITLE, CHOICE_BODY, true, -1, -1, { "venice" })
    end)
    log("question to player Venice" .. (ok and " shown" or (" FAILED: " .. tostring(err))))
end

-- runs at the player's turn end (main.lua calls crusades.historicCalltoHolyWar there)
local function afterHolyWarCheck(crusades, original)
    local turn = turnNow()
    local venice = faction("venice")
    local state = counter(C_STATE)
    if turn == ZARA_TURN and state == 0 and isPlayer(venice) then
        if TEST or turn ~= 140 then original() end
        askPlayerVenice(crusades)
        return
    end
    original()
    if state == 0 and turn >= ZARA_TURN and turn < CONST_TURN and venice and not isPlayer(venice) then
        stageZara()
    elseif state == 1 and turn >= CONST_TURN then
        stageConstantinople()
    end
end

-- player answered YES (main.lua calls crusades.veniceSacksConstantinople)
local function playerAccepted()
    if counter(C_STATE) ~= 0 then log("YES ignored, state " .. counter(C_STATE)); return end
    local venice = faction("venice")
    excommunicate(venice)
    stageZara()
end

local function onCounter(eventData)
    local name = get(eventData, "eventCounter")
    if name == "CONSTANTINOPLE_SACK_CRUSADE_declined" and counter(C_STATE) == 0 and turnNow() >= ZARA_TURN then
        setCounter(C_STATE, 9)
        log("player Venice declined - no crusade armies")
    end
end

-- fallback when the labelled general is gone (test 15 Oct 2026: Dandolo, then 90, died at the turn change and the
-- leaderless army gave up the siege): the biggest Venetian army within 3 tiles of the target
local function veniceArmyNear(venice, sett)
    local best, bestUnits = nil, 0
    for i = 0, (get(venice, "numOfCharacters") or 0) - 1 do
        local okC, char = pcall(function() return venice:getCharacter(i) end)
        local army = okC and get(char, "army") or nil
        if army and get(army, "leader") == char then
            local dx = math.abs((get(char, "xCoord") or -99) - sett.xCoord)
            local dy = math.abs((get(char, "yCoord") or -99) - sett.yCoord)
            local units = get(army, "numOfUnits") or 0
            if math.max(dx, dy) <= 3 and units > bestUnits then best, bestUnits = army, units end
        end
    end
    return best
end

-- AI Venice: force the assault from the turn after the spawn
local function forceAssaults(eventData)
    local f = get(eventData, "faction")
    if get(f, "name") ~= "venice" or isPlayer(f) then return end
    local turn = turnNow()
    for _, key in ipairs({ "zara", "const" }) do
        local spec = STACKS[key]
        local spawned = counter(spec.counter) - 1
        if spawned >= 0 and turn >= spawned + 1 and turn <= spawned + ASSAULT_WINDOW then
            local sett = settlement(spec.settlement)
            local okR, record = pcall(function() return M2TW.campaign:getCharacterByLabel(spec.label) end)
            local char = okR and get(record, "character") or nil
            local army = get(char, "army")
            if army == nil and sett then
                army = veniceArmyNear(f, sett)
                if army then log("turn " .. turn .. ": " .. spec.label .. " general gone, using the Venetian army next to " .. spec.settlement) end
            end
            local owner = get(get(sett, "ownerFaction"), "name")
            if sett and army and owner ~= "venice" then
                local ok, err = pcall(function() army:siegeSettlement(sett, true) end)
                log("turn " .. turn .. ": forced assault on " .. spec.settlement
                    .. (ok and " ordered" or (" FAILED: " .. tostring(err))))
            elseif sett and owner == "venice" then
                setCounter(spec.counter, 0)
                log(spec.settlement .. " is Venetian - forced assaults finished")
            else
                log("turn " .. turn .. ": no assault on " .. spec.settlement .. " (army " .. tostring(army ~= nil) .. ")")
            end
        end
    end
end

-- copy of SSHIP's crusades.disbandCrusadeUnits (crusades.lua, Macaras) that skips our labelled generals
local CRUSADE_UNITS = { ["Religious Fanatics"] = true, ["Flagellants"] = true, ["Dismounted Crusader Knights"] = true,
    ["Crusader Sergeants"] = true, ["Crusader Knights"] = true, ["Great Cross"] = true }
local function disbandCrusadeUnits(eventData)
    log("crusade cleanup (SSHIP rule, our armies exempt)")
    for f = 0, M2TW.campaign.numberOfFactions - 1 do
        local fac = M2TW.campaign:getFactionByID(f)
        if fac.name ~= "jerusalem" and fac ~= eventData.faction and fac.religion ~= 2 then
            for i = 0, fac.numOfCharacters - 1 do
                local char = fac:getCharacter(i)
                local label = get(char.characterRecord, "label") or ""
                if char.army ~= nil and char:getTypeName() == "named_character" and fac.religion == 0 then
                    if string.sub(label, 1, #LABEL_PREFIX) == LABEL_PREFIX then
                        log("kept crusader units of " .. label)
                    else
                        local hitlist = {}
                        for u = 0, char.army.numOfUnits - 1 do
                            local unit = char.army:getUnit(u)
                            if CRUSADE_UNITS[unit.eduEntry.eduType] then hitlist[#hitlist + 1] = unit end
                        end
                        for k = 1, #hitlist do hitlist[k]:kill() end
                    end
                end
            end
        end
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

if not HI.installed then
    HI.installed = true
    local crusades = require('sship.crusades')
    local originalHolyWar = crusades.historicCalltoHolyWar
    crusades.historicCalltoHolyWar = function()
        local ok, err = pcall(afterHolyWarCheck, crusades, originalHolyWar)
        if not ok then log("ERROR in historicCalltoHolyWar wrapper: " .. tostring(err)) end
    end
    crusades.veniceSacksConstantinople = function()
        local ok, err = pcall(playerAccepted)
        if not ok then log("ERROR in playerAccepted: " .. tostring(err)) end
    end
    crusades.disbandCrusadeUnits = function(eventData)
        local ok, err = pcall(disbandCrusadeUnits, eventData)
        if not ok then log("ERROR in disbandCrusadeUnits: " .. tostring(err)) end
    end
    afterHook("onEventCounter", onCounter)
    afterHook("onFactionTurnStart", forceAssaults)
end

HistoricInvasions = HI
return HI
