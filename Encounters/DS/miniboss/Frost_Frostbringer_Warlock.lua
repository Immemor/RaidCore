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
local mod = core:NewEncounter("FrostbringerWarlock", 52, 98, 109)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Frostbringer Warlock" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Frostbringer Warlock"] = "Frostbringer Warlock",
    ["Glacier"] = "Glacier",
    -- Cast.
    ["Frost Waves"] = "Frost Waves",
    ["Exploding Ice"] = "Exploding Ice",
    -- Bar and messages.
    ["PHASE2"] = "Phase 2",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Frostbringer Warlock"] = "Sorcier cryogène",
    ["Glacier"] = "Glacier",
    -- Cast.
    --TODO ["Frost Waves"] = "Frost Waves",
    --TODO ["Exploding Ice"] = "Exploding Ice",
    -- Bar and messages.
    ["PHASE2"] = "Phase 2",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Frostbringer Warlock"] = "Frostbringer-Hexenmeister",
    -- Cast.
    -- Bar and messages.
  })
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["WAVES"] = { sColor = "xkcdLightGreenBlue" },
    ["EXPLODING_ICE"] = { sColor = "xkcdLightGreenBlue" },
    ["GLACIER"] = { sColor = "xkcdLightGreenBlue" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID__GLACIER = 74397

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local nFrostbringerWarlockId
local nGlacierPopTime
local bIsPhase2

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  nFrostbringerWarlockId = nil
  nGlacierPopTime = 0
  bIsPhase2 = false
  mod:AddTimerBar("WAVES", "Frost Waves", 36)
  mod:AddTimerBar("EXPLODING_ICE", "Exploding Ice", 17)
end

function mod:OnUnitCreated(nId, tUnit, sUnitName)
  if self.L["Frostbringer Warlock"] == sUnitName then
    if nId and (nFrostbringerWarlockId == nil or nFrostbringerWarlockId == nId) then
      -- A filter is needed, because there is many unit called Frostbringer Warlock.
      -- Only the first is the good.
      nFrostbringerWarlockId = nId
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
    end
  end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
  if self.L["Frostbringer Warlock"] == sName then
    if nPourcent <= 20 then
      if bIsPhase2 == false then
        mod:AddMsg("PHASE2", "PHASE2", 5)
        mod:RemoveTimerBar("EXPLODING_ICE")
        mod:RemoveTimerBar("WAVES")
      end
      bIsPhase2 = true
    end
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if self.L["Frostbringer Warlock"] == sName then
    if self.L["Frost Waves"] == sCastName then
      mod:RemoveTimerBar("WAVES")
      mod:RemoveTimerBar("GLACIER")
    elseif self.L["Exploding Ice"] == sCastName then
      mod:RemoveTimerBar("EXPLODING_ICE")
    end
  end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
  if self.L["Frostbringer Warlock"] == sName then
    if self.L["Frost Waves"] == sCastName then
      mod:AddTimerBar("WAVES", "Frost Waves", 36)
      mod:AddTimerBar("EXPLODING_ICE", "Exploding Ice", 36.5)
      mod:AddTimerBar("GLACIER", "Glacier", 12)
    end
  end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  if nSpellId == DEBUFFID__GLACIER then
    local nCurrentTime = GetGameTime()
    if nGlacierPopTime + 5 < nCurrentTime then
      nGlacierPopTime = nCurrentTime
      mod:AddTimerBar("GLACIER", "Glacier", 51)
    end
  end
end
