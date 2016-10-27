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
local mod = core:NewEncounter("Thrag", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "unit.thrag" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.thrag"] = "Chief Engine Scrubber Thrag",
    ["unit.jumpstart"] = "Jumpstart Charge",
    -- Cast names.
    ["cast.thrag.gigavolt"] = "Gigavolt",
    -- Messages.
    ["msg.thrag.gigavolt.get_out"] = "GET OUT",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.jumpstart"] = "Starthilfe-Ladung",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.jumpstart"] = "Charge de démarrage",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("BombLines", false)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local playerUnit
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
end

mod:RegisterUnitEvents("unit.thrag",{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS)
    end,
  }
)

mod:RegisterUnitEvents("unit.jumpstart",{
    [core.E.UNIT_CREATED] = function (_, id, unit)
      if mod:GetSetting("BombLines") then
        core:AddLineBetweenUnits("JUMP_START_LINE_"..id, playerUnit:GetId(), id, 5)
      end
    end,
    [core.E.UNIT_DESTROYED] = function (_, id)
      if mod:GetSetting("BombLines") then
        core:RemoveLineBetweenUnits("JUMP_START_LINE_"..id)
      end
    end,
  }
)
