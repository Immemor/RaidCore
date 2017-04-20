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
local ApolloTimer = require "ApolloTimer"
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Octog", 104, 0, 548)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.octog" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.octog"] = "Star-Eater the Voracious",
    ["unit.squirgling"] = "Squirgling",
    ["unit.orb"] = "Chaos Orb",
    ["unit.pool"] = "Noxious Ink Pool",
    -- NPC says.
    ["say.octog.orb"] = "Stay close! The feast be about to begin!",
    ["say.octog.supernova"] = "Ye'll be helpless soon... and I'll be fed!",
    -- Cast names.
    ["cast.octog.supernova"] = "Supernova",
    ["cast.octog.hookshot"] = "Hookshot",
    ["cast.octog.flamethrower"] = "Flamethrower",
    ["cast.octog.squirgling"] = "Summon Squirglings",
    -- Buffs.
    ["buff.pool.ink"] = "Noxious Ink",
    ["buff.squirgling.smasher"] = "Squirgling Smasher",
    ["buff.octog.rend"] = "Rend",
    ["buff.octog.flamethrower"] = "Space Fire",
    ["buff.octog.shield"] = "Astral Shield",
    ["buff.octog.orb.channel"] = "Chaos Orbs",
    ["buff.octog.orb.amplifier"] = "Chaos Amplifier",
    ["buff.orb.target"] = "Chaos Orb",
    ["buff.orb.tether"] = "Chaos Tether",
    ["buff.orb.energies"] = "Chaotic Energies",
    -- Messages.
    ["msg.octog.hookshot.next"] = "Next hookshot in",
    ["msg.octog.flamethrower.next"] = "Next flamethrower in",
    ["msg.octog.flamethrower.interrupt"] = "INTERRUPT OCTOG",
    ["msg.octog.hookshot"] = "HOOKSHOT",
    ["msg.octog.supernova.wipe"] = "Supernova end in",
    ["msg.orb.first"] = "First orb soon",
    ["msg.orb.next"] = "%d orbs in",
    ["msg.orb.spawn"] = "%d orbs spawning",
    ["msg.midphase.coming"] = "Midphase coming soon",
    ["msg.midphase.started"] = "MIDPHASE",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.octog"] = "Dévore-Astre le Vorace",
    -- NPC says.
    ["say.octog.orb"] = "Reste là ! Le festin va bientôt commencer !",
    ["say.octog.supernova"] = "Bientôt, tu pourras plus rien faire... et moi, j'aurai plus faim !",
    -- Buffs.
    ["buff.orb.energies"] = "Énergies chaotiques",
    ["buff.octog.flamethrower"] = "Feu spatial",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.octog"] = "Sternenschlinger der Gefräßige",
    -- NPC says.
    ["say.octog.orb"] = "Bleibt schön in der Nähe! Gleich gibt’s was zu futtern!",
    ["say.octog.supernova"] = "Bald wirst du aufhören zu zappeln ... und mein Bauch aufhören zu grummeln!",
    -- Buffs.
    ["buff.orb.energies"] = "Chaotische Energien",
    ["buff.octog.flamethrower"] = "Weltraumfeuer",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("CircleOrb")
