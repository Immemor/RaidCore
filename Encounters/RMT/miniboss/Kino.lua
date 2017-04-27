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

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Kino", 104, 548, 553)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "unit.kino", "unit.station" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.kino"] = "Mixmaster Kino",
    ["unit.station"] = "DJ Station",
    -- Cast names.
    ["cast.kino.bass"] = "Drop the Bass",
    -- Messages.
    ["msg.kino.sick_beats.timer"] = "Sick beats interval %.1fs",
    ["msg.kino.sick_beats.speedup"] = "Sick beats every %.1fs",
    ["msg.kino.bass.timer"] = "Dropping the bass in",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_SICK_BEATS_SPEEDUP"] = {sColor = "xkcdRed"},
    ["NEXT_BASS_DROP"] = {sColor = "xkcdPurple"},
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local TIMERS = {
  SICK_BEATS = {
    SPEEDUP = 40,
    INITIAL_INTERVAL = 5.5,
  },
  BASS = {
    NORMAL = 40,
  }
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local sickBeatsInterval
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  sickBeatsInterval = TIMERS.SICK_BEATS.INITIAL_INTERVAL
  mod:StartSpeedupTimer()
  mod:StartBassTimer()
end

function mod:StartBassTimer()
  mod:AddTimerBar("NEXT_BASS_DROP", "msg.kino.bass.timer", TIMERS.BASS.NORMAL)
end

function mod:StartSpeedupTimer()
  local msg = self.L["msg.kino.sick_beats.timer"]:format(sickBeatsInterval)
  mod:AddTimerBar("NEXT_SICK_BEATS_SPEEDUP", msg, TIMERS.SICK_BEATS.SPEEDUP, nil, nil, mod.OnSpeedupTimer, mod)
end

function mod:ShowSpeedupMessage()
  local msg = self.L["msg.kino.sick_beats.speedup"]:format(sickBeatsInterval)
  mod:AddMsg("SICK_BEATS_SPEEDUP", msg, 5, "Info", "xkcdOrange")
end

function mod:OnSpeedupTimer()
  sickBeatsInterval = sickBeatsInterval - 1
  mod:ShowSpeedupMessage()
  mod:StartSpeedupTimer()
end

mod:RegisterUnitEvents({"unit.kino", "unit.station"},{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CAST)
    end,
  }
)

function mod:OnBassCastStart()
  mod:RemoveTimerBar("NEXT_BASS_DROP")
end

function mod:OnBassCastEnd()
  mod:StartBassTimer()
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.kino",{
    ["cast.kino.bass"] = {
      [core.E.CAST_START] = mod.OnBassCastStart,
      [core.E.CAST_END] = mod.OnBassCastEnd,
    }
  }
)
