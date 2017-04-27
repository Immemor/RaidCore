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
local mod = core:NewEncounter("Robomination", 104, {548, 0}, {551, 548})
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "unit.robo" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.robo"] = "Robomination",
    ["unit.trash_compactor"] = "Trash Compactor",
    ["unit.arm.cannon"] = "Cannon Arm",
    ["unit.arm.flailing"] = "Flailing Arm",
    ["unit.scanning_eye"] = "Scanning Eye",
    -- Cast names.
    ["cast.arm.cannon.fire"] = "Cannon Fire",
    ["cast.robo.laser"] = "Incineration Laser",
    ["cast.robo.spew"] = "Noxious Belch",
    -- Datachron.
    ["chron.robo.snake"] = "Robomination tries to crush ([^%s]+%s[^!]+)!$",
    ["chron.robo.laser"] = "Robomination tries to incinerate ([^%s]+%s.+)$",
    ["chron.robo.hides"] = "The Robomination sinks down into the trash.",
    ["chron.robo.shows"] = "The Robomination erupts back into the fight!",
    -- Messages.
    ["msg.snake.other"] = "SNAKE ON %s",
    ["msg.snake.you"] = "SNAKE ON YOU",
    ["msg.snake.near"] = "SNAKE NEAR ON %s",
    ["msg.snake.next"] = "Next snake in",
    ["msg.robo.laser.other"] = "LASER ON %s",
    ["msg.robo.laser.you"] = "LASER ON YOU",
    ["msg.robo.laser.next"] = "Next incinerate in",
    ["msg.maze.coming"] = "MAZE SOON",
    ["msg.maze.now"] = "CENTER",
    ["msg.arms.next"] = "Arms spawning in",
    ["msg.arm.cannon.spawned"] = "CANNON",
    ["msg.arm.cannon.interrupt"] = "INTERRUPT CANNON %d",
    ["msg.spew.now"] = "Spew",
    ["msg.spew.next"] = "Next spew in",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.arm.flailing"] = "Fuchtelnder Arm",
    -- Datachron.
    ["chron.robo.laser"] = "Die Robomination versucht, ([^%s]+%s[^%s]+) zu verbrennen.",
    ["chron.robo.hides"] = "Die Robomination sinkt in den Müll hinab.",
    ["chron.robo.erupts"] = "Die Robomination stürzt sich erneut ins Gefecht!",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.arm.flailing"] = "Bras agité",
    -- Cast names.
    ["cast.robo.laser"] = "Laser d'incinération",
    -- Datachron.
    ["chron.robo.laser"] = "Robomination essaie d'incinérer ([^%s]+%s[^%.]+)%.",
    ["chron.robo.hides"] = "Robomination s'enfonce dans les ordures.",
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Spell ids.
local DEBUFFS = {
  SNAKE = 75126,
  LASER = 75626,
}

-- Phases.
local DPS_PHASE = 1
local MAZE_PHASE = 2
local MID_MAZE_PHASE = 3

-- Timers.
local TIMERS = {
  SNAKE = {
    FIRST = 7.5,
    NORMAL = 17.5,
  },
  LASER = {
    FIRST = 18.5,
    NORMAL = 42.5,
  },
  SPEW = {
    FIRST = 15.6,
    NORMAL = 31.75,
    AFTER_MID = 10,
  },
  ARMS = {
    NORMAL = 45,
  }
}

