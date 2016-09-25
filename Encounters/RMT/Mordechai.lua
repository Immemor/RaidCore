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
    ["cast.turret.discharge"] = "Kinetic Discharge",
    -- Datachrons.
    ["chron.airlock.opened"] = "The airlock has been opened!",
    ["chron.airlock.closed"] = "The airlock has been closed!",
    -- Markers.
    ["mark.anchor_1"] = "1",
    ["mark.anchor_2"] = "2",
    ["mark.anchor_3"] = "3",
    ["mark.anchor_4"] = "4",

    -- Messages.
    ["msg.mordechai.shuriken.next"] = "Next Shuriken",
    ["msg.phase.start"] = "SUCKY SUCKY PHASE SOON",
    ["msg.orb.spawned"] = "Orb Spawned",
    ["msg.orb.kinetic_link"] = "DPS THE ORB!",
    ["msg.orb.next"] = "Next Orb",
    ["msg.mordechai.shuriken.you"] = "SHURIKEN ON YOU"
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("LinesCleave")
mod:RegisterDefaultSetting("WorldMarkerAnchor")
mod:RegisterDefaultSetting("MarkerAnchorHP")
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
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_NULLIFIED = 85614 -- Green
local DEBUFF_KINETIC_LINK = 86797 -- Purple
local DEBUFF_SHOCKING_ATTRACTION = 86861

local FIRST_SUCKY_PHASE_UPPER_HEALTH = 86.5
local FIRST_SUCKY_PHASE_LOWER_HEALTH = 85.5
local FIRST_SHURIKEN_TIMER = 11
local SHURIKEN_TIMER = 22

--TODO: I made the timers based on the only log I had
-- Need to get more logs again with casts from turret etc.
local FIRST_ORB_TIMER = 18.5
local ORB_TIMER = 26

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
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  anchors = {}
  anchorCount = 0
  mod:AddAnchorWorldMarkers()
  mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", ORB_TIMER)
end

function mod:OnBossDisable()
end

mod:RegisterUnitEvents("unit.turret",{
    [core.E.UNIT_CREATED] = function(_, _, unit)
      core:WatchUnit(unit)
    end,
  }
)

mod:RegisterUnitEvents("unit.mordechai",{
    [core.E.UNIT_CREATED] = function(_, _, unit)
      mordechai = unit
      core:AddUnit(unit)
      core:WatchUnit(unit)
      mod:AddCleaveLines()
    end,
    [core.E.HEALTH_CHANGED] = function(_, _, percent)
      if percent >= FIRST_SUCKY_PHASE_LOWER_HEALTH and percent <= FIRST_SUCKY_PHASE_UPPER_HEALTH then
        if mod:GetSetting("MessageAirlockPhaseSoon") then
          mod:AddMsg("SUCKY PHASE", "msg.phase.start", 5, mod:GetSetting("SoundAirlockPhaseSoon") == true and "Info")
        end
      end
    end,
    [core.E.CAST_START] = {
      ["cast.mordechai.shatter"] = function(_, _)
        mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", SHURIKEN_TIMER, mod:GetSetting("SoundShurikenCountdown"))
      end
    }
  }
)

mod:RegisterUnitEvents("unit.anchor",{
    [core.E.UNIT_CREATED] = function(_, id, unit)
      anchors[id] = unit
      core:AddUnit(unit)
      core:WatchUnit(unit)
      if mod:GetSetting("MarkerAnchorHP") then
        core:MarkUnit(unit, 0, 100)
      end

      anchorCount = anchorCount + 1
      if anchorCount == 4 then
        mod:RemoveAnchorWorldMarkers()
        mod:RemoveCleaveLines()
        mod:RemoveTimerBar("NEXT_ORB_TIMER")
        anchorCount = 0
      end
    end,
    [core.E.UNIT_DESTROYED] = function (_, id)
      anchors[id] = nil
    end,
    [core.E.HEALTH_CHANGED] = function (_, id, percent)
      if mod:GetSetting("MarkerAnchorHP") then
        core:MarkUnit(anchors[id], 0, percent)
      end
    end,
  }
)

mod:RegisterUnitEvents("unit.orb",{
    [core.E.UNIT_CREATED] = function(_, _, _)
      if mod:GetSetting("MessageOrbSpawn") then
        mod:AddMsg("ORB_SPAWNED", "msg.orb.spawned", 5, mod:GetSetting("SoundOrbSpawn") == true and "Info")
      end
      mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", ORB_TIMER)
    end
  }
)

mod:RegisterDatachronEvent("chron.airlock.closed", "EQUAL", function (_)
    mod:AddCleaveLines()
    mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", FIRST_SHURIKEN_TIMER, true)
    mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", FIRST_ORB_TIMER)
    mod:AddAnchorWorldMarkers()
  end
)

function mod:OnDebuffAdd(id, spellId)
  local isOnMyself = id == GameLib.GetPlayerUnit():GetId()
  if DEBUFF_KINETIC_LINK == spellId and isOnMyself then
    if mod:GetSetting("MessageOrbLink") then
      mod:AddMsg("KINETIC_LINK_MSG", "msg.orb.kinetic_link", 5, mod:GetSetting("SoundOrbLink") == true and "Burn")
    end
  end
  if DEBUFF_SHOCKING_ATTRACTION == spellId then
    core:AddPicture("SHOCKING_ATTRACTION_TARGET_"..id, id, "Crosshair", 30, 0, 0, nil, "white")
    if isOnMyself then
      if mod:GetSetting("MessageShockingAttraction") then
        mod:AddMsg("SHOCKING_ATTRACTION", "msg.mordechai.shuriken.you", 5, mod:GetSetting("SoundShurikenCountdown") == true and "RunAway")
      end
    end
  end
end

function mod:OnDebuffRemove(id, spellId)
  if DEBUFF_SHOCKING_ATTRACTION == spellId then
    core:RemovePicture("SHOCKING_ATTRACTION_TARGET_"..id)
  end
end

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
  if not mod:GetSetting("LinesCleave") then
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
