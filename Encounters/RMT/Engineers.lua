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
    -- Cast names
    ["Liquidate"] = "Liquidate",
    ["Electroshock"] = "Electroshock",
    -- Datachron
    ["suffers from Electroshock"] = "suffers from Electroshock",
    -- Messages
    ["%s SWAP TO WARRIOR"] = "%s SWAP TO WARRIOR",
    ["YOU SWAP TO WARRIOR"] = "YOU SWAP TO WARRIOR",
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ION_CLASH = 84051
local DEBUFF_UNSTABLE_VOLTAGE = 84045

-- Timers
local FIRST_ELECTROSHOCK_TIMER = 11
local ELECTROSHOCK_TIMER = 18
local JUMP_ELECTROSHOCK_TIMER = 17

local FIRST_LIQUIDATE_TIMER = 14
local LIQUIDATE_TIMER = 22
local JUMP_LIQUIDATE_TIMER = 17

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
local ENGINEER_TIMER_NAMES = {
  [WARRIOR] = "OnWarriorLocationTimer",
  [ENGINEER] = "OnEngineerLocationTimer",
}
local ENGINEER_NICKNAMES = {
  [WARRIOR] = "Warrior",
  [ENGINEER] = "Engineer",
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime

local currentWarriorPlatform
local currentEngineerPlatform
local coreUnits
local engineerUnits
local playerUnit
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CoreHealth", false)
mod:RegisterDefaultSetting("Liquidate")
mod:RegisterDefaultSetting("Electroshock")
mod:RegisterDefaultSetting("ElectroshockSwap")
mod:RegisterDefaultSetting("ElectroshockSwapYou")
mod:RegisterDefaultSetting("FireOrb")
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  coreUnits = {}
  engineerUnits = {}
  --locales
  for name, id in pairs(CORE_NAMES) do
    CORE_NAMES[name] = nil
    CORE_NAMES[self.L[name]] = id
  end
  for name, id in pairs(ENGINEER_NAMES) do
    ENGINEER_NAMES[name] = nil
    ENGINEER_NAMES[self.L[name]] = id
  end
  -- This ensures that the core healths get added on the bottom, or else the engineers health will be mixed in with the core healths.
  if mod:GetSetting("CoreHealth") then
    timer = ApolloTimer.Create(1, false, "RegisterCoreHealth", mod)
  end
  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "Next Electroshock in", FIRST_ELECTROSHOCK_TIMER)
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "Next Liquidate in", FIRST_LIQUIDATE_TIMER)
end

function mod:RegisterCoreHealth()
  for coreId, coreUnit in pairs(coreUnits) do
    core:AddUnit(coreUnit)
  end
end

function mod:CheckBossLocation(engineerId)
  if engineerUnits[engineerId].firstCheck then
    engineerUnits[engineerId].firstCheck = false
    return
  end

  local shortestDistance = 100000
  local currentDistance
  for coreId, coreUnit in pairs(coreUnits) do
    currentDistance = mod:GetDistanceBetweenUnits(
      engineerUnits[engineerId].unit, coreUnit
    )
    if shortestDistance > currentDistance then
      shortestDistance = currentDistance
      engineerUnits[engineerId].location = coreId
    end
  end
end

function mod:OnWarriorLocationTimer()
  mod:CheckBossLocation(WARRIOR)
end

function mod:OnEngineerLocationTimer()
  mod:CheckBossLocation(ENGINEER)
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  --[=====[
  if DEBUFF_ION_CLASH == nSpellId then
    mod:AddMsg("DISCHARGED_PLASMA_MSG", "KITE THE FIRE ORB", 5, "RunAway")
    core:AddPicture(nId, nId, "Crosshair", 20)
  end
  if DEBUFF_UNSTABLE_VOLTAGE == nSpellId then
    mod:AddMsg("UNSTABLE_VOLTAGE_MSG", "GET AWAY FROM THE CENTER", 5, "RunAway")
  end
  --]=====]
end

function mod:OnDebuffRemove(nId, nSpellId, nStack, fTimeRemaining)
  --[=====[
  if nSpellId == DEBUFF_ION_CLASH then
    core:RemovePicture(nId)
  end
  --]=====]
end

function mod:OnUnitDestroyed(nId, tUnit, sName)

end

