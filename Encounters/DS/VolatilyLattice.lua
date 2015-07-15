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
local mod = core:NewEncounter("Lattice", 52, 98, 116)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
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
    ["Enrage"] = "Enrage",
    ["P2: SHIELD PHASE"] = "P2: SHIELD PHASE",
    ["P2: JUMP PHASE"] = "P2: JUMP PHASE",
    ["LASER"] = "LASER",
    ["EXPLOSION"] = "EXPLOSION",
    ["BEGIN OF SCANNING LASER"] = "BEGIN OF SCANNING LASER",
    ["NEXT BEAM"] = "NEXT BEAM",
    ["NEXT PILLAR"] = "NEXT PILLAR",
    ["BEAM on %s"] = "BEAM on %s",
    ["PILLAR TIMEOUT"] = "PILLAR TIMEOUT",
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
    ["Enrage"] = "Enrage",
    ["P2: SHIELD PHASE"] = "P2: PHASE BOUCLIER",
    ["P2: JUMP PHASE"] = "P2: PHASE SAUTER",
    ["LASER"] = "LASER",
    ["EXPLOSION"] = "EXPLOSION",
    ["BEGIN OF SCANNING LASER"] = "DEBUT DU BALAYAGE LASER",
    ["NEXT BEAM"] = "PROCHAIN LASER",
    ["NEXT PILLAR"] = "PROCHAIN PILLIER",
    ["BEAM on %s"] = "LASER sur %s",
    ["PILLAR TIMEOUT"] = "PILLIER EXPIRATION",
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
    --["BEGIN OF SCANNING LASER"] = "BEGIN OF SCANNING LASER", -- TODO: German translation missing !!!!
    --["NEXT BEAM"] = "NEXT BEAM", -- TODO: German translation missing !!!!
    --["NEXT PILLAR"] = "NEXT PILLAR", -- TODO: German translation missing !!!!
    --["BEAM on %s"] = "BEAM on %s", -- TODO: German translation missing !!!!
    --["PILLAR TIMEOUT"] = "PILLAR TIMEOUT", -- TODO: German translation missing !!!!
})
-- Default settings.
mod:RegisterDefaultSetting("LineDataDevourers")
mod:RegisterDefaultSetting("SoundBeamOnYou")
mod:RegisterDefaultSetting("SoundBeamOnOther")
mod:RegisterDefaultSetting("SoundNewWave")
mod:RegisterDefaultSetting("SoundBigCast")
mod:RegisterDefaultSetting("SoundShieldPhase")
mod:RegisterDefaultSetting("SoundJumpPhase")
mod:RegisterDefaultSetting("SoundLaserCountDown")
mod:RegisterDefaultSetting("SoundExplosionCountDown")
mod:RegisterDefaultSetting("OtherPlayerBeamMarkers")
mod:RegisterDefaultSetting("OtherLogicWallMarkers")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["ENRAGE"] = { sColor = "xkcdAmethyst" },
    ["DATA_DEVOURER"] = { sColor = "xkcdBrightLimeGreen" },
    ["NEXT_PILLAR"] = { sColor = "xkcdOrangeYellow" },
    ["BEAM"] = { sColor = "xkcdLipstickRed" },
    ["PILLAR_TIMEOUT"] = { sColor = "xkcdAppleGreen" },
    ["P2"] = { sColor = "xkcdBabyPurple" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local nDataDevourerLastPopTime
local nObstinateLogicWallLastPopTime

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    nDataDevourerLastPopTime = 0
    nObstinateLogicWallLastPopTime = 0
    mod:AddTimerBar("ENRAGE", "Enrage", 576)
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Data Devourer"] then
        if mod:GetSetting("LineDataDevourers") and self:GetDistanceBetweenUnits(unit, GetPlayerUnit()) < 45 then
            core:AddPixie(unit:GetId(), 1, GetPlayerUnit(), unit, "Blue", 5, 10, 10)
        end
        local nCurrentTime = GetGameTime()
        if nDataDevourerLastPopTime + 13 < nCurrentTime then
            nDataDevourerLastPopTime = nCurrentTime
            mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 15)
        end
    elseif self.L["Obstinate Logic Wall"] == sName then
        mod:RemoveTimerBar("PILLAR_TIMEOUT")
        core:AddUnit(unit)
        if mod:GetSetting("OtherLogicWallMarkers") then
            core:MarkUnit(unit)
        end
    end
end

function mod:RemoveLaserMark(nPlayerId)
    core:DropMark(nPlayerId)
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Data Devourer"] then
        core:DropPixie(unit:GetId())
    end
end

function mod:OnChatDC(message)
    local sPlayerFocused = message:match(self.L["Avatus sets his focus on [PlayerName]!"])
    if sPlayerFocused then
        local tPlayerUnit = GameLib.GetPlayerUnitByName(sPlayerFocused)
        local nPlayerId = tPlayerUnit:GetId()
        if nPlayerId and mod:GetSetting("OtherPlayerBeamMarkers") then
            core:MarkUnit(tPlayerUnit, nil, self.L["LASER"])
            self:ScheduleTimer("RemoveLaserMark", 15, nPlayerId)
        end
        local sText = self.L["BEAM on %s"]:format(sPlayerFocused)
        if nPlayerId == GetPlayerUnit():GetId() then
            core:AddMsg("BEAM", sText, 5, mod:GetSetting("SoundBeamOnYou") and "RunAway")
        else
            core:AddMsg("BEAM", sText, 5, mod:GetSetting("SoundBeamOnOther") and "Info", "Blue")
        end
        mod:AddTimerBar("BEAM", sText, 15)
    elseif message == self.L["Avatus prepares to delete all"] then
        core:AddMsg("PILLAR_TIMEOUT", self.L["PILLAR TIMEOUT"], 5, mod:GetSetting("SoundBigCast") and "Beware")
        mod:AddTimerBar("PILLAR_TIMEOUT", "PILLAR TIMEOUT", 10)
        mod:AddTimerBar("NEXT_PILLAR", "NEXT PILLAR", 50)
    elseif message == self.L["Secure Sector Enhancement"] then
        core:AddMsg("P2", self.L["P2: SHIELD PHASE"], 5, mod:GetSetting("SoundShieldPhase") and "Alert")
        mod:AddTimerBar("P2", "EXPLOSION", 15, mod:GetSetting("SoundLaserCountDown"))
        mod:AddTimerBar("BEAM", "NEXT BEAM", 44)
        mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 53)
        mod:AddTimerBar("NEXT_PILLAR", "NEXT PILLAR", 58)
    elseif message == self.L["Vertical Locomotion Enhancement"] then
        core:AddMsg("P2", self.L["P2: JUMP PHASE"], 5, mod:GetSetting("SoundJumpPhase") and "Alert")
        mod:AddTimerBar("P2", "BEGIN OF SCANNING LASER", 15, mod:GetSetting("SoundExplosionCountDown"))
        mod:AddTimerBar("BEAM", "NEXT BEAM", 58)
        mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 68)
        mod:AddTimerBar("NEXT_PILLAR", "NEXT PILLAR", 75)
    end
end
