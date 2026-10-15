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

-- Mongols convert to Islam at turn 340 (Modding_SSHIP, 15 Oct 2026).
-- Must stay AFTER require('sship.main'). To switch it off, delete the next line.
require('sship.mongol_islam')
