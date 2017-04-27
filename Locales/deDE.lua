------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
local Apollo = require "Apollo"

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("RaidCore", "deDE", false, true)
if not L then return end

L["Start test scenario"] = "Testszenario starten"
L["Stop test scenario"] = "Testszenario stoppen"
L["Move Bars"] = "Balken bewegen"
L["Lock Bars"] = "Balken sperren"
L["Reset Bars"] = "Balken resetten"
L["csi.summon"] = "Zu deinem Gruppenmitglied teleportieren?"
L["message.summon.request"] = "%s versucht dich herbeizurufen. Versuche jetzt anzunehmen."

L["config"] = "konfig"
L["reset"] = "resetten"
L["versioncheck"] = "versionskontrolle"
L["break"] = "pause"
L["summon"] = "herbeirufen"
