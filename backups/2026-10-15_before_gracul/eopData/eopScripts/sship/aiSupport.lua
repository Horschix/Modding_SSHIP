local log = LOG.new()
log.level = LOG_LEVELS.aiSupport

local helpers = require('sship.helpers')

local module = {
	_DESCRIPTION = 'manages all scripts aiming to help or balance AI'
}

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---MARK: parameters
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---How long to wait before destroying AI-blocking buildings
local turnsBeforeDestruction = 10

--- table to store buildings to be destroyed depending on faction
--- table | string either 'all' or a set containing the internal name for each faction that have to destroy the building chain
--- Value can also contain a second key/value pair, giving a threshold in absolute turn numbers under which buildind will not be destroyed
---@type table<string, string|table>
local toBeDestroyed = {
	['autonomy'] = 'all',
	['food_supply'] = 'all',
	['justice_city'] = 'all',
	['justice_castle'] ='all',
	['siege'] = 'all',
	['castle_siege'] = 'all',
	['grasslands'] = {exlude = helpers.listToSet({'mongols', 'cumans',}), turnThreshold = 60,},
	['chude_building'] = {exlude = helpers.listToSet({'mongols', 'cumans',}), turnThreshold = 160,},
	['temple_perkunas'] = {include = helpers.listToSet({'mongols', 'cumans',})},
	['temple_dievas'] = {include = helpers.listToSet({'mongols', 'cumans',})},
	['temple_giltine'] = {include = helpers.listToSet({'mongols', 'cumans',})},
}

--- Stores settlements thresholds for changeAILabel()
---@type table<string, integer>
local settlementsThreshold = {
	['france'] = 9,
	['aragon'] = 9,
	['jerusalem'] = 8,
	['georgia'] = 8,
	['hre'] = 7,
	['venice'] = 7,
	['pisa'] = 7,
	['sicily'] = 7,
	['abbasid'] = 7,
	['zengid'] = 7,
	['spain'] = 7,
	['rum'] = 6,
	['egypt'] = 6,
	['turks'] = 5,
	['byzantium'] = 5,
	['moors'] = 5,
}

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---MARK: functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---destroy buildings that AI cannot manage well or that block other building lines
---@param settStruct settlementStruct
function module.destroySpecialBuildings(settStruct)
	if settStruct.turnsOwned < turnsBeforeDestruction then
		log.debug('settlement conquest is too recent ('..settStruct.turnsOwned..' ago), not destroying special buildings')
		return
	end
	if settStruct.ownerFaction.isPlayerControlled == 1 then 
		log.debug('settlement owned by the player, not destroying special buildings')
		return
	end
	log.debug('looping through every building in '..helpers.logSettlement(settStruct)..' to seek those to destroy')
	local factionName = settStruct.ownerFaction.name
	for i =  settStruct.buildingsNum - 1, 0, -1 do
		local tree = settStruct:getBuilding(i):getType()
		if toBeDestroyed[tree] ~= nil then
		log.trace('\t\tbuilding eligible for destruction : '..tree)
			if toBeDestroyed[tree].turnThreshold == nil or toBeDestroyed[tree].turnThreshold < M2TW.campaign.turnNumber then
				if toBeDestroyed[tree] == 'all' then
					settStruct:destroyBuilding(tree, false)
					log.debug('\tbuilding destroyed')
				elseif toBeDestroyed[tree].exlude ~= nil and toBeDestroyed[tree].exlude[factionName] == nil then
					settStruct:destroyBuilding(tree, false)
					log.debug('\tbuilding destroyed')
				elseif toBeDestroyed[tree].include ~= nil and toBeDestroyed[tree].include[factionName] then
					settStruct:destroyBuilding(tree, false)
					log.debug('\tbuilding destroyed')
				end
			end
		end
	end
end

--- changes neighbouring AIs labels depending on number of settlements owned by player
---@param faction factionStruct
function module.changeAILabel(faction)
	--- guard clauses
	-- should be removed, but for the WIP on campaign ai, its all the same 
	for i = 0, M2TW.campaign.numberOfFactions - 1 do
		local otherFaction  = M2TW.campaign:getFactionByOrder(i)
		local name = otherFaction.name
		if name ~= 'slave' and name ~= 'mongols' and name ~= 'papal_states' and otherFaction.isPlayerControlled == 0 then
			M2TWEOP.scriptCommand('link_faction_ai', name..' default')
		end
	end
	-- until here to be removed
	if M2TWEOP:getOptions2().campaignDifficulty ~= 3 then
		log.debug('exit changeAILabel : the game is not played on Very Hard difficulty')
		return
	end
	if settlementsThreshold == nil then
		log.info('settlementsThreshold table doesnt exist')
		return
	end
	if settlementsThreshold[faction.name] == nil then
		log.info('exit changeAILabel() : '..helpers.logFaction(faction)..' is not eligible')
		return
	end
	--- main code
	local campaign = M2TW.campaign
	for i = 0, campaign.numberOfFactions - 1 do
		local otherFaction  = campaign:getFactionByOrder(i)
		local name = otherFaction.name
		if settlementsThreshold[faction.name] ~= nil and faction:isNeighbourFaction(otherFaction) then
			if otherFaction ~= nil and settlementsThreshold[otherFaction.name] ~= nil then

				-- some factions should not have their labl changed
				if name ~= 'slave' and name ~= 'mongols' and name ~= 'papal_states' then
					log.debug('testing faction: '..name..' current AI label: '..otherFaction.ai_label)
					-- settlementsThreshold[otherFaction.name] is nil, why ?
					
					if otherFaction.settlementsNum > settlementsThreshold[otherFaction.name] and otherFaction.ai_label ~= 'difficult' then
						log.info('switching faction '..name..' ai label to "difficult"')
						M2TWEOP.scriptCommand('link_faction_ai', name..' difficult')
					elseif otherFaction.settlementsNum < (settlementsThreshold[otherFaction.name] + 1) and otherFaction.ai_label ~= 'default' then
						log.info('switching faction '..name..' ai label to "default"')
						M2TWEOP.scriptCommand('link_faction_ai', name..' default')
					end
					log.debug(otherFaction.ai_label)
					
				else log.error('changeAILabel() encountered a nil faction when looping over neighbouring regions owners')
				end
			end
		end
		
	end
end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: siegesTables 
---------------------------------------------------------------------------------------------------------------------------------

 
local armyTable= {			
rum = {          
				"Fari Horse Archers",		
				"Fari Horse Archers",		
				"Fari Lancers",	
				"Fari Lancers",	
				"Dismounted Fari Archers",	
				"Dismounted Fari Archers",		
				"Turkish Archers",		
				"Turkish Archers",	
				"Turkish Javelinmen",	
				"Turkish Javelinmen",
				"Ahdath Militia",		
				"Ahdath Militia",	
				"Dismounted Fari Lancers",	
				"Dismounted Fari Lancers",
},
france = {          
				"Spear Militia",
				"Spear Militia",
				"Spear Militia",
				"Dismounted Mailed Knights",
				"Dismounted Mailed Knights",
				"Dismounted Mailed Knights",
				"Mailed Knights",
				"Mailed Knights",
				"Prussian Archers",
				"Prussian Archers",
				"Mercenary Spearmen",
				"Mercenary Spearmen",
				"Mounted Sergeants",
				"Mounted Sergeants",
				"Mounted Sergeants",
				
},
georgia = {          
				"georgian light spearmen",
				"georgian light spearmen",
				"georgian light spearmen",
				"georgian dismounted heavy horse archers",
				"georgian dismounted heavy horse archers",
				"georgian mandaturi",
				"georgian mandaturi",
				"georgian medium spearmen",
				"georgian medium spearmen",
				"georgian medium lancers",
				"georgian medium lancers",
				"georgian medium lancers",
				"georgian heavy lancers",
				"georgian heavy lancers",
				"georgian dismounted heavy lancers",
				
},
pisa = {          
				"Urban Spear Militia",
				"Urban Spear Militia",
				"Urban Spear Militia",
				"Dismounted Mailed Knights",
				"Dismounted Mailed Knights",
				"Mailed Knights",
				"Prussian Archers",
				"Prussian Archers",
				"Mercenary Spearmen",
				"Mercenary Spearmen",
				"Mounted Sergeants",
		
},
sicily = {          
				"Urban Spear Militia",
				"Urban Spear Militia",
				"Urban Spear Militia",
				"Norman Serjeants",
				"Norman Serjeants",
				"Norman Serjeants",
				"Norman Knights",
				"Norman Knights",
				"Mercenary Spearmen",
				"Dismounted Norman Cavalry",
				"Mounted Sergeants",
				"Mercenary Spearmen",
				"Dismounted Norman Cavalry",
				"Mounted Sergeants",
		
},
norway = {          
				"Landevearnmenn",
				"Landevearnmenn",
				"Landevearnmenn",
				"Norse Axemen",
				"Norse Axemen",
				"Norse Axemen",
				"Norse Axemen",
				"Norse Swordsmen",
				"Norse Swordsmen",
				"Norse Swordsmen",
				"Mercenary Spearmen",
				"Norse Archers",
				"Norse Archers",
				"Mounted Sergeants",
				"Mounted Sergeants",
				
},
england = {          
				"Fyrd Spearmen",
				"Fyrd Spearmen",
				"Norman Cavalry",
				"Norman Cavalry",
				"Norman Cavalry",
				"Dismounted Norman Cavalry",
				"Dismounted Norman Cavalry",
				"Hunters",
				"Hunters",
				"Norman Serjeants",
				"Norman Serjeants",
				"Hunters",
				"Hunters",
				"Hunters",
				
},
}


---------------------------------------------------------------------------------------------------------------------------------
-- MARK: campaignAI 
---------------------------------------------------------------------------------------------------------------------------------
--[[
This is all eop ai does (Fynn 2/6/2025 12:27 m)
if you want a basic simplified breakdown of what my ai does its just:
  1. for each character it gets the movement extents (within 1 turn or multiple) and saves every settlement/character in range
  2. then for each settlement/character it checks all the other characters that can reach it
  3. then it creates orders to attack/defend this character/settlement based on the total strength of ppl that can reach it
  4. it prioritizes these orders based on stuff like strength balance, distance etc
  5. then it checks for each order in order of priority if it can be executed succesfully and if it can then 
	it executes it by moving pplin position and possibly attacking
  6. once all the orders are completed it checks everyone if it has anyone left within their movement 
  	range to merge with and merges them, also armies that are standing in the open which are in range of threats
  	that outpower them are ordered to move to closest safety if possible
its more micro level / tactical not grand strategy, if a character is at a far place there 
is nothing stopping him from attacking enemy stuff.
]]
function module.printEopAiConfig(config)
    log.info("CampaignAI: eopAiConfig - turn number: "..M2TW.campaign.turnNumber)
    log.info("===========")
    log.info(string.format("%-25s %s", "enabled",             tostring(config.enabled)))
    log.info(string.format("%-25s %s", "enableLogging",       tostring(config.enableLogging)))
    log.info(string.format("%-25s %s", "aggressionFactor",    tostring(config.aggressionFactor)))
    log.info(string.format("%-25s %s", "defenseFactor",       tostring(config.defenseFactor)))
    log.info(string.format("%-25s %s", "residenceFactor",     tostring(config.residenceFactor)))
    log.info(string.format("%-25s %s", "aidFactor",           tostring(config.aidFactor)))
    log.info(string.format("%-25s %s", "moveCostFactor",      tostring(config.moveCostFactor)))
    log.info(string.format("%-25s %s", "powerFactor",         tostring(config.powerFactor)))
    log.info(string.format("%-25s %s", "nonBorderFactor",     tostring(config.nonBorderFactor)))
    log.info(string.format("%-25s %s", "invadePriorityFactor",tostring(config.invadePriorityFactor)))
    log.info(string.format("%-25s %s", "maxTurnSearchCount",  tostring(config.maxTurnSearchCount)))
end

