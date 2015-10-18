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
local FROST_BOULDER_POSITION = {
    [1] = { x = 3364.5, y = -765.64, z = -3255.61 },
    [2] = { x = 3632.57, y = -745.72, z = -3375.77 },
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local icicleSpell

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    icicleSpell = false
    mod:AddTimerBar("ICICLE", "~" .. self.L["ICICLE"], 17)
    mod:AddTimerBar("SHATTER", "~" .. self.L["Shatter"], 30)
end

function mod:OnUnitCreated(tUnit, sName)
    if self.L["Frost-Boulder Avalanche"] == sName then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
    if sName == self.L["Frost-Boulder Avalanche"] then
        if nPourcent == 85 or nPourcent == 55 or nPourcent == 31 then
            mod:AddMsg("CYCLONE", "CYCLONE SOON", 5, "Info", "Blue")
        elseif nPourcent == 22 then
            mod:AddMsg("PHASE2", "PHASE 2 SOON", 5, "Info", "Blue")
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Frost-Boulder Avalanche"] == sName then
        if self.L["Icicle Storm"] == sCastName then
            mod:RemoveTimerBar("SHATTER")
            mod:AddMsg("ICICLE", self.L["ICICLE"].." !!", 5, "Alert")
            mod:AddTimerBar("ICICLE", "ICICLE", 22)
            icicleSpell = true
        elseif self.L["Shatter"] == sCastName then
            mod:AddMsg("SHATTER", self.L["Shatter"]:upper().." !!", 5, "Alert")
            mod:AddTimerBar("SHATTER", "Shatter", 30)
        elseif self.L["Cyclone"] == sCastName then
            mod:AddMsg("CYCLONE", self.L["Cyclone"]:upper(), 5, "RunAway")
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
