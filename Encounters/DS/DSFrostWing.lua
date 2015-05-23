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
local mod = core:NewEncounter("DSFrostWing", 52, 98, 109)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Frost-Boulder Avalanche", "Frostbringer Warlock" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Frost-Boulder Avalanche",
    ["Frostbringer Warlock"] = "Frostbringer Warlock",
    -- Cast.
    ["Icicle Storm"] = "Icicle Storm",
    ["Shatter"] = "Shatter",
    ["Cyclone"] = "Cyclone",
    -- Bar and messages.
    ["CYCLONE SOON"] = "CYCLONE SOON",
    ["ICICLE"] = "ICICLE",
    ["PHASE 2 SOON"] = "PHASE 2 SOON",
    ["1ST ABILITY"] = "1ST ABILITY",
    ["2ND ABILITY"] = "2ND ABILITY",
    ["3RD ABILITY"] = "3RD ABILITY",
    ["FROST WAVE"] = "FROST WAVE",
    ["RUNNNN"] = "RUNNNN",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Avalanche cryoroc",
    ["Frostbringer Warlock"] = "Sorcier cryogène",
    -- Cast.
    ["Icicle Storm"] = "Tempête de stalactites",
    ["Shatter"] = "Fracasser",
    ["Cyclone"] = "Cyclone",
    -- Bar and messages.
    --["CYCLONE SOON"] = "CYCLONE SOON", -- TODO: French translation missing !!!!
    --["ICICLE"] = "ICICLE", -- TODO: French translation missing !!!!
    --["PHASE 2 SOON"] = "PHASE 2 SOON", -- TODO: French translation missing !!!!
    --["1ST ABILITY"] = "1ST ABILITY", -- TODO: French translation missing !!!!
    --["2ND ABILITY"] = "2ND ABILITY", -- TODO: French translation missing !!!!
    --["3RD ABILITY"] = "3RD ABILITY", -- TODO: French translation missing !!!!
    --["FROST WAVE"] = "FROST WAVE", -- TODO: French translation missing !!!!
    --["RUNNNN"] = "RUNNNN", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Frostfelsen-Lawine",
    ["Frostbringer Warlock"] = "Frostbringer-Hexenmeister",
    -- Cast.
    ["Icicle Storm"] = "Eiszapfensturm",
    ["Shatter"] = "Zerschmettern",
    ["Cyclone"] = "Wirbelsturm",
    -- Bar and messages.
    --["CYCLONE SOON"] = "CYCLONE SOON", -- TODO: German translation missing !!!!
    --["ICICLE"] = "ICICLE", -- TODO: German translation missing !!!!
    --["PHASE 2 SOON"] = "PHASE 2 SOON", -- TODO: German translation missing !!!!
    --["1ST ABILITY"] = "1ST ABILITY", -- TODO: German translation missing !!!!
    --["2ND ABILITY"] = "2ND ABILITY", -- TODO: German translation missing !!!!
    --["3RD ABILITY"] = "3RD ABILITY", -- TODO: German translation missing !!!!
    --["FROST WAVE"] = "FROST WAVE", -- TODO: German translation missing !!!!
    --["RUNNNN"] = "RUNNNN", -- TODO: German translation missing !!!!
})
mod:RegisterDefaultTimerBarConfigs({
    ["ICICLE"] = { sColor = "xkcdLightRed" },
    ["SHATTER"] = { sColor = "xkcdBluegreen" },
    ["RUN"] = { sColor = "xkcdBlue" },
    ["1ST"] = { sColor = "xkcdLightPurple" },
    ["2ND"] = { sColor = "xkcdLightPurple" },
    ["3RD"] = { sColor = "xkcdLightPurple" },
    ["WAVES"] = { sColor = "xkcdLightGreenBlue" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local icicleSpell = false

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
end

function mod:OnHealthChanged(unitName, health)
    if unitName == self.L["Frost-Boulder Avalanche"] and (health == 85 or health == 55 or health == 31) then
        core:AddMsg("CYCLONE", self.L["CYCLONE SOON"], 5, "Info", "Blue")
    elseif unitName == self.L["Frost-Boulder Avalanche"] and health == 22 then
        core:AddMsg("PHASE2", self.L["PHASE 2 SOON"], 5, "Info", "Blue")
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Frost-Boulder Avalanche"] then
        if castName == self.L["Icicle Storm"] then
            mod:RemoveTimerBar("SHATTER")
            core:AddMsg("ICICLE", self.L["ICICLE"].." !!", 5, "Alert")
            mod:AddTimerBar("ICICLE", "ICICLE", 22)
            icicleSpell = true
        elseif castName == self.L["Shatter"] then
            core:AddMsg("SHATTER", self.L["Shatter"]:upper().." !!", 5, "Alert")
            mod:AddTimerBar("SHATTER", "Shatter", 30)
        elseif castName == self.L["Cyclone"] then
            core:AddMsg("CYCLONE", self.L["Cyclone"]:upper(), 5, "RunAway")
            mod:AddTimerBar("RUN", "RUNNNN", 23, 1)
            if icicleSpell then
                mod:AddTimerBar("1ST", "1ST ABILITY", 33)
                mod:AddTimerBar("2ND", "2ND ABILITY", 40.5)
                mod:AddTimerBar("3RD", "3RD ABILITY", 48)
            else
                mod:AddTimerBar("SHATTER", "Shatter", 30)
            end
            mod:AddTimerBar("CYCLONE", "Cyclone", 90, true)
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Frost-Boulder Avalanche"] then
            icicleSpell = false
            core:AddUnit(unit)
            core:WatchUnit(unit)
            mod:AddTimerBar("ICICLE", "~" .. self.L["ICICLE"], 17)
            mod:AddTimerBar("SHATTER", "~" .. self.L["Shatter"], 30)
        elseif sName == self.L["Frostbringer Warlock"] then
            core:AddUnit(unit)
            mod:AddTimerBar("WAVES", "FROST WAVE", 30)
        end
    end
end
