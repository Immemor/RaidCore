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
    ["msg.mid_phase.soon"] = "Mid phase soon",
    -- Markers.
    ["mark.cardinal.N"] = "N",
    ["mark.cardinal.S"] = "S",
    ["mark.cardinal.E"] = "E",
    ["mark.cardinal.W"] = "W",
    ["mark.world_ender.1"] = "W1",
    ["mark.world_ender.2"] = "W2",
    ["mark.world_ender.3"] = "W3",
    ["mark.world_ender.4"] = "W4",
    ["mark.world_ender.5"] = "W5",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("IndicatorPlanets")
mod:RegisterDefaultSetting("IndicatorAsteroids")
mod:RegisterDefaultSetting("MarkCardinal")
mod:RegisterDefaultSetting("MarkWorldenderSpawn")
-- Sounds.
mod:RegisterDefaultSetting("CountdownWorldender")
mod:RegisterDefaultSetting("SoundWorldenderSpawn")
mod:RegisterDefaultSetting("SoundMidphaseSoon")
mod:RegisterDefaultSetting("SoundSolarWindStacksWarning")
-- Messages.
mod:RegisterDefaultSetting("MessageWorldenderSpawn")
mod:RegisterDefaultSetting("MessageMidphaseSoon")
mod:RegisterDefaultSetting("MessageSolarWindStacksWarning")
-- Binds.
mod:RegisterMessageSetting("WORLD_ENDER_SPAWN_MSG", core.E.COMPARE_EQUAL, "MessageWorldenderSpawn", "SoundWorldenderSpawn")
mod:RegisterMessageSetting("MID_PHASE", core.E.COMPARE_EQUAL, "MessageMidphaseSoon", "SoundMidphaseSoon")
mod:RegisterMessageSetting("SOLAR_WINDS_MSG", core.E.COMPARE_EQUAL, "MessageSolarWindStacksWarning", "SoundSolarWindStacksWarning")

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

local ENDER_SPAWN_MARKERS = {
  [1] = Vector3.New(-159.57, -95.93, 346.34),
  [2] = Vector3.New(-149.60, -96.06, 315.52),
  [3] = Vector3.New(-43.89, -95.98, 279.71),
  [4] = Vector3.New(-157.29, -95.91, 363.64),
  [5] = Vector3.New(-19.37, -95.79, 414.22),
}

local PHASES_CLOSE = {
  {UPPER = 76.5, LOWER = 75.5},
  {UPPER = 46.5, LOWER = 45.5},
  {UPPER = 13.5, LOWER = 12.5},
}

local CARDINAL_MARKERS = {
  ["N"] = Vector3.New(-76.75, -96.21, 309.26),
  ["S"] = Vector3.New(-76.55, -96.21, 405.18),
  ["E"] = Vector3.New(-30.00, -96.22, 357.03),
  ["W"] = Vector3.New(-124.81, -96.21, 356.96),
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
local worldEnderCount
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  asteroidCount = 0
  asteroidClusterCount = 0
  solarWindsStack = 0
  worldEnderCount = 1
  planets = {}
  alphaCassus = nil
  for locale, planet in next, PLANETS do
    PLANETS[self.L[locale]] = planet
  end
  playerId = GameLib.GetPlayerUnit():GetId()
  --mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", TIMERS.ASTEROIDS.NORMAL)
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.FIRST, mod:GetSetting("CountdownWorldender"))
  mod:SetCardinalMarkers()
  if mod:GetSetting("MarkWorldenderSpawn") then
    mod:SetWorldMarker("WORLD_ENDER_MARKER_"..worldEnderCount, "mark.world_ender."..worldEnderCount, ENDER_SPAWN_MARKERS[worldEnderCount], "xkcdCyan")
  end
end

function mod:SetCardinalMarkers()
  if not mod:GetSetting("MarkCardinal") then
    return
  end
  for direction, location in next, CARDINAL_MARKERS do
    mod:SetWorldMarker("CARDINAL_"..direction, "mark.cardinal."..direction, location)
  end
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
  if mod:GetSetting("IndicatorPlanets") then
    core:AddLineBetweenUnits(planet.id, alphaCassus.id, planet.id, 10, planet.indicatorColor, nil, 8, 3.5)
  end
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

function mod:OnAlphaCassusHealthChanged(_, _, percent)
  for i = 1, #PHASES_CLOSE do
    if percent >= PHASES_CLOSE[i].LOWER and percent <= PHASES_CLOSE[i].UPPER then
      mod:AddMsg("MID_PHASE", "msg.mid_phase.soon", 5, "Info", "xkcdWhite")
      break
    end
  end
end

function mod:OnAlphaCassusDestroyed(id, unit)
  core:RemoveSimpleLine(id)
  alphaCassus = nil
end

function mod:OnAsteroidCreated(id, unit)
  if mod:GetSetting("IndicatorAsteroids") then
    core:AddLineBetweenUnits("ASTEROID_LINE_" .. id, playerId, id, 3, "xkcdOrange", nil, nil, 8)
  end
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
  --mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", timer)
end

function mod:OnAsteroidDestroyed(id, _)
  core:RemoveLineBetweenUnits("ASTEROID_LINE_" .. id)
end

function mod:OnWorldEnderCreated(id, unit)
  core:AddUnit(unit)
  asteroidClusterCount = 0
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.NORMAL, mod:GetSetting("CountdownWorldender"))
  core:AddLineBetweenUnits("WORLD_ENDER_" .. id, playerId, id, 6, "xkcdCyan")
  mod:AddMsg("WORLD_ENDER_SPAWN_MSG", "msg.word_ender_spawn", 5, "Beware", "xkcdCyan")
end

function mod:OnWorldEnderDestroyed(id, unit)
  asteroidCount = asteroidCount - 3
  core:RemoveLineBetweenUnits("WORLD_ENDER_" .. id)
  mod:DropWorldMarker("WORLD_ENDER_MARKER_" .. worldEnderCount)
  worldEnderCount = worldEnderCount + 1

  if mod:GetSetting("MarkWorldenderSpawn") then
    mod:SetWorldMarker("WORLD_ENDER_MARKER_"..worldEnderCount, "mark.world_ender."..worldEnderCount, ENDER_SPAWN_MARKERS[worldEnderCount], "xkcdCyan")
  end
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
    [core.E.HEALTH_CHANGED] = mod.OnAlphaCassusHealthChanged,
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
