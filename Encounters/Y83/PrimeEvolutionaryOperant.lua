----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Description:
--   Unique encounter in Core-Y83 raid.
--
--   - There are 3 boss called "Prime Evolutionary Operant". At any moment, one of them is
--     compromised, and his name is "Prime Phage Distributor".
--   - Bosses don't move, their positions are constants so.
--   - The boss call "Prime Phage Distributor" have a debuff called "Compromised Circuitry".
--   - And switch boss occur at 60% and 20% of health.
--   - The player which will be irradied is the last connected in the game (probability: 95%).
--
--   So be careful, with code based on name, as bosses are renamed many times during the combat.
--
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("PrimeEvolutionaryOperant", 91, 0, 475)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", {
    "Prime Evolutionary Operant", "Prime Phage Distributor", "Organic Incinerator"
})
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Prime Evolutionary Operant"] = "Prime Evolutionary Operant",
    ["Prime Phage Distributor"] = "Prime Phage Distributor",
    ["Sternum Buster"] = "Sternum Buster",
    ["Organic Incinerator"] = "Organic Incinerator",
    -- Datachron messages.
    ["(.*) is being irradiated"] = "(.*) is being irradiated!",
    ["ENGAGING TECHNOPHAGE TRASMISSION"] = "ENGAGING TECHNOPHAGE TRASMISSION",
    ["A Prime Purifier has been corrupted!"] = "A Prime Purifier has been corrupted!",
    ["INITIATING DECONTAMINATION SEQUENCE"] = "INITIATING DECONTAMINATION SEQUENCE",
    -- Cast
    ["Disintegrate"] = "Disintegrate",
    ["Digitize"] = "Digitize",
    ["Strain Injection"] = "Strain Injection",
    ["Corruption Spike"] = "Corruption Spike",
    -- Bars messages.
    ["~Next irradiate"] = "~Next irradiate",
    ["%u STACKS BEFORE CORRUPTION"] = "%u STACKS BEFORE CORRUPTION",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Prime Evolutionary Operant"] = "Opérateur de la Primo Évolution",
    ["Prime Phage Distributor"] = "Distributeur de Primo Phage",
    ["Organic Incinerator"] = "Incinérateur organique",
    -- Datachron messages.
    ["Disintegrate"] = "Désintégration",
    ["(.*) is being irradiated"] = "(.*) est irradiée.",
    ["ENGAGING TECHNOPHAGE TRASMISSION"] = "ENCLENCHEMENT DE LA TRANSMISSION DU TECHNOPHAGE",
    -- Bars messages.
    ["~Next irradiate"] = "~Prochaine irradiation",
    ["%u STACKS BEFORE CORRUPTION"] = "%u STACKS AVANT CORRUPTION",
})
mod:RegisterGermanLocale({
})
-- Default settings.
mod:RegisterDefaultSetting("SoundNextIrradiateCountDown")
mod:RegisterDefaultSetting("SoundSwitch")
mod:RegisterDefaultSetting("LinesOnBosses")
mod:RegisterDefaultSetting("LineRadiation")
mod:RegisterDefaultSetting("PictureIncubation")
mod:RegisterDefaultSetting("IncubationRegroupZone")
mod:RegisterDefaultSetting("OrganicIncineratorBeam")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_IRRADIATE"] = { sColor = "xkcdLightRed" },
})

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local NewVector3 = Vector3.New

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Center of the room, where is the Organic Incinerator button.
local ORGANIC_INCINERATOR = { x = 1268, y = -800, z = 876 }
-- It's when the player enter in "nuclear" green zone. If this last have some STRAIN INCUBATION,
-- he will lost it, and an small mob will pop.
local DEBUFF_RADIATION_BATH = 71188
-- DOT taken by one or more players, which is dispel with RADIATION_BATH or ENGAGING datachron
-- event.
local DEBUFF_STRAIN_INCUBATION = 49303
-- Debuff get only in Hard Mode.
local DEBUFF_DEGENERATION = 79892
-- DoT taken by everyone when the laser is interrupted. Hardmode only
local DEBUFF_PAIN_SUPPRESSORS = 81783
-- Buff stackable on bosses. The beam from the wall buff the boss when they are not hit by the boss
-- itself. At 15 stacks, the datachron message "A Prime Purifier has been corrupted!" will trig.
-- Note: the datachron event is raised before the buff update event.
local BUFF_NANOSTRAIN_INFUSION = 50075
local NANOSTRAIN_2_CORRUPTION_THRESHOLD = 15
-- Buff on bosses. The boss called "Prime Phage Distributor" have this buff, others not.
local BUFF_COMPROMISED_CIRCUITRY = 48735
-- On the axe Y, where is the ground.
local GROUND_Y = -800.51
-- Lines on bosses.
local STATIC_LINES = {
    -- West boss (or left):
    { NewVector3(1220.19, GROUND_Y, 874.18), NewVector3(1246.70, GROUND_Y, 920.07) },
    { NewVector3(1216.12, GROUND_Y, 893.83), NewVector3(1208.58, GROUND_Y, 880.88) },
    { NewVector3(1216.12, GROUND_Y, 893.83), NewVector3(1201.14, GROUND_Y, 893.83) },
    { NewVector3(1216.12, GROUND_Y, 907.16), NewVector3(1201.14, GROUND_Y, 907.16) },
    { NewVector3(1216.12, GROUND_Y, 907.16), NewVector3(1208.64, GROUND_Y, 920.10) },
    { NewVector3(1227.65, GROUND_Y, 913.78), NewVector3(1220.25, GROUND_Y, 926.77) },
    { NewVector3(1227.65, GROUND_Y, 913.78), NewVector3(1235.09, GROUND_Y, 926.77) },
    -- Est boss (or right):
    { NewVector3(1289.25, GROUND_Y, 920.17), NewVector3(1315.75, GROUND_Y, 874.27) },
    { NewVector3(1308.30, GROUND_Y, 913.88), NewVector3(1300.85, GROUND_Y, 926.87) },
    { NewVector3(1308.30, GROUND_Y, 913.88), NewVector3(1315.75, GROUND_Y, 926.87) },
    { NewVector3(1319.82, GROUND_Y, 907.23), NewVector3(1327.35, GROUND_Y, 920.17) },
    { NewVector3(1319.82, GROUND_Y, 907.23), NewVector3(1334.80, GROUND_Y, 907.27) },
    { NewVector3(1319.82, GROUND_Y, 893.92), NewVector3(1334.80, GROUND_Y, 893.92) },
    { NewVector3(1319.82, GROUND_Y, 893.92), NewVector3(1327.35, GROUND_Y, 880.97) },
    -- North boss (or middle/ahead):
    { NewVector3(1294.67, GROUND_Y, 837.02), NewVector3(1241.67, GROUND_Y, 837.02) },
    { NewVector3(1279.70, GROUND_Y, 823.67), NewVector3(1294.67, GROUND_Y, 823.62) },
    { NewVector3(1279.70, GROUND_Y, 823.67), NewVector3(1287.22, GROUND_Y, 810.72) },
    { NewVector3(1268.17, GROUND_Y, 817.01), NewVector3(1275.62, GROUND_Y, 804.02) },
    { NewVector3(1268.17, GROUND_Y, 817.01), NewVector3(1260.72, GROUND_Y, 804.02) },
    { NewVector3(1256.64, GROUND_Y, 823.67), NewVector3(1249.12, GROUND_Y, 810.72) },
    { NewVector3(1256.64, GROUND_Y, 823.67), NewVector3(1241.67, GROUND_Y, 823.62) },
}
local INCUBATION_ZONE_WEST = 1
local INCUBATION_ZONE_NORTH = 2
local INCUBATION_ZONE_EST = 3
local INCUBATION_REGROUP_ZONE = {
    -- West boss (or left):
    [INCUBATION_ZONE_WEST] = NewVector3(1238.03, GROUND_Y, 894.45),
    -- North boss (or middle/ahead):
    [INCUBATION_ZONE_NORTH] = NewVector3(1268.17, GROUND_Y, 842.32),
    -- Est boss (or right):
    [INCUBATION_ZONE_EST] = NewVector3(1298.20, GROUND_Y, 894.57),
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local nRadiationEndTime
local nPainSuppressorsFadeTime
local tPrimeOperant2ZoneIndex
local nPrimeDistributorId
local bIsPhaseUnder20Poucent

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    nRadiationEndTime = 0
    nPainSuppressorsFadeTime = 0
    tPrimeOperant2ZoneIndex = {}
    nPrimeDistributorId = nil
    bIsPhaseUnder20Poucent = false
    mod:AddTimerBar("NEXT_IRRADIATE", "~Next irradiate", 27, mod:GetSetting("SoundNextIrradiateCountDown"))
    if mod:GetSetting("LinesOnBosses") then
        for i, Vectors in next, STATIC_LINES do
            core:AddLineBetweenUnits("StaticLine" .. i, Vectors[1], Vectors[2], 3, "xkcdAmber")
        end
    end
    if mod:GetSetting("IncubationRegroupZone") then
        local Vector = INCUBATION_REGROUP_ZONE[INCUBATION_ZONE_NORTH]
        core:AddPicture("IZ" .. INCUBATION_ZONE_NORTH, Vector, "ClientSprites:LootCloseBox_Holo", 30)
    end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    if self.L["Prime Evolutionary Operant"] == sName then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        core:AddSimpleLine(("Cleave%d"):format(nId), nId, 0, 15, 0, 5, "green")
        local tPosition = tUnit:GetPosition()
        if tPosition.x < ORGANIC_INCINERATOR.x then
            core:MarkUnit(tUnit, 51, "L")
            tPrimeOperant2ZoneIndex[nId] = INCUBATION_ZONE_WEST
        else
            core:MarkUnit(tUnit, 51, "R")
            tPrimeOperant2ZoneIndex[nId] = INCUBATION_ZONE_EST
        end
    elseif self.L["Prime Phage Distributor"] == sName then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        core:MarkUnit(tUnit, 51, "M")
        core:AddSimpleLine(("Cleave%d"):format(nId), nId, 0, 15, 0, 5, "green")
        tPrimeOperant2ZoneIndex[nId] = INCUBATION_ZONE_NORTH
        nPrimeDistributorId = nId
    elseif self.L["Organic Incinerator"] == sName then
        core:WatchUnit(tUnit)
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if self.L["Prime Evolutionary Operant"] == sName and self.L["Prime Phage Distributor"] == sName then
        core:RemoveSimpleLine(("Cleave%d"):format(nId))
    end
end

function mod:OnDatachron(sMessage)
    local sPlayerNameIrradiate = sMessage:match(self.L["(.*) is being irradiated"])
    if sPlayerNameIrradiate then
        -- Sometime it's 26s, sometime 27s or 28s.
        mod:AddTimerBar("NEXT_IRRADIATE", "~Next irradiate", 26, mod:GetSetting("SoundNextIrradiateCountDown"))
        if mod:GetSetting("LineRadiation") then
            local tMemberUnit = GetPlayerUnitByName(sPlayerNameIrradiate)
            if tMemberUnit then
                local nMemberId = tMemberUnit:GetId()
                local nPlayerId = GetPlayerUnit():GetId()
                if nMemberId ~= nPlayerId then
                    local o = core:AddLineBetweenUnits("RADIATION", nPlayerId, nMemberId, 3, "cyan")
                    o:SetMinLengthVisible(10)
                end
            end
        end
    elseif sMessage == self.L["ENGAGING TECHNOPHAGE TRASMISSION"] then
        mod:AddTimerBar("NEXT_IRRADIATE", "~Next irradiate", 40, mod:GetSetting("SoundNextIrradiateCountDown"))
    elseif sMessage == self.L["A Prime Purifier has been corrupted!"] then
        bIsPhaseUnder20Poucent = true
    end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
    if nPourcent == 62 or nPourcent == 22 then
        mod:AddMsg("SWITCH", "SWITCH SOON", 5, mod:GetSetting("SoundSwitch") and "Long")
    elseif nPourcent == 20 then
        tPrimeOperant2ZoneIndex[nId] = nil
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local nPlayerId = GetPlayerUnit():GetId()
    local tUnit = GetUnitById(nId)
    local nCurrentTime = GetGameTime()

    if DEBUFF_STRAIN_INCUBATION == nSpellId then
        if mod:GetSetting("PictureIncubation") then
            core:AddPicture(("INCUBATION %d"):format(nId), nId, "Crosshair", 20)
        end
        if mod:GetSetting("IncubationRegroupZone") and nPrimeDistributorId then
            local nIndex = tPrimeOperant2ZoneIndex[nPrimeDistributorId]
            if nIndex then
                local sColor = nPlayerId == nId and "ffff00ff" or "60ff00ff"
                local Vector = INCUBATION_REGROUP_ZONE[nIndex]
                local o = core:AddLineBetweenUnits("SafeZoneGO" .. nId, nId, Vector, 5, sColor, 10)
                o:SetSprite("CRB_MegamapSprites:sprMap_PlayerArrowNoRing", 20)
                o:SetMinLengthVisible(5)
                o:SetMaxLengthVisible(50)
            end
        end
    elseif DEBUFF_RADIATION_BATH == nSpellId then
        if nRadiationEndTime < nCurrentTime then
            nRadiationEndTime = nCurrentTime + 12
            if mod:GetSetting("LineRadiation") then
                local o = core:AddLineBetweenUnits("RADIATION", nPlayerId, tUnit:GetPosition(), 3, "cyan")
                o:SetMinLengthVisible(10)
                mod:ScheduleTimer(function()
                    core:RemoveLineBetweenUnits("RADIATION")
                end, 10)
            end
        end
    elseif DEBUFF_PAIN_SUPPRESSORS == nSpellId then
        -- When the Organic Incinerator is interrupt, all alive players will have this debuff
        -- during 7s. The Organic Incinerator beam is without danger during 5s.
        if nPainSuppressorsFadeTime < nCurrentTime then
            nPainSuppressorsFadeTime = nCurrentTime + fTimeRemaining
            local line = core:GetSimpleLine("Orga.Inc. beam")
            if line then
                line:SetColor("6000ff00")
                self:ScheduleTimer(function(line) line:SetColor("A0ff8000") end, 4, line)
                self:ScheduleTimer(function(line) line:SetColor("red") end, 5, line)
            end
        end
    end
end

function mod:OnDebuffRemove(nId, nSpellId)
    if DEBUFF_STRAIN_INCUBATION == nSpellId then
        core:RemovePicture(("INCUBATION %d"):format(nId))
        core:RemoveLineBetweenUnits("SafeZoneGO" .. nId)
    end
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    if BUFF_COMPROMISED_CIRCUITRY == nSpellId then
        for i, Vector in next, INCUBATION_REGROUP_ZONE do
            core:RemovePicture("IZ" .. i)
        end
        if not bIsPhaseUnder20Poucent then
            nPrimeDistributorId = nId
            if mod:GetSetting("IncubationRegroupZone") then
                local nIndex = tPrimeOperant2ZoneIndex[nId]
                if nIndex then
                    local Vector = INCUBATION_REGROUP_ZONE[nIndex]
                    core:AddPicture("IZ" .. nIndex, Vector, "ClientSprites:LootCloseBox_Holo", 30)
                end
            end
        end
    end
end

function mod:OnBuffUpdate(nId, nSpellId, nNewStack, fTimeRemaining)
    if BUFF_NANOSTRAIN_INFUSION == nSpellId then
        local nRemain = NANOSTRAIN_2_CORRUPTION_THRESHOLD - nNewStack
        if nRemain == 2 or nRemain == 1 then
            local sColor = nRemain == 2 and "blue" or "red"
            core:AddMsg("WARNING", self.L["%u STACKS BEFORE CORRUPTION"]:format(nRemain), 4, nil, sColor)
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Organic Incinerator"] == sName then
        local line = core:GetSimpleLine("Orga.Inc. beam")
        if not line and mod:GetSetting("OrganicIncineratorBeam") then
            core:AddSimpleLine("Orga.Inc. beam", nId, 0, 65, 0, 10, "red")
        end
    end
end
