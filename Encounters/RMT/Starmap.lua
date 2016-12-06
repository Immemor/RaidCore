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
    ["chron.critical_mass"] = "([^%s]+%s[^%s]+) has reached Critical Mass!",
    -- Messages.
    ["msg.asteroid.next"] = "Asteroids in",
    ["msg.world_ender.next"] = "World Ender in",
    ["msg.solar_winds.high_stacks"] = "HIGH SOLAR STACKS",
    ["msg.critical_mass.you"] = "CRITICAL MASS",
    ["msg.world_ender.spawned"] = "World Ender Spawned",
    ["msg.mid_phase.soon"] = "Mid phase soon",
    -- Markers.
    ["mark.cardinal.N"] = "N",
    ["mark.cardinal.S"] = "S",
    ["mark.cardinal.E"] = "E",
    ["mark.cardinal.W"] = "W",
    ["mark.world_ender.spawn_location"] = "W%d",
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
mod:RegisterDefaultSetting("LineWorldender")
mod:RegisterDefaultSetting("LineAsteroids")
mod:RegisterDefaultSetting("LineAlphaCassusCleave")
mod:RegisterDefaultSetting("CirclePlanetOrbits")
mod:RegisterDefaultSetting("CirclePermanentPlanetOrbits", false)
mod:RegisterDefaultSetting("MarkDebrisField")
mod:RegisterDefaultSetting("MarkSolarWindTimer")
mod:RegisterDefaultSetting("CrosshairCosmicDebris")
-- Sounds.
mod:RegisterDefaultSetting("CountdownWorldender")
mod:RegisterDefaultSetting("SoundWorldenderSpawn")
mod:RegisterDefaultSetting("SoundMidphaseSoon")
mod:RegisterDefaultSetting("SoundSolarWindStacksWarning")
mod:RegisterDefaultSetting("SoundCriticalMassYouWarning")
-- Messages.
mod:RegisterDefaultSetting("MessageWorldenderSpawn")
mod:RegisterDefaultSetting("MessageMidphaseSoon")
mod:RegisterDefaultSetting("MessageSolarWindStacksWarning")
mod:RegisterDefaultSetting("MessageCriticalMassYouWarning")
-- Binds.
mod:RegisterMessageSetting("WORLD_ENDER_SPAWN_MSG", core.E.COMPARE_EQUAL, "MessageWorldenderSpawn", "SoundWorldenderSpawn")
mod:RegisterMessageSetting("MID_PHASE", core.E.COMPARE_EQUAL, "MessageMidphaseSoon", "SoundMidphaseSoon")
mod:RegisterMessageSetting("SOLAR_WINDS_MSG", core.E.COMPARE_EQUAL, "MessageSolarWindStacksWarning", "SoundSolarWindStacksWarning")
mod:RegisterMessageSetting("CRITICAL_MASS_MSG", core.E.COMPARE_EQUAL, "MessageCriticalMassYouWarning", "SoundCriticalMassYouWarning")

mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_WORLD_ENDER_TIMER"] = { sColor = "xkcdCyan" },
    ["NEXT_ASTEROID_TIMER"] = { sColor = "xkcdOrange" },
  }
)
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local next = next
local GetTickCount = GameLib.GetTickCount
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  SOLAR_WINDS = 87536,
  IRRADIATED_ARMOR = 84305,
  ACCUMULATING_MASS = 84344,
  PULSAR = 87542,
  BURNING_ATMOSPHERE = 84301,
  CRITICAL_MASS = 84345,
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
  SOLAR_WIND = {
    UPDATE = 0.1,
    INTERVAL = 4,
  }
}

local PLANETS = {
  ["unit.aldinari"] = {
    INDICATOR_COLOR = "xkcdPurple",
    ORBIT = {LOWER = 16, UPPER = 23}
  },
  ["unit.cassus"] = {
    INDICATOR_COLOR = "xkcdCyan",
    ORBIT = {LOWER = 36, UPPER = 44}
  },
  ["unit.vulpes_nix"] = {
    INDICATOR_COLOR = "xkcdBrown",
    ORBIT = {LOWER = 53, UPPER = 65}
  }
}
local tempPlanets = PLANETS
PLANETS = {}
for locale, planet in next, tempPlanets do
  PLANETS[mod.L[locale]] = planet
