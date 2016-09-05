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
    ["Next Electroshock in"] = "Next Electroshock in",
    ["Next Liquidate in"] = "Next Liquidate in",
    ["Stack"] = "Stack",
    ["%s SWAP TO WARRIOR"] = "%s SWAP TO WARRIOR",
    ["YOU SWAP TO WARRIOR"] = "YOU SWAP TO WARRIOR",
    ["Next Fire Orb in"] = "Next Fire Orb in",
    ["FIRE ORB ON YOU"] = "FIRE ORB ON YOU",
    ["Fire Orb spawned"] = "Fire Orb spawned",
    ["Fire Orb is safe to pop in"] = "Fire Orb is safe to pop in",
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ION_CLASH = 84051
local DEBUFF_UNSTABLE_VOLTAGE = 84045
local DEBUFF_ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_DIMINISHING_FUSION_REACTION = 87214
local BUFF_INSULATION = 83987
local ELECTROSHOCK_X_TOLERANCE = 0.01
local ELECTROSHOCK_Z_TOLERANCE = 0.011

-- Timers.
local FIRST_ELECTROSHOCK_TIMER = 11
local ELECTROSHOCK_TIMER = 18
local JUMP_ELECTROSHOCK_TIMER = 12
local NEXT_FIRE_ORB_TIMER = 24
local FIRE_ORB_SAFE_TIMER = 14

local FIRST_LIQUIDATE_TIMER = 12
local LIQUIDATE_TIMER = 22

-- Cores.
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
--shorten these
local CORE_NICKNAMES = {
  [FUSION_CORE] = "Fusion Core",
  [COOLING_TURBINE] = "Cooling Turbine",
  [SPARK_PLUG] = "Spark Plug",
  [LUBRICANT_NOZZLE] = "Lubricant Nozzle"
}

-- Engineers.
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
local ENGINEER_NICKNAMES = {
  [WARRIOR] = "Warrior",
  [ENGINEER] = "Engineer",
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
--Do not reset coreUnits since they don't get destroyed after each pull
local coreUnits = {}
local engineerUnits
local playerUnit
local orbUnits
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CoreHealth", false)
mod:RegisterDefaultSetting("Liquidate")
mod:RegisterDefaultSetting("Electroshock")
mod:RegisterDefaultSetting("ElectroshockSwap")
mod:RegisterDefaultSetting("ElectroshockSwapYou")
mod:RegisterDefaultSetting("FireOrb")
mod:RegisterDefaultSetting("FireOrbAlt")
----------------------------------------------------------------------------------------------------
-- Raw event handlers.
----------------------------------------------------------------------------------------------------
Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyedRaw", mod)
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
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

  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["Next Electroshock in"], FIRST_ELECTROSHOCK_TIMER)
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", self.L["Next Liquidate in"], FIRST_LIQUIDATE_TIMER)
end

function mod:OnBossDisable()
  mod:RemoveUnits()
end

function mod:AddUnits()
  for engineerId, engineer in pairs(engineerUnits) do
    core:WatchUnit(engineer.unit)
    core:AddUnit(engineer.unit)
  end
  for coreId, coreUnit in pairs(coreUnits) do
    core:WatchUnit(coreUnit)
    if mod:GetSetting("CoreHealth") then
      core:AddUnit(coreUnit)
    end
  end
end

function mod:RemoveUnits()
  for engineerId, engineer in pairs(engineerUnits) do
    core:RemoveUnit(engineer.unit)
  end
  for coreId, coreUnit in pairs(coreUnits) do
    if mod:GetSetting("CoreHealth") then
      core:RemoveUnit(coreUnit)
    end
  end
end

function mod:CheckBossLocation(engineerId)
  local shortestDistance = 100000
  local currentDistance
  local oldLocation = engineerUnits[engineerId].location
  local newLocation = oldLocation
  for coreId, coreUnit in pairs(coreUnits) do
    currentDistance = mod:GetDistanceBetweenUnits(
      engineerUnits[engineerId].unit, coreUnit
    )
    if shortestDistance > currentDistance then
      shortestDistance = currentDistance
      newLocation = coreId
    end
  end
  if newLocation ~= oldLocation then
    engineerUnits[engineerId].location = newLocation
    mod:OnEngiChangeLocation(engineerId, oldLocation, newLocation)
  end
end

function mod:OnEngiChangeLocation(engineerId, oldCoreId, newCoreId)
end

function mod:OnBuffRemove(id, spellId)
  if spellId == BUFF_INSULATION then
    mod:CheckBossLocation(ENGINEER)
    mod:CheckBossLocation(WARRIOR)
  end
end

