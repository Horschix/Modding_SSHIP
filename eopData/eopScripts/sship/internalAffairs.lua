 local log = LOG.new()
 log.level = LOG_LEVELS.internalAffairs

 local helpers = require('sship.helpers')
 local module = {
     _DESCRIPTION = 'Succession, civil war and rebelions script',
     _AUTHOR = 'Macaras'
 }

 local formerHeir
 local formerLeader
 local newHeir
 local newLeader
 local throneSwitchReady = 0
 local rebelionPoints
 local settlNumberFactor = 0

local corruptionSett = 0
local corruption = 0
local factionsArea = 0
local connectionFactor = 0
local relDiversity = 0      -- 1 means religion completely unified, 0 means only nonfaction-religions present
local publUnrest = 0
local publEntertainment = 0
local publLaw = 0
local publUnrestSett = 0
local publEntertainmentSett = 0
local publLawSett = 0
local generalsTraits
local loyaltySettlements = 0

--[[

The new system in eop explanation:

1. If FL dies without any heir, the new FL is one of the family members, choosing of an heir is left to the engine
2. If FL dies with an adult heir, he becomes a new FL
3. If FL dies with his heir underage, the underage heir becomes an FH (eop) and the other family member becomes the FL with a trait Regent.
Also every end of turn it should be checked if the FL has a son, even underage, and this son should become a FH asap.

Regent historical event should be triggered, and checked every turn until the boy heir becomes adult, then:
1. The Regent FL gives back the power peacefully to the boy heir (it happens when regent chivalry and piety is more then 3)
2. The Regent refuses to release the power and civil war starts, the boy is killed or exiled and new FL appeared

Reasons to start a civil war:
1. Regent refuses to give power back,
2. The kingdoms disunity points grow high,
3. The usurper general appears if FL has low authority

]]
---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Adjustable variables
---------------------------------------------------------------------------------------------------------------------------------
local maxWarningTurns = 7  -- civil war warning, maybe adjusted to whatever number, after these turn number civil war will trigger
local civilWarThreshold = 20 -- civil war warning, if rebelion points calculated are higher than this - civil war happens
local aiEasierLife = 35 -- this will be subtracted from ai rebelion points, to make it easier for ais
local mongolsEasierLife = 150   -- Mongols conquers very big and diverse area very fast, pagans in the muslim and orthodox world, need a special relief  
local playerEasierLife = 0  -- decrease civil war point on lower difficulties
local SETTL_POINTS = 2.5  -- Horschix 14 Oct 2026: was 10 per settlement above the limit; a quarter now, because SSHIP_submod #4 adds many small towns (all settlements count the same)
-- Horschix 16 Oct 2026: free settlement allowance = the faction's settlement count at campaign start (descr_strat +
-- starting_settlements.lua, counted 16 Oct), at least SSHIP's 10; SSHIP's growth over time is added on top.
-- Factions not listed (10 or fewer at start, or appearing later) keep SSHIP's 10.
local START_SETTLEMENTS = { hre = 55, byzantium = 46, moors = 40, turks = 27, hungary = 21, england = 19, poland = 17, sicily = 16, egypt = 15, jerusalem = 14, cumans = 13, spain = 13, zengid = 13, kievan_rus = 12 }
local AI_FIRST_TURN = 30  -- Horschix 16 Oct 2026: AI civil wars from this turn on (SSHIP: after turn 5)
local AI_CHANCE = 25      -- Horschix 16 Oct 2026: % chance per turn once over the threshold (SSHIP: 33)
---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Main Function CivilWar
---------------------------------------------------------------------------------------------------------------------------------
---@param faction factionStruct
function module.mainFunctionCivilWars(faction)
    local revoltPoints
    -- module. is left so in the future there mey be an access to these resources from the main.lua, especially:
    -- civilWarRise, countRevoltPoints..
    if faction.isPlayerControlled == 1 then
	   -- if the points are above the threshold and player received warnings more times then maxWarningTurns, start civil war
	   -- the function internalAffairs.civilWarWarning(faction) displays a warning and returns how many times the warning appeared
	   revoltPoints = module.countRevoltPoints(faction)
		-- in case the player reloads the script:
	   if SAVED_DATA.civilWarWarningTurnsFactions == nil or SAVED_DATA.civilWarWarningTurnsFactions[faction.name]==nil then module.initCivilWarningTurns(faction) end
	  	-- here is where the warning turns are stored globally and saved:
	   local civilWarningNumber = SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns
	   	if revoltPoints > civilWarThreshold then
			civilWarningNumber = module.civilWarWarning(faction)	-- here the warning event is called and warning counter increased
	   	end
	   -- if the revolt points are too big and the turn number is as desired, consider civil war:
	   	if revoltPoints > civilWarThreshold and M2TW.campaign.turnNumber > 0 then
			--if the warnings were shown a number of turns, start civil war:
	   		if civilWarningNumber == maxWarningTurns then
				-- here the civil war will already happen, just the question how big should it be
				if revoltPoints < 30 then  module.civilWarRise(faction,-10,'too big') -- small civil war
				elseif revoltPoints > 30 and revoltPoints < 50 then module.civilWarRise(faction,0,'too big')
				elseif revoltPoints > 50 then module.civilWarRise(faction,20,'too big')
				end
                module.cancelVassals(faction)
			end
		end
		if revoltPoints <= civilWarThreshold then
		-- revolt point are below threshold, but if its after some warnings, there should be an info for the player
			if civilWarningNumber > 0 then
				module.afterWarningEvent(faction)
				SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns = 0
		-- if there was no warning before -> internalAffairs.turnsAfterWarning = 0, so also no info for the player
			else
				SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns = 0
			end
		end
    else    -- for AI
        -- if faction too big - civil war, but the revolt points are always lower than the player's because of the standard AI bonuses in the game.
		-- Also for AI there is no warning.
		-- this works also in place of mongol decline script, so the powerful faction will not conquer the world too quickly
        local hitChance = helpers.randomNumber(0,100)
        local revoltPoints = module.countRevoltPoints(faction)
        if M2TW.campaign.turnNumber >= AI_FIRST_TURN and revoltPoints > civilWarThreshold and hitChance < AI_CHANCE then
            module.civilWarRise(faction,0,'too big ai')
        end
    end
    SAVED_DATA.civilWarWarningTurnsFactions[faction.name].revoltPoints = revoltPoints
end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Init and Print Civil War factors
---------------------------------------------------------------------------------------------------------------------------------

---@param fac factionStruct
 function module.initCivilWarningTurns(fac)
    log.debug("InternalA: Warning Points Table Created for Faction: "..fac.name)
    SAVED_DATA.civilWarWarningTurnsFactions[fac.name] = {civilWarWarningTurns=0}
    log.debug("CW Init: Table created, points for faction:"..fac.name.." is: "..SAVED_DATA.civilWarWarningTurnsFactions[fac.name].civilWarWarningTurns)
    maxWarningTurns = 5+ helpers.randomNumber(0,3)

end

function module.printCivilWarningTurns()
    if SAVED_DATA.civilWarWarningTurnsFactions == nil then return end
    --print the table of all the factions points:
    log.debug("======== The Civil War warning turns table of all the factions: ============")
    local campaign = M2TW.campaign
    for i = 0, campaign.numberOfFactions - 1 do
        local fac = campaign:getFactionByOrder(i);
        if SAVED_DATA.civilWarWarningTurnsFactions[fac.name] == nil then
            log.debug("SAVED_DATA.civilWarWarningTurnsFactions[fac.name].civilWarWarningTurns was not initialized (so 0 is given)")
            SAVED_DATA.civilWarWarningTurnsFactions[fac.name] = {civilWarWarningTurns=0}
        end
        log.debug("Warning turns: Faction: "..fac.name.." | turns: "..SAVED_DATA.civilWarWarningTurnsFactions[fac.name].civilWarWarningTurns)
    end
    log.debug("====================================================")
end


---------------------------------------------------------------------------------------------------------------------------------
-- MARK: countRevoltPoints
---------------------------------------------------------------------------------------------------------------------------------
---@param faction factionStruct
---@return integer
function module.countRevoltPoints(faction)

if faction == nil or faction.leader == nil then
    log.debug("InternalA: Faction, its leader or other resource doesnt exist anymore.")
    return 0
