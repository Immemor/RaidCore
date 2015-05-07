--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("Lattice", 52, 98, 116)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Avatus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Obstinate Logic Wall"] = "Obstinate Logic Wall",
    ["Data Devourer"] = "Data Devourer",
    -- Datachron messages.
    ["Avatus sets his focus on [PlayerName]!"] = "Avatus sets his focus on (.*)!",
    ["Avatus prepares to delete all"] = "Avatus prepares to delete all data!",
    ["Secure Sector Enhancement"] = "The Secure Sector Enhancement Ports have been activated!",
    ["Vertical Locomotion Enhancement"] = "The Vertical Locomotion Enhancement Ports have been activated!",
    -- Cast.
    ["Null and Void"] = "Null and Void",
    -- Bar and messages.
    ["P2: SHIELD PHASE"] = "P2: SHIELD PHASE",
    ["P2: JUMP PHASE"] = "P2: JUMP PHASE",
    ["LASER"] = "LASER",
    ["EXPLOSION"] = "EXPLOSION",
    ["NEXT BEAM"] = "NEXT BEAM",
    ["[%u] WAVE"] = "[%u] WAVE",
    ["BEAM on YOU !!!"] = "BEAM on YOU !!!",
    ["[%u] BEAM on %s"] = "[%u] BEAM on %s",
    ["BIG CAST"] = "BIG CAST",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Obstinate Logic Wall"] = "Mur de logique obstiné",
    ["Data Devourer"] = "Dévoreur de données",
    -- Datachron messages.
    --["Avatus sets his focus on [PlayerName]!"] = "Avatus sets his focus on (.*)!", -- TODO: French translation missing !!!!
    ["Avatus prepares to delete all"] = "Avatus se prépare à effacer toutes les données !",
    ["Secure Sector Enhancement"] = "Les ports d'amélioration de secteur sécurisé ont été activés !",
    ["Vertical Locomotion Enhancement"] = "Les ports d'amélioration de locomotion verticale ont été activés !",
    -- Cast.
    ["Null and Void"] = "Caduque",
    -- Bar and messages.
    --["P2: SHIELD PHASE"] = "P2: SHIELD PHASE", -- TODO: French translation missing !!!!
    --["P2: JUMP PHASE"] = "P2: JUMP PHASE", -- TODO: French translation missing !!!!
    --["LASER"] = "LASER", -- TODO: French translation missing !!!!
    --["EXPLOSION"] = "EXPLOSION", -- TODO: French translation missing !!!!
    --["NEXT BEAM"] = "NEXT BEAM", -- TODO: French translation missing !!!!
    ["[%u] WAVE"] = "[%u] WAVE",
    --["BEAM on YOU !!!"] = "BEAM on YOU !!!", -- TODO: French translation missing !!!!
    --["[%u] BEAM on %s"] = "[%u] BEAM on %s", -- TODO: French translation missing !!!!
    --["BIG CAST"] = "BIG CAST", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Obstinate Logic Wall"] = "Hartnäckige Logikmauer",
    ["Data Devourer"] = "Datenverschlinger",
    -- Datachron messages.
    --["Avatus sets his focus on [PlayerName]!"] = "Avatus sets his focus on (.*)!", -- TODO: German translation missing !!!!
    --["Avatus prepares to delete all"] = "Avatus prepares to delete all data!", -- TODO: German translation missing !!!!
    --["Secure Sector Enhancement"] = "The Secure Sector Enhancement Ports have been activated!", -- TODO: German translation missing !!!!
    --["Vertical Locomotion Enhancement"] = "The Vertical Locomotion Enhancement Ports have been activated!", -- TODO: German translation missing !!!!
    -- Cast.
    ["Null and Void"] = "Unordnung und Chaos",
    -- Bar and messages.
    --["P2: SHIELD PHASE"] = "P2: SHIELD PHASE", -- TODO: German translation missing !!!!
    --["P2: JUMP PHASE"] = "P2: JUMP PHASE", -- TODO: German translation missing !!!!
    --["LASER"] = "LASER", -- TODO: German translation missing !!!!
    --["EXPLOSION"] = "EXPLOSION", -- TODO: German translation missing !!!!
    --["NEXT BEAM"] = "NEXT BEAM", -- TODO: German translation missing !!!!
    --["[%u] WAVE"] = "[%u] WAVE", -- TODO: German translation missing !!!!
    --["BEAM on YOU !!!"] = "BEAM on YOU !!!", -- TODO: German translation missing !!!!
    --["[%u] BEAM on %s"] = "[%u] BEAM on %s", -- TODO: German translation missing !!!!
    --["BIG CAST"] = "BIG CAST", -- TODO: German translation missing !!!!
})

