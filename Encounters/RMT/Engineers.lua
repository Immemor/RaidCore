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
local mod = core:NewEncounter("Engineers", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", {
    "unit.warrior", "unit.engineer",
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
  })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.fusion_core"] = "Fusion Core",
    ["unit.cooling_turbine"] = "Cooling Turbine",
    ["unit.spark_plug"] = "Spark Plug",
    ["unit.lubricant_nozzle"] = "Lubricant Nozzle",
    ["unit.engineer"] = "Head Engineer Orvulgh", -- Engineer
    ["unit.warrior"] = "Chief Engineer Wilbargh", -- Warrior
    ["unit.fire_orb"] = "Discharged Plasma", -- Fire Orb
    -- Cast names.
    ["cast.warrior.liquidate"] = "Liquidate",
    ["cast.engineer.electroshock"] = "Electroshock",
    ["cast.rocket_jump"] = "Rocket Jump",
    -- Messages.
    ["msg.warrior.liquidate.next"] = "Next Liquidate in",
    ["msg.warrior.liquidate.stack"] = "Stack",
    ["msg.engineer.electroshock.next"] = "Next Electroshock in",
    ["msg.engineer.electroshock.swap.other"] = "%s SWAP TO WARRIOR",
    ["msg.engineer.electroshock.swap.you"] = "YOU SWAP TO WARRIOR",
    ["msg.engineer.electroshock.swap.return"] = "YOU SWAP BACK TO ENGINEER",
    ["msg.fire_orb.next"] = "Next Fire Orb in",
    ["msg.fire_orb.you"] = "FIRE ORB ON YOU",
    ["msg.fire_orb.spawned"] = "Fire Orb spawned",
    ["msg.fire_orb.pop.timer"] = "Fire Orb is safe to pop in",
    ["msg.fire_orb.pop.msg"] = "Pop the Fire Orb!",
    ["msg.core.health.high.warning"] = "%s pillar at HIGH HEALTH!",
    ["msg.core.health.low.warning"] = "%s pillar at LOW HEALTH!",
    ["msg.rocket_jump.moved"] = "%s HAS MOVED"
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_ATOMIC_ATTRACTION = 84053
local DEBUFF_ION_CLASH = 84051
local BUFF_INSULATION = 83987

-- Timers
local FIRST_ELECTROSHOCK_TIMER = 11
local ELECTROSHOCK_TIMER = 18
local JUMP_ELECTROSHOCK_TIMER = 12
local FIRST_FIRE_ORB_TIMER = 21
local NEXT_FIRE_ORB_TIMER = 24
local FIRE_ORB_SAFE_TIMER = 18

local FIRST_LIQUIDATE_TIMER = 12
local LIQUIDATE_TIMER = 22

local CORE_HEALTH_LOW_PERCENTAGE = 15
local CORE_HEALTH_LOW_WARN_PERCENTAGE = 20
local CORE_HEALTH_LOW_WARN_PERCENTAGE_REENABLE = 23
local CORE_HEALTH_HIGH_WARN_PERCENTAGE = 85
local CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE = 82

local FUSION_CORE = 1
local COOLING_TURBINE = 2
local SPARK_PLUG = 3
local LUBRICANT_NOZZLE = 4
local CORE_NAMES = {
  ["unit.fusion_core"] = FUSION_CORE,
  ["unit.cooling_turbine"] = COOLING_TURBINE,
  ["unit.spark_plug"] = SPARK_PLUG,
  ["unit.lubricant_nozzle"] = LUBRICANT_NOZZLE
}
local CORE_BAR_COLORS = {
  [FUSION_CORE] = "xkcdDarkRed",
  [COOLING_TURBINE] = "xkcdSkyBlue",
  [SPARK_PLUG] = "xkcdLightYellow",
  [LUBRICANT_NOZZLE] = "xkcdLightPurple",
}