-- Compactors.
local COMPACTORS_EDGE = {
  { y = -203.4208984375, x = 0.71257400512695, z = -1349.8697509766 },
  { y = -203.4208984375, x = 10.955376625061, z = -1339.6927490234 },
  { y = -203.4208984375, x = -19.743923187256, z = -1339.6927490234 },
  { y = -203.4208984375, x = -9.5010261535645, z = -1349.8697509766 },
  { y = -203.4208984375, x = 0.71258544921875, z = -1319.4196777344 },
  { y = -203.4208984375, x = 10.955380439758, z = -1329.5698242188 },
  { y = -203.4208984375, x = -19.743919372559, z = -1329.5698242188 },
  { y = -203.4208984375, x = -9.5010147094727, z = -1319.4196777344 },
}
local COMPACTORS_CORNER = {
  { y = -203.4208984375, x = 10.955372810364, z = -1349.8697509766 },
  { y = -203.4208984375, x = -19.743927001953, z = -1349.8697509766 },
  { y = -203.4208984375, x = -19.743915557861, z = -1319.4196777344 },
  { y = -203.4208984375, x = 10.95538520813, z = -1319.4196777344 },
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local phase
local mazeArmCount
local roboUnit
local cannonArms
local playerUnit
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("CrosshairSnake")
mod:RegisterDefaultSetting("CompactorGridCorner")
mod:RegisterDefaultSetting("CompactorGridEdge", false)
mod:RegisterDefaultSetting("LineCannonArm")
mod:RegisterDefaultSetting("CrosshairLaser")
mod:RegisterDefaultSetting("LineRoboMaze")
mod:RegisterDefaultSetting("MarkerCannonInterrupt")
-- Sounds.
mod:RegisterDefaultSetting("SoundSnake")
mod:RegisterDefaultSetting("SoundSnakeNear")
mod:RegisterDefaultSetting("SoundSnakeNearAlt", false)
mod:RegisterDefaultSetting("SoundPhaseChange")
mod:RegisterDefaultSetting("SoundPhaseChangeClose")
mod:RegisterDefaultSetting("SoundArmSpawn")
mod:RegisterDefaultSetting("SoundCannonInterrupt")
mod:RegisterDefaultSetting("SoundLaser")
mod:RegisterDefaultSetting("SoundSpew")
-- Messsages.
mod:RegisterDefaultSetting("MessageSnake")
mod:RegisterDefaultSetting("MessageSnakeNear")
mod:RegisterDefaultSetting("MessageSnakeOther")
mod:RegisterDefaultSetting("MessagePhaseChange")
mod:RegisterDefaultSetting("MessagePhaseChangeClose")
mod:RegisterDefaultSetting("MessageArmSpawn")
mod:RegisterDefaultSetting("MessageCannonInterrupt")
mod:RegisterDefaultSetting("MessageLaser")
mod:RegisterDefaultSetting("MessageSpew")
-- Binds.
mod:RegisterMessageSetting("SNAKE_MSG", core.E.COMPARE_EQUAL, "MessageSnake", "SoundSnake")
mod:RegisterMessageSetting("SNAKE_MSG_NEAR", core.E.COMPARE_EQUAL, "MessageSnakeNear", "SoundSnakeNear")
mod:RegisterMessageSetting("SNAKE_MSG_OTHER", core.E.COMPARE_EQUAL, "MessageSnakeOther")
mod:RegisterMessageSetting("ROBO_MAZE_CLOSE", core.E.COMPARE_EQUAL, "MessagePhaseChangeClose", "SoundPhaseChangeClose")
mod:RegisterMessageSetting("ROBO_MAZE_NOW", core.E.COMPARE_EQUAL, "MessagePhaseChange", "SoundPhaseChange")
mod:RegisterMessageSetting("ARMS_MSG_SPAWN", core.E.COMPARE_EQUAL, "MessageArmSpawn", "SoundArmSpawn")
mod:RegisterMessageSetting("ARMS_MSG_CAST_%d+", core.E.COMPARE_MATCH, "MessageCannonInterrupt", "SoundCannonInterrupt")
mod:RegisterMessageSetting("LASER_MSG", core.E.COMPARE_EQUAL, "MessageLaser", "SoundLaser")
mod:RegisterMessageSetting("SPEW_MSG", core.E.COMPARE_EQUAL, "MessageSpew", "SoundSpew")
-- Timer default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_SNAKE_TIMER"] = { sColor = "xkcdBrown" },
    ["NEXT_SPEW_TIMER"] = { sColor = "green" },
    ["NEXT_INCINERATE_TIMER"] = { sColor = "red" },
  }
)
mod:RegisterUnitBarConfig("unit.robo", {
    nPriority = 0,
    tMidphases = {
      {percent = 75},
      {percent = 50},
    }
  }
)
mod:RegisterUnitBarConfig("unit.scanning_eye", {
    tMidphases = {
      {percent = 75},
      {percent = 50},
      {percent = 25},
    }
  }
)
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  phase = DPS_PHASE
  mazeArmCount = 0
  roboUnit = nil
  cannonArms = {}
  playerUnit = GameLib.GetPlayerUnit()
  mod:AddTimerBar("NEXT_ARMS_TIMER", "msg.arms.next", TIMERS.ARMS.NORMAL)
  mod:AddTimerBar("NEXT_SNAKE_TIMER", "msg.snake.next", TIMERS.SNAKE.FIRST)
  mod:AddTimerBar("NEXT_SPEW_TIMER", "msg.spew.next", TIMERS.SPEW.FIRST)
  mod:DrawCompactorGrid()
