--[[
    Fort -> outpost (minor settlement), SSHIP version
    Ported 10 Oct 2026 from the EUR script (Horschix/Modding_DAC-EUR #35,
    eopData/eopScripts/eur/campaign/fort_settlement.lua, version 8 - its header tells what failed on the way).

    PLAYER ONLY.
    FINAL RULES (TEST = false): a general brings NEED (500) men in settler units into one of his forts; a window
    with the button "Found settlement - COST gold" appears; clicking it makes the army step out, replaces the
    fort by a town "Outpost of <region>", removes the settler units (their men become the population), charges
    COST and orders the army back in.
    TEST VERSION (TEST = true, step 1 of 2): no settlers needed and free - a general standing in a fort is
    enough. It only shows whether SSHIP copes with a second settlement inside a region.

    Never delete a fort while somebody is in it (general loses his map figure); only normal move orders work
    for a general in a fort (teleport / reposition do nothing) - EUR tests of 8 Oct 2026.

    HOW IT IS LOADED: last lines of eopData/eopScripts/luaPluginScript.lua
        require('sship.fort_settlement')
    after require('sship.main') (it wraps the draw() function defined there). Remove the line to switch it
    off. Outposts already founded stay in the save.
    Nothing here calls M2TWEOP, M2TW or ImGui while the file is loading - only inside draw().
    Game-log lines start with FORTSETT.
]]
local FS = {}
local SETT_LEVEL  = 1        -- 1 = town / wooden castle. Level 0 castle (motte and bailey) has NO map model in most
                             -- cultures of descr_cultures.txt: the dwarves got the Weathertop model for it (8 Oct)
local SETT_CASTLE = false    -- a town, not a castle (user, 8 Oct 2026)
local NAME_PREFIX = "hxsett_"
local TEST        = true     -- step 1: free, no settlers needed. Set to false for the final rules.
local COST        = 5000     -- gold for founding an outpost, charged when the town is created (user, 10 Oct 2026)
local NEED        = 500      -- settlers (men) that must be in the fort; they are removed and become the population
local SETTLER_UNITS = {      -- unit types of step 2 (one per religion group; not in the unit file yet)
    ["Catholic Settlers"] = true, ["Orthodox Settlers"] = true, ["Muslim Settlers"] = true, ["Pagan Settlers"] = true,
}
if TEST then COST, NEED = 0, 0 end

local message, messageUntil = nil, 0
local lastTileKey = nil

local function log(text)
    if type(M2TWEOP) == "table" and type(M2TWEOP.logGame) == "function" then
        M2TWEOP.logGame("FORTSETT " .. tostring(text))
    end
end

local function say(text)
    message = text
    messageUntil = os.clock() + 12
    log(text)
end

