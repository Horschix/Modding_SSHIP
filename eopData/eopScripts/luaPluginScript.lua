---@diagnostic disable: lowercase-global
require('helpers/tableSave')
require('sship.main')

-- Uncomment to use VSCode Lua Debugger
-- json = require "helpers/dkjson"
-- local mobdebug = require "helpers/mobdebug"
-- mobdebug.start('127.0.0.1', 8818)

-- Recruitment costs population (Horschix/Modding_DAC-EUR). Must stay AFTER require('sship.main').
-- To switch it off, delete the next line.
require('sship.population_recruitment')

-- Forts can be turned into outposts (minor settlements). Must stay AFTER require('sship.main').
-- To switch it off, delete the next line.
require('sship.fort_settlement')

-- Towns and cities that already existed in 1132, added at the start of a NEW campaign (Modding_SSHIP #4).
-- Must stay AFTER require('sship.main'). To switch it off, delete the next line.
require('sship.starting_settlements')

-- Historic invasion armies for SSHIP events, first: Fourth Crusade at Zara and Constantinople (Modding_SSHIP, 15 Oct 2026).
-- Must stay AFTER require('sship.main'). To switch it off, delete the next line.
require('sship.historic_invasions')

-- Mongols (Ilkhanate) convert to Islam at turn 327 (Modding_SSHIP, 15 Oct 2026).
-- Must stay AFTER require('sship.main'). To switch it off, delete the next line.
require('sship.mongol_islam')

-- Cumans become the Golden Horde (turn 221) and turn Muslim (turn 361) (Modding_SSHIP, 15 Oct 2026).
-- Must stay AFTER require('sship.main'). To switch it off, delete the next line.
require('sship.golden_horde')

-- Supply costs of the player's armies with a turn report; switches off SSHIP's extra rebellion roll (#7, 15 Oct 2026).
-- Must stay AFTER require('sship.main'). To switch it off, delete the next line.
require('sship.army_costs')

-- TEMPORARY: logs damaged buildings + build queue of player settlements (Karahisar repair bug). Delete when done.
require('sship.building_diag')

-- Forts: 4 units free upkeep (engine setting), AI gets the 5000 fort price back (15 Oct 2026). Delete to switch off.
require('sship.fort_rules')

-- Ertugrul and Osman Gazi for Rum, House of Osman trait, Ottoman Domain (#10, 15 Oct 2026). Delete to switch off.
require('sship.ottoman_rise')

-- Sacked settlements may drop a level (25%), exterminated ones always; buildings drop with them (15 Oct 2026).
-- Delete the next line to switch it off.
require('sship.sack_downgrade')

-- Dynasties: Ayyubids / Mamluks for Egypt, Eretnids for the Zengids, and the Zengid / Abbasid / Egyptian army reforms
-- that SSHIP 0.98 lost (16 Oct 2026). Delete the next line to switch it off.
require('sship.dynasties')
