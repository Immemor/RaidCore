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
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("WarmongerTalarii", 52, 98, 110)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Warmonger Talarii" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Warmonger Talarii"] = "Warmonger Talarii",
    ["Conjured Fire Bomb"] = "Conjured Fire Bomb",
    -- Cast.
    ["Incineration"] = "Incineration",
    ["Conjure Fire Elementals"] = "Conjure Fire Elementals",
    ["Fire Room"] = "[DS] Fire Room - Osun (F) - Bubble Block (Target Selection)",
    -- Bar and messages.
    ["INTERRUPT !"] = "INTERRUPT !",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["Safe Bubble"] = "Safe Bubble",
    ["Bombs"] = "Bombs",
    ["ELEMENTALS SOON"] = "ELEMENTALS SOON",
    ["FIRE ELEMENTALS"] = "FIRE ELEMENTALS",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Warmonger Talarii"] = "Guerroyeuse Talarii",
    ["Conjured Fire Bomb"] = "Bombe incendiaire invoquée",
    -- Cast.
    ["Incineration"] = "Incinération",
    ["Conjure Fire Elementals"] = "Invocation d'Élémentaires de feu",
    ["Fire Room"] = "[DS] Fire Room - Osun (F) - Bubble Block (Target Selection)",
    -- Bar and messages.
    ["INTERRUPT !"] = "INTERROMPRE !",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["Safe Bubble"] = "Bulle Sûre",
    ["Bombs"] = "Bombes",
    ["ELEMENTALS SOON"] = "ÉLÉMENTAIRES BIENTÔT",
    ["FIRE ELEMENTALS"] = "ÉLÉMENTAIRES DE FEU",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Warmonger Talarii"] = "Kriegstreiberin Talarii",
    ["Conjured Fire Bomb"] = "Beschworene Feuerbombe",
    -- Cast.
    ["Incineration"] = "Lodernde Flammen",
    ["Conjure Fire Elementals"] = "Feuerelementare beschwören",
    -- Bar and messages.
    ["KNOCKBACK"] = "RÜCKSTOß",
  })
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BOMBS"] = { sColor = "xkcdLightRed" },
    ["BUBBLE"] = { sColor = "xkcdBabyBlue" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local nPreviousBombPopTime
local bIsFirstFireRoom

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  nPreviousBombPopTime = 0
  bIsFirstFireRoom = true
  mod:AddTimerBar("KNOCK", "KNOCKBACK", 23)
end

function mod:OnUnitCreated(nId, tUnit, sUnitName)
  if self.L["Warmonger Talarii"] == sUnitName then
    core:AddUnit(tUnit)
    core:WatchUnit(tUnit)
  elseif self.L["Conjured Fire Bomb"] == sUnitName then
    local nCurrentTime = GetGameTime()
    if nPreviousBombPopTime + 8 < nCurrentTime then
      mod:AddMsg("BOMB", "BOMB", 5, nil, "Blue")
      mod:AddTimerBar("BOMB", "BOMB", 23)
      nPreviousBombPopTime = nCurrentTime
    end
  end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
  if self.L["Warmonger Talarii"] == sName then
    if nPourcent == 67 or nPourcent == 34 then
      mod:AddMsg("ELEMENTALS", "ELEMENTALS SOON", 5, "Info")
    end
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if self.L["Warmonger Talarii"] == sName then
    if self.L["Incineration"] == sCastName then
      mod:AddMsg("KNOCK", "INTERRUPT !", 5, "Alert")
      mod:AddTimerBar("KNOCK", "KNOCKBACK", 29)
    elseif self.L["Conjure Fire Elementals"] == sCastName then
      mod:AddMsg("ELEMENTALS", "ELEMENTALS", 5)
    elseif self.L["Fire Room"] == sCastName then
      if bIsFirstFireRoom == false then
        core:PlaySound("Long")
      end
      bIsFirstFireRoom = false
    end
  end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
  if self.L["Warmonger Talarii"] == sName then
    if self.L["Fire Room"] == sCastName then
      mod:AddTimerBar("BUBBLE", "Safe Bubble", 50, true)
    end
  end
end
