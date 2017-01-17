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
    ["unit.essence"] = "Essence Void",
    ["unit.tortued_apparition"] = "Tortured Apparition",
    ["unit.orb"] = "Soul Eater",
    ["unit.boneclaw"] = "Risen Boneclaw",
    ["unit.titan"] = "Risen Titan",
    -- Cast names.
    ["cast.essence.surge"] = "Essence Surge", -- Essence fully materialized
    ["cast.laveka.devoursouls"] = "Devour Souls",
    -- Messages.
    ["msg.laveka.soulfire.you"] = "SOULFIRE ON YOU",
    ["msg.laveka.spirit_of_soulfire"] = "Spirit of Soulfire",
    ["msg.laveka.expulsion"] = "STACK!",
    ["msg.laveka.echoes_of_the_afterlife.timer"] = "Echoes of Afterlife",
    ["msg.adds.next"] = "Next Titan in ...",
    ["msg.souleaters.next"] = "Next Soul Eaters in ...",
    ["msg.mid_phase.soon"] = "Mid phase soon",
    ["msg.essence.interrupt"] = "Interrupt Essence",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("LineCleanse", false)
-- Messages.
mod:RegisterDefaultSetting("MessageMidphaseSoon")
mod:RegisterDefaultSetting("MessageEssence", false)
-- Sounds.
mod:RegisterDefaultSetting("SoundMidphaseSoon")
mod:RegisterDefaultSetting("SoundCleanse", false)
mod:RegisterDefaultSetting("SoundEssenceSpawn", false)
-- Essences.
for i = 1, 5 do
  mod:RegisterDefaultSetting("SoundEssence"..i, false)
  mod:RegisterDefaultSetting("LineEssence"..i, false)