end

local ALPHA_CASSUS_POSITION = Vector3.New(-76.779495239258, -95, 356.81430053711)
local PHASES_CLOSE = {
  {UPPER = 76.5, LOWER = 75.5},
  {UPPER = 46.5, LOWER = 45.5},
  {UPPER = 13.5, LOWER = 12.5},
}

--From LUI-BossMods
local ENDER_SPAWN_MARKERS = {
  Vector3.New(-159.57, -95.93, 346.34),
  Vector3.New(-149.60, -96.06, 315.52),
  Vector3.New(-43.89, -95.98, 279.71),
  Vector3.New(-157.29, -95.91, 363.64),
  Vector3.New(-19.37, -95.79, 414.22),
}
local CARDINAL_MARKERS = {
  ["N"] = Vector3.New(-76.75, -96.21, 309.26),
  ["S"] = Vector3.New(-76.55, -96.21, 405.18),
  ["E"] = Vector3.New(-30.00, -96.22, 357.03),
  ["W"] = Vector3.New(-124.81, -96.21, 356.96),
}
local CLEAVE_COLORS = {
  [0] = "xkcdGreen",
  [1] = "xkcdRed",
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local playerId
local solarWindsStack
local solarWindStartTick
local solarWindTimer = ApolloTimer.Create(TIMERS.SOLAR_WIND.UPDATE, true, "OnUpdateSolarWindTimer", mod)
solarWindTimer:Stop()
local planets
local alphaCassus
local worldEnderCount
local lastWorldEnder
local worldEnders
local solarFlareCount
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  lastWorldEnder = nil
  solarWindsStack = 0
  worldEnderCount = 0
  solarWindStartTick = 0
  worldEnders = {}
  planets = {}
  alphaCassus = nil
  solarFlareCount = 0
  playerId = GameLib.GetPlayerUnit():GetId()
  mod:StartSecondAsteroidTimer()
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.FIRST, mod:GetSetting("CountdownWorldender"))
  mod:SetCardinalMarkers()
  mod:DrawWorldEnderMarkers()
  core:AddUnitSpacer("WORLD_ENDER_SPACE", nil, 2)
  if mod:GetSetting("CirclePermanentPlanetOrbits") then
    mod:DrawPlanetOrbits()
  end
end

function mod:OnBossDisable()
  solarWindTimer:Stop()
end

function mod:DrawWorldEnderMarkers()
  if not mod:GetSetting("MarkWorldenderSpawn") then return end
  for i = 1, #ENDER_SPAWN_MARKERS do
    local msg = self.L["mark.world_ender.spawn_location"]:format(i)
    mod:SetWorldMarker("WORLD_ENDER_MARKER_"..i, msg, ENDER_SPAWN_MARKERS[i], "xkcdCyan")
  end
end

function mod:StartAsteroidTimer()
  mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", TIMERS.ASTEROIDS.NORMAL, nil, nil, mod.StartSecondAsteroidTimer, mod)
end

function mod:StartSecondAsteroidTimer()
  mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", TIMERS.ASTEROIDS.NORMAL, nil, nil, mod.StartThirdAsteroidTimer, mod)
end

function mod:StartThirdAsteroidTimer()
  mod:AddTimerBar("NEXT_ASTEROID_TIMER", "msg.asteroid.next", TIMERS.ASTEROIDS.NEXT_IS_WORLD_ENDER)
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
    name = name,
    indicatorColor = PLANETS[name].INDICATOR_COLOR,
    orbitSize = PLANETS[name].ORBIT,
  }
  core:AddUnit(unit, PLANETS[name].INDICATOR_COLOR, 1)
  if alphaCassus then
    mod:DrawPlanetTankIndicator(planets[id])
  end
end

function mod:RemoveWorldEnderLine(targetName)
  for id, worldEnder in next, worldEnders do
    if worldEnder.targetName == targetName then
      core:RemoveLineBetweenUnits("WORLD_ENDER_" .. id)
    end
  end
end

