----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--[[
Description:
2 Boms will appear at the same time at 2 different corners of the map.
They loose health over time and can be dpsed. They explode at 0 health and
deal significant damage to the raid and put different debuffs on all players.

Incendiary Warhead:
Puts a dot on all players.

Caustic Warhead:
Reduces all incoming healing by 70% on all players.

Strat:
Explode caustic warhead first, use dmg reduction abilities like dGrid. Heal up
after it explodes and let incendiary die by itself and then heal up again.
--]]
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Luk'Ki", 104, 548, 555)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "unit.luk'ki" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.luk'ki"] = "Munitions Specialist Luk'ki",
    -- Cast names.
    -- Messages.
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents({"unit.luk'ki"},{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_ALL)
    end,
  }
)
