----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- TODO
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Mordechai", 104, 0, 548)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.mordechai" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.mordechai"] = "Mordechai Redmoon",
    ["unit.anchor"] = "Airlock Anchor",
    ["unit.orb"] = "Kinetic Orb",
    ["unit.junk"] = "Airlock Junk",
    ["unit.invis.0"] = "Hostile Invisible Unit for Fields (0 hit radius)", -- ??
    ["unit.shuriken"] = "Ignores Collision Big Base Invisible Unit for Spells (1 hit radius)",
    ["unit.turret"] = "Redmoon Turret",
    -- Cast names.
    ["cast.mordechai.cross"] = "Cross Shot",
    ["cast.mordechai.shatter"] = "Shatter Shock",
    ["cast.mordechai.barrage"] = "Vicious Barrage",
    ["cast.turret.discharge"] = "Kinetic Discharge",
    -- Datachrons.
    ["chron.airlock.opened"] = "The airlock has been opened!",
    ["chron.airlock.closed"] = "The airlock has been closed!",
    -- Markers.
    ["mark.anchor_1"] = "1",
    ["mark.anchor_2"] = "2",
    ["mark.anchor_3"] = "3",
    ["mark.anchor_4"] = "4",
    -- Buffs.
    ["buffs.airlock.decompression"] = "Decompression",
    ["buffs.orb.discharge"] = "Kinetic Discharge",
    ["buffs.mordechai.shatter"] = "Shatter Shock",
    ["buffs.mordechai.attraction"] = "Shocking Attraction",
    ["buffs.airlock.anchor"] = "Anchor Lockdown",
    -- Says.
    ["say.mordechai.airlock.open"] = "I'll send ye into the great black, ye gutless mud skuppers!",
    ["say.mordechai.airlock.close"] = "Shut that bloody airlock, damn ye!",
    ["say.mordechai.1"] = "Dine on me hot flux, lubbers!",
    ["say.mordechai.3"] = "Where ye be goin', cowards? Ha ha! Nowhere but the grave!",
    -- Messages.
    ["msg.mordechai.shuriken.next"] = "Next Shuriken",
    ["msg.mordechai.barrage.next"] = "Next Vicious Barrage",
    ["msg.phase.start"] = "SUCKY SUCKY PHASE SOON",
    ["msg.orb.spawned"] = "ORB",
    ["msg.orb.kinetic_link"] = "DPS THE ORB!",
    ["msg.orb.next"] = "Next Orb",
    ["msg.mordechai.shuriken.you"] = "SHURIKEN ON YOU"
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.invis.0"] = "Feindselige unsichtbare Einheit für Felder (Trefferradius 0)", -- ??
    ["unit.turret"] = "Rotmonds Geschützturm",
    -- Buffs.
    ["buffs.org.kinetic_link"] = "Kinetische Verbindung",
    ["buffs.orb.fixation"] = "Kinetische Fixierung",
    -- Says.
    ["say.mordechai.airlock.open"] = "Ich schicke euch in die Große Schwärze, ihr feigen Schlammspringer!",
    ["say.mordechai.airlock.close"] = "Macht die verfluchte Luftschleuse zu, verdammt noch mal!",
    ["say.mordechai.1"] = "Fresst meinen heißen Flux, ihr Landratten!",
    ["say.mordechai.2"] = "Ab ins Nichts!",
    ["say.mordechai.3"] = "Wo wollt ihr denn hin, ihr Memmen? Ha, ha! Höchstens in euer Grab!",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.invis.0"] = "Unité hostile invisible de terrain (rayon de portée : 0)", -- ??
    ["unit.turret"] = "Tourelle de Rougelune",
    -- Buffs.
    ["buffs.orb.kinetic_link"] = "Lien cinétique",
    ["buffs.orb.fixation"] = "Fixation cinétique",
    -- Says.
    ["say.mordechai.airlock.open"] = "Vous allez bouffer des pissenlits par la racine, espèces de sabordeurs dégonflés !",
    ["say.mordechai.airlock.close"] = "Fermez ce maudit sas, abrutis !",
    ["say.mordechai.1"] = "Vous allez tous crever, bande d'asticots !",
    ["say.mordechai.2"] = "Allez, ouste, dans l'vide !",
    ["say.mordechai.3"] = "Où est-ce que vous pensez aller, bande de lâches ? Ha ha ! Ici, c'est l'terminus !",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("LinesCleave")