function mod:OnPlanetDestroyed(id, unit, name)
  core:DropMark(id)
  planets[id] = nil
  core:RemoveLineBetweenUnits(id)
  mod:RemoveWorldEnderLine(name)
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
  core:AddUnit(unit, "xkcdOrange", 0)
  core:WatchUnit(unit, core.E.TRACK_HEALTH + core.E.TRACK_CASTS)
  mod:DrawPlanetTankIndicators()
  mod:UpdateAlphaCassusCleaveLine()
end

function mod:UpdateAlphaCassusCleaveLine()
  if mod:GetSetting("LineAlphaCassusCleave") then
    core:AddSimpleLine(alphaCassus.id, alphaCassus.unit, 8, 20, nil, 10, CLEAVE_COLORS[solarFlareCount%2])
  end
end

function mod:OnSolarFlareEnd(id)
  solarFlareCount = solarFlareCount + 1
  mod:UpdateAlphaCassusCleaveLine()
end

function mod:OnAlphaCassusHealthChanged(id, percent)
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
    core:AddLineBetweenUnits("ASTEROID_LINE_" .. id, alphaCassus.id, id, 10, "xkcdBrown", nil, 8, 3.5)
  end
  if mod:GetSetting("LineAsteroids") then
    core:AddSimpleLine(id, unit, 0, 16, nil, 6, "xkcdBananaYellow")
  end
end

function mod:OnAsteroidDestroyed(id, _)
  core:RemoveLineBetweenUnits("ASTEROID_LINE_" .. id)
end

function mod:OnWorldEnderCreated(id, unit)
  worldEnderCount = worldEnderCount + 1
  lastWorldEnder = {
    id = id,
    unit = unit,
  }
  core:AddUnit(unit, "xkcdCyan", 3)
  mod:AddTimerBar("NEXT_WORLD_ENDER_TIMER", "msg.world_ender.next", TIMERS.WORLD_ENDER.NORMAL, mod:GetSetting("CountdownWorldender"))
  if mod:GetSetting("LineWorldender") then
    core:AddLineBetweenUnits("WORLD_ENDER_" .. id, playerId, id, 6, "xkcdCyan")
  end
  mod:AddMsg("WORLD_ENDER_SPAWN_MSG", "msg.world_ender.spawned", 5, "Beware", "xkcdCyan")
  mod:StartAsteroidTimer()
  mod:DropWorldMarker("WORLD_ENDER_MARKER_" .. worldEnderCount)
end

function mod:OnWorldEnderDestroyed(id, unit)
  core:RemoveLineBetweenUnits("WORLD_ENDER_" .. id)
  worldEnders[id] = nil
end

function mod:OnDebrisCreated(id, unit)
  if mod:GetSetting("CrosshairCosmicDebris") then
    core:AddPicture("DEBRIS_PICTURE_" .. id, id, "Crosshair", 40, nil, nil, nil, "xkcdRed")
  end
end

function mod:OnDebrisDestroyed(id, unit)
  core:RemovePicture("DEBRIS_PICTURE_" .. id)
end

function mod:MarkPlanetsWithSolarWindTime(remainingTime)
  if not mod:GetSetting("MarkSolarWindTimer") then return end
  local stringTime = string.format("%.1f", remainingTime)
  for id, planet in next, planets do
    core:MarkUnit(planet.unit, core.E.LOCATION_STATIC_FLOOR, stringTime)
  end
end

function mod:RemoveSolarWindPlanetMarks()
  for id, planet in next, planets do
    core:DropMark(planet.id)
  end
end

function mod:OnUpdateSolarWindTimer()
  local remainingTime = TIMERS.SOLAR_WIND.INTERVAL - ((GetTickCount() - solarWindStartTick) / 1000)
  if remainingTime < 0 then
    solarWindTimer:Stop()
    mod:RemoveSolarWindPlanetMarks()
  else
    mod:MarkPlanetsWithSolarWindTime(remainingTime)
  end
end

function mod:StartSolarWindTimer()
  solarWindStartTick = GetTickCount()
  solarWindTimer:Start()
end

function mod:OnSolarWindsAdded(id, spellId, stack, timeRemaining)
  if playerId ~= id then return end
  mod:StartSolarWindTimer()
end