mod:RegisterDefaultSetting("MarkOrb")
mod:RegisterDefaultSetting("CircleInkPools")
-- Sounds.
mod:RegisterDefaultSetting("SoundChaosOrbSoon")
mod:RegisterDefaultSetting("SoundMidphaseSoon")
mod:RegisterDefaultSetting("SoundMidphaseStarted")
mod:RegisterDefaultSetting("SoundFlamethrowerInterrupt")
mod:RegisterDefaultSetting("SoundHookshot")
mod:RegisterDefaultSetting("SoundOrbSpawn")
-- Messages.
mod:RegisterDefaultSetting("MessageChaosOrbSoon")
mod:RegisterDefaultSetting("MessageMidphaseSoon")
mod:RegisterDefaultSetting("MessageMidphaseStarted")
mod:RegisterDefaultSetting("MessageFlamethrowerInterrupt")
mod:RegisterDefaultSetting("MessageHookshot")
mod:RegisterDefaultSetting("MessageOrbSpawn")
mod:RegisterDefaultSetting("MessageAstralShield")
-- Binds.
mod:RegisterMessageSetting("CHAOS_ORB_SOON", core.E.COMPARE_EQUAL, "MessageChaosOrbSoon", "MessageChaosOrbSoon")
mod:RegisterMessageSetting("ORB_SPAWN", core.E.COMPARE_EQUAL, "MessageOrbSpawn", "SoundOrbSpawn")
mod:RegisterMessageSetting("MIDPHASE_SOON", core.E.COMPARE_EQUAL, "MessageMidphaseSoon", "SoundMidphaseSoon")
mod:RegisterMessageSetting("MIDPHASE_STARTED", core.E.COMPARE_EQUAL, "MessageMidphaseStarted", "SoundMidphaseStarted")
mod:RegisterMessageSetting("FLAMETHROWER_MSG_CAST", core.E.COMPARE_EQUAL, "MessageFlamethrowerInterrupt", "SoundFlamethrowerInterrupt")
mod:RegisterMessageSetting("HOOKSHOT_CAST", core.E.COMPARE_EQUAL, "MessageHookshot", "SoundHookshot")
mod:RegisterMessageSetting("ASTRAL_SHIELD_STACKS", core.E.COMPARE_EQUAL, "MessageAstralShield")
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_HOOKSHOT_TIMER"] = { sColor = "xkcdBrown" },
    ["NEXT_FLAMETHROWER_TIMER"] = { sColor = "xkcdRed" },
    ["NEXT_ORB_TIMER"] = { sColor = "xkcdPurple" },
    ["SUPERNOVA_WIPE_TIMER"] = { sColor = "xkcdRed" }
  }
)
mod:RegisterUnitBarConfig("unit.octog", {
    nPriority = 0,
    tMidphases = {
      {percent = 85, color = "xkcdBlack"},
      {percent = 65},
      {percent = 35},
      {percent = 5},
    }
  }
)
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local next, floor, max = next, math.floor, math.max
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Debuffs and Buffs.
local DEBUFFS = {
  REND = 85443, --Reduces Mitigation by 2.5% per stack.
  NOXIOUS_INK = 85533, --Taking X damage every 0s.
  SQUIRGLING_SMASHER = 86804, --Increases Damage Dealt by 5% and Outgoing healing by 5% per stack.
  SPACE_FIRE = 87159, --Taking X technology damage every 3s.
  CHAOS_ORB = 85578, --Protected by Chaos Orbs.
  CHAOS_ORB_STACK = 85582, --Damage taken increased by 10% per stack.
  CHAOS_TETHER = 85583, --Chaos orb deals lethal damage to those who try to scape its grasp.
}
local BUFFS = {
  CHAOS_AMPLIFIER = 86876, --Increases the potency of Chaos Orbs.
  CHAOS_ORBS = 86885, --Channeling Chaos Orbs.
  ASTRAL_SHIELD = 85679, --Immune to damage.
  ASTRAL_SHIELD_STACKS = 85643, --Immune to damage.
}

local TIMERS = {
  HOOKSHOT = {
    FIRST = 10,
    NORMAL = 30,
  },
  FLAMETHROWER = {
    NORMAL = 40,
  },
  ORB = {
    SECOND = 80,
    NORMAL = 85,
  },
  SUPERNOVA = {
    WIPE = 25,
  },
  POOL = {
    UPDATE = 0.25,
    GROW = 7.5,
  }
}

