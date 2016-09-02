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

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local jumpStarts

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()

end

mod:RegisterUnitEvents("Chief Engine Scrubber Thrag",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
    end,
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Gigavolt"] == sCastName then
        mod:AddMsg("GIGAVOLT", "GET OUT", 5, "RunAway")
      end
    end,
  }
)

mod:RegisterUnitEvents("Jumpstart Charge",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      jumpStarts[nId] = tUnit
      --core:WatchUnit(tUnit)
      core:AddLineBetweenUnits(string.format("JUMP_START_LINE %d", nId), playerUnit:GetId(), nId, 5)
    end,
    ["OnUnitDestroyed"] = function (self, nId, tUnit, sName)
      jumpStarts[nId] = nil
      core:RemoveLineBetweenUnits(string.format("JUMP_START_LINE %d", nId))
    end,
  }
)