end
if faction.name == 'slave' then
    log.debug("InternalA: No counting rebelion points for the slave faction.")
    return 0
end
-- if 2 or more settlements lost it means probably a small revolution or overwhelming enemy,
-- do no shown the warning nor count points this turn
if faction.settlementsLost > 2 then
    log.debug("InternalA: Return - faction's settlements lost "..faction.settlementsLost)
    faction.settlementsLost = 0
    return 0
end

-- Horschix 16 Oct 2026: reset the module-level sums (SSHIP reset them only after a player warning, so AI values carried over)
corruption = 0; publUnrest = 0; publEntertainment = 0; publLaw = 0; loyaltySettlements = 0; relDiversity = 0
--------------------------------------------------------------------------
-- FIRST LOOP THROUGH THE CHARACTERS, COLLECT THE TRAITS VALUES
    local loyaltyCharacters = 0
    local chivalryFac = 0
    local pietyFac = 0
    for i=0, faction.numOfCharacters -1 do
        local ourCharacter = M2TW.campaign:getFaction(faction.name):getCharacter(i)
        log.debug("InternalA: character number "..i.." Character name: "..ourCharacter.characterRecord.localizedDisplayName.." Character loyalty: "..ourCharacter.characterRecord.loyalty..",chivalry: "..ourCharacter.characterRecord.chivalryAndDread..",piety: "..ourCharacter.characterRecord.piety)
        loyaltyCharacters = loyaltyCharacters + ourCharacter.characterRecord.loyalty
        chivalryFac = chivalryFac + ourCharacter.characterRecord.chivalryAndDread
        pietyFac = pietyFac + ourCharacter.characterRecord.piety
    end
    -- dread/chivalry are from -10 to +10, while the other are from 0 to 10, so above 5 decreases the rebelion chance
    loyaltyCharacters = loyaltyCharacters / faction.numOfCharacters -5
    chivalryFac = chivalryFac / faction.numOfCharacters
    pietyFac = pietyFac / faction.numOfCharacters -5
    generalsTraits = loyaltyCharacters + chivalryFac + pietyFac     -- good traits (high numbers) should be  subtracted from the rebelion points
--------------------------------------------------------------------------
-- LOOP THROUGH SETTLEMENTS, COLLECT CORRUPTION, ROADS, LAW BUILDINGS ETC.
    -- first roads
    local roadsNumber = 0
    local distanceCapital = 0
    local isPresentCastle = false
    local isPresentCity = false
    for i = 0, faction.settlementsNum - 1 do
        local settlem1 = faction:getSettlement(i)
        if settlem1.isCastle == 1 then
            isPresentCastle = settlem1:buildingPresentMinLevel("c_roads", false)
            log.debug("InternalA: Castle "..settlem1.name..": Roads present: "..tostring(isPresentCastle))
            if isPresentCastle then roadsNumber = roadsNumber + 1 end  -- Horschix 16 Oct 2026: SSHIP counted every settlement
        else
            isPresentCity = settlem1:buildingPresentMinLevel("roads", false)
            log.debug("InternalA: City "..settlem1.name..": Roads present: "..tostring(isPresentCity))
            if isPresentCity then roadsNumber = roadsNumber + 1 end
        end
        log.debug("InternalA: -------- settlement info: "..settlem1.name.." --------")
        log.debug("InternalA: corruption: "..settlem1.settlementStats.CorruptionExpense)
        log.debug("InternalA: total income: "..settlem1.settlementStats.TotalIncomeWithoutAdmin)
        log.debug("InternalA: total PublicOrderLaw: "..settlem1.settlementStats.PublicOrderLaw) -- Constantinople: 12
        log.debug("InternalA: total PublicOrderBuildingsEntertainment: "..settlem1.settlementStats.PublicOrderBuildingsEntertainment)
        log.debug("InternalA: settlem1.siegeDuration: "..settlem1.siegeDuration)
        log.debug("InternalA: settlem1.settlem1.settlementStats.PublicOrderUnrest: "..settlem1.settlementStats.PublicOrderUnrest) --1 point for 5%
        log.debug("InternalA: settlem1.turnsOwned: "..settlem1.turnsOwned)
        log.debug("InternalA: settlem1.loyalty: "..settlem1.loyaltyLastTurn)
        -- corruption per settlement is always between 0 and 1, so it may be added to the total revolt probability:
        -- total factION corruption it is usually a small value, for ex hre - 0.03; cities with 0 corruption improve the faction's statistics
        corruptionSett = settlem1.settlementStats.CorruptionExpense / settlem1.settlementStats.TotalIncomeWithoutAdmin
        --should unrest be changed to turmoil
        publUnrestSett = settlem1.settlementStats.PublicOrderUnrest
        publEntertainmentSett = settlem1.settlementStats.PublicOrderBuildingsEntertainment
        publLawSett = settlem1.settlementStats.PublicOrderLaw
        -- adding values for all settlments
        corruption = corruption + corruptionSett
        publUnrest = publUnrest + publUnrestSett
        publEntertainment = publEntertainment + publEntertainmentSett
        publLaw = publLaw + publLawSett  -- Horschix 16 Oct 2026: SSHIP had publEntertainment + publLawSett
        -- loyalty in settl. is above 100 -> means happy, or lower then 100 which means unrest, 100 is too easy to keep though
        loyaltySettlements = loyaltySettlements + (settlem1.settlementStats.PublicOrder - 125) 
    -- - distanceCapital is 0-10, so percentage divided by 10, its a good marker of how big the spreading area
        log.debug("InternalA: -- distance to Capital: "..settlem1.settlementStats.PublicOrderDistanceToCapital)
        distanceCapital = distanceCapital + (settlem1.settlementStats.PublicOrderDistanceToCapital / 10)
    -- -religion unity- checking faction's religion support through all the settlements, KofJersusalem - 0.35, HRE - 0.84
        local settReligion = 1- settlem1:getReligion(faction.factionRecord.religionID) -- this will give low values, close to 0 for the unified settlements, and big for diverse religion
        log.debug("InternalA: "..settlem1.name.. ", faction's religion value: "..settReligion)
        relDiversity = relDiversity + settReligion  -- sum for all the settlements
    end

    --------------------------------------------------------------------------
    -- the values must be standardized, divided by the number of settlements
    -- more religious united faction, smaller value
    relDiversity = relDiversity / faction.settlementsNum
    corruption = corruption / faction.settlementsNum
    publUnrest = publUnrest / faction.settlementsNum
    publEntertainment = publEntertainment / faction.settlementsNum
    publLaw = publLaw / faction.settlementsNum
    loyaltySettlements = loyaltySettlements / faction.settlementsNum
    --------------------------------------------------------------------------
    -- OTHER FACTIONS FEATURES, APART FROM SETTLEMENTS OR GENERALS
    factionsArea = distanceCapital / faction.settlementsNum
    local portsNumber = M2TW.campaign.currentFaction.portsNum
    -- connectionFactor value - less roads, the bigger factor
    connectionFactor =(roadsNumber + portsNumber) / faction.settlementsNum
    -- watchtowers if 0 then factor = 1, if 10 or more is always 0,
    -- so buildig more then 10 watchtowers doesnt affect the civil war
    local watchtowerNumber = M2TW.campaign.currentFaction.watchtowersNum
    if watchtowerNumber > 10 then watchtowerNumber = 10 end
    -- warmonger and aggressive status
    local warmongerCounterValue =  M2TWEOP.getScriptCounter("PLAYER_AGGRESSIVITY_WARMONGER")
    local aggCounterValue =  M2TWEOP.getScriptCounter("PLAYER_AGGRESSIVITY_AGGRESSIVE")

    --------------------------------------------------------------------------
    -- settlements number, ex in first 50 turns more then 10 settlements will add rebelion points:

    -- Horschix 16 Oct 2026: SSHIP's schedule (10 / 11 / 11 / 12 / 13 / 14 / 17 / 30) is now growth on top of the
    -- faction's starting size (START_SETTLEMENTS, at least 10).
    local turn = M2TW.campaign.turnNumber
    local growth
    if turn < 50 then growth = 0
    elseif turn < 150 then growth = 1
    elseif turn < 200 then growth = 2
    elseif turn < 250 then growth = 3
    elseif turn < 300 then growth = 4
    elseif turn < 400 then growth = 7
    else growth = 20
    end
    local allowance = math.max(10, START_SETTLEMENTS[faction.name] or 10) + growth
    settlNumberFactor = faction.settlementsNum - allowance
    log.debug("InternalA: Faction's settlement allowance "..allowance.." (owns "..faction.settlementsNum..")")
    --------------------------------------------------------------------------
    -- logs:

    log.debug("InternalA: Faction's settlNumberFactor "..settlNumberFactor*SETTL_POINTS)
    log.debug("InternalA: Faction's roadsnumber "..roadsNumber)
    log.debug("InternalA: Faction's portsnumber "..portsNumber)
    log.debug("InternalA: Faction's connection factor "..connectionFactor*5)
    log.debug("InternalA: Faction's watchtower number "..watchtowerNumber)
    log.debug("InternalA: Faction's area "..factionsArea*50)
    log.debug("InternalA: Faction's religious diversity "..relDiversity*50)
    log.debug("InternalA: Faction's corruption "..corruption*50)
    log.debug("InternalA: Faction's publUnrest "..publUnrest*5)
    log.debug("InternalA: Faction's publEntertainment "..publEntertainment*5)
    log.debug("InternalA: Faction's publLaw "..publLaw*5)
    log.debug("InternalA: Faction's settlements average loyalty "..loyaltySettlements*0.5)
    log.debug("InternalA: generals average loyalty "..loyaltyCharacters)
    log.debug("InternalA: Faction's average chivalry "..chivalryFac)
    log.debug("InternalA: Faction's average piety "..pietyFac)
    log.debug("InternalA: Warmonger, rebelion more likely! value: "..warmongerCounterValue*5)
    log.debug("InternalA: Aggressive, rebelion more likely! value: "..aggCounterValue*5)
    log.debug("InternalA: Faction's generals traits "..generalsTraits*5)
    log.debug("InternalA: Faction's leader.authority "..faction.leader.authority*2)
    --------------------------------------------------------------------------
    -- final calculation:
    -- loyaltySettlements may be -15 for example, so then it adds to rebelion chance
    local infrastructure = - watchtowerNumber - publEntertainment*5 - publLaw*5 - loyaltySettlements*0.5 - connectionFactor*5
    local kingdom = - faction.leader.authority*2 + settlNumberFactor*SETTL_POINTS + factionsArea *50 + warmongerCounterValue*5 + aggCounterValue*5
    local people = relDiversity*50 - generalsTraits*5 + publUnrest*5 + corruption*100
    rebelionPoints =  infrastructure + kingdom + people
    local campaign = M2TW.campaign
	local difficultLevel = campaign.campaignDifficultyFaction[faction.factionID+1]
    --local difficultLevel = M2TWEOP:getOptions2().campaignDifficulty
    if faction.isPlayerControlled == 1 then -- easier for lower difficulties
        if difficultLevel == 3 then
            log.info("InternalA: faction is player controlled and difficulty is VH: "..M2TWEOP:getOptions2().campaignDifficulty)
            playerEasierLife = 0
        elseif difficultLevel == 2 then
            log.info("InternalA: faction is player controlled and difficulty is H: "..M2TWEOP:getOptions2().campaignDifficulty)
            playerEasierLife = 10
        elseif difficultLevel < 2 then
            log.info("InternalA: faction is player controlled and difficulty is M: "..M2TWEOP:getOptions2().campaignDifficulty)
            playerEasierLife = 20
        end
        rebelionPoints = rebelionPoints - playerEasierLife
    elseif faction.isPlayerControlled == 0 then rebelionPoints = rebelionPoints - aiEasierLife -- easier for AI
    end     
    if faction.name == 'mongols' then rebelionPoints = rebelionPoints - mongolsEasierLife end
    log.info("InternalA: the total rebelion points for faction "..faction.name.." is: "..rebelionPoints)
    return rebelionPoints
