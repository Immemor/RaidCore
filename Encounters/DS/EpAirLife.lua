----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--   There is 2 phases in this combat, which are repeated many times.
--
--   In phase 1:
--     - Players have to avoid Wild Brambles and destroyed them with the Twirl.
--     - From second phase 1, players with thunder debuff must go under a tree which have been
--       healed.
--
--   In phase 2:
--    - Players have to jump on lights in the sky, to fall them and kill them.
--    - At the end of this phase, all light not destroyed will do some global dommage.
--
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
    ["Enrage"] = "Enrage",
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
    ["Next Healing Tree"] = "Prochain Arbres à Soigner",
    ["No-Healing Debuff!"] = "Aucun-Soin Debuff!",
    ["NO HEAL DEBUFF"] = "NO HEAL",
    ["Lightning"] = "Foudre",
    ["Lightning on YOU"] = "Foudre sur VOUS",
    ["Enrage"] = "Enrage",
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
local nFirstTreeId
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
    nFirstTreeId = nil

    mod:AddTimerBar("MIDPHASE", "Middle Phase", 90, mod:GetSetting("SoundMidphaseCountDown"))
    mod:AddTimerBar("THORN", "Thorns", 20)
    mod:AddTimerBar("ENRAGE", "Enrage", 500)
end

function mod:OnUnitCreated(tUnit, sName)
    local nId = tUnit:GetId()
    local nCurrentTime = GetGameTime()

    if sName == self.L["Wild Brambles"] then
        if nLastThornsTime + 5 < nCurrentTime and nCurrentTime + 16 < nMidPhaseTime then
            nLastThornsTime = nCurrentTime
            nTwirlCount = nTwirlCount + 1
            mod:AddTimerBar("THORN", "Thorns", 15)
            if nTwirlCount % 2 == 1 then
                mod:AddTimerBar("TWIRL", "Twirl", 15)
            end
        end
    elseif sName == self.L["[DS] e395 - Air - Tornado"] then
        if not bIsMidPhase then
            bIsMidPhase = true
            nTwirlCount = 0
            nMidPhaseTime = nCurrentTime + 115
            mod:AddTimerBar("MIDEND", "Midphase Ending", 35)
            mod:AddTimerBar("THORN", "Thorns", 35)
            mod:AddTimerBar("LIFEKEEP", "Next Healing Tree", 35)
        end
    elseif sName == self.L["Life Force"] then
        if mod:GetSetting("LineLifeOrbs") then
            core:AddPixie(nId, 2, tUnit, nil, "Blue", 10, 40, 0)
        end
    elseif sName == self.L["Lifekeeper"] then
        nTreeKeeperCount = nTreeKeeperCount + 1
        if nTreeKeeperCount % 2 == 0 then
            local FirstTree_Pos = GetUnitById(nFirstTreeId):GetPosition()
            local SecondTree_Pos = GetUnitById(nId):GetPosition()
            -- Let's say the first will be the always the north.
            -- So we have only to compare the Z axis.

            local nNorthTreeId, nSouthTreeId = nFirstTreeId, nId
            if FirstTree_Pos.z > SecondTree_Pos.z then
                -- Second Tree is more on north than First Tree. Inverse them so.
                nNorthTreeId = nId
                nSouthTreeId = nFirstTreeId
            end
            table.insert(tTreeKeeperList, nNorthTreeId)
            table.insert(tTreeKeeperList, nSouthTreeId)
            local tNorthTreeUnit = GetUnitById(nNorthTreeId)
            local tSouthTreeUnit = GetUnitById(nSouthTreeId)
            core:AddUnit(tNorthTreeUnit)
            core:AddUnit(tSouthTreeUnit)
            core:MarkUnit(tNorthTreeUnit, nil, nTreeKeeperCount - 1)
            core:MarkUnit(tSouthTreeUnit, nil, nTreeKeeperCount)
            if (nTreeKeeperCount + 2) % 4 == 0 then
                local bCountDownEnable = mod:GetSetting("SoundHealingTreeCountDown")
                mod:AddTimerBar("LIFEKEEP", "Next Healing Tree", 30, bCountDownEnable)
            end
        else
            nFirstTreeId = nId
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
        mod:AddTimerBar("MIDPHASE", "Middle Phase", 90, mod:GetSetting("SoundMidphaseCountDown"))
    elseif sName == self.L["Life Force"] then
        core:DropPixie(nId)
    elseif sName == self.L["Lifekeeper"] then
        for i, nTreeId in next, tTreeKeeperList do
            if nTreeId == nId then
                table.remove(tTreeKeeperList, i)
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
            mod:AddMsg("TWIRL", "TWIRL ON YOU!", 5, sSound)
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
            mod:AddMsg("NOHEAL", "No-Healing Debuff!", 5, sSound)
        end
    elseif nSpellId == DEBUFFID_LIGHTNING_STRIKE then
        if mod:GetSetting("OtherLightningMarkers") then
            core:MarkUnit(tUnit, nil, self.L["Lightning"])
        end
        nLightningStrikeCount = nLightningStrikeCount + 1
        if mod:GetSetting("LineHealingTrees") and #tTreeKeeperList > 0 then
            local sKey = ("LIGHTNING %d"):format(nId)
            core:AddPixie(sKey, 1, tUnit, GetUnitById(tTreeKeeperList[1]), "xkcdBrightPurple", 5)
        end
        if nId == nPlayerId then
            local sSound = mod:GetSetting("SoundLightning") and "RunAway"
            mod:AddMsg("LIGHTNING", "Lightning on YOU", 5, sSound)
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
                    mod:AddMsg("BLIND", "Blinding Light", 5, sSound)
                end
            end
        end
    end
end
