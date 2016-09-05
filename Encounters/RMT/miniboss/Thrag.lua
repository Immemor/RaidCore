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
mod:RegisterTrigMob("ALL", { "Chief Engine Scrubber Thrag" })
mod:RegisterEnglishLocale({
    ["Chief Engine Scrubber Thrag"] = "Chief Engine Scrubber Thrag",
    ["Hostile Invisible Unit for Fields (0 hit radius)"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    ["Gigavolt"] = "Gigavolt",
    ["Jumpstart Charge"] = "Jumpstart Charge",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("Gigavolt")
mod:RegisterDefaultSetting("BombLines")
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
end

mod:RegisterUnitEvents("Chief Engine Scrubber Thrag",{
    ["OnUnitCreated"] = function (self, id, unit, name)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
    ["OnCastStart"] = function (self, id, castName, castEndTime, name)
      if self.L["Gigavolt"] == castName then
        mod:AddMsg("GIGAVOLT", "GET OUT", 5, mod:GetSetting("Gigavolt") == true and "RunAway")
      end
    end,
  }
)

mod:RegisterUnitEvents("Jumpstart Charge",{
    ["OnUnitCreated"] = function (self, id, unit, name)
      jumpStarts[id] = unit
      core:WatchUnit(unit)
      if mod:GetSetting("BombLines") then
        core:AddLineBetweenUnits(string.format("JUMP_START_LINE %d", id), playerUnit:GetId(), id, 5)
      end
    end,
    ["OnUnitDestroyed"] = function (self, id, unit, name)
      jumpStarts[id] = nil
      if mod:GetSetting("BombLines") then
        core:RemoveLineBetweenUnits(string.format("JUMP_START_LINE %d", id))
      end
    end,
  }
)