end


---------------------------------------------------------------------------------------------------------------------------------
-- MARK: civilWarWarning
---------------------------------------------------------------------------------------------------------------------------------
---@param faction factionStruct
---@return integer
function module.civilWarWarning(faction)
    if faction.name == 'slave' then
        log.debug("InternalA: No civil war for slave faction.")
        return 0
    end
    if SAVED_DATA.civilWarWarningTurnsFactions == nil or SAVED_DATA.civilWarWarningTurnsFactions[faction.name] == nil then
        SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns = 0
    end
    local civilWarWarningTurns = SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns

    log.debug("InternalA: Civil War Warning shown number: "..civilWarWarningTurns.." Max Turn number: "..maxWarningTurns)
    -- call the warning even as long as the max warning turns is not reached,
    -- minus one so that the last info is avoided, instead the civil war will happen
    if civilWarWarningTurns < maxWarningTurns - 1 then
        local factions = {M2TW.campaign.currentFaction.name}
        local civilWarTitle = "Civil War Warning "
        local civilWarBody = "   The kingdom, grown too vast and too swiftly, now suffers the pangs of disunity, a malady that hath felled many an empire in ages past. True and great dominions are built slowly upon the virtue, honesty, and hard work of all inhabitants. Relying solely on conquest and brutal force is unsustainable- the unity and virtue of citizens is essential. Vast lands, diverse cultures, and the ambitions of haughty nobles breed discontent, and thy rebellion score is a perilous: "..math.floor(rebelionPoints).." Should this number be equal or exceed "..civilWarThreshold..", beware of the specter of division. These be the causes of rebellion: \n  • The rebelion points from the number of settlements: "..tostring(settlNumberFactor*SETTL_POINTS).."\n  • Rebelion points due to faction's leader authority: "..tostring(- faction.leader.authority*2).." \n  • Public unrest: "..math.floor(publUnrest*5).." \n  • Roads, ports: "..math.floor(-connectionFactor*10).." \n  • Loyalty of people in your settlements: "..math.floor(-loyaltySettlements*0.5).." \n  • Size of the land area, points: "..math.floor(factionsArea*50).." \n  • Buildings of law and entertainment, points: "..math.floor(-publEntertainment*5 - publLaw*5).."\n  • Traits of your generals: "..math.floor(-generalsTraits*5).."\n  • Corruption: "..math.floor(corruption*100).." \n  • Rebelion points from religious diversity/unity: "..math.floor(-relDiversity*50).."\n  • Being considered aggressor or warmonger (+5 points for each)."
        M2TW.campaign.historicEvent("CIVIL_WAR_WARNING", civilWarTitle, civilWarBody, false,-1,-1,factions)
    end
    civilWarWarningTurns = civilWarWarningTurns + 1
    SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns = civilWarWarningTurns
    -- reset all factors
    corruption = 0
    factionsArea = 0
    connectionFactor = 0
    relDiversity = 0
    publUnrest = 0
    publEntertainment = 0
    publLaw = 0
    publUnrestSett = 0
    publEntertainmentSett = 0
    publLawSett = 0
    generalsTraits = 0
    loyaltySettlements = 0
return civilWarWarningTurns
end



---------------------------------------------------------------------------------------------------------------------------------
-- MARK: afterWarningEvent
---------------------------------------------------------------------------------------------------------------------------------
---@param faction factionStruct
function module.afterWarningEvent(faction)
    if faction.name == 'slave' then
        log.debug("InternalA: InternalA: No civil war for slave faction.")
        return 0
    end
    if SAVED_DATA.civilWarWarningTurnsFactions == nil or SAVED_DATA.civilWarWarningTurnsFactions[faction.name] == nil then
        SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns = 0
    end
     log.debug("InternalA: Settlements factor: "..settlNumberFactor)
        local factions = {M2TW.campaign.currentFaction.name}
        local civilWarTitle = "Civil War no more a threat  "
        local civilWarBody = " \n Your rebelion points are now: "..math.floor(rebelionPoints)..". For the future - remedies exist to quell the rising tides of rebellion:\n  • Make sure your leader has authority \n  • Build roads, ports\n  • Make sure public unrest is low (quickest way to lower rebelion points, even just lowering taxes may help to silence the rebels) \n  • Fight corruption, build law buildings\n  • Build watchtowers (though their aid be but a small measure)\n  • Ensure your generals possess the virtues of loyalty, chivalry, and piety\n  • Strive to see the true faith (your kingdom's official religion) prevail in all corners of the lands, that unity of spirit may bind the people. Furthermore, every 50 turns the number of settlements that may be owned without risking the civil war increases."
        M2TW.campaign.historicEvent("CIVIL_WAR_WARNING", civilWarTitle, civilWarBody, false,-1,-1,factions)
    -- reset all factors
    corruption = 0
    factionsArea = 0
    connectionFactor = 0
    relDiversity = 0
    publUnrest = 0
    publEntertainment = 0
    publLaw = 0
    publUnrestSett = 0
    publEntertainmentSett = 0
    publLawSett = 0
    generalsTraits = 0
    loyaltySettlements = 0
    maxWarningTurns = 5 + helpers.randomNumber(0,3)