local POOL_SIZES = {
  5.5, 7.55, 9.3, 11.6, 13.5, 15.5, 17.5
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local orbCount
local nextOrbTime
local playerId
local currentOrbNumber
local inkPools
local drawPools
local updatePoolTimer = ApolloTimer.Create(TIMERS.POOL.UPDATE, true, "OnUpdatePoolTimer", mod)
updatePoolTimer:Stop()
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  orbCount = 0
  inkPools = {}
  drawPools = false
  playerId = GameLib.GetPlayerUnit():GetId()
  mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.octog.hookshot.next", TIMERS.HOOKSHOT.FIRST)
  mod:AddTimerBar("NEXT_FLAMETHROWER_TIMER", "msg.octog.flamethrower.next", TIMERS.FLAMETHROWER.NORMAL)
  updatePoolTimer:Start()
end

function mod:OnBossDisable()
  updatePoolTimer:Stop()
end

function mod:IsPhaseClose(phase, percent)
  for i = 1, #phase do
    if percent >= phase[i].LOWER and percent <= phase[i].UPPER then
      return true
    end
  end
  return false
end

function mod:DisplayInterruptFlamethrower()
  mod:AddMsg("FLAMETHROWER_MSG_CAST", "msg.octog.flamethrower.interrupt", 2, "Inferno", "xkcdOrange")
end

function mod:OnFlamethrowerStart()
  mod:RemoveTimerBar("NEXT_FLAMETHROWER_TIMER")
  mod:ScheduleTimer("DisplayInterruptFlamethrower", 1)
end

function mod:OnFlamethrowerEnd()
  mod:AddTimerBar("NEXT_FLAMETHROWER_TIMER", "msg.octog.flamethrower.next", TIMERS.FLAMETHROWER.NORMAL)
end

function mod:OnSupernovaStart()
  mod:AddMsg("MIDPHASE_STARTED", "msg.midphase.started", 5, "Info", "xkcdWhite")
  mod:RemoveTimerBar("NEXT_HOOKSHOT_TIMER")
  mod:RemoveTimerBar("NEXT_FLAMETHROWER_TIMER")
  mod:RemoveTimerBar("NEXT_ORB_TIMER")
  mod:AddTimerBar("SUPERNOVA_WIPE_TIMER", "msg.octog.supernova.wipe", TIMERS.SUPERNOVA.WIPE)
end

function mod:OnSupernovaEnd()
  mod:RemoveTimerBar("SUPERNOVA_WIPE_TIMER")
  mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.octog.hookshot.next", TIMERS.HOOKSHOT.NORMAL)
  core:RemoveMsg("ASTRAL_SHIELD_STACKS")
  mod:StartOrbTimer(max(nextOrbTime - GetGameTime(), 10))
end

function mod:OnHookshotStart()
  mod:AddMsg("HOOKSHOT_CAST", "msg.octog.hookshot", 2, "Beware", "xkcdRed")
end

function mod:OnHookshotEnd()
  mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.octog.hookshot.next", TIMERS.HOOKSHOT.NORMAL)
end

function mod:OnOctogCreated(id, unit)
  core:WatchUnit(unit, core.E.TRACK_CASTS + core.E.TRACK_HEALTH + core.E.TRACK_BUFFS)
end

function mod:OnOctogHealthChanged(id, percent, name)
  local isMidPhaseClose = mod:IsMidphaseClose(name, percent)
  if isMidPhaseClose then
    if percent > 84 then
      mod:AddMsg("CHAOS_ORB_SOON", "msg.orb.first", 5, "Info", "xkcdWhite")
    else
      mod:AddMsg("MIDPHASE_SOON", "msg.midphase.coming", 5, "Info", "xkcdWhite")
    end
  end
end

function mod:OnBarUnitCreated(id, unit)
  mod:AddUnit(unit)
end

function mod:StartOrbTimer(timer)
  local msg = self.L["msg.orb.next"]:format(orbCount + 1)
  mod:AddTimerBar("NEXT_ORB_TIMER", msg, timer)
end

function mod:OnOrbsSpawning()
  currentOrbNumber = 0
  orbCount = orbCount + 1
  local msg = self.L["msg.orb.spawn"]:format(orbCount)
  mod:AddMsg("ORB_SPAWN", msg, 2, "Info", "xkcdWhite")
  mod:DrawPools()

  local orbTimer = orbCount == 1 and TIMERS.ORB.SECOND or TIMERS.ORB.NORMAL
  mod:StartOrbTimer(orbTimer)
  nextOrbTime = GetGameTime() + orbTimer
end

function mod:OnAstralShieldUpdate(id, spellId, stacks)
  mod:AddMsg("ASTRAL_SHIELD_STACKS", stacks, 5, nil, "xkcdOrange")
end

function mod:DrawOrbCircle(id, unit, color)
  if mod:GetSetting("CircleOrb") then
    core:AddPolygon(id, unit, 16.5, nil, 5, color, 20)
  end
end

function mod:MarkOrbWithNumber(unit)
  if mod:GetSetting("MarkOrb") then
    core:MarkUnit(unit, core.E.LOCATION_STATIC_FLOOR, currentOrbNumber)
  end
end

function mod:OnOrbCreated(id, unit)
  currentOrbNumber = currentOrbNumber + 1
  mod:DrawOrbCircle(id, unit, "xkcdGreen")
  mod:MarkOrbWithNumber(unit)
end

function mod:OnChaosTetherAdd(id, spellId, stacks, timeRemaining, sName, unitCaster)
  if id == playerId and unitCaster and unitCaster:IsValid() then
    mod:DrawOrbCircle(unitCaster:GetId(), unitCaster, "xkcdRed")
  end
end

function mod:DrawPools()
  drawPools = true
  for id, inkPool in next, inkPools do
    mod:DrawPool(inkPool)
  end
end

function mod:RemovePools()
  drawPools = false
  for id, inkPool in next, inkPools do
    mod:RemovePool(inkPool)
  end
end

function mod:RemovePool(inkPool)
  core:RemovePolygon(inkPool.id)
end

function mod:DrawPool(inkPool)
  if drawPools and mod:GetSetting("CircleInkPools") then
    local poolSize = POOL_SIZES[inkPool.currentSizeIndex]
    core:AddPolygon(inkPool.id, inkPool.unit, poolSize, nil, 1, "xkcdBlack", 15)
  end
end

function mod:UpdatePoolSize(inkPool, poolSizeIndex)
  if inkPool.currentSizeIndex ~= poolSizeIndex and poolSizeIndex <= #POOL_SIZES then
    inkPool.currentSizeIndex = poolSizeIndex
    mod:DrawPool(inkPool)
  end
end

function mod:OnUpdatePoolTimer()
  local currentTime = GetGameTime()
  for id, inkPool in next, inkPools do
    local poolSizeIndex = floor((currentTime - inkPool.creationTime)/TIMERS.POOL.GROW) + 1
    mod:UpdatePoolSize(inkPool, poolSizeIndex)
  end
end

function mod:OnPoolCreated(id, unit)
  inkPools[id] = {
    creationTime = GetGameTime(),
    unit = unit,
    currentSizeIndex = 1,
    id = id,
  }
  mod:DrawPool(inkPools[id])
end

function mod:OnPoolDestroyed(id, unit)
  inkPools[id] = nil
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.octog",{
    [core.E.UNIT_CREATED] = mod.OnOctogCreated,
    [core.E.HEALTH_CHANGED] = mod.OnOctogHealthChanged,
    ["cast.octog.flamethrower"] = {
      [core.E.CAST_START] = mod.OnFlamethrowerStart,
      [core.E.CAST_END] = mod.OnFlamethrowerEnd,
    },
    ["say.octog.supernova"] = {
      [core.E.NPC_SAY] = mod.OnSupernovaStart,
    },
    ["cast.octog.supernova"] = {
      [core.E.CAST_END] = mod.OnSupernovaEnd,
    },
    ["cast.octog.hookshot"] = {
      [core.E.CAST_START] = mod.OnHookshotStart,
      [core.E.CAST_END] = mod.OnHookshotEnd,
    },
    ["say.octog.orb"] = {
      [core.E.NPC_SAY] = mod.OnOrbsSpawning,
    },
    [BUFFS.ASTRAL_SHIELD_STACKS] = {
      [core.E.BUFF_UPDATE] = mod.OnAstralShieldUpdate,
    },
    [BUFFS.CHAOS_ORBS] = {
      [core.E.BUFF_REMOVE] = mod.RemovePools,
    },
  }
)
mod:RegisterUnitEvents("unit.orb", {
    [core.E.UNIT_CREATED] = mod.OnOrbCreated,
  }
)
mod:RegisterUnitSpellEvent(core.E.ALL_UNITS, core.E.DEBUFF_ADD, DEBUFFS.CHAOS_TETHER, mod.OnChaosTetherAdd)
mod:RegisterUnitEvents({"unit.orb", "unit.octog"}, {
    [core.E.UNIT_CREATED] = mod.OnBarUnitCreated,
  }
)
mod:RegisterUnitEvents("unit.pool", {
    [core.E.UNIT_CREATED] = mod.OnPoolCreated,
    [core.E.UNIT_DESTROYED] = mod.OnPoolDestroyed,
  }
)
