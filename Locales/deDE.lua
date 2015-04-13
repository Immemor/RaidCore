------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("RaidCore", "deDE", false, true)
if not L then return end

-- Zone translation. Temporary translation.
L["Elemental Vortex Alpha"] = "Elementarvortex Alpha"
L["Elemental Vortex Beta"] = "Elementarvortex Beta"
L["Elemental Vortex Delta"] = "Elementarvortex Delta"
--L["Phagetech Uplink Hub"] = "Phagetech Uplink Hub" -- 	-- TODO: German translation missing !!!!
--L["Isolation Chamber"] = "Isolation Chamber" -- 	-- TODO: German translation missing !!!!
--L["Archive Access Core"] = "Archive Access Core" -- 	-- TODO: German translation missing !!!!
--L["Augmentation Core"] = "Augmentation Core" -- 	-- TODO: German translation missing !!!!
--L["Experimentation Lab CX-33"] = "Experimentation Lab CX-33" -- 	-- TODO: German translation missing !!!!
L["Halls of the Infinite Mind"] = "Hallen des Unendlichen Geistes"
--L["Infinite Generator Core"] = "Infinite Generator Core" -- 	-- TODO: German translation missing !!!!
L["Lower Infinite Generator Core"] = "Unterer unendlicher Generatorkern"
--L["Defeat the System Daemons"] = "Defeat the System Daemons" -- 	-- TODO: German translation missing !!!!
L["The Oculus"] = "Der Oculus"
--L["Defeat Dreadphage Ohmna"] = "Defeat Dreadphage Ohmna" -- 	-- TODO: German translation missing !!!!