local WARRIOR = 1
local ENGINEER = 2
local ENGINEER_NICK_NAMES = {
  [WARRIOR] = "unit.warrior",
  [ENGINEER] = "unit.engineer"
}
local ENGINEER_NAMES = {
  ["unit.warrior"] = WARRIOR,
  ["unit.engineer"] = ENGINEER,
}
local ENGINEER_START_LOCATION = {
  [WARRIOR] = SPARK_PLUG,
  [ENGINEER] = COOLING_TURBINE,
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local next = next
local function TableLength(table)
  local count = 0
  for _, _ in next, table do
    count = count + 1
  end
  return count
end
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
--Do not reset coreUnits since they don't get destroyed after each pull
local coreUnits = {}
local engineerUnits
local player
local orbUnits

local fireOrbTargetTestTimer = ApolloTimer.Create(1, false, "RegisterOrbTarget", mod)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("BarsCoreHealth", false)
mod:RegisterDefaultSetting("MarkerCoreHealth")
mod:RegisterDefaultSetting("LineElectroshock")
mod:RegisterDefaultSetting("SoundLiquidate")
mod:RegisterDefaultSetting("SoundElectroshock")
mod:RegisterDefaultSetting("SoundElectroshockSwap")
mod:RegisterDefaultSetting("MessageElectroshockSwap")
mod:RegisterDefaultSetting("SoundElectroshockSwapYou")
mod:RegisterDefaultSetting("SoundFireOrb")
mod:RegisterDefaultSetting("SoundFireOrbAlt")
mod:RegisterDefaultSetting("SoundFireOrbPop")
mod:RegisterDefaultSetting("SoundCoreHealthWarning")
mod:RegisterDefaultSetting("MessageBossMove", false)
mod:RegisterDefaultSetting("MessageElectroshockSwapReturn")
mod:RegisterDefaultSetting("SoundElectroshockSwapReturn")
mod:RegisterDefaultSetting("VisualIonClashCircle")
----------------------------------------------------------------------------------------------------
-- Raw event handlers.
----------------------------------------------------------------------------------------------------
Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyedRaw", mod)
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  player = {}
  player.unit = GameLib.GetPlayerUnit()
  player.location = 0
  engineerUnits = {}
  orbUnits = {}
  --locales
  for name, id in pairs(CORE_NAMES) do
    CORE_NAMES[self.L[name]] = id
  end
  for name, id in pairs(ENGINEER_NAMES) do
    ENGINEER_NAMES[self.L[name]] = id
  end

  for _, coreUnit in pairs(coreUnits) do
    coreUnit.healthWarning = false
    coreUnit.enabled = false
  end

  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["msg.engineer.electroshock.next"], FIRST_ELECTROSHOCK_TIMER)
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", self.L["msg.warrior.liquidate.next"], FIRST_LIQUIDATE_TIMER)
end

function mod:OnBossDisable()
  mod:RemoveUnits()
end

function mod:AddUnits()
  mod:RemoveUnits()
  for _, engineer in pairs(engineerUnits) do
    core:WatchUnit(engineer.unit)
    core:AddUnit(engineer.unit)
  end
  if mod:GetSetting("BarsCoreHealth") then
    core:AddUnitSpacer("CORE_SPACER")
  end
  for coreId, coreUnit in pairs(coreUnits) do
    core:WatchUnit(coreUnit.unit)

    mod:UpdateCoreHealthMark(coreUnit, 30)
    if mod:GetSetting("BarsCoreHealth") then
      core:AddUnit(coreUnit.unit, CORE_BAR_COLORS[coreId])
    end
  end
end

function mod:RemoveUnits()
  for _, engineer in pairs(engineerUnits) do
    core:RemoveUnit(engineer.unit)
  end
  if mod:GetSetting("BarsCoreHealth") then
    core:RemoveUnit("CORE_SPACER")
    for _, coreUnit in pairs(coreUnits) do
      core:RemoveUnit(coreUnit.unit)
    end
  end
end

function mod:GetUnitPlatform(unit)
  local shortestDistance = 100000
  local currentDistance
  local location = 0
  for coreId, coreUnit in next, coreUnits do
    currentDistance = mod:GetDistanceBetweenUnits(unit, coreUnit.unit)
    if shortestDistance > currentDistance then
      shortestDistance = currentDistance
      location = coreId
    end
  end
  return location
end

function mod:OnEngiChangeLocation(engineerId, _, newLocation)
  if mod:GetSetting("MessageBossMove") and ENGINEER_NICK_NAMES[engineerId] ~= nil then
    local engineerName = ENGINEER_NICK_NAMES[engineerId]
    mod:AddMsg("BOSS_MOVED_PLATFORM", self.L["msg.rocket_jump.moved"]:format(self.L[engineerName]), 5, "Alarm")
  end
  if newLocation == FUSION_CORE then
    mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
    mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", self.L["msg.fire_orb.next"], FIRST_FIRE_ORB_TIMER)
  end
end

function mod:UpdateCoreHealthMark(coreUnit, percent)
  if mod:GetSetting("MarkerCoreHealth") then
    return
  end

  local color = "White"
  if percent <= CORE_HEALTH_LOW_PERCENTAGE or percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE then
    color = "Red"
  elseif percent <= CORE_HEALTH_LOW_WARN_PERCENTAGE or percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE then
    color = "Yellow"
  end
  if not coreUnit.enabled then
    color = "DarkGray"
  end

  core:MarkUnit(coreUnit.unit, 0, percent, color)
end

function mod:OnBuffAdd(id, spellId)
  if spellId == BUFF_INSULATION then
    local coreUnit = coreUnits[CORE_NAMES[GetUnitById(id):GetName()]]
    coreUnit.enabled = false
    mod:UpdateCoreHealthMark(coreUnit)
  end
