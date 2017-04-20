------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
local Apollo = require "Apollo"

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("RaidCore", "enUS", true, true)
if not L then return end

L["Start test scenario"] = "Start test scenario"
L["Stop test scenario"] = "Stop test scenario"
L["Move Bars"] = "Move Bars"
L["Lock Bars"] = "Lock Bars"
L["Reset Bars"] = "Reset Bars"
L["Raid Resume"] = "Raid Resume"
L["csi.summon"] = "Teleport to your group member?"
L["message.summon.request"] = "%s requested that you accept a summon. Attempting to accept now."

L["config"] = "config"
L["reset"] = "reset"
L["versioncheck"] = "versioncheck"
L["pull"] = "pull"
L["break"] = "break"
L["summon"] = "summon"
