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
local mod = core:NewEncounter("Bio_Enhanced_Broodmother", 52, 98, 108)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Bio-Enhanced Broodmother" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Bio-Enhanced Broodmother"] = "Bio-Enhanced Broodmother",
    -- Cast
    ["Augmented Bio-Web"] = "Augmented Bio-Web",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Bio-Enhanced Broodmother"] = "Mère de couvée augmentée",
    -- Cast
    ["Augmented Bio-Web"] = "Bio-soie augmentée",
})
mod:RegisterGermanLocale({
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BIOWEB"] = { sColor = "xkcdBluishGreen" },
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
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Bio-Enhanced Broodmother"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        mod:AddTimerBar("BIOWEB", self.L["Augmented Bio-Web"], 46)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if castName == self.L["Augmented Bio-Web"] then
        mod:RemoveTimerBar("BIOWEB")
        core:PlaySound("Alert")
    end
end

function mod:OnSpellCastEnd(unitName, castName, unit)
    if castName == self.L["Augmented Bio-Web"] then
        mod:AddTimerBar("BIOWEB", self.L["Augmented Bio-Web"], 44)
    end
end
