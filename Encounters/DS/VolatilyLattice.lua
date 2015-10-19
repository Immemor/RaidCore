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
    -- Timer bars.
    ["Next Beam"] = "Next Beam",
    ["Next Pillar"] = "Next Pillar",
    ["Pillar Timeout"] = "Pillar Timeout",
    ["Enrage"] = "Enrage",
    ["Explosion"] = "Explosion",
    -- Message bars.
    ["P2: SHIELD PHASE"] = "P2: SHIELD PHASE",
    ["P2: JUMP PHASE"] = "P2: JUMP PHASE",
    ["LASER"] = "LASER",
    ["BEAM on %s"] = "BEAM on %s",
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
    -- Timer bars.
    ["Next Beam"] = "Prochain Laser",
    ["Next Pillar"] = "Prochain Pillier",
    ["Pillar Timeout"] = "Pillier Expiration",
    ["Enrage"] = "Enrage",
    ["Explosion"] = "Explosion",
    -- Message bars.
    ["P2: SHIELD PHASE"] = "P2: PHASE BOUCLIER",
    ["P2: JUMP PHASE"] = "P2: PHASE SAUTER",
    ["LASER"] = "LASER",
    ["BEAM on %s"] = "LASER sur %s",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Obstinate Logic Wall"] = "Hartnäckige Logikmauer",
    ["Data Devourer"] = "Datenverschlinger",
    -- Datachron messages.
    -- Cast.
    ["Null and Void"] = "Unordnung und Chaos",
    -- Bar and messages.
})
-- Default settings.
mod:RegisterDefaultSetting("LineDataDevourers")
mod:RegisterDefaultSetting("SoundBeamOnYou")
mod:RegisterDefaultSetting("SoundBeamOnOther")
mod:RegisterDefaultSetting("SoundBigCast")
mod:RegisterDefaultSetting("SoundShieldPhase")
mod:RegisterDefaultSetting("SoundJumpPhase")
mod:RegisterDefaultSetting("SoundLaserCountDown")
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

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local nDataDevourerLastPopTime

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    nDataDevourerLastPopTime = 0
    mod:AddTimerBar("ENRAGE", "Enrage", 576)
    mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 10)
    mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 45)
end

function mod:OnUnitCreated(nId, unit, sName)
    if sName == self.L["Data Devourer"] then
        if mod:GetSetting("LineDataDevourers") then
            local line = core:AddLineBetweenUnits(nId, GetPlayerUnit():GetId(), nId, 5, "blue")
            line:SetMaxLengthVisible(45)
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

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Data Devourer"] then
        core:RemoveLineBetweenUnits(nId)
    end
end

function mod:OnDatachron(sMessage)
    local sPlayerFocused = sMessage:match(self.L["Avatus sets his focus on [PlayerName]!"])
    if sPlayerFocused then
        local tPlayerUnit = GameLib.GetPlayerUnitByName(sPlayerFocused)
        local nPlayerId = tPlayerUnit:GetId()
        if nPlayerId and mod:GetSetting("OtherPlayerBeamMarkers") then
            core:MarkUnit(tPlayerUnit, nil, self.L["LASER"])
            self:ScheduleTimer(function(nPlayerId)
                core:DropMark(nPlayerId)
            end, 15, nPlayerId)
        end
        local sText = self.L["BEAM on %s"]:format(sPlayerFocused)
        if nPlayerId == GetPlayerUnit():GetId() then
            mod:AddMsg("BEAM", sText, 5, mod:GetSetting("SoundBeamOnYou") and "RunAway")
        else
            mod:AddMsg("BEAM", sText, 5, mod:GetSetting("SoundBeamOnOther") and "Info", "Blue")
        end
        mod:AddTimerBar("BEAM", sText, 15)
    elseif sMessage == self.L["Avatus prepares to delete all"] then
        mod:AddMsg("PILLAR_TIMEOUT", "Pillar Timeout", 5, mod:GetSetting("SoundBigCast") and "Beware")
        mod:AddTimerBar("PILLAR_TIMEOUT", "Pillar Timeout", 10)
        mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 50)
    elseif sMessage == self.L["Secure Sector Enhancement"] then
        mod:AddMsg("P2", "P2: SHIELD PHASE", 5, mod:GetSetting("SoundShieldPhase") and "Alert")
        mod:AddTimerBar("P2", "Explosion", 15, mod:GetSetting("SoundLaserCountDown"))
        mod:AddTimerBar("BEAM", "Next Beam", 44)
        mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 53)
        mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 58)
    elseif sMessage == self.L["Vertical Locomotion Enhancement"] then
        mod:AddMsg("P2", "P2: JUMP PHASE", 5, mod:GetSetting("SoundJumpPhase") and "Alert")
        mod:AddTimerBar("BEAM", "Next Beam", 58)
        mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 68)
        mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 75)
    end
end
