------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
local Apollo = require "Apollo"

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("RaidCore", "frFR", false, true)
if not L then return end

L["Start test scenario"] = "Début du scénario de test"
L["Stop test scenario"] = "Fin du scénario de test"
L["Move Bars"] = "Déplacer Barres"
L["Lock Bars"] = "Vérrouiller Barres"
L["Reset Bars"] = "Reset Barres"
L["Raid Resume"] = "Raid Reprise"
L["csi.summon"] = "Vous téléporter vers le membre du groupe ?"
L["message.summon.request"] = "%s vous demande d'accepter l'invocation. Attente d'acceptation en cours."

L["config"] = "options"
L["reset"] = "reinitialiser"
L["versioncheck"] = "versionverification"
L["break"] = "pause"
L["summon"] = "invocation"