end

function mod:OnBarUnitCreated(id, unit, name)
  mod:AddUnit(unit)
end

function mod:OnSnakeTarget(message, snakeTargetName)
  local snakeTarget = GetPlayerUnitByName(snakeTargetName)
  local isOnMyself = snakeTarget == playerUnit
  local isSnakeNearYou = not isOnMyself and mod:GetDistanceBetweenUnits(playerUnit, snakeTarget) < 10
  if isOnMyself then
    mod:AddMsg("SNAKE_MSG", "msg.snake.you", 5, "RunAway", "xkcdBlue")
  elseif isSnakeNearYou then
    local sound = "RunAway"
    local msg = self.L["msg.snake.near"]:format(snakeTarget:GetName())
    if mod:GetSetting("SoundSnakeNearAlt") then
      sound = "Destruction"
    end
    mod:AddMsg("SNAKE_MSG_NEAR", msg, 5, sound, "xkcdBlue")
  else
    local msg = self.L["msg.snake.other"]:format(snakeTarget:GetName())
    mod:AddMsg("SNAKE_MSG_OTHER", msg, 5, nil, "xkcdBlue")
  end

  if mod:GetSetting("CrosshairSnake") then
    core:AddPicture("SNAKE_CROSSHAIR", snakeTarget, "Crosshair", 20)
  end

  mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
  mod:AddTimerBar("NEXT_SNAKE_TIMER", "msg.snake.next", TIMERS.SNAKE.NORMAL)
end

function mod:OnRobominationHides()
  phase = MAZE_PHASE
  mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
  mod:RemoveTimerBar("NEXT_INCINERATE_TIMER")
  mod:RemoveTimerBar("NEXT_SPEW_TIMER")
  mod:RemoveTimerBar("NEXT_ARMS_TIMER")
  core:RemovePicture("SNAKE_CROSSHAIR")
  core:RemovePicture("LASER_CROSSHAIR")

  core:RemoveMsg("ROBO_MAZE_CLOSE")
  mod:AddMsg("ROBO_MAZE_NOW", "msg.maze.now", 5, "Info", "xkcdWhite")
  mod:RemoveCompactorGrid()
  mod:RemoveCannonArmLines()
end

function mod:OnRobominationShows()
  phase = DPS_PHASE
  core:RemoveLineBetweenUnits("ROBO_MAZE_LINE")
  mod:AddTimerBar("NEXT_SNAKE_TIMER", "msg.snake.next", TIMERS.SNAKE.FIRST)
  mod:AddTimerBar("NEXT_SPEW_TIMER", "msg.spew.next", TIMERS.SPEW.AFTER_MID)
  mod:AddTimerBar("NEXT_INCINERATE_TIMER", "msg.robo.laser.next", TIMERS.LASER.FIRST, mod:GetSetting("SoundLaser"))
  mod:AddTimerBar("NEXT_ARMS_TIMER", "msg.arms.next", TIMERS.ARMS.NORMAL)
  mod:DrawCompactorGrid()
end

