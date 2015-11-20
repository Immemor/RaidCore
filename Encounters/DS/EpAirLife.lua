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
    ["Time to die, sapients!"] = "Time to die, sapients!",
    -- Cast.
    ["Blinding Light"] = "Blinding Light",
    -- Timer bars.
    ["Next middle phase"] = "Next middle phase",
    ["Next thorns"] = "Next thorns",
    ["Avatus incoming"] = "Avatus incoming",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["TWIRL ON YOU!"] = "TWIRL ON YOU!",
    ["Twirl"] = "Twirl",
    ["Midphase Ending"] = "Midphase Ending",
    ["Next Healing Tree"] = "Next Healing Tree",
    ["No-Healing Debuff!"] = "No-Healing Debuff!",
    ["Lightning"] = "Lightning",
    ["Lightning on %s"] = "Lightning on %s",
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
    ["Time to die, sapients!"] = "Maintenant c'est l'heure de mourir, misérables !",
    -- Cast.
    ["Blinding Light"] = "Lumière aveuglante",
    -- Timer bars.
    ["Next middle phase"] = "Prochaine phase milieu",
    ["Next thorns"] = "Prochaine épines",
    ["Avatus incoming"] = "Avatus arrivé",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["TWIRL ON YOU!"] = "TOURNOIEMENT SUR VOUS!",
    ["Twirl"] = "Tournoiement",
    ["Midphase Ending"] = "Phase Milieu Fin",
    ["Next Healing Tree"] = "Prochain Arbres à Soigner",
    ["No-Healing Debuff!"] = "Aucun-Soin Debuff!",
    ["Lightning"] = "Foudre",
    ["Lightning on %s"] = "Foudre sur %s",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Visceralus"] = "Viszeralus",
    ["Aileron"] = "Aileron",
    ["Wild Brambles"] = "Wilde Brombeeren",
    ["Life Force"] = "Lebenskraft",
    ["Lifekeeper"] = "Lebensbewahrer",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blendendes Licht",
    -- Timer bars.
    -- Message bars.
    ["Twirl"] = "Wirbel",
    ["Lightning"] = "Blitz",
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
mod:RegisterDefaultSetting("SoundLightningOnYou")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["THORN"] = { sColor = "xkcdBluegreen" },
    ["MIDEND"] = { sColor = "xkcdDarkgreen" },
    ["LIFEKEEP"] = { sColor = "xkcdAvocadoGreen" },
    ["TWIRL"] = { sColor = "xkcdBluegreen" },
    ["MIDPHASE"] = { sColor = "xkcdBluePurple" },
    ["AVATUS_INCOMING"] = { sColor = "xkcdAmethyst" },
    ["ENRAGE"] = { sColor = "xkcdBloodRed" },
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
    nLastThornsTime = 0
    bIsMidPhase = false
    nMidPhaseTime = GetGameTime() + 90
    nTwirlCount = 0
    nTreeKeeperCount = 0
    tTreeKeeperList = {}
    nFirstTreeId = nil

    mod:AddTimerBar("MIDPHASE", "Next middle phase", 90, mod:GetSetting("SoundMidphaseCountDown"))
    mod:AddTimerBar("THORN", "Next thorns", 20)
    mod:AddTimerBar("AVATUS_INCOMING", "Avatus incoming", 500)
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nCurrentTime = GetGameTime()

    if sName == self.L["Wild Brambles"] then
        if nLastThornsTime + 5 < nCurrentTime and nCurrentTime + 16 < nMidPhaseTime then
            nLastThornsTime = nCurrentTime
            nTwirlCount = nTwirlCount + 1
            mod:AddTimerBar("THORN", "Next thorns", 15)
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
            mod:AddTimerBar("THORN", "Next thorns", 35)
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
            core:AddSimpleLine("Visc1", nId, 0, 25, 0, 4, "blue", 10)
            core:AddSimpleLine("Visc2", nId, 0, 25, 72, 4, "green", 20)
            core:AddSimpleLine("Visc3", nId, 0, 25, 144, 4, "green", 20)
            core:AddSimpleLine("Visc4", nId, 0, 25, 216, 4, "green", 20)
            core:AddSimpleLine("Visc5", nId, 0, 25, 288, 4, "green", 20)
        end
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if bIsMidPhase and sName == self.L["[DS] e395 - Air - Tornado"] then
        bIsMidPhase = false
        mod:AddTimerBar("MIDPHASE", "Next middle phase", 90, mod:GetSetting("SoundMidphaseCountDown"))
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

function mod:OnDatachron(sMessage)
    if self.L["Time to die, sapients!"] == sMessage then
        mod:RemoveTimerBar("AVATUS_INCOMING")
        mod:AddTimerBar("ENRAGE", "Enrage", 34)
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
            mod:AddSpell2Dispel(nId, DEBUFFID_LIFE_FORCE_SHACKLE)
        end
        if nId == nPlayerId and mod:GetSetting("OtherNoHealDebuff") then
            local sSound = mod:GetSetting("SoundNoHealDebuff") and "Alarm"
            mod:AddMsg("NOHEAL", "No-Healing Debuff!", 5, sSound)
        end
    elseif nSpellId == DEBUFFID_LIGHTNING_STRIKE then
        if mod:GetSetting("OtherLightningMarkers") then
            core:MarkUnit(tUnit, nil, self.L["Lightning"])
        end
        if mod:GetSetting("LineHealingTrees") and #tTreeKeeperList > 0 then
            local sKey = ("LIGHTNING %d"):format(nId)
            core:AddPixie(sKey, 1, tUnit, GetUnitById(tTreeKeeperList[1]), "xkcdBrightPurple", 5)
        end
        if nId == nPlayerId then
            local sSound = mod:GetSetting("SoundLightning") and "RunAway"
            mod:AddMsg(nId, self.L["Lightning on %s"]:format(tUnit:GetName()), 3, sSound, "red")
        else
            mod:AddMsg(nId, self.L["Lightning on %s"]:format(tUnit:GetName()), 3, nil, "blue")
        end
    end
end

function mod:OnDebuffRemove(nId, nSpellId)
    if nSpellId == DEBUFFID_TWIRL then
        core:DropMark(nId)
        core:RemoveUnit(nId)
    elseif nSpellId == DEBUFFID_LIFE_FORCE_SHACKLE then
        mod:RemoveSpell2Dispel(nId, DEBUFFID_LIFE_FORCE_SHACKLE)
    elseif nSpellId == DEBUFFID_LIGHTNING_STRIKE then
        local sKey = ("LIGHTNING %d"):format(nId)
        core:DropPixie(sKey)
        core:DropMark(nId)
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Visceralus"] == sName then
        if self.L["Blinding Light"] == sCastName then
            if mod:GetSetting("OtherBlindingLight") then
                local tUnit = GetUnitById(nId)
                local bIsClose = self:GetDistanceBetweenUnits(tUnit, GetPlayerUnit()) < 33
                if bIsClose then
                    local sSound = mod:GetSetting("SoundBlindingLight") and "Beware"
                    mod:AddMsg("BLIND", "Blinding Light", 5, sSound)
                end
            end
        end
    end
end
