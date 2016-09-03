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
    -- Cast names
    ["Liquidate"] = "Liquidate",
    ["Electroshock"] = "Electroshock",
    -- Datachron
    ["suffers from Electroshock"] = "suffers from Electroshock",
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_ION_CLASH = 84051
local DEBUFF_UNSTABLE_VOLTAGE = 84045

-- Timers
local FIRST_ELECTROSHOCK_TIMER = 12
local ELECTROSHOCK_TIMER = 20

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
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

local currentWarriorPlatform
local currentEngineerPlatform
local coreUnits
local engineerUnits
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
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
end

function mod:GetCurrentPlatform(tUnit, sName)
  local i
  local shortestDistance = 100000
  local currentDistance
  local currentPlatform
  for i=1,4,1
  do
    currentDistance = mod:GetDistanceBetweenUnits(tUnit, BUFF_STATIONS[i])
    if shortestDistance > currentDistance then
      shortestDistance = currentDistance
      currentPlatform = BUFF_STATIONS[i]
    end
  end

  -- Engineer
  if sName == self.L["Head Engineer Orvulgh"] then
    currentEngineerPlatform = currentPlatform
  end

  -- Warrior
  if sName == self.L["Chief Engineer Wilbargh"] then
    currentEngineerPlatform = currentPlatform
  end
  Print("Engineer Platform: " .. currentEngineerPlatform)
  Print("Warrior Platform: " .. currentWarriorPlatform)
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  if DEBUFF_ION_CLASH == nSpellId then
    mod:AddMsg("ION_CLASH_MSG", "KITE THE FIRE ORB", 5, "RunAway")
    core:AddPicture(nId, nId, "Crosshair", 20)
  end
  if DEBUFF_UNSTABLE_VOLTAGE == nSpellId then
    mod:AddMsg("UNSTABLE_VOLTAGE_MSG", "GET AWAY FROM THE CENTER", 5, "RunAway")
  end
end

function mod:OnDebuffRemove(nId, nSpellId, nStack, fTimeRemaining)
  if nSpellId == DEBUFF_ION_CLASH then
    core:RemovePicture(nId)
  end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)

end

function mod:OnUnitCreated(nId, unit, sName)

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
        engineerUnits[ENGINEER_NAMES[sName]] = {
          unit = tUnit,
          location = ENGINEER_START_LOCATION[ENGINEER_NAMES[sName]],
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
        mod:AddMsg("LIQUIDATE_MSG", "Stack", 5, "Info")
      end
    end,
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      mod:GetCurrentPlatform(tUnit, sName)
    end,
    ["OnCastEnd"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Rocket Jump"] == sCastName then
        mod:GetCurrentPlatform(tUnit, sName)
      end
    end,
  }
)

-- Engineer
mod:RegisterUnitEvents("Head Engineer Orvulgh",{
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Electroshock"] == sCastName then
        mod:AddMsg("ELECTROSHOCK_CAST_MSG", "Electroshock", 5, "Info")
      end
    end,
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      mod:GetCurrentPlatform(tUnit, sName)
    end,
    ["OnCastEnd"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Rocket Jump"] == sCastName then
        mod:GetCurrentPlatform(tUnit, sName)
      end
    end,
  }
)

mod:RegisterDatachronEvent("suffers from Electroshock", "FIND", function (self, sMessage)
    local tElectroshockTarget = GetPlayerUnitByName(string.match(sMessage, "([^%s]+%s[^%s]+)".." "..self.L["suffers from Electroshock"]))
    local bIsOnMyself = tElectroshockTarget == playerUnit
    local sSound = "Info"
    local sElectroshockOnX = ""
    if bIsOnMyself then
      sElectroshockOnX = self.L["YOU SWAP TO WARRIOR"]
    else
      sElectroshockOnX = self.L["%s SWAP TO WARRIOR"]:format(tElectroshockTarget:GetName())
    end

    mod:AddMsg("ELECTROSHOCK_MSG", sElectroshockOnX, 5, sSound, "Red")
  end
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