mod:RegisterDefaultSetting("WorldMarkerAnchor")
mod:RegisterDefaultSetting("MarkerAnchorHP")
mod:RegisterDefaultSetting("CrosshairShockingAttraction")
mod:RegisterDefaultSetting("MarkerPurple")
mod:RegisterDefaultSetting("LinePurple")
-- Sounds.
mod:RegisterDefaultSetting("SoundOrbSpawn")
mod:RegisterDefaultSetting("SoundOrbLink")
mod:RegisterDefaultSetting("SoundAirlockPhaseSoon")
mod:RegisterDefaultSetting("SoundShockingAttraction")
mod:RegisterDefaultSetting("SoundShurikenCountdown")
-- Messages.
mod:RegisterDefaultSetting("MessageOrbSpawn")
mod:RegisterDefaultSetting("MessageOrbLink")
mod:RegisterDefaultSetting("MessageAirlockPhaseSoon")
mod:RegisterDefaultSetting("MessageShockingAttraction")
-- Binds.
mod:RegisterMessageSetting("ORB_SPAWNED", core.E.COMPARE_EQUAL, "MessageOrbSpawn", "SoundOrbSpawn")
mod:RegisterMessageSetting("KINETIC_LINK_MSG", core.E.COMPARE_EQUAL, "MessageOrbLink", "SoundOrbLink")
mod:RegisterMessageSetting("SUCKY_PHASE", core.E.COMPARE_EQUAL, "MessageAirlockPhaseSoon", "SoundAirlockPhaseSoon")
mod:RegisterMessageSetting("SHOCKING_ATTRACTION", core.E.COMPARE_EQUAL, "MessageShockingAttraction", "SoundShockingAttraction")
-- Timer default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_ORB_TIMER"] = { sColor = "xkcdLightLightblue" },
    ["NEXT_BARRAGE_TIMER"] = { sColor = "xkcdRed" },
    ["NEXT_SHURIKEN_TIMER"] = { sColor = "xkcdBlue" },
  }
)
mod:RegisterUnitBarConfig("unit.mordechai", {
    nPriority = 0,
    tMidphases = {
      {percent = 85},
      {percent = 60},
      {percent = 35},
      {percent = 10},
    }
  }
)
mod:RegisterUnitBarConfig("unit.orb", {
    barColor = "xkcdPurplePink",
  }
)
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  NULLIFIED = 85614, -- Green
  KINETIC_LINK = 86797, -- Purple
  SHOCKING_ATTRACTION = 86861,
}

local TIMERS = {
  SHURIKEN = {
    FIRST = 11,
    NORMAL = 22,
  },
  BARRAGE = {
    FIRST = 19,
    NORMAL = 44,
  },
  ORB = {
    FIRST = 22,
    AFTER_MID = 15,
    NORMAL = 27,
  }
}

