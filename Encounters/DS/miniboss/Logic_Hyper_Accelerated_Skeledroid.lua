
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
local mod = core:NewEncounter("HyperAcceleratedSkeledroid", 52, 98, 111)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Hyper-Accelerated Skeledroid" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Hyper-Accelerated Skeledroid"] = "Hyper-Accelerated Skeledroid",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Hyper-Accelerated Skeledroid"] = "Crânedroïde hyper-accéléré",
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
end

function mod:OnUnitCreated(nId, unit, sName)
    if self.L["Hyper-Accelerated Skeledroid"] == sName then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    end
end
