----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- Fake boss, to test few basic feature in RaidCore.
--
-- This last should be declared only in alpha version or with git database.
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
--@alpha@
local mod = core:NewEncounter("GalerasTest", 6, 0, 16, true)
--@end-alpha@
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Crimson Spiderbot", "Crimson Clanker" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Crimson Clanker"] = "Crimson Clanker",
    ["Crimson Spiderbot"] = "Crimson Spiderbot",
    ["Phaser Combo"] = "Phaser Combo",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Crimson Clanker"] = "Cybernéticien écarlate",
    ["Crimson Spiderbot"] = "Arachnobot écarlate",
    ["Phaser Combo"] = "Combo de phaser",
  })
mod:RegisterDefaultTimerBarConfigs({
    ["UNIT"] = { sColor = "red", bEmphasize = false },
    ["INFINITE"] = { sColor = "FF008080", bEmphasize = true },
    ["INFINITE2"] = { bEmphasize = true },
    ["LONG"] = { sColor = "FF80FF20" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local function InfiniteTimer2()
  mod:AddTimerBar("INFINITE2", "Loop Timer outside", 10, nil, nil, InfiniteTimer2)
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  mod:AddTimerBar("INFINITE", "Timer in class", 12, false, nil, mod.InfiniteTimer, mod)
  mod:AddTimerBar("INFINITE2", "Timer outside", 12, nil, nil, InfiniteTimer2)
  mod:AddTimerBar("LONG", "Long long timer...", 1000)
end

function mod:InfiniteTimer()
  mod:AddTimerBar("INFINITE", "Loop Timer in class", 10, false, nil, mod.InfiniteTimer, mod)
end

function mod:OnUnitCreated(nId, unit, sName)
  if sName == self.L["Crimson Spiderbot"] then
    core:MarkUnit(unit, 1, "A")
  end
end

function mod:OnEnteredCombat(nId, tUnit, sName, bInCombat)
  if bInCombat then
    if sName == self.L["Crimson Spiderbot"] then
      core:WatchUnit(tUnit)
      core:AddUnit(tUnit)
      core:MarkUnit(tUnit, 51)
    end
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if sCastName == self.L["Phaser Combo"] then
    mod:AddTimerBar("UNIT", "End of Combo Phaser", 3)
  end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
  if sCastName == self.L["Phaser Combo"] then
    mod:AddTimerBar("UNIT", "Next Combo Phaser", 5)
  end
end
