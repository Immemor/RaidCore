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
local mod = core:NewEncounter("Gloomclaw", 52, 98, 115)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Gloomclaw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Gloomclaw"] = "Gloomclaw",
    ["Corrupted Ravager"] = "Corrupted Ravager",
    ["Empowered Ravager"] = "Empowered Ravager",
    ["Strain Parasite"] = "Strain Parasite",
    ["Gloomclaw Skurge"] = "Gloomclaw Skurge",
    ["Corrupted Fraz"] = "Corrupted Fraz",
    ["Essence of Logic"] = "Essence of Logic",
    -- Datachron messages.
    ["Gloomclaw is reduced to a weakened state"] = "Gloomclaw is reduced to a weakened state!",
    ["Gloomclaw is vulnerable"] = "Gloomclaw is vulnerable!",
    ["Gloomclaw is pushed back"] = "Gloomclaw is pushed back by the purification of the essences!",
    ["Gloomclaw is moving forward"] = "Gloomclaw is moving forward to corrupt more essences!",
    -- Cast.
    ["Rupture"] = "Rupture",
    ["Corrupting Rays"] = "Corrupting Rays",
    -- Timer bars.
    ["Next wave #%u"] = "Next wave #%u",
    ["Next rupture"] = "Next rupture",
    ["Full corruption"] = "Full corruption",
    -- Message bars.
    ["WAVE"] = "WAVE",
    ["INTERRUPT %s"] = "INTERRUPT %s",
    ["SECTION %u"] = "SECTION %u",
    ["FROG %u"] = "FROG %u",
    ["LEFT"] = "LEFT",
    ["RIGHT"] = "RIGHT",
    ["TRANSITION"] = "TRANSITION",
    ["MOO PHASE"] = "MOO PHASE",
    ["BURN HIM HARD"] = "BURN HIM HARD",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Gloomclaw"] = "Serrenox",
    ["Corrupted Ravager"] = "Ravageur corrompu",
    ["Empowered Ravager"] = "Ravageur renforcé",
    ["Strain Parasite"] = "Parasite de la Souillure",
    ["Gloomclaw Skurge"] = "Skurge serrenox",
    ["Corrupted Fraz"] = "Friz corrompu",
    ["Essence of Logic"] = "Essence de logique",
    -- Datachron messages.
    ["Gloomclaw is reduced to a weakened state"] = "Serrenox a été affaibli !",
    ["Gloomclaw is vulnerable"] = "Serrenox est vulnérable !",
    ["Gloomclaw is pushed back"] = "Serrenox est repoussé par la purification des essences !",
    ["Gloomclaw is moving forward"] = "Serrenox s'approche pour corrompre davantage d'essences !",
    -- Cast.
    ["Rupture"] = "Rupture",
    ["Corrupting Rays"] = "Rayons de corruption",
    -- Timer bars.
    ["Next wave #%u"] = "Next wave n°%u",
    ["Next rupture"] = "Prochaine rupture",
    ["Full corruption"] = "Totalement corrompu",
    -- Message bars.
    ["WAVE"] = "WAVE",
    ["INTERRUPT %s"] = "INTERROMPRE %s",
    ["SECTION %u"] = "SECTION %u",
    ["FROG %u"] = "ADD %u",
    ["LEFT"] = "GAUCHE",
    ["RIGHT"] = "DROITE",
    ["TRANSITION"] = "TRANSITION",
    ["MOO PHASE"] = "MOO PHASE",
    ["BURN HIM HARD"] = "Burst DPS",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Gloomclaw"] = "Düsterklaue",
    ["Corrupted Ravager"] = "Korrumpierter Verwüster",
    ["Strain Parasite"] = "Transmutierten-Parasit",
    ["Gloomclaw Skurge"] = "Düsterklauen-Geißel",
    ["Corrupted Fraz"] = "Korrumpierter Fraz",
    ["Essence of Logic"] = "Logikessenz",
    -- Datachron messages.
    -- Cast.
    ["Rupture"] = "Aufreißen",
    ["Corrupting Rays"] = "Korrumpierende Strahlen",
    -- Timer bars.
    -- Message bars.
})
-- Default settings.
mod:RegisterDefaultSetting("SoundRuptureInterrupt")
mod:RegisterDefaultSetting("SoundCorruptingRays")
mod:RegisterDefaultSetting("SoundSectionSwitch")
mod:RegisterDefaultSetting("SoundMoOWarning")
mod:RegisterDefaultSetting("SoundWaveWarning")
mod:RegisterDefaultSetting("SoundRuptureCountDown")
mod:RegisterDefaultSetting("SoundCorruptionCountDown")
mod:RegisterDefaultSetting("OtherMaulerMarkers")
mod:RegisterDefaultSetting("OtherLeftRightMarkers")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["RUPTURE"] = { sColor = "xkcdBrightRed" },
    ["WAVE"] = { sColor = "xkcdBrightOrange" },
    ["CORRUPTION"] = { sColor = "xkcdBrown" },
    ["MOO"] = { sColor = "xkcdBurntYellow" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local leftSpawn = {
    {x = 4288.5, y = -568.48095703125, z = -16765.66796875 },
    {x = 4288.5, y = -568.30078125, z = -16858.9765625 },
    {x = 4288.5, y = -568.95300292969, z = -16949.40234375 },
    {x = 4288.5, y = -568.95300292969, z = -17040.22265625 },
    {x = 4288.5, y = -568.95300292969, z = -17040.099609375 }
}
local rightSpawn = {
    {x = 4332.5, y = -568.4833984375, z = -16765.66796875 },
    {x = 4332.5, y = -568.45147705078, z = -16858.9765625 },
    {x = 4332.5, y = -568.95300292969, z = -16949.40234375 },
    {x = 4332.5, y = -568.95300292969, z = -17040.22265625 },
    {x = 4332.5, y = -568.95300292969, z = -17040.099609375 }
}
local spawnTimer = { 26, 33, 25, 14, 20.5 }
local spawnCount = { 4, 3, 4, 5, 5 }
local maulerSpawn = {
    ["northwest"] = { x = 4288, y = -568, z = -17040 },
    ["northeast"] = { x = 4332, y = -568, z = -17040 },
    ["southwest"] = { x = 4288, y = -568, z = -16949 }, --todo check if these 2 are sw/se or other way around
    ["southeast"] = { x = 4332, y = -568, z = -16949 },
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local prev
local waveCount, ruptCount, essenceUp
local first
local section

local function RemoveEssenceTracking()
    for nId, _ in next, essenceUp do
        core:RemoveUnit(nId)
        core:DropMark(nId)
        essenceUp[nId] = nil
    end
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    waveCount, ruptCount, prev = 0, 0, 0
    section = 1
    first = true
    essenceUp = {}
    mod:AddTimerBar("RUPTURE", "next rupture", 35, mod:GetSetting("SoundRuptureCountDown"))
    mod:AddTimerBar("CORRUPTION", "Full corruption", 106, mod:GetSetting("SoundCorruptionCountDown"))
end

function mod:OnWipe()
    Apollo.RemoveEventHandler("CombatLogHeal", self)
    core:ResetWorldMarkers()
end

function mod:OnUnitCreated(nId, tUnit, sName)
    if sName == self.L["Corrupted Ravager"] or sName == self.L["Empowered Ravager"] then
        core:WatchUnit(tUnit)
    elseif sName == self.L["Gloomclaw"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sName == self.L["Gloomclaw"] and sCastName == self.L["Rupture"] then
        ruptCount = ruptCount + 1
        mod:AddMsg("RUPTURE", self.L["INTERRUPT %s"]:format(sName:upper()), 5, mod:GetSetting("SoundRuptureInterrupt") and "Destruction")
        if ruptCount == 1 then
            mod:AddTimerBar("RUPTURE", "Next rupture", 43, mod:GetSetting("SoundRuptureCountDown"))
        end
    elseif (sName == self.L["Corrupted Ravager"] or sName == self.L["Empowered Ravager"])
        and sCastName == self.L["Corrupting Rays"] then

        local playerUnit = GameLib.GetPlayerUnit()
        local tUnit = GetUnitById(nId)
        local distance_to_unit = self:GetDistanceBetweenUnits(playerUnit, tUnit)
        if distance_to_unit < 35 then
            mod:AddMsg("RAYS", self.L["INTERRUPT %s"]:format(sName:upper()), 5, mod:GetSetting("SoundCorruptingRays") and "Inferno")
        end
    end
end

function mod:OnDatachron(sMessage)
    local isPushBack = sMessage == self.L["Gloomclaw is pushed back"]
    local isMoveForward = sMessage == self.L["Gloomclaw is moving forward"]

    if isPushBack or isMoveForward then
        if not first then
            waveCount, ruptCount, prev = 0, 0, 0
            mod:RemoveTimerBar("RUPTURE")
            mod:RemoveTimerBar("CORRUPTION")
            mod:RemoveTimerBar("WAVE")
            if isPushBack then
                section = section + 1
            else
                section = section - 1
            end
            mod:AddMsg("PHASE", self.L["SECTION %u"]:format(section), 5, mod:GetSetting("SoundSectionSwitch") and "Info", "Blue")
            if section ~= 4 then 
                mod:AddTimerBar("WAVE", self.L["Next wave #%u"]:format(waveCount + 1), 11)
                mod:AddTimerBar("RUPTURE", "Next rupture", 39, mod:GetSetting("SoundRuptureCountDown"))
            end
            mod:AddTimerBar("CORRUPTION", "Full corruption", 111, mod:GetSetting("SoundCorruptionCountDown"))
        else
            first = false
        end
        core:ResetWorldMarkers()
        if mod:GetSetting("OtherMaulerMarkers") then
            core:SetWorldMarker("FROG1", self.L["FROG %u"]:format(1), maulerSpawn["northwest"])
            core:SetWorldMarker("FROG2", self.L["FROG %u"]:format(2), maulerSpawn["northeast"])
            core:SetWorldMarker("FROG3", self.L["FROG %u"]:format(3), maulerSpawn["southeast"])
            core:SetWorldMarker("FROG4", self.L["FROG %u"]:format(4), maulerSpawn["southwest"])
        end
        if mod:GetSetting("OtherLeftRightMarkers") then
            if leftSpawn[section] then
                core:SetWorldMarker("SECLEFT", self.L["LEFT"], leftSpawn[section])
            end
            if rightSpawn[section] then
                core:SetWorldMarker("SECRIGHT", self.L["RIGHT"], rightSpawn[section])
            end
        end
        Apollo.RegisterEventHandler("CombatLogHeal", "OnCombatLogHeal", self)
    elseif sMessage:find(self.L["Gloomclaw is reduced to a weakened state"]) then
        mod:RemoveTimerBar("RUPTURE")
        mod:RemoveTimerBar("CORRUPTION")
        mod:RemoveTimerBar("WAVE")
        mod:AddMsg("TRANSITION", "TRANSITION", 5, mod:GetSetting("SoundMoOWarning") and "Alert")
        RemoveEssenceTracking()
    elseif sMessage:find(self.L["Gloomclaw is vulnerable"]) then
        mod:RemoveTimerBar("RUPTURE")
        mod:RemoveTimerBar("CORRUPTION")
        mod:RemoveTimerBar("WAVE")
        mod:AddMsg("TRANSITION", "BURN HIM HARD", 5, mod:GetSetting("SoundMoOWarning") and "Alert")
        mod:AddTimerBar("MOO", "MOO PHASE", 20, mod:GetSetting("SoundMoOWarning"))
        RemoveEssenceTracking()
    end
end

function mod:OnCombatLogHeal(tArgs)
    if tArgs.unitTarget then
        local NO_BREAK_SPACE = string.char(194, 160)
        local targetName = tArgs.unitTarget:GetName():gsub(NO_BREAK_SPACE, " ")
        local targetId = tArgs.unitTarget:GetId()
        if targetName == self.L["Essence of Logic"] then
            if not essenceUp[targetId] then
                essenceUp[targetId] = true
                local essPos = tArgs.unitTarget:GetPosition()
                core:MarkUnit(tArgs.unitTarget, 0, (essPos.x < 4310) and "L" or "R")
                core:AddUnit(tArgs.unitTarget)
                if #essenceUp == 2 then
                    Apollo.RemoveEventHandler("CombatLogHeal", self)
                end
            end
        end
    end
end

function mod:OnEnteredCombat(nId, tUnit, sName, bInCombat)
    if bInCombat then
        if sName == self.L["Strain Parasite"]
            or sName == self.L["Gloomclaw Skurge"]
            or sName == self.L["Corrupted Fraz"] then

            local timeOfEvent = GameLib.GetGameTime()
            if timeOfEvent - prev > 10 then
                prev = timeOfEvent
                waveCount = waveCount + 1
                mod:AddMsg("WAVE", "WAVE", 5, mod:GetSetting("SoundWaveWarning") and "Info", "Blue")
                if section < 5 then
                    if waveCount < spawnCount[section] then
                        mod:AddTimerBar("WAVE", self.L["Next wave #%u"]:format(waveCount + 1), spawnTimer[section])
                    end
                else
                    local sTimerText = self.L["Next wave #%u"]:format(waveCount + 1)
                    if waveCount == 1 then
                        mod:AddTimerBar("WAVE", sTimerText, 20.5)
                    elseif waveCount == 2 then
                        mod:AddTimerBar("WAVE", sTimerText, 30)
                    elseif waveCount == 3 then
                        mod:AddTimerBar("WAVE", sTimerText, 15)
                    end
                end
            end
        end
    end
end
