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
-- Visuals.
mod:RegisterDefaultSetting("BombLines", false)
-- Sounds.
mod:RegisterDefaultSetting("SoundPulseCannon")
-- Messages.
mod:RegisterDefaultSetting("MessagePulseCannon")
-- Binds.
mod:RegisterMessageSetting("PULSECANNON", "EQUAL", "MessagePulseCannon", "SoundPulseCannon")
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local playerUnit
local skootyUnit
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
end

mod:RegisterUnitEvents("unit.skooty",{
    [core.E.UNIT_CREATED] = function (self, id, unit)
      skootyUnit = unit
      core:AddUnit(unit)
      core:WatchUnit(unit, core.E.TRACK_CASTS)
    end,
    [core.E.UNIT_DESTROYED] = function ()
      skootyUnit = nil
    end,
    [core.E.CAST_START] = {
      ["cast.skooty.cannon"] = function (self, id, castName)
        local target = skootyUnit and skootyUnit:GetTarget()
        if target and target:IsThePlayer() then
          mod:AddMsg("PULSECANNON", self.L["msg.skooty.cannon.get_out"], 5, "RunAway")
        end
      end,
    }
  }
)

mod:RegisterUnitEvents("unit.jumpstart",{
    [core.E.UNIT_CREATED] = function (self, id, unit)
      if mod:GetSetting("BombLines") then
        core:AddLineBetweenUnits("JUMP_START_LINE_%d"..id, playerUnit:GetId(), id, 5)
      end
    end,
    [core.E.UNIT_DESTROYED] = function (self, id, unit)
      if mod:GetSetting("BombLines") then
        core:RemoveLineBetweenUnits("JUMP_START_LINE_%d"..id)
      end
    end,
  }
)
