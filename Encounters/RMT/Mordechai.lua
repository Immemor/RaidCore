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
local mod = core:NewEncounter("Mordechai", 104, 0, 548)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Mordechai Redmoon" })
mod:RegisterEnglishLocale({
    ["Mordechai Redmoon"] = "Mordechai Redmoon"
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()

end

function mod:OnBuffAdd(id, spellId, stack, timeRemaining)
end

function mod:OnCastStart(id, castName, castEndTime, name)
end

function mod:OnDebuffAdd(id, spellId, stack, timeRemaining)

end

function mod:OnUnitDestroyed(id, tUnit, name)

end

function mod:OnUnitCreated(id, unit, name)

end

mod:RegisterUnitEvents("Mordechai Redmoon",{
    ["OnUnitCreated"] = function (self, id, unit, name)
      core:AddUnit(unit)
      core:WatchUnit(unit)
    end,
  }
)
