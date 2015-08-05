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
local mod = core:NewEncounter("GrandWarmongerTarGresh", 52, 98, 110)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Grand Warmonger Tar'gresh" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Grand Warmonger Tar'gresh"] = "Grand Warmonger Tar'gresh",
    ["The Warmonger"] = "The Warmonger",
    -- Cast.
    ["Meteor Storm"] = "Meteor Storm",
    -- Bar and messages.
    ["STORM !!"] = "STORM !!",
    ["~METEOR STORM"] = "~METEOR STORM",
    ["Next flame of Tar'gresh to kill"] = "Next \"flame of Tar'gresh\" to kill",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Grand Warmonger Tar'gresh"] = "Grand guerroyeur Tar'gresh",
    -- Cast.
    ["Meteor Storm"] = "Pluie de météores",
    -- Bar and messages.
    ["STORM !!"] = "PLUIE !!",
    ["~METEOR STORM"] = "~PLUIE DE MÉTÉORES",
    ["Next flame of Tar'gresh to kill"] = "Prochaine \"flame of Tar'gresh\" à tuer",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Grand Warmonger Tar'gresh"] = "Großer Kriegstreiber Tar’gresh",
    -- Cast.
    ["Meteor Storm"] = "Meteorsturm",
    -- Bar and messages.
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["STORM"] = { sColor = "xkcdLightGreen" },
    ["NEXT_KILL"] = { sColor = "xkcdLightBlue" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local nGrandWarmongerTarGreshId
local nPreviousWarmongerTime
local bIsFirstFireRoom

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)

    nGrandWarmongerTarGreshId = nil
    nPreviousWarmongerTime = 0
    mod:AddTimerBar("STORM", self.L["~METEOR STORM"], 26)
    mod:AddTimerBar("NEXT_KILL", self.L["Next flame of Tar'gresh to kill"], 45)
end

function mod:OnUnitCreated(tUnit, sUnitName)
    if self.L["Grand Warmonger Tar'gresh"] == sUnitName then
        local nUnitId = tUnit:GetId()
        if nUnitId and (nGrandWarmongerTarGreshId == nil or nGrandWarmongerTarGreshId == nUnitId) then
            -- A filter is needed, because there is many unit called "Grand Warmonger Tar'gresh".
            -- Only the first is the good.
            nGrandWarmongerTarGreshId = nUnitId
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
        end
    elseif self.L["The Warmonger"] == sUnitName then
        -- A bubble have been created (twice event).
        local nCurrentTime = GetGameTime()
        if nPreviousWarmongerTime + 10 < nCurrentTime then
            nPreviousWarmongerTime = nCurrentTime
            mod:AddTimerBar("NEXT_KILL", self.L["Next flame of Tar'gresh to kill"], 55)
        end
    end
end

function mod:OnSpellCastStart(sUnitName, sCastName, tUnit)
    if self.L["Grand Warmonger Tar'gresh"]  == sUnitName then
        if self.L["Meteor Storm"] == sCastName then
            core:AddMsg("STORM", self.L["STORM !!"], 5, "RunAway")
        end
    end
end

function mod:OnSpellCastEnd(sUnitName, sCastName, tUnit)
    if self.L["Grand Warmonger Tar'gresh"]  == sUnitName then
        if self.L["Meteor Storm"] == sCastName then
            mod:AddTimerBar("STORM", self.L["~METEOR STORM"], 43)
        end
    end
end
