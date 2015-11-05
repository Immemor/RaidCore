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
local mod = core:NewEncounter("Logic_Guided_Rockslide", 52, 98, 108)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Logic Guided Rockslide" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Logic Guided Rockslide"] = "Logic Guided Rockslide",
    -- Cast
    ["Logic Guided Rockslide focuses on (.*)!"] = "Logic Guided Rockslide focuses on (.*)!",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Logic Guided Rockslide"] = "Éboulement guidé par la logique",
    -- Cast
    ["Logic Guided Rockslide focuses on (.*)!"] = "L'Éboulement guidé par la logique est focalisé sur (.*) !",
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
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local tRockslideUnit

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    tRockslideUnit = nil
end

function mod:OnUnitCreated(nId, unit, sName)
    if sName == self.L["Logic Guided Rockslide"] then
        tRockslideUnit = unit
        core:AddUnit(unit)
        core:WatchUnit(unit)
        core:AddPolygon("TWIRL RANGE MIN", nId, 11.2, 0, 4, "xkcdBrightPurple", 16)
    end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
    if sName == self.L["Logic Guided Rockslide"] then
        core:RemoveLineBetweenUnits("FOCUS")
        core:RemovePicture("FOCUS")
    end
end

function mod:OnDatachron(sMessage)
    local sPlayerFocus = sMessage:match(self.L["Logic Guided Rockslide focuses on (.*)!"])
    if sPlayerFocus then
        local tUnit = GetPlayerUnitByName(sPlayerFocus)
        if tUnit == GetPlayerUnit() then
            core:PlaySound("Alarm")
        end
        if tRockslideUnit then
            local nRockslideId = tRockslideUnit:GetId()
            local nId = tUnit:GetId()
            core:AddLineBetweenUnits("FOCUS", nId, nRockslideId, 4, "blue")
            core:AddPicture("FOCUS", nId, "RaidCore_Draw:Crosshair", 30)
        end
    end
end
