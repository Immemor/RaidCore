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
local mod = core:NewEncounter("Engineers", 104, {548, 0}, {552, 548})
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, {
    "unit.warrior", "unit.engineer",
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
  }
)
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
    ["msg.engineer.electroshock.swap.return"] = "SWAP TO ENGINEER",
    ["msg.fire_orb.next"] = "Next Fire Orb in",
    ["msg.fire_orb.you"] = "FIRE ORB ON YOU",
    ["msg.fire_orb.spawned"] = "Fire Orb",
    ["msg.fire_orb.pop.timer"] = "Fire Orb is safe to pop in",
    ["msg.fire_orb.pop.msg"] = "Pop the Orb",
    ["msg.core.health.high.warning"] = "%s HIGH HEALTH!",
    ["msg.core.health.low.warning"] = "%s LOW HEALTH!",
    ["msg.rocket_jump.moved"] = "%s MOVED",
    ["msg.heat.generation"] = "Core Health",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.fire_orb"] = "Plasmaentladung",
    -- Public Event Names.
    ["pub.fusion_core"] = "Fusionskern",
    ["pub.cooling_turbine"] = "Kühlturbine",
    ["pub.spark_plug"] = "Zündkerze",
    ["pub.lubricant_nozzle"] = "Schmiermitteldüse",
    -- Datachrons.
    ["chron.elektroshock"] = "([^%s]+%s[^%s]+) leidet unter „Electroshock“",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.fire_orb"] = "Plasma déchargé",
    -- Public Event Names.
    ["pub.fusion_core"] = "Noyau de fusion",
    ["pub.cooling_turbine"] = "Turbine de refroidissement",
    ["pub.spark_plug"] = "Bougie d'allumage",
    ["pub.lubricant_nozzle"] = "Embout de lubrification",
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  ELECTROSHOCK_VULNERABILITY = 83798,
  ATOMIC_ATTRACTION = 84053,
  ION_CLASH = 84051,
}
local BUFFS = {
  INSULATION = 83987,
}

local TIMERS = {
  ELECTROSHOCK = {
    FIRST = 11,
    JUMP = 12,
    NORMAL = 18,
  },
  FIRE_ORB = {
    FIRST = 21,
    NORMAL = 24,
    SAFE = 18,
  },
  LIQUIDATE = {
    FIRST = 12,
    NORMAL = 22,
    EXTEND = 4,
  }
}

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
local tempCores = CORE_NAMES
CORE_NAMES = {}
for locale, planet in next, tempCores do
  CORE_NAMES[mod.L[locale]] = planet
end
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
local tempEngis = ENGINEER_NAMES
ENGINEER_NAMES = {}
for locale, planet in next, tempEngis do
  ENGINEER_NAMES[mod.L[locale]] = planet
