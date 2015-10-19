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
local mod = core:NewEncounter("EpAirWater", 52, 98, 118)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Hydroflux", "Aileron" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Aileron",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Glacial Icestorm",
    -- Timer bars.
    ["Next middle phase"] = "Next middle phase",
    ["Next frost tombs"] = "Next frost tombs",
    ["Next icestorm"] = "Next icestorm",
    -- Message bars.
    ["ICESTORM"] = "ICESTORM",
    ["TWIRL ON YOU!"] = "TWIRL ON YOU!",
    ["TWIRL"] = "TWIRL",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Ventemort",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Tempête de neige glaciale",
    -- Timer bars.
    ["Next middle phase"] = "Prochaine phase milieu",
    ["Next frost tombs"] = "Prochain tombeau glacé",
    ["Next icestorm"] = "Prochaine tempête glaciale",
    -- Message bars.
    ["TWIRL ON YOU!"] = "TOURNOIEMENT SUR VOUS!",
    ["TWIRL"] = "TOURNOIEMENT",
    ["ICESTORM"] = "TEMPÊTE GLACIALE",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Aileron",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Frostiger Eissturm",
    -- Timer bars.
    -- Message bars.
})
-- Default settings.
mod:RegisterDefaultSetting("SoundMidphase")
mod:RegisterDefaultSetting("SoundIcestorm")
mod:RegisterDefaultSetting("SoundTwirl")
mod:RegisterDefaultSetting("SoundFrostTombsCountDown")
mod:RegisterDefaultSetting("OtherTwirlWarning")
mod:RegisterDefaultSetting("OtherTwirlPlayerMarkers")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["MIDPHASE"] = { sColor = "xkcdLavenderBlue" },
    ["TOMB"] = { sColor = "xkcdDarkishBlue" },
    ["ICESTORM"] = { sColor = "xkcdTurquoiseBlue" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local BUFFID_MOO1 = 69959
local BUFFID_MOO2 = 47075
local DEBUFFID_TWIRL = 70440

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit= GameLib.GetPlayerUnit

local nMOOCount = 0
local bIsPhase2 = false

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    nMOOCount = 0
    bIsPhase2 = false
    mod:AddTimerBar("MIDPHASE", "Next middle phase", 60, mod:GetSetting("SoundMidphase"))
    mod:AddTimerBar("TOMB", "Next frost tombs", 30, mod:GetSetting("SoundFrostTombsCountDown"))
end

function mod:OnUnitCreated(nId, tUnit, sName)
    if sName == self.L["Hydroflux"] or sName == self.L["Aileron"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Hydroflux"] == sName then
        if self.L["Tsunami"] == sCastName then
            bIsPhase2 = true
            nMOOCount = nMOOCount + 1
            mod:AddMsg("PHASE2", self.L["Tsunami"]:upper(), 5, mod:GetSetting("SoundMidphase") and "Alert")
        elseif self.L["Glacial Icestorm"] == sCastName then
            mod:AddMsg("ICESTORM", "ICESTORM", 5, mod:GetSetting("SoundIcestorm") and "RunAway")
        end
    end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
    if sName == self.L["Hydroflux"] then
        if sCastName == self.L["Tsunami"] then
            mod:AddTimerBar("MIDPHASE", "Next middle phase", 88, mod:GetSetting("SoundMidphase"))
            mod:AddTimerBar("TOMB", "Next frost tombs", 30, mod:GetSetting("SoundFrostTombsCountDown"))
        end
    end
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    if bIsPhase2 and (nSpellId == BUFFID_MOO1 or nSpellId == BUFFID_MOO2) then
        bIsPhase2 = false
        if nMOOCount == 2 then
            nMOOCount = 0
            mod:AddTimerBar("ICESTORM", "Next icestorm", 15)
        end
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    if nSpellId == DEBUFFID_TWIRL then
        if mod:GetSetting("OtherTwirlWarning") and GetPlayerUnit():GetId() == nId then
            mod:AddMsg("TWIRL", "TWIRL ON YOU!", 5, mod:GetSetting("SoundTwirl") and "Inferno")
        end
        if mod:GetSetting("OtherTwirlPlayerMarkers") then
            core:MarkUnit(tUnit, nil, self.L["TWIRL"])
        end
        core:AddUnit(tUnit)
    end
end

function mod:OnDebuffRemove(nId, nSpellId)
    if nSpellId == DEBUFFID_TWIRL then
        core:DropMark(nId)
        core:RemoveUnit(nId)
    end
end
