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
local mod = core:NewEncounter("Skooty", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.skooty" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.skooty"] = "Assistant Technician Skooty",
    ["unit.jumpstart"] = "Jumpstart Charge",
    -- Cast names.
    ["cast.skooty.cannon"] = "Pulse Cannon",
    -- Messages.
    ["msg.skooty.cannon.get_out"] = "GET OUT",
    ["msg.skooty.cannon.get_out_tank"] = "TANK GET OUT",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.jumpstart"] = "Starthilfe-Ladung",
    ["unit.tether"] = "Befestigungshaken",
    -- Cast names.
    ["cast.skooty.cannon"] = "Impulskanone",
    -- Buffs.
    ["buff.impulse"] = "Impulskanone",
    ["buff.tether"] = "Alle Schotten dicht!",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.jumpstart"] = "Charge de démarrage",
    ["unit.tether"] = "Crochet de verrouillage",
    -- Cast names.
    ["cast.skooty.cannon"] = "Canon à impulsions",
    -- Buffs.
    ["buff.impulse"] = "Canon à impulsions",
    ["buff.tether"] = "Se préparer au pire",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("BombLines", false)
-- Sounds.
mod:RegisterDefaultSetting("SoundPulseCannon")
mod:RegisterDefaultSetting("SoundPulseCannonTank")
-- Messages.
mod:RegisterDefaultSetting("MessagePulseCannon")
mod:RegisterDefaultSetting("MessagePulseCannonTank")
-- Binds.
mod:RegisterMessageSetting("PULSECANNON", core.E.COMPARE_EQUAL, "MessagePulseCannon", "SoundPulseCannon")
mod:RegisterMessageSetting("PULSECANNON_TANK", core.E.COMPARE_EQUAL, "MessagePulseCannonTank", "SoundPulseCannonTank")
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

function mod:OnSkootyCreated(id, unit, name)
  skootyUnit = unit
  core:AddUnit(unit)
  core:WatchUnit(unit, core.E.TRACK_CASTS)
end

function mod:OnSkootyDestroyed(id, unit, name)
  skootyUnit = nil
end

function mod:OnSkootyCannonStart()
  local target = skootyUnit and skootyUnit:GetTarget()
  if target and target:IsThePlayer() then
    mod:AddMsg("PULSECANNON", "msg.skooty.cannon.get_out", 5, "RunAway")
  else
    mod:AddMsg("PULSECANNON_TANK", "msg.skooty.cannon.get_out_tank", 5, "Info", "xkcdWhite")
  end
end

function mod:OnJumpstartCreated(id, unit, name)
  if mod:GetSetting("BombLines") then
    core:AddLineBetweenUnits("JUMP_START_LINE_"..id, playerUnit, unit, 5)
  end
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.jumpstart",{
    [core.E.UNIT_CREATED] = mod.OnJumpstartCreated,
  }
)
mod:RegisterUnitEvents("unit.skooty",{
    [core.E.UNIT_CREATED] = mod.OnSkootyCreated,
    [core.E.UNIT_DESTROYED] = mod.OnSkootyDestroyed,
    [core.E.CAST_START] = {
      ["cast.skooty.cannon"] = mod.OnSkootyCannonStart,
    }
  }
)