function mod:OnLaserTarget(message, laserTargetName)
  local laserTarget = GetPlayerUnitByName(laserTargetName)
  local isOnMyself = laserTarget == playerUnit
  local laserOnX
  if isOnMyself then
    laserOnX = "msg.robo.laser.you"
  else
    laserOnX = self.L["msg.robo.laser.other"]:format(laserTarget:GetName())
  end

  if mod:GetSetting("CrosshairLaser") then
    core:AddPicture("LASER_CROSSHAIR", laserTarget, "Crosshair", 30, 0, 0, nil, "Red")
  end

  mod:RemoveTimerBar("NEXT_INCINERATE_TIMER")
  mod:AddTimerBar("NEXT_INCINERATE_TIMER", "msg.robo.laser.next", TIMERS.LASER.NORMAL, mod:GetSetting("SoundLaser"))
  mod:AddMsg("LASER_MSG", laserOnX, 5, "Burn", "xkcdRed")
end

function mod:DrawCompactorGrid()
  mod:HelperCompactorGrid(COMPACTORS_EDGE, false, true)
  mod:HelperCompactorGrid(COMPACTORS_CORNER, true, true)
end

function mod:RemoveCompactorGrid()
  mod:HelperCompactorGrid(COMPACTORS_EDGE, false, false)
  mod:HelperCompactorGrid(COMPACTORS_CORNER, true, false)
end

function mod:HelperCompactorGrid(compactors, isCorner, isAdding)
  local color = (isCorner == true and "Green") or "Red"
  local idString = (isCorner == true and "COMPACTOR_CORNER_%d") or "COMPACTOR_EDGE_%d"
  local setting = (isCorner == true and "CompactorGridCorner") or "CompactorGridEdge"
  if not mod:GetSetting(setting) then
    return
  end
  for i, position in pairs(compactors) do
    local id = string.format(idString, i)
    if isAdding then
      core:AddPolygon(id, position, 7, 45, 4, color, 4)
    else
      core:RemovePolygon(id)
    end
  end
end

function mod:OnSnakeDebuffRemove()
  core:RemovePicture("SNAKE_CROSSHAIR")
end

function mod:OnLaserDebuffRemove()
  core:RemovePicture("LASER_CROSSHAIR")
end

function mod:OnScanningEyeCreated(id, unit, name)
  phase = MID_MAZE_PHASE
end

function mod:OnArmCreated(id, unit, name)
  if phase == MID_MAZE_PHASE then
    mazeArmCount = mazeArmCount + 1
  end
end

function mod:OnArmDestroyed(id, unit, name)
  if phase == MID_MAZE_PHASE then
    mazeArmCount = mazeArmCount - 1
    if mazeArmCount == 0 then
      mod:RedrawCannonArmLines()
      if mod:GetSetting("LineRoboMaze") then
        core:AddLineBetweenUnits("ROBO_MAZE_LINE", playerUnit, roboUnit, 8)
      end
    end
  end
end

function mod:RedrawCannonArmLines()
  if mod:GetSetting("LineCannonArm") then
    for id, cannonArm in pairs(cannonArms) do
      core:AddLineBetweenUnits("CANNON_ARM_LINE_"..id, playerUnit, cannonArm.unit, 5)
    end
  end
end

function mod:RemoveCannonArmLines()
  if mod:GetSetting("LineCannonArm") then
    for id, _ in pairs(cannonArms) do
      core:RemoveLineBetweenUnits("CANNON_ARM_LINE_"..id)
    end
  end
end

function mod:MarkCannonArm(cannonArm)
  if mod:GetSetting("MarkerCannonInterrupt") then
    core:MarkUnit(cannonArm.unit, core.E.LOCATION_STATIC_FLOOR, cannonArm.interrupt)
  end
end

function mod:OnCannonArmCreated(id, unit, name)
  cannonArms[id] = {unit = unit, interrupt = 1}
  mod:MarkCannonArm(cannonArms[id])
  core:WatchUnit(unit, core.E.TRACK_CASTS)
  if mod:GetSetting("LineCannonArm") then
    core:AddLineBetweenUnits("CANNON_ARM_LINE_"..id, playerUnit, unit, 5)
  end
  if phase == DPS_PHASE then
    mod:AddTimerBar("NEXT_ARMS_TIMER", "msg.arms.next", TIMERS.ARMS.NORMAL)
  end
  mod:AddMsg("ARMS_MSG_SPAWN", "msg.arm.cannon.spawned", 5, "Info", "xkcdWhite")