function mod:OnDebuffAdd(id, spellId, stack, timeRemaining)
  if DEBUFF_ELECTROSHOCK_VULNERABILITY == spellId then
    local target = GetUnitById(id)
    local targetName = target:GetName()
    local isOnMyself = targetName == playerUnit:GetName()
    local electroshockOnX = ""
    local messageId = string.format("ELECTROSHOCK_MSG_%s", targetName)
    local sound
    if bIsOnMyself then
      electroshockOnX = self.L["YOU SWAP TO WARRIOR"]
      sound = mod:GetSetting("ElectroshockSwapYou") == true and "RunAway"
    else
      electroshockOnX = self.L["%s SWAP TO WARRIOR"]:format(targetName)
      sound = mod:GetSetting("ElectroshockSwap") == true and "Info"
    end

    mod:AddMsg(messageId, electroshockOnX, 5, sound, "Red")
  end
end

function mod:IsPlayerClose(unit)
  return mod:GetDistanceBetweenUnits(playerUnit, unit) < 75
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
    ["OnUnitCreated"] = function (self, id, unit, name)
      if CORE_NAMES[name] ~= nil then
        coreUnits[CORE_NAMES[name]] = unit
      elseif ENGINEER_NAMES[name] ~= nil then
        local engineerId = ENGINEER_NAMES[name]
        engineerUnits[engineerId] = {
          unit = unit,
          location = ENGINEER_START_LOCATION[engineerId],
        }
      end
      if #coreUnits == 4 and #engineerUnits == 2 then
        mod:AddUnits()
      end
    end,
  }
)

-- Warrior
mod:RegisterUnitEvents("Chief Engineer Wilbargh",{
    ["OnCastStart"] = function (self, id, castName, castEndTime, name)
      if self.L["Liquidate"] == castName then
        if mod:IsPlayerClose(engineerUnits[WARRIOR].unit) then
          mod:AddMsg("LIQUIDATE_MSG", self.L["Stack"], 5, mod:GetSetting("Liquidate") == true and "Info")
        end
      end
    end,
    ["OnCastEnd"] = function (self, id, castName, castEndTime, name)
      if self.L["Rocket Jump"] == castName then
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
      end
      if self.L["Liquidate"] == castName then
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
        mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", self.L["Next Liquidate in"], LIQUIDATE_TIMER)
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
  Print(tostring(facingDifference))

  return math.abs(facingDifference.x) < ELECTROSHOCK_X_TOLERANCE and math.abs(facingDifference.z) < ELECTROSHOCK_Z_TOLERANCE
end

-- Engineer
mod:RegisterUnitEvents("Head Engineer Orvulgh",{
    ["OnCastStart"] = function (self, id, castName, castEndTime, name)
      if self.L["Electroshock"] == castName then
        if mod:IsPlayerClose(engineerUnits[ENGINEER].unit) then
          mod:AddMsg("ELECTROSHOCK_CAST_MSG", self.L["Electroshock"], 5, mod:GetSetting("Electroshock") == true and "Beware")
        end
        if mod:IsUnitFacingOtherUnit(engineerUnits[ENGINEER].unit, playerUnit) then
          Print("HE IS FACING ME!")
        end
      end
    end,
    ["OnCastEnd"] = function (self, id, castName, castEndTime, name)
      if self.L["Rocket Jump"] == castName then
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["Next Electroshock in"], JUMP_ELECTROSHOCK_TIMER)
      end
      if self.L["Electroshock"] == castName then
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", self.L["Next Electroshock in"], ELECTROSHOCK_TIMER)
      end
    end,
  }
)

mod:RegisterUnitEvents("Discharged Plasma",{
    ["OnUnitCreated"] = function (self, id, unit, name)
      core:WatchUnit(unit)
      mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
      mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", self.L["Next Fire Orb in"], NEXT_FIRE_ORB_TIMER)
      mod:AddTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id), self.L["Fire Orb is safe to pop in"], FIRE_ORB_SAFE_TIMER)
      local testTimer = ApolloTimer.Create(1, false, "RegisterOrbTarget", mod)
      testTimer:Start()
      orbUnits[id] = {
        unit = unit,
        checkedTarget = false,
        popMessageSent = false,
        timer = testTimer
      }
    end,
    ["OnUnitDestroyed"] = function (self, id, unit, name)
      orbUnits[id] = nil
      mod:RemoveTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", id))
    end,
  }
)

function mod:RegisterOrbTarget()
  for orbId, orbUnit in pairs(orbUnits) do
    if not orbUnit.checkedTarget then
      orbUnit.checkedTarget = true
      local target = orbUnit.unit:GetTarget()
      local isOnMyself = target == playerUnit
      if isOnMyself then
        mod:AddMsg("DISCHARGED_PLASMA_MSG", self.L["FIRE ORB ON YOU"], 5, mod:GetSetting("FireOrb") == true and "RunAway")
      else
        mod:AddMsg("DISCHARGED_PLASMA_MSG", self.L["Fire Orb spawned"], 2, mod:GetSetting("FireOrbAlt") == true and "Info")
      end
    end
  end
end
