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
    ["chron.world_ender.cassus"] = "A World Ender is heading to the Cassus' orbit.",
    -- Messages.
    ["msg.asteroid.next"] = "Asteroids in",
    ["msg.world_ender.next"] = "World Ender in",
    ["msg.solar_winds.high_stacks"] = "HIGH SOLAR STACKS",
    ["msg.world_ender.spawned"] = "World Ender Spawned",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_WORLD_ENDER_TIMER"] = { sColor = "xkcdCyan" },
    ["NEXT_ASTEROID_TIMER"] = { sColor = "xkcdOrange" },
  }
)
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local next = next
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

local PLANETS = {
  ["unit.aldinari"] = {
    INDICATOR_COLOR = "xkcdPurple",
  },
  ["unit.cassus"] = {
    INDICATOR_COLOR = "xkcdCyan",
  },
  ["unit.vulpes_nix"] = {
    INDICATOR_COLOR = "xkcdBrown",
  }
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local asteroidCount
local asteroidClusterCount
local playerId
local solarWindsStack
local planets
local alphaCassus
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  asteroidCount = 0
  asteroidClusterCount = 0
  solarWindsStack = 0
  planets = {}
  alphaCassus = nil
  for locale, planet in next, PLANETS do
    PLANETS[self.L[locale]] = planet
  end
  playerId = GameLib.GetPlayerUnit():GetId()
  mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", TIMERS.ASTEROIDS.NORMAL)
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.FIRST)
end

function mod:OnPlanetCreated(id, unit, name)
  planets[id] = {
    id = id,
    unit = unit,
    indicatorColor = PLANETS[name].INDICATOR_COLOR,
  }
  if alphaCassus then
    mod:DrawPlanetTankIndicator(planets[id])
  end
end

function mod:OnPlanetDestroyed(id, unit)
  planets[id] = nil
  core:RemoveLineBetweenUnits(id)
end

function mod:DrawPlanetTankIndicator(planet)
  core:AddLineBetweenUnits(planet.id, alphaCassus.id, planet.id, 10, planet.indicatorColor, nil, 8, 3.5)
end

function mod:DrawPlanetTankIndicators()
  for id, planet in next, planets do
    mod:DrawPlanetTankIndicator(planet)
  end
end

function mod:OnAlphaCassusCreated(id, unit)
  alphaCassus = {
    id = id,
    unit = unit,
  }
  core:AddUnit(unit)
  core:WatchUnit(unit, core.E.TRACK_ALL)
  mod:DrawPlanetTankIndicators()
  core:AddSimpleLine(id, unit, 8, 3.5, nil, 10, "xkcdRed")
end

function mod:OnAlphaCassusDestroyed(id, unit)
  core:RemoveSimpleLine(id)
  alphaCassus = nil
end

function mod:OnAsteroidCreated(id, unit)
  core:AddLineBetweenUnits("ASTEROID_LINE_" .. id, playerId, id, 3, "xkcdOrange", nil, nil, 8)
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
  core:RemoveLineBetweenUnits("ASTEROID_LINE_" .. id)
end

function mod:OnWorldEnderCreated(id, unit)
  core:AddUnit(unit)
  asteroidClusterCount = 0
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.NORMAL, true)
  core:AddLineBetweenUnits("WORLD_ENDER_" .. id, playerId, id, 6, "xkcdCyan")
  mod:AddMsg("WORLD_ENDER_SPAWN_MSG", "msg.word_ender_spawn", 5, "Beware", "xkcdCyan")
end

function mod:OnWorldEnderDestroyed(id, unit)
  asteroidCount = asteroidCount - 3
  core:RemoveLineBetweenUnits("WORLD_ENDER_" .. id)
end

function mod:OnDebrisCreated(id, unit)
  core:AddPicture("DEBRIS_PICTURE_" .. id, id, "Crosshair", 40, nil, nil, nil, "red")
end

function mod:OnDebrisDestroyed(id, unit)
  core:RemovePicture("DEBRIS_PICTURE_" .. id)
end

function mod:OnSolarWindsUpdated(id, _, stack)
  if playerId == id then
    if stack == 5 and solarWindsStack < stack then
      mod:AddMsg("SOLAR_WINDS_MSG", "msg.solar_winds.high_stacks", 5, "Beware", "white")
    end
    solarWindsStack = stack
  end
end

mod:RegisterUnitEvents("unit.alpha",{
    [core.E.UNIT_CREATED] = mod.OnAlphaCassusCreated,
    [core.E.UNIT_DESTROYED] = mod.OnAlphaCassusDestroyed,
  }
)
mod:RegisterUnitEvents("unit.asteroid",{
    [core.E.UNIT_CREATED] = mod.OnAsteroidCreated,
    [core.E.UNIT_DESTROYED] = mod.OnAsteroidDestroyed,
  }
)
mod:RegisterUnitEvents("unit.world_ender",{
    [core.E.UNIT_CREATED] = mod.OnWorldEnderCreated,
    [core.E.UNIT_DESTROYED] = mod.OnWorldEnderDestroyed,
  }
)
mod:RegisterUnitEvents("unit.debris",{
    [core.E.UNIT_CREATED] = mod.OnDebrisCreated,
    [core.E.UNIT_DESTROYED] = mod.OnDebrisDestroyed,
  }
)
mod:RegisterUnitEvents(core.E.ALL_UNITS,{
    [DEBUFFS.SOLAR_WINDS] = {
      [core.E.DEBUFF_UPDATE] = mod.OnSolarWindsUpdated,
    }
  }
)
mod:RegisterUnitEvents({
    "unit.aldinari",
    "unit.cassus",
    "unit.vulpes_nix",
    },{
    [core.E.UNIT_CREATED] = mod.OnPlanetCreated,
    [core.E.UNIT_DESTROYED] = mod.OnPlanetDestroyed,
  }
)
