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
    ["unit.cannon_arm"] = "Cannon Arm",
    ["unit.flailing_arm"] = "Flailing Arm",
    ["unit.scanning_eye"] = "Scanning Eye",
    -- Cast names.
    ["cast.cannon_fire"] = "Cannon Fire",
    ["cast.laser"] = "Incineration Laser",
    ["cast.spew"] = "Noxious Belch",
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
    ["msg.cannon_arm.spawned"] = "CANNON",
    ["msg.cannon_arm.interrupt"] = "INTERRUPT CANNON %d",
    ["msg.spew.now"] = "Spew",
    ["msg.spew.next"] = "Next spew in",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.flailing_arm"] = "Fuchtelnder Arm",
    -- Datachron.
    ["chron.robo.laser"] = "Die Robomination versucht, ([^%s]+%s[^%s]+) zu verbrennen.",
    ["chron.robo.hides"] = "Die Robomination sinkt in den Müll hinab.",
    ["chron.robo.erupts"] = "Die Robomination stürzt sich erneut ins Gefecht!",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.flailing_arm"] = "Bras agité",
    -- Cast names.
    ["cast.laser"] = "Laser d'incinération",
    -- Datachron.
    ["chron.robo.laser"] = "Robomination essaie d'incinérer ([^%s]+%s[^%.]+)%.",
    ["chron.robo.hides"] = "Robomination s'enfonce dans les ordures.",
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Spell ids.
local DEBUFF_SNAKE = 75126
local DEBUFF_LASER = 75626

-- Phases.
local DPS_PHASE = 1
local MAZE_PHASE = 2
local MID_MAZE_PHASE = 3

-- Timers.
local FIRST_SNAKE_TIMER = 7.5
local SNAKE_TIMER = 17.5

local FIRST_INCINERATE_TIMER = 18.5
local INCINERATE_TIMER = 42.5

local FIRST_SPEW_TIMER = 15.6
local SPEW_TIMER = 31.75
local MAZE_SPEW_TIMER = 10

local ARMS_TIMER = 45

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
local GetUnitById = GameLib.GetUnitById
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
  mod:AddTimerBar("NEXT_ARMS_TIMER", "msg.arms.next", ARMS_TIMER)
  mod:AddTimerBar("NEXT_SNAKE_TIMER", "msg.snake.next", FIRST_SNAKE_TIMER)
  mod:AddTimerBar("NEXT_SPEW_TIMER", "msg.spew.next", FIRST_SPEW_TIMER)
  mod:DrawCompactorGrid()
end

function mod:OnBarUnitCreated(id, unit, name)
  mod:AddUnit(unit)
end

mod:RegisterDatachronEvent("chron.robo.snake", core.E.COMPARE_MATCH, function(self, _, snakeTargetName)
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
      core:AddPicture("SNAKE_CROSSHAIR", snakeTarget:GetId(), "Crosshair", 20)
    end

    mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
    mod:AddTimerBar("NEXT_SNAKE_TIMER", "msg.snake.next", SNAKE_TIMER)
  end
)

mod:RegisterDatachronEvent("chron.robo.hides", core.E.COMPARE_EQUAL, function()
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
)

mod:RegisterDatachronEvent("chron.robo.shows", core.E.COMPARE_EQUAL, function()
    phase = DPS_PHASE
    core:RemoveLineBetweenUnits("ROBO_MAZE_LINE")
    mod:AddTimerBar("NEXT_SNAKE_TIMER", "msg.snake.next", FIRST_SNAKE_TIMER)
    mod:AddTimerBar("NEXT_SPEW_TIMER", "msg.spew.next", MAZE_SPEW_TIMER)
    mod:AddTimerBar("NEXT_INCINERATE_TIMER", "msg.robo.laser.next", FIRST_INCINERATE_TIMER, mod:GetSetting("SoundLaser"))
    mod:AddTimerBar("NEXT_ARMS_TIMER", "msg.arms.next", ARMS_TIMER)
    mod:DrawCompactorGrid()
  end
)

mod:RegisterDatachronEvent("chron.robo.laser", core.E.COMPARE_MATCH, function(self, _, laserTargetName)
    local laserTarget = GetPlayerUnitByName(laserTargetName)
    local isOnMyself = laserTarget == playerUnit
    local laserOnX
    if isOnMyself then
      laserOnX = "msg.robo.laser.you"
    else
      laserOnX = self.L["msg.robo.laser.other"]:format(laserTarget:GetName())
    end

    if mod:GetSetting("CrosshairLaser") then
      core:AddPicture("LASER_CROSSHAIR", laserTarget:GetId(), "Crosshair", 30, 0, 0, nil, "Red")
    end

    mod:RemoveTimerBar("NEXT_INCINERATE_TIMER")
    mod:AddTimerBar("NEXT_INCINERATE_TIMER", "msg.robo.laser.next", INCINERATE_TIMER, mod:GetSetting("SoundLaser"))
    mod:AddMsg("LASER_MSG", laserOnX, 5, "Burn", "xkcdRed")
  end
)

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

mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.DEBUFF_REMOVE] = {
      [DEBUFF_SNAKE] = function()
        core:RemovePicture("SNAKE_CROSSHAIR")
      end,
      [DEBUFF_LASER] = function()
        core:RemovePicture("LASER_CROSSHAIR")
      end,
    },
  }
)
mod:RegisterUnitEvents({
    "unit.cannon_arm",
    "unit.flailing_arm",
    "unit.robo",
    "unit.scanning_eye",
    },{
    [core.E.UNIT_CREATED] = mod.OnBarUnitCreated,
  }
)

mod:RegisterUnitEvents("unit.scanning_eye",{
    [core.E.UNIT_DESTROYED] = function()
      phase = MID_MAZE_PHASE
    end,
  }
)

mod:RegisterUnitEvents({"unit.cannon_arm", "unit.flailing_arm"},{
    [core.E.UNIT_CREATED] = function()
      if phase == MID_MAZE_PHASE then
        mazeArmCount = mazeArmCount + 1
      end
    end,
    [core.E.UNIT_DESTROYED] = function()
      if phase == MID_MAZE_PHASE then
        mazeArmCount = mazeArmCount - 1
        if mazeArmCount == 0 then
          mod:RedrawCannonArmLines()
          if mod:GetSetting("LineRoboMaze") then
            core:AddLineBetweenUnits("ROBO_MAZE_LINE", playerUnit:GetId(), roboUnit:GetId(), 8)
          end
        end
      end
    end,
  }
)

function mod:RedrawCannonArmLines()
  if mod:GetSetting("LineCannonArm") then
    for id, _ in pairs(cannonArms) do
      core:AddLineBetweenUnits(string.format("CANNON_ARM_LINE %d", id), playerUnit:GetId(), id, 5)
    end
  end
end

function mod:RemoveCannonArmLines()
  if mod:GetSetting("LineCannonArm") then
    for id, _ in pairs(cannonArms) do
      core:RemoveLineBetweenUnits(string.format("CANNON_ARM_LINE %d", id))
    end
  end
end

function mod:MarkCannonArm(cannonArm)
  if mod:GetSetting("MarkerCannonInterrupt") then
    core:MarkUnit(cannonArm.unit, core.E.LOCATION_STATIC_FLOOR, cannonArm.interrupt)
  end
end

mod:RegisterUnitEvents("unit.cannon_arm",{
    [core.E.UNIT_CREATED] = function (_, id, unit)
      cannonArms[id] = {unit = unit, interrupt = 1}
      mod:MarkCannonArm(cannonArms[id])
      core:WatchUnit(unit, core.E.TRACK_CASTS)
      if mod:GetSetting("LineCannonArm") then
        core:AddLineBetweenUnits(string.format("CANNON_ARM_LINE %d", id), playerUnit:GetId(), id, 5)
      end
      if phase == DPS_PHASE then
        mod:AddTimerBar("NEXT_ARMS_TIMER", "msg.arms.next", ARMS_TIMER)
      end
      mod:AddMsg("ARMS_MSG_SPAWN", "msg.cannon_arm.spawned", 5, "Info", "xkcdWhite")
    end,
    ["cast.cannon_fire"] = {
      [core.E.CAST_START] = function(self, id)
        if mod:GetDistanceBetweenUnits(playerUnit, GetUnitById(id)) < 45 then
          local msg = self.L["msg.cannon_arm.interrupt"]:format(cannonArms[id].interrupt)
          mod:AddMsg("ARMS_MSG_CAST_"..id, msg, 2, "Inferno", "xkcdOrange")
        end
        cannonArms[id].interrupt = cannonArms[id].interrupt + 1
      end,
      [core.E.CAST_END] = function(self, id)
        mod:MarkCannonArm(cannonArms[id])
      end
    },
    [core.E.UNIT_DESTROYED] = function(_, id)
      cannonArms[id] = nil
      core:RemoveLineBetweenUnits(string.format("CANNON_ARM_LINE %d", id))
    end,
  }
)

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
  mod:AddTimerBar("NEXT_SPEW_TIMER", "msg.spew.next", SPEW_TIMER)
  mod:AddMsg("SPEW_MSG", "msg.spew.now", 4, "Beware", "xkcdAcidGreen")
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.robo",{
    [core.E.UNIT_CREATED] = mod.OnRobominationCreated,
    [core.E.HEALTH_CHANGED] = mod.OnRobominationHealthChanged,
    [core.E.CAST_START] = {
      ["cast.spew"] = mod.OnRobominationSpewStart,
    },
  }
)
