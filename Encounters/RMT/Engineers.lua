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
    "Chief Engineer Wilbargh", "Head Engineer Orvulgh",
    "Fusion Core",
    "Cooling Turbine",
    "Spark Plug",
    "Lubricant Nozzle"
  })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Fusion Core"] = "Fusion Core",
    ["Cooling Turbine"] = "Cooling Turbine",
    ["Spark Plug"] = "Spark Plug",
    ["Lubricant Nozzle"] = "Lubricant Nozzle",
    ["Head Engineer Orvulgh"] = "Head Engineer Orvulgh", -- Engineer
    ["Chief Engineer Wilbargh"] = "Chief Engineer Wilbargh", -- Warrior
    ["Air Current"] = "Air Current",
    ["Friendly Invisible Unit for Fields"] = "Friendly Invisible Unit for Fields",
    ["Hostile Invisible Unit for Fields (0 hit radius)"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    ["Discharged Plasma"] = "Discharged Plasma", -- Fire Orb
    -- Cast names.
    ["Liquidate"] = "Liquidate",
    ["Electroshock"] = "Electroshock",
    -- Datachron.
    ["([^%s]+%s[^%s]+) suffers from Electroshock"] = "([^%s]+%s[^%s]+) suffers from Electroshock",
    -- Messages.
    ["electroshock.next"] = "Next Electroshock in",
    ["liquidate.next"] = "Next Liquidate in",
    ["liquidate.stack"] = "Stack",
    ["electroshock.swap.other"] = "%s SWAP TO WARRIOR",
    ["electroshock.swap.you"] = "YOU SWAP TO WARRIOR",
    ["fire_orb.next"] = "Next Fire Orb in",
    ["fire_orb.you"] = "FIRE ORB ON YOU",
    ["fire_orb.spawned"] = "Fire Orb spawned",
    ["fire_orb.pop.timer"] = "Fire Orb is safe to pop in",
    ["fire_orb.pop.msg"] = "Pop the Fire Orb!",
    ["core.health.high.warning"] = "%s pillar at 85%%!",
    ["core.health.low.warning"] = "%s pillar at 15%%!"
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ELECTROSHOCK_VULNERABILITY = 83798
local BUFF_INSULATION = 83987

-- Timers
local FIRST_ELECTROSHOCK_TIMER = 11
local ELECTROSHOCK_TIMER = 18
local JUMP_ELECTROSHOCK_TIMER = 12
local NEXT_FIRE_ORB_TIMER = 24
local FIRE_ORB_SAFE_TIMER = 14

local FIRST_LIQUIDATE_TIMER = 12
local LIQUIDATE_TIMER = 22

local FUSION_CORE = 1
local COOLING_TURBINE = 2
local SPARK_PLUG = 3
local LUBRICANT_NOZZLE = 4
local CORE_NAMES = {
  ["Fusion Core"] = FUSION_CORE,
  ["Cooling Turbine"] = COOLING_TURBINE,
  ["Spark Plug"] = SPARK_PLUG,
  ["Lubricant Nozzle"] = LUBRICANT_NOZZLE
}

local WARRIOR = 1
local ENGINEER = 2
local ENGINEER_NAMES = {
  ["Chief Engineer Wilbargh"] = WARRIOR,
  ["Head Engineer Orvulgh"] = ENGINEER,
}
local ENGINEER_START_LOCATION = {
  [WARRIOR] = SPARK_PLUG,
  [ENGINEER] = COOLING_TURBINE,
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local function TableLength(table)
  local count = 0
  for _, _ in pairs(table) do
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
    CORE_NAMES[name] = nil
    CORE_NAMES[self.L[name]] = id
  end
  for name, id in pairs(ENGINEER_NAMES) do
    ENGINEER_NAMES[name] = nil
    ENGINEER_NAMES[self.L[name]] = id
  end

  for _, coreUnit in pairs(coreUnits) do
    coreUnit.healthWarning = false
  end

  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["electroshock.next"], FIRST_ELECTROSHOCK_TIMER)
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", self.L["liquidate.next"], FIRST_LIQUIDATE_TIMER)
end

function mod:OnBossDisable()
  mod:RemoveUnits()
end

function mod:AddUnits()
  for _, engineer in pairs(engineerUnits) do
    core:WatchUnit(engineer.unit)
    core:AddUnit(engineer.unit)
  end
  if mod:GetSetting("BarsCoreHealth") then
    core:AddUnitSpacer("CORE_SPACER")
  end
  for _, coreUnit in pairs(coreUnits) do
    core:WatchUnit(coreUnit.unit)
    if mod:GetSetting("BarsCoreHealth") then
      core:AddUnit(coreUnit.unit)
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
  for coreId, coreUnit in pairs(coreUnits) do
    currentDistance = mod:GetDistanceBetweenUnits(unit, coreUnit.unit)
    if shortestDistance > currentDistance then
      shortestDistance = currentDistance
      location = coreId
    end
  end
  return location
end

function mod:OnEngiChangeLocation()
end

function mod:OnBuffRemove(_, spellId)
  if spellId == BUFF_INSULATION then
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
      electroshockOnX = self.L["electroshock.swap.you"]
      sound = mod:GetSetting("SoundElectroshockSwapYou") == true and "Burn"
    else
      electroshockOnX = self.L["electroshock.swap.other"]:format(targetName)
      sound = mod:GetSetting("SoundElectroshockSwap") == true and "Info"
    end
    if isOnMyself or mod:GetSetting("MessageElectroshockSwap") then
      mod:AddMsg(messageId, electroshockOnX, 5, sound, "Red")
    end
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
    "Head Engineer Orvulgh", "Chief Engineer Wilbargh",
    "Fusion Core",
    "Cooling Turbine",
    "Spark Plug",
    "Lubricant Nozzle"
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
    "Fusion Core",
    "Cooling Turbine",
    "Spark Plug",
    "Lubricant Nozzle"
    },{
    ["OnHealthChanged"] = function (self, _, percent, name)
      local coreId = CORE_NAMES[name]
      local coreUnit = coreUnits[coreId]
      if percent > 15 and percent < 85 then
        coreUnit.healthWarning = false
      elseif percent >= 85 and not coreUnit.healthWarning then
        coreUnit.healthWarning = true
        mod:AddMsg("CORE_HEALTH_HIGH_WARN", self.L["core.health.high.warning"]:format(name), 5, mod:GetSetting("SoundCoreHealthWarning") and "Info")
      elseif percent <= 15 and not coreUnit.healthWarning and mod:IsPlayerOnPlatform(coreId) then
        coreUnit.healthWarning = true
        mod:AddMsg("CORE_HEALTH_LOW_WARN", self.L["core.health.low.warning"]:format(name), 5, mod:GetSetting("SoundCoreHealthWarning") and "Inferno")
      end
    end
  }
)