end
local ENGINEER_START_LOCATION = {
  [WARRIOR] = SPARK_PLUG,
  [ENGINEER] = COOLING_TURBINE,
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local next, GetUnitById = next, GameLib.GetUnitById
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local coreUnits
local engineerUnits
local player
local coreMaxHealth
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("BarsCoreHealth", false)
mod:RegisterDefaultSetting("MarkerCoreHealth")
mod:RegisterDefaultSetting("MarkerDebuff")
mod:RegisterDefaultSetting("LineElectroshock")
mod:RegisterDefaultSetting("VisualIonClashCircle")
-- Sounds.
mod:RegisterDefaultSetting("SoundBossMove", false)
mod:RegisterDefaultSetting("SoundLiquidate")
mod:RegisterDefaultSetting("SoundElectroshock")
mod:RegisterDefaultSetting("SoundElectroshockSwap")
mod:RegisterDefaultSetting("SoundElectroshockSwapYou")
mod:RegisterDefaultSetting("SoundElectroshockSwapReturn")
mod:RegisterDefaultSetting("SoundFireOrb")
mod:RegisterDefaultSetting("SoundFireOrbAlt")
mod:RegisterDefaultSetting("SoundFireOrbPop")
mod:RegisterDefaultSetting("SoundCoreHealthWarning")
-- Messages.
mod:RegisterDefaultSetting("MessageBossMove", false)
mod:RegisterDefaultSetting("MessageElectroshockSwap")
mod:RegisterDefaultSetting("MessageElectroshockSwapYou")
mod:RegisterDefaultSetting("MessageElectroshockSwapReturn")
mod:RegisterDefaultSetting("MessageLiquidate")
mod:RegisterDefaultSetting("MessageElectroshock")
mod:RegisterDefaultSetting("MessageFireOrb")
mod:RegisterDefaultSetting("MessageFireOrbAlt")
mod:RegisterDefaultSetting("MessageFireOrbPop")
mod:RegisterDefaultSetting("MessageCoreHealthWarning")
-- Binds.
mod:RegisterMessageSetting("BOSS_MOVED_PLATFORM", core.E.COMPARE_EQUAL, "MessageBossMove", "SoundBossMove")
mod:RegisterMessageSetting("ELECTROSHOCK_MSG_OVER", core.E.COMPARE_EQUAL, "MessageElectroshockSwapReturn", "SoundElectroshockSwapReturn")
mod:RegisterMessageSetting("ELECTROSHOCK_MSG_YOU", core.E.COMPARE_EQUAL, "MessageElectroshockSwapYou", "SoundElectroshockSwapYou")
mod:RegisterMessageSetting("ELECTROSHOCK_MSG_OTHER", core.E.COMPARE_FIND, "MessageElectroshockSwap", "SoundElectroshockSwap")
mod:RegisterMessageSetting("ELECTROSHOCK_CAST_MSG", core.E.COMPARE_EQUAL, "MessageElectroshock", "SoundElectroshock")
mod:RegisterMessageSetting("LIQUIDATE_MSG", core.E.COMPARE_EQUAL, "MessageLiquidate", "SoundLiquidate")
mod:RegisterMessageSetting("DISCHARGED_PLASMA_MSG", core.E.COMPARE_EQUAL, "MessageFireOrb", "SoundFireOrb")
mod:RegisterMessageSetting("DISCHARGED_PLASMA_MSG_SPAWN", core.E.COMPARE_EQUAL, "MessageFireOrbAlt", "SoundFireOrbAlt")
mod:RegisterMessageSetting("FIRE_ORB_POP_MSG", core.E.COMPARE_EQUAL, "MessageFireOrbPop", "SoundFireOrbPop")
mod:RegisterMessageSetting("CORE_HEALTH_[^_]+_WARN", core.E.COMPARE_MATCH, "MessageCoreHealthWarning", "SoundCoreHealthWarning")
-- Timer default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_ELEKTROSHOCK_TIMER"] = { sColor = "xkcdGreen" },
    ["NEXT_LIQUIDATE_TIMER"] = { sColor = "xkcdOrange" },
    ["NEXT_FIRE_ORB_TIMER"] = { sColor = "xkcdLightRed" },
  }
)
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  player = {}
  player.unit = GameLib.GetPlayerUnit()
  player.location = 0
  coreMaxHealth = 0
  engineerUnits = {}
  coreUnits = {}

  if mod:GetSetting("BarsCoreHealth") then
    core:AddUnitSpacer("CORE_SPACER", nil, 2)
  end

  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "msg.engineer.electroshock.next", TIMERS.ELECTROSHOCK.FIRST)
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "msg.warrior.liquidate.next", TIMERS.LIQUIDATE.FIRST)
  mod:AddProgressBar("HEAT_GENERATIOn", "msg.heat.generation", mod.GetCoreTotalHealthPercentage, mod)
end

