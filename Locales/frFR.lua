------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("RaidCore", "frFR", false, true)
if not L then return end

L["Start test scenario"] = "Début du scénario de test"
L["Stop test scenario"] = "Fin du scénario de test"
L["Move Bars"] = "Déplacer Barres"
L["Lock Bars"] = "Vérrouiller Barres"
L["Reset Bars"] = "Reset Barres"
L["Raid Resume"] = "Raid Reprise"
