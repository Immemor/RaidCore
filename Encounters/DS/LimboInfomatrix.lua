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
local mod = core:NewEncounter("LimboInfomatrix", 52, 98, 114)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Invisible Hate Unit" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Invisible Hate Unit"] = "Invisible Hate Unit",
    ["Keeper of Sands"] = "Keeper of Sands",
    ["Infomatrix Antlion"] = "Infomatrix Antlion",
    ["BEAX"] = "16623 Hostile Invisible Unit for Fields (0 hit radius) (Very Fast Move Updates) - BEAX",
    -- Cast.
    ["Exhaust"] = "Exhaust",
    ["Desiccate"] = "Desiccate",
    -- Bar and messages.
    ["Warning: Knock-Back"] = "Warning: Knock-Back",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Invisible Hate Unit"] = "Unité haineuse invisible",
    ["Keeper of Sands"] = "Gardien des sables",
    ["Infomatrix Antlion"] = "Fourmilion de l'Infomatrice",
    ["BEAX"] = "16623 Hostile Invisible Unit for Fields (0 hit radius) (Very Fast Move Updates) - BEAX",
    -- Cast.
    ["Exhaust"] = "Épuiser",
    ["Desiccate"] = "Dessécher",
    -- Bar and messages.
    ["Warning: Knock-Back"] = "Attention: Knock-Back",
})
mod:RegisterGermanLocale({
})
-- Default settings.
mod:RegisterDefaultSetting("LinePathOfInvisibleUnit")
mod:RegisterDefaultSetting("SoundDessicateInterrupt")
mod:RegisterDefaultSetting("OtherMarkerAntlion")

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Keeper of Sands"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif sName == self.L["Infomatrix Antlion"] then
        core:AddUnit(unit)
        if mod:GetSetting("OtherMarkerAntlion") then
            core:MarkUnit(unit)
        end
    elseif sName == self.L["BEAX"] then
        -- TODO: Draw 2 circles: 7.5 and 14 of radius.
        -- core:SetWorldMarker(unit:GetId(), "x", unit:GetPosition())
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["BEAX"] then
        -- core:DropWorldMarker(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Keeper of Sands"] then
        local bInRange = mod:GetDistanceBetweenUnits(GetPlayerUnit(), unit) < 40
        if bInRange then
            if castName == self.L["Desiccate"] then
                if mod:GetSetting("SoundDessicateInterrupt") then
                    core:PlaySound("Alert")
                end
            elseif castName == self.L["Exhaust"] then
                core:AddMsg("EXHAUST", self.L["Warning: Knock-Back"], 3, "Info")
            end
        end
    end
end
