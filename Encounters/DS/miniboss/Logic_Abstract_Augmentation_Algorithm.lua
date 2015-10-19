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
local mod = core:NewEncounter("AbstractAugmentationAlgorithm", 52, 98, 112)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Abstract Augmentation Algorithm" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Abstract Augmentation Algorithm"] = "Abstract Augmentation Algorithm",
    ["Quantum Processing Unit"] = "Quantum Processing Unit",
    -- Datachron messages.
    ["Quantum processing unit amplified"] = "The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit",
    -- Cast.
    ["Data Deconstruction"] = "Data Deconstruction",
    -- Bar and messages.
    ["Next interrupt"] = "Next interrupt",
    ["%s is candidate to interrupt"] = "%s is candidate to interrupt",
    ["Next candidate is %s"] = "Next candidate is %s",
    ["Next quantum amplified"] = "Next quantum amplified",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Abstract Augmentation Algorithm"] = "Algorithme d'augmentation abstrait",
    ["Quantum Processing Unit"] = "Processeur quantique",
    -- Datachron messages.
    ["Quantum processing unit amplified"] = "L'algorithme d'augmentation abstrait a amplifié un processeur quantique !",
    -- Cast.
    ["Data Deconstruction"] = "Déconstruction de données",
    -- Bar and messages.
    ["Next interrupt"] = "Prochaine interruption",
    ["%s is candidate to interrupt"] = "%s est candidat pour interrompre",
    ["Next candidate is %s"] = "Prochain candidat est %s",
    ["Next quantum amplified"] = "Prochain quantum amplifié",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Abstract Augmentation Algorithm"] = "Abstrakter Augmentations-Algorithmus",
    ["Quantum Processing Unit"] = "Quantum-Aufbereitungseinheit",
    -- Datachron messages.
    -- Cast.
    ["Data Deconstruction"] = "Datendekonstruktion",
    -- Bar and messages.
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_INTERRUPT"] = { sColor = "xkcdBloodRed" },
    ["NEXT_QUANTUM_AMPLIFIED"] = { sColor = "xkcdBloodOrange" },
})
mod:RegisterDefaultSetting("OtherKickerAnnounce")

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID__DATA_DECONSTRUCTION = 72559
local INTERRUPT_INTERVAL = 2

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local tKickerList
local nLastKickerId
local nExpectedKickerId

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    tKickerList = {}
    nLastKickerId = nil
    nExpectedKickerId = nil
    mod:AddTimerBar("NEXT_INTERRUPT", "Next interrupt", INTERRUPT_INTERVAL)
    mod:AddTimerBar("NEXT_QUANTUM_AMPLIFIED", "Next quantum amplified", 30)

    for i = 1, GroupLib.GetMemberCount() do
        local tMember = GroupLib.GetGroupMember(i)
        local tPlayer = GroupLib.GetUnitForGroupMember(i)
        if tMember and tPlayer and tPlayer:GetHealth() ~= 0 and not tMember.bTank then
            local nPlayerId = tPlayer:GetId()
            tKickerList[nPlayerId] = -nPlayerId
        end
    end
end

function mod:OnUnitCreated(nId, unit, sName)
    if self.L["Abstract Augmentation Algorithm"] == sName then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif self.L["Quantum Processing Unit"] == sName then
        core:AddUnit(unit)
        core:MarkUnit(unit)
        mod:AddTimerBar("NEXT_QUANTUM_AMPLIFIED", "Next quantum amplified", 35)
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    mod:OnDebuffAddedOrUpdated(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnDebuffUpdate(nId, nSpellId, nOldStack, nStack, fTimeRemaining)
    mod:OnDebuffAddedOrUpdated(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnDebuffAddedOrUpdated(nId, nSpellId, nStack, fTimeRemaining)
    if DEBUFFID__DATA_DECONSTRUCTION == nSpellId then
        local nCurrentTime = GetGameTime()
        tKickerList[nId] = nCurrentTime + fTimeRemaining

        if nLastKickerId ~= nId then
            nLastKickerId = nId

            if nExpectedKickerId and nExpectedKickerId ~= nId then
                if tKickerList[nExpectedKickerId] < 0 then
                    -- Give a second chance to this player to kick.
                    tKickerList[nExpectedKickerId] = 0
                elseif tKickerList[nExpectedKickerId] == 0 then
                    -- This player haven't interrupt twice times, invalid it so.
                    tKickerList[nExpectedKickerId] = nil
                end
            end

            local nCandidateId = nil
            -- Remove players who are dead or no more available.
            for nPlayerId, nTimeout in next, tKickerList do
                local tPlayerUnit = GetUnitById(nPlayerId)
                if tPlayerUnit == nil or tPlayerUnit:GetHealth() == 0 then
                    tKickerList[nPlayerId] = nil
                end
            end
            -- Determine the two next kickers.
            for nPlayerId, nTimeout in next, tKickerList do
                if nTimeout < nCurrentTime then
                    if nCandidateId == nil then
                        nCandidateId = nPlayerId
                    elseif nTimeout < tKickerList[nCandidateId] then
                        nCandidateId = nPlayerId
                    end
                end
            end

            nExpectedKickerId = nCandidateId
            local sCandidateName = nCandidateId and GetUnitById(nCandidateId):GetName()
            if sCandidateName then
                local bIsCountDown = nCandidateId == GetPlayerUnit():GetId()
                local sMessage = self.L["%s is candidate to interrupt"]:format(sCandidateName)
                mod:AddTimerBar("NEXT_INTERRUPT", sMessage, INTERRUPT_INTERVAL, bIsCountDown)
                if mod:GetSetting("OtherKickerAnnounce") then
                    mod:AddMsg("KICKER", sMessage, INTERRUPT_INTERVAL, nil, "red")
                end
            else
                mod:AddTimerBar("NEXT_INTERRUPT", "Next interrupt", INTERRUPT_INTERVAL)
            end
        end
    end
end
