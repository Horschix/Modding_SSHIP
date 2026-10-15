---------------------------------------------------------------------------------------------------------------------
-- army_costs.lua  (Modding_SSHIP, 15 Oct 2026) - supply costs of the PLAYER's armies, with a turn report.
-- SSHIP 0.98 still hands out the traits ArmyCost (1-5: campaigning abroad / besieging) and AtSeaCost (1-2), but the
-- money part (old campaign-script monitors, kept only as a comment in economy.lua) no longer runs, and armies without
-- a general got a rebellion roll instead (armiesRebelion.lua). Rebuilt here like EUR's army_costs.lua (user, 15 Oct):
--   * SSHIP's own amounts, every difficulty (the trait rules themselves still need Very Hard):
--       general ArmyCost 1..5 : 250, 500, 1000, 1500, 2000 per turn (shown as "besieging" when his army besieges)
--       general AtSeaCost 1..2 : 500, 1000 per turn
--       army without a general in the field: 1000 in own lands, 2000 in foreign lands; besieging: 2000
--       (not charged: inside a settlement or fort, fleets, turn 0)
--       marriage of a family member: 1000; marriage to a princess: 2000 (SSHIP's old values)
--   * charged at the start of the player's turn (marriages when they happen); a message EVERY turn with costs shows
--     the total and the breakdown (marriages since the last report included)
--   * SSHIP's extra rebellion roll for armies without a general is switched off; the game's own (vanilla) rebellion
--     of such armies stays (user: "the same value as in vanilla")
--   * nothing is ever taken from an AI faction
-- Log prefix ARMYCOST. Remove the require line in luaPluginScript.lua to switch it all off (SSHIP's rebellion roll
-- then comes back).
---------------------------------------------------------------------------------------------------------------------
local AC = ArmyCosts or {}

local ARMY_COST    = { 250, 500, 1000, 1500, 2000 }
local AT_SEA_COST  = { 500, 1000 }
local CAPTAIN_HOME, CAPTAIN_ABROAD, CAPTAIN_SIEGE = 1000, 2000, 2000
local MARRIAGE, PRINCESS = 1000, 2000

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("ARMYCOST " .. tostring(text))
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

local function traitLevel(record, trait)
    local ok, value = pcall(function() return record:getTraitLevel(trait) end)
    if ok and type(value) == "number" then return value end
    return 0
end

local function turnNow() return get(M2TW.campaign, "turnNumber") or 0 end

local function isPlayer(f) return get(f, "isPlayerControlled") == 1 end

local function isNamed(char)
    local t = get(char, "characterType")
    return t ~= nil and t == get(characterType, "named_character")
end

-- marriages since the last report, per faction name: { sum, count, princess, byChar = { [key] = paid } }
AC.marriages = AC.marriages or {}

---------------------------------------------------------------------------------------------------------------------
-- the bill
---------------------------------------------------------------------------------------------------------------------
local function generalCosts(f, bill)
    for i = 0, (get(f, "numOfCharacters") or 0) - 1 do
        local okC, char = pcall(function() return f:getCharacter(i) end)
        local record = okC and get(char, "characterRecord") or nil
        if record ~= nil then
            local army = get(char, "army")
            local cost = ARMY_COST[traitLevel(record, "ArmyCost")]
            -- inside a settlement (e.g. a minor settlement in a region whose capital is foreign): SSHIP's trait still
            -- counts that as enemy lands, but no supply cost is charged (user, 15 Oct 2026)
            if cost and (get(char, "settlement") ~= nil or (army ~= nil and call(army, "findInSettlement"))) then
                log(tostring(get(record, "fullName") or get(record, "shortName")) .. ": ArmyCost "
                    .. traitLevel(record, "ArmyCost") .. " not charged (inside a settlement)")
                cost = nil
            end
            if cost then
                if army ~= nil and get(army, "siege") ~= nil then
                    bill.siegeGen = bill.siegeGen + cost; bill.nSiegeGen = bill.nSiegeGen + 1
                else
                    bill.fieldGen = bill.fieldGen + cost; bill.nFieldGen = bill.nFieldGen + 1
                end
            end
            local sea = AT_SEA_COST[traitLevel(record, "AtSeaCost")]
            if sea then bill.sea = bill.sea + sea; bill.nSea = bill.nSea + 1 end
        end
    end
end

local function captainCosts(f, bill)
    local fname = get(f, "name")
    for i = 0, (get(f, "armiesNum") or 0) - 1 do
        local okA, army = pcall(function() return f:getArmy(i) end)
        local leader = okA and get(army, "leader") or nil
        if leader ~= nil and not isNamed(leader) and get(army, "isAdmiral") ~= true
            and (get(army, "numOfUnits") or 0) > 0 and not call(army, "findInSettlement") and not call(army, "findInFort") then
            if get(army, "siege") ~= nil then
                bill.siegeCap = bill.siegeCap + CAPTAIN_SIEGE; bill.nSiegeCap = bill.nSiegeCap + 1
            else
                local okT, tile = pcall(function() return M2TW.stratMap.getTile(leader.xCoord, leader.yCoord) end)
                local rid = okT and get(tile, "regionID") or get(army, "regionID")
                local okR, region = pcall(function() return M2TW.stratMap.getRegion(rid) end)
                if okR and region ~= nil and get(region, "isSea") ~= true then
                    if get(get(region, "faction"), "name") == fname then
                        bill.homeCap = bill.homeCap + CAPTAIN_HOME; bill.nHomeCap = bill.nHomeCap + 1
                    else
                        bill.abroadCap = bill.abroadCap + CAPTAIN_ABROAD; bill.nAbroadCap = bill.nAbroadCap + 1
                    end
                end
            end
        end
    end
end

local function plural(n, one, many) return n .. " " .. (n == 1 and one or many) end

local function report(f, bill, marriage, total)
    local L = { "Keeping our armies in the field has cost the treasury " .. total .. " coins this turn"
        .. (marriage and marriage.sum > 0 and " (marriages included)." or ".") }
    if bill.nFieldGen > 0 then
        L[#L + 1] = "- " .. bill.fieldGen .. " for " .. plural(bill.nFieldGen, "general", "generals") .. " campaigning in foreign lands"
    end
    if bill.nSiegeGen > 0 then
        L[#L + 1] = "- " .. bill.siegeGen .. " for " .. plural(bill.nSiegeGen, "general", "generals") .. " besieging"
    end
    if bill.nSea > 0 then
        L[#L + 1] = "- " .. bill.sea .. " for " .. plural(bill.nSea, "general", "generals") .. " at sea"
    end
    if bill.nHomeCap > 0 then
        L[#L + 1] = "- " .. bill.homeCap .. " for " .. plural(bill.nHomeCap, "army", "armies") .. " without a general in our lands ("
            .. CAPTAIN_HOME .. " each)"
    end
    if bill.nAbroadCap > 0 then
        L[#L + 1] = "- " .. bill.abroadCap .. " for " .. plural(bill.nAbroadCap, "army", "armies") .. " without a general abroad ("
            .. CAPTAIN_ABROAD .. " each)"
    end
    if bill.nSiegeCap > 0 then
        L[#L + 1] = "- " .. bill.siegeCap .. " for " .. plural(bill.nSiegeCap, "army", "armies") .. " without a general besieging ("
            .. CAPTAIN_SIEGE .. " each)"
    end
    if marriage and marriage.sum > 0 then
        L[#L + 1] = "- " .. marriage.sum .. " for " .. plural(marriage.count, "marriage", "marriages") .. " since the last report"
            .. (marriage.princess > 0 and (" (" .. plural(marriage.princess, "with a princess", "with princesses") .. ")") or "")
    end
    L[#L + 1] = "\nA general skilled in logistics pays less. Armies without a general cost nothing inside a settlement or "
        .. "fort. These costs are not shown in the finance scroll."
    local body = "\n" .. table.concat(L, "\n")
    local ok, err = pcall(function()
        M2TW.campaign.historicEvent("HX_ARMY_COSTS", "The Cost of War", body, false, -1, -1, { get(f, "name") })
    end)
    if not ok then log("could not show the report: " .. tostring(err)) end
end

function AC.charge(f)
    if not isPlayer(f) or get(f, "money") == nil then return end
    local turn = turnNow()
    local bill = { fieldGen = 0, nFieldGen = 0, siegeGen = 0, nSiegeGen = 0, sea = 0, nSea = 0,
                   homeCap = 0, nHomeCap = 0, abroadCap = 0, nAbroadCap = 0, siegeCap = 0, nSiegeCap = 0 }
    generalCosts(f, bill)
    if turn > 0 then captainCosts(f, bill) end
    local armies = bill.fieldGen + bill.siegeGen + bill.sea + bill.homeCap + bill.abroadCap + bill.siegeCap
    local marriage = AC.marriages[get(f, "name")]
    AC.marriages[get(f, "name")] = nil
    local total = armies + (marriage and marriage.sum or 0)
    if total <= 0 then return end
    if armies > 0 then f.money = f.money - armies end   -- marriages were paid when they happened
    log(tostring(get(f, "name")) .. " turn " .. turn .. ": armies " .. armies .. " (generals field " .. bill.nFieldGen
        .. ", siege " .. bill.nSiegeGen .. ", sea " .. bill.nSea .. "; captains home " .. bill.nHomeCap .. ", abroad "
        .. bill.nAbroadCap .. ", siege " .. bill.nSiegeCap .. "), marriages " .. (marriage and marriage.sum or 0))
    report(f, bill, marriage, total)
end

---------------------------------------------------------------------------------------------------------------------
-- marriages: paid at once; a princess marriage may also fire the normal marriage event -> charged once, 2000 in all
---------------------------------------------------------------------------------------------------------------------
local function marriage(eventData, amount, princess)
    local f = get(eventData, "faction")
    if not isPlayer(f) then return end
    local record = get(eventData, "character")
    local key = turnNow() .. ":" .. tostring(get(record, "localizedDisplayName") or get(record, "fullName") or "?")
    local fname = get(f, "name")
    local m = AC.marriages[fname] or { sum = 0, count = 0, princess = 0, byChar = {} }
    AC.marriages[fname] = m
    local paid = m.byChar[key] or 0
    local due = math.max(0, amount - paid)
    if paid == 0 then m.count = m.count + 1 end
    if princess and not m.byChar[key .. ":p"] then m.princess = m.princess + 1; m.byChar[key .. ":p"] = true end
    m.byChar[key] = paid + due
    if due > 0 then
        f.money = f.money - due
        m.sum = m.sum + due
    end
    log(tostring(fname) .. ": marriage " .. key .. (princess and " (princess)" or "") .. " charged " .. due)
end

---------------------------------------------------------------------------------------------------------------------
-- hooks
---------------------------------------------------------------------------------------------------------------------
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

-- SSHIP's extra rebellion roll off (the module table is shared with main.lua, so replacing the field is enough)
local function switchOffRebellionRoll()
    local ok, mod = pcall(require, "sship.armiesRebelion")
    if ok and type(mod) == "table" then
        mod.checkArmiesLoyalty = function() end
        log("SSHIP's armiesRebelion roll switched off (vanilla rebellion of armies without a general stays)")
    else
        log("ERROR: armiesRebelion not found - its rebellion roll stays on")
    end
end

if not AC.installed then
    AC.installed = true
    afterHook("onFactionTurnStart", function(e) AC.charge(get(e, "faction")) end)
    afterHook("onCharacterMarries", function(e) marriage(e, MARRIAGE, false) end)
    afterHook("onCharacterMarriesPrincess", function(e) marriage(e, PRINCESS, true) end)
    switchOffRebellionRoll()
end

ArmyCosts = AC
return AC
