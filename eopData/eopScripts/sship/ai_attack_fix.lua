--[[
    AI may attack the player's enemies (Horschix/Modding_SSHIP, 17 Oct 2026; ported from EUR issue #44)

    PROBLEM: an AI faction that is at war with the player and borders him may be left alone by every other
    AI faction, even one at war with it. Engine behaviour of Medieval II, tied to the campaign difficulty
    (seen in DaC/EUR). The engine keeps a switch for it in its difficulty table, which M2TWEOP shows as
        M2TWEOP.getCampaignDifficulty2().dontAttackAiDefenders
    The engine sets it back ON before every faction's AI planning, so this file switches it OFF again
    at map load, at every faction's turn start, at onAiTurn and at onCalculateLTGD.

    LOG (lines start with AIFIX):
      - once after start / load: difficulty level and the switch's value BEFORE any change
      - once per turn: how often the switch had come back on
      - "AIFIX ltgd ...": per AI faction and enemy, the engine's war decision; [P] = enemy is also at war with
        the player, inv = invasion type (0 buildup, 1 immediate, 2 raids, 3 opportunistic, 4 start, 5 none),
        prio = invade priority
      - "AIFIX battle ...": both armies' units before a battle

    FIX = false below: only log, change nothing.
    HOW IT IS LOADED: last require line of eopData/eopScripts/luaPluginScript.lua - delete it to switch off.
    Nothing here calls M2TWEOP or M2TW while the file is loading - only inside the events.
]]
local AF = {}
local FIX = true                    -- false = only write the values to the log

local reported = false              -- values written to the log since this start / load
local changes  = 0                  -- how often the switch had to be set back

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("AIFIX " .. tostring(text))
    end
end

local function field(tbl, name)
    local ok, value = pcall(function() return tbl[name] end)
    if ok then return tostring(value) end
    return "?"
end

local function report(d1, d2)
    local level = "?"
    pcall(function() level = tostring(M2TWEOP.getOptions2().campaignDifficulty) end)
    log("campaign difficulty level (0 easy .. 3 very hard): " .. level)
    if d2 ~= nil then
        log("engine switches: dontAttackAiDefenders=" .. field(d2, "dontAttackAiDefenders")
            .. " forceNavalInvasions=" .. field(d2, "forceNavalInvasions")
            .. " brigandControllerTargetSettlements=" .. field(d2, "brigandControllerTargetSettlements"))
    end
    if d1 ~= nil then
        log("engine values: maxPlayerPeaceTurns=" .. field(d1, "maxPlayerPeaceTurns")
            .. " playerRegionValueModifier=" .. field(d1, "playerRegionValueModifier")
            .. " aiHireMercenaries=" .. field(d1, "aiHireMercenaries"))
    end
end

local counts = { turnstart = 0, aiturn = 0, ltgd = 0 }   -- how often the switch was back on, per point
local quiet  = false                -- after the first look: count instead of one line per change

local function apply(where, key)
    if type(M2TWEOP) ~= "table" or type(M2TWEOP.getCampaignDifficulty2) ~= "function" then
        if not reported then reported = true; log("ERROR this M2TWEOP has no getCampaignDifficulty2 - nothing done") end
        return
    end
    local d2 = M2TWEOP.getCampaignDifficulty2()
    if d2 == nil then return end
    if not reported then
        reported = true
        local d1 = nil
        pcall(function() d1 = M2TWEOP.getCampaignDifficulty1() end)
        log("first look (" .. tostring(where) .. "), before any change:")
        report(d1, d2)
        if not FIX then log("FIX is off - nothing is changed") end
    end
    if not FIX then return end
    if d2.dontAttackAiDefenders ~= false then
        d2.dontAttackAiDefenders = false
        changes = changes + 1
        if key ~= nil then counts[key] = counts[key] + 1 end
        if quiet then return end
        quiet = true
        local turn = "?"
        pcall(function() turn = tostring(M2TW.campaign.turnNumber) end)
        log("dontAttackAiDefenders was on - switched off (" .. tostring(where) .. ", turn " .. turn
            .. ", change no. " .. tostring(changes) .. "); now " .. field(d2, "dontAttackAiDefenders"))
    end
end

local function turnNumber()
    local turn = -1
    pcall(function() turn = M2TW.campaign.turnNumber end)
    return turn
end

local lastTurn = nil
local seen = {}                     -- pairs already written this turn

local function newTurnCheck()
    local turn = turnNumber()
    if lastTurn ~= nil and turn ~= lastTurn then
        log("turn " .. tostring(lastTurn) .. ": switch was back on " .. counts.turnstart .. "x at a turn start, "
            .. counts.aiturn .. "x at onAiTurn, " .. counts.ltgd .. "x at onCalculateLTGD")
        counts.turnstart, counts.aiturn, counts.ltgd = 0, 0, 0
        seen = {}
    end
    lastTurn = turn
end

function AF.onCampaignMapLoaded()
    reported = false                -- a new campaign or a loaded save: look again
    quiet = false
    apply("map loaded", nil)
