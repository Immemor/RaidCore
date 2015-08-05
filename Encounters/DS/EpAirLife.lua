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
mod:RegisterDefaultSetting("LineVisceralus")
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
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit= GameLib.GetPlayerUnit

local nLightningStrikeCount
local nTreeKeeperCount
local tTreeKeeperList
local nLastThornsTime = 0
local bIsMidPhase
local nMidPhaseTime
local nTwirlCount

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffAdd", self)
    Apollo.RegisterEventHandler("DEBUFF_DEL", "OnDebuffDel", self)

    nLastThornsTime = 0
    bIsMidPhase = false
    nMidPhaseTime = GetGameTime() + 90
    nTwirlCount = 0
    nTreeKeeperCount = 0
    tTreeKeeperList = {}

    mod:AddTimerBar("MIDPHASE", self.L["Middle Phase"], 90, mod:GetSetting("SoundMidphaseCountDown"))
    mod:AddTimerBar("THORN", self.L["Thorns"], 20)
end

function mod:OnUnitCreated(tUnit, sName)
    local nId = tUnit:GetId()
    local nCurrentTime = GetGameTime()

    if sName == self.L["Wild Brambles"] then
        if nLastThornsTime + 5 < nCurrentTime and nCurrentTime + 16 < nMidPhaseTime then
            nLastThornsTime = nCurrentTime
            nTwirlCount = nTwirlCount + 1
            mod:AddTimerBar("THORN", self.L["Thorns"], 15)
            if nTwirlCount % 2 == 1 then
                mod:AddTimerBar("TWIRL", self.L["Twirl"], 15)
            end
        end
    elseif sName == self.L["[DS] e395 - Air - Tornado"] then
        if not bIsMidPhase then
            bIsMidPhase = true
            nTreeKeeperCount = 0
            nLightningStrikeCount = 0
            nTwirlCount = 0
            nMidPhaseTime = nCurrentTime + 115
            mod:AddTimerBar("MIDEND", self.L["Midphase Ending"], 35)
            mod:AddTimerBar("THORN", self.L["Thorns"], 35)
            mod:AddTimerBar("LIFEKEEP", self.L["Next Healing Tree"], 35)
        end
    elseif sName == self.L["Life Force"] then
        if mod:GetSetting("LineLifeOrbs") then
            core:AddPixie(nId, 2, tUnit, nil, "Blue", 10, 40, 0)
        end
    elseif sName == self.L["Lifekeeper"] then
        core:AddUnit(tUnit)
        nTreeKeeperCount = nTreeKeeperCount + 1
        tTreeKeeperList[nTreeKeeperCount] = nId
        if mod:GetSetting("LineHealingTrees") then
            core:AddPixie(nId, 1, GetPlayerUnit(), tUnit, "Yellow", 2)
        end
        if nTreeKeeperCount % 2 == 0 then
            local Tree1_Pos = GetUnitById(tTreeKeeperList[nTreeKeeperCount - 1]):GetPosition()
            local Tree2_Pos = GetUnitById(tTreeKeeperList[nTreeKeeperCount]):GetPosition()
            -- Let's say the first will be the always the north.
            -- So we have only to compare the Z axis.

            if Tree1_Pos.z > Tree2_Pos.z then
                -- Tree2 is more on north than Tree1.
                -- Inverse the order so.
                local copy_id = tTreeKeeperList[nTreeKeeperCount - 1]
                tTreeKeeperList[nTreeKeeperCount - 1] = tTreeKeeperList[nTreeKeeperCount]
                tTreeKeeperList[nTreeKeeperCount] = copy_id
            end
            core:MarkUnit(GetUnitById(tTreeKeeperList[nTreeKeeperCount - 1]), nil, nTreeKeeperCount - 1)
            core:MarkUnit(GetUnitById(tTreeKeeperList[nTreeKeeperCount]), nil, nTreeKeeperCount)
            if nTreeKeeperCount == 2 then
                mod:AddTimerBar("LIFEKEEP", self.L["Next Healing Tree"], 30, mod:GetSetting("SoundHealingTreeCountDown"))
            end
        end
    elseif sName == self.L["Aileron"] then
        core:AddUnit(tUnit)
        if mod:GetSetting("LineCleaveAileron") then
            core:AddPixie(tUnit:GetId(), 2, tUnit, nil, "Red", 10, 30, 0)
        end
    elseif sName == self.L["Visceralus"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        if mod:GetSetting("LineVisceralus") then
            core:AddPixie("Visceralus_1", 2, tUnit, nil, "red", 5, 30, 0)
            core:AddPixie("Visceralus_2", 2, tUnit, nil, "xkcdBarbiePink", 5, 30, 72)
            core:AddPixie("Visceralus_3", 2, tUnit, nil, "xkcdBarbiePink", 5, 30, 144)
            core:AddPixie("Visceralus_4", 2, tUnit, nil, "xkcdBarbiePink", 5, 30, 216)
            core:AddPixie("Visceralus_5", 2, tUnit, nil, "xkcdBarbiePink", 5, 30, 288)
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    local nId = unit:GetId()
    if bIsMidPhase and sName == self.L["[DS] e395 - Air - Tornado"] then
        bIsMidPhase = false
        mod:AddTimerBar("MIDPHASE", self.L["Middle Phase"], 90, mod:GetSetting("SoundMidphaseCountDown"))
    elseif sName == self.L["Life Force"] then
        core:DropPixie(nId)
    elseif sName == self.L["Lifekeeper"] then
        core:DropPixie(nId)
        for i, nTreeId in next, tTreeKeeperList do
            if nTreeId == nId then
                tTreeKeeperList[i] = nil
                break
            end
        end
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local nPlayerId = GetPlayerUnit():GetId()
    local tUnit = GetUnitById(nId)

    if nSpellId == DEBUFFID_TWIRL then
        if nId == nPlayerId and mod:GetSetting("OtherTwirlWarning") then
            local sSound = mod:GetSetting("SoundTwirl") and "Inferno"
            core:AddMsg("TWIRL", self.L["TWIRL ON YOU!"], 5, sSound)
        end

        if mod:GetSetting("OtherTwirlPlayerMarkers") then
            core:MarkUnit(tUnit, nil, self.L["Twirl"]:upper())
        end
        core:AddUnit(tUnit)
    elseif nSpellId == DEBUFFID_LIFE_FORCE_SHACKLE then
        if mod:GetSetting("OtherNoHealDebuffPlayerMarkers") then
            core:MarkUnit(tUnit, nil, self.L["NO HEAL DEBUFF"])
        end
        if nId == nPlayerId and mod:GetSetting("OtherNoHealDebuff") then
            local sSound = mod:GetSetting("SoundNoHealDebuff") and "Alarm"
            core:AddMsg("NOHEAL", self.L["No-Healing Debuff!"], 5, sSound)
        end
    elseif nSpellId == DEBUFFID_LIGHTNING_STRIKE then
        if mod:GetSetting("OtherLightningMarkers") then
            core:MarkUnit(tUnit, nil, self.L["Lightning"])
        end
        nLightningStrikeCount = nLightningStrikeCount + 1
        if mod:GetSetting("LineHealingTrees") then
            local nTreeTarget = math.floor((nLightningStrikeCount + 1) / 2)
            local sKey = ("LIGHTNING %d"):format(nId)
            core:AddPixie(sKey, 1, tUnit, GetUnitById(tTreeKeeperList[nTreeTarget]), "xkcdBrightPurple", 5)
        end
        if nId == nPlayerId then
            local sSound = mod:GetSetting("SoundLightning") and "RunAway"
            core:AddMsg("LIGHTNING", self.L["Lightning on YOU"], 5, sSound)
        end
    end
end

function mod:OnDebuffDel(nId, nSpellId)
    if nSpellId == DEBUFFID_TWIRL then
        core:DropMark(nId)
        core:RemoveUnit(nId)
    elseif nSpellId == DEBUFFID_LIFE_FORCE_SHACKLE then
        core:DropMark(nId)
    elseif nSpellId == DEBUFFID_LIGHTNING_STRIKE then
        local sKey = ("LIGHTNING %d"):format(nId)
        core:DropPixie(sKey)
        core:DropMark(nId)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Visceralus"] then
        if castName == self.L["Blinding Light"] then
            if mod:GetSetting("OtherBlindingLight") then
                if self:GetDistanceBetweenUnits(unit, GetPlayerUnit()) < 33 then
                    local sSound = mod:GetSetting("SoundBlindingLight") and "Beware"
                    core:AddMsg("BLIND", self.L["Blinding Light"], 5, sSound)
                end
            end
        end
    end
end