function mod:GetCoreTotalHealthPercentage(oldValue)
  if not coreMaxHealth then
    return oldValue
  end
  local coreCurrentHealth = 0
  local totalHealthPercent
  local barColor = "xkcdRed"
  for coreId, coreUnit in pairs(coreUnits) do
    coreCurrentHealth = coreCurrentHealth + coreUnit.unit:GetHealth()
  end
  totalHealthPercent = (coreCurrentHealth / coreMaxHealth) * 100
  if totalHealthPercent < 28.5 then
    barColor = "xkcdGreen"
  elseif totalHealthPercent < 30 then
    barColor = "xkcdOrange"
  end
  return totalHealthPercent, barColor
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
  if ENGINEER_NICK_NAMES[engineerId] ~= nil then
    local msg = self.L["msg.rocket_jump.moved"]:format(self.L[ENGINEER_NICK_NAMES[engineerId]])
    mod:AddMsg("BOSS_MOVED_PLATFORM", msg, 5, "Alarm", "xkcdWhite")
  end
  if newLocation == FUSION_CORE then
    mod:RemoveTimerBar("NEXT_FIRE_ORB_TIMER")
    mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", "msg.fire_orb.next", TIMERS.FIRE_ORB.FIRST)
  end
end

function mod:UpdateCoreHealthMark(coreUnit)
  if not mod:GetSetting("MarkerCoreHealth") then
    return
  end
  local percent = coreUnit.percent
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

function mod:OnAnyUnitDestroyed(id, unit, name)
  core:DropMark(id)
end

function mod:OnElectroshockAdd(id, spellId, stack, timeRemaining, targetName)
  local targetUnit
  if id == player.unit:GetId() then
    targetUnit = player.unit
    mod:AddMsg("ELECTROSHOCK_MSG_YOU", "msg.engineer.electroshock.swap.you", 5, "Burn", "Red")
  else
    targetUnit = GetUnitById(id)
    local messageId = string.format("ELECTROSHOCK_MSG_OTHER_%s", targetName)
    local electroshockOnX = self.L["msg.engineer.electroshock.swap.other"]:format(targetName)
    mod:AddMsg(messageId, electroshockOnX, 5, "Info", "xkcdBlue")
  end
  if mod:GetSetting("MarkerDebuff") then
    core:MarkUnit(targetUnit, core.E.LOCATION_STATIC_CHEST, "E", "xkcdOrange")
  end
end

function mod:OnElectroshockRemove(id, spellId, targetName)
  if id == player.unit:GetId() then
    mod:AddMsg("ELECTROSHOCK_MSG_OVER", "msg.engineer.electroshock.swap.return", 5, "Burn", "xkcdGreen")
  end
  core:DropMark(id)
end

function mod:OnIonClashAdd(id, spellId, stack, timeRemaining, name)
  if mod:GetSetting("VisualIonClashCircle") then
    core:AddPolygon("ION_CLASH", id, 9, 0, 10, "xkcdBlue", 64)
  end
end

function mod:OnIonClashRemove(id, spellId, name)
  core:RemovePolygon("ION_CLASH")
end

function mod:OnAtomicAttactionAdd(id, spellId, stack, timeRemaining, targetName)
  if id == player.unit:GetId() then
    mod:AddMsg("DISCHARGED_PLASMA_MSG", "msg.fire_orb.you", 5, "RunAway", "xkcdLightRed")
  elseif mod:IsPlayerOnPlatform(FUSION_CORE) then
    mod:AddMsg("DISCHARGED_PLASMA_MSG_SPAWN", "msg.fire_orb.spawned", 2, "Info", "xkcdWhite")
  end
end

function mod:IsPlayerOnPlatform(coreId)
  player.location = mod:GetUnitPlatform(player.unit)
  return player.location == coreId
end

function mod:OnEngineerCreated(id, unit, name)
  local engineerId = ENGINEER_NAMES[name]
  engineerUnits[engineerId] = {
    unit = unit,
    location = ENGINEER_START_LOCATION[engineerId],
  }
  core:WatchUnit(unit, core.E.TRACK_CASTS)
  mod:AddUnit(unit, nil, 1)
