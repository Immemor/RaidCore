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
local mod = core:NewEncounter("Skooty", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "unit.skooty" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.skooty"] = "Assistant Technician Skooty",
    ["unit.jumpstart"] = "unit.jumpstart",
    -- Cast names.
    ["cast.skooty.cannon"] = "Pulse Cannon",
    -- Messages.
    ["msg.skooty.cannon.get_out"] = "GET OUT",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("PulseCannon")
mod:RegisterDefaultSetting("BombLines", false)
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local jumpStarts
local playerUnit
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  jumpStarts = {}
end

mod:RegisterUnitEvents("unit.skooty",{
    [core.E.UNIT_CREATED] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS)
    end,
    [core.E.CAST_START] = {
      ["cast.skooty.cannon"] = function (self, _, castName)
        mod:AddMsg("PULSECANNON", self.L["msg.skooty.cannon.get_out"], 5, mod:GetSetting("PulseCannon") == true and "RunAway")
      end,
    }
  }
)

mod:RegisterUnitEvents("unit.jumpstart",{
    [core.E.UNIT_CREATED] = function (_, id, unit)
      jumpStarts[id] = unit
      if mod:GetSetting("BombLines") then
        core:AddLineBetweenUnits(string.format("JUMP_START_LINE %d", id), playerUnit:GetId(), id, 5)
      end
    end,
    [core.E.UNIT_DESTROYED] = function (_, id)
      jumpStarts[id] = nil
      if mod:GetSetting("BombLines") then
        core:RemoveLineBetweenUnits(string.format("JUMP_START_LINE %d", id))
      end
    end,
  }
)
