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
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Luk'Ki", 104, 548, 555)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "unit.luk'ki" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.luk'ki"] = "Munitions Specialist Luk'ki",
    ["unit.invis.0"] = "Hostile Invisible Unit for Fields (0 hit radius)", --?
    ["unit.invis.random_rot"] = "Hostile Invisible Unit Random Rot (0 hit radius)", --?
    ["unit.caustic"] = "Caustic Warhead",
    ["unit.incindiary"] = "Incindiary Warhead",
    -- Messages.
    ["msg.bomb.next"] = "Next bombs in",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.invis.0"] = "Feindselige unsichtbare Einheit für Felder (Trefferradius 0)",
    -- Cast names.
    -- Messages.
    ["msg.bomb.next"] = "Nächste Bomben in",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.invis.0"] = "Unité hostile invisible de terrain (rayon de portée : 0)",
    ["unit.invis.random_rot"] = "Corruption aléatoire unité hostile invisible (rayon de portée : 0)",
    -- Cast names.
    -- Messages.
    ["msg.bomb.next"] = "Prochaine bombes dans",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  mod:StartFirstBombTimer()
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

mod:RegisterUnitEvent("unit.caustic", core.E.UNIT_CREATED, mod.StartNormalBombTimer)
mod:RegisterUnitEvents({"unit.luk'ki", "unit.incindiary", "unit.caustic"},{
    [core.E.UNIT_CREATED] = mod.AddUnit,
  }
)