-- a wrong field name must never crash the game
local function get(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    if ok then return value end
    return nil
end

local function getTile(x, y)
    local ok, tile = pcall(function() return M2TW.stratMap.getTile(x, y) end)
    if ok then return tile end
    return nil
end

local function tileFree(x, y)
    local ok, free = pcall(function() return M2TWEOP.isTileFree(x, y) end)
    return ok and free == true
end

-- every character of every faction standing on this tile
local function charactersAt(x, y)
    local found = {}
    local campaign = get(M2TW, "campaign")
    local factions = get(campaign, "numberOfFactions")
    if type(factions) ~= "number" then return found, false end
    for f = 0, factions - 1 do
        local okF, faction = pcall(function() return campaign:getFactionByOrder(f) end)
        if okF and faction ~= nil then
            local count = get(faction, "numOfCharacters") or 0
            for i = 0, count - 1 do
                local ok, char = pcall(function() return faction:getCharacter(i) end)
                if ok and char ~= nil and get(char, "xCoord") == x and get(char, "yCoord") == y then
                    found[#found + 1] = char
                end
            end
        end
    end
    return found, true
end

local function playerFaction()
    local campaign = get(M2TW, "campaign")
    local ok, fac = pcall(function() return campaign:getPlayerFaction(0) end)
    if ok and fac ~= nil and get(fac, "isPlayerControlled") == 1 then return fac end
    local n = get(campaign, "numberOfFactions") or 0
    for f = 0, n - 1 do
        local okF, faction = pcall(function() return campaign:getFactionByOrder(f) end)
        if okF and faction ~= nil and get(faction, "isPlayerControlled") == 1 then return faction end
    end
    return nil
end

-- the fort on this tile if it belongs to the player, else nil
local function ownFort(x, y)
    local fort = get(getTile(x, y), "fort")
    if not fort then return nil end
    local owner = get(fort, "ownerFaction")
    if owner ~= nil and get(owner, "isPlayerControlled") == 1 then return fort end
    return nil
end

local function hasFort(x, y)
    local tile = getTile(x, y)
    if tile ~= nil and get(tile, "fort") then return true end
    return false
end

-- What the player is looking at. Returns state, x, y of the fort:
--   "beside" = a selected character stands next to a fort (button), "inside" = he stands in it (hint only)
local pending = {}      -- "x,y" = true: fort already removed there, settlement still to be created (this session only)

local lastInside = nil   -- { x, y }: fort the selected character was last seen in

local function selectedFortTile()
    local info = get(M2TW, "selectionInfo")
    if info == nil then return nil end
    local char = get(info, "selectedCharacter")
    if char ~= nil then
        local cx, cy = get(char, "xCoord"), get(char, "yCoord")
        if type(cx) ~= "number" or type(cy) ~= "number" then return nil end
        if ownFort(cx, cy) then
            lastInside = { cx, cy }
            return "inside", cx, cy
        end
        lastInside = nil
        for dx = -1, 1 do
            for dy = -1, 1 do
                if (dx ~= 0 or dy ~= 0) and pending[(cx + dx) .. "," .. (cy + dy)] and not hasFort(cx + dx, cy + dy) then
                    return "beside", cx + dx, cy + dy
                end
            end
        end
        return nil
    end
    -- nobody selected: the game drops the selection when an army enters a fort (test of 8 Oct 2026)
    local fortSel = get(info, "selectedFort")
    if fortSel ~= nil then
        local fx, fy = get(fortSel, "xCoord"), get(fortSel, "yCoord")
        if type(fx) == "number" and type(fy) == "number" and ownFort(fx, fy) then
            if not FS.fortSelLogged then FS.fortSelLogged = true; log("selectedFort can be read: " .. fx .. "," .. fy) end
            return "inside", fx, fy
        end
    end
    if get(info, "selectedSettlement") ~= nil then lastInside = nil; return nil end
    if lastInside ~= nil then
        if ownFort(lastInside[1], lastInside[2]) then return "inside", lastInside[1], lastInside[2] end
        lastInside = nil
    end
    return nil
end

-- free land tiles beside the fort, straight neighbours first (test of 10 Oct 2026: the first tile picked was
-- not reached, so the script now tries the next one when the army does not move)
local function freeTilesBeside(x, y)
    local list = {}
    local order = { {0,-1}, {1,0}, {0,1}, {-1,0}, {1,-1}, {1,1}, {-1,1}, {-1,-1} }
    for i = 1, #order do
        local tx, ty = x + order[i][1], y + order[i][2]
        local tile = getTile(tx, ty)
        if tileFree(tx, ty) and get(tile, "isLand") ~= 0 and get(tile, "hasCliff") ~= true then
            list[#list + 1] = { tx, ty }
        end
    end
    return list
end

-- the settler units of an army: list of units and their men
local function settlersOf(army)
    local units, men = {}, 0
    local count = get(army, "numOfUnits")
    if type(count) ~= "number" then return units, men end
    for i = 0, count - 1 do
        local ok, unit = pcall(function() return army:getUnit(i) end)
        if ok and unit ~= nil and SETTLER_UNITS[get(get(unit, "eduEntry"), "eduType")] then
            local n = get(unit, "soldierCountStratMap")
            if type(n) == "number" then
                units[#units + 1] = { unit = unit, men = n }
                men = men + n
            end
        end
    end
    return units, men
end

-- men of the settler units in the fort and the units themselves (looked up twice a second at most)
local fortInfo = { key = nil, at = 0, men = 0, units = {} }
local function fortState(x, y)
    local key, now = x .. "," .. y, os.clock()
    if fortInfo.key ~= key or now - fortInfo.at > 0.5 then
        local units, men = settlersOf(get(get(getTile(x, y), "fort"), "army"))
        fortInfo = { key = key, at = now, men = men, units = units }
    end
    return fortInfo.men, fortInfo.units
end

local function describe(chars)
    local parts = {}
    for i = 1, #chars do
        parts[#parts + 1] = tostring(get(get(chars[i], "characterRecord"), "fullName")) .. " type " .. tostring(get(chars[i], "characterType"))
    end
    return table.concat(parts, "; ")
end

-- step 3, also used alone for a tile whose fort is already gone
local function createSettlement(player, x, y)
    local name = NAME_PREFIX .. x .. "_" .. y
    local okAdd, sett = pcall(function() return player:addSettlement(x, y, name, SETT_LEVEL, SETT_CASTLE) end)
    if not okAdd or sett == nil then
        log("addSettlement gave " .. tostring(okAdd) .. " / " .. tostring(sett))
        return nil
    end
    pending[x .. "," .. y] = nil
    -- "built by" the player's faction: picks the look on the map
    local fid = get(player, "factionID")
    local okC = pcall(function() sett.creatorFactionID = fid end)
    local okS = pcall(function() sett.subFactionID = fid end)
    local shown = "Outpost"
    local region = nil
    pcall(function() region = M2TW.stratMap.getRegion(sett.regionID) end)
    local regionName = get(region, "localizedRegionName") or get(region, "localizedName")
    if type(regionName) == "string" and regionName ~= "" then shown = "Outpost of " .. regionName end
    local ok1 = pcall(function() sett.localizedName = shown end)
    local ok2 = "none"     -- EUR's marker building minor_sett does not exist in SSHIP
    local ok3 = pcall(function() sett.baseFertility = 1 end)
    local here = charactersAt(x, y)
    log("step 3 ok: " .. name .. " '" .. shown .. "' factionID " .. tostring(fid) .. " creator set " .. tostring(okC)
        .. ", subfaction set " .. tostring(okS) .. ", name set " .. tostring(ok1) .. ", minor_sett " .. tostring(ok2)
        .. ", fertility " .. tostring(ok3) .. ", minor = " .. tostring(get(sett, "isMinorSettlement"))
        .. ", population " .. tostring(get(get(sett, "settlementStats"), "population"))
        .. ", settlement army " .. tostring(get(sett, "army")) .. ", governor " .. tostring(get(sett, "governor"))
        .. ", characters on the tile: " .. #here .. " " .. describe(here))
    return shown, sett
end

local job = nil     -- founding from inside: { phase, x, y, tiles, try, deadline, nextCheck, ... }

-- a normal move order, as if the player had clicked (needs movement points)
-- fortArmy: in SSHIP's engine a general standing in a fort has no army of his own (character.army is nil,
-- log of 10 Oct 2026); the troops are the fort's army, so that one gets the order.
local function orderMove(char, tx, ty, fortArmy)
    local army = get(char, "army") or get(char, "visitingArmy") or fortArmy
    local okA, errA = false, "no army"
    if army ~= nil then okA, errA = pcall(function() army:moveTactical(tx, ty, false) end) end
    local how = "moveTactical " .. tostring(okA) .. "/" .. tostring(errA)
    if not okA then
        local okC, errC = pcall(function() char:moveToTile(tx, ty) end)
        how = how .. ", moveToTile " .. tostring(okC) .. "/" .. tostring(errC)
        okA = okC
    end
    log("order " .. tostring(get(get(char, "characterRecord"), "fullName")) .. " to " .. tx .. "," .. ty .. ": " .. how
        .. ", movePoints " .. tostring(get(char, "movePoints")))
    return okA
end

-- removes the EMPTY fort and creates the settlement; returns the shown name or nil (message already set)
local function replaceFort(player, x, y)
    local tile = getTile(x, y)
    local fortObj = tile and get(tile, "fort")
    if not fortObj then say("Failed: no fort on this tile any more."); return nil end
    local owner = get(fortObj, "ownerFaction") or get(fortObj, "faction")
    local ownerName = get(owner, "name")
    log("replace fort at " .. x .. "," .. y .. " player " .. tostring(get(player, "name")) .. ", fort owner " .. tostring(ownerName))
    local deleter = (type(ownerName) == "string") and owner or player
    local okDel, errDel = pcall(function() deleter:deleteFort(fortObj) end)
    if not okDel or hasFort(x, y) then
        say("Failed at step 2: the fort could not be removed (" .. tostring(errDel) .. ").")
        return nil
    end
    local shown, sett = createSettlement(player, x, y)
    if shown == nil then
        pending[x .. "," .. y] = true
        say("Failed at step 3: fort removed, but no settlement was created. Select an army beside the tile and press again.")
        return nil
    end
    return shown, sett
end

-- removes the settler units (collected while they stood in the fort) until NEED men are gone; they become the
-- town's population
local function settleDown(units, sett)
    if TEST then
        log("test version: no settlers removed, population stays " .. tostring(get(get(sett, "settlementStats"), "population")))
        return
    end
    local gone, killed = 0, 0
    for i = 1, #units do
        if gone >= NEED then break end
        local men = units[i].men
        local ok, err = pcall(function() units[i].unit:kill() end)
        if ok then gone = gone + men; killed = killed + 1 else log("ERROR settler unit not removed: " .. tostring(err)) end
    end
    local okP = pcall(function() sett.settlementStats.population = math.max(gone, 400) end)
    log("settlers: " .. killed .. " units / " .. gone .. " men removed, population set " .. tostring(okP)
        .. " -> " .. tostring(get(get(sett, "settlementStats"), "population")))
end

-- state "beside": the fort must be empty.
-- state "inside": the garrison gets a normal order to step one tile aside; FS.tick does the rest when it has left.
-- (Removing the fort under the garrison left the general invisible / not in the garrison, and teleport /
--  reposition never moved him - tests of 8 Oct 2026. Only normal move orders are used now.)
function FS.found(x, y, state)
    local player = playerFaction()
    if player == nil then say("Failed: player faction not found."); return end
    if job ~= nil then say("Still busy with the last founding."); return end

    if pending[x .. "," .. y] and not hasFort(x, y) then
        local shown = createSettlement(player, x, y)
        if shown then say("Settlement founded: " .. shown .. ". Walk your army in.")
        else say("Failed at step 3 again: still no settlement on that tile.") end
        return
    end
    if not hasFort(x, y) then say("Failed: no fort on this tile any more."); return end

    local inside, scanned = charactersAt(x, y)
    if not scanned then say("Failed at step 1: could not check who is in the fort."); return end

    if state ~= "inside" or #inside == 0 then say("A general must stand in the fort."); return end
    fortInfo.key = nil
    local men, units = fortState(x, y)
    if men < NEED then say("Not enough settlers in the fort: " .. men .. " of " .. NEED .. "."); return end
    local money = get(player, "money")
    if type(money) == "number" and money < COST then say("Not enough gold: founding an outpost costs " .. COST .. "."); return end

    local tiles = freeTilesBeside(x, y)
    if #tiles == 0 then say("No free tile beside the fort for the army to step on."); return end
    local fortArmy = get(get(getTile(x, y), "fort"), "army")
    log("start (inside) at " .. x .. "," .. y .. ", characters inside: " .. #inside .. " " .. describe(inside)
        .. ", fort army " .. tostring(fortArmy) .. ", free tiles beside: " .. #tiles)
    for i = 1, #inside do orderMove(inside[i], tiles[1][1], tiles[1][2], fortArmy) end
    job = { phase = "out", settlers = units, chars = inside, x = x, y = y, tiles = tiles, try = 1, fortArmy = fortArmy,
            retryAt = os.clock() + 3, deadline = os.clock() + 3 * #tiles + 3, nextCheck = os.clock() + 0.5 }
    say("The army steps out of the fort ...")
end

-- characters of the list that stand within two tiles of x, y (but not on it)
local function besideOf(chars, x, y)
    local found = {}
    for i = 1, #chars do
        local cx, cy = get(chars[i], "xCoord"), get(chars[i], "yCoord")
        if type(cx) == "number" and type(cy) == "number" and math.abs(cx - x) <= 2 and math.abs(cy - y) <= 2
            and not (cx == x and cy == y) then
            found[#found + 1] = chars[i]
        end
    end
    return found
end

local function allAt(chars, x, y)
    for i = 1, #chars do
        if not (get(chars[i], "xCoord") == x and get(chars[i], "yCoord") == y) then return false end
    end
    return true
end

-- called every frame; looks twice a second while a founding from inside is running
function FS.tick()
    if job == nil then return end
    local now = os.clock()
    if now < job.nextCheck then return end
    job.nextCheck = now + 0.5
    local player = playerFaction()
    if job.phase == "out" then
        local inside = charactersAt(job.x, job.y)
        if #inside == 0 then
            local shown, sett = replaceFort(player, job.x, job.y)
            if shown == nil then job = nil; return end
            settleDown(job.settlers, sett)
            if COST > 0 then
                local okPay, errPay = pcall(function() M2TWEOP.callConsole("add_money", "-" .. tostring(COST)) end)
                log("charged " .. COST .. " gold: " .. tostring(okPay) .. " " .. tostring(errPay))
            end
            -- whoever of them stands beside the town now (the engine may have picked another tile than ordered)
            job.chars = besideOf(job.chars, job.x, job.y)
            log("walk in: " .. #job.chars .. " " .. describe(job.chars))
            if #job.chars == 0 then
                lastInside = nil
                say("Settlement founded: " .. shown .. ". Walk your army in.")
                job = nil
                return
            end
            for i = 1, #job.chars do orderMove(job.chars[i], job.x, job.y) end
            lastInside = nil
            job.phase, job.shown, job.deadline = "in", shown, now + 12
            say("Settlement founded: " .. shown .. ". The army walks in ...")
        elseif now >= job.retryAt and job.try < #job.tiles then
            -- did not move (blocked tile?): try the next tile beside the fort
            job.try = job.try + 1
            job.retryAt = now + 3
            local t = job.tiles[job.try]
            log("still in the fort, try " .. job.try .. " of " .. #job.tiles .. ": " .. describe(inside))
            for i = 1, #inside do orderMove(inside[i], t[1], t[2], job.fortArmy) end
        elseif now > job.deadline then
            log("gave up: " .. #inside .. " still in the fort " .. describe(inside))
            job = nil
            say("The army did not leave the fort (no movement left?). Nothing was changed - try again next turn.")
        end
    elseif job.phase == "in" then
        local outside = besideOf(job.chars, job.x, job.y)
        if allAt(job.chars, job.x, job.y) then
            local sett = get(getTile(job.x, job.y), "settlement")
            log("done: army inside, settlement army " .. tostring(get(sett, "army")) .. ", governor " .. tostring(get(sett, "governor")))
            say("Settlement founded: " .. tostring(job.shown) .. ". Your army is inside.")
            job = nil
        elseif now > job.deadline then
            log("army still beside the settlement: " .. describe(outside))
            say("Settlement founded: " .. tostring(job.shown) .. ". Your army had no movement left - walk it in next turn.")
            job = nil
        end
    end
end

function FS.draw()
    local okTick, errTick = pcall(FS.tick)
    if not okTick then
        job = nil
        say("Failed with a script error: " .. tostring(errTick))
    end
    local state, x, y = nil, nil, nil
    local okSel, st, sx, sy = pcall(selectedFortTile)
    if okSel and st ~= nil then state, x, y = st, sx, sy end
    local men = 0
    if state == "inside" then
        local okF, m = pcall(fortState, x, y)
        if okF then men = m end
        if men < NEED and job == nil then state, x, y = nil, nil, nil end        -- no settlers: no window at all
    end
    if message ~= nil and os.clock() > messageUntil then message = nil end
    if x == nil and message == nil then lastTileKey = nil; return end
    if x ~= nil then
        local key = state .. " " .. x .. "," .. y
        if key ~= lastTileKey then lastTileKey = key; log("window shown: " .. key) end
    end

    local width  = (type(SCREEN) == "table" and type(SCREEN.width) == "number" and SCREEN.width > 0) and SCREEN.width or 1920
    local height = (type(SCREEN) == "table" and type(SCREEN.height) == "number" and SCREEN.height > 0) and SCREEN.height or 1080
    local label = (TEST and "Found settlement (test, free)" or ("Found settlement - " .. COST .. " gold"))
    local clicked, began = false, false
    local okDraw, errDraw = pcall(function()
        -- placed once; the window has a title bar and can be dragged
        ImGui.SetNextWindowPos(width * 0.36, height * 0.55, ImGuiCond.FirstUseEver)
        ImGui.SetNextWindowBgAlpha(0.9)
        ImGui.Begin("Found an outpost", true, ImGuiWindowFlags.AlwaysAutoResize)
        began = true
        if state == "beside" then
            if ImGui.Button("Found settlement", 260, 40) then clicked = true end
        elseif state == "inside" and job == nil then
            local money = get(playerFaction(), "money")
            if type(money) == "number" and money < COST then
                ImGui.Text(label)
                ImGui.Text("Not enough gold.")
            else
                if ImGui.Button(label, 360, 40) then clicked = true end
            end
        end
        if message ~= nil then ImGui.Text(message) end
    end)
    if began then pcall(function() ImGui.End() end) end
    if not okDraw and not FS.drawErrorLogged then
        FS.drawErrorLogged = true
        log("ERROR while drawing: " .. tostring(errDraw))
    end
    if clicked and x ~= nil then
        local ok, err = pcall(FS.found, x, y, state)
        if not ok then say("Failed with a script error: " .. tostring(err)) end
    end
end

if not FS.installed then
    FS.installed = true
    local previous = _G["draw"]
    _G["draw"] = function(pDevice)
        if previous then previous(pDevice) end      -- SSHIP's own draw() in sship/main.lua
        local ok, err = pcall(FS.draw)
        if not ok and not FS.errorLogged then
            FS.errorLogged = true
            log("ERROR in draw: " .. tostring(err))
        end
    end
end

FortSettlement = FS

return FS
