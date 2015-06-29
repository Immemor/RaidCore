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
local mod = core:NewEncounter("Fully_Optimized_Canimid", 52, 98, 108)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Fully-Optimized Canimid" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Fully-Optimized Canimid"] = "Fully-Optimized Canimid",
    -- Cast
    ["Undermine"] = "Undermine",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Fully-Optimized Canimid"] = "Canimide entièrement optimisé",
    -- Cast
    ["Undermine"] = "Ébranler",
})
mod:RegisterGermanLocale({
})
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
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Fully-Optimized Canimid"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
end

function mod:OnSpellCastEnd(unitName, castName, unit)
end

function mod:OnChatDC(message)
end
