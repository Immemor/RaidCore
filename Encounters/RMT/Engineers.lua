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
local mod = core:NewEncounter("Engineers", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", {
    "Chief Engineer Wilbargh", "Head Engineer Orvulgh",
    "Fusion Core",
    "Cooling Turbine",
    "Spark Plug",
    "Lubricant Nozzle"
  })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Fusion Core"] = "Fusion Core",
    ["Cooling Turbine"] = "Cooling Turbine",
    ["Spark Plug"] = "Spark Plug",
    ["Lubricant Nozzle"] = "Lubricant Nozzle",
    ["Head Engineer Orvulgh"] = "Head Engineer Orvulgh",
    ["Chief Engineer Wilbargh"] = "Chief Engineer Wilbargh",
    ["Air Current"] = "Air Current",
    ["Friendly Invisible Unit for Fields"] = "Friendly Invisible Unit for Fields",
    ["Hostile Invisible Unit for Fields (0 hit radius)"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    -- Cast names
    ["Liquidate"] = "Liquidate",
    -- Datachron
    ["Hornious Eversong suffers from Electroshock"] = "",
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

mod:RegisterUnitEvents({
    "Head Engineer Orvulgh", "Chief Engineer Wilbargh",
    "Fusion Core",
    "Cooling Turbine",
    "Spark Plug",
    "Lubricant Nozzle"
    },{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
    end,
  }
)
mod:RegisterUnitEvents("Chief Engineer Wilbargh",{
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Liquidate"] == sCastName then
        --Stack
      end
    end,
  }
)

-- mod:RegisterUnitEvents({"Friendly Invisible Unit for Fields"},{
-- ["OnUnitCreated"] = function (self, nId, tUnit, sName)
-- core:AddPixie(nId, 2, tUnit, nil, "Green", 10, 50, 0)
-- core:AddPixie(nId, 2, tUnit, nil, "Green", 10, 20, 180)
-- end,
-- ["OnUnitDestroyed"] = function (self, nId, tUnit, sName)
-- core:DropPixie(nId)
-- end,
-- }
-- )
