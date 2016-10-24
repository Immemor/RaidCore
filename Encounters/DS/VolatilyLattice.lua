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
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "unit.avatus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.avatus"] = "Avatus",
    ["unit.wall"] = "Obstinate Logic Wall",
    ["unit.devourer"] = "Data Devourer",
    -- Datachron messages.
    ["chron.avatus.laser"] = "Avatus sets his focus on ([^%s]+%s[^!]+)!",
    ["chron.avatus.delete"] = "Avatus prepares to delete all data!",
    ["chron.station.secure"] = "The Secure Sector Enhancement Ports have been activated!",
    ["chron.station.jump"] = "The Vertical Locomotion Enhancement Ports have been activated!",
    -- Cast.
    ["cast.avatus.null_void"] = "Null and Void",
    -- Timer bars.
    ["msg.beam.next"] = "Next Beam",
    ["msg.pillar.next"] = "Next Pillar",
    ["msg.pillar.timeout"] = "Pillar Timeout",
    ["msg.enrage"] = "Enrage",
    ["msg.explosion"] = "Explosion",
    ["msg.devourer.next"] = "Next Data Devourers",
    -- Message bars.
    ["msg.phase.shield"] = "P2: SHIELD PHASE",
    ["msg.phase.jump"] = "P2: JUMP PHASE",
    ["msg.beam.x"] = "BEAM on %s",
    ["msg.beam.you"] = "BEAM on YOU",
    -- Marks
    ["mark.laser"] = "LASER",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.wall"] = "Mur de logique obstiné",
    ["unit.devourer"] = "Dévoreur de données",
    -- Datachron messages.
    --["chron.avatus.laser"] = "Avatus sets his focus on (.*)!", -- TODO: French translation missing !!!!
    ["chron.avatus.delete"] = "Avatus se prépare à effacer toutes les données !",
    ["chron.station.secure"] = "Les ports d'amélioration de secteur sécurisé ont été activés !",
    ["chron.station.jump"] = "Les ports d'amélioration de locomotion verticale ont été activés !",
    -- Cast.
    ["cast.avatus.null_void"] = "Caduque",
    -- Timer bars.
    ["msg.beam.next"] = "Prochain Laser",
    ["msg.pillar.next"] = "Prochain Pillier",
    ["msg.devourer.next"] = "Prochain Dévoreur",
    ["msg.pillar.timeout"] = "Pillier Expiration",
    -- Message bars.
    ["msg.phase.shield"] = "P2: PHASE BOUCLIER",
    ["msg.phase.jump"] = "P2: PHASE SAUTER",
    ["msg.beam.x"] = "LASER sur %s",
    ["msg.beam.you"] = "LASER sur VOUS",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.wall"] = "Hartnäckige Logikmauer",
    ["unit.devourer"] = "Datenverschlinger",
    -- Datachron messages.
    -- Cast.
    ["cast.avatus.null_void"] = "Unordnung und Chaos",
    -- Timer bars.
    ["msg.beam.next"] = "Nächster Laser",
    ["msg.pillar.next"] = "Nächste Säulen",
    ["msg.devourer.next"] = "Nächste Datenverschlinger",
    ["msg.pillar.timeout"] = "Säulen Time-out",
    -- Bar and messages.
    ["msg.phase.shield"] = "P2: SCHILD-PHASE",
    ["msg.phase.jump"] = "P2: SPRING-PHASE",
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
mod:RegisterMessageSetting("BEAM_YOU", "EQUAL", "MessageBeamOnYou", "SoundBeamOnYou")
mod:RegisterMessageSetting("BEAM_OTHER", "EQUAL", "MessageBeamOnOther", "SoundBeamOnOther")
mod:RegisterMessageSetting("P2_SHIELD", "EQUAL", "MessageShieldPhase", "SoundShieldPhase")
mod:RegisterMessageSetting("P2_JUMP", "EQUAL", "MessageJumpPhase", "SoundJumpPhase")
mod:RegisterMessageSetting("PILLAR_TIMEOUT", "EQUAL", "MessageBigCast", "SoundBigCast")

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
  mod:AddTimerBar("ENRAGE", "msg.enrage", 576)
  mod:AddTimerBar("DATA_DEVOURER", "msg.devourer.next", 10)
  mod:AddTimerBar("NEXT_PILLAR", "msg.pillar.next", 45)
end

function mod:OnDataDevourerCreated(id, unit, name)
  if mod:GetSetting("LineDataDevourers") then
    local line = core:AddLineBetweenUnits(id, playerId, id, 5, "blue")
    line:SetMaxLengthVisible(45)
  end
  local currentTime = GetGameTime()
  if lastDataDevourerTime + 13 < currentTime then
    lastDataDevourerTime = currentTime
    mod:AddTimerBar("DATA_DEVOURER", "msg.devourer.next", 15)
  end
end

function mod:OnDataDevourerDestroyed(id, unit, name)
  core:RemoveLineBetweenUnits(id)
end
function mod:OnWallCreated(id, unit, name)
  mod:RemoveTimerBar("PILLAR_TIMEOUT")
  core:AddUnit(unit)
  if mod:GetSetting("OtherLogicWallMarkers") then
    core:MarkUnit(unit)
  end
end

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

function mod:OnDeleteDatachron(message)
  mod:AddMsg("PILLAR_TIMEOUT", "msg.pillar.timeout", 5, "Beware")
  mod:AddTimerBar("PILLAR_TIMEOUT", "msg.pillar.timeout", 10)
  mod:AddTimerBar("NEXT_PILLAR", "msg.pillar.next", 50)
end

function mod:OnSecureDatachron(message)
  mod:AddMsg("P2_SHIELD", "msg.phase.shield", 5, "Alert")
  mod:AddTimerBar("P2", "msg.explosion", 15, mod:GetSetting("SoundLaserCountDown"))
  mod:AddTimerBar("BEAM", "msg.beam.next", 44)
  mod:AddTimerBar("DATA_DEVOURER", "msg.devourer.next", 53)
  mod:AddTimerBar("NEXT_PILLAR", "msg.pillar.next", 58)
end

function mod:OnJumpDatachron(message)
  mod:AddMsg("P2_JUMP", "msg.phase.jump", 5, "Alert")
  mod:AddTimerBar("BEAM", "msg.beam.next", 58)
  mod:AddTimerBar("DATA_DEVOURER", "msg.devourer.next", 68)
  mod:AddTimerBar("NEXT_PILLAR", "msg.pillar.next", 75)
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvent("unit.wall", core.E.UNIT_CREATED, mod.OnWallCreated)
mod:RegisterUnitEvents("unit.devourer",{
    [core.E.UNIT_CREATED] = mod.OnDataDevourerCreated,
    [core.E.UNIT_DESTROYED] = mod.OnDataDevourerDestroyed,
  }
)
mod:RegisterDatachronEvent("chron.station.secure", "EQUAL", mod.OnSecureDatachron)
mod:RegisterDatachronEvent("chron.station.jump", "EQUAL", mod.OnJumpDatachron)
mod:RegisterDatachronEvent("chron.avatus.laser", "MATCH", mod.OnLaserDatachron)
mod:RegisterDatachronEvent("chron.avatus.delete", "EQUAL", mod.OnDeleteDatachron)
