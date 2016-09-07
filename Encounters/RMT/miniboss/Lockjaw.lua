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
mod:RegisterDefaultSetting("SoundShackles")
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("Chief Warden Lockjaw",{
    ["OnUnitCreated"] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
    ["OnCastStart"] = function (self, _, castName)
      if self.L["Blaze Shackles"] == castName then
        mod:AddMsg("CIRCLES", "DODGE CIRCLES", 5, mod:GetSetting("SoundShackles") == true and "Info")
      end
    end,
  }
)

mod:RegisterUnitEvents("Blaze Shackle",{
    ["OnUnitCreated"] = function (_, id)
      if mod:GetSetting("CrosshairTethers") then
        core:AddPicture(id, id, "Crosshair", 25)
      end
    end,
    ["OnUnitDestroyed"] = function (_, id)
      core:RemovePicture(id)
    end,
  }
)