-- Warrior
mod:RegisterUnitEvents("Chief Engineer Wilbargh",{
    ["OnCastStart"] = function (self, _, castName)
      if self.L["Liquidate"] == castName then
        if mod:IsPlayerOnPlatform(engineerUnits[WARRIOR].location) then
          mod:AddMsg("LIQUIDATE_MSG", self.L["liquidate.stack"], 5, mod:GetSetting("SoundLiquidate") == true and "Info")
        end
      end
    end,
    ["OnCastEnd"] = function (self, _, castName)
      if self.L["Rocket Jump"] == castName then
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
      end
      if self.L["Liquidate"] == castName then
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
        mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", self.L["liquidate.next"], LIQUIDATE_TIMER)
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
mod:RegisterUnitEvents("Head Engineer Orvulgh",{
    ["OnCastStart"] = function (self, _, castName)
      if self.L["Electroshock"] == castName then
        if mod:GetSetting("LineElectroshock") then
          core:AddPixie("ELECTROSHOCK_PIXIE", 2, engineerUnits[ENGINEER].unit, nil, "Red", 10, 80, 0)
        end
        if mod:IsPlayerOnPlatform(engineerUnits[ENGINEER].location) then
          mod:AddMsg("ELECTROSHOCK_CAST_MSG", self.L["Electroshock"], 5, mod:GetSetting("SoundElectroshock") == true and "Beware")
        end
      end
    end,
    ["OnCastEnd"] = function (self, _, castName)
      if self.L["Rocket Jump"] == castName then
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["electroshock.next"], JUMP_ELECTROSHOCK_TIMER)
      end
      if self.L["Electroshock"] == castName then
        if mod:GetSetting("LineElectroshock") then
          core:DropPixie("ELECTROSHOCK_PIXIE")
        end
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["electroshock.next"], ELECTROSHOCK_TIMER)
      end
    end,
  }
)

function mod:PopFireOrb()
  if mod:IsPlayerOnPlatform(FUSION_CORE) then
    mod:AddMsg("FIRE_ORB_POP_MSG", self.L["fire_orb.pop.msg"], 5, mod:GetSetting("SoundFireOrbPop") == true and "Alarm")
  end
end

mod:RegisterUnitEvents("Discharged Plasma",{
    ["OnUnitCreated"] = function (self, id, unit)
      core:WatchUnit(unit)
      mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
      mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", self.L["fire_orb.next"], NEXT_FIRE_ORB_TIMER)
      mod:AddTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id), self.L["fire_orb.pop.timer"], FIRE_ORB_SAFE_TIMER, false, "Red", mod.PopFireOrb, mod)
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

function mod:RegisterOrbTarget()
  if orbUnits == nil then
    return
  end
  for _, orbUnit in pairs(orbUnits) do
    if not orbUnit.checkedTarget then
      orbUnit.checkedTarget = true
      local target = orbUnit.unit:GetTarget()
      local isOnMyself = target == player.unit
      if isOnMyself then
        mod:AddMsg("DISCHARGED_PLASMA_MSG", self.L["fire_orb.you"], 5, mod:GetSetting("SoundFireOrb") == true and "RunAway")
      elseif mod:IsPlayerOnPlatform(FUSION_CORE) then
        mod:AddMsg("DISCHARGED_PLASMA_MSG", self.L["fire_orb.spawned"], 2, mod:GetSetting("SoundFireOrbAlt") == true and "Info")
      end
    end
  end
end