--- Should be set once every turn, or after each reloading of the game,
--- because if only set once - after reload gets unexpected values and ai becomes chaotic.
---@param faction factionStruct
function module.setFactors(faction)
	if not faction then log.debug('CampaignAI: setFactors entered with nil parameter, return') return end 
	log.debug("CampaignAI: faction: "..faction.name)
	-- nonBorderFactor fynn: 0 should not attack non bordering 
	-- but you can also just set it something low so they only do it if its really worth it
	local aiCfg = M2TWEOP.getEopAiConfig()

	-- To be set only once per turn, for all factions together:
	if faction.name == 'slave' then 
		if M2TW.campaign.turnNumber <= 3 then	-- ai signs peace?
			aiCfg.moveCostFactor = 2.0
			aiCfg.nonBorderFactor = 0
			aiCfg.enabled = false
			aiCfg.enableLogging = false
			aiCfg.defenseFactor = 1.2
			--aiCfg.aggressionFactor = 1.0
		elseif  M2TW.campaign.turnNumber > 3 then	--eop enabled = true, ai starts to behave differently
			aiCfg.moveCostFactor = 2.0
			aiCfg.nonBorderFactor = 0
			aiCfg.enabled = true
			aiCfg.enableLogging = false
			aiCfg.defenseFactor = 1.2
			--aiCfg.aggressionFactor = 1.0
		end 
	-- FACTIONS specific settings:	
	-- the city target settings seems to work in general for all the factions - cities become more important 
	-- Make Sicily focus on Corinth and Napoli
		local sicilyFac = M2TW.campaign:getFaction("sicily")
		local facData = aiCfg.getFactionData(sicilyFac)
		local corinth = M2TW.stratMap:getSettlement("Corinth")
		local naples = M2TW.stratMap:getSettlement("Naples")
		facData:setSettlementFactor(corinth, 3.0) 
		facData:setSettlementFactor(naples, 3.0)
	-- Denmark focus on Sigtuna:
		local denmarkFac = M2TW.campaign:getFaction("denmark")
		local sigtuna = M2TW.stratMap:getSettlement("Sigtuna")
		facData = aiCfg.getFactionData(denmarkFac)
		facData:setSettlementFactor(sigtuna, 4.0) 
	-- Novgorod focus on Polotsk:
		local russiaFac = M2TW.campaign:getFaction("russia")
		local polotsk = M2TW.stratMap:getSettlement("Polotsk")
		facData = aiCfg.getFactionData(russiaFac)
		facData:setSettlementFactor(polotsk, 4.0) 
	-- Cumans focus on Bolgar:
		local cumansFac = M2TW.campaign:getFaction("cumans")
		local bulgar = M2TW.stratMap:getSettlement("Bulgar")
		facData = aiCfg.getFactionData(cumansFac)
		facData:setSettlementFactor(bulgar, 4.0) 
	-- printed just once a turn
		module.printEopAiConfig(aiCfg)	
	else
	-- to be set for each faction separately:
		local facData = aiCfg.getFactionData(faction)
		local slaveFac = M2TW.campaign:getFaction("slave")
		if M2TW.campaign.turnNumber < 50 then
				facData:setTargetFactionFactor(slaveFac, 6.0)	-- this makes AI more decisive vs slave in the begining of the game
		elseif M2TW.campaign.turnNumber >= 50 then
				facData:setTargetFactionFactor(slaveFac, 1.0)	-- later in the game, don't focus on slaves too much
				--aiCfg.aggressionFactor = 5.0
		end
	end

end
---function to adjust the AI behaviour during the game, called every turn from onCalculateLTGD
---@param ltgd aiLongTermGoalDirector
function module.mainCampaignAI(ltgd)
local faction = ltgd.faction
local aiCfg = M2TWEOP.getEopAiConfig()
	for j = 0, M2TW.campaign.numberOfFactions -1 do
        local targetFaction = M2TW.campaign:getFactionByID(j)
		local ltgdValues = ltgd:getLongTermGoalValues(targetFaction.factionID)
		local invadePriority = ltgdValues.invadePriority
		log.info('CampaignAI:'.." LTGD "..faction.name.." => "..targetFaction.name.." invade priority: "..invadePriority.." turn: "..M2TW.campaign.turnNumber)
	end 

	if M2TW.campaign.turnNumber == 2 then
		
		local rumFac = M2TW.campaign:getFaction("rum")
		local byzFac = M2TW.campaign:getFaction("byzantium")
		if rumFac.isPlayerControlled == 0 and byzFac.isPlayerControlled == 0 then 
			M2TW.campaign:setDipStance(dipRelType.peace, byzFac, rumFac)
		end
	elseif M2TW.campaign.turnNumber >= 2 then

	end
end


---------------------------------------------------------------------------------------------------------------------------------
-- MARK: aiInitialSupport
---------------------------------------------------------------------------------------------------------------------------------

-- Helper function to get bodyguard type by culture ID
local function getBodyguardType(cultureID)
	if cultureID == M2TWEOP.getCultureID("middle_eastern") then
		return "ME Bodyguard"
	elseif cultureID == M2TWEOP.getCultureID("northern_european") then
		return "NE Bodyguard"
	elseif cultureID == M2TWEOP.getCultureID("southern_european") then
		return "SE Bodyguard"
	elseif cultureID == M2TWEOP.getCultureID("greek") then
		return "Greek Bodyguard"
	elseif cultureID == M2TWEOP.getCultureID("eastern_european") then
		return "EE Bodyguard"
	end
	return nil
end

---@param faction string
---@param x integer
---@param y integer
---@return armyStruct|nil spawnArmy
local function spawnArmy(faction, x, y)
	local spawnX, spawnY = M2TW.stratMap.findValidTileNearTile(x, y, characterType.named_character)
	local spawnFaction = M2TW.campaign:getFaction(faction)
	-- Get bodyguard type
	local bodyguardType = getBodyguardType(spawnFaction.cultureID)
	if not bodyguardType then return nil end
	-- Get army table from lookup
	local armyUnits = armyTable[spawnFaction.name]
	if not armyUnits then return nil end
	-- Spawn the army
	local spawnedArmy = spawnFaction:spawnArmy(
		"random_name", "", characterType.named_character, "", "",
		spawnX, spawnY, 43, true, 31,
		M2TWEOPDU.getEduIndexByType(bodyguardType), 3, 0, 0
	)
	if not spawnedArmy then return nil end
	helpers.giveRandomTraitsCharacter(spawnedArmy.leader)
	-- Create units 
	for i = 1, #armyUnits do
		local randomFactor = helpers.randomNumber(0, 6)
		if randomFactor < 5 then spawnedArmy:createUnit(armyUnits[i], randomFactor, 0, 0) end
	end
	return spawnedArmy
end

---@param conquerFaction string
---@param x integer
---@param y integer
---@param settlementName string
---@param attackImediate boolean
local function spawnAndSiege(conquerFaction, x, y, settlementName, attackImediate)

	local faction = M2TW.campaign:getFaction(conquerFaction)
	log.debug("aiInitialSupport: faction " .. conquerFaction .. " is not player controlled")
	local spawnX, spawnY = M2TW.stratMap.findValidTileNearTile(x, y, characterType.named_character)
	local spawnedArmy = spawnArmy(conquerFaction, spawnX, spawnY)
	if not spawnedArmy then return end
	log.debug("aiInitialSupport: Army spawned, faction:" .. spawnedArmy.faction.name .. 
	          ", leader: " .. spawnedArmy.leader.characterRecord.localizedDisplayName)
	local settlement = M2TW.stratMap:getSettlement(settlementName)
	if settlement.siegesNum == 0 and settlement.ownerFaction.name ~= conquerFaction then
		-- sometimes AI gives up the siege, so in some cases attackImediate needs to be true
		if attackImediate == true then 
			local hasOwnershipNE = (M2TWEOPDU.getEduEntryByType("NE Trebuchet")):hasOwnership(faction.factionID)
			local hasOwnershipME = (M2TWEOPDU.getEduEntryByType("ME Trebuchet")):hasOwnership(faction.factionID)
			if hasOwnershipNE then 
				local newUnit = spawnedArmy:createUnit("NE Trebuchet",1,1,1);
				local newUnit = spawnedArmy:createUnit("NE Trebuchet",1,1,1);
			elseif hasOwnershipME then
				local newUnit = spawnedArmy:createUnit("ME Trebuchet",1,1,1);
				local newUnit = spawnedArmy:createUnit("ME Trebuchet",1,1,1);
			end
		end
		spawnedArmy:siegeSettlement(settlement, attackImediate)	
		spawnedArmy.leader.movePoints = 0 
		spawnedArmy.leader.movePointsArmy = 0 
		spawnedArmy.leader.movePointsMaxArmy = 0 
		module.spawnedGeneral = spawnedArmy.leader
	end
	return spawnedArmy
end

---------------------------------------------------------------------------------------------------------------------------------
-- MARK: Scripted Sieges
---------------------------------------------------------------------------------------------------------------------------------

local aiScriptedSiegesData = {
    sicily = {
        turns = {},
        cities = {"Corinth", "Thessalonica", "Durazzo", "Arta"}
    },
    rum = {
        turns = {},
        cities = {"Constantinople", "Nicaea", "Attaleia", "Smyrna"}
    },
	norway = {
        turns = {},
        cities = {"Aberdeen", "Edinburgh"}
    },
	england = {
		turns = {},
        cities = {"Rouen", "Rennes","Ghent"}

	}
}
local maxTurnInvasion = 150	--default 200
local minTurnInvasion = 75	--default 50
local maxNumberOfInvasions = 8

-- INITIALIZATION OF RANDOM SIEGES
function module.initScriptedSieges()
    log.debug("ScriptedSieges: =============== initScriptedSieges ==================")
    for factionName, data in pairs(aiScriptedSiegesData) do
        log.debug("ScriptedSieges: initializing faction: " .. factionName)
        local numOfSieges = helpers.randomNumber(1, maxNumberOfInvasions)
        data.turns = {} -- clear before filling
        for i = 1, numOfSieges do
            local turnOfInvasion = helpers.randomNumber(minTurnInvasion, maxTurnInvasion)
            log.debug("ScriptedSieges: faction["..factionName.."] turn added: " .. turnOfInvasion)
            table.insert(data.turns, turnOfInvasion)
        end
    end
    -- SAVE for campaign
    SAVED_DATA.scriptedSieges = aiScriptedSiegesData
end



-- PRINT CONTENT 
function module.printScriptedSieges()
    local saved = SAVED_DATA.scriptedSieges
    if not saved then
        log.debug("ScriptedSieges: No saved data!")
        return
    end
    for faction, data in pairs(saved) do
        log.debug("ScriptedSieges: faction " .. faction.." turn now: "..M2TW.campaign.turnNumber)
        log.debug("ScriptedSieges: cities to attack:")
        for i = 1, #data.cities do
            log.debug("ScriptedSieges: - " .. data.cities[i])
        end
        log.debug("ScriptedSieges: planned turns:")
        for i = 1, #data.turns do
            log.debug("ScriptedSieges: - turn " .. data.turns[i])
        end
    end
end