end

function mod:OnCoreCreated(id, unit, name)
  coreUnits[CORE_NAMES[name]] = {
    unit = unit,
    healthWarning = false,
    enabled = false,
    percent = 30,
  }
  coreMaxHealth = coreMaxHealth + unit:GetMaxHealth()
  core:WatchUnit(unit, core.E.TRACK_BUFFS + core.E.TRACK_HEALTH)
  mod:UpdateCoreHealthMark(coreUnits[CORE_NAMES[name]])
  if mod:GetSetting("BarsCoreHealth") then
    mod:AddUnit(unit, CORE_BAR_COLORS[CORE_NAMES[name]], 3)
  end
end

function mod:OnEngineerDestroyed(id, unit, name)
  engineerUnits[ENGINEER_NAMES[name]] = nil
end

function mod:OnCoreHealthChanged(id, percent, name)
  local coreId = CORE_NAMES[name]
  local coreUnit = coreUnits[coreId]
  coreUnit.percent = percent
  mod:UpdateCoreHealthMark(coreUnit)

  if percent > CORE_HEALTH_LOW_WARN_PERCENTAGE_REENABLE and percent < CORE_HEALTH_HIGH_WARN_PERCENTAGE_REENABLE then
    coreUnit.healthWarning = false
  elseif percent >= CORE_HEALTH_HIGH_WARN_PERCENTAGE and not coreUnit.healthWarning then
    coreUnit.healthWarning = true
    mod:AddMsg("CORE_HEALTH_HIGH_WARN", self.L["msg.core.health.high.warning"]:format(name), 5, "Info", "xkcdRed")
  elseif percent <= CORE_HEALTH_LOW_WARN_PERCENTAGE and not coreUnit.healthWarning and mod:IsPlayerOnPlatform(coreId) then
    coreUnit.healthWarning = true
    mod:AddMsg("CORE_HEALTH_LOW_WARN", self.L["msg.core.health.low.warning"]:format(name), 5, "Inferno", "xkcdRed")
  end
end

function mod:OnCoreInsulationAdd(id, spellId, stack, timeRemaining, name)
  local coreUnit = coreUnits[CORE_NAMES[name]]
  coreUnit.enabled = false
  mod:UpdateCoreHealthMark(coreUnit)
end

function mod:OnCoreInsulationRemove(id, spellId, name)
  local coreUnit = coreUnits[CORE_NAMES[name]]
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

function mod:OnWarriorLiquidateStart()
  if mod:IsPlayerOnPlatform(engineerUnits[WARRIOR].location) then
    mod:AddMsg("LIQUIDATE_MSG", "msg.warrior.liquidate.stack", 5, "Info", "xkcdOrange")
  end
end

function mod:OnWarriorLiquidateEnd()
  mod:AddTimerBar("NEXT_LIQUIDATE_TIMER", "msg.warrior.liquidate.next", TIMERS.LIQUIDATE.NORMAL)
end

function mod:OnWarriorRocketJumpStart()
  mod:ExtendTimerBar("NEXT_LIQUIDATE_TIMER", TIMERS.LIQUIDATE.EXTEND)
end

function mod:OnEngineerElectroshockStart()
  if mod:GetSetting("LineElectroshock") then
    core:AddSimpleLine("ELECTROSHOCK", engineerUnits[ENGINEER].unit, nil, 80, nil, 10, "xkcdRed")
  end
  if mod:IsPlayerOnPlatform(engineerUnits[ENGINEER].location) then
    mod:AddMsg("ELECTROSHOCK_CAST_MSG", "cast.engineer.electroshock", 5, "Beware", "xkcdOrange")
  end
end

function mod:OnEngineerElectroshockEnd()
  core:RemoveSimpleLine("ELECTROSHOCK")
  mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "msg.engineer.electroshock.next", TIMERS.ELECTROSHOCK.NORMAL)
