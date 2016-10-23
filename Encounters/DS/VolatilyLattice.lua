----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- TODO
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Lattice", 52, 98, 116)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Avatus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["unit.wall"] = "Obstinate Logic Wall",
    ["unit.devourer"] = "Data Devourer",
    -- Datachron messages.
    ["chron.avatus.laser"] = "Avatus sets his focus on ([^%s]+%s[^!]+)!",
    ["chron.avatus.delete"] = "Avatus prepares to delete all data!",
    ["chron.station.secure"] = "The Secure Sector Enhancement Ports have been activated!",
    ["chron.station.jump"] = "The Vertical Locomotion Enhancement Ports have been activated!",
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
    ["msg.beam.x"] = "BEAM on %s",
    ["msg.beam.you"] = "BEAM on YOU",
    -- Marks
    ["mark.laser"] = "LASER",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["unit.wall"] = "Mur de logique obstiné",
    ["unit.devourer"] = "Dévoreur de données",
    -- Datachron messages.
    --["chron.avatus.laser"] = "Avatus sets his focus on (.*)!", -- TODO: French translation missing !!!!
    ["chron.avatus.delete"] = "Avatus se prépare à effacer toutes les données !",
    ["chron.station.secure"] = "Les ports d'amélioration de secteur sécurisé ont été activés !",
    ["chron.station.jump"] = "Les ports d'amélioration de locomotion verticale ont été activés !",
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
    ["msg.beam.x"] = "LASER sur %s",
    ["msg.beam.you"] = "LASER sur VOUS",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["unit.wall"] = "Hartnäckige Logikmauer",
    ["unit.devourer"] = "Datenverschlinger",
    -- Datachron messages.
    -- Cast.
    ["Null and Void"] = "Unordnung und Chaos",
    -- Bar and messages.
    ["msg.beam.x"] = "LASER auf %s",
    ["msg.beam.you"] = "LASER auf DIR",
  }
)
-- Default settings.
-- Visuals.
mod:RegisterDefaultSetting("LineDataDevourers")
mod:RegisterDefaultSetting("OtherPlayerBeamMarkers")
mod:RegisterDefaultSetting("OtherLogicWallMarkers")
-- Messages.
mod:RegisterDefaultSetting("MessageBeamOnYou")
mod:RegisterDefaultSetting("MessageBeamOnOther")
mod:RegisterDefaultSetting("MessageBigCast")
mod:RegisterDefaultSetting("MessageShieldPhase")
mod:RegisterDefaultSetting("MessageJumpPhase")
-- Sounds.
mod:RegisterDefaultSetting("SoundBeamOnYou")
mod:RegisterDefaultSetting("SoundBeamOnOther")
mod:RegisterDefaultSetting("SoundBigCast")
mod:RegisterDefaultSetting("SoundShieldPhase")
mod:RegisterDefaultSetting("SoundJumpPhase")
mod:RegisterDefaultSetting("SoundLaserCountDown")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["ENRAGE"] = { sColor = "xkcdAmethyst" },
    ["DATA_DEVOURER"] = { sColor = "xkcdBrightLimeGreen" },
    ["NEXT_PILLAR"] = { sColor = "xkcdOrangeYellow" },
    ["BEAM"] = { sColor = "xkcdLipstickRed" },
    ["PILLAR_TIMEOUT"] = { sColor = "xkcdAppleGreen" },
    ["P2"] = { sColor = "xkcdBabyPurple" },
  }
)
mod:RegisterMessageSetting("BEAM_YOU", core.E.COMPARE_EQUAL, "MessageBeamOnYou", "SoundBeamOnYou")
mod:RegisterMessageSetting("BEAM_OTHER", core.E.COMPARE_EQUAL, "MessageBeamOnOther", "SoundBeamOnOther")
mod:RegisterMessageSetting("P2_SHIELD", core.E.COMPARE_EQUAL, "MessageShieldPhase", "SoundShieldPhase")
mod:RegisterMessageSetting("P2_JUMP", core.E.COMPARE_EQUAL, "MessageJumpPhase", "SoundJumpPhase")
mod:RegisterMessageSetting("PILLAR_TIMEOUT", core.E.COMPARE_EQUAL, "MessageBigCast", "SoundBigCast")

----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local lastDataDevourerTime
local playerId

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerId = GameLib.GetPlayerUnit():GetId()
  lastDataDevourerTime = 0
  mod:AddTimerBar("ENRAGE", "Enrage", 576)
  mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 10)
  mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 45)
end

function mod:OnDataDevourerCreated(id, unit, name)
  if mod:GetSetting("LineDataDevourers") then
    local line = core:AddLineBetweenUnits(id, playerId, id, 5, "blue")
    line:SetMaxLengthVisible(45)
  end
  local currentTime = GetGameTime()
  if lastDataDevourerTime + 13 < currentTime then
    lastDataDevourerTime = currentTime
    mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 15)
  end
end

function mod:OnDataDevourerDestroyed(id, unit, name)
  core:RemoveLineBetweenUnits(id)
end
mod:RegisterUnitEvents("unit.devourer",{
    [core.E.UNIT_CREATED] = mod.OnDataDevourerCreated,
    [core.E.UNIT_DESTROYED] = mod.OnDataDevourerDestroyed,
  }
)

function mod:OnWallCreated(id, unit, name)
  mod:RemoveTimerBar("PILLAR_TIMEOUT")
  core:AddUnit(unit)
  if mod:GetSetting("OtherLogicWallMarkers") then
    core:MarkUnit(unit)
  end
end
mod:RegisterUnitEvent("unit.wall", core.E.UNIT_CREATED, mod.OnWallCreated)

function mod:DropLaserMark(id)
  if id then
    core:DropMark(id)
  end
end

function mod:MarkOtherLaserTargets(isMyself, unit)
  if not isMyself and mod:GetSetting("OtherPlayerBeamMarkers") then
    mod:MarkUnit(unit, core.E.LOCATION_STATIC_CHEST, "mark.laser", "xkcdRed")
  end
end

function mod:ShowBeamMessages(isMyself, text)
  if isMyself then
    mod:AddMsg("BEAM_YOU", "msg.laser.you", 5, "RunAway")
  else
    mod:AddMsg("BEAM_OTHER", text, 5, "Info", "xkcdBlue")
  end
end

function mod:OnLaserDatachron(message, laserTargetName)
  local targetUnit = GetPlayerUnitByName(laserTargetName)
  local isMyself = targetUnit and targetUnit:IsThePlayer() or false
  local laserMarkId = targetUnit and targetUnit:GetId() or nil
  local text = self.L["msg.beam.x"]:format(laserTargetName)
  mod:ShowBeamMessages(isMyself, text)
  mod:MarkOtherLaserTargets(isMyself, targetUnit)
  mod:AddTimerBar("BEAM", text, 15, nil, nil, mod.DropLaserMark, mod, laserMarkId)
end
mod:RegisterDatachronEvent("chron.avatus.laser", core.E.COMPARE_MATCH, mod.OnLaserDatachron)

function mod:OnDeleteDatachron(message)
  mod:AddMsg("PILLAR_TIMEOUT", "Pillar Timeout", 5, "Beware")
  mod:AddTimerBar("PILLAR_TIMEOUT", "Pillar Timeout", 10)
  mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 50)
end
mod:RegisterDatachronEvent("chron.avatus.delete", core.E.COMPARE_EQUAL, mod.OnDeleteDatachron)

function mod:OnSecureDatachron(message)
  mod:AddMsg("P2_SHIELD", "P2: SHIELD PHASE", 5, "Alert")
  mod:AddTimerBar("P2", "Explosion", 15, mod:GetSetting("SoundLaserCountDown"))
  mod:AddTimerBar("BEAM", "Next Beam", 44)
  mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 53)
  mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 58)
end
mod:RegisterDatachronEvent("chron.station.secure", core.E.COMPARE_EQUAL, mod.OnSecureDatachron)

function mod:OnJumpDatachron(message)
  mod:AddMsg("P2_JUMP", "P2: JUMP PHASE", 5, "Alert")
  mod:AddTimerBar("BEAM", "Next Beam", 58)
  mod:AddTimerBar("DATA_DEVOURER", "Next Data Devourer", 68)
  mod:AddTimerBar("NEXT_PILLAR", "Next Pillar", 75)
end
mod:RegisterDatachronEvent("chron.station.jump", core.E.COMPARE_EQUAL, mod.OnJumpDatachron)
