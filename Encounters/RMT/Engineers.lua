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
    ["([^%s]+%s[^%s]+) suffers from Electroshock"] = "([^%s]+%s[^%s]+) suffers from Electroshock",
    -- Messages
    ["%s SWAP TO WARRIOR"] = "%s SWAP TO WARRIOR",
    ["YOU SWAP TO WARRIOR"] = "YOU SWAP TO WARRIOR",
    ["Next Fire Orb in"] = "Next Fire Orb in",
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ION_CLASH = 84051
local DEBUFF_UNSTABLE_VOLTAGE = 84045
local DEBUFF_ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_DIMINISHING_FUSION_REACTION = 87214

-- Timers
local FIRST_ELECTROSHOCK_TIMER = 11
local ELECTROSHOCK_TIMER = 18
local JUMP_ELECTROSHOCK_TIMER = 12
local NEXT_FIRE_ORB_TIMER = 24
local FIRE_ORB_SAFE_TIMER = 14

local FIRST_LIQUIDATE_TIMER = 12
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
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  coreUnits = {}
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
  -- This ensures that the core healths get added on the bottom, or else the engineers health will be mixed in with the core healths.
  if mod:GetSetting("CoreHealth") then
    ApolloTimer.Create(1, false, "RegisterCoreHealth", mod)
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
  if DEBUFF_ELECTROSHOCK_VULNERABILITY == nSpellId then
    local target = GetUnitById(nId)
    local targetName = target:GetName()
    local isOnMyself = targetName == playerUnit:GetName()
    local sElectroshockOnX = ""
    local sMessageId = string.format("ELECTROSHOCK_MSG_%s", targetName)
    if bIsOnMyself then
      sElectroshockOnX = self.L["YOU SWAP TO WARRIOR"]
      sSound = mod:GetSetting("ElectroshockSwapYou") == true and "RunAway"
    else
      sElectroshockOnX = self.L["%s SWAP TO WARRIOR"]:format(targetName)
      sSound = mod:GetSetting("ElectroshockSwap") == true and "Info"
    end

    mod:AddMsg(sMessageId, sElectroshockOnX, 5, sSound, "Red")
  end
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
  return mod:GetDistanceBetweenUnits(playerUnit, unit) < 75
end

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
        if mod:IsPlayerClose(engineerUnits[WARRIOR].unit) then
          mod:AddMsg("LIQUIDATE_MSG", "Stack", 5, mod:GetSetting("Liquidate") == true and "Info")
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
        if mod:IsPlayerClose(engineerUnits[ENGINEER].unit) then
          mod:AddMsg("ELECTROSHOCK_CAST_MSG", "Electroshock", 5, mod:GetSetting("Electroshock") == true and "Beware")
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
      core:WatchUnit(tUnit)
      mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
      mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", self.L["Next Fire Orb in"], NEXT_FIRE_ORB_TIMER)
      mod:AddTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", nId), "Fire Orb is safe to pop in", FIRE_ORB_SAFE_TIMER)
      local testTimer = ApolloTimer.Create(1, false, "RegisterOrbTarget", mod)
      testTimer:Start()
      orbUnits[nId] = {
        unit = tUnit,
        checkedTarget = false,
        popMessageSent = false,
        timer = testTimer
      }
    end,
    ["OnUnitDestroyed"] = function (self, nId, tUnit, sName)
      orbUnits[nId] = nil
      mod:RemoveTimerBar(string.format("FIRE_ORB_SAFE_TIMER %d", nId))
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
        mod:AddMsg("DISCHARGED_PLASMA_MSG", "FIRE ORB ON YOU", 5, mod:GetSetting("FireOrb") == true and "RunAway")
      else
        mod:AddMsg("DISCHARGED_PLASMA_MSG", "Fire Orb spawned", 2, mod:GetSetting("FireOrbAlt") == true and "Info")
      end
    end
  end
end

--function mod:OnBuffUpdate(nId, nSpellId, nOldStack, nStack, fTimeRemaining)
--  if nSpellId == 87214 and nStack > 7 then
--    local orbUnit = orbUnits[nId]
--    if not orbUnit.popMessageSent then
--      orbUnit.popMessageSent = true
--      local target = orbUnit.unit:GetTarget()
--      local isOnMyself = target == playerUnit
--      if isOnMyself then
--        mod:AddMsg("DISCHARGED_PLASMA_MSG_POP", "POP THE FIRE ORB", 5, mod:GetSetting("FireOrbPop") == true and "Inferno")
--      end
--    end
--  end
--end

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