end
---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Disband Units
---------------------------------------------------------------------------------------------------------------------------------
---@param army armyStruct
local function disbandNonRebelUnits(army)
-- table with the units from EDU (unit_type) that should be disbanded
-- jihad is different, there are no special jihad units, mutatawi worriors are recruited in the cities and may be kept after jihad
if not army then return end
local hitlist = {}
    for u=0, army.numOfUnits -1 do
        local thisUnit = army:getUnit(u)
        local hasSlaveOwnership = thisUnit.eduEntry:hasOwnership(30) -- slaveId is 30 always
            if hasSlaveOwnership == false then
                table.insert(hitlist,thisUnit)
                log.info("InternalA: non-rebel units disbanded, unit: "..thisUnit.eduEntry.eduType..", hasSlaveOwnership: "..tostring(hasSlaveOwnership))
            end
    end
    for k=1, #hitlist do
        hitlist[k]:kill()
    end
end
---------------------------------------------------------------------------------------------------------------------------------
-- MARK: civilWarRise
---------------------------------------------------------------------------------------------------------------------------------
--civilWarScale should not be bigger then 100 - that will make all the cities rebell
---@param faction factionStruct
---@param civilWarScale integer
---@param civilWarReason string
function module.civilWarRise(faction, civilWarScale, civilWarReason)

    if faction.name == 'slave' then
        log.debug("InternalA: No civil war for slave faction.")
        return 0
    end
    log.debug("InternalA: ------- Civil war begins: "..faction.name)
    -- loop through settlements
        for i = 0, faction.settlementsNum - 1 do
            local governorLoyalty
            local newOwner = M2TW.campaign:getFaction("slave")
            local settlem1 = faction:getSettlement(i)
            log.debug("InternalA: ------- settlement being checked: "..settlem1.name)


            if settlem1.governor ~= nil and settlem1.governor.characterRecord.loyalty > 0 then
                local isLeader = settlem1.governor.characterRecord:isLeader()
                local isHeir = settlem1.governor.characterRecord:isHeir()

                governorLoyalty = settlem1.governor.characterRecord.loyalty
                if isHeir == true or isLeader == true then governorLoyalty = 100 end    -- settlements with king or heir should not revolt.
                log.debug("InternalA: Governing character in settlement "..settlem1.name.." has loyalty: "..governorLoyalty)

            else
                governorLoyalty = 0
            end
            local distanceCapital = settlem1.settlementStats.PublicOrderDistanceToCapital
            log.debug("InternalA: distance to capital: "..distanceCapital)
            local revoltChance = helpers.randomNumber(0,100) - governorLoyalty + distanceCapital + civilWarScale
            log.debug("InternalA: revolt chance is: "..revoltChance)
            log.debug("InternalA: settlem1.isCapital: "..tostring(settlem1.isCapital))
            log.debug("InternalA: settlem1.siegeDuration: "..tostring(settlem1.siegeDuration))
            if revoltChance > 50 and settlem1.isCapital == false and settlem1.siegeDuration == 0 then
                settlem1:changeOwner(newOwner, true)
                log.debug("InternalA: settlement: "..settlem1.name.." rebelled!")
                local settlem1Army = settlem1.army
                disbandNonRebelUnits(settlem1Army)  -- there is a bug in the current version of eop, will wait untill its fixed
            else
                log.debug("InternalA: settlement: "..settlem1.name.." did not rebelled.")
            end
        end
    -- loop through the generals that are not in the settlement

        local inSettlement
        local slaveFaction = M2TW.campaign:getFactionByID(30);

        for i=0, faction.numOfCharacters -1 do
            local ourCharacter = M2TW.campaign:getFaction(faction.name):getCharacter(i)
            local ourType=ourCharacter:getTypeName();
            inSettlement = ourCharacter.settlement
            --if general in the settlement (if not, inSettlement = nil), or is the leader/heir no rebellion
            if inSettlement ~= nil or ourCharacter.characterRecord:isLeader() == true or ourCharacter.characterRecord:isHeir() == true then
                log.debug("InternalA: name: "..ourCharacter.characterRecord.localizedDisplayName.." Character is a leader/heir or in the settlement")
            else
                if ourType == "named_character" then -- named_character is basicaly a general, so diplomasts, spies etc are excluded
                    local revoltChance = helpers.randomNumber(0,10)
                    if revoltChance > ourCharacter.characterRecord.loyalty then     -- loyalty is up to 10, so loyalty 0 will always revolt, 10 never
                        log.debug("InternalA: name: "..ourCharacter.characterRecord.localizedDisplayName..", loyalty: "..ourCharacter.characterRecord.loyalty)
                        ourCharacter:switchFaction(slaveFaction, true,true)
                        log.debug("InternalA: Character: "..ourCharacter.characterRecord.localizedDisplayName.."rebelled.")
                        -- there is a need to remove the units that have no slave ownership!
                        local ourCharacterArmy = ourCharacter.army
                        if ourCharacterArmy then disbandNonRebelUnits(ourCharacterArmy) end
                    end
                end
            end
        end




        -- the message for the player
        log.debug("InternalA: civilWarScale: "..civilWarScale)
        log.debug("InternalA: civilWarReason: "..civilWarReason)
        --need to create a table for the historicEvent function
        local factions = {M2TW.campaign.currentFaction.name}

        if civilWarReason == 'too big' then
            local civilWarTitle = "Civil War in "..faction.localizedName
            local civilWarBody = "\n  Whispers of conspiracy, corruption and discontent have turned to open rebellion! The drums of war echo across the land! The shadow of civil war descended over this country as the noble houses turned away from their enemies and against each other... \n  The victorious leader is "..faction.leader.localizedDisplayName..". Some cities might have been lost to rebelion, the new ruler will need to unite the kingdom again.\n  At the begining of the game it is difficult to maintain a big area or many settlements, but with time it becomes easier and easier. Sometimes the only way is to wait, consolidate your kingdom before continuing conquest."
            M2TW.campaign.historicEvent("CIVIL_WAR", civilWarTitle, civilWarBody, false,-1,-1,factions)
            SAVED_DATA.civilWarWarningTurnsFactions[faction.name].civilWarWarningTurns = 0
            maxWarningTurns = 5 + helpers.randomNumber(0,3)
        elseif civilWarReason == 'too big ai' then
            local civilWarTitle = "Civil War in "..faction.localizedName
            local civilWarBody = "\n  Whispers of conspiracy, corruption and discontent have turned to open rebellion! The drums of war echo across the land! The shadow of civil war descended over this country as the noble houses turned away from their enemies and against each other... \n  The victorious leader is "..faction.leader.localizedDisplayName..". Some cities might have been lost to rebelion, the new ruler will need to unite the kingdom again."
            M2TW.campaign.historicEvent("CIVIL_WAR", civilWarTitle, civilWarBody, false)    -- this warning is for all players to see
        elseif civilWarReason == 'regent' then
            local civilWarTitle = "Civil War in "..faction.localizedName
            local civilWarBody = "\n  Listen to this tale of trouble, where ambition throws seeds of discord in a once-great kingdom! The Lord Regent, who promised to rule until the true heir could take over, has given in to the temptation of power. His heart has became as hard as iron, and he refused to give up the throne to the young lord who has every right to rule.\n\n  Now, the kingdom is hit by disaster, torn apart as noble houses took sides — some swearing loyalty to the Regent, others pledging their swords to the rightful ruler. \n\n  The Regent has holed up in the capital, surrounded by loyal guards and mercenaries whose loyalty is bought with gold. This lesson teaches us that chivalry and loyalty are valuable qualities in your nobles.\n\n  Keep your governors in happy settlements with low taxes, build churches and tournament grounds, and free the prisoners. You'll find that the good traits of your generals will help your kingdom to thrive."
            M2TW.campaign.historicEvent("CIVIL_WAR", civilWarTitle, civilWarBody, false,-1,-1,factions)
        elseif civilWarReason == 'vicious regent' then
            local civilWarTitle = "Civil War in "..faction.localizedName
            local civilWarBody = "\n  As a storm mirrored the turmoil in his soul, Lord Regent summoned his closest advisors to the dimly lit chamber. His voice, a menacing rasp, cut through the tense silence: the rightful heir was a threat to the kingdom that needed to be removed. Under the cloak of the following night, lord regent's men stormed the prince's chambers, dragging the boy from his bed and spiriting him away to the castle's deepest dungeons. There, with cold resolve, the Regent sealed his fate: the boy would never challenge him.\n\n  But fate, as it often does, has challenged the tyrant. Knights fiercely loyal to the late king uncovered the Regent's treachery. A civil war erupted, tearing the kingdom apart and resulting in division and the loss of cities. Yet, in the end, the vicious Regent and his forces prevailed.\n\n  With the heir mysteriously vanished, the former Regent crowned himself king amidst ashes and sorrow. Turmoil gripped the cities, and dissent increased."
            helpers.adjustTurmoil(faction, 20)
            M2TW.campaign.historicEvent("CIVIL_WAR", civilWarTitle, civilWarBody, false,-1,-1,factions)
        elseif civilWarReason == 'usurper' then
            local civilWarTitle = "Civil War in "..faction.localizedName
            local civilWarBody = "\n  A grave shadow has fallen upon our land. The vile usurper, consumed by envy and discontent with the righteous and benevolent rule of our rightful king, has dared to sow discord among the people. With a heart blackened by ambition, this traitor has ignited the flames of civil war, tearing at the very fabric of our kingdom's peace. Villages burn, families are divided, and the once-harmonious land now trembles under the weight of betrayal. The fate of the crown rests in your hands. You must rally your strength, gather loyal allies, and march forth to restore the unity and honor to our beleaguered realm."
            M2TW.campaign.historicEvent("CIVIL_WAR", civilWarTitle, civilWarBody, false,-1,-1,factions)
        end

