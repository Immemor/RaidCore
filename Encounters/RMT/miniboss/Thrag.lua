----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- TODO
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Thrag", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.thrag" })
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
-- Locals.
----------------------------------------------------------------------------------------------------
local playerUnit

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
end

function mod:OnThragCreated(id, unit, name)
  core:AddUnit(unit)
end

function mod:OnJumpstartCreated(id, unit, name)
  if mod:GetSetting("BombLines") then
    core:AddLineBetweenUnits("JUMP_START_LINE_"..id, playerUnit, unit, 5)
  end
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.thrag",{
    [core.E.UNIT_CREATED] = mod.OnThragCreated,
  }
)
mod:RegisterUnitEvents("unit.jumpstart",{
    [core.E.UNIT_CREATED] = mod.OnJumpstartCreated,
  }
)
