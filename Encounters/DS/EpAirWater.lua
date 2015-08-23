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
    -- Bar and messages.
    ["MOO !"] = "MOO !",
    ["MOO PHASE"] = "MOO PHASE",
    ["ICESTORM"] = "ICESTORM",
    ["~Middle Phase"] = "~Middle Phase",
    ["~Frost Tombs"] = "~Frost Tombs",
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
    -- Bar and messages.
    --["MOO !"] = "MOO !", -- TODO: French translation missing !!!!
    ["MOO PHASE"] = "MOO PHASE",
    --["ICESTORM"] = "ICESTORM", -- TODO: French translation missing !!!!
    --["~Middle Phase"] = "~Middle Phase", -- TODO: French translation missing !!!!
    --["~Frost Tombs"] = "~Frost Tombs", -- TODO: French translation missing !!!!
    --["TWIRL ON YOU!"] = "TWIRL ON YOU!", -- TODO: French translation missing !!!!
    --["TWIRL"] = "TWIRL", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Aileron",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Frostiger Eissturm",
    -- Bar and messages.
    --["MOO !"] = "MOO !", -- TODO: German translation missing !!!!
    --["MOO PHASE"] = "MOO PHASE", -- TODO: German translation missing !!!!
    --["ICESTORM"] = "ICESTORM", -- TODO: German translation missing !!!!
    --["~Middle Phase"] = "~Middle Phase", -- TODO: German translation missing !!!!
    --["~Frost Tombs"] = "~Frost Tombs", -- TODO: German translation missing !!!!
    --["TWIRL ON YOU!"] = "TWIRL ON YOU!", -- TODO: German translation missing !!!!
    --["TWIRL"] = "TWIRL", -- TODO: German translation missing !!!!
})
-- Default settings.
mod:RegisterDefaultSetting("SoundMidphase")
mod:RegisterDefaultSetting("SoundIcestorm")
mod:RegisterDefaultSetting("SoundTwirl")
mod:RegisterDefaultSetting("SoundMoO")
mod:RegisterDefaultSetting("SoundFrostTombsCountDown")
mod:RegisterDefaultSetting("OtherTwirlWarning")
mod:RegisterDefaultSetting("OtherTwirlPlayerMarkers")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["MIDPHASE"] = { sColor = "xkcdLavenderBlue" },
    ["TOMB"] = { sColor = "xkcdDarkishBlue" },
    ["MOO"] = { sColor = "xkcdGreenishBlue" },
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
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("BUFF_ADD", "OnBuffAdd", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffAdd", self)
    Apollo.RegisterEventHandler("DEBUFF_DEL", "OnDebuffDel", self)

    nMOOCount = 0
    bIsPhase2 = false
    mod:AddTimerBar("MIDPHASE", "Middle Phase", 60, mod:GetSetting("SoundMidphase"))
    mod:AddTimerBar("TOMB", "~Frost Tombs", 30, mod:GetSetting("SoundFrostTombsCountDown"))
end

function mod:OnUnitCreated(tUnit, sName)
    if sName == self.L["Hydroflux"] or sName == self.L["Aileron"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Hydroflux"] then
        if castName == self.L["Tsunami"] then
            bIsPhase2 = true
            nMOOCount = nMOOCount + 1
            mod:AddMsg("PHASE2", self.L["Tsunami"]:upper(), 5, mod:GetSetting("SoundMidphase") and "Alert")
        elseif castName == self.L["Glacial Icestorm"] then
            mod:AddMsg("ICESTORM", "ICESTORM", 5, mod:GetSetting("SoundIcestorm") and "RunAway")
        end
    end
end

function mod:OnSpellCastEnd(unitName, castName)
    if unitName == self.L["Hydroflux"] then
        if castName == self.L["Tsunami"] then
            mod:AddTimerBar("MIDPHASE", "~Middle Phase", 88, mod:GetSetting("SoundMidphase"))
            mod:AddTimerBar("TOMB", "~Frost Tombs", 30, mod:GetSetting("SoundFrostTombsCountDown"))
        end
    end
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    if bIsPhase2 and (nSpellId == BUFFID_MOO1 or nSpellId == BUFFID_MOO2) then
        bIsPhase2 = false
        mod:AddMsg("MOO", "MOO !", 5, mod:GetSetting("SoundMoO") and "Info", "Blue")
        mod:AddTimerBar("MOO", "MOO PHASE", 10, mod:GetSetting("SoundMoO"))
        if nMOOCount == 2 then
            nMOOCount = 0
            mod:AddTimerBar("ICESTORM", "ICESTORM", 15)
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

function mod:OnDebuffDel(nId, nSpellId)
    if nSpellId == DEBUFFID_TWIRL then
        core:DropMark(nId)
        core:RemoveUnit(nId)
    end
end
