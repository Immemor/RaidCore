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
    ["Chief Warden Lockjaw"] = "Chief Warden Lockjaw",
    ["Hostile Invisible Unit for Fields (0 hit radius)"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    ["Blaze Shackle"] = "Blaze Shackle",
    ["Blaze Shackles"] = "Blaze Shackles",
  })
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CrosshairTethers")
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()

end

mod:RegisterUnitEvents("Chief Warden Lockjaw",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
    end,
  }
)

mod:RegisterUnitEvents("Blaze Shackle",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      if mod:GetSetting("CrosshairTethers") then
        core:AddPicture(nId, nId, "Crosshair", 25)
      end
    end,
    ["OnUnitDestroyed"] = function (self, nId, tUnit, sName)
      core:RemovePicture(nId)
    end,
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Blaze Shackles"] == sCastName then
        mod:AddMsg("CIRCLES", "DODGE CIRCLES", 5, "Info")
      end
    end,
  }
)
