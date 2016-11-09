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
local mod = core:NewEncounter("Mordechai", 104, 0, 548)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "unit.mordechai" })
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
mod:RegisterMessageSetting("ORB_SPAWNED", "EQUAL", "MessageOrbSpawn", "SoundOrbSpawn")
mod:RegisterMessageSetting("KINETIC_LINK_MSG", "EQUAL", "MessageOrbLink", "SoundOrbLink")
mod:RegisterMessageSetting("SUCKY_PHASE", "EQUAL", "MessageAirlockPhaseSoon", "SoundAirlockPhaseSoon")
mod:RegisterMessageSetting("SHOCKING_ATTRACTION", "EQUAL", "MessageShockingAttraction", "SoundShockingAttraction")
-- Timer default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_ORB_TIMER"] = { sColor = "xkcdLightLightblue" },
    ["NEXT_BARRAGE_TIMER"] = { sColor = "xkcdRed" },
    ["NEXT_SHURIKEN_TIMER"] = { sColor = "xkcdBlue" },
  }
)
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_NULLIFIED = 85614 -- Green
local DEBUFF_KINETIC_LINK = 86797 -- Purple
local DEBUFF_SHOCKING_ATTRACTION = 86861

local PHASES_CLOSE = {
  {UPPER = 86.5, LOWER = 85.5},
  {UPPER = 61.5, LOWER = 60.5},
  {UPPER = 36.5, LOWER = 35.5},
  {UPPER = 11.5, LOWER = 10.5},
}
local FIRST_SHURIKEN_TIMER = 11
local SHURIKEN_TIMER = 22
local FIRST_BARRAGE_TIMER = 19
local BARRAGE_TIMER = 44

local FIRST_ORB_TIMER = 22
local FIRST_ORB_MIDPHASE_TIMER = 15
local ORB_TIMER = 27

local ANCHOR_POSITIONS = {
  { x = 93.849998474121, y = 353.87435913086, z = 209.71000671387 },
  { x = 93.849998474121, y = 353.87435913086, z = 179.71000671387 },
  { x = 123.849998474121, y = 353.87435913086, z = 209.71000671387 },
  { x = 123.849998474121, y = 353.87435913086, z = 179.71000671387 },
}

local MORDECHAI_POSITION = {
  x = 108.84799957275, y = 353.87435913086, z = 194.70899963379
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
  mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", FIRST_ORB_TIMER)
end

function mod:OnBossDisable()
end

mod:RegisterUnitEvents("unit.turret",{
    [core.E.UNIT_CREATED] = function(_, _, unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS)
    end,
    ["cast.turret.discharge"] = {
      [core.E.CAST_START] = function()
        mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", ORB_TIMER)
      end
    }
  }
)

mod:RegisterUnitEvents("unit.mordechai",{
    [core.E.UNIT_CREATED] = function(_, _, unit)
      mordechai = unit
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS + core.E.TRACK_HEALTH)
      mod:AddCleaveLines()
    end,
    [core.E.HEALTH_CHANGED] = function(_, _, percent)
      for i = 1, #PHASES_CLOSE do
        if percent >= PHASES_CLOSE[i].LOWER and percent <= PHASES_CLOSE[i].UPPER then
          mod:AddMsg("SUCKY_PHASE", "msg.phase.start", 5, "Info", "xkcdWhite")
          break
        end
      end
    end,
    ["cast.mordechai.shatter"] = {
      [core.E.CAST_START] = function()
        mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", SHURIKEN_TIMER, mod:GetSetting("SoundShurikenCountdown"))
        mod:RemoveCleaveLines()
      end,
      [core.E.CAST_END] = function()
        mod:AddCleaveLines()
      end,
    },
    ["cast.mordechai.barrage"] = {
      [core.E.CAST_START] = function()
        mod:AddTimerBar("NEXT_BARRAGE_TIMER", "msg.mordechai.barrage.next", BARRAGE_TIMER)
        mod:RemoveCleaveLines()
      end,
      [core.E.CAST_END] = function()
        mod:AddCleaveLines()
      end,
    },
  }
)

mod:RegisterUnitEvents("unit.anchor",{
    [core.E.UNIT_CREATED] = function(_, id, unit)
      anchors[id] = unit
      core:AddUnit(unit)
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
    end,
    [core.E.UNIT_DESTROYED] = function(_, id)
      anchors[id] = nil
    end,
    [core.E.HEALTH_CHANGED] = function(_, id, percent)
      if mod:GetSetting("MarkerAnchorHP") then
        core:MarkUnit(anchors[id], 0, percent)
      end
    end,
  }
)