local ANCHOR_POSITIONS = {
  { x = 93.849998474121, y = 353.87435913086, z = 209.71000671387 },
  { x = 93.849998474121, y = 353.87435913086, z = 179.71000671387 },
  { x = 123.849998474121, y = 353.87435913086, z = 209.71000671387 },
  { x = 123.849998474121, y = 353.87435913086, z = 179.71000671387 },
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local mordechai
local anchors
local anchorCount
local playerUnit
local numberOfAirPhases
local isAirPhase
local orbs
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  anchors = {}
  orbs = {}
  anchorCount = 0
  numberOfAirPhases = 0
  isAirPhase = false
  mod:AddAnchorWorldMarkers()
  mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", TIMERS.ORB.FIRST)
end

function mod:OnBarUnitCreated(id, unit, name)
  mod:AddUnit(unit)
end

function mod:OnTurretCreated(id, unit, name)
  core:WatchUnit(unit, core.E.TRACK_CASTS)
end

function mod:OnTurretCastOrbStart()
  mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", TIMERS.ORB.NORMAL)
end

function mod:OnMordechaiCreated(id, unit, name)
  mordechai = unit
  core:WatchUnit(unit, core.E.TRACK_CASTS + core.E.TRACK_HEALTH)
  mod:AddCleaveLines()
end

function mod:OnMordechaiHealthChanged(id, percent, name)
  if mod:IsMidphaseClose(name, percent) then
    mod:AddMsg("SUCKY_PHASE", "msg.phase.start", 5, "Info", "xkcdWhite")
  end
end

function mod:OnMordechaiShatterStart()
  mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", TIMERS.SHURIKEN.NORMAL, mod:GetSetting("SoundShurikenCountdown"))
  mod:RemoveCleaveLines()
end

function mod:OnMordechaiBarrageStart()
  mod:AddTimerBar("NEXT_BARRAGE_TIMER", "msg.mordechai.barrage.next", TIMERS.BARRAGE.NORMAL)
  mod:RemoveCleaveLines()
end

function mod:OnAnchorCreated(id, unit, name)
  anchors[id] = unit
  core:WatchUnit(unit, core.E.TRACK_HEALTH)
  if mod:GetSetting("MarkerAnchorHP") then
    core:MarkUnit(unit, 0, 100)
  end

  anchorCount = anchorCount + 1
  if anchorCount == 4 then
    isAirPhase = true
    numberOfAirPhases = numberOfAirPhases + 1
    mod:RemoveAnchorWorldMarkers()
    mod:RemoveCleaveLines()
    mod:RemoveTimerBar("NEXT_ORB_TIMER")
    mod:RemoveTimerBar("NEXT_BARRAGE_TIMER")
    mod:RemoveTimerBar("NEXT_SHURIKEN_TIMER")
    anchorCount = 0
  end
end

function mod:OnAnchorDestroyed(id, unit, name)
  anchors[id] = nil
end

function mod:OnAnchorHealthChanged(id, percent)
  if mod:GetSetting("MarkerAnchorHP") then
    core:MarkUnit(anchors[id], 0, percent)
  end
end

function mod:OnOrbCreated()
  mod:AddMsg("ORB_SPAWNED", "msg.orb.spawned", 5, "Info", "xkcdWhite")
end

function mod:OnAirlockClosed()
  isAirPhase = false
  mod:AddCleaveLines()
  mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", TIMERS.SHURIKEN.FIRST, mod:GetSetting("SoundShurikenCountdown"))
  mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", TIMERS.ORB.AFTER_MID)
  if numberOfAirPhases >= 2 then
    mod:AddTimerBar("NEXT_BARRAGE_TIMER", "msg.mordechai.barrage.next", TIMERS.BARRAGE.FIRST)
  end
  mod:AddAnchorWorldMarkers()
end

function mod:OnAnyUnitDestroyed(id, unit, name)
  core:DropMark(id)
end

function mod:OnKineticLinkAdded(id, spellId, stack, timeRemaining, name, unitCaster)
  if mod:GetSetting("MarkerPurple") then
    core:MarkUnit(GetUnitById(id), core.E.LOCATION_STATIC_CHEST, "P", "xkcdPurplePink")
  end

  if id ~= playerUnit:GetId() then -- not on myself
    return
  end

  mod:AddMsg("KINETIC_LINK_MSG", "msg.orb.kinetic_link", 5, "Burn", "xkcdPurplePink")

  if mod:GetSetting("LinePurple") then
    local casterId = unitCaster:GetId()
    orbs[casterId] = unitCaster
    core:AddLineBetweenUnits("PURPLE_LINE_"..casterId, id, casterId, 7, "xkcdLightMagenta")
  end
end

function mod:OnKineticLinkRemoved(id, spellId, name, unitCaster)
  core:DropMark(id)
  if unitCaster then
    local casterId = unitCaster:GetId()
    orbs[casterId] = nil
    core:RemoveLineBetweenUnits("PURPLE_LINE_"..casterId)
  else
    for casterId, unit in next, orbs do
      if not unit:IsValid() then
        orbs[casterId] = nil
        core:RemoveLineBetweenUnits("PURPLE_LINE_"..casterId)
      end
    end
  end
end

function mod:OnShockingAttractionAdded(id)
  if mod:GetSetting("CrosshairShockingAttraction") then
    core:AddPicture("SHOCKING_ATTRACTION_TARGET_"..id, id, "Crosshair", 30, 0, 0, nil, "blue")
  end
  if id == playerUnit:GetId() then
    mod:AddMsg("SHOCKING_ATTRACTION", "msg.mordechai.shuriken.you", 5, "RunAway", "xkcdBlue")
  end
end

function mod:OnShockingAttractionRemoved(id)
  core:RemovePicture("SHOCKING_ATTRACTION_TARGET_"..id)
end

function mod:AddAnchorWorldMarkers()
  if not mod:GetSetting("WorldMarkerAnchor") then return end
  for i = 1, #ANCHOR_POSITIONS do
    mod:SetWorldMarker("ANCHOR_"..i, "mark.anchor_"..i, ANCHOR_POSITIONS[i])
  end
end

function mod:RemoveAnchorWorldMarkers()
  if not mod:GetSetting("WorldMarkerAnchor") then return end
  for i = 1, #ANCHOR_POSITIONS do
    mod:DropWorldMarker("ANCHOR_"..i)
  end
end

function mod:AddCleaveLines()
  if not mod:GetSetting("LinesCleave") or isAirPhase then return end
  core:AddSimpleLine("CLEAVE_FRONT_RIGHT", mordechai, 3.5, 40, 24.5, 5, "white", nil, 3)
  core:AddSimpleLine("CLEAVE_BACK_RIGHT", mordechai, 3.5, 40, 180-24.5, 5, "white", nil, 3)
  core:AddSimpleLine("CLEAVE_FRONT_LEFT", mordechai, 3.5, 40, -24.5, 5, "white", nil, -3)
  core:AddSimpleLine("CLEAVE_BACK_LEFT", mordechai, 3.5, 40, -(180-24.5), 5, "white", nil, -3)

  core:AddSimpleLine("CLEAVE_FRONT_RIGHT2", mordechai, 0, 3.5, 17.5, 5, "white", nil, -5.5)
  core:AddSimpleLine("CLEAVE_BACK_RIGHT2", mordechai, 0, 3.5, 180-17.5, 5, "white", nil, -5.5)
  core:AddSimpleLine("CLEAVE_FRONT_LEFT2", mordechai, 0, 3.5, -17.5, 5, "white", nil, 5.5)
  core:AddSimpleLine("CLEAVE_BACK_LEFT2", mordechai, 0, 3.5, -(180-17.5), 5, "white", nil, 5.5)
end

function mod:RemoveCleaveLines()
  if not mod:GetSetting("LinesCleave") then return end
  core:RemoveSimpleLine("CLEAVE_FRONT_RIGHT")
  core:RemoveSimpleLine("CLEAVE_BACK_RIGHT")
  core:RemoveSimpleLine("CLEAVE_FRONT_LEFT")
  core:RemoveSimpleLine("CLEAVE_BACK_LEFT")
  core:RemoveSimpleLine("CLEAVE_FRONT_RIGHT2")
  core:RemoveSimpleLine("CLEAVE_BACK_RIGHT2")
  core:RemoveSimpleLine("CLEAVE_FRONT_LEFT2")
  core:RemoveSimpleLine("CLEAVE_BACK_LEFT2")
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.mordechai",{
    [core.E.UNIT_CREATED] = mod.OnMordechaiCreated,
    [core.E.HEALTH_CHANGED] = mod.OnMordechaiHealthChanged,
    ["cast.mordechai.shatter"] = {
      [core.E.CAST_START] = mod.OnMordechaiShatterStart,
      [core.E.CAST_END] = mod.AddCleaveLines,
    },
    ["cast.mordechai.barrage"] = {
      [core.E.CAST_START] = mod.OnMordechaiBarrageStart,
      [core.E.CAST_END] = mod.AddCleaveLines,
    },
  }
)
mod:RegisterUnitEvents("unit.turret",{
    [core.E.UNIT_CREATED] = mod.OnTurretCreated,
    ["cast.turret.discharge"] = {
      [core.E.CAST_START] = mod.OnTurretCastOrbStart,
    }
  }
)
mod:RegisterUnitEvents("unit.anchor",{
    [core.E.UNIT_CREATED] = mod.OnAnchorCreated,
    [core.E.UNIT_DESTROYED] = mod.OnAnchorDestroyed,
    [core.E.HEALTH_CHANGED] = mod.OnAnchorHealthChanged,
  }
)
mod:RegisterUnitEvent("unit.orb", core.E.UNIT_CREATED, mod.OnOrbCreated)
mod:RegisterDatachronEvent("chron.airlock.closed", core.E.COMPARE_EQUAL, mod.OnAirlockClosed)
mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.UNIT_DESTROYED] = mod.OnAnyUnitDestroyed,
    [DEBUFFS.KINETIC_LINK] = {
      [core.E.DEBUFF_ADD] = mod.OnKineticLinkAdded,
      [core.E.DEBUFF_REMOVE] = mod.OnKineticLinkRemoved,
    },
    [DEBUFFS.SHOCKING_ATTRACTION] = {
      [core.E.DEBUFF_ADD] = mod.OnShockingAttractionAdded,
      [core.E.DEBUFF_REMOVE] = mod.OnShockingAttractionRemoved,
    },
  }
)
mod:RegisterUnitEvents({
    "unit.mordechai",
    "unit.anchor",
    "unit.orb",
    },{
    [core.E.UNIT_CREATED] = mod.OnBarUnitCreated,
  }
)
