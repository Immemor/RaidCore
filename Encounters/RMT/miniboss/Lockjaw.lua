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
local mod = core:NewEncounter("Lockjaw", 104, 548, 550)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Chief Warden Lockjaw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Chief Warden Lockjaw"] = "Chief Warden Lockjaw",
    ["Hostile Invisible Unit for Fields (0 hit radius)"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    ["Blaze Shackle"] = "Blaze Shackle",
    -- Cast names.
    ["Blaze Shackles"] = "Blaze Shackles",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CrosshairTethers")
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("Chief Warden Lockjaw",{
    ["OnUnitCreated"] = function (self, id, unit, name)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
    ["OnCastStart"] = function (self, id, castName, castEndTime, name)
      if self.L["Blaze Shackles"] == castName then
        mod:AddMsg("CIRCLES", "DODGE CIRCLES", 5, "Info")
      end
    end,
  }
)

mod:RegisterUnitEvents("Blaze Shackle",{
    ["OnUnitCreated"] = function (self, id, unit, name)
      if mod:GetSetting("CrosshairTethers") then
        core:AddPicture(id, id, "Crosshair", 25)
      end
    end,
    ["OnUnitDestroyed"] = function (self, id, unit, name)
      core:RemovePicture(id)
    end,
  }
)