end
-- Binds.
mod:RegisterMessageSetting("SPIRIT_OF_SOULFIRE_EXPIRED_MSG", core.E.COMPARE_EQUAL, nil, "SoundCleanse")
mod:RegisterMessageSetting("ESSENCE_SPAWN", core.E.COMPARE_EQUAL, "MessageEssence", "SoundEssenceSpawn")
mod:RegisterDefaultTimerBarConfigs({
    ["SPIRIT_OF_SOULFIRE_TIMER"] = { sColor = "xkcdBarbiePink" },
  }
)
mod:RegisterUnitBarConfig("unit.laveka", {
    nPriority = 0,
    tMidphases = {
      {percent = 75},
      {percent = 50},
      {percent = 25},
    }
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
  EXPULSION_OF_SOULS = 87901, -- Runic circle debuff
  NECROTIC_EXPLOSION = 75610,
  SOUL_EATER = 87069,
  REALM_OF_THE_DEAD = 75528, -- When in dead world
  ECHOES_OF_THE_AFTERLIFE = 75525, -- stacking debuff
  SOULFIRE = 75574, -- Debuff to be cleansed
}

local BUFFS = {
  SPIRIT_OF_SOULFIRE = 75576,
  MOMENT_OF_OPPORTUNITY = 54211,
}

local TIMERS = {
  SOUL_EATERS = {
    FIRST = 76,
    NORMAL = 61,
  },
  ECHOES_OF_THE_AFTERLIFE = 10,
  ADDS = {
    FIRST = 35,
    NORMAL = 90,
  }
}

local ROOM_CENTER = { x = -724.16839599609, y = 186.84739685059, z = -264.67279052734 }

local SOUL_EATER_ORBITS = {
  [1] = 6,
  [2] = 12,
  [3] = 18,
  [4] = 24,
  [5] = 30,
  [6] = 36
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local player
local essenceNumber
local essences
local isDeadRealm
local lastSpiritOfSoulfireStack
local soulEatersActive
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  essenceNumber = 0
  isDeadRealm = false
  lastSpiritOfSoulfireStack = 0
  essences = {}
  player = {}
  player.unit = GameLib.GetPlayerUnit()
  player.id = player.unit:GetId()
  mod:AddTimerBar("ADDS_TIMER", "msg.adds.next", TIMERS.ADDS.FIRST)
  mod:AddTimerBar("ADDS_TIMER", "msg.souleaters.next", TIMERS.SOUL_EATERS.FIRST, true)
  --mod:DrawSoulEaterOrbits()
end

function mod:OnAnyUnitDestroyed(id, unit, name)
  mod:RemoveSoulfireLine(id, name)
end

function mod:OnWatchedUnitCreated(id, unit, name)
  core:AddUnit(unit)
  core:WatchUnit(unit, core.E.TRACK_ALL)
end

function mod:OnSoulfireAdd(id, spellId, stack, timeRemaining, targetName)
  if id ~= player.id then
    mod:AddSoulfireLine(id, targetName)
  else
    core:MarkUnit(player.unit, core.E.LOCATION_STATIC_CHEST, "S", "xkcdBarbiePink")
    mod:AddMsg("SOULFIRE_MSG_YOU", "msg.laveka.soulfire.you", 5, "Burn", "xkcdBarbiePink")
  end
end

function mod:OnSoulfireRemove(id, spellId, targetName)
  mod:RemoveSoulfireLine(id, targetName)
end

function mod:AddSoulfireLine(id, name)
  if mod:GetSetting("LineCleanse") then
    core:AddLineBetweenUnits("SOULFIRE_LINE_"..name, player.unit, id, 7, "xkcdBarbiePink")
  end
end

function mod:RemoveSoulfireLine(id, name)
  if mod:GetSetting("LineCleanse") then
    core:RemoveLineBetweenUnits("SOULFIRE_LINE_"..name)
  end
  if id == player.id then
    core:DropMark(id)
  end
end

function mod:OnSpiritOfSoulfireAdd(id, spellId, stack, timeRemaining, targetName)
  lastSpiritOfSoulfireStack = 0
  mod:AddSpiritOfSoulfireTimer(stack, timeRemaining)
end

function mod:OnSpiritOfSoulfireUpdate(id, spellId, stack, timeRemaining)
  mod:AddSpiritOfSoulfireTimer(stack, timeRemaining)
end

function mod:AddSpiritOfSoulfireTimer(stack, timeRemaining)
  if stack > lastSpiritOfSoulfireStack then
    mod:AddTimerBar("SPIRIT_OF_SOULFIRE_TIMER", self.L["msg.laveka.spirit_of_soulfire"].." "..tostring(stack), timeRemaining)
  end
  lastSpiritOfSoulfireStack = stack
end

function mod:OnSpiritOfSoulfireRemove(id, spellId, targetName)
  lastSpiritOfSoulfireStack = 0
  mod:AddMsg("SPIRIT_OF_SOULFIRE_EXPIRED_MSG", nil, 1, "Inferno")
  mod:RemoveTimerBar("SPIRIT_OF_SOULFIRE_TIMER")
end

function mod:OnExpulsionAdd(id, spellId, stack, timeRemaining, targetName)
  if isDeadRealm then
    mod:AddMsg("EXPULSION", "msg.laveka.expulsion", 5, "Beware", "xkcdRed")
  end
end

function mod:OnEchoesAdd(id, spellId, stack, timeRemaining, targetName)
  mod:StartEchoesTimer(id)
end

function mod:OnEchoesUpdate(id, spellId, stack, timeRemaining)
  mod:StartEchoesTimer(id)
end

function mod:StartEchoesTimer(id)
  if id == player.id then
    mod:AddTimerBar("ECHOES_OF_THE_AFTERLIFE_TIMER", "msg.laveka.echoes_of_the_afterlife.timer", TIMERS.ECHOES_OF_THE_AFTERLIFE)
  end
end

function mod:OnEchoesRemove(id, spellId, targetName)
  if id == player.id then
    mod:RemoveTimerBar("ECHOES_OF_THE_AFTERLIFE_TIMER")
  end
end

function mod:ToggleDeadRealm(id)
  if id == player.id then
    isDeadRealm = not isDeadRealm
  end
end

function mod:OnRealmOfTheDeadAdd(id, spellId, stack, timeRemaining, targetName)
  mod:StartEchoesTimer(id)
  mod:ToggleDeadRealm(id)
end

function mod:OnRealmOfTheDeadRemove(id, spellId, stack, timeRemaining, targetName)
  mod:ToggleDeadRealm(id)
end

function mod:OnEssenceCreated(id, unit, name)
  core:WatchUnit(unit, core.E.TRACK_CASTS)
  essenceNumber = essenceNumber + 1
  if essenceNumber % 6 == 0 then
    essenceNumber = 1
  end
  essences[id] = {
    number = essenceNumber,
  }
  core:MarkUnit(unit, core.E.LOCATION_STATIC_FLOOR, essenceNumber)
  if mod:GetSetting("LineEssence"..essenceNumber) then
    core:AddLineBetweenUnits("ESSENCE_LINE"..id, player.unit, id, 8, "xkcdPurple")
  end
  mod:AddMsg("ESSENCE_SPAWN", "Essence "..essenceNumber, 5, "Info", "xkcdWhite")
end

function mod:OnEssenceDestroyed(id, unit, name)
  essences[id] = nil
  core:RemoveLineBetweenUnits("ESSENCE_LINE"..id)
end

function mod:OnEssenceSurgeStart(id)
  if mod:GetSetting("SoundEssence"..essences[id].number) then
    mod:AddMsg("ESSENCE_CAST", "msg.essence.interrupt", 2, "Inferno", "xkcdRed")
  end
end

function mod:OnSoulEaterCreated()
  if not soulEatersActive then
    soulEatersActive = true
    mod:DrawSoulEaterOrbits()
  end
end

function mod:OnDevourSoulsStop()
  soulEatersActive = false
  mod:RemoveSoulEaterOrbits()
end

function mod:DrawSoulEaterOrbits()
  for id, radius in next, SOUL_EATER_ORBITS do
    core:AddPolygon("ORBIT_"..id, ROOM_CENTER, radius, nil, 2, "xkcdRed", 40)
    local coordinates_up = Vector3.New({x = ROOM_CENTER.x, y = ROOM_CENTER.y, z = (ROOM_CENTER.z + radius)})
    local coordinates_down = Vector3.New({x = ROOM_CENTER.x, y = ROOM_CENTER.y, z = (ROOM_CENTER.z - radius)})
    mod:SetWorldMarker("ORBIT_"..id.."up", id, coordinates_up)
    mod:SetWorldMarker("ORBIT_"..id.."down", id, coordinates_down)
  end
end

function mod:RemoveSoulEaterOrbits()
  for id, radius in next, SOUL_EATER_ORBITS do
    core:RemovePolygon("ORBIT_"..id)
    mod:DropWorldMarker("ORBIT_"..id.."up")
    mod:DropWorldMarker("ORBIT_"..id.."down")
  end
end

function mod:OnMidphaseEnd()
  mod:AddTimerBar("SOULEATER_TIMER", "msg.souleaters.next", TIMERS.SOUL_EATERS.NORMAL, true)
end

function mod:OnTitanCreated(id, unit, name)
  if not isDeadRealm then
    mod:AddTimerBar("ADDS_TIMER", "msg.adds.next", TIMERS.ADDS.NORMAL)
  end
end

function mod:OnLavekaHealthChanged(id, percent, name)
  if mod:IsMidphaseClose(name, percent) then
    mod:AddMsg("MID_PHASE", "msg.mid_phase.soon", 5, "Info", "xkcdWhite")
  end
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents("unit.essence",{
    [core.E.UNIT_CREATED] = mod.OnEssenceCreated,
    [core.E.UNIT_DESTROYED] = mod.OnEssenceDestroyed,
    ["cast.essence.surge"] = {
      [core.E.CAST_START] = mod.OnEssenceSurgeStart,
    },
  }
)

mod:RegisterUnitEvents("unit.titan",{
    [core.E.UNIT_CREATED] = mod.OnTitanCreated,
  }
)

mod:RegisterUnitEvents("unit.orb",{
    [core.E.UNIT_CREATED] = mod.OnSoulEaterCreated,
  }
)

mod:RegisterUnitEvents({
    "unit.laveka",
    "unit.titan",
    },{
    [core.E.UNIT_CREATED] = mod.OnWatchedUnitCreated,
  }
)

mod:RegisterUnitEvents("unit.laveka",{
    [core.E.HEALTH_CHANGED] = mod.OnLavekaHealthChanged,
    [BUFFS.SPIRIT_OF_SOULFIRE] = {
      [core.E.BUFF_ADD] = mod.OnSpiritOfSoulfireAdd,
      [core.E.BUFF_UPDATE] = mod.OnSpiritOfSoulfireUpdate,
      [core.E.BUFF_REMOVE] = mod.OnSpiritOfSoulfireRemove,
    },
    [BUFFS.MOMENT_OF_OPPORTUNITY] = {
      [core.E.BUFF_ADD] = mod.OnMidphaseEnd,
    },
    ["cast.laveka.devoursouls"] = {
      [core.E.CAST_END] = mod.OnDevourSoulsStop,
    },
  }
)

mod:RegisterUnitEvents(core.E.ALL_UNITS,{
    [core.E.UNIT_DESTROYED] = mod.OnAnyUnitDestroyed,
    [DEBUFFS.SOULFIRE] = {
      [core.E.DEBUFF_ADD] = mod.OnSoulfireAdd,
      [core.E.DEBUFF_REMOVE] = mod.OnSoulfireRemove,
    },
    [DEBUFFS.EXPULSION_OF_SOULS] = {
      [core.E.DEBUFF_ADD] = mod.OnExpulsionAdd,
    },
    [DEBUFFS.ECHOES_OF_THE_AFTERLIFE] = {
      [core.E.DEBUFF_ADD] = mod.OnEchoesAdd,
      [core.E.DEBUFF_UPDATE] = mod.OnEchoesUpdate,
      [core.E.DEBUFF_REMOVE] = mod.OnEchoesRemove,
    },
    [DEBUFFS.REALM_OF_THE_DEAD] = {
      [core.E.DEBUFF_ADD] = mod.OnRealmOfTheDeadAdd,
      [core.E.DEBUFF_REMOVE] = mod.OnRealmOfTheDeadRemove,
    },
  }
)