end


---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Cancel Vassals
---------------------------------------------------------------------------------------------------------------------------------
function module.cancelVassals(facSuperior)
    if facSuperior.name == 'slave' then
        return 0
    end
        local factionsNum = M2TW.campaign.numberOfFactions;
        for i = 1, factionsNum do
            local facInferior = M2TW.campaign.factionsSortedByDescrStrat[i]
            if M2TW.campaign:checkDipStance(dipRelType.suzerain, facInferior, facSuperior) then 
                M2TW.campaign:setDipStance(dipRelType.peace, facSuperior, facInferior)
                log.debug("InternalA: faction: "..facSuperior.name..". Reset vassalage with: "..facInferior.name)
                local resetTitle = "Vassalage cancelled for: "..facSuperior.localizedName
                local resetBody = "\n\n  By decree of the realm, all vassals of "..facSuperior.localizedName..", are hereby released from their sworn duties. Their oaths are dissolved, their service honored, and their bonds severed. Let them depart in peace, with no dishonor upon their names.. "
                M2TW.campaign.historicEvent("VASSALAGE_CANCELLED", resetTitle, resetBody, false)
            end 
        end
end 

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Eliminate the dead spouses
---------------------------------------------------------------------------------------------------------------------------------
--setting as heir the oldest son
---@param faction factionStruct
function module.removeDeadSpouses(faction)
       -- check if the wife of the leader died, if so, remove her from the tree - that allows the leader to marry again
        if faction.leader.spouse ~= nil and faction.leader.age < 50 and faction.leader.spouse.isAlive == false then
            log.debug("InternalA: Removing the dead wife/husband, spouse name is: "..faction.leader.spouse.fullName)
            local factions = {M2TW.campaign.currentFaction.name}
            local deadSpouseTitle = " Mourning for the dead spouse is over"
            local deadSpouseBody = "  After a season of lamentation for his dearly departed lady wife, "..faction.leader.spouse.localizedDisplayName..",  the noble ruler of the faction - "..faction.leader.localizedDisplayName.." is henceforth at liberty to seek anew the bonds of holy matrimony. Let it be known throughout the land that, having fulfilled the sacred duties of mourning, he may now pursue a union befitting his station, that the lineage and honor of his house may endure through the ages."
            M2TW.campaign.historicEvent("CIVIL_WAR_WARNING", deadSpouseTitle, deadSpouseBody, false,-1,-1,factions)
            faction.leader.spouse = nil
        end
        -- check if the wife of the heir died, if so, remove her from the tree - that allows the heir to marry again
        if faction.heir.spouse ~= nil and faction.heir.age < 50 and faction.heir.spouse.isAlive == false then
            log.debug("InternalA: Removing the dead wife/husband, spouse name is: "..faction.heir.spouse.fullName)
            local factions = {M2TW.campaign.currentFaction.name}
            local deadSpouseTitle = " Mourning for the dead spouse is over"
            local deadSpouseBody = "  After a season of lamentation for his dearly departed lady wife, "..faction.heir.spouse.localizedDisplayName..",  the noble heir of the faction - "..faction.heir.localizedDisplayName.." is henceforth at liberty to seek anew the bonds of holy matrimony. Let it be known throughout the land that, having fulfilled the sacred duties of mourning, he may now pursue a union befitting his station, that the lineage and honor of his house may endure through the ages."
            M2TW.campaign.historicEvent("CIVIL_WAR_WARNING", deadSpouseTitle, deadSpouseBody, false,-1,-1,factions)
            faction.heir.spouse = nil
        end
end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Fix Traits
---------------------------------------------------------------------------------------------------------------------------------
--[[
    ** Trait Factionleader
Level Faction_Leader1									; Claimant
   Threshold 1 
Level Faction_Leader2									; Heir Apparent
   Threshold 2 
Level Faction_Leader3									; Faction Leader
   Threshold 3 

]]
---@param faction factionStruct
local function fixFactionLeaderTraits(faction)
    -- remove the trait from other general
    -- give it to faction heir.
    for i=0, faction.numOfCharacters -1 do
        local ourCharacter = M2TW.campaign:getFaction(faction.name):getCharacter(i)
        local characterTraitLevel = ourCharacter.characterRecord:getTraitLevel("Factionleader")
        log.debug("InternalA: trait Heir Apparent for: "..ourCharacter.characterRecord.localizedDisplayName.." level is:"..characterTraitLevel )
        -- removes FactionLeader trait from characters that are not leaders nor heirs:
        if characterTraitLevel == 2 and ourCharacter.characterRecord:isHeir() == false and ourCharacter.characterRecord:isLeader() == false then
            ourCharacter.characterRecord:removeTrait("Factionleader")
            log.debug("InternalA: trait Heir Apparent Removed from: "..ourCharacter.characterRecord.localizedDisplayName)
        end
        -- changes FactionLeader trait, level 1 to level 3 for the leader:
        if characterTraitLevel == 1 and ourCharacter.characterRecord:isLeader() == true then
            ourCharacter.characterRecord:removeTrait("Factionleader")
            log.debug("InternalA: trait Claimant Removed from: "..ourCharacter.characterRecord.localizedDisplayName)
            ourCharacter.characterRecord:addTrait("Factionleader", 3)
        end
    end
    local factionHeir = faction.heir
    if not factionHeir then return end  -- faction heir sometimes may not be present
    if factionHeir:getTraitLevel("Factionleader") ~= 2 then
        factionHeir:addTrait("Factionleader", 2)
         log.debug("InternalA: trait Heir Apparent given to: "..factionHeir.localizedDisplayName)
    end
