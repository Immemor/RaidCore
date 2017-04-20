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

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Dud'li", 104, 548, 555)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.dud'li" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.dud'li"] = "Torpedo Technician Dud'li",
    ["unit.warhead.flashbang"] = "Flashbang Warhead",
    ["unit.warhead.radioactive"] = "Radioactive Warhead",
    -- Marks.
    ["mark.bombsite.a"] = "A",
    ["mark.bombsite.b"] = "B",
    -- Messages.
    ["msg.bomb.next"] = "Next bombs in",
    ["msg.bomb.spawn"] = "Bombs spawned",
    ["msg.bomb.close"] = "%s exploding soon",
    ["msg.flashbang"] = "Flashbang",
    ["msg.radioactive"] = "Radioactive",
  }
)
mod:RegisterGermanLocale({
    -- Messages.
    ["msg.bomb.next"] = "Nächste Bomben in",
  }
)
mod:RegisterFrenchLocale({
    -- Messages.
    ["msg.bomb.next"] = "Prochaine bombe dans",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
-- Visual.
mod:RegisterDefaultSetting("CrosshairBombs")
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
local TIMERS = {
  BOMBS = {
    FIRST = 21,
    NORMAL = 42,
  }
}
local WORLD_POSITIONS = {
  BOMBSITES = {
    A = {x = 63.706142425537, y = 0.84451651573181, z = 77.654678344727},
    B = {x = 63.706142425537, y = 0.84451651573181, z = -12.570874214172},
  }
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local explosionMessagesSent
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  explosionMessagesSent = {}
  mod:StartFirstBombTimer()
  mod:AddWorldMarkers()
end

function mod:AddWorldMarkers()
  mod:SetWorldMarker("BOMBSITE_A", "mark.bombsite.a", WORLD_POSITIONS.BOMBSITES.A)
  mod:SetWorldMarker("BOMBSITE_B", "mark.bombsite.b", WORLD_POSITIONS.BOMBSITES.B)
end

function mod:OnFlashbangCreated(id, unit, name)
  mod:StartNormalBombTimer()
  mod:ShowBombSpawnMessage()
end

function mod:GetPriorityBombLocationName(unit)
  if mod:IsPositionNearA(unit:GetPosition()) then
    return self.L["mark.bombsite.a"]
  end
  return self.L["mark.bombsite.b"]
end

function mod:ShowBombSpawnMessage()
  mod:AddMsg("BOMB_SPAWN", "msg.bomb.spawn", 5, "Info", "xkcdWhite")
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

function mod:OnFlashbangHealthChanged(id, percent)
  mod:OnBombHealthChanged(id, percent, self.L["msg.flashbang"])
end

function mod:OnRadioactiveHealthChanged(id, percent)
  mod:OnBombHealthChanged(id, percent, self.L["msg.radioactive"])
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitEvents({"unit.warhead.radioactive", "unit.warhead.flashbang"},{
    [core.E.UNIT_CREATED] = mod.OnBombCreated,
  }
)
mod:RegisterUnitEvents("unit.warhead.flashbang",{
    [core.E.UNIT_CREATED] = mod.OnFlashbangCreated,
    [core.E.HEALTH_CHANGED] = mod.OnFlashbangHealthChanged,
  }
)
mod:RegisterUnitEvent("unit.warhead.radioactive", core.E.HEALTH_CHANGED, mod.OnRadioactiveHealthChanged)
mod:RegisterUnitEvents({"unit.dud'li", "unit.warhead.radioactive", "unit.warhead.flashbang"},{
    [core.E.UNIT_CREATED] = mod.OnBarUnitCreated,
  }
)
