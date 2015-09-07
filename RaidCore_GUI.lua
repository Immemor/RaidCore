----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--  Description:
--
--  TODO
--
----------------------------------------------------------------------------------------------------
require "Window"
require "GameLib"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local next, pcall, assert, error = next, pcall, assert, error
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- local functions.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Public "form" functions.
----------------------------------------------------------------------------------------------------
