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
mod:RegisterTrigMob("ALL", { "unit.octog" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.octog"] = "Star-Eater the Voracious",
    ["unit.squirgling"] = "Squirgling",
    ["unit.orb"] = "Chaos Orb",
    ["unit.pool"] = "Noxious Ink Pool",
    -- Cast names.
    ["cast.supernova"] = "Supernova",
    ["cast.hookshot"] = "Hookshot",
    ["cast.flamethrower"] = "Flamethrower",
    -- Messages.
    ["msg.hookshot.next"] = "Next hookshot in",
    ["msg.flamethrower.next"] = "Next flamethrower in",
    ["msg.chaos.orbs.coming"] = "Chaos orb(s) coming soon",
    ["msg.midphase.coming"] = "Midphase coming soon",
    ["msg.midphase.started"] = "MIDPHASE",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

-- Timers.
local FIRST_HOOKSHOT_TIMER = 10
local HOOKSHOT_TIMER = 45
local FLAMETHROWER_TIMER = 40

-- Health trackers
local FIRST_CHAOS_ORB_UPPER_HEALTH = 86.5
local FIRST_CHAOS_ORB_LOWER_HEALTH = 85.5

local SECOND_CHAOS_ORB_UPPER_HEALTH = 71.5
local SECOND_CHAOS_ORB_LOWER_HEALTH = 70.5

local MIDPHASE_UPPER_HEALTH = 66.5
local MIDPHASE_LOWER_HEALTH = 65.5

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.hookshot.next", FIRST_HOOKSHOT_TIMER)
  mod:AddTimerBar("NEXT_FLAMETHROWER_TIMER", "msg.flamethrower.next", FLAMETHROWER_TIMER)
  mod:DrawCompactorGrid()
end

mod:RegisterUnitEvents({
    "unit.orb",
    },{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
  }
)

mod:RegisterUnitEvents({
    "unit.octog",
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
    [core.E.HEALTH_CHANGED] = function(_, _, percent)
      if (percent >= FIRST_CHAOS_ORB_LOWER_HEALTH and percent <= FIRST_CHAOS_ORB_UPPER_HEALTH) or (percent >= SECOND_CHAOS_ORB_LOWER_HEALTH and percent <= SECOND_CHAOS_ORB_UPPER_HEALTH) then
        mod:AddMsg("CHAOS_ORB_SOON", "msg.chaos.orbs.coming", 5, "Info", "xkcdWhite")
      end
      if (percent >= MIDPHASE_LOWER_HEALTH and percent <= MIDPHASE_UPPER_HEALTH) then
        mod:AddMsg("MIDPHASE_SOON", "msg.midphase.coming", 5, "Info", "xkcdWhite")
      end
    end,
    [core.E.CAST_START] = {
      ["cast.supernova"] = function(self)
        mod:AddMsg("MIDPHASE_STARTED", "msg.midphase.started", 5, "Info", "xkcdWhite")
        mod:RemoveTimerBar("NEXT_HOOKSHOT_TIMER")
        mod:RemoveTimerBar("NEXT_FLAMETHROWER_TIMER")
      end,
    },
    [core.E.CAST_END] = {
      ["cast.hookshot"] = function(self)
        mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.hookshot.next", HOOKSHOT_TIMER)
      end,
      ["cast.flamethrower"] = function(self)
        mod:AddTimerBar("NEXT_HOOKSHOT_TIMER", "msg.flamethrower.next", FLAMETHROWER_TIMER)
      end
    },
  }
)

mod:RegisterUnitEvents({
    "unit.squirgling",
    "unit.pool",
    },{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:WatchUnit(unit)
    end,
  }
)
