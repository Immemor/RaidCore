--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("Gloomclaw", 52, 98, 115)
if not mod then return end

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
    -- Bar and messages.
    ["INTERRUPT %s"] = "INTERRUPT %s",
    ["NEXT RUPTURE"] = "NEXT RUPTURE",
    ["~NEXT RUPTURE"] = "~NEXT RUPTURE",
    ["FULL CORRUPTION"] = "FULL CORRUPTION",
    ["SECTION %u"] = "SECTION %u",
    ["[%u] WAVE"] = "[%u] WAVE",
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
    -- Bar and messages.
    ["INTERRUPT %s"] = "INTÉRROMPRE %s",
    ["NEXT RUPTURE"] = "PROCHAINE RUPTURE",
    ["~NEXT RUPTURE"] = "~PROCHAINE RUPTURE",
    ["FULL CORRUPTION"] = "100% CORROMPU",
    ["SECTION %u"] = "SECTION %u",
    ["[%u] WAVE"] = "[%u] WAVE",
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
    --["Empowered Ravager"] = "Empowered Ravager", -- TODO: German translation missing !!!!
    ["Strain Parasite"] = "Transmutierten-Parasit",
    ["Gloomclaw Skurge"] = "Düsterklauen-Geißel",
    ["Corrupted Fraz"] = "Korrumpierter Fraz",
    ["Essence of Logic"] = "Logikessenz",
    -- Datachron messages.
    --["Gloomclaw is reduced to a weakened state"] = "Gloomclaw is reduced to a weakened state!", -- TODO: German translation missing !!!!
    --["Gloomclaw is vulnerable"] = "Gloomclaw is vulnerable!", -- TODO: German translation missing !!!!
    --["Gloomclaw is pushed back"] = "Gloomclaw is pushed back by the purification of the essences!", -- TODO: German translation missing !!!!
    --["Gloomclaw is moving forward"] = "Gloomclaw is moving forward to corrupt more essences!", -- TODO: German translation missing !!!!
    -- Cast.
    ["Rupture"] = "Aufreißen",
    ["Corrupting Rays"] = "Korrumpierende Strahlen",
    -- Bar and messages.
    --["INTERRUPT %s"] = "INTERRUPT %s", -- TODO: German translation missing !!!!
    --["NEXT RUPTURE"] = "NEXT RUPTURE", -- TODO: German translation missing !!!!
    --["~NEXT RUPTURE"] = "~NEXT RUPTURE", -- TODO: German translation missing !!!!
    --["FULL CORRUPTION"] = "FULL CORRUPTION", -- TODO: German translation missing !!!!
    --["SECTION %u"] = "SECTION %u", -- TODO: German translation missing !!!!
    --["[%u] WAVE"] = "[%u] WAVE", -- TODO: German translation missing !!!!
    --["FROG %u"] = "FROG %u", -- TODO: German translation missing !!!!
    --["LEFT"] = "LEFT", -- TODO: German translation missing !!!!
    --["RIGHT"] = "RIGHT", -- TODO: German translation missing !!!!
    --["TRANSITION"] = "TRANSITION", -- TODO: German translation missing !!!!
    --["MOO PHASE"] = "MOO PHASE", -- TODO: German translation missing !!!!
    --["BURN HIM HARD"] = "BURN HIM HARD", -- TODO: German translation missing !!!!
})

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local waveCount, ruptCount, essenceUp = 0, 0, {}
local first = true
local section = 1
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

local spawnTimer = {
    26,
    33,
    25,
    14,
    20.5
}

local spawnCount = {
    4,
    3,
    4,
    5,
    5
}

local maulerSpawn = {
    ["northwest"] = { x = 4288, y = -568, z = -17040 },
    ["northeast"] = { x = 4332, y = -568, z = -17040 },
    ["southwest"] = { x = 4288, y = -568, z = -16949 }, --todo check if these 2 are sw/se or other way around
    ["southeast"] = { x = 4332, y = -568, z = -16949 },
}
--[[
L1 : 4288.5, -568.48095703125, -16765.66796875
R1 : 4332.5, -568.4833984375, -16765.66796875

L2 : 4288.5, -568.30078125, -16858.9765625
R2 : 4332.5, -568.45147705078, -16858.9765625

L3 : 4288.5, -568.95300292969, -16949.40234375
R3 : 4332.5, -568.95300292969, -16949.40234375

L4 : 4288.5, -568.95300292969, -17040.22265625
R4 : 4332.5, -568.95300292969, -17040.22265625

L5 : 4288.5, -568.95300292969, -17054.87109375
R5 : 4332.5, -568.95300292969, -17054.87109375
]]--

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--
function mod:OnWipe()
    Apollo.RemoveEventHandler("CombatLogHeal", self)
    core:ResetWorldMarkers()
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Corrupted Ravager"] or sName == self.L["Empowered Ravager"] then
        core:WatchUnit(unit)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Gloomclaw"] and castName == self.L["Rupture"] then
        ruptCount = ruptCount + 1
        core:AddMsg("RUPTURE", self.L["INTERRUPT %s"]:format(unitName:upper()), 5, mod:GetSetting("SoundRuptureInterrupt", "Destruction"))
        if ruptCount == 1 then
            core:AddBar("RUPTURE", self.L["NEXT RUPTURE"], 43, mod:GetSetting("SoundRuptureCountdown"))
        end
    elseif (unitName == self.L["Corrupted Ravager"] or unitName == self.L["Empowered Ravager"])
        and castName == self.L["Corrupting Rays"] then

        local playerUnit = GameLib.GetPlayerUnit()
        local distance_to_unit = self:GetDistanceBetweenUnits(playerUnit, unit)
        if distance_to_unit < 35 then
            core:AddMsg("RAYS", self.L["INTERRUPT %s"]:format(unitName:upper()), 5, mod:GetSetting("SoundCorruptingRays", "Inferno"))
        end
    end