function mod:OnSolarWindsUpdated(id, spellId, stack, timeRemaining)
  if playerId ~= id then return end
  if solarWindsStack < stack then
    mod:StartSolarWindTimer()
    if stack == 5 then
      mod:AddMsg("SOLAR_WINDS_MSG", "msg.solar_winds.high_stacks", 5, "Beware", "white")
    end
  end
  solarWindsStack = stack
end

function mod:DrawPlanetOrbits()
  if not mod:GetSetting("CirclePlanetOrbits") then return end
  for name, planet in next, PLANETS do
    core:AddPolygon("LOWER_ORBIT_"..name, ALPHA_CASSUS_POSITION, planet.ORBIT.LOWER, nil, 5, planet.INDICATOR_COLOR, 40)
    core:AddPolygon("UPPER_ORBIT_"..name, ALPHA_CASSUS_POSITION, planet.ORBIT.UPPER, nil, 5, planet.INDICATOR_COLOR, 40)
  end
end

function mod:RemovePlanetOrbits()
  if mod:GetSetting("CirclePermanentPlanetOrbits") then return end
  for name, planet in next, PLANETS do
    core:RemovePolygon("LOWER_ORBIT_"..name)
    core:RemovePolygon("UPPER_ORBIT_"..name)
  end
end

function mod:OnCriticalMassAdded(id)
  if playerId == id then
    mod:AddMsg("CRITICAL_MASS_MSG", "msg.critical_mass.you", 5, "Inferno", "white")
    mod:DrawPlanetOrbits()
  end
end

function mod:OnCriticalMassRemoved(id)
  if playerId == id then
    core:RemoveMsg("CRITICAL_MASS_MSG")
    mod:RemovePlanetOrbits()
  end
end

function mod:OnDebrisFieldCreated(id, unit)
  if mod:GetSetting("MarkDebrisField") then
    core:AddPicture("DEBRIS_FIELD_MARKER"..id, unit, "IconSprites:Icon_Windows_UI_SabotageBomb_Red", 40)
  end
end

function mod:OnDebrisFieldDestroyed(id, unit)
  core:RemovePicture("DEBRIS_FIELD_MARKER"..id)
end

function mod:OnWorldEnderTarget(targetName)
  lastWorldEnder.targetName = targetName
  worldEnders[lastWorldEnder.id] = lastWorldEnder
end

function mod:OnWorldEnderTargetAldinari()
  mod:OnWorldEnderTarget(self.L["unit.aldinari"])
end

function mod:OnWorldEnderTargetVulpesNix()
  mod:OnWorldEnderTarget(self.L["unit.vulpes_nix"])
end

function mod:OnWorldEnderTargetCassus()
  mod:OnWorldEnderTarget(self.L["unit.cassus"])
end

mod:RegisterDatachronEvent("chron.world_ender.aldinari", core.E.COMPARE_EQUAL, mod.OnWorldEnderTargetAldinari)
mod:RegisterDatachronEvent("chron.world_ender.vulpes_nix", core.E.COMPARE_EQUAL, mod.OnWorldEnderTargetVulpesNix)
mod:RegisterDatachronEvent("chron.world_ender.cassus", core.E.COMPARE_EQUAL, mod.OnWorldEnderTargetCassus)
mod:RegisterUnitEvents("unit.alpha",{
    [core.E.UNIT_CREATED] = mod.OnAlphaCassusCreated,
    [core.E.UNIT_DESTROYED] = mod.OnAlphaCassusDestroyed,
    [core.E.HEALTH_CHANGED] = mod.OnAlphaCassusHealthChanged,
    ["cast.alpha.flare"] = {
      [core.E.CAST_END] = mod.OnSolarFlareEnd,
    }
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
      [core.E.DEBUFF_ADD] = mod.OnSolarWindsAdded,
      [core.E.DEBUFF_UPDATE] = mod.OnSolarWindsUpdated,
    },
    [DEBUFFS.CRITICAL_MASS] = {
      [core.E.DEBUFF_ADD] = mod.OnCriticalMassAdded,
      [core.E.DEBUFF_REMOVE] = mod.OnCriticalMassRemoved,
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
mod:RegisterUnitEvents("unit.debris_field",{
    [core.E.UNIT_CREATED] = mod.OnDebrisFieldCreated,
    [core.E.UNIT_DESTROYED] = mod.OnDebrisFieldDestroyed,
  }
)
