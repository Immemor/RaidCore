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
local mod = core:NewEncounter("EpAirLife", 52, 98, 119)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Aileron", "Visceralus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Visceralus"] = "Visceralus",
    ["Aileron"] = "Aileron",
    ["Wild Brambles"] = "Wild Brambles",
    ["[DS] e395 - Air - Tornado"] = "[DS] e395 - Air - Tornado",
    ["Life Force"] = "Life Force",
    ["Lifekeeper"] = "Lifekeeper",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blinding Light",
    -- Bar and messages.
    ["TWIRL ON YOU!"] = "TWIRL ON YOU!",
    ["Thorns"] = "Thorns",
    ["Twirl"] = "Twirl",
    ["Midphase Ending"] = "Midphase Ending",
    ["Middle Phase"] = "Middle Phase",
    ["Next Healing Tree"] = "Next Healing Tree",
    ["No-Healing Debuff!"] = "No-Healing Debuff!",
    ["NO HEAL DEBUFF"] = "NO HEAL",
    ["Lightning"] = "Lightning",
    ["Lightning on YOU"] = "Lightning on YOU",
    ["Recently Saved!"] = "Recently Saved!",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Visceralus"] = "Visceralus",
    ["Aileron"] = "Ventemort",
    ["Wild Brambles"] = "Ronces sauvages",
    ["[DS] e395 - Air - Tornado"] = "[DS] e395 - Air - Tornado",
    ["Life Force"] = "Force vitale",
    ["Lifekeeper"] = "Garde-vie",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Lumière aveuglante",
    -- Bar and messages.
    ["TWIRL ON YOU!"] = "TOURNOIEMENT SUR VOUS!",
    ["Thorns"] = "Épines",
    ["Twirl"] = "Tournoiement",
    ["Midphase Ending"] = "Phase Milieu Fin",
    ["Middle Phase"] = "Phase Milieu",
    --["Next Healing Tree"] = "Next Healing Tree", -- TODO: French translation missing !!!!
    --["No-Healing Debuff!"] = "No-Healing Debuff!", -- TODO: French translation missing !!!!
    ["NO HEAL DEBUFF"] = "NO HEAL",
    ["Lightning"] = "Foudre",
    --["Lightning on YOU"] = "Lightning on YOU", -- TODO: French translation missing !!!!
    --["Recently Saved!"] = "Recently Saved!", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Visceralus"] = "Viszeralus",
    ["Aileron"] = "Aileron",
    ["Wild Brambles"] = "Wilde Brombeeren",
    --["[DS] e395 - Air - Tornado"] = "[DS] e395 - Air - Tornado", -- TODO: German translation missing !!!!
    ["Life Force"] = "Lebenskraft",
    ["Lifekeeper"] = "Lebensbewahrer",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blendendes Licht",
    -- Bar and messages.
    --["TWIRL ON YOU!"] = "TWIRL ON YOU!", -- TODO: German translation missing !!!!
    ["Thorns"] = "Dornen",
    ["Twirl"] = "Wirbel",
    --["Midphase Ending"] = "Midphase Ending", -- TODO: German translation missing !!!!
    --["Middle Phase"] = "Middle Phase", -- TODO: German translation missing !!!!
    --["Next Healing Tree"] = "Next Healing Tree", -- TODO: German translation missing !!!!
    --["No-Healing Debuff!"] = "No-Healing Debuff!", -- TODO: German translation missing !!!!
    --["NO HEAL DEBUFF"] = "NO HEAL", -- TODO: German translation missing !!!!
    ["Lightning"] = "Blitz",
    --["Lightning on YOU"] = "Lightning on YOU", -- TODO: German translation missing !!!!
    --["Recently Saved!"] = "Recently Saved!", -- TODO: German translation missing !!!!
})
-- Default settings.
mod:RegisterDefaultSetting("LineLifeOrbs")
mod:RegisterDefaultSetting("LineHealingTrees")
mod:RegisterDefaultSetting("LineCleaveAileron")
mod:RegisterDefaultSetting("SoundHealingTreeCountDown")
mod:RegisterDefaultSetting("SoundMidphaseCountDown")
mod:RegisterDefaultSetting("SoundNoHealDebuff")
mod:RegisterDefaultSetting("SoundLightning")
mod:RegisterDefaultSetting("SoundTwirl")
mod:RegisterDefaultSetting("SoundBlindingLight")
mod:RegisterDefaultSetting("OtherTwirlWarning")
mod:RegisterDefaultSetting("OtherTwirlPlayerMarkers")
mod:RegisterDefaultSetting("OtherNoHealDebuffPlayerMarkers")
mod:RegisterDefaultSetting("OtherNoHealDebuff")
mod:RegisterDefaultSetting("OtherLightningMarkers")
mod:RegisterDefaultSetting("OtherBlindingLight")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["THORN"] = { sColor = "xkcdBluegreen" },
    ["MIDEND"] = { sColor = "xkcdDarkgreen" },
    ["LIFEKEEP"] = { sColor = "xkcdAvocadoGreen" },
    ["TWIRL"] = { sColor = "xkcdBluegreen" },
    ["MIDPHASE"] = { sColor = "xkcdBluePurple" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_TWIRL = 70440
local DEBUFFID_LIFE_FORCE_SHACKLE = 74366
local DEBUFFID_LIGHTNING_STRIKE = 74485

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local last_thorns = 0
local last_twirl = 0
local midphase = false
local myName
local CheckTwirlTimer = nil
local twirl_units = {}
local twirlCount = 0

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
    Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end

function mod:OnReset()
    last_thorns = 0
    last_twirl = 0
    midphase = false
    if CheckTwirlTimer then
        self:CancelTimer(CheckTwirlTimer)
    end
    twirl_units = {}
    twirlCount = 0
end

function mod:OnUnitCreated(unit, sName)
    local eventTime = GameLib.GetGameTime()
    if sName == self.L["Wild Brambles"] and eventTime > last_thorns + 1 and eventTime + 16 < midphase_start then
        last_thorns = eventTime
        twirlCount = twirlCount + 1
        mod:AddTimerBar("THORN", "Thorns", 15)
        if twirlCount == 1 then
            mod:AddTimerBar("TWIRL", "Twirl", 15)
        elseif twirlCount % 2 == 1 then
            mod:AddTimerBar("TWIRL", "Twirl", 15)
        end
    elseif not midphase and sName == self.L["[DS] e395 - Air - Tornado"] then
        midphase = true
        twirlCount = 0
        midphase_start = eventTime + 115
        mod:AddTimerBar("MIDEND", "Midphase Ending", 35)
        mod:AddTimerBar("THORN", "Thorns", 35)
        mod:AddTimerBar("LIFEKEEP", "Next Healing Tree", 35)
    elseif sName == self.L["Life Force"] and mod:GetSetting("LineLifeOrbs") then
        core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 10, 40, 0)
    elseif sName == self.L["Lifekeeper"] then
        if mod:GetSetting("LineHealingTrees") then
            core:AddPixie(unit:GetId(), 1, GameLib.GetPlayerUnit(), unit, "Yellow", 5, 10, 10)
        end
        core:AddUnit(unit)
        mod:AddTimerBar("LIFEKEEP", "Next Healing Tree", 30, mod:GetSetting("SoundHealingTreeCountDown"))
    end
