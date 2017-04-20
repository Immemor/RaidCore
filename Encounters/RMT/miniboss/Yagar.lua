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
local mod = core:NewEncounter("Yagar", 104, 548, 553)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "unit.yagar", "unit.disposal" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.yagar"] = "Fry-Cook Yagar",
    ["unit.glob"] = "Sauce Glob",
    ["unit.disposal"] = "Garbage Disposal",
    ["unit.grease"] = "Grease Fire",
    ["unit.cubig"] = "Roasting Cubig",
    -- Cast names.
    -- Messages.
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  CHARCUTERIE = 87842, --Probably pig target
  SIZZLING = 87747, -- ??
}
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents({"unit.yagar", "unit.disposal", "unit.cubig"},{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_ALL)
    end,
  }
)
