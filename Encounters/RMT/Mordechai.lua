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
local mod = core:NewEncounter("Mordechai", 104, 0, 548)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Mordechai Redmoon" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Mordechai Redmoon"] = "Mordechai Redmoon"
  })
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("Mordechai Redmoon",{
    ["OnUnitCreated"] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
  }
)