end

function mod:OnUnitDestroyed(unit, sName)
    local eventTime = GameLib.GetGameTime()
    if midphase and sName == self.L["[DS] e395 - Air - Tornado"] then
        midphase = false
        mod:AddTimerBar("MIDPHASE", "Middle Phase", 90, mod:GetSetting("SoundMidphaseCountDown"))
    elseif sName == self.L["Life Force"] then
        core:DropPixie(unit:GetId())
    elseif sName == self.L["Lifekeeper"] then
        core:DropPixie(unit:GetId())
    end
end

function mod:OnDebuffApplied(unitName, splId, unit)
    local eventTime = GameLib.GetGameTime()
    local splName = GameLib.GetSpell(splId):GetName()
    if splId == DEBUFFID_TWIRL then
        if unitName == myName and mod:GetSetting("OtherTwirlWarning") then
            core:AddMsg("TWIRL", self.L["TWIRL ON YOU!"], 5, mod:GetSetting("SoundTwirl") and "Inferno")
        end

        if mod:GetSetting("OtherTwirlPlayerMarkers") then
            core:MarkUnit(unit, nil, self.L["Twirl"]:upper())
        end
        core:AddUnit(unit)
        twirl_units[unitName] = unit
        if not CheckTwirlTimer then
            CheckTwirlTimer = self:ScheduleRepeatingTimer("CheckTwirlTimer", 1)
        end
    elseif splId == DEBUFFID_LIFE_FORCE_SHACKLE then
        if mod:GetSetting("OtherNoHealDebuffPlayerMarkers") then
            core:MarkUnit(unit, nil, self.L["NO HEAL DEBUFF"])
        end
        if unitName == strMyName and mod:GetSetting("OtherNoHealDebuff") then
            core:AddMsg("NOHEAL", self.L["No-Healing Debuff!"], 5, mod:GetSetting("SoundNoHealDebuff") and "Alarm")
        end
    elseif splId == DEBUFFID_LIGHTNING_STRIKE then
        if mod:GetSetting("OtherLightningMarkers") then
            core:MarkUnit(unit, nil, self.L["Lightning"])
        end
        if unitName == strMyName then
            core:AddMsg("LIGHTNING", self.L["Lightning on YOU"], 5, mod:GetSetting("SoundLightning") and "RunAway")
        end
    end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
    local splName = GameLib.GetSpell(splId):GetName()
    if splId == DEBUFFID_TWIRL then
        core:RemoveUnit(unit:GetId())
    elseif splId == DEBUFFID_LIFE_FORCE_SHACKLE then
        core:DropMark(unit:GetId())
    elseif splId == DEBUFFID_LIGHTNING_STRIKE then
        core:DropMark(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    local eventTime = GameLib.GetGameTime()
    if unitName == self.L["Visceralus"] and castName == self.L["Blinding Light"] and mod:GetSetting("OtherBlindingLight") then
        local playerUnit = GameLib.GetPlayerUnit()
        if self:GetDistanceBetweenUnits(unit, playerUnit) < 33 then
            core:AddMsg("BLIND", self.L["Blinding Light"], 5, mod:GetSetting("SoundBlindingLight") and "Beware")
        end
    end
end

function mod:CheckTwirlTimer()
    for unitName, unit in pairs(twirl_units) do
        if unit and unit:GetBuffs() then
            local bUnitHasTwirl = false
            local debuffs = unit:GetBuffs().arHarmful
            for _, debuff in pairs(debuffs) do
                if debuff.splEffect:GetId() == DEBUFFID_TWIRL then
                    bUnitHasTwirl = true
                end
            end
            if not bUnitHasTwirl then
                -- else, if the debuff is no longer present, no need to track anymore.
                core:DropMark(unit:GetId())
                core:RemoveUnit(unit:GetId())
                twirl_units[unitName] = nil
            end
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        local eventTime = GameLib.GetGameTime()
        local playerUnit = GameLib.GetPlayerUnit()
        myName = playerUnit:GetName()

        if sName == self.L["Aileron"] then
            core:AddUnit(unit)
            if mod:GetSetting("LineCleaveAileron") then
                core:AddPixie(unit:GetId(), 2, unit, nil, "Red", 10, 30, 0)
            end
        elseif sName == self.L["Visceralus"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)

            last_thorns = 0
            last_twirl = 0
            twirl_units = {}
            CheckTwirlTimer = nil
            midphase = false
            midphase_start = eventTime + 90
            twirlCount = 0

            mod:AddTimerBar("MIDPHASE", "Middle Phase", 90, mod:GetSetting("SoundMidphaseCountDown"))
            mod:AddTimerBar("THORN", "Thorns", 20)
        end
    end
end
