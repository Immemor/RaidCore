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
  [1] = { x = 93.849998474121, y = 353.87435913086, z = 209.71000671387 },
  [2] = { x = 93.849998474121, y = 353.87435913086, z = 179.71000671387 },
  [3] = { x = 123.849998474121, y = 353.87435913086, z = 209.71000671387 },
  [4] = { x = 123.849998474121, y = 353.87435913086, z = 179.71000671387 },
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local mordechai
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  mod:SetWorldMarker("ANCHOR_1", "mark.anchor_1", ANCHOR_POSITIONS[1])
  mod:SetWorldMarker("ANCHOR_2", "mark.anchor_2", ANCHOR_POSITIONS[2])
  mod:SetWorldMarker("ANCHOR_3", "mark.anchor_3", ANCHOR_POSITIONS[3])
  mod:SetWorldMarker("ANCHOR_4", "mark.anchor_4", ANCHOR_POSITIONS[4])

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
        mod:AddMsg("SUCKY PHASE", "msg.phase.start", 5)
      end
    end,
    [core.E.CAST_START] = {
      ["cast.mordechai.shatter"] = function(_, _)
        mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", SHURIKEN_TIMER, true)
      end
    }
  }
)

mod:RegisterUnitEvents("unit.anchor",{
    [core.E.UNIT_CREATED] = function(_, _, _)
      mod:RemoveTimerBar("NEXT_ORB_TIMER")
      mod:RemoveCleaveLines()
    end,
  }
)

mod:RegisterUnitEvents("unit.orb",{
    [core.E.UNIT_CREATED] = function(_, _, _)
      mod:AddMsg("ORB_SPAWNED", "msg.orb.spawned", 5)
      mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", ORB_TIMER)
    end
  }
)

mod:RegisterDatachronEvent("chron.airlock.closed", "EQUAL", function (_)
    mod:AddCleaveLines()
    mod:AddTimerBar("NEXT_SHURIKEN_TIMER", "msg.mordechai.shuriken.next", FIRST_SHURIKEN_TIMER, true)
    mod:AddTimerBar("NEXT_ORB_TIMER", "msg.orb.next", FIRST_ORB_TIMER)
  end
)

function mod:OnDebuffAdd(id, spellId)
  local isOnMyself = id == GameLib.GetPlayerUnit():GetId()
  if DEBUFF_KINETIC_LINK == spellId and isOnMyself then
    mod:AddMsg("KINETIC_LINK_MSG", "msg.orb.kinetic_link", 5, "Burn")
  end
  if DEBUFF_SHOCKING_ATTRACTION == spellId then
    core:AddPicture("SHOCKING_ATTRACTION_TARGET_"..id, id, "Crosshair", 30, 0, 0, nil, "white")
    if isOnMyself then
      mod:AddMsg("SHOCKING_ATTRACTION", "msg.mordechai.shuriken.you", 5, "RunAway")
    end
  end
end

function mod:OnDebuffRemove(id, spellId)
  if DEBUFF_SHOCKING_ATTRACTION == spellId then
    core:RemovePicture("SHOCKING_ATTRACTION_TARGET_"..id)
  end
end

function mod:AddCleaveLines()
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
  core:RemoveSimpleLine("CLEAVE_FRONT_RIGHT")
  core:RemoveSimpleLine("CLEAVE_BACK_RIGHT")
  core:RemoveSimpleLine("CLEAVE_FRONT_LEFT")
  core:RemoveSimpleLine("CLEAVE_BACK_LEFT")
  core:RemoveSimpleLine("CLEAVE_FRONT_RIGHT2")
  core:RemoveSimpleLine("CLEAVE_BACK_RIGHT2")
  core:RemoveSimpleLine("CLEAVE_FRONT_LEFT2")
  core:RemoveSimpleLine("CLEAVE_BACK_LEFT2")
end