function mod:IsPlayerClose(unit)
  return mod:GetDistanceBetweenUnits(playerunit, unit) < 75
end

mod:RegisterDatachronEvent("suffers from Electroshock", "FIND", function (self, sMessage)
    local tElectroshockTarget = string.match(sMessage, "([^%s]+%s[^%s]+)" .. " " .. self.L["suffers from Electroshock"])
    local bIsOnMyself = tElectroshockTarget == playerUnit:GetName()
    local sSound = "Info"
    local sElectroshockOnX = ""
    if bIsOnMyself then
      sElectroshockOnX = self.L["YOU SWAP TO WARRIOR"]
      sSound = "RunAway"
    else
      sElectroshockOnX = self.L["%s SWAP TO WARRIOR"]:format(tElectroshockTarget)
    end

    mod:AddMsg("ELECTROSHOCK_MSG", sElectroshockOnX, 5, sSound, "Red")
  end
)

mod:RegisterUnitEvents({
    "Head Engineer Orvulgh", "Chief Engineer Wilbargh",
    "Fusion Core",
    "Cooling Turbine",
    "Spark Plug",
    "Lubricant Nozzle"
    },{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:WatchUnit(tUnit)
      if CORE_NAMES[sName] ~= nil then
        coreUnits[CORE_NAMES[sName]] = tUnit
      elseif ENGINEER_NAMES[sName] ~= nil then
        local id = ENGINEER_NAMES[sName]
        engineerUnits[id] = {
          unit = tUnit,
          location = ENGINEER_START_LOCATION[id],
          timer = ApolloTimer.Create(1.5, false, ENGINEER_TIMER_NAMES[id], mod),
          firstCheck = true,
        }
      end
    end,
  }
)

-- Warrior
mod:RegisterUnitEvents("Chief Engineer Wilbargh",{
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Liquidate"] == sCastName then
        --Stack
        if mod:IsPlayerClose(engineerUnits[WARRIOR].unit) and mod:GetSetting("Liquidate") then
          mod:AddMsg("LIQUIDATE_MSG", "Stack", 5, "Info")
        end
      end
    end,
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
    end,
    ["OnCastEnd"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Rocket Jump"] == sCastName then
        engineerUnits[WARRIOR].timer:Start()
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
        mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "Next Liquidate in", JUMP_LIQUIDATE_TIMER)
      end
      if self.L["Liquidate"] == sCastName then
        mod:RemoveTimerBar("NEXT_LIQUIDATE_TIMER")
        mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "Next Liquidate in", LIQUIDATE_TIMER)
      end
    end,
  }
)

-- Engineer
mod:RegisterUnitEvents("Head Engineer Orvulgh",{
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Electroshock"] == sCastName then
        if mod:IsPlayerClose(engineerUnits[ENGINEER].unit) and mod:GetSetting("Electroshock") then
          mod:AddMsg("ELECTROSHOCK_CAST_MSG", "Electroshock", 5, "Beware")
        end
      end
    end,
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
    end,
    ["OnCastEnd"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Rocket Jump"] == sCastName then
        engineerUnits[ENGINEER].timer:Start()
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "Next Electroshock in", JUMP_ELECTROSHOCK_TIMER)
      end
      if self.L["Electroshock"] == sCastName then
        mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
        mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "Next Electroshock in", ELECTROSHOCK_TIMER)
      end
    end,
  }
)

mod:RegisterUnitEvents("Discharged Plasma",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      if mod:IsPlayerClose(tUnit) and mod:GetSetting("FireOrb") then
        mod:AddMsg("DISCHARGED_PLASMA_MSG", "KITE THE FIRE ORB", 5, "RunAway")
        local tOrbTarget = tUnit:GetTarget()
        --Print(tOrbTarget)
      end
    end,
  }
)

-- mod:RegisterUnitEvents({"Friendly Invisible Unit for Fields"},{
-- ["OnUnitCreated"] = function (self, nId, tUnit, sName)
-- core:AddPixie(nId, 2, tUnit, nil, "Green", 10, 50, 0)
-- core:AddPixie(nId, 2, tUnit, nil, "Green", 10, 20, 180)
-- end,
-- ["OnUnitDestroyed"] = function (self, nId, tUnit, sName)
-- core:DropPixie(nId)
-- end,
-- }
-- )
