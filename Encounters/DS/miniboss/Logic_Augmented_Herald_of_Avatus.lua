
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
local mod = core:NewEncounter("AugmentedHeraldOfAvatus", 52, 98, 111)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Augmented Herald of Avatus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Augmented Herald of Avatus"] = "Augmented Herald of Avatus",
    -- Bar and messages.
    ["CUBE SMASH"] = "CUBE SMASH",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Augmented Herald of Avatus"] = "Messager d'Avatus augmenté",
    -- Bar and messages.
    --["CUBE SMASH"] = "CUBE SMASH", -- TODO: French translation missing !!!!
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    -- Unit names.
    ["Augmented Herald of Avatus"] = "Avatus’ augmentierter Herold",
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
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)

    mod:AddTimerBar("CUBE", self.L["CUBE SMASH"], 8)
end

function mod:OnUnitCreated(unit, sName)
    if self.L["Augmented Herald of Avatus"] == sName then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    end
end

function mod:OnSpellCastStart(sName, sSpellName, tUnit)
    if self.L["Augmented Herald of Avatus"] == sName then
        if self.L["Cube Smash"] == sSpellName then
            mod:AddTimerBar("CUBE", self.L["CUBE SMASH"], 17)
        end
    end
end