end

function AF.onFactionTurnStart(eventData)
    local name = "?"
    pcall(function() name = tostring(eventData.faction.name) end)
    newTurnCheck()
    apply("turn start of " .. name, "turnstart")
end

function AF.onAiTurn(aiFaction)
    apply("onAiTurn", "aiturn")
end

-- one log line per AI faction and enemy: what the engine decided about that enemy
local function logDecisions(ltgd)
    local me = ltgd.faction
    if me == nil or me.isPlayerControlled == 1 then return end
    local campaign = M2TW.campaign
    local players = {}
    for i = 0, campaign.numberOfFactions - 1 do
        local f = campaign:getFactionByOrder(i)
        if f ~= nil and f.isPlayerControlled == 1 then players[#players + 1] = f end
    end
    for i = 0, campaign.numberOfFactions - 1 do
        local target = campaign:getFactionByOrder(i)
        if target ~= nil and target.factionID ~= me.factionID and target.name ~= "slave"
            and campaign:checkDipStance(dipRelType.war, me, target) then
            local key = me.name .. ">" .. target.name
            if not seen[key] then
                seen[key] = true
                local mark = "-"
                if target.isPlayerControlled == 1 then
                    mark = "PLAYER"
                else
                    for _, pl in ipairs(players) do
                        if campaign:checkDipStance(dipRelType.war, pl, target) then mark = "P" end
                    end
                end
                local v = ltgd:getLongTermGoalValues(target.factionID)
                log("ltgd turn " .. tostring(turnNumber()) .. " " .. key .. " [" .. mark .. "] inv=" .. field(v, "invasionType")
                    .. " prio=" .. field(v, "invadePriority") .. " atWar=" .. field(v, "atWar")
                    .. " peace=" .. field(v, "wantPeace") .. " force=" .. field(v, "forceInvade")
                    .. " canForce=" .. field(v, "canForceInvade") .. " def=" .. field(v, "defendType"))
            end
        end
    end
end

function AF.onCalculateLTGD(ltgd)
    apply("onCalculateLTGD", "ltgd")
    if ltgd == nil then return end
    local ok, err = pcall(logDecisions, ltgd)
    if not ok and not AF.ltgdErrorShown then
        AF.ltgdErrorShown = true
        log("ERROR in the decision log (shown once): " .. tostring(err))
    end
end

-- units of an army as one text
local function armyText(army)
    if army == nil then return "no army" end
    local names, counts2 = {}, {}
    for i = 0, army.numOfUnits - 1 do
        local unit = army:getUnit(i)
        local name = "?"
        pcall(function() name = tostring(unit.eduEntry.eduType) end)
        if counts2[name] == nil then counts2[name] = 0; names[#names + 1] = name end
        counts2[name] = counts2[name] + 1
    end
    local parts = {}
    for _, name in ipairs(names) do parts[#parts + 1] = counts2[name] .. "x " .. name end
    return table.concat(parts, ", ")
end

local function recordArmy(record)
    local army = nil
    pcall(function() army = record.character.army end)
    return army
end

local function facName(eventData, key)
    local name = "?"
    pcall(function() name = tostring(eventData[key].name) end)
    return name
end

function AF.onGeneralAssaultsGeneral(eventData)
    log("battle (army attacks army): " .. facName(eventData, "faction") .. " [" .. armyText(recordArmy(eventData.character))
        .. "] against " .. facName(eventData, "targetFaction") .. " [" .. armyText(recordArmy(eventData.targetCharacter)) .. "]")
end

function AF.onGeneralAssaultsResidence(eventData, settlement, fort)
    local place, garrison = "?", nil
    pcall(function() if settlement ~= nil then place = tostring(settlement.name); garrison = settlement.army end end)
    pcall(function() if fort ~= nil then place = "fort"; garrison = fort.army end end)
    log("battle (army attacks " .. place .. "): " .. facName(eventData, "faction") .. " [" .. armyText(recordArmy(eventData.character))
        .. "] against " .. facName(eventData, "targetFaction") .. " [" .. armyText(garrison) .. "]")
end

-- hooks with one argument
local function wrap(hookName, method)
    local previous = _G[hookName]
    _G[hookName] = function(a, b, c)
        if previous then previous(a, b, c) end
        local ok, err = pcall(method, a, b, c)
        if not ok then log("ERROR in " .. hookName .. ": " .. tostring(err)) end
    end
end

if not AF.installed then
    AF.installed = true
    wrap("onCampaignMapLoaded", AF.onCampaignMapLoaded)
    wrap("onFactionTurnStart", AF.onFactionTurnStart)
    wrap("onAiTurn", AF.onAiTurn)
    wrap("onCalculateLTGD", AF.onCalculateLTGD)
    wrap("onGeneralAssaultsGeneral", AF.onGeneralAssaultsGeneral)
    wrap("onGeneralAssaultsResidence", AF.onGeneralAssaultsResidence)
end

AiAttackFix = AF
