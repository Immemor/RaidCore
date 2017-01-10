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
local mod = core:NewEncounter("Laveka", 104, 548, 559)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.laveka" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.laveka"] = "Laveka the Dark-Hearted",
    ["unit.phantom"] = "Phantom",
    ["unit.essence_void"] = "Essence Void",
    ["unit.tortued_apparition"] = "Tortured Apparition",
    ["unit.orb"] = "Soul Eater",
    ["unit.boneclaw"] = "Risen Boneclaw",
    ["unit.titan"] = "Risen Titan",
    -- Cast names.
    -- Messages.
    ["msg.laveka.soulfire.you"] = "SOULFIRE ON YOU",
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  EXPULSION_OF_SOULS = 87901, -- Runic circle debuff
  NECROTIC_EXPLOSION = 75610,
  SOUL_EATER = 87069,
  REALM_OF_THE_DEAD = 75528, -- When in dead world
  ECHOES_OF_THE_AFTERLIFE = 75525, -- stacking debuff
  SOULFIRE = 75574, -- Debuff to be cleansed
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local player
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    player = {}
    player.unit = GameLib.GetPlayerUnit()
end

function mod:OnAnyUnitDestroyed(id, unit, name)
  core:RemoveLineBetweenUnits("SOULFIRE_LINE_"..id)
end

function mod:OnWatchedUnitCreated(id, unit, name)
  core:AddUnit(unit)
  core:WatchUnit(unit, core.E.TRACK_ALL)
end

function mod:OnSoulfireAdd(id, spellId, stack, timeRemaining, targetName)
  if id ~= player.unit:GetId() then
    core:AddLineBetweenUnits("SOULFIRE_LINE_"..id, player.unit, id, 8)
  else
    mod:AddMsg("SOULFIRE_MSG_YOU", "msg.laveka.soulfire.you", 5, "Burn", "xkcdGreen")
  end
end

function mod:OnSoulfireRemove(id, spellId, targetName)
  if id ~= player.unit:GetId() then
    core:RemoveLineBetweenUnits("SOULFIRE_LINE_"..id)
  end
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents({
    "unit.laveka",
    "unit.titan",
    },{
    [core.E.UNIT_CREATED] = mod.OnWatchedUnitCreated,
  }
)

mod:RegisterUnitEvents(core.E.ALL_UNITS,{
    [core.E.UNIT_DESTROYED] = mod.OnAnyUnitDestroyed,
    [DEBUFFS.SOULFIRE] = {
      [core.E.DEBUFF_ADD] = mod.OnSoulfireAdd,
      [core.E.DEBUFF_REMOVE] = mod.OnSoulfireRemove,
    }
  }
)