end

function mod:OnCannonArmDestroyed(id, unit, name)
  cannonArms[id] = nil
end

function mod:OnCannonFireStart(id)
  if mod:GetDistanceBetweenUnits(playerUnit, cannonArms[id].unit) < 45 then
    local msg = self.L["msg.arm.cannon.interrupt"]:format(cannonArms[id].interrupt)
    mod:AddMsg("ARMS_MSG_CAST_"..id, msg, 2, "Inferno", "xkcdOrange")
  end
  cannonArms[id].interrupt = cannonArms[id].interrupt + 1
end

function mod:OnCannonFireEnd(id)
  mod:MarkCannonArm(cannonArms[id])
end

function mod:OnRobominationCreated(id, unit, name)
  core:WatchUnit(unit, core.E.TRACK_CASTS + core.E.TRACK_HEALTH)
  roboUnit = unit
end

function mod:OnRobominationHealthChanged(id, percent, name)
  if mod:IsMidphaseClose(name, percent) then
    mod:AddMsg("ROBO_MAZE_CLOSE", "msg.maze.coming", 5, "Info", "xkcdWhite")
  end
end

function mod:OnRobominationSpewStart()
  mod:RemoveTimerBar("NEXT_SPEW_TIMER")
  mod:AddTimerBar("NEXT_SPEW_TIMER", "msg.spew.next", TIMERS.SPEW.NORMAL)
  mod:AddMsg("SPEW_MSG", "msg.spew.now", 4, "Beware", "xkcdAcidGreen")
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterDatachronEvent("chron.robo.hides", core.E.COMPARE_EQUAL, mod.OnRobominationHides)
mod:RegisterDatachronEvent("chron.robo.shows", core.E.COMPARE_EQUAL, mod.OnRobominationShows)
mod:RegisterDatachronEvent("chron.robo.snake", core.E.COMPARE_MATCH, mod.OnSnakeTarget)
mod:RegisterDatachronEvent("chron.robo.laser", core.E.COMPARE_MATCH, mod.OnLaserTarget)
mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.DEBUFF_REMOVE] = {
      [DEBUFFS.SNAKE] = mod.OnSnakeDebuffRemove,
      [DEBUFFS.LASER] = mod.OnLaserDebuffRemove,
    },
  }
)
mod:RegisterUnitEvent("unit.scanning_eye", core.E.UNIT_DESTROYED, mod.OnScanningEyeCreated)
mod:RegisterUnitEvents({"unit.arm.cannon", "unit.arm.flailing"},{
    [core.E.UNIT_CREATED] = mod.OnArmCreated,
    [core.E.UNIT_DESTROYED] = mod.OnArmDestroyed,
  }
)
mod:RegisterUnitEvents({
    "unit.arm.cannon",
    "unit.arm.flailing",
    "unit.robo",
    "unit.scanning_eye",
    },{
    [core.E.UNIT_CREATED] = mod.OnBarUnitCreated,
  }
)
mod:RegisterUnitEvents("unit.arm.cannon",{
    [core.E.UNIT_CREATED] = mod.OnCannonArmCreated,
    [core.E.UNIT_DESTROYED] = mod.OnCannonArmDestroyed,
    ["cast.arm.cannon.fire"] = {
      [core.E.CAST_START] = mod.OnCannonFireStart,
      [core.E.CAST_END] = mod.OnCannonFireEnd,
    },
  }
)
mod:RegisterUnitEvents("unit.robo",{
    [core.E.UNIT_CREATED] = mod.OnRobominationCreated,
    [core.E.HEALTH_CHANGED] = mod.OnRobominationHealthChanged,
    [core.E.CAST_START] = {
      ["cast.robo.spew"] = mod.OnRobominationSpewStart,
    },
  }
)
