----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--[[
Description:
2 Boms will appear at the same time at 2 different corners of the map.
They loose health over time and can be dpsed. They explode at 0 health and
deal significant damage to the raid and put different debuffs on all players.

Incendiary Warhead:
Puts a dot on all players.

Caustic Warhead:
Reduces all incoming healing by 70% on all players.

Strat:
Explode caustic warhead first, use dmg reduction abilities like dGrid. Heal up
after it explodes and let incindiary die by itself and then heal up again.
--]]
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Luk'ki", 104, 548, 555)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.luk'ki" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.luk'ki"] = "Munitions Specialist Luk'ki",
    ["unit.invis.0"] = "Hostile Invisible Unit for Fields (0 hit radius)", --?
    ["unit.invis.random_rot"] = "Hostile Invisible Unit Random Rot (0 hit radius)", --?
    ["unit.warhead.caustic"] = "Caustic Warhead",
    ["unit.warhead.incindiary"] = "Incindiary Warhead",
    -- Marks.
    ["mark.bombsite.a"] = "A",
    ["mark.bombsite.b"] = "B",
    -- Messages.
    ["msg.bomb.next"] = "Next bombs in",
    ["msg.bomb.priority"] = "Rush %s",
    ["msg.bomb.close"] = "%s exploding soon",
    ["msg.caustic"] = "Caustic",
    ["msg.incindiary"] = "Incindiary",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.invis.0"] = "Feindselige unsichtbare Einheit für Felder (Trefferradius 0)",
    -- Messages.
    ["msg.bomb.next"] = "Nächste Bomben in",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.invis.0"] = "Unité hostile invisible de terrain (rayon de portée : 0)",
    ["unit.invis.random_rot"] = "Corruption aléatoire unité hostile invisible (rayon de portée : 0)",
    -- Messages.
    ["msg.bomb.next"] = "Prochaine bombe dans",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visual.
mod:RegisterDefaultSetting("CrosshairBombs")
mod:RegisterDefaultSetting("LineBombs")
-- Messages.
mod:RegisterDefaultSetting("MessageBombSpawn")
mod:RegisterDefaultSetting("MessageBombClose")
-- Sound.
mod:RegisterDefaultSetting("SoundBombSpawn")
mod:RegisterDefaultSetting("SoundBombClose")
-- Binds.
mod:RegisterMessageSetting("BOMB_SPAWN", core.E.COMPARE_EQUAL, "MessageBombSpawn", "SoundBombSpawn")
mod:RegisterMessageSetting("BOMB_CLOSE_%d+", core.E.COMPARE_MATCH, "MessageBombClose", "SoundBombClose")
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_BOMB_TIMER"] = {sColor = "xkcdBrown"},
  }
)
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFS = {
  CAUSTIC = 87690, -- Reduces incoming healing by 70%
  INCINDIARY = 87693, -- Damage over time?
}
local TIMERS = {
  BOMBS = {
    FIRST = 21,
    NORMAL = 42,
  }
}
local WORLD_POSITIONS = {
  BOMBSITES = {
    A = {x = 153.99252319336, y = 0.84451651573181, z = 77.654678344727},
    B = {x = 153.99252319336, y = 0.84451651573181, z = -12.570874214172},
  }
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local playerId
local explosionMessagesSent
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerId = GameLib.GetPlayerUnit():GetId()
  explosionMessagesSent = {}
  mod:StartFirstBombTimer()
  mod:AddWorldMarkers()
end

function mod:AddWorldMarkers()
  mod:SetWorldMarker("BOMBSITE_A", "mark.bombsite.a", WORLD_POSITIONS.BOMBSITES.A)
  mod:SetWorldMarker("BOMBSITE_B", "mark.bombsite.b", WORLD_POSITIONS.BOMBSITES.B)
end

function mod:OnIncindiaryCreated(id, unit, name)
  mod:DrawLineToBomb(id)
  mod:StartNormalBombTimer()

  local locationName = mod:GetPriorityBombLocationName(unit)
  mod:ShowBombSpawnMessage(locationName)
end

function mod:DrawLineToBomb(id)
  if mod:GetSetting("LineBombs") then
    core:AddLineBetweenUnits("PRIORITY_BOMB", playerId, id, 5)
  end
end

function mod:GetPriorityBombLocationName(unit)
  if mod:IsPositionNearA(unit:GetPosition()) then
    return self.L["mark.bombsite.a"]
  end
  return self.L["mark.bombsite.b"]
end

function mod:IsPositionNearA(position)
  return position.z > 45
end

function mod:ShowBombSpawnMessage(locationName)
  local msg = self.L["msg.bomb.priority"]:format(locationName)
  mod:AddMsg("BOMB_SPAWN", msg, 5, "Info", "xkcdWhite")
end

function mod:StartFirstBombTimer()
  mod:StartBombTimer(TIMERS.BOMBS.FIRST)
end

function mod:StartNormalBombTimer()
  mod:StartBombTimer(TIMERS.BOMBS.NORMAL)
end

function mod:StartBombTimer(time)
  mod:AddTimerBar("NEXT_BOMB_TIMER", "msg.bomb.next", time)
end

function mod:OnBarUnitCreated(id, unit, name)
  core:AddUnit(unit)
end

function mod:OnBombCreated(id, unit, name)
  core:WatchUnit(unit, core.E.TRACK_HEALTH)
  explosionMessagesSent[id] = false
  if mod:GetSetting("CrosshairBombs") then
    core:AddPicture(id, id, "Crosshair", 30, 0, 0, nil, "red")
  end
end

function mod:IsBombCloseToExplosion(id, percent)
  return not explosionMessagesSent[id] and percent <= 10
end

function mod:OnBombHealthChanged(id, percent, nickName)
  if mod:IsBombCloseToExplosion(id, percent) then
    explosionMessagesSent[id] = true
    local msg = self.L["msg.bomb.close"]:format(nickName)
    mod:AddMsg("BOMB_CLOSE_"..id, msg, 5, "Beware", "xkcdRed")
  end
end

function mod:OnIncindiaryHealthChanged(id, percent)
  mod:OnBombHealthChanged(id, percent, self.L["msg.incindiary"])
end

function mod:OnCausticHealthChanged(id, percent)
  mod:OnBombHealthChanged(id, percent, self.L["msg.caustic"])
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents({"unit.warhead.incindiary", "unit.warhead.caustic"},{
    [core.E.UNIT_CREATED] = mod.OnBombCreated,
  }
)
mod:RegisterUnitEvents("unit.warhead.incindiary",{
    [core.E.UNIT_CREATED] = mod.OnIncindiaryCreated,
    [core.E.HEALTH_CHANGED] = mod.OnIncindiaryHealthChanged,
  }
)
mod:RegisterUnitEvent("unit.warhead.caustic", core.E.HEALTH_CHANGED, mod.OnCausticHealthChanged)
mod:RegisterUnitEvents({"unit.luk'ki", "unit.warhead.incindiary", "unit.warhead.caustic"},{
    [core.E.UNIT_CREATED] = mod.OnBarUnitCreated,
  }
)
