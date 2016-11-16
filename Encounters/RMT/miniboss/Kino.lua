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
local mod = core:NewEncounter("Kino", 104, 548, 553)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "unit.kino", "unit.station" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.kino"] = "Mixmaster Kino",
    ["unit.station"] = "DJ Station",
    -- Cast names.
    -- Messages.
    ["msg.kino.sick_beats.timer"] = "Sick beats interval %ds",
    ["msg.kino.sick_beats.speedup"] = "Sick beats every %ds",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_SICK_BEATS_SPEEDUP"] = {sColor = "xkcdRed"},
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local TIMERS = {
  SICK_BEATS = {
    SPEEDUP = 40,
    START = 5.5,
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
  sickBeatsInterval = TIMERS.SICK_BEATS.START
  mod:StartSpeedupTimer()
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
      core:WatchUnit(unit, core.E.TRACK_ALL)
    end,
  }
)
