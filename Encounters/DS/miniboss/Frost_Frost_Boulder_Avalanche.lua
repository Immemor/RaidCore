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
local mod = core:NewEncounter("FrostBoulderAvalanche", 52, 98, 109)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Frost-Boulder Avalanche" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Frost-Boulder Avalanche",
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
    ["RUNNNN"] = "RUNNNN",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Avalanche cryoroc",
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
    --["RUNNNN"] = "RUNNNN", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Frostfelsen-Lawine",
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
    --["RUNNNN"] = "RUNNNN", -- TODO: German translation missing !!!!
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["ICICLE"] = { sColor = "xkcdLightRed" },
    ["SHATTER"] = { sColor = "xkcdBluegreen" },
    ["RUN"] = { sColor = "xkcdBlue" },
    ["1ST"] = { sColor = "xkcdLightPurple" },
    ["2ND"] = { sColor = "xkcdLightPurple" },
    ["3RD"] = { sColor = "xkcdLightPurple" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local icicleSpell

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)

    icicleSpell = false
    mod:AddTimerBar("ICICLE", self.L["~"] .. self.L["ICICLE"], 17)
    mod:AddTimerBar("SHATTER", self.L["~"] .. self.L["Shatter"], 30)
end

function mod:OnUnitCreated(tUnit, sName)
    if self.L["Frost-Boulder Avalanche"] == sName then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnHealthChanged(sUnitName, nHealth)
    if sUnitName == self.L["Frost-Boulder Avalanche"] then
        if nHealth == 85 or nHealth == 55 or nHealth == 31 then
            core:AddMsg("CYCLONE", self.L["CYCLONE SOON"], 5, "Info", "Blue")
        elseif nHealth == 22 then
            core:AddMsg("PHASE2", self.L["PHASE 2 SOON"], 5, "Info", "Blue")
        end
    end
end

function mod:OnSpellCastStart(sUnitName, sCastName, unit)
    if self.L["Frost-Boulder Avalanche"] == sUnitName then
        if self.L["Icicle Storm"] == sCastName then
            mod:RemoveTimerBar("SHATTER")
            core:AddMsg("ICICLE", self.L["ICICLE"].." !!", 5, "Alert")
            mod:AddTimerBar("ICICLE", self.L["ICICLE"], 22)
            icicleSpell = true
        elseif self.L["Shatter"] == sCastName then
            core:AddMsg("SHATTER", self.L["Shatter"]:upper().." !!", 5, "Alert")
            mod:AddTimerBar("SHATTER", self.L["Shatter"], 30)
        elseif self.L["Cyclone"] == sCastName then
            core:AddMsg("CYCLONE", self.L["Cyclone"]:upper(), 5, "RunAway")
            mod:AddTimerBar("RUN", self.L["RUNNNN"], 23, 1)
            if icicleSpell then
                mod:AddTimerBar("1ST", self.L["1ST ABILITY"], 33)
                mod:AddTimerBar("2ND", self.L["2ND ABILITY"], 40.5)
                mod:AddTimerBar("3RD", self.L["3RD ABILITY"], 48)
            else
                mod:AddTimerBar("SHATTER", self.L["Shatter"], 30)
            end
            mod:AddTimerBar("CYCLONE", self.L["Cyclone"], 90, true)
        end
    end
end