mod:RegisterUnitEvents("unit.orb",{
    [core.E.UNIT_CREATED] = function()
      mod:AddMsg("ORB_SPAWNED", "msg.orb.spawned", 5, "Info", "xkcdWhite")
    end
  }
)

mod:RegisterDatachronEvent("chron.airlock.closed", "EQUAL", function()
    isAirPhase = false
    mod:AddCleaveLines()
    mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", FIRST_SHURIKEN_TIMER, mod:GetSetting("SoundShurikenCountdown"))
    mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", FIRST_ORB_MIDPHASE_TIMER)
    if numberOfAirPhases >= 2 then
      mod:AddTimerBar("NEXT_BARRAGE_TIMER", "msg.mordechai.barrage.next", FIRST_BARRAGE_TIMER)
    end
    mod:AddAnchorWorldMarkers()
  end
)

mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.UNIT_DESTROYED] = function (self, id, unit, name)
      --Drop mark in case the player dies with the debuff
      core:DropMark(id)
    end,
    [DEBUFF_KINETIC_LINK] = {
      [core.E.DEBUFF_ADD] = function (self, id, spellId, stack, timeRemaining, name, unitCaster)
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
      end,
      [core.E.DEBUFF_REMOVE] = function (self, id, spellId, name, unitCaster)
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

      end,
    },
    [DEBUFF_SHOCKING_ATTRACTION] = {
      [core.E.DEBUFF_ADD] = function (self, id)
        if mod:GetSetting("CrosshairShockingAttraction") then
          core:AddPicture("SHOCKING_ATTRACTION_TARGET_"..id, id, "Crosshair", 30, 0, 0, nil, "blue")
        end
        if id == playerUnit:GetId() then
          mod:AddMsg("SHOCKING_ATTRACTION", "msg.mordechai.shuriken.you", 5, "RunAway", "xkcdBlue")
        end
      end,
      [core.E.DEBUFF_REMOVE] = function (self, id)
        core:RemovePicture("SHOCKING_ATTRACTION_TARGET_"..id)
      end,
    },
  }
)

function mod:AddAnchorWorldMarkers()
  if not mod:GetSetting("WorldMarkerAnchor") then
    return
  end
  for i = 1, #ANCHOR_POSITIONS do
    mod:SetWorldMarker("ANCHOR_"..i, "mark.anchor_"..i, ANCHOR_POSITIONS[i])
  end
end

function mod:RemoveAnchorWorldMarkers()
  if not mod:GetSetting("WorldMarkerAnchor") then
    return
  end
  for i = 1, #ANCHOR_POSITIONS do
    mod:DropWorldMarker("ANCHOR_"..i)
  end
end

function mod:AddCleaveLines()
  if not mod:GetSetting("LinesCleave") or isAirPhase then
    return
  end
  local id = mordechai:GetId()
  core:AddSimpleLine("CLEAVE_FRONT_RIGHT", id, 3.5, 40, 24.5, 5, "white", nil, 3)
  core:AddSimpleLine("CLEAVE_BACK_RIGHT", id, 3.5, 40, 180-24.5, 5, "white", nil, 3)
  core:AddSimpleLine("CLEAVE_FRONT_LEFT", id, 3.5, 40, -24.5, 5, "white", nil, -3)
  core:AddSimpleLine("CLEAVE_BACK_LEFT", id, 3.5, 40, -(180-24.5), 5, "white", nil, -3)

  core:AddSimpleLine("CLEAVE_FRONT_RIGHT2", id, 0, 3.5, 17.5, 5, "white", nil, -5.5)
  core:AddSimpleLine("CLEAVE_BACK_RIGHT2", id, 0, 3.5, 180-17.5, 5, "white", nil, -5.5)
  core:AddSimpleLine("CLEAVE_FRONT_LEFT2", id, 0, 3.5, -17.5, 5, "white", nil, 5.5)
  core:AddSimpleLine("CLEAVE_BACK_LEFT2", id, 0, 3.5, -(180-17.5), 5, "white", nil, 5.5)
end

function mod:RemoveCleaveLines()
  if not mod:GetSetting("LinesCleave") then
    return
  end
  core:RemoveSimpleLine("CLEAVE_FRONT_RIGHT")
  core:RemoveSimpleLine("CLEAVE_BACK_RIGHT")
  core:RemoveSimpleLine("CLEAVE_FRONT_LEFT")
  core:RemoveSimpleLine("CLEAVE_BACK_LEFT")
  core:RemoveSimpleLine("CLEAVE_FRONT_RIGHT2")
  core:RemoveSimpleLine("CLEAVE_BACK_RIGHT2")
  core:RemoveSimpleLine("CLEAVE_FRONT_LEFT2")
  core:RemoveSimpleLine("CLEAVE_BACK_LEFT2")
end