-- PROCESS SIEGES FOR ONE FACTION
local function processFactionSieges(factionName)
	-- check for nil, failed initializing
    local saved = SAVED_DATA.scriptedSieges
    if not saved then return end
    local data = saved[factionName]
    if not data then return end

    log.debug("ScriptedSieges: processScriptedSieges for faction " .. factionName)

    for i = 1, #data.turns do
        if data.turns[i] == M2TW.campaign.turnNumber then
            log.debug("ScriptedSieges: turn matches planned attack: " .. data.turns[i])

            -- choose city, may be two or more armies attacking the same city the same turn 
            local randomCity = data.cities[helpers.randomNumber(1, #data.cities)]
            local settlement = M2TW.stratMap:getSettlement(randomCity)

            if settlement then
                local spawnX, spawnY = M2TW.stratMap.findValidTileNearTile(
                    settlement.xCoord,
                    settlement.yCoord,
                    characterType.named_character
                )
                local spawnArmy = spawnAndSiege(factionName, spawnX, spawnY, randomCity, true)
				local factionAttacked = settlement.ownerFaction
				if spawnArmy and factionAttacked.isPlayerControlled == 1 then
					local invasionTitle = "Sudden Attack! You have been invaded!"
					local invasionBody = "God have mercy! dire tidings reach us this day! Our sworn enemy "..string.upper(factionName).." has devised a most devious ploy to ambush our valiant forces! "..settlement.name.." was set upon without warning, attacked by a considerable force under cover of darkness. We shall answer this treachery with righteous fury!"
					M2TW.campaign.historicEvent("SCRIPTED_INVASION_INFO", invasionTitle, invasionBody, false,settlement.xCoord,settlement.yCoord,{factionAttacked})
				end
            else
                log.debug("ScriptedSieges: ERROR - settlement not found: " .. randomCity)
            end
        end
    end
end


---MAIN ENTRY: RUN AT EVERY FACTION TURN
---@param faction factionStruct
function module.aiInitialSupportSieges(faction)
    local currentTurn = M2TW.campaign.turnNumber
    -- Player factions never use this system
    if faction.isPlayerControlled == 1 then return end
	-- TURN 0: nothing happens
    -- TURN 1: initial scripted sieges & initialize random future sieges
    if currentTurn == 0 then

        if faction.name == "rum" then
            spawnAndSiege("rum", 332, 124, "Caesarea", true)
        elseif faction.name == "france" then
            spawnAndSiege("france", 97, 176, "Clermont", true)
        elseif faction.name == "georgia" then
            spawnAndSiege("georgia", 392, 136, "Ani", true)
        elseif faction.name == "pisa" then
            spawnAndSiege("pisa", 159, 158, "Florence", true)
        end
        -- Initialize siege plan only *once*, when SLAVE runs on turn 0
        if faction.name == "slave" then
            log.debug("ScriptedSieges: initializing scripted sieges...")
            module.initScriptedSieges()
        end
        return
    elseif currentTurn > 0 then
		-- TURNS > 1
		log.debug("ScriptedSieges: aiInitialSupportSieges, faction: "
			.. faction.name .. " turn: " .. currentTurn)
		if not SAVED_DATA.scriptedSieges then
			log.debug("ScriptedSieges: ERROR - siege table missing! Initialization failed?")
			return
		end
		-- process the faction that is current
		if SAVED_DATA.scriptedSieges[faction.name] then
			processFactionSieges(faction.name)
		end
	end
end


return module






---@LATER implement all this is AI still needs a hand after using EOP ai 
--[[
			for i = 1, #data.cities do
				log.debug("ScriptedSieges: "..data.cities[i])
			end
;======================================================================================================
;-------- Spawn of Armies at the Beginning
;
; Whan does it happen (engine quirk): between slave FactionTurnEnd and Player PreFactionTurnStart
;

monitor_event PreFactionTurnStart not IsFactionAIControlled
	log --- script start: Additional AI armies

	if I_IsFactionAIControlled england
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction england
				character	David Plantagenet, named character, age 20, x 83, y 214, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_English 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction england
				character	David Plantagenet, named character, age 30, x 76, y 189, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_English 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Scouts				exp 0 armour 0 weapon_lvl 0
				unit	Norman Serjeants	exp 7 armour 0 weapon_lvl 0
				unit	Norman Serjeants	exp 0 armour 0 weapon_lvl 0
				unit	Fyrd Spearmen		exp 4 armour 0 weapon_lvl 0
				unit	Fyrd Spearmen		exp 1 armour 0 weapon_lvl 0
				unit	Fyrd Spearmen		exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------------------------------------------------------------------------------ ENGLAND ARMY SPAWNED
	end_if

	if I_IsFactionAIControlled france
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction france
				character	Amaury Capet, named character, age 20, x 92, y 200, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_French 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction france
				character	Amaury Capet, named character, age 30, x 97, y 185, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_French 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Breton Light Cavalry	exp 0 armour 0 weapon_lvl 0					
				unit	Norman Serjeants	exp 7 armour 0 weapon_lvl 0
				unit	Norman Serjeants	exp 0 armour 0 weapon_lvl 0
				unit	Spear Militia		exp 7 armour 0 weapon_lvl 0
				unit	Spear Militia		exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------------------------------------------------------------------------------ FRANCE ARMY SPAWNED
	end_if

	if I_IsFactionAIControlled hre
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction hre
				character	Arnoldt von_Hohenstaufen, named character, age 20, x 144, y 204, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_HRE 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction hre
				character	Arnoldt von_Hohenstaufen, named character, age 30, x 124, y 212, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_HRE 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Scouts				exp 0 armour 0 weapon_lvl 0					
				unit	Sergeant Spearmen	exp 7 armour 0 weapon_lvl 0
				unit	Sergeant Spearmen	exp 4 armour 0 weapon_lvl 0
				unit	Sergeant Spearmen	exp 0 armour 0 weapon_lvl 0
				unit	Axe Militia			exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ hre army spawned
	end_if

	if I_IsFactionAIControlled spain
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction spain
				character	Enrique de_Castilla, named character, age 20, x 46, y 150, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Spanish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction spain
				character	Enrique de_Castilla, named character, age 30, x 47, y 136, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Spanish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Scouts				exp 0 armour 0 weapon_lvl 0					
				unit	Spear Militia		exp 1 armour 0 weapon_lvl 0
				unit	Spear Militia		exp 1 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ spain army spawned
	end_if

	if I_IsFactionAIControlled serbia
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction serbia
				character	Belos, named character, age 20, x 232, y 156, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Serbian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	EE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction serbia
				character	Belos, named character, age 30, x 232, y 156, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Serbian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	EE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Scouts				exp 0 armour 0 weapon_lvl 0					
				unit	Slav Levies			exp 7 armour 0 weapon_lvl 0
				unit	Slav Levies			exp 4 armour 0 weapon_lvl 0
				unit	Slav Levies			exp 1 armour 0 weapon_lvl 0
				unit	Slav Levies			exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ serbia army spawned
	end_if

	if I_IsFactionAIControlled venice
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction venice
				character	Barbus Selvo, named character, age 20, x 165, y 175, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Venetian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction venice
				character	Barbus Selvo, named character, age 30, x 165, y 175, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Venetian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard			exp 1 armour 1 weapon_lvl 0	
				unit	Italian Cavalry Militia	exp 4 armour 0 weapon_lvl 0
				unit	Urban Spear Militia		exp 7 armour 0 weapon_lvl 0
				unit	Urban Spear Militia		exp 1 armour 0 weapon_lvl 0
				unit	Urban Spear Militia		exp 0 armour 0 weapon_lvl 0
				unit	Urban Crossbow Militia	exp 1 armour 0 weapon_lvl 0
				unit	Urban Crossbow Militia	exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ venice army spawned
	end_if

	if I_IsFactionAIControlled sicily
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction sicily
				character	Ettore d_Altavilla, named character, age 20, x 170, y 119, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Sicilian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction sicily
				character	Ettore d_Altavilla, named character, age 30, x 196, y 138, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Sicilian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard			exp 1 armour 1 weapon_lvl 0
				unit	Scouts				exp 0 armour 0 weapon_lvl 0					
				unit	Norman Serjeants		exp 4 armour 0 weapon_lvl 0
				unit	Norman Serjeants		exp 1 armour 0 weapon_lvl 0
				unit	Urban Crossbow Militia	exp 4 armour 0 weapon_lvl 0
				unit	Urban Crossbow Militia	exp 1 armour 0 weapon_lvl 0
			end
		end_if
	log ------ sicily army spawned
	end_if

	if I_IsFactionAIControlled abbasid
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction abbasid
				character	random_name, named character, age 20, x 404, y 82, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Abbasid 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction abbasid
				character	random_name, named character, age 30, x 412, y 77, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Abbasid 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard				exp 2 armour 1 weapon_lvl 0
				unit	Turkomans					exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry		exp 4 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry		exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry		exp 0 armour 0 weapon_lvl 0
				unit	Kurdish Javelinmen			exp 0 armour 0 weapon_lvl 0
				unit	Dismounted Fari Archers		exp 4 armour 0 weapon_lvl 0
				unit	Dismounted Fari Archers		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ abbasid army spawned
	end_if

	if I_IsFactionAIControlled pisa
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction pisa
				character	Evio Visconti, named character, age 20, x 155, y 157, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Pisan 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction pisa
				character	Evio Visconti, named character, age 30, x 155, y 157, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Pisan 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard			exp 1 armour 1 weapon_lvl 0	
				unit	Italian Cavalry Militia	exp 4 armour 0 weapon_lvl 0
				unit	Urban Spear Militia		exp 7 armour 0 weapon_lvl 0
				unit	Urban Spear Militia		exp 1 armour 0 weapon_lvl 0
				unit	Urban Spear Militia		exp 0 armour 0 weapon_lvl 0
				unit	Urban Crossbow Militia	exp 1 armour 0 weapon_lvl 0
				unit	Urban Crossbow Militia	exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ pisa army spawned
	end_if

	if I_IsFactionAIControlled scotland
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction scotland
				character	Comgell mac_Donnchada, named character, age 20, x 64, y 244, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Scottish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction scotland
				character	Comgell mac_Donnchada, named character, age 30, x 55, y 252, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Scottish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Highlanders			exp 0 armour 0 weapon_lvl 0
				unit	Norman Serjeants	exp 4 armour 0 weapon_lvl 0
				unit	Norman Serjeants	exp 1 armour 0 weapon_lvl 0
				unit	Scots Skirmisher	exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ scotland army spawned
	end_if

	if I_IsFactionAIControlled cumans
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction cumans
				character	Balamir of_the_Oghuz, named character, age 20, x 279, y 176, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Cumans 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Cuman Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction cumans
				character	Balamir of_the_Oghuz, named character, age 30, x 374, y 185, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Cumans 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Cuman Bodyguard		exp 2 armour 1 weapon_lvl 0
				unit	Cuman Horse Militia	exp 1 armour 0 weapon_lvl 0
				unit	Kasogi Senior Militia	exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ cumans army spawned
	end_if

	if I_IsFactionAIControlled byzantium
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction byzantium
				character	Areovindos Komnenos, named character, age 20, x 275, y 144, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Greek 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Greek Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction byzantium
				character	Areovindos Komnenos, named character, age 30, x 275, y 144, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Greek 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Greek Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Contaratoi		exp 0 armour 0 weapon_lvl 0
				unit	Contaratoi	exp 1 armour 0 weapon_lvl 0
				unit	Contaratoi	exp 0 armour 0 weapon_lvl 0
				unit	Mourtatoi	exp 1 armour 0 weapon_lvl 0
				unit	Toxotae		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ byzantium army spawned
	end_if

	if I_IsFactionAIControlled russia
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction russia
				character	Domazhir Novgorodskii, named character, age 20, x 301, y 253, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Russian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	EE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction russia
				character	Domazhir Novgorodskii, named character, age 30, x 300, y 262, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Russian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	EE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Junior Militia		exp 7 armour 0 weapon_lvl 0
				unit	Junior Militia		exp 0 armour 0 weapon_lvl 0
				unit	Woodsmen			exp 7 armour 0 weapon_lvl 0
				unit	Woodsmen			exp 4 armour 0 weapon_lvl 0
				unit	Woodsmen			exp 1 armour 0 weapon_lvl 0
				unit	Woodsmen			exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ russia army spawned
	end_if

	if I_IsFactionAIControlled poland
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction poland
				character	Dobromir Piast, named character, age 20, x 226, y 210, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Polish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction poland
				character	Dobromir Piast, named character, age 30, x 209, y 231, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 3 , ReligionStarter 1 , Royal_Blood_Polish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Scouts				exp 1 armour 1 weapon_lvl 0
				unit	Woodsmen			exp 4 armour 0 weapon_lvl 0
				unit	Woodsmen			exp 1 armour 0 weapon_lvl 0
				unit	Woodsmen			exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 7 armour 0 weapon_lvl 0
				unit	Hunters				exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ poland army spawned
	end_if

	if I_IsFactionAIControlled moors
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction moors
				character	Ayyub al_Andalusi, named character, age 20, x 18, y 80, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Moorish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction moors
				character	Ayyub al_Andalusi, named character, age 30, x 18, y 80, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 3 , ReligionStarter 1 , Royal_Blood_Moorish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Ahdath Militia	exp 0 armour 0 weapon_lvl 0
				unit	Ahdath Militia		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ moors army spawned
	end_if

	if I_IsFactionAIControlled rum
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction rum
				character	Beyhan Arslan, named character, age 20, x 314, y 120, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Rum_Turkish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction rum
				character	Beyhan Arslan, named character, age 30, x 307, y 123, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Rum_Turkish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Ahdath Militia	exp 0 armour 0 weapon_lvl 0
				unit	Turkish Archers		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ rum army spawned
	end_if

	if I_IsFactionAIControlled egypt
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction egypt
				character	Abdul-Malik al-Fatimiyyun, named character, age 20, x 309, y 60, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Egyptian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction egypt
				character	Abdul-Malik al-Fatimiyyun, named character, age 30, x 306, y 61, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Egyptian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Ahdath Militia	exp 0 armour 0 weapon_lvl 0
				unit	Ahdath Militia	exp 0 armour 0 weapon_lvl 0
				unit	African Archers		exp 0 armour 0 weapon_lvl 0
				unit	African Archers		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ egypt army spawned
	end_if

	if I_IsFactionAIControlled denmark
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction denmark
				character	Birger Svendsen, named character, age 20, x 174, y 246, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Danish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Royal Hirdsmen		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction denmark
				character	Birger Svendsen, named character, age 30, x 159, y 240, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Danish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Royal Hirdsmen		exp 2 armour 0 weapon_lvl 0
				unit	Viking Raiders		exp 1 armour 0 weapon_lvl 0
				unit	Hunters				exp 4 armour 0 weapon_lvl 0
				unit	Hunters				exp 1 armour 0 weapon_lvl 0
			end
		end_if
	log ------ denmark army spawned
	end_if

	if I_IsFactionAIControlled portugal
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction portugal
				character	Cristovan Vimaranes, named character, age 20, x 17, y 135, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Portuguese 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction portugal
				character	Cristovan Vimaranes, named character, age 30, x 15, y 133, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Portuguese 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
					unit	SE Bodyguard			exp 1 armour 0 weapon_lvl 0
					unit	Jinetes					exp 0 armour 0 weapon_lvl 0
					unit	Sergeant Spearmen		exp 7 armour 0 weapon_lvl 0
					unit	Sergeant Spearmen		exp 0 armour 0 weapon_lvl 0
					unit	Lusitanian Javelinmen	exp 7 armour 0 weapon_lvl 0
					unit	Lusitanian Javelinmen	exp 0 armour 0 weapon_lvl 0
					unit	Axe Militia				exp 7 armour 0 weapon_lvl 0
					unit	Axe Militia				exp 0 armour 0 weapon_lvl 0
					unit	Urban Crossbow Militia	exp 0 armour 0 weapon_lvl 0
					unit	Hunters					exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ portugal army spawned
	end_if

	if I_IsFactionAIControlled hungary
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction hungary
				character	Bod Arpadhazi, named character, age 20, x 212, y 177, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Hungarian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction hungary
				character	Bod Arpadhazi, named character, age 30, x 215, y 185, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Hungarian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Magyar Cavalry		exp 1 armour 0 weapon_lvl 0
				unit	EE Spear Militia	exp 0 armour 0 weapon_lvl 0
				unit	EE Spear Militia	exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 4 armour 0 weapon_lvl 0
				unit	Hunters				exp 1 armour 0 weapon_lvl 0
			end
		end_if
	log ------ hungary army spawned
	end_if

	if I_IsFactionAIControlled jerusalem
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction jerusalem
				character	Colin de_Boulogne, named character, age 20, x 329, y 72, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Jerusalem 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction jerusalem
				character	Colin de_Boulogne, named character, age 30, x 329, y 72, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Jerusalem 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	NE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Mounted Sergeants	exp 1 armour 0 weapon_lvl 0
				unit	Sergeant Spearmen	exp 0 armour 0 weapon_lvl 0
				unit	Sergeant Spearmen	exp 1 armour 0 weapon_lvl 0
				unit	Sergeant Spearmen	exp 0 armour 0 weapon_lvl 0
				unit	Sergeant Spearmen	exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ jerusalem army spawned
	end_if

	if I_IsFactionAIControlled lithuania
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction lithuania
				character	Kestutis, named character, age 20, x 243, y 243, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Lithuanian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Lith Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction lithuania
				character	Kestutis, named character, age 30, x 243, y 243, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Lithuanian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
					unit	Lith Bodyguard			exp 1 armour 1 weapon_lvl 0
					unit	Ducal Cavalry			exp 0 armour 0 weapon_lvl 0
					unit	Ducal Spearmen			exp 0 armour 0 weapon_lvl 0
					unit	Baltic Spearmen			exp 7 armour 0 weapon_lvl 0
					unit	Baltic Spearmen			exp 0 armour 0 weapon_lvl 0
					unit	Lithuanian Axemen		exp 7 armour 0 weapon_lvl 0
					unit	Lithuanian Axemen		exp 0 armour 0 weapon_lvl 0
					unit	Lithuanian Skirmishers	exp 0 armour 0 weapon_lvl 0
					unit	Lithuanian Archers		exp 7 armour 0 weapon_lvl 0
					unit	Lithuanian Archers		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ lithuania army spawned
	end_if

	if I_IsFactionAIControlled kievan_rus
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction kievan_rus
				character	Dobroslav Yaroslavich, named character, age 20, x 294, y 207, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Kievan 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	EE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction kievan_rus
				character	Dobroslav Yaroslavich, named character, age 30, x 272, y 209, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Kievan 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	EE Bodyguard		exp 1 armour 1 weapon_lvl 0
				unit	Junior Militia	exp 0 armour 0 weapon_lvl 0
				unit	Junior Militia	exp 1 armour 0 weapon_lvl 0
				unit	Hunters				exp 4 armour 0 weapon_lvl 0
				unit	Hunters				exp 1 armour 0 weapon_lvl 0
			end
		end_if
	log ------ kievan_rus army spawned
	end_if

	if I_IsFactionAIControlled aragon
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction aragon
				character	Alvar Ramirez, named character, age 20, x 85, y 142, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Aragonese 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction aragon
				character	Alvar Ramirez, named character, age 30, x 68, y 142, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Aragonese 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	SE Bodyguard			exp 1 armour 0 weapon_lvl 0
				unit	Alforrats				exp 0 armour 0 weapon_lvl 0
				unit	Almughavars		exp 0 armour 0 weapon_lvl 0
				unit	Almughavars				exp 7 armour 0 weapon_lvl 0
				unit	Almughavars				exp 0 armour 0 weapon_lvl 0
				unit	Axe Militia				exp 7 armour 0 weapon_lvl 0
				unit	Axe Militia				exp 0 armour 0 weapon_lvl 0
				unit	Hunters					exp 7 armour 0 weapon_lvl 0
				unit	Hunters					exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ aragon army spawned
	end_if

	if I_IsFactionAIControlled norway
		if I_EventCounter DifficultyLevel <= 2	;updated by Lifthrasir May 2013
			spawn_army
				faction norway
				character	Erik Haakonsson, named character, age 20, x 114, y 280, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Norwegian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Royal Hirdsmen		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2	;updated by Lifthrasir May 2013
			spawn_army
				faction norway
				character	Erik Haakonsson, named character, age 30, x 114, y 280, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Norwegian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Royal Hirdsmen		exp 1 armour 1 weapon_lvl 0
				unit	Viking Raiders		exp 1 armour 0 weapon_lvl 0
				unit	Svenner				exp 7 armour 0 weapon_lvl 0
				unit	Svenner				exp 0 armour 0 weapon_lvl 0
				unit	Hunters				exp 4 armour 0 weapon_lvl 0
				unit	Hunters				exp 1 armour 0 weapon_lvl 0
			end
		end_if
	log ------ norway army spawned
	end_if

	if I_IsFactionAIControlled zengid
		if I_EventCounter DifficultyLevel <= 2
			spawn_army
				faction zengid
				character	Batu Mohammed, named character, age 20, x 399, y 103, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Zengid 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
			end
		end_if

		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction zengid
				character	Batu Mohammed, named character, age 30, x 357, y 107, family
				traits LoyaltyStarter 1 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Zengid 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard				exp 2 armour 1 weapon_lvl 0
				unit	Turkomans					exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry		exp 4 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry		exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry		exp 0 armour 0 weapon_lvl 0
				unit	Kurdish Javelinmen			exp 0 armour 0 weapon_lvl 0
				unit	Dismounted Fari Archers		exp 4 armour 0 weapon_lvl 0
				unit	Dismounted Fari Archers		exp 0 armour 0 weapon_lvl 0
			end
		end_if
	log ------ zengid army spawned
	end_if
	log ------ script end
	terminate_monitor
end_monitor

;======================================================================================================
;-------- Spawn of Fleets at the Beginning

monitor_event PreFactionTurnStart not IsFactionAIControlled
log --- script start : Additional starting fleets

	if I_IsFactionAIControlled england
		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction england
				character random_name, admiral, age 20, x 47, y 206
				unit	cog		exp 2 armour 0 weapon_lvl 0
			end
			log ------ england fleet spawned
		end_if
	end_if

	if I_IsFactionAIControlled moors
		if I_EventCounter DifficultyLevel > 2
			spawn_army
				faction moors
				character random_name, admiral, age 22, x 27, y 94
				unit	dhow		exp 2 armour 0 weapon_lvl 0
			end
			log ------ moors fleet spawned
		end_if
	end_if
	log ------ script end
	terminate_monitor
end_monitor


;======================================================================================================
;======================================================================================================
;-------- Scripted Early Sieges with Additional Armies
;======================================================================================================
;======================================================================================================
;
; The aim of this script is to support the weak factions that happen to be inactive, and also to make the often inactive regions of the map running.
;
; FURTHER MODDING:
; - add automatic siege of Pamplona for Aragon

; IF YOU ADD A SIEGE:
; - make both historical and gameplay assessment before adding or removing.
; - if you add, remember to terminate monitors to save time
; Pitfals:
; - give good loyalty to spawned general: if he rebels you would have a slave general attacking a slave settlement because of the script. So the game will CTD.
; - maintaining siege for longer than 1 turn seems not to work in practice;
; - the AI will never besiege a settlement that does not border one of theirs by land or by sea. Even if the script forcibly makes the AI army besiege a settlement, the AI army would just break off the next turn.
;   In this context the concept of "bordering by sea" is very blurry and making the AI sieging settlements on the other side of any water surface is prone to error.


;====================================================================================================== NORWAY: Skara 4, Sigtuna 24
; Skara is needed to provide Norway with some money, Sigtuna is just in case of inactivity (and unlikely since the AI very often expands in this direction).

monitor_event FactionTurnStart FactionType norway
	and I_TurnNumber > 2

	log --- script start : norway siege Skara
	if not I_IsFactionAIControlled norway
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 3
		if not I_SettlementOwner Skara = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Skara
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction norway
			character	Gunnar Guddrodson, named character, age 30, x 175, y 266, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 1 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		Royal Hirdsmen			exp 1 armour 0 weapon_lvl 0
			unit		Svenner					exp 0 armour 0 weapon_lvl 0
			unit		Drengjar				exp 7 armour 0 weapon_lvl 0
			unit		Drengjar				exp 0 armour 0 weapon_lvl 0
			unit		Bondir					exp 7 armour 0 weapon_lvl 0
			unit		Bondir					exp 0 armour 0 weapon_lvl 0
			unit		Hunters					exp 7 armour 0 weapon_lvl 0
			unit		Hunters					exp 0 armour 0 weapon_lvl 0
		end

		log ------ siege Skara
		siege_settlement Gunnar Guddrodson, Skara, maintain
	end_if

	if I_TurnNumber = 4
		log ------ attack Skara
		console_command auto_win attacker
		siege_settlement Gunnar Guddrodson, Skara, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType norway
	and I_TurnNumber > 22

	log --- script start : norway siege Sigtuna
	if not I_IsFactionAIControlled norway
		log ------ terminate monitor (player control the faction)
		terminate_monitor													; terminate to shorten the turn times in the future
	end_if

	if I_TurnNumber = 23

		if not I_SettlementOwner Sigtuna = slave

			terminate_monitor
		end_if

		if I_SettlementUnderSiege Sigtuna
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction norway
			character	Bjorn Stenger, named character, age 24, x 205, y 275, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 1 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 8 , Intelligent 6
			unit		Royal Hirdsmen			exp 1 armour 0 weapon_lvl 0
			unit		Viking Raiders			exp 0 armour 0 weapon_lvl 0
			unit		Drengjar				exp 0 armour 0 weapon_lvl 0
			unit		Bondir					exp 7 armour 0 weapon_lvl 0
			unit		Bondir					exp 0 armour 0 weapon_lvl 0
			unit		Hunters					exp 7 armour 0 weapon_lvl 0
			unit		Hunters					exp 0 armour 0 weapon_lvl 0
		end

		log ------ siege settlement
		siege_settlement Bjorn Stenger, Sigtuna, maintain
	end_if

	if I_TurnNumber = 24
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Bjorn Stenger, Sigtuna, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== DENMARK: Ribe 4, Visby 24
; Ribe is to provide some space from HRE (or an additional army), Visby is to ensure the island is conquered (and it also helps Denmark not to be wiped out from the map).

monitor_event FactionTurnStart FactionType denmark
	and I_TurnNumber > 2

	log --- script start : denmark siege Ribe
	if not I_IsFactionAIControlled denmark
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 3
		if not I_SettlementOwner Ribe = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Ribe
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction denmark
			character	Gunnar Estridsen, named character, age 30, x 140, y 244, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		Royal Hirdsmen				exp 1 armour 0 weapon_lvl 0
			unit		Norse Axemen				exp 4 armour 0 weapon_lvl 0
			unit		Skjoldborgsmenn				exp 1 armour 0 weapon_lvl 0
			unit		Skjoldborgsmenn				exp 1 armour 0 weapon_lvl 0
			unit		Viking Raiders				exp 4 armour 0 weapon_lvl 0
			unit		Viking Raiders				exp 1 armour 0 weapon_lvl 0
			unit		Norse Archers				exp 3 armour 0 weapon_lvl 0
			unit		Norse Archers				exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Gunnar Estridsen, Ribe, maintain
	end_if

	if I_TurnNumber = 4
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Gunnar Estridsen, Ribe, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType denmark
	and I_TurnNumber > 22

	log --- script start : denmark siege Visby
	if not I_IsFactionAIControlled denmark
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 23
		if not I_SettlementOwner Visby = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Visby
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction denmark
			character	Agge Jorgensen, named character, age 25, x 211, y 260, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 1 , ReligionStarter 1 , BiologicalSon 1 , Handsome 5 , Intelligent 7
			unit		Royal Hirdsmen				exp 1 armour 0 weapon_lvl 0
			unit		Viking Raiders				exp 4 armour 0 weapon_lvl 0
			unit		Viking Raiders				exp 1 armour 0 weapon_lvl 0
			unit		Norse Archers				exp 3 armour 0 weapon_lvl 0
			unit		Norse Archers				exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Agge Jorgensen, Visby, maintain
	end_if

	if I_TurnNumber = 24
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Agge Jorgensen, Visby, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== LITHUANIA: Riga 4, Goroden 20
; Riga is to give some money and recruitment, Goroden is to ensure this front is going (it's often taken earlier) and make Lithuania a serious challenge to Poland.

monitor_event FactionTurnStart FactionType lithuania
	and I_TurnNumber > 2

	log --- script start : lithuania siege Riga
	if not I_IsFactionAIControlled lithuania
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 3

		if not I_SettlementOwner Riga = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Riga
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction lithuania
			character	Margiris of_Hrodna, named character, age 30, x 250, y 254, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Lith Bodyguard			exp 1 armour 1 weapon_lvl 0
				unit	Ducal Cavalry			exp 0 armour 0 weapon_lvl 0
				unit	Ducal Spearmen			exp 0 armour 0 weapon_lvl 0
				unit	Baltic Spearmen			exp 7 armour 0 weapon_lvl 0
				unit	Baltic Spearmen			exp 0 armour 0 weapon_lvl 0
				unit	Lithuanian Axemen		exp 7 armour 0 weapon_lvl 0
				unit	Lithuanian Axemen		exp 0 armour 0 weapon_lvl 0
				unit	Chude Militia			exp 0 armour 0 weapon_lvl 0
				unit	Lithuanian Skirmishers	exp 0 armour 0 weapon_lvl 0
				unit	Lithuanian Archers		exp 7 armour 0 weapon_lvl 0
				unit	Lithuanian Archers		exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Margiris of_Hrodna, Riga, maintain
	end_if

	if I_TurnNumber = 4
		log ------ script Early sieges --- attack Riga
		console_command auto_win attacker
		siege_settlement Margiris of_Hrodna, Riga, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType lithuania
	and I_TurnNumber > 18

	log --- script start : lithuania siege Goroden
	if not I_IsFactionAIControlled lithuania
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 19

		if not I_SettlementOwner Goroden = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Goroden
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction lithuania
			character	Treniota of_Kreva, named character, age 28, x 249, y 228, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 3 , ReligionStarter 1 , BiologicalSon 1 , Handsome 5 , Intelligent 7
				unit	Lith Bodyguard			exp 1 armour 1 weapon_lvl 0
				unit	Ducal Cavalry			exp 0 armour 0 weapon_lvl 0
				unit	Ducal Spearmen			exp 0 armour 0 weapon_lvl 0
				unit	Baltic Spearmen			exp 7 armour 0 weapon_lvl 0
				unit	Baltic Spearmen			exp 0 armour 0 weapon_lvl 0
				unit	Lithuanian Axemen		exp 7 armour 0 weapon_lvl 0
				unit	Lithuanian Axemen		exp 0 armour 0 weapon_lvl 0
				unit	Chude Militia			exp 0 armour 0 weapon_lvl 0
				unit	Lithuanian Skirmishers	exp 0 armour 0 weapon_lvl 0
				unit	Lithuanian Archers		exp 7 armour 0 weapon_lvl 0
				unit	Lithuanian Archers		exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Treniota of_Kreva, Goroden, maintain
	end_if

	if I_TurnNumber = 20
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Treniota of_Kreva, Goroden, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log --- script start
end_monitor

;====================================================================================================== NOVGOROD: Polotsk 6
; this one is very often thwarted by the rebels: they're stronger

monitor_event FactionTurnStart FactionType russia
	and I_TurnNumber > 4

	log --- script start : russia siege Polotsk
	if not I_IsFactionAIControlled russia
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 5

		if not I_SettlementOwner Polotsk = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Polotsk
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn armys
		spawn_army
			faction russia
			character	Vselovod Izborskii, named character, age 24, x 281, y 244, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 1 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 8 , Intelligent 6
			unit		EE Bodyguard				exp 3 armour 0 weapon_lvl 0
			unit		Druzhina					exp 1 armour 0 weapon_lvl 0
			unit		Berdiche Axemen				exp 4 armour 0 weapon_lvl 0
			unit		Woodsmen					exp 1 armour 0 weapon_lvl 0
			unit		Rus Senior Militia			exp 4 armour 0 weapon_lvl 0
			unit		Rus Senior Militia			exp 0 armour 0 weapon_lvl 0
			unit		Junior Militia				exp 1 armour 0 weapon_lvl 0
			unit		Junior Militia				exp 0 armour 0 weapon_lvl 0
			unit		EE Peasant Archers			exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Vselovod Izborskii, Polotsk, maintain
	end_if

	if I_TurnNumber = 6
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Vselovod Izborskii, Polotsk, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== CUMANS: Severin 4, Bulgar 14
; Severin is to make the ERE life harder and keep this front running, Bulgar is to ensure this province is in play (it's really far away!), then threaten Russian from the north-east

	monitor_event FactionTurnStart FactionType cumans
	and I_TurnNumber > 2

	log --- script start : cumans siege Severin
	if not I_IsFactionAIControlled cumans
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 3

		if not I_SettlementOwner Severin = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Severin
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction cumans
			character	Bonyak of_Karluk, named character, age 26, x 246, y 168, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 5 , Intelligent 5
			unit		Cuman Bodyguard				exp 2 armour 0 weapon_lvl 0
			unit		Behk Druzhina				exp 3 armour 0 weapon_lvl 0
			unit		Behk Druzhina				exp 1 armour 0 weapon_lvl 0
			unit		Cuman Horse Militia			exp 4 armour 0 weapon_lvl 0
			unit		Cuman Horse Militia			exp 1 armour 0 weapon_lvl 0
			unit		Steppe Alans				exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Cuman Militia	exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Cuman Militia	exp 0 armour 0 weapon_lvl 0
			unit		Dismounted Cuman Militia	exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Bonyak of_Karluk, Severin, maintain
	end_if

	if I_TurnNumber = 4
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Bonyak of_Karluk, Severin, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType cumans
	and I_TurnNumber > 12

	log --- script start : cumans siege Bulgar
	if not I_IsFactionAIControlled cumans
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 13

		if not I_SettlementOwner Bulgar = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Bulgar
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction cumans
			character	Ilteris of_the_Oghuz, named character, age 30, x 435, y 241, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		Cuman Bodyguard				exp 2 armour 0 weapon_lvl 0
			unit		Behk Druzhina				exp 3 armour 0 weapon_lvl 0
			unit		Behk Druzhina				exp 1 armour 0 weapon_lvl 0
			unit		Cuman Horse Militia			exp 4 armour 0 weapon_lvl 0
			unit		Cuman Horse Militia			exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Cuman Militia	exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Cuman Militia	exp 0 armour 0 weapon_lvl 0
			unit		Dismounted Cuman Militia	exp 0 armour 0 weapon_lvl 0
			unit		Kasogi						exp 0 armour 0 weapon_lvl 0
			unit		Kasogi						exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Ilteris of_the_Oghuz, Bulgar, maintain
	end_if

	if I_TurnNumber = 14
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Ilteris of_the_Oghuz, Bulgar, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== FRANCE: Dijon 5
; to give France a bit more power as it's squeezed between HRE and England

monitor_event FactionTurnStart FactionType france
	and I_TurnNumber > 3

	log --- script start : france siege Dijon
	if not I_IsFactionAIControlled france
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 4

		if not I_SettlementOwner Dijon = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Dijon
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction france
			character	Aubert Tristan, named character, age 30, x 114, y 186, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_French 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		NE Bodyguard					exp 1 armour 0 weapon_lvl 0
			unit		Mailed Knights					exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Sword Mailed Knights	exp 4 armour 0 weapon_lvl 0
			unit		Sergeant Spearmen				exp 4 armour 0 weapon_lvl 0
			unit		Sergeant Spearmen				exp 1 armour 0 weapon_lvl 0
			unit		Sergeant Spearmen				exp 1 armour 0 weapon_lvl 0
			unit		Peasant Archers					exp 1 armour 0 weapon_lvl 0
			unit		Peasant Archers					exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Aubert Tristan, Dijon, maintain
	end_if

	if I_TurnNumber = 5
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Aubert Tristan, Dijon, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== ENGLAND: Poitiers 7
; to enable England fighting France on the continent

monitor_event FactionTurnStart FactionType england
	and I_TurnNumber > 5

	log --- script start : england siege Poitiers
	if not I_IsFactionAIControlled england
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 6

		if not I_SettlementOwner Poitiers = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Poitiers
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction england
			character	Giles Blacke, named character, age 30, x 80, y 181, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_English 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		NE Bodyguard				exp 1 armour 0 weapon_lvl 0
			unit		Norman Cavalry				exp 4 armour 0 weapon_lvl 0
			unit		Dismounted Norman Cavalry	exp 1 armour 0 weapon_lvl 0
			unit		Armored Sergeants			exp 4 armour 0 weapon_lvl 0
			unit		Armored Sergeants			exp 1 armour 0 weapon_lvl 0
			unit		Fyrd Spearmen				exp 1 armour 0 weapon_lvl 0
			unit		Fyrd Spearmen				exp 0 armour 0 weapon_lvl 0
			unit		Peasant Archers				exp 1 armour 0 weapon_lvl 0
			unit		Peasant Archers				exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Giles Blacke, Poitiers, maintain
	end_if

	if I_TurnNumber = 7
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Giles Blacke, Poitiers, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== PORTUGAL: Badajoz 2
; The AI is usually very good at taking Lisbon, no need for that one. This one is to provide Portugal with a third settlement and challenge the Moors.

monitor_event FactionTurnStart FactionType portugal
	and I_TurnNumber > 0

	log --- script start : portugal siege Badajoz
	if not I_IsFactionAIControlled portugal
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if not I_IsFactionAIControlled moors
		log ------ terminate monitor (player control the Moors)
		terminate_monitor
	end_if

	log --- script start : portugal siege Badajoz
	if not I_IsFactionAIControlled spain
		log ------ terminate monitor (player control the Castille)
		terminate_monitor
	end_if

	if I_TurnNumber = 1

		if not I_SettlementOwner Badajoz = moors
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Badajoz
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction portugal
			character	Fernando Bragansa, named character, age 30, x 28, y 127, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 8
			unit		SE Bodyguard					exp 1 armour 0 weapon_lvl 0
			unit		Caballeros Hidalgos				exp 1 armour 0 weapon_lvl 0
			unit		Caballeros Villanos				exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Sword Mailed Knights	exp 2 armour 0 weapon_lvl 0
			unit		Light Swordsmen					exp 2 armour 0 weapon_lvl 0
			unit		Spear Militia					exp 0 armour 0 weapon_lvl 0
			unit		Spear Militia					exp 0 armour 0 weapon_lvl 0
			unit		Lusitanian Javelinmen			exp 1 armour 0 weapon_lvl 0
			unit		Javelinmen						exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Fernando Bragansa, Badajoz, maintain
	end_if

	if I_TurnNumber = 2
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Fernando Bragansa, Badajoz, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== PISA: Cagliari 5, Tunis 9
;-------- PISA takes SARDEGNA --------------------------------------------------------------------------
; Cagliari: to ensure the islands are taken. Tunis: to ensure this theater is active.

monitor_event FactionTurnStart FactionType pisa
	and I_TurnNumber > 3

	log --- script start : pisa siege Cagliari
	if not I_IsFactionAIControlled pisa
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 4

		if not I_SettlementOwner Cagliari = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Cagliari
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction pisa
			character	Matteo Gariboldi, named character, age 30, x 142, y 130, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Handsome 6 , Intelligent 6
			unit		SE Bodyguard					exp 1 armour 0 weapon_lvl 0
			unit		Sergeant Spearmen				exp 0 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 0 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 0 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia			exp 3 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia			exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Matteo Gariboldi, Cagliari, maintain
	end_if

	if I_TurnNumber = 5
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Matteo Gariboldi, Cagliari, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType pisa
	and I_TurnNumber > 7

	log --- script start : pisa siege Tunis
	if not I_IsFactionAIControlled pisa
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 8

		if not I_SettlementOwner Tunis = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Tunis
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction pisa
			character	Corsello Legnano, named character, age 32, x 151, y 108, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 2 , ReligionStarter 1 , Handsome 6 , Intelligent 8
			unit		SE Bodyguard					exp 1 armour 0 weapon_lvl 0
			unit		Italian Cavalry Militia			exp 0 armour 0 weapon_lvl 0
			unit		Dismounted Sword Mailed Knights	exp 1 armour 0 weapon_lvl 0
			unit		Sergeant Spearmen				exp 4 armour 0 weapon_lvl 0
			unit		Sergeant Spearmen				exp 0 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 4 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 0 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia			exp 3 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia			exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Corsello Legnano, Tunis, maintain
	end_if

	if I_TurnNumber = 9
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Corsello Legnano, Tunis, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== SICILY: Tarabulus 12
; Sicily is very good at autoresolve, it takes Italy at ease (until the Pope is met ;-). Tarabulus prompts Sicily to expand in Africa, so it's good.
; however, there's been a report for 098 that taking Naples is difficult for the AI

monitor_event FactionTurnStart FactionType sicily
	and I_TurnNumber > 10

	log --- script start : sicily siege Tarabulus
	if not I_IsFactionAIControlled sicily
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 11

		if not I_SettlementOwner Tarabulus = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Tarabulus
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction sicily
			character	Ferrante Rocca, named character, age 30, x 173, y 82, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Sicilian 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		SE Bodyguard				exp 1 armour 0 weapon_lvl 0
			unit		Mounted Sergeants			exp 4 armour 0 weapon_lvl 0
			unit		Norman Cavalry				exp 4 armour 0 weapon_lvl 0
			unit		Norman Cavalry				exp 1 armour 0 weapon_lvl 0
			unit		Norman Cavalry				exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Norman Cavalry	exp 0 armour 0 weapon_lvl 0
			unit		Urban Spear Militia			exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia			exp 0 armour 0 weapon_lvl 0
			unit		Crossbow Militia			exp 1 armour 0 weapon_lvl 0
			unit		Crossbow Militia			exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Ferrante Rocca, Tarabulus, maintain
	end_if

	if I_TurnNumber = 12
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Ferrante Rocca, Tarabulus, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor


;====================================================================================================== VENICE: Zara 4, Verona 14
; Zara to provide challenge and fight with the other factions, Verona to ensure Venice expands to face HRE and Sicily.

monitor_event FactionTurnStart FactionType venice
	and I_TurnNumber > 2

	log --- script start : venice siege Zara
	if not I_IsFactionAIControlled venice
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 3

		if not I_SettlementOwner Zara = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Zara
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction venice
			character	Thadeo Zorzi, named character, age 30, x 188, y 164, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
			unit		SE Bodyguard				exp 1 armour 0 weapon_lvl 0
			unit		Italian Cavalry Militia		exp 1 armour 0 weapon_lvl 0
			unit		Armored Sergeants			exp 4 armour 0 weapon_lvl 0
			unit		Armored Sergeants			exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia			exp 4 armour 0 weapon_lvl 0
			unit		Urban Spear Militia			exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia			exp 0 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia		exp 4 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia		exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Thadeo Zorzi, Zara, maintain
	end_if

	if I_TurnNumber = 4
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Thadeo Zorzi, Zara, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType venice
	and I_TurnNumber > 12

	log --- script start : venice siege Verona
	if not I_IsFactionAIControlled venice
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 13

		if not I_SettlementOwner Verona = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Verona
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
			spawn_army
			faction venice
			character	Raffiano Morosini, named character, age 33, x 158, y 172, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 3 , ReligionStarter 1 , BiologicalSon 1 , Handsome 8 , Intelligent 5
			unit		SE Bodyguard					exp 1 armour 0 weapon_lvl 0
			unit		Italian Cavalry Militia			exp 0 armour 0 weapon_lvl 0
			unit		Dismounted Sword Mailed Knights	exp 1 armour 0 weapon_lvl 0
			unit		Dismounted Sword Mailed Knights	exp 1 armour 0 weapon_lvl 0
			unit		Armored Sergeants				exp 4 armour 0 weapon_lvl 0
			unit		Armored Sergeants				exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 1 armour 0 weapon_lvl 0
			unit		Urban Spear Militia				exp 0 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia			exp 1 armour 0 weapon_lvl 0
			unit		Urban Crossbow Militia			exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Raffiano Morosini, Verona, maintain
	end_if

	if I_TurnNumber = 14
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Raffiano Morosini, Verona, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== SERBIA: Skadar 2, Vrhbosna 9
; The AI usually takes Vrhbosna around turn 2, this one is just in-case.

monitor_event FactionTurnStart FactionType serbia
	and I_TurnNumber > 0

	log --- script start : serbia siege Skadar
	if not I_IsFactionAIControlled serbia
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 1

		if not I_SettlementOwner Skadar = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Skadar
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction serbia
			character	Gojko Petrovic, named character, age 30, x 217, y 148, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 3 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	Bashtinik Infantry			exp 2 armour 0 weapon_lvl 0
				unit	Scouts						exp 1 armour 0 weapon_lvl 0
				unit	Bashtinik Infantry			exp 0 armour 0 weapon_lvl 0
				unit	Axe Militia					exp 0 armour 0 weapon_lvl 0
				unit	Slav Levies					exp 7 armour 0 weapon_lvl 0
				unit	Slav Levies					exp 0 armour 0 weapon_lvl 0
				unit	Slav Mercenaries			exp 0 armour 0 weapon_lvl 0
				unit	Balkan Archers				exp 7 armour 0 weapon_lvl 0
				unit	Balkan Archers				exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Gojko Petrovic, Skadar, maintain
	end_if

	if I_TurnNumber = 2
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Gojko Petrovic, Skadar, attack
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType serbia
	and I_TurnNumber > 7

	log --- script start : serbia siege Vrhbosna
	if not I_IsFactionAIControlled serbia
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 8

		if not I_SettlementOwner Vrhbosna = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Vrhbosna
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
			spawn_army
			faction serbia
			character	Ivica Petrovic, named character, age 22, x 208, y 160, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 1 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 7 , Intelligent 6
				unit	EE Bodyguard 				exp 2 armour 0 weapon_lvl 0
				unit	Scouts						exp 1 armour 0 weapon_lvl 0
				unit	Dismounted Vlastelcici 		exp 0 armour 0 weapon_lvl 0
				unit	Bashtinik Infantry			exp 0 armour 0 weapon_lvl 0
				unit	Axe Militia					exp 0 armour 0 weapon_lvl 0
				unit	Slav Levies					exp 7 armour 0 weapon_lvl 0
				unit	Slav Levies					exp 0 armour 0 weapon_lvl 0
				unit	Slav Mercenaries			exp 0 armour 0 weapon_lvl 0
				unit	Balkan Archers				exp 7 armour 0 weapon_lvl 0
				unit	Balkan Archers				exp 0 armour 0 weapon_lvl 0
		end
		log ------- siege settlement
		siege_settlement Ivica Petrovic, Vrhbosna, maintain
	end_if

	if I_TurnNumber = 9
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Ivica Petrovic, Vrhbosna, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== RUM: Kaiseri 4, Sives 12
; Kayseri is to some chance against the ERE behemot, and Sives is similar - to prevent inactivity

monitor_event FactionTurnStart FactionType rum
	and I_TurnNumber > 3

	log --- script start : rum siege Caesarea
	if not I_IsFactionAIControlled rum
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 4

		if not I_SettlementOwner Caesarea = slave
			log ------ terminate monitor (settlement is controlled by another faction
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Caesarea
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction rum
			character	Mes_ud Gazi, named character, age 30, x 334, y 124, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Rum_Turkish 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard			exp 1 armour 0 weapon_lvl 0
				unit	Turkish Horse Archers	exp 1 armour 0 weapon_lvl 0
				unit	Turkish Horse Archers	exp 0 armour 0 weapon_lvl 0
				unit	Turkomans				exp 0 armour 0 weapon_lvl 0
				unit	Armenian Infantry		exp 4 armour 0 weapon_lvl 0
				unit	Armenian Infantry		exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 0 armour 0 weapon_lvl 0				
				unit	Dismounted Fari Archers	exp 0 armour 0 weapon_lvl 0
				unit	Turkish Archers			exp 1 armour 0 weapon_lvl 0
				unit	Turkish Archers			exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Mes_ud Gazi, Caesarea, maintain
	end_if

	if I_TurnNumber = 5
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Mes_ud Gazi, Caesarea, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

monitor_event FactionTurnStart FactionType rum
	and I_TurnNumber > 10

	log --- script start : rum siege Sives
	if not I_IsFactionAIControlled rum
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 11

		if not I_SettlementOwner Sives = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Sives
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
			spawn_army
			faction rum
			character	Osman Muzaffer, named character, age 30, x 345, y 132, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , Royal_Blood_Rum_Turkish 1 , BiologicalSon 1 , Handsome 7 , Intelligent 7
				unit	ME Bodyguard			exp 1 armour 0 weapon_lvl 0
				unit	Turkish Horse Archers	exp 1 armour 0 weapon_lvl 0
				unit	Turkomans				exp 1 armour 0 weapon_lvl 0
				unit	Turkomans				exp 0 armour 0 weapon_lvl 0
				unit	Armenian Infantry		exp 4 armour 0 weapon_lvl 0
				unit	Armenian Infantry		exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 4 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 0 armour 0 weapon_lvl 0				
				unit	Dismounted Fari Archers	exp 0 armour 0 weapon_lvl 0
				unit	Turkish Archers			exp 1 armour 0 weapon_lvl 0
				unit	Turkish Archers			exp 0 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Osman Muzaffer, Sives, maintain
	end_if

	if I_TurnNumber = 12
		log ------  attack settlement
		console_command auto_win attacker
		siege_settlement Osman Muzaffer, Sives, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor


;====================================================================================================== GEORGIA: Ani 16
;-------- GEORGIA to ANI
; Georgia is very effective on auto-resolve because it has heavy units. It takes Ani very soon. This siege is only in-case it's totally inactive.

monitor_event FactionTurnStart FactionType georgia
	and I_TurnNumber > 14

	log --- script start : georgia siege Ani
	if not I_IsFactionAIControlled georgia
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 15

		if not I_SettlementOwner Ani = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Ani
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction georgia
			character	Guaram Mikeladze, named character, age 30, x 392, y 136, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	bodyguard georgia			exp 1 armour 0 weapon_lvl 0
				unit	georgian heavy lancers		exp 1 armour 0 weapon_lvl 0
				unit	georgian medium swordsmen	exp 4 armour 0 weapon_lvl 0
				unit	georgian medium swordsmen	exp 1 armour 0 weapon_lvl 0
				unit	georgian light spearmen		exp 4 armour 0 weapon_lvl 0
				unit	georgian light spearmen		exp 1 armour 0 weapon_lvl 0
				unit	georgian light spearmen		exp 0 armour 0 weapon_lvl 0
				unit	georgian light archer		exp 0 armour 0 weapon_lvl 0
				unit	aor trasc javelin			exp 1 armour 0 weapon_lvl 0
				unit	aor trasc javelin			exp 1 armour 0 weapon_lvl 0
		end
		log ------ siege settlement
		siege_settlement Guaram Mikeladze, Ani, maintain
	end_if

	if I_TurnNumber = 16
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Guaram Mikeladze, Ani, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;====================================================================================================== ZENGHIDS: Damascus 7
; otherwised Damascus is very passive: huge garrison prevents AI from taking it
; however, it's to be seen how the Crusader States will cope with both Egypt and Zengids

monitor_event FactionTurnStart FactionType zengid
	and I_TurnNumber > 5

	log --- script start : zengid siege Damascus
	if not I_IsFactionAIControlled zengid
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 6

		if not I_SettlementOwner Damascus = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Damascus
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction zengid
			character	Bekir el_Aziz, named character, age 36, x 344, y 90, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 3 , GoodCommander 3 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 8
				unit	ME Bodyguard			exp 2 armour 0 weapon_lvl 0
				unit	Ghulams					exp 1 armour 0 weapon_lvl 0
				unit	Fari Horse Archers		exp 1 armour 0 weapon_lvl 0
				unit	Armenian Aspet Cavalry	exp 0 armour 0 weapon_lvl 0
				unit	Dismounted Ghulams		exp 1 armour 0 weapon_lvl 0
				unit	Dismounted Arab Cavalry	exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 4 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 0 armour 0 weapon_lvl 0				
				unit	Dismounted Fari Archers	exp 0 armour 0 weapon_lvl 0
				unit	Turkish Archers			exp 1 armour 0 weapon_lvl 0
				unit	Turkish Archers			exp 0 armour 0 weapon_lvl 0				
		end
		log ------ siege settlement
		siege_settlement Bekir el_Aziz, Damascus, maintain
	end_if

	if I_TurnNumber = 7
		log ------ attack settlement
		console_command auto_win attacker
		siege_settlement Bekir el_Aziz, Damascus, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor


;====================================================================================================== ABBASIDS: Al_Ahsa 7
; to ensure this far-away province is conquered and does not make Abbasid fall by sucking in the forces that may be useful against Seljuks or Zengids

monitor_event FactionTurnStart FactionType abbasid
	and I_TurnNumber > 5

	log --- script start : abbasid siege Al_Ahsa
	if not I_IsFactionAIControlled abbasid
		log ------ terminate monitor (player control the faction)
		terminate_monitor
	end_if

	if I_TurnNumber = 6

		if not I_SettlementOwner Al_Ahsa = slave
			log ------ terminate monitor (settlement is controlled by another faction)
			terminate_monitor
		end_if

		if I_SettlementUnderSiege Al_Ahsa
			log ------ terminate monitor (settlement is already under siege)
			terminate_monitor
		end_if

		log ------ spawn army
		spawn_army
			faction abbasid
			character	Abdun al-Hassan, named character, age 30, x 435, y 30, family
			traits LoyaltyStarter 3 , ContentGeneral 2 , MilitaryInclination 1 , Military_Edu 2 , GoodCommander 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6
				unit	ME Bodyguard			exp 2 armour 0 weapon_lvl 0
				unit	Ghulams					exp 1 armour 0 weapon_lvl 0
				unit	Fari Horse Archers		exp 1 armour 0 weapon_lvl 0
				unit	Bedouin Cavalry			exp 0 armour 0 weapon_lvl 0
				unit	Dismounted Ghulams		exp 1 armour 0 weapon_lvl 0
				unit	Abna Heavy Spearmen		exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 4 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 1 armour 0 weapon_lvl 0
				unit	Daylami Light Infantry	exp 0 armour 0 weapon_lvl 0				
				unit	Dismounted Fari Archers	exp 0 armour 0 weapon_lvl 0
				unit	Saracen Archers			exp 1 armour 0 weapon_lvl 0
				unit	Saracen Archers			exp 0 armour 0 weapon_lvl 0
			
		end
		log ------ siege settlement
		siege_settlement Abdun al-Hassan, Al_Ahsa, maintain
	end_if

	if I_TurnNumber = 7
		log ------ script Early sieges --- attack Al_Ahsa
		console_command auto_win attacker
		siege_settlement Abdun al-Hassan, Al_Ahsa, attack
		log ------ terminate monitor
		terminate_monitor
	end_if
	log ------ script end
end_monitor

;======================================================================================================
;-------- Additional Fleets Throughout The Game
;======================================================================================================


set_event_counter SupportCounter 0

monitor_event FactionTurnEnd FactionType slave

	log --- script start : Additional fleets
	inc_event_counter SupportCounter 1

	if I_EventCounter SupportCounter  > 75
		set_event_counter SupportCounter 0
		log ------ SupportCounter reset to 0
	end_if

	if I_IsFactionAIControlled england
		and I_NumberOfSettlements england > 0
		and I_EventCounter SupportCounter = 5
		log ------ spawn fleet for england
		spawn_army
			faction england
			character random_name, admiral, age 20, x 94, y 239
			unit	cog		exp 2 armour 0 weapon_lvl 0
			unit	cog		exp 2 armour 0 weapon_lvl 0
			unit	cog		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled france
		and I_NumberOfSettlements france > 0
		and I_EventCounter SupportCounter = 10
		log ------ spawn fleet for france
		spawn_army
			faction france
			character random_name, admiral, age 20, x 112, y 245
			unit	cog		exp 2 armour 0 weapon_lvl 0
			unit	cog		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled scotland
		and I_NumberOfSettlements scotland > 0
		and I_EventCounter SupportCounter = 15
		log ------ spawn fleet for scotland
		spawn_army
			faction scotland
			character random_name, admiral, age 20, x 76, y 270
			unit	cog		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled norway
		and I_NumberOfSettlements norway > 0
		and I_EventCounter SupportCounter = 20
		log ------ spawn fleet for norway
		spawn_army
			faction norway
			character random_name, admiral, age 20, x 85, y 282
			unit	longboat		exp 2 armour 0 weapon_lvl 0
			unit	longboat		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled denmark
		and I_NumberOfSettlements denmark > 0
		and I_EventCounter SupportCounter = 25
		log ------ spawn fleet for denmark
		spawn_army
			faction denmark
			character random_name, admiral, age 20, x 199, y 246
			unit	longboat		exp 2 armour 0 weapon_lvl 0
			unit	longboat		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled portugal
		and I_NumberOfSettlements portugal > 0
		and I_EventCounter SupportCounter = 30
		log ------ spawn fleet for portugal
		spawn_army
			faction portugal
			character random_name, admiral, age 20, x 2, y 137
			unit	cog		exp 2 armour 0 weapon_lvl 0
			unit	cog		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled spain
		and I_NumberOfSettlements spain > 0
		and I_EventCounter SupportCounter = 35
		log ------ spawn fleet for spain
		spawn_army
			faction spain
			character random_name, admiral, age 20, x 28, y 175
			unit	cog		exp 2 armour 0 weapon_lvl 0
			unit	cog		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled aragon
		and I_NumberOfSettlements aragon > 0
		and I_EventCounter SupportCounter = 40
		log ------ spawn fleet for aragon
		spawn_army
			faction aragon
			character random_name, admiral, age 20, x 117, y 140
			unit	cog		exp 2 armour 0 weapon_lvl 0
			unit	cog		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled russia
		and I_NumberOfSettlements russia > 0
		and I_EventCounter SupportCounter = 45
		log ------ spawn fleet for russia
		spawn_army
			faction russia
			character random_name, admiral, age 20, x 219, y 284
			unit	ladya		exp 2 armour 0 weapon_lvl 0
			unit	ladya		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled venice
		and I_NumberOfSettlements venice > 0
		and I_EventCounter SupportCounter = 50
		log ------ spawn fleet for venice
		spawn_army
			faction venice
			character random_name, admiral, age 20, x 187, y 155
			unit	galley		exp 2 armour 0 weapon_lvl 0
			unit	galley		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled sicily
		and I_NumberOfSettlements sicily > 0
		and I_EventCounter SupportCounter = 55
		log ------ spawn fleet for sicily
		spawn_army
			faction sicily
			character random_name, admiral, age 20, x 159, y 130
			unit	galley		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled pisa
		and I_NumberOfSettlements pisa > 0
		and I_EventCounter SupportCounter = 60
		log ------ spawn fleet for pisa
		spawn_army
			faction pisa
			character random_name, admiral, age 20, x 132, y 149
			unit	galley		exp 2 armour 0 weapon_lvl 0
			unit	galley		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled byzantium
		and I_NumberOfSettlements byzantium > 0
		and I_EventCounter SupportCounter = 65
		log ------ spawn fleet for byzantium
		spawn_army
			faction byzantium
			character random_name, admiral, age 20, x 256, y 106
			unit	dromon		exp 2 armour 0 weapon_lvl 0
			unit	dromon		exp 2 armour 0 weapon_lvl 0
			unit	dromon		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled egypt
		and I_NumberOfSettlements egypt > 0
		and I_EventCounter SupportCounter = 70
		log ------ spawn fleet for egypt
		spawn_army
			faction egypt
			character random_name, admiral, age 20, x 310, y 81
			unit	dhow		exp 2 armour 0 weapon_lvl 0
			unit	dhow		exp 2 armour 0 weapon_lvl 0
			unit	dhow		exp 2 armour 0 weapon_lvl 0
		end
	end_if

	if I_IsFactionAIControlled moors
		and I_NumberOfSettlements moors > 0
		and I_EventCounter SupportCounter = 75
		log ------ spawn fleet for moors
		spawn_army
			faction moors
			character random_name, admiral, age 20, x 6, y 92
			unit	dhow		exp 2 armour 0 weapon_lvl 0
			unit	dhow		exp 2 armour 0 weapon_lvl 0
			unit	dhow		exp 2 armour 0 weapon_lvl 0
		end
	end_if
	log ------ script end
end_monitor


;======================================================================================================
;-------- Additional General if there're Too Few
;======================================================================================================
; if a faction has few generals (3 or fewer) then every 20 years it can get 2 scripted generals added into family
; I_NumberOfHeirs - counts all named characters, not only in the family

declare_counter heir_venice
set_counter heir_venice 0
declare_counter heir_sicily
set_counter heir_sicily 0
declare_counter heir_abbasid
set_counter heir_abbasid 0
declare_counter heir_pisa
set_counter heir_pisa 0
; declare_counter heir_papal_states		; not used right now for papal states --- Belovese
; set_counter heir_papal_states 0
declare_counter heir_denmark
set_counter heir_denmark 0
declare_counter heir_egypt
set_counter heir_egypt 0
declare_counter heir_scotland
set_counter heir_scotland 0
declare_counter heir_cumans
set_counter heir_cumans 0
declare_counter heir_mongols
set_counter heir_mongols 0
declare_counter heir_turks
set_counter heir_turks 0
declare_counter heir_rum
set_counter heir_rum 0
declare_counter heir_france
set_counter heir_france 0
declare_counter heir_hre
set_counter heir_hre 0
declare_counter heir_england
set_counter heir_england 0
declare_counter heir_portugal
set_counter heir_portugal 0
declare_counter heir_poland
set_counter heir_poland 0
declare_counter heir_byzantium
set_counter heir_byzantium 0
declare_counter heir_moors
set_counter heir_moors 0
declare_counter heir_russia
set_counter heir_russia 0
declare_counter heir_spain
set_counter heir_spain 0
declare_counter heir_hungary
set_counter heir_hungary 0
declare_counter heir_aragon
set_counter heir_aragon 0
declare_counter heir_lithuania
set_counter heir_lithuania 0
declare_counter heir_kievan_rus
set_counter heir_kievan_rus 0
declare_counter heir_serbia
set_counter heir_serbia 0
declare_counter heir_georgia
set_counter heir_georgia 0
declare_counter heir_norway
set_counter heir_norway 0
declare_counter heir_jerusalem
set_counter heir_jerusalem 0
declare_counter heir_zengid
set_counter heir_zengid 0
declare_counter heir_reset
set_counter heir_reset 0

monitor_event FactionTurnStart FactionType slave

	log --- script start : Additional generals
	inc_counter heir_reset 1

	if I_CompareCounter heir_reset > 39
		log ------ reset counters
		set_counter heir_venice 0
		set_counter heir_sicily 0
		set_counter heir_abbasid 0
		set_counter heir_pisa 0
		; set_counter heir_papal_states 0	; not used right now --- Belovese
		set_counter heir_denmark 0
		set_counter heir_egypt 0
		set_counter heir_scotland 0
		set_counter heir_cumans 0
		set_counter heir_mongols 0
		set_counter heir_turks 0
		set_counter heir_rum 0
		set_counter heir_france 0
		set_counter heir_hre 0
		set_counter heir_england 0
		set_counter heir_portugal 0
		set_counter heir_poland 0
		set_counter heir_byzantium 0
		set_counter heir_moors 0
		set_counter heir_russia 0
		set_counter heir_spain 0
		set_counter heir_hungary 0
		set_counter heir_aragon 0
		set_counter heir_lithuania 0
		set_counter heir_kievan_rus 0
		set_counter heir_serbia 0
		set_counter heir_georgia 0
		set_counter heir_norway 0
		set_counter heir_jerusalem 0
		set_counter heir_zengid 0

		set_counter heir_reset 0

	end_if

	if I_IsFactionAIControlled england
		and I_NumberOfHeirs england < 4
		and I_CompareCounter heir_england < 2
		and I_NumberOfSettlements england > 0
		log ------ spawn additional general for england
		spawn_army
			faction england
			character	random_name, named character, age 20, x 68, y 215, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_English 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_england 1
	end_if

	if I_IsFactionAIControlled scotland
		and I_NumberOfHeirs scotland < 4
		and I_CompareCounter heir_scotland < 2
		and I_NumberOfSettlements scotland > 0
		log ------ spawn additional general for scotland
		spawn_army
			faction scotland
			character	random_name, named character, age 20, x 44, y 248, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Scottish 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_scotland 1
	end_if

	if I_IsFactionAIControlled denmark
		and I_NumberOfHeirs denmark < 4
		and I_CompareCounter heir_denmark < 2
		and I_NumberOfSettlements denmark > 0
		log ------ spawn additional general for denmark
		spawn_army
			faction denmark
			character	random_name, named character, age 20, x 176, y 248, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Danish 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_denmark 1
	end_if

	if I_IsFactionAIControlled norway	;updated by Lifthrasir May 2013
		and I_NumberOfHeirs norway < 4
		and I_CompareCounter heir_norway < 2
		and I_NumberOfSettlements norway > 0
		log ------ spawn additional general for norway
		spawn_army
			faction norway
			character	random_name, named character, age 20, x 139, y 276, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Norwegian 1
			unit	Royal Hirdsmen		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_norway 1
	end_if

	if I_IsFactionAIControlled france
		and I_NumberOfHeirs france < 4
		and I_CompareCounter heir_france < 2
		and I_NumberOfSettlements france > 0
		log ------ spawn additional general for france
		spawn_army
			faction france
			character	random_name, named character, age 20, x 95, y 191, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_French 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_france 1
	end_if

	if I_IsFactionAIControlled hre
		and I_NumberOfHeirs hre < 4
		and I_CompareCounter heir_hre < 2
		and I_NumberOfSettlements hre > 0
		log ------ spawn additional general for hre
		spawn_army
			faction hre
			character	random_name, named character, age 20, x 144, y 208, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_HRE 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_hre 1
	end_if

	if I_IsFactionAIControlled abbasid
		and I_NumberOfHeirs abbasid < 4
		and I_CompareCounter heir_abbasid < 2
		and I_NumberOfSettlements abbasid > 0
		log ------ spawn additional general for abbasid
		spawn_army
			faction abbasid
			character	random_name, named character, age 20, x 405, y 62, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Abbasid 1
			unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_abbasid 1
	end_if

	if I_IsFactionAIControlled pisa
		and I_NumberOfHeirs pisa < 4
		and I_CompareCounter heir_pisa < 2
		and I_NumberOfSettlements pisa > 0
		log ------ spawn additional general for pisa
		spawn_army
			faction pisa
			character	random_name, named character, age 20, x 157, y 156, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Pisan 1
			unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_pisa 1
	end_if

	if I_IsFactionAIControlled aragon
		and I_NumberOfHeirs aragon < 4
		and I_CompareCounter heir_aragon < 2
		and I_NumberOfSettlements aragon > 0
		log ------ spawn additional general for aragon
		spawn_army
			faction aragon
			character	random_name, named character, age 20, x 59, y 155, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Aragonese 1
			unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_aragon 1
	end_if

	if I_IsFactionAIControlled spain
		and I_NumberOfHeirs spain < 4
		and I_CompareCounter heir_spain < 2
		and I_NumberOfSettlements spain > 0
		log ------ spawn additional general for spain
		spawn_army
			faction spain
			character	random_name, named character, age 20, x 46, y 152, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Spanish 1
			unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_spain 1
	end_if

	if I_IsFactionAIControlled portugal
		and I_NumberOfHeirs portugal < 4
		and I_CompareCounter heir_portugal < 2
		and I_NumberOfSettlements portugal > 0
		log ------ spawn additional general for portugal
		spawn_army
			faction portugal
			character	random_name, named character, age 20, x 26, y 145, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Portuguese 1
			unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_portugal 1
	end_if

	if I_IsFactionAIControlled venice
		and I_NumberOfHeirs venice < 4
		and I_CompareCounter heir_venice < 2
		and I_NumberOfSettlements venice > 0
		log ------ spawn additional general for venice
		spawn_army
			faction venice
			character	random_name, named character, age 20, x 178, y 171, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Venetian 1
			unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_venice 1
	end_if

	if I_IsFactionAIControlled sicily
		and I_NumberOfHeirs sicily < 4
		and I_CompareCounter heir_sicily < 2
		and I_NumberOfSettlements sicily > 0
		log ------ spawn additional general for sicily
		spawn_army
			faction sicily
			character	random_name, named character, age 20, x 183, y 112, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Sicilian 1
			unit	SE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_sicily 1
	end_if

	if I_IsFactionAIControlled poland
		and I_NumberOfHeirs poland < 4
		and I_CompareCounter heir_poland < 2
		and I_NumberOfSettlements poland > 0
		log ------ spawn additional general for poland
		spawn_army
			faction poland
			character	random_name, named character, age 20, x 216, y 219, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Polish 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_poland 1
	end_if

	if I_IsFactionAIControlled hungary
		and I_NumberOfHeirs hungary < 4
		and I_CompareCounter heir_hungary < 2
		and I_NumberOfSettlements hungary > 0
		log ------ spawn additional general for hungary
		spawn_army
			faction hungary
			character	random_name, named character, age 20, x 213, y 180, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Hungarian 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_hungary 1
	end_if

	if I_IsFactionAIControlled kievan_rus
		and I_NumberOfHeirs kievan_rus < 4
		and I_CompareCounter heir_kievan_rus < 2
		and I_NumberOfSettlements kievan_rus > 0
		log ------ spawn additional general for kievan_rus
		spawn_army
			faction kievan_rus
			character	random_name, named character, age 20, x 308, y 210, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Kievan 1
			unit	EE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_kievan_rus 1
	end_if

	if I_IsFactionAIControlled russia
		and I_NumberOfHeirs russia < 4
		and I_CompareCounter heir_russia < 2
		and I_NumberOfSettlements russia > 0
		log ------ spawn additional general for russia
		spawn_army
			faction russia
			character	random_name, named character, age 20, x 304, y 273, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Russian 1
			unit	EE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_russia 1
	end_if

	if I_IsFactionAIControlled byzantium
		and I_NumberOfHeirs byzantium < 4
		and I_CompareCounter heir_byzantium < 2
		and I_NumberOfSettlements byzantium > 0
		log ------ spawn additional general for byzantium
		spawn_army
			faction byzantium
			character	random_name, named character, age 20, x 236, y 115, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Greek 1
			unit	Greek Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_byzantium 1
	end_if

	if I_IsFactionAIControlled lithuania
		and I_NumberOfHeirs lithuania < 4
		and I_CompareCounter heir_lithuania < 2
		and I_NumberOfSettlements lithuania > 0
		log ------ spawn additional general for lithuania
		spawn_army
			faction lithuania
			character	random_name, named character, age 20, x 251, y 247, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Lithuanian 1
			unit	Lith Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_lithuania 1
	end_if

	if I_IsFactionAIControlled serbia
		and I_NumberOfHeirs serbia < 4
		and I_CompareCounter heir_serbia < 2
		and I_NumberOfSettlements serbia > 0
		log ------ spawn additional general for serbia
		spawn_army
			faction serbia
			character	random_name, named character, age 20, x 220, y 159, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Serbian 1
			unit	EE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_serbia 1
	end_if

	if I_IsFactionAIControlled jerusalem
		and I_NumberOfHeirs jerusalem < 4
		and I_CompareCounter heir_jerusalem < 2
		and I_NumberOfSettlements jerusalem > 0
		log ------ spawn additional general for jerusalem
		spawn_army
			faction jerusalem
			character	random_name, named character, age 20, x 339, y 78, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Jerusalem 1
			unit	NE Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_jerusalem 1
	end_if

	if I_IsFactionAIControlled turks
		and I_NumberOfHeirs turks < 4
		and I_CompareCounter heir_turks < 2
		and I_NumberOfSettlements turks > 0
		log ------ spawn additional general for turks
		spawn_army
			faction turks
			character	random_name, named character, age 20, x 460, y 92, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Turkish 1
			unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_turks 1
	end_if

	if I_IsFactionAIControlled rum
		and I_NumberOfHeirs rum < 4
		and I_CompareCounter heir_rum < 2
		and I_NumberOfSettlements rum > 0
		log ------ spawn additional general for rum
		spawn_army
			faction rum
			character	random_name, named character, age 20, x 317, y 115, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Rum_Turkish 1
			unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_rum 1
	end_if

	if I_IsFactionAIControlled egypt
		and I_NumberOfHeirs egypt < 4
		and I_CompareCounter heir_egypt < 2
		and I_NumberOfSettlements egypt > 0
		log ------ spawn additional general for egypt
		spawn_army
			faction egypt
			character	random_name, named character, age 20, x 307, y 43, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Egyptian 1
			unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_egypt 1
	end_if

	if I_IsFactionAIControlled moors
		and I_NumberOfHeirs moors < 4
		and I_CompareCounter heir_moors < 2
		and I_NumberOfSettlements moors > 0
		log ------ spawn additional general for moors
		spawn_army
			faction moors
			character	random_name, named character, age 20, x 24, y 79, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Moorish 1
			unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_moors 1
	end_if

	if I_IsFactionAIControlled zengid
		and I_NumberOfHeirs zengid < 4
		and I_CompareCounter heir_zengid < 2
		and I_NumberOfSettlements zengid > 0
		log ------ spawn additional general for zengid
		spawn_army
			faction zengid
			character	random_name, named character, age 20, x 374, y 95, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Zengid 1
			unit	ME Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_zengid 1
	end_if

	if I_IsFactionAIControlled cumans
		and I_NumberOfHeirs cumans < 4
		and I_CompareCounter heir_cumans < 2
		and I_NumberOfSettlements cumans > 0
		log ------ spawn additional general for cumans
		spawn_army
			faction cumans
			character	random_name, named character, age 20, x 399, y 183, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Cumans 1
			unit	Cuman Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_cumans 1
	end_if

	if I_IsFactionAIControlled mongols
		and I_NumberOfHeirs mongols < 4
		and I_CompareCounter heir_mongols < 2
		and I_EventCounter mongols_invasion > 0
		and I_NumberOfSettlements mongols > 0
		log ------ spawn additional general for mongols
		spawn_army
			faction mongols
			character	random_name, named character, age 20, x 502, y 160, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Mamluk 1
			unit	Keshikten Bodyguard		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_mongols 1
	end_if

	if I_IsFactionAIControlled georgia
		and I_NumberOfHeirs georgia < 4
		and I_CompareCounter heir_georgia < 2
		and I_NumberOfSettlements georgia > 0
		log ------ spawn additional general for georgia
		spawn_army
			faction georgia
			character	random_name, named character, age 20, x 392, y 165, family
			traits MilitaryInclination 2 , Military_Edu 2 , NaturalMilitarySkill 2 , GoodCommander 1 , Loyal 2 , ReligionStarter 1 , BiologicalSon 1 , Handsome 6 , Intelligent 6 , Royal_Blood_Georgian 1
			unit	bodyguard georgia		exp 2 armour 0 weapon_lvl 0
		end
		inc_counter heir_georgia 1
	end_if
	log ------ script end
end_monitor
]]