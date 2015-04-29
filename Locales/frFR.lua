------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("RaidCore", "frFR", false, true)
if not L then return end

-- Zone translation. Temporary translation.
L["Elemental Vortex Alpha"] = "Vortex élementaire Alpha"
L["Elemental Vortex Beta"] = "Vortex élementaire Bêta"
L["Elemental Vortex Delta"] = "Vortex élementaire Delta"
--L["Phagetech Uplink Hub"] = "Phagetech Uplink Hub" -- 	-- TODO: French translation missing !!!!
--L["Isolation Chamber"] = "Isolation Chamber" -- 	-- TODO: French translation missing !!!!
--L["Archive Access Core"] = "Archive Access Core" -- 	-- TODO: French translation missing !!!!
--L["Augmentation Core"] = "Augmentation Core" -- 	-- TODO: French translation missing !!!!
--L["Experimentation Lab CX-33"] = "Experimentation Lab CX-33" -- 	-- TODO: French translation missing !!!!
L["Halls of the Infinite Mind"] = "Salles de l'Esprit infini"
L["Infinite Generator Core"] = "Noyau du générateur d'infinité"
L["Lower Infinite Generator Core"] = "Noyau du générateur d'infinité inférieur"
--L["Defeat the System Daemons"] = "Defeat the System Daemons" -- 	-- TODO: French translation missing !!!!
L["The Oculus"] = "Oculus"
L["Defeat Dreadphage Ohmna"] = "Terrasser Ohmna la Terriphage"
