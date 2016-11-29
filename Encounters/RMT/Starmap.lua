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
local mod = core:NewEncounter("Starmap", 104, 548, 556)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, {
    "unit.alpha",
    "unit.aldinari",
    "unit.cassus",
    "unit.vulpes_nix",
  }
)
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.alpha"] = "Alpha Cassus",
    ["unit.aldinari"] = "Aldinari",
    ["unit.cassus"] = "Cassus",
    ["unit.vulpes_nix"] = "Vulpes Nix",

    ["unit.asteroid"] = "Rogue Asteroid",
    ["unit.debris"] = "Cosmic Debris",
    ["unit.debris_field"] = "Debris Field",
    ["unit.pulsar"] = "Pulsar",
    ["unit.world_ender"] = "World Ender",
    -- Cast names.
    ["cast.alpha.flare"] = "Solar Flare",
    -- Datachron.
    ["chron.world_ender.aldinari"] = "A World Ender is heading to the Aldinari's orbit.",
    ["chron.world_ender.vulpes_nix"] = "A World Ender is heading to the Vulpes Nix's orbit.",
    -- Messages.
    ["msg.asteroid.next"] = "Asteroids in",
    ["msg.world_ender.next"] = "World Ender in",
    ["msg.solar.stacks"] = "%d STACKS",
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  SOLAR_WINDS = 87536,
  IRRADIATED_ARMOR = 84305,
  ACCUMULATING_MASS = 84344,
  PULSAR = 87542,
  BURNING_ATMOSPHERE = 84301,
}

local TIMERS = {
  WORLD_ENDER = {
    FIRST = 52,
    NORMAL = 78,
  },
  ASTEROIDS = {
    NORMAL = 26,
    NEXT_IS_WORLD_ENDER = 52,
  },
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local asteroidCount
local asteroidClusterCount
local playerId
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  asteroidCount = 0
  asteroidClusterCount = 0
  playerId = GameLib.GetPlayerUnit():GetId()
  mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", TIMERS.ASTEROIDS.NORMAL)
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.FIRST)
end

function mod:OnAlphaCassusCreated(id, unit)
  core:AddUnit(unit)
  core:WatchUnit(unit, core.E.TRACK_ALL)
end

function mod:OnAsteroidCreated(id, unit)
  core:AddLineBetweenUnits("ASTEROID_LINE_%s" .. id, playerId, id, 4, "Blue")
  asteroidCount = asteroidCount + 1
  if asteroidCount >= 4 then
    asteroidCount = 0
    asteroidClusterCount = asteroidClusterCount + 1
  end
  local timer = TIMERS.ASTEROIDS.NORMAL
  if asteroidClusterCount >= 2 then
    asteroidClusterCount = 0
    timer = TIMERS.ASTEROIDS.NEXT_IS_WORLD_ENDER
  end
  mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", timer)
end

function mod:OnAsteroidDestroyed(id, _)
  core:RemoveLineBetweenUnits("ASTEROID_LINE_%s" .. id)
end

function mod:OnWorldEnderCreated(id, unit)
  core:AddUnit(unit)
  asteroidClusterCount = 0
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.NORMAL)
  core:AddLineBetweenUnits("WORLD_ENDER_%s" .. id, playerId, id, 6, "Red")
end

function mod:OnWorldEnderDestroyed(id, unit)
  asteroidCount = asteroidCount - 1
  core:RemoveLineBetweenUnits("WORLD_ENDER_%s" .. id)
end

function mod:OnDebrisCreated(id, unit)
  core:AddPicture("DEBRIS_PICTURE_" .. id, id, "Crosshair", 40, nil, nil, nil, "red")
end

function mod:OnDebrisDestroyed(id, unit)
  core:RemovePicture("DEBRIS_PICTURE_" .. id)
end

mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [DEBUFFS.SOLAR_WINDS] = {
      [core.E.DEBUFF_UPDATE] = function(self, id, _, stack)
        if playerId == id and stack == 6 then
          mod:AddMsg("SOLAR_WINDS_MSG", string.format(self.L["msg.solar.stacks"], stack), 5, "Beware", "xkcdBloodOrange")
        end
      end
    },
  }
)

mod:RegisterUnitEvents("unit.alpha",{
    [core.E.UNIT_CREATED] = mod.OnAlphaCassusCreated,
  }
)
mod:RegisterUnitEvents("unit.asteroid",{
    [core.E.UNIT_CREATED] = mod.OnAsteroidCreated,
    [core.E.UNIT_DESTROYED] = mod.OnAsteroidDestroyed,
  }
)
mod:RegisterUnitEvents("unit.world_ender",{
    [core.E.UNIT_CREATED] = mod.OnWorldEnderCreated,
  }
)
mod:RegisterUnitEvents("unit.debris",{
    [core.E.UNIT_CREATED] = mod.OnDebrisCreated,
    [core.E.UNIT_DESTROYED] = mod.OnDebrisDestroyed,
  }
)