end
---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Set Heir
---------------------------------------------------------------------------------------------------------------------------------
--setting as heir the oldest son
---@param faction factionStruct
function module.setHeir(faction)
    if faction.isPlayerControlled ~= 1 or faction.leader == nil or faction.name == 'slave' or faction.factionRecord.hasFamilyTree == false then
        return 0
    end
    -- if faction leader is a regent do not change the heir:
    local regentTraitLevel = faction.leader:getTraitLevel('FactionRegent')
    if regentTraitLevel == 2 then
        log.debug("InternalA: faction leader is a regent - do not change the heir to his children : "..regentTraitLevel)
        return
    end
    -- children are numbered from 1 to 4 max
    for i = 1, faction.leader.numberOfChildren do
		local childFL
        -- first check if FH is a grandson of FL, its the case with England setting from descr_strat:
        -- parent is the father
        if faction.leader.children[i] ~= nil and faction.heir ~= nil and faction.heir.parent ~= nil and faction.heir.parent.spouse ~= nil then
			childFL = faction.leader.children[i]
            log.debug("InternalA: checking grandsons : "..faction.name..", F child considered: "..childFL.fullName)
            log.debug("InternalA: faction heir parent : "..faction.heir.parent.fullName)
            log.debug("InternalA: faction heir parents spouse : "..faction.heir.parent.spouse.fullName)
            log.debug("InternalA: faction heir piety : "..faction.heir.piety)
            if faction.heir.parent.fullName == childFL.fullName then
                -- this is true for England for example:
                log.debug("InternalA: the faction heir is FL grandson, his father is: "..faction.heir.parent.fullName.." no change")
                return
            end

            if faction.heir.parent.spouse.fullName == childFL.fullName then
                -- this is true for England for example:
                log.debug("InternalA: the faction heir is FL grandson, his mother is: "..faction.heir.parent.spouse.localizedDisplayName.." no change")
                return
            end
        end
    end
    for i = 1, faction.leader.numberOfChildren do
		local childFL
		if faction.leader.children[i] ~= nil then
			childFL = faction.leader.children[i]
			log.debug("InternalA: setHeir(faction) : "..faction.name..", F child considered: "..childFL.fullName)
            -- if the heir is already a son of the leader, return, no message and change
            if faction.heir ~= nil and childFL == faction.heir then return end
            -- if the heir is married to the leaders daughter, no message and change
            if childFL.isMale == false and childFL.isAlive and childFL.spouse == faction.heir then
                log.debug("InternalA: the faction heir is married to princess, no change of heir")
                --return
            elseif childFL.isMale == true and childFL.isAlive then
                -- the loop needs to go only after first son is found (will be the oldest)
                childFL:setAsHeir(true)
                local setHeirTitle = "A New Heir Chosen"
                local setHeirBody = "\n In the heart of the kingdom, a momentous occasion unfolded, one that would shape the fate of the realm for generations to come. The council of nobles convened to deliberate on the rightful heir to the throne— a decision steeped in tradition, lineage, and divine favor. \n "..faction.heir.localizedDisplayName.." is now publicly accepted as the new heir.\n\n GAME STRATEGY: If the heir's father (king) is dead, another noble will become Regent until the time young leader reaches maturity. It is very important that the regent have high CHIVALRY, PIETY and LOYALTY. These features will become crucial when the heir comes of age, as the regent will need to surrender his power. Viscious regent may cause a civil war and even assassinate the rightful heir. "
                M2TW.campaign.historicEvent("YOUNG_HEIR_CHOSEN", setHeirTitle, setHeirBody, false)




                return
            end
		end
    end
    fixFactionLeaderTraits(faction)
    log.debug("InternalA: The FL has no potential heir, no sons.")


end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Memorize Royals
---------------------------------------------------------------------------------------------------------------------------------
-- record the current FL and FH, prepare for the recalculation - changing the heir and leader
---@param faction factionStruct
---@return integer
function module.memorizeRoyals(faction)

    if faction.name == 'slave' or faction.isPlayerControlled ~= 1  or faction.heir == nil or faction.leader == nil then
        return 0
    end
    log.debug("InternalA: ------------ Memorizing FH & FL-----------------")
    formerHeir = faction.heir
    formerLeader = faction.leader  -- its characterRecord
    if formerLeader.character == nil then
        log.debug("InternalA: Memorizing entered, but character underage (only has 'characterRecord') - return.")
        throneSwitchReady = 0
        return 0
    else
        log.debug("InternalA: the former FL marked for death value:"..tostring(formerLeader.character.markedForDeath))
    end
    -- 'marked for death' is used to check if the leader really died or was changed recently.
    -- if he didn't die, the script could enter eternal loop of changing the FL
    -- this condition makes sure the recalculation will happen only once
    if formerLeader.character.markedForDeath == false then
        log.debug("InternalA: Memorizing entered, but character didnt die - return.")
        throneSwitchReady = 0
        return 0
    elseif  formerLeader.character.markedForDeath == true then
        log.debug("InternalA: Memorizing entered, character is markedForDeath - the recalculation may follow")
        log.debug("InternalA: faction: "..faction.name..", former, memorized FH: "..formerHeir.fullName)
        log.debug("InternalA: faction: "..faction.name..", former, memorized FL: "..formerLeader.fullName)
        throneSwitchReady = 1
    end
   return 1
  end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Recalculation FL Died
---------------------------------------------------------------------------------------------------------------------------------
---@param faction factionStruct
function module.recalculationFLDied(faction)
    -- When king dies the order of events is this:
    -- onCeasedFactionLeader - here it needs to be memorized who is former FL and FH
    -- onBecomesFactionLeader
    -- onCeasedFactionHeir
    -- onBecomesFactionHeir
    -- the recalculation has to be started onBecomesFactionHeir, when the cycle is closed

    if faction.name == 'slave' or faction.isPlayerControlled ~= 1  or faction.heir == nil or faction.leader == nil then
        return
    end
    log.debug("InternalA: throne switch ready: "..throneSwitchReady)
    if throneSwitchReady == 0 then
        return
    elseif throneSwitchReady == 1 then
        log.debug("InternalA: ------------ Recalculating -> FL Died  -----------------")
        throneSwitchReady = 0
        newLeader = faction.leader
        newHeir = faction.heir
        -- if new leader is underage doesnt have the character, only characterRecord!
        if newLeader.character ~= nil then
            log.debug("InternalA: new leader is an adult, characterRecord is ~= nil")
        end
        -- new heir is the heir chosen by the engine after the death of the leader
        -- switch heir <-> leader
        if formerHeir.isChild == true then
            faction:setLeader(newHeir, true)
            newLeader:setAsHeir(true)
            log.debug("InternalA: the switch of leader and heir is done.")
            log.debug("InternalA: faction: "..faction.name..", NEW LEADER set in script: "..faction.leader.fullName)
            log.debug("InternalA: faction: "..faction.name..", NEW HEIR set inn script: "..faction.heir.fullName)
 
        end
        -- determining regency(FactionRegent 1 and 2 points - doesnt change the trait name):
        if faction.heir.isChild == true then
            log.debug("InternalA: the new heir is a child")
            if faction.heir.parent ~= nil and faction.heir.parent == faction.leader then
                log.debug("InternalA: the new leader is the heir's father, no regent trait given")
            else
                faction.leader:addTraitPoints("FactionRegent",2)
                log.debug("InternalA: the new leader received FactionRegent trait")
            end
        else
            log.debug("InternalA: the new heir is an adult - no regent")
        end
    end
    fixFactionLeaderTraits(faction)
-- add turmoil when FL dies:
    helpers.adjustTurmoil(faction, 3)
