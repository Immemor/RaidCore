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

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)

end

function mod:OnUnitDestroyed(nId, tUnit, sName)

end

function mod:OnUnitCreated(nId, unit, sName)

end

mod:RegisterUnitEvents("Mordechai Redmoon",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
    end,
  }
)