end

function mod:OnBuffRemove(id, spellId)
  if spellId == BUFF_INSULATION then
    local coreUnit = coreUnits[CORE_NAMES[GetUnitById(id):GetName()]]
    coreUnit.enabled = true
    mod:UpdateCoreHealthMark(coreUnit)

    for engineerId, engineer in pairs(engineerUnits) do
      local oldLocation = engineerUnits[engineerId].location
      local newLocation = mod:GetUnitPlatform(engineer.unit)
      if newLocation ~= oldLocation then
        engineerUnits[engineerId].location = newLocation
        mod:OnEngiChangeLocation(engineerId, oldLocation, newLocation)
      end
    end
  end
end

function mod:OnDebuffAdd(id, spellId)
  if DEBUFF_ELECTROSHOCK_VULNERABILITY == spellId then
    local target = GetUnitById(id)
    local targetName = target:GetName()
    local isOnMyself = targetName == player.unit:GetName()
    local electroshockOnX
    local messageId = string.format("ELECTROSHOCK_MSG_%s", targetName)
    local sound
    if isOnMyself then
      electroshockOnX = self.L["msg.engineer.electroshock.swap.you"]
      sound = mod:GetSetting("SoundElectroshockSwapYou") == true and "Burn"
    else
      electroshockOnX = self.L["msg.engineer.electroshock.swap.other"]:format(targetName)
      sound = mod:GetSetting("SoundElectroshockSwap") == true and "Info"
    end
    if isOnMyself or mod:GetSetting("MessageElectroshockSwap") then
      mod:AddMsg(messageId, electroshockOnX, 5, sound, "Red")
    end
  elseif DEBUFF_ATOMIC_ATTRACTION == spellId then
    local target = GetUnitById(id)
    local isOnMyself = target == player.unit
    if isOnMyself then
      mod:AddMsg("DISCHARGED_PLASMA_MSG", self.L["msg.fire_orb.you"], 5, mod:GetSetting("SoundFireOrb") == true and "RunAway")
    elseif mod:IsPlayerOnPlatform(FUSION_CORE) then
      mod:AddMsg("DISCHARGED_PLASMA_MSG", self.L["msg.fire_orb.spawned"], 2, mod:GetSetting("SoundFireOrbAlt") == true and "Info")
    end
  elseif DEBUFF_ION_CLASH == spellId and mod:GetSetting("VisualIonClashCircle") then
    core:AddPolygon("ION_CLASH", id, 9, 0, 10, "xkcdBlue", 64)
  end
end

function mod:OnDebuffRemove(id, spellId)
  if DEBUFF_ELECTROSHOCK_VULNERABILITY == spellId then
    local target = GetUnitById(id)
    local targetName = target:GetName()
    local isOnMyself = targetName == player.unit:GetName()
    if isOnMyself and mod:GetSetting("MessageElectroshockSwapReturn") then
      mod:AddMsg("ELECTROSHOCK_MSG_OVER", self.L["msg.engineer.electroshock.swap.return"], 5, mod:GetSetting("SoundElectroshockSwapReturn") == true and "Burn")
    end
  elseif DEBUFF_ION_CLASH == spellId and mod:GetSetting("VisualIonClashCircle") then
    core:RemovePolygon("ION_CLASH")
  end
end

function mod:IsPlayerOnPlatform(coreId)
  player.location = mod:GetUnitPlatform(player.unit)
  return player.location == coreId
end

function mod:OnUnitDestroyedRaw(unit)
  local name = unit:GetName()
  if CORE_NAMES[name] ~= nil then
    coreUnits[CORE_NAMES[name]] = nil
  end
end

mod:RegisterUnitEvents({
    "unit.engineer", "unit.warrior",
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
    },{
    ["OnUnitCreated"] = function (_, _, unit, name)
      if CORE_NAMES[name] ~= nil then
        coreUnits[CORE_NAMES[name]] = {
          unit = unit,
          healthWarning = false,
        }
      elseif ENGINEER_NAMES[name] ~= nil then
        local engineerId = ENGINEER_NAMES[name]
        engineerUnits[engineerId] = {
          unit = unit,
          location = ENGINEER_START_LOCATION[engineerId],
        }
      end
      if TableLength(coreUnits) == 4 and TableLength(engineerUnits) == 2 then
        mod:AddUnits()
      end
    end,
    ["OnUnitDestroyed"] = function (_, _, _, name)
      if ENGINEER_NAMES[name] ~= nil then
        engineerUnits[ENGINEER_NAMES[name]] = nil
      end
    end,
  }
)