end

function mod:OnChatDC(message)
    local isPushBack = message == self.L["Gloomclaw is pushed back"]
    local isMoveForward = message == self.L["Gloomclaw is moving forward"]

    if isPushBack or isMoveForward then
        if not first then
            waveCount, ruptCount, prev = 0, 0, 0
            core:StopBar("RUPTURE")
            core:StopBar("CORRUPTION")
            core:StopBar("WAVE")
            if isPushBack then
                section = section + 1
            else
                section = section - 1
            end
            core:AddMsg("PHASE", self.L["SECTION %u"]:format(section), 5, mod:GetSetting("SoundSectionSwitch", "Info"), "Blue")
            if section ~= 4 then 
                core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), 11)
                core:AddBar("RUPTURE", self.L["NEXT RUPTURE"], 39, mod:GetSetting("SoundRuptureCountdown"))
            end
            core:AddBar("CORRUPTION", self.L["FULL CORRUPTION"], 111, mod:GetSetting("SoundCorruptionCountdown"))
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
        if mod:GetSetting("OtherLeftRightMarkers") and leftSpawn[section] then
            core:SetWorldMarker("SECLEFT", self.L["LEFT"], leftSpawn[section])
        end
        if mod:GetSetting("OtherLeftRightMarkers") and rightSpawn[section] then
            core:SetWorldMarker("SECRIGHT", self.L["RIGHT"], rightSpawn[section])
        end
        Apollo.RegisterEventHandler("CombatLogHeal", "OnCombatLogHeal", self)
    elseif message:find(self.L["Gloomclaw is reduced to a weakened state"]) then
        core:StopBar("RUPTURE")
        core:StopBar("CORRUPTION")
        core:StopBar("WAVE")
        core:AddMsg("TRANSITION", self.L["TRANSITION"], 5, mod:GetSetting("SoundMoOWarning", "Alert"))
        core:AddBar("MOO", self.L["MOO PHASE"], 15)
        for unitId, v in pairs(essenceUp) do
            core:RemoveUnit(unitId)
            essenceUp[unitId] = nil
        end
    elseif message:find(self.L["Gloomclaw is vulnerable"]) then
        core:StopBar("RUPTURE")
        core:StopBar("CORRUPTION")
        core:StopBar("WAVE")
        core:AddMsg("TRANSITION", self.L["BURN HIM HARD"], 5, mod:GetSetting("SoundMoOWarning", "Alert"))
        core:AddBar("MOO", self.L["MOO PHASE"], 20, mod:GetSetting("SoundMoOWarning"))
        for unitId, v in pairs(essenceUp) do
            core:RemoveUnit(unitId)
            essenceUp[unitId] = nil
        end
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

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Gloomclaw"] then
            waveCount, ruptCount, prev = 0, 0, 0
            section = 1
            first = true
            for unitId, v in pairs(essenceUp) do
                core:RemoveUnit(unitId)
                essenceUp[unitId] = nil
            end
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:AddBar("RUPTURE", self.L["~NEXT RUPTURE"], 35, mod:GetSetting("SoundRuptureCountdown"))
            core:AddBar("CORRUPTION", self.L["FULL CORRUPTION"], 106, mod:GetSetting("SoundCorruptionCountdown"))
        elseif sName == self.L["Strain Parasite"]
            or sName == self.L["Gloomclaw Skurge"]
            or sName == self.L["Corrupted Fraz"] then

            local timeOfEvent = GameLib.GetGameTime()
            if timeOfEvent - prev > 10 then
                prev = timeOfEvent
                waveCount = waveCount + 1
                core:AddMsg("WAVE", self.L["[%u] WAVE"]:format(waveCount), 5, mod:GetSetting("SoundWaveWarning", "Info"), "Blue")
                if section < 5 then
                    if waveCount < spawnCount[section] then
                        core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), spawnTimer[section])
                    end
                else
                    if waveCount == 1 then
                        core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), 20.5)
                    elseif waveCount == 2 then
                        core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), 30)
                    elseif waveCount == 3 then
                        core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), 15)
                    end
                end
            end
        end
    end
end
