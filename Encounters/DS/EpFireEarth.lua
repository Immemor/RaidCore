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
local mod = core:NewEncounter("EpFireEarth", 52, 98, 117)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "Pyrobane", "Megalith" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Pyrobane"] = "Pyrobane",
    ["Megalith"] = "Megalith",
    ["Lava Mine"] = "Lava Mine",
    ["Obsidian Outcropping"] = "Obsidian Outcropping",
    ["Flame Wave"] = "Flame Wave",
    ["Lava Floor (invis unit)"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
    -- Datachron.
    ["The lava begins to rise through the floor!"] = "The lava begins to rise through the floor!",
    ["Time to die, sapients!"] = "Time to die, sapients!",
    -- Timer bars.
    ["Next lava floor phase"] = "Next lava floor phase",
    ["Next Obsidian"] = "Next Obsidian %d/%d",
    ["End of lava floor phase"] = "End of lava floor phase",
    ["Avatus incoming"] = "Avatus incoming",
    ["Enrage"] = "Enrage",
    -- Message bars.
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Pyrobane"] = "Pyromagnus",
    ["Megalith"] = "Mégalithe",
    ["Lava Mine"] = "Mine de lave",
    ["Obsidian Outcropping"] = "Affleurement d'obsidienne",
    ["Flame Wave"] = "Vague de feu",
    ["Lava Floor (invis unit)"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
    -- Datachron.
    ["The lava begins to rise through the floor!"] = "La lave apparaît par les fissures du sol !",
    ["Time to die, sapients!"] = "Maintenant c'est l'heure de mourir, misérables !",
    -- Timer bars.
    ["Next lava floor phase"] = "Prochaine phase de lave",
    ["Next Obsidian"] = "Prochaine Obsidienne %d/%d",
    ["End of lava floor phase"] = "Fin de la phase de lave",
    ["Avatus incoming"] = "Avatus arrivé",
    ["Enrage"] = "Enrage",
    -- Message bars.
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Pyrobane"] = "Pyroman",
    ["Megalith"] = "Megalith",
    ["Flame Wave"] = "Flammenwelle",
  })
-- Default settings.
mod:RegisterDefaultSetting("LineFlameWaves")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["AVATUS_INCOMING"] = { sColor = "xkcdAmethyst" },
    ["LAVA_FLOOR"] = { sColor = "xkcdBloodRed" },
    ["ENRAGE"] = { sColor = "xkcdBloodRed" },
    ["OBSIDIAN"] = { sColor = "xkcdMediumBrown" },
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local OBSIDIAN_POP_INTERVAL = 14
local LAVA_MINE_POP_INTERVAL = 11.2

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local nObsidianPopMax, nObsidianPopCount
local nLavaFloorCount

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  nObsidianPopMax = 6
  nObsidianPopCount = 1
  nLavaFloorCount = 0
  local text = self.L["Next Obsidian"]:format(nObsidianPopCount, nObsidianPopMax)
  mod:AddTimerBar("OBSIDIAN", text, OBSIDIAN_POP_INTERVAL)
  mod:AddTimerBar("LAVA_FLOOR", "Next lava floor phase", 94)
  mod:AddTimerBar("AVATUS_INCOMING", "Avatus incoming", 425)
end

function mod:OnDatachron(sMessage)
  if sMessage == self.L["The lava begins to rise through the floor!"] then
    mod:AddTimerBar("LAVA_FLOOR", "End of lava floor phase", 28)
    nLavaFloorCount = nLavaFloorCount + 1
  elseif self.L["Time to die, sapients!"] == sMessage then
    mod:RemoveTimerBar("AVATUS_INCOMING")
    mod:AddTimerBar("ENRAGE", "Enrage", 34)
  end
end

function mod:OnUnitCreated(nId, unit, sName)
  if sName == self.L["Pyrobane"] or sName == self.L["Megalith"] then
    core:AddUnit(unit)
  elseif sName == self.L["Flame Wave"] then
    if mod:GetSetting("LineFlameWaves") then
      core:AddSimpleLine(nId, unit, nil, 20, nil, 10, "Green")
    end
  elseif sName == self.L["Obsidian Outcropping"] then
    nObsidianPopCount = nObsidianPopCount + 1
    if nObsidianPopCount <= nObsidianPopMax then
      local text = self.L["Next Obsidian"]:format(nObsidianPopCount, nObsidianPopMax)
      mod:AddTimerBar("OBSIDIAN", text, OBSIDIAN_POP_INTERVAL)
    end
  end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
  if sName == self.L["Lava Floor (invis unit)"] then
    if nLavaFloorCount < 3 then
      mod:AddTimerBar("LAVA_FLOOR", "Next lava floor phase", 89)
    end
    nObsidianPopCount = 1
    if nObsidianPopMax > 2 then
      nObsidianPopMax = nObsidianPopMax - 2
    else
      nObsidianPopMax = 2
    end
    local text = self.L["Next Obsidian"]:format(nObsidianPopCount, nObsidianPopMax)
    local nTimeOffset = (6 - nObsidianPopMax) * OBSIDIAN_POP_INTERVAL + 8
    mod:AddTimerBar("OBSIDIAN", text, nTimeOffset)
  elseif self.L["Pyrobane"] == sName then
    mod:RemoveTimerBar("LAVA_FLOOR")
  end
end
