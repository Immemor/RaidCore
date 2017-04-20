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
local mod = core:NewEncounter("FullyOptimizedCanimid", 52, 98, 108)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Fully-Optimized Canimid" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Fully-Optimized Canimid"] = "Fully-Optimized Canimid",
    -- Cast
    ["Terra-forme"] = "Terra-forme",
    ["Undermine"] = "Undermine",
    -- Bar and messages.
    ["5 x undermine"] = "5x undermine",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Fully-Optimized Canimid"] = "Canimide entièrement optimisé",
    -- Cast
    ["Terra-forme"] = "Terra-forme",
    ["Undermine"] = "Ébranler",
    -- Bar and messages.
    ["5 x undermine"] = "5x Ébranler",
  })
mod:RegisterGermanLocale({
  })
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["Terra-forme"] = { sColor = "xkcdAmethyst" },
    ["Undermine"] = { sColor = "xkcdBloodOrange" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  mod:AddTimerBar("Terra-forme", "Terra-forme", 59.5)
  mod:AddTimerBar("Undermine", "5 x undermine", 31.7)
end

function mod:OnUnitCreated(nId, tUnit, sName)
  if sName == self.L["Fully-Optimized Canimid"] then
    core:AddUnit(tUnit)
    core:WatchUnit(tUnit)
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if self.L["Fully-Optimized Canimid"] == sName then
    if self.L["Terra-forme"] == sCastName then
      mod:RemoveTimerBar("Terra-forme")
    elseif self.L["Undermine"] == sCastName then
      mod:RemoveTimerBar("5 x undermine")
    end
  end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
  if self.L["Fully-Optimized Canimid"] == sName then
    if self.L["Terra-forme"] == sCastName then
      -- Timings are corrects only if the absorb have been broken.
      -- The MOO duration is 10s.
      mod:AddTimerBar("Undermine", "5 x undermine", 28.8)
      mod:AddTimerBar("Terra-forme", "Terra-forme", 66)
    end
  end
end