-- Cores
mod:RegisterUnitEvents({
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
    },{
    ["OnHealthChanged"] = function (self, _, percent, name)
      local coreId = CORE_NAMES[name]
      local coreUnit = coreUnits[coreId]

      mod:UpdateCoreHealthMark(coreUnit, percent)

      if percent > CORE_HEALTH_LOW_WARN_PERCENTAGE_REENABLE and percent < CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE then
        coreUnit.healthWarning = false
      elseif percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE and not coreUnit.healthWarning then
        coreUnit.healthWarning = true
        mod:AddMsg("CORE_HEALTH_HIGH_WARN", self.L["msg.core.health.high.warning"]:format(name), 5, mod:GetSetting("SoundCoreHealthWarning") and "Info")
      elseif percent <= CORE_HEALTH_LOW_WARN_PERCENTAGE and not coreUnit.healthWarning and mod:IsPlayerOnPlatform(coreId) then
        coreUnit.healthWarning = true
        mod:AddMsg("CORE_HEALTH_LOW_WARN", self.L["msg.core.health.low.warning"]:format(name), 5, mod:GetSetting("SoundCoreHealthWarning") and "Inferno")
      end
    end
  }
)

-- Warrior
mod:RegisterUnitEvents("unit.warrior",{
    ["OnCastStart"] = function (self, _, castName)
      if self.L["cast.warrior.liquidate"] == castName then
        if mod:IsPlayerOnPlatform(engineerUnits[WARRIOR].location) then
          mod:AddMsg("LIQUIDATE_MSG", self.L["msg.warrior.liquidate.stack"], 5, mod:GetSetting("SoundLiquidate") == true and "Info")
        end
      end
      if self.L["cast.rocket_jump"] == castName then
        mod:ExtendTimerBar("NEXT_LIQUIDATE_TIMER", 4)
      end
    end,
    ["OnCastEnd"] = function (self, _, castName)
      if self.L["cast.warrior.liquidate"] == castName then
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
        mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", self.L["msg.warrior.liquidate.next"], LIQUIDATE_TIMER)
      end
    end,
  }
)

function mod:IsUnitFacingOtherUnit(unit, otherUnit)
  local unitVector = Vector3.New(unit:GetPosition())
  local otherUnitVector = Vector3.New(otherUnit:GetPosition())
  local difference = otherUnitVector - unitVector
  local normalized = difference:Normal()
  normalized.y = 0
  local facing = Vector3.New(unit:GetFacing())
  local facingDifference = normalized - facing

  return math.abs(facingDifference.x) < 0.01 and math.abs(facingDifference.z) < 0.01
end

-- Engineer
mod:RegisterUnitEvents("unit.engineer",{
    ["OnCastStart"] = function (self, _, castName)
      if self.L["cast.engineer.electroshock"] == castName then
        if mod:GetSetting("LineElectroshock") then
          core:AddPixie("ELECTROSHOCK_PIXIE", 2, engineerUnits[ENGINEER].unit, nil, "Red", 10, 80, 0)
        end
        if mod:IsPlayerOnPlatform(engineerUnits[ENGINEER].location) then
          mod:AddMsg("ELECTROSHOCK_CAST_MSG", self.L["cast.engineer.electroshock"], 5, mod:GetSetting("SoundElectroshock") == true and "Beware")
        end
      end
    end,
    ["OnCastEnd"] = function (self, _, castName)
      if self.L["cast.rocket_jump"] == castName then
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["msg.engineer.electroshock.next"], JUMP_ELECTROSHOCK_TIMER)
      end
      if self.L["cast.engineer.electroshock"] == castName then
        if mod:GetSetting("LineElectroshock") then
          core:DropPixie("ELECTROSHOCK_PIXIE")
        end
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["msg.engineer.electroshock.next"], ELECTROSHOCK_TIMER)
      end
    end,
  }
)

function mod:PopFireOrb()
  if mod:IsPlayerOnPlatform(FUSION_CORE) then
    mod:AddMsg("FIRE_ORB_POP_MSG", self.L["msg.fire_orb.pop.msg"], 5, mod:GetSetting("SoundFireOrbPop") == true and "Alarm")
  end
end

mod:RegisterUnitEvents("unit.fire_orb",{
    ["OnUnitCreated"] = function (self, id, unit)
      core:WatchUnit(unit)
      mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
      mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", self.L["msg.fire_orb.next"], NEXT_FIRE_ORB_TIMER)
      mod:AddTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id), self.L["msg.fire_orb.pop.timer"], FIRE_ORB_SAFE_TIMER, false, "Red", mod.PopFireOrb, mod)
      fireOrbTargetTestTimer:Start()
      orbUnits[id] = {
        unit = unit,
        checkedTarget = false,
        popMessageSent = false,
      }
    end,
    ["OnUnitDestroyed"] = function (_, id)
      orbUnits[id] = nil
      mod:RemoveTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id))
    end,
  }
)