--------------------------------------------------------------------------------
-- Locals
--
local NO_BREAK_SPACE = string.char(194, 160)

local prev = 0
local waveCount, beamCount = 0, 0
local playerName
local phase2 = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--
function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Data Devourer"] and self:GetDistanceBetweenUnits(unit, GameLib.GetPlayerUnit()) < 45 and mod:GetSetting("LineDataDevourers") then
        core:AddPixie(unit:GetId(), 1, GameLib.GetPlayerUnit(), unit, "Blue", 5, 10, 10)
    end
end

function mod:RemoveLaserMark(unit)
    core:DropMark(unit:GetId())
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Data Devourer"] then
        core:DropPixie(unit:GetId())
    end
end

function mod:OnChatDC(message)
    local playerFocus = message:match(self.L["Avatus sets his focus on [PlayerName]!"])
    if playerFocus then
        beamCount = beamCount + 1
        local pUnit = GameLib.GetPlayerUnitByName(playerFocus)
        if pUnit and mod:GetSetting("OtherPlayerBeamMarkers") then
            core:MarkUnit(pUnit, nil, self.L["LASER"])
            self:ScheduleTimer("RemoveLaserMark", 15, pUnit)
        end
        if playerFocus == playerName then
            core:AddMsg("BEAM", self.L["BEAM on YOU !!!"], 5, mod:GetSetting("SoundBeam", "RunAway"))
        else
            core:AddMsg("BEAM", self.L["[%u] BEAM on %s"]:format(beamCount, playerFocus), 5, mod:GetSetting("SoundBeam", "Info"), "Blue")
        end
        if phase2 then
            core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), 15, mod:GetSetting("SoundNewWave"))
            phase2 = false
        else
            core:AddBar("BEAM", self.L["[%u] BEAM on %s"]:format(beamCount, playerFocus), 15)
            if beamCount == 3 then
                core:AddBar("WAVE", self.L["[%u] WAVE"]:format(waveCount + 1), 15, mod:GetSetting("SoundNewWave"))
            end
        end
    elseif message == self.L["Avatus prepares to delete all"] then
        core:StopBar("BEAM")
        core:StopBar("WAVE")
        core:AddMsg("BIGC", self.L["BIG CAST"] .. " !!", 5, mod:GetSetting("SoundBigCast", "Beware"))
        core:AddBar("BIGC", self.L["BIG CAST"], 10)
        beamCount = 0
    elseif message == self.L["Secure Sector Enhancement"] then
        core:StopBar("BEAM")
        core:StopBar("WAVE")
        phase2 = true
        waveCount, beamCount = 0, 0
        core:AddMsg("P2", self.L["P2: SHIELD PHASE"], 5, mod:GetSetting("SoundShieldPhase", "Alert"))
        core:AddBar("P2", self.L["LASER"], 15, mod:GetSetting("SoundLaser"))
        core:AddBar("BEAM", self.L["NEXT BEAM"], 44)
    elseif message == self.L["Vertical Locomotion Enhancement"] then
        core:StopBar("BEAM")
        core:StopBar("WAVE")
        phase2 = true
        waveCount, beamCount = 0, 0
        core:AddMsg("P2", self.L["P2: JUMP PHASE"], 5, mod:GetSetting("SoundJumpPhase", "Alert"))
        core:AddBar("P2", self.L["EXPLOSION"], 15, mod:GetSetting("SoundExplosion"))
        core:AddBar("BEAM", self.L["NEXT BEAM"], 58)
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Obstinate Logic Wall"] then
            local timeOfEvent = GameLib.GetGameTime()
            if mod:GetSetting("OtherLogicWallMarkers") then
                core:MarkUnit(unit)
            end
            core:AddUnit(unit)
            if timeOfEvent - prev > 20 and not phase2 then
                prev = timeOfEvent
                waveCount = waveCount + 1
                core:AddMsg("WAVE", self.L["[%u] WAVE"]:format(waveCount), 5, mod:GetSetting("SoundNewWave", "Alert"))
            end
        elseif sName == self.L["Avatus"] then
            playerName = GameLib.GetPlayerUnit():GetName():gsub(NO_BREAK_SPACE, " ")
            prev = 0
            waveCount, beamCount = 0, 0
            phase2 = false
            core:Berserk(576)
        end
    end
end