end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Recal. FH came of age
---------------------------------------------------------------------------------------------------------------------------------
---@param faction factionStruct
function module.recalculationFHofAge(faction)
    local regentSurrenderPts
    local surrenderProb
    -- the function make new heir the new faction leader. The former leader - regent is a new heir until a son
    -- will be born of a new leader
    -- if the regent has a low chivalry and piety - civil war
    if faction.name == 'slave' or faction.isPlayerControlled ~= 1  or faction.heir == nil or faction.leader == nil then
        return
    end
    local regentTraitLevel = faction.leader:getTraitLevel('FactionRegent')
    log.debug("InternalA: ------------ Faction Heir Came of Age  -----------------")
    log.debug("InternalA: Faction Leader Regent value: "..regentTraitLevel)
    if regentTraitLevel <= 0 then  -- there is no regent
         return
    end
    newLeader = faction.leader
    newHeir = faction.heir
    -- higher values lower chance of civil war, the max is 30
    regentSurrenderPts = faction.leader.chivalryAndDread + faction.leader.piety + faction.leader.loyalty
    -- the probability 0 to 10, the higher value, smaller chance of civil wars.
    -- if loyalty + piety + chivalry is higher then 20 -> zero chance of civil war
    surrenderProb = helpers.randomNumber(0,20)
    log.debug("InternalA: regentSurrenderPts: "..regentSurrenderPts)
    log.debug("InternalA: surrenderProb: "..surrenderProb)
    if regentSurrenderPts  < surrenderProb then
        if regentSurrenderPts < 6 then
            module.civilWarRise(faction,20,'vicious regent')
            faction.leader:removeTrait("FactionRegent")
            faction.heir.character:kill()
        else
            faction.leader:removeTrait("FactionRegent")
            module.civilWarRise(faction,0,'regent')
        end

    else
        local regentSurrenderTitle = "The Regent Peacefully Surrenders"
        local regentSurrenderBody = "\n "..faction.leader.localizedDisplayName..", a knight of noble birth and unmatched prowess in battle, bore the heavy mantle of regency with a heart both noble and troubled. For years, he steered the kingdom through tempestuous waters, quelling rebellions and restoring peace among the fractious lords. Yet, as the seasons turned and the moon waxed and waned, a shadow loomed over his heart—a whisper that echoed through the halls of his mind... \n However, when the rightful heir came of age, the Regent surrendered his power willingly, not as one defeated but as one who understood that true leadership lies not in dominion but in service to one's people. Together with the former heir they forged a bond—one of respect and unity—that would guide the kingdom into an era marked by peace and prosperity."
        M2TW.campaign.historicEvent("An heir came of age", regentSurrenderTitle, regentSurrenderBody, false)
        faction.leader:removeTrait("FactionRegent")
        faction:setLeader(newHeir, true)
        newLeader:setAsHeir(true)
        fixFactionLeaderTraits(faction)
    end

end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Usurper
---------------------------------------------------------------------------------------------------------------------------------
-- if FL has low authority, or the average of generals have low chivalry and piety then usurper may appear.
-- There is a probablility every turn that usurper appears. If he jumps to the 3rd degree, which means he gets more and more
-- power, then civil war starts. The current king is killed and the usurper becomes a new king, or if FL gained enough authority
-- the usurper is killed.

local lowestKingsAuthority = 5 -- if King's authority is below this, the usurpeer may appear
local usurperAppearChance = 33 -- determines how often will usurper appear, probability 0-100

---@param character character
local function calcFaithfulness(character)
        local loyaltyChar = character.characterRecord.loyalty
        local chivalryChar = character.characterRecord.chivalryAndDread
        local pietyChar = character.characterRecord.piety
        local faithfulnessValue = loyaltyChar + chivalryChar + pietyChar
        return faithfulnessValue
end

---@param character character
local function usurpEventText(character)
    return '\n Because your Facton Leader has low authority an usurper appeared in your court: '..character.characterRecord.localizedDisplayName..'. From now on you will have to pay close attention to him, so that the begining of the conspiracy doesnt evolve into a civil war in your kingdom. Important is also to take care of your Faction Leader authority.'
end
local function usurpIncreaseInfluence(character)
    return "\n Your Faction Leader's authority grows weak, and the usurper "..character.characterRecord.localizedDisplayName.." is gaining influence. Your leader should remain in the capital, and it would serve him well to win several battles (especially a heroic victory would prove most helpful). Make certain also that he bears not the officemonger trait. It is of great importance that the heir gains influence and prestige in victorious battles and crusades, so that when he becomes the leader, he shall be able to inspire obedience and command respect."
end
local function usurpLastChance(character)
    return "\n Your Faction Leader's authority grows weak, and the usurper "..character.characterRecord.localizedDisplayName.." now stands as a true contender for the throne. The situation is grave indeed, and only through the pretender's demise—be it by mysterious circumstances or death in battle—can civil war be averted."
end
---@param faction factionStruct
function module.usurperCalculation(faction)
    -- check if there is an usurper already in the faction
    -- if so - he is the one, no need to loop through generals
    -- check the FL authority and generals piety:

    local usurperFound = false
    local usurperCharacter
    local currentCharacter
    local KingAuthority = faction.leader.authority
    local validCharacterList ={}
    local factionName = faction.name

    -- if the usurper is a FL or FH usurper trait should be removed
    local usurperLeaderLevel
    local usurperHeirLevel
    if faction.leader then usurperLeaderLevel = faction.leader:getTraitLevel('Usurper') end
    if faction.heir then usurperHeirLevel = faction.heir:getTraitLevel('Usurper') end
    if usurperLeaderLevel > 0  then
        faction.leader:removeTrait("Usurper")
        log.debug("Usurper: Usurper level removed, FL: ")
    elseif faction.factionRecord.hasFamilyTree == true and usurperHeirLevel > 0 then
        faction.heir:removeTrait("Usurper")
        log.debug("Usurper: Usurper level removed, FH: ")
    end

    if KingAuthority >= lowestKingsAuthority then return end

    log.info("Usurper: --------------- Finding potential usurper, the faction considered: "..factionName)

    -- FIRST STEP- FIND THE ONE LOWEST FAITHFULNESS TO THE KING
    -- create a list of valid characters, not heirs, not leaders, and only 'named characters'
    for i=0, faction.numOfCharacters -1 do
        currentCharacter = M2TW.campaign:getFaction(factionName):getCharacter(i)
        -- maybe there already is an usurper, so finish
        if currentCharacter.characterRecord:getTraitLevel('Usurper') > 0 then
            usurperFound = true
            usurperCharacter = currentCharacter
            log.debug("Usurper: usurper found, exisiting already: "..usurperCharacter.characterRecord.localizedDisplayName)
            break
        end
        local isLeader = currentCharacter.characterRecord:isLeader()
        local isHeir = currentCharacter.characterRecord:isHeir()
        local ourType = currentCharacter:getTypeName();
        if isLeader == true or isHeir == true or ourType ~= 'named_character' then
            log.debug("Usurper: skiped char, index: "..i..", isLeader:"..tostring(isLeader)..", isHeir: "..tostring(isHeir).." or its type is: "..currentCharacter.characterType)
        else
            table.insert(validCharacterList,currentCharacter)
            log.debug("Usurper: valid character inserted: "..currentCharacter.characterRecord.localizedDisplayName)
        end
    end
    -- just print the list to check:
    for k=1, #validCharacterList do
        log.info("Usurper: print valid characters list index: "..k.." character: "..validCharacterList[k].characterRecord.localizedDisplayName.." faithfullness value for character is: "..calcFaithfulness(validCharacterList[k]))
    end
    local i=1
    -- bubble sorting to find the character with minimal faithfullness
    if not validCharacterList[1] and usurperFound == false then log.debug("Usurper: no potential usurper, return.") return end
    local minFaithfullnessCharacter = validCharacterList[1]

    while usurperFound == false and validCharacterList[i+1]~= nil do
        currentCharacter = M2TW.campaign:getFaction(factionName):getCharacter(i)
        -- skip characters that are not named character, heir or leader
        local minFaithValue2 = calcFaithfulness(validCharacterList[i+1])
        if calcFaithfulness(minFaithfullnessCharacter) > minFaithValue2 then minFaithfullnessCharacter = validCharacterList[i+1] end
        i=i+1
    end

    if not usurperFound then log.debug("Usurper: general with minimal faithfulness is: "..minFaithfullnessCharacter.characterRecord.localizedDisplayName) end

 -- SECOND STEP- EITHER ASSIGN AN USURPER TRAIT OR INCREASE/REMOVE THE USURPER LEVEL
    local hitChance = helpers.randomNumber(0,100)
    if KingAuthority < lowestKingsAuthority and usurperFound == false and hitChance < usurperAppearChance then
            -- give usurper title to the lowest faithfullnes general:
            minFaithfullnessCharacter.characterRecord:addTrait("Usurper", 1)
            log.debug("Usurper: Potential usurper found became an actual usurper: "..minFaithfullnessCharacter.characterRecord.localizedDisplayName)
            local recipients  = {factionName}
		    M2TW.campaign.historicEvent("Usurper: Usurper appeared", "Usurper appeared", usurpEventText(minFaithfullnessCharacter), false,-1,-1,recipients)
    elseif KingAuthority < lowestKingsAuthority and usurperFound == true and hitChance < usurperAppearChance then
            -- raise the usurper level
            usurperCharacter.characterRecord:addTraitPoints("Usurper", 1)
            local levelUsurper = usurperCharacter.characterRecord:getTraitLevel("Usurper")
            if levelUsurper < 4 then 
                local recipients  = {factionName}
                M2TW.campaign.historicEvent("Usurper: Usurper stronger", "Warning ! The usurper is gaining influence", usurpIncreaseInfluence(usurperCharacter), false,-1,-1,recipients)
                log.debug("Usurper: Usurper level raised: "..usurperCharacter.characterRecord.localizedDisplayName.." usurper level: "..levelUsurper)
            elseif levelUsurper == 4 then
                local recipients  = {factionName}
                M2TW.campaign.historicEvent("Usurper: Usurper stronger", "Last Warning ! The civil war is imminent", usurpLastChance(usurperCharacter), false,-1,-1,recipients)
                log.debug("Usurper: Usurper level high: "..usurperCharacter.characterRecord.localizedDisplayName.." usurper level: "..levelUsurper)
            elseif levelUsurper > 4 then
                usurperCharacter.characterRecord:removeTrait("Usurper")
                log.debug("Usurper: Usurper trait removed, civil war starting.")
                module.civilWarRise(faction, 0, 'usurper')
            end
            -- if king's authority is above lowestKingsAuthority there should be a reverse process - a chance to loose the usurper trait
    elseif KingAuthority > lowestKingsAuthority and usurperFound == true and hitChance < usurperAppearChance then
            usurperCharacter.characterRecord:removeTrait("Usurper")
            log.debug("Usurper: Usurper trait removed, kings authority is good.")
    end

