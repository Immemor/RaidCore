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
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("CircleOrb")
mod:RegisterDefaultSetting("MarkOrb")
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
  },
  SUPERNOVA = {
    WIPE = 25,
  }
}

-- Health trackers
local FIRST_ORB_CLOSE = {
  {UPPER = 86.5, LOWER = 85.5}, -- 85
}

local PHASES_CLOSE = {
  {UPPER = 66.5, LOWER = 65.5}, -- 65
  {UPPER = 36.5, LOWER = 35.5}, -- 35
  {UPPER = 6.5, LOWER = 5.5}, -- 5
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local orbCount
local playerId
local currentOrbNumber
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  orbCount = 0
  playerId = GameLib.GetPlayerUnit():GetId()
  mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.octog.hookshot.next", TIMERS.HOOKSHOT.FIRST)
  mod:AddTimerBar("NEXT_FLAMETHROWER_TIMER", "msg.octog.flamethrower.next", TIMERS.FLAMETHROWER.NORMAL)
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
  mod:AddTimerBar("SUPERNOVA_WIPE_TIMER", "msg.octog.supernova.wipe", TIMERS.SUPERNOVA.WIPE)
end

function mod:OnSupernovaEnd()
  mod:RemoveTimerBar("SUPERNOVA_WIPE_TIMER")
  mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.octog.hookshot.next", TIMERS.HOOKSHOT.NORMAL)
  core:RemoveMsg("ASTRAL_SHIELD_STACKS")
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

function mod:OnOctogHealthChanged(id, percent)
  if mod:IsPhaseClose(FIRST_ORB_CLOSE, percent) then
    mod:AddMsg("CHAOS_ORB_SOON", "msg.orb.first", 5, "Info", "xkcdWhite")
  end
  if mod:IsPhaseClose(PHASES_CLOSE, percent) then
    mod:AddMsg("MIDPHASE_SOON", "msg.midphase.coming", 5, "Info", "xkcdWhite")
  end
  if percent == 85 then
    --TODO what happens after midphase
    local msg = self.L["msg.orb.next"]:format(2)
    mod:AddTimerBar("NEXT_ORB_TIMER", msg, TIMERS.ORB.SECOND)
  end
end

function mod:AddUnit(id, unit)
  core:AddUnit(unit)
end

function mod:OnOrbsSpawning()
  currentOrbNumber = 0
  orbCount = orbCount + 1
  local msg = self.L["msg.orb.spawn"]:format(orbCount)
  mod:AddMsg("ORB_SPAWN", msg, 2, "Info", "xkcdWhite")
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

function mod:OnOrbDestroyed(id, unit)
  core:RemovePolygon(id)
end

function mod:OnChaosTetherAdd(id, spellId, stacks, timeRemaining, sName, unitCaster)
  if id == playerId and unitCaster and unitCaster:IsValid() then
    mod:DrawOrbCircle(unitCaster:GetId(), unitCaster, "xkcdRed")
  end
end

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
    }
  }
)

mod:RegisterUnitEvents("unit.orb", {
    [core.E.UNIT_CREATED] = mod.OnOrbCreated,
    [core.E.UNIT_DESTROYED] = mod.OnOrbDestroyed,
  }
)
mod:RegisterUnitSpellEvent(core.E.ALL_UNITS, core.E.DEBUFF_ADD, DEBUFFS.CHAOS_TETHER, mod.OnChaosTetherAdd)
mod:RegisterUnitEvents({"unit.orb", "unit.octog"}, {
    [core.E.UNIT_CREATED] = mod.AddUnit,
  }
)
