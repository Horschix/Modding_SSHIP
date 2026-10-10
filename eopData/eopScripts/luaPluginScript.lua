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