end

return module

--[[
from export_vnvs:

{Faction_Regent1_desc}The current king has failed to raise a son, and as a result,
this man will become regent of the realm when the current king passes onto the next world.
{Faction_Regent1_effects_desc}+2 to personal security (improves the chances of foiling assassination attempts)
{Faction_Regent1}Heir Presumptive
{Faction_Regent2_desc}This man acts as regent, while the true heirs of the faction are raised and educated.
If the previous royal line has been extinguished, the regent's son will be recognised as the next legitimate ruler.
{Faction_Regent2_effects_desc}+3 to personal security (improves the chances of foiling assassination attempts)
{Faction_Regent2}Regent

{Usurper1_desc}This man is not happy with the current political situation and his exclusion from the leadership.
 He is moving to overthrow the ruling family.
{Usurper1_effects_desc}-2 Loyalty, -1 Morale for all troops on the battlefield, 5% malus on tax income, +3 Authority
 (more likely to become the next heir)
{Usurper1}Conspirator
{Usurper2_desc}Whoever the true heir is, this man can and will seize their throne for himself upon the current leader's demise.
{Usurper2_effects_desc}+1 Loyalty, -1 Morale for all troops on the battlefield, 5% malus on tax income,
will cause a civil war upon accession to the throne
{Usurper2}Heir Effective
{Usurper3_desc}This man has crowned himself ruler, in defiance of the lawful succession and general sentiment.
{Usurper3_effects_desc}-2 Morale for all troops on the battlefield, 10% malus on tax income
{Usurper3}Usurper
{Usurper4_desc}This man has crowned himself ruler, in defiance of the lawful succession and general sentiment.
{Usurper4_effects_desc}-1 Morale for all troops on the battlefield, 5% malus on tax income, +1 Dread
{Usurper4_epithet_desc}the Usurper
{Usurper4}Usurper
{Usurper5_desc}This man has crowned himself ruler, in defiance of the lawful succession, though it seems not to matter.
{Usurper5_effects_desc}+1 Morale for all troops on the battlefield, +2 Dread
{Usurper5}Usurper
{Usurper_Opponent1_desc}Honour has made this man an outspoken opponent of the usurper – he outright refuses to obey their orders.
{Usurper_Opponent1_effects_desc}-6 Loyalty, -90% movement points
{Usurper_Opponent1}Despises Usurper
{Usurper_Opponent2_desc}This man has serious misgivings about the legitimacy of the current ruler, and goes out of his way to fail in the execution of their orders.
{Usurper_Opponent2_effects_desc}-4 Loyalty, -60% movement points, -1 from personal security (decreases the chances of foiling assassination attempts)
{Usurper_Opponent2}Undermines Usurper
{Usurper_Opponent3_desc}In this man's eyes, the current ruler is a usurper who ought be opposed when possible. In keeping with this, he makes things more difficult than they need to be for the regime.
{Usurper_Opponent3_effects_desc}-3 Loyalty, -40% movement points, -2 from personal security (decreases the chances of foiling assassination attempts)
{Usurper_Opponent3}Opposes Usurper
{Usurper_Opponent4_desc}Unenthusiastic as he may be about the current ruler and the means by which they came to power, this man has few means to oppose him – and fewer hiding places.
{Usurper_Opponent4_effects_desc}-2 Loyalty, -20% movement points, -3 from personal security (decreases the chances of foiling assassination attempts)
{Usurper_Opponent4}Dislikes Usurper



Religions ID:
    catholic - 0
	orthodox - 1
	islam - 2
	pagan - 3
	heretic - 4



IN CAMPAIGN_SCRIPT IT WORKS AS FOLLOWS:

; ---------- (III) START CIVIL WAR if FL is Usurper --------------------------------------------------------
		; if there's Usurper on the throne, and no civil war yet, then income goes down and rebel armies are spawned.
		; it seems that nested form of if-claused (as below) is less prone to crashes than not-nested.
		log ------ test factions for civil war conditions
		if I_FactionLeaderTrait spain Usurper > 2
			and I_EventCounter civil_war_spain_going_on = 0
			and RandomPercent < 50
			and not I_IsFactionAIControlled spain

			set_event_counter civil_war_spain_going_on 1
			set_event_counter civil_war_player_going_on 1
			historic_event civil_war_spain
			increment_kings_purse spain -1000


			if I_NumberOfSettlements spain > 2
				log ------ emerge slave from spain
				faction_emerge slave spain 1 100.0 0.0 1.2 town true


	; It works as follows:
	; the "resistance" counter goes from 0 to 25 and again
	; if in any faction the FactionLeader is a Usurper then there's 50% chance that a Civil War starts and depending on the size of the faction 1 to 5 armies are spawned
	; (safety valve: if for any reason the FL doesn't have the Usurper trait anymore (eg he died and a new FL comes), then end the civil war)
	; when the counter equals a number for a faction (eg. Spain = 1) then remove trait Usurper from the FL and end Civil War



		; ---------- (IV) Safety Valve: end Civil War immediately if FL has lost the Usurper trait (for whatever reason)
		log ------ check if Leader has lost Usurper

		if I_EventCounter civil_war_spain_going_on = 1
			if I_FactionLeaderTrait spain Usurper < 3

				historic_event end_civil_war_spain
				increment_kings_purse spain 1000
				set_event_counter civil_war_spain_going_on 0
				set_event_counter civil_war_player_going_on 0

			end_if
		end_if

		; ---------- (V) End Civil War after Period of Resistance ----------------------------
		; (if it's the lucky number (resistance) for a faction, then end civil war and get rid of the Usurper trait (the trigger reacting to "new_house_spain" is in EDCT)
		log ------ end civil wars after some time

		if I_EventCounter resistance == 1
			if I_EventCounter civil_war_spain_going_on = 1

				if I_FactionLeaderTrait spain Usurper > 2
					set_event_counter new_house_spain 1
				end_if

				historic_event end_civil_war_spain
				increment_kings_purse spain 1000
				set_event_counter civil_war_spain_going_on 0
				set_event_counter civil_war_player_going_on 0
			end_if
		end_if

		if I_EventCounter resistance == 2
			if I_EventCounter civil_war_france_going_on = 1




deathType
Enum with a character death types.

alive int
diedNatural int
diedInDisaster int
diedInBattle int
assassinated int
executed int
executedPrisoner int
poisoned int
plague int
starvation int
captainRemoval int
removedForRetraining int
incompatibleFaction int
bribed int
disbanded int
sunk int
married int
acquired int
retired int
disgraced int
denounced int


    ]]