----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--   TODO
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("PhageMaw", 67, 147, 149)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Phage Maw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Phage Maw"] = "Phage Maw",
    ["Detonation Bomb"] = "Detonation Bomb",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "The augmented shield has been destroyed",
    ["Phage Maw begins charging an orbital strike"] = "Phage Maw begins charging an orbital strike",
    -- Bar and messages.
    ["Bomb %u"] = "Bomb %u",
    ["BOOOM !"] = "BOOOM !",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Phage Maw"] = "Phagegueule",
    ["Detonation Bomb"] = "Bombe à détonateur",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "Le bouclier augmenté a été détruit",
    ["Phage Maw begins charging an orbital strike"] = "La Méga Gueule d'acier commence à charger une frappe orbitale",
    -- Bar and messages.
    ["Bomb %u"] = "Bombe %u",
    ["BOOOM !"] = "BOOOM !",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Phage Maw"] = "Phagenschlund",
    ["Detonation Bomb"] = "Sprengbombe",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "Der augmentierte Schild wurde zerstört",
    ["Phage Maw begins charging an orbital strike"] = "Phagenschlund beginnt einen Orbitalschlag aufzuladen",
    -- Bar and messages.
    ["Bomb %u"] = "Bombe %u",
    ["BOOOM !"] = "BOOOM !",
})
-- Default settings.
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Phage Maw"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif sName == self.L["Detonation Bomb"] then
        core:MarkUnit(unit, 1)
        core:AddUnit(unit)
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The augmented shield has been destroyed"]) then
        core:AddTimerBar("MAW1", self.L["Bomb %u"]:format(1), 20)
        core:AddTimerBar("MAW2", self.L["Bomb %u"]:format(2), 49)
        core:AddTimerBar("MAW3", self.L["Bomb %u"]:format(3), 78)
        core:AddTimerBar("PHAGEMAW", "BOOOM !", 104)
    elseif message:find(self.L["Phage Maw begins charging an orbital strike"]) then
        core:ResetMarks()
    end
end