end

function mod:OnEngineerRocketJumpEnd()
  mod:RemoveTimerBar("NEXT_ELEKTROSHOCK_TIMER")
  mod:AddTimerBar("NEXT_ELEKTROSHOCK_TIMER", "msg.engineer.electroshock.next", TIMERS.ELECTROSHOCK.JUMP)
end

function mod:PopFireOrb()
  if mod:IsPlayerOnPlatform(FUSION_CORE) then
    mod:AddMsg("FIRE_ORB_POP_MSG", "msg.fire_orb.pop.msg", 5, "Alarm", "xkcdGreen")
  end
end

function mod:OnFireOrbCreated(id, unit, name)
  mod:AddTimerBar("NEXT_FIRE_ORB_TIMER", "msg.fire_orb.next", TIMERS.FIRE_ORB.NORMAL)
  mod:AddTimerBar("FIRE_ORB_SAFE_TIMER_"..id, "msg.fire_orb.pop.timer", TIMERS.FIRE_ORB.SAFE, false, "Red", mod.PopFireOrb, mod)
end

function mod:OnFireOrbDestroyed(id, unit, name)
  mod:RemoveTimerBar("FIRE_ORB_SAFE_TIMER_"..id)
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.UNIT_DESTROYED] = mod.OnAnyUnitDestroyed,
    [DEBUFFS.ELECTROSHOCK_VULNERABILITY] = {
      [core.E.DEBUFF_ADD] = mod.OnElectroshockAdd,
      [core.E.DEBUFF_REMOVE] = mod.OnElectroshockRemove,
    },
    [DEBUFFS.ION_CLASH] = {
      [core.E.DEBUFF_ADD] = mod.OnIonClashAdd,
      [core.E.DEBUFF_REMOVE] = mod.OnIonClashRemove,
    },
    [core.E.DEBUFF_ADD] = {
      [DEBUFFS.ATOMIC_ATTRACTION] = mod.OnAtomicAttactionAdd,
    },
  }
)
mod:RegisterUnitEvents({
    "unit.fusion_core",
    "unit.cooling_turbine",
    "unit.spark_plug",
    "unit.lubricant_nozzle"
    },{
    [core.E.UNIT_CREATED] = mod.OnCoreCreated,
    [core.E.HEALTH_CHANGED] = mod.OnCoreHealthChanged,
    [BUFFS.INSULATION] = {
      [core.E.BUFF_ADD] = mod.OnCoreInsulationAdd,
      [core.E.BUFF_REMOVE] = mod.OnCoreInsulationRemove,
    },
  }
)
mod:RegisterUnitEvents({"unit.engineer", "unit.warrior"}, {
    [core.E.UNIT_CREATED] = mod.OnEngineerCreated,
    [core.E.UNIT_DESTROYED] = mod.OnEngineerDestroyed,
  }
)
mod:RegisterUnitEvents("unit.warrior",{
    ["cast.warrior.liquidate"] = {
      [core.E.CAST_START ]= mod.OnWarriorLiquidateStart,
      [core.E.CAST_END] = mod.OnWarriorLiquidateEnd,
    },
    [core.E.CAST_START] = {
      ["cast.rocket_jump"] = mod.OnWarriorRocketJumpStart,
    },
  }
)
mod:RegisterUnitEvents("unit.engineer",{
    ["cast.engineer.electroshock"] = {
      [core.E.CAST_START] = mod.OnEngineerElectroshockStart,
      [core.E.CAST_END] = mod.OnEngineerElectroshockEnd,
    },
    ["cast.rocket_jump"] = {
      [core.E.CAST_END] = mod.OnEngineerRocketJumpEnd,
    },
  }
)
mod:RegisterUnitEvents("unit.fire_orb",{
    [core.E.UNIT_CREATED] = mod.OnFireOrbCreated,
    [core.E.UNIT_DESTROYED] = mod.OnFireOrbDestroyed,
  }
)
