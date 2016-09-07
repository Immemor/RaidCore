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
    ["cast.gigavolt"] = "Gigavolt",
    -- Messages.
    ["msg.gigavolt.get_out"] = "GET OUT",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("Gigavolt", false)
mod:RegisterDefaultSetting("BombLines", false)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

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

mod:RegisterUnitEvents("unit.thrag",{
    ["OnUnitCreated"] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
    ["OnCastStart"] = function (_, _, _)
      -- TODO: Redo
      -- if self.L["cast.gigavolt"] == castName then
      --   mod:AddMsg("GIGAVOLT", self.L["msg.gigavolt.get_out"], 5, mod:GetSetting("Gigavolt") == true and "RunAway")
      -- end
    end,
  }
)

mod:RegisterUnitEvents("unit.jumpstart",{
    ["OnUnitCreated"] = function (_, id, unit)
      jumpStarts[id] = unit
      core:WatchUnit(unit)
      if mod:GetSetting("BombLines") then
        core:AddLineBetweenUnits(string.format("JUMP_START_LINE %d", id), playerUnit:GetId(), id, 5)
      end
    end,
    ["OnUnitDestroyed"] = function (_, id)
      jumpStarts[id] = nil
      if mod:GetSetting("BombLines") then
        core:RemoveLineBetweenUnits(string.format("JUMP_START_LINE %d", id))
      end
    end,
  }
)
