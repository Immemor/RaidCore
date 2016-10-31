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
local mod = core:NewEncounter("Dud'li", 104, 548, 555)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "unit.dud'li" })
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
-- Messages.
mod:RegisterDefaultSetting("MessageBombSpawn")
-- Sound.
mod:RegisterDefaultSetting("SoundBombSpawn")
-- Binds.
mod:RegisterMessageSetting("BOMB_SPAWN", "EQUAL", "MessageBombSpawn", "SoundBombSpawn")
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

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
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

function mod:AddUnit(id, unit, name)
  core:AddUnit(unit)
end

mod:RegisterUnitEvents("unit.warhead.flashbang",{
    [core.E.UNIT_CREATED] = mod.OnFlashbangCreated,
  }
)
mod:RegisterUnitEvents({"unit.dud'li", "unit.warhead.radioactive", "unit.warhead.flashbang"},{
    [core.E.UNIT_CREATED] = mod.AddUnit,
  }
)
