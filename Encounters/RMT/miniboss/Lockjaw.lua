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
mod:RegisterTrigMob("ALL", { "unit.lockjaw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.lockjaw"] = "Chief Warden Lockjaw",
    ["unit.shackle"] = "Blaze Shackle",
    -- Cast names.
    ["cast.lockjaw.shackle"] = "Blaze Shackles",
    -- Messages.
    ["msg.lockjaw.shackle.dodge"] = "DODGE CIRCLES",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CrosshairTethers")
mod:RegisterDefaultSetting("SoundShackles")
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.lockjaw",{
    ["OnUnitCreated"] = function (_, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS)
    end,
    ["OnCastStart"] = function (self, _, castName)
      if self.L["cast.lockjaw.shackle"] == castName then
        mod:AddMsg("CIRCLES", self.L["msg.lockjaw.shackle.dodge"], 5, mod:GetSetting("SoundShackles") == true and "Info")
      end
    end,
  }
)

mod:RegisterUnitEvents("unit.shackle",{
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
