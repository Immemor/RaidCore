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
local mod = core:NewEncounter("EpAirEarth", 52, 98, 117)
if not mod then return end

local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "Megalith", "Aileron" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Aileron"] = "Aileron",
    ["Air Column"] = "Air Column",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith",
    ["fractured crust leaves it exposed"] = "fractured crust leaves it exposed",
    -- Cast.
    ["Supercell"] = "Supercell",
    ["Raw Power"] = "Raw Power",
    ["Fierce Swipe"] = "Fierce Swipe",
    -- Timer bars.
    ["Next supercell"] = "Next supercell",
    ["Next fierce swipe"] = "Next fierce swipe",
    ["Next tornado"] = "Next tornado",
    ["Next raw power"] = "Next raw power",
    -- Message bars.
    ["EARTH"] = "EARTH",
    ["JUMP !"] = "JUMP, JUMP, JUMP, JUMP !!!"
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Megalith"] = "Mégalithe",
    ["Aileron"] = "Ventemort",
    ["Air Column"] = "Colonne d'air",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "Le sol tremble sous les pieds de Mégalithe !",
    ["fractured crust leaves it exposed"] = "La croûte fracturée de Mégalithe le rend vulnérable !",
    -- Cast.
    ["Supercell"] = "Super-cellule",
    ["Raw Power"] = "Énergie brute",
    ["Fierce Swipe"] = "Baffe féroce",
    -- Timer bars.
    ["Next supercell"] = "Prochaine super-cellule",
    ["Next fierce swipe"] = "Prochaine baffe féroce",
    ["Next tornado"] = "Prochaine tornade",
    ["Next raw power"] = "Prochaine énergie brute",
    -- Message bars.
    ["EARTH"] = "TERRE",
    ["JUMP !"] = "SAUTEZ, SAUTEZ, SAUTEZ, SAUTEZ !!!"
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Aileron"] = "Aileron",
    ["Air Column"] = "Luftsäule",
    -- Datachron messages.
    -- Cast.
    ["Supercell"] = "Superzelle",
    ["Raw Power"] = "Rohe Kraft",
    -- Timer bars.
    -- Message bars.
  })
-- Default settings.
mod:RegisterDefaultSetting("LineTornado")
mod:RegisterDefaultSetting("LineCleaveAileron")
mod:RegisterDefaultSetting("SoundTornadoCountDown")
mod:RegisterDefaultSetting("SoundMidphase")
mod:RegisterDefaultSetting("SoundSupercell")
mod:RegisterDefaultSetting("SoundQuakeJump")
mod:RegisterDefaultSetting("SoundMoO")
mod:RegisterDefaultSetting("OtherQuakeWarnings")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["SUPERCELL"] = { sColor = "xkcdBlueBlue" },
    ["TORNADO"] = { sColor = "xkcdBrightSkyBlue" },
    ["RAWPOWER"] = { sColor = "xkcdBrownishRed" },
    ["FIERCE_SWIPE"] = { sColor = "xkcdBurntYellow" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local nStartTime, nRefTime = 0, 0
local bMidPhase = false

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  local nTime = GetGameTime()
  nStartTime = nTime
  nRefTime = nTime
  bMidPhase = false

  mod:AddTimerBar("SUPERCELL", "Next supercell", 65, mod:GetSetting("SoundSupercell"))
  mod:AddTimerBar("TORNADO", "Next tornado", 16, mod:GetSetting("SoundTornadoCountDown"))
  mod:AddTimerBar("FIERCE_SWIPE", "Next fierce swipe", 16)
end

function mod:OnUnitCreated(nId, unit, sName)
  if sName == self.L["Megalith"] then
    core:AddUnit(unit)
    core:WatchUnit(unit, core.E.TRACK_CASTS)
    core:MarkUnit(unit, nil, self.L["EARTH"])
  elseif sName == self.L["Aileron"] then
    if mod:GetSetting("LineCleaveAileron") then
      core:AddSimpleLine(nId, unit, nil, 15, nil, 10, "Green")
    end
    core:AddUnit(unit)
    core:WatchUnit(unit, core.E.TRACK_CASTS)
  elseif sName == self.L["Air Column"] then
    if mod:GetSetting("LineTornado") then
      core:AddSimpleLine(unit:GetId(), unit, nil, 30, nil, nil, "xkcdBlue", 10)
    end
    if GetGameTime() > nStartTime + 10 then
      mod:AddTimerBar("TORNADO", "Next tornado", 17, mod:GetSetting("SoundTornadoCountDown"))
    end
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if self.L["Megalith"] == sName then
    if self.L["Raw Power"] == sCastName then
      bMidPhase = true
      mod:AddMsg("RAW", sCastName:upper(), 5, mod:GetSetting("SoundMidphase") and "Alert")
    elseif self.L["Fierce Swipe"] == sCastName then
      mod:AddTimerBar("FIERCE_SWIPE", "Next fierce swipe", 16.5)
    end
  elseif self.L["Aileron"] == sName then
    if self.L["Supercell"] == sCastName then
      local timeOfEvent = GetGameTime()
      if timeOfEvent - nRefTime > 30 then
        nRefTime = timeOfEvent
        mod:AddMsg("SUPERCELL", sCastName:upper(), 5, mod:GetSetting("SoundSupercell") and "Alarm")
        mod:AddTimerBar("SUPERCELL", "Next supercell", 80)
      end
    end
  end
end

function mod:OnDatachron(sMessage)
  if sMessage:find(self.L["The ground shudders beneath Megalith"]) then
    if mod:GetSetting("SoundQuakeJump") then
      core:PlaySound("Beware")
    end
    if mod:GetSetting("OtherQuakeWarnings") then
      mod:AddMsg("QUAKE1", "JUMP !", 2)
      mod:AddMsg("QUAKE2", "JUMP !", 2)
    end
  elseif sMessage:find(self.L["fractured crust leaves it exposed"]) and bMidPhase then
    bMidPhase = false
    mod:AddTimerBar("RAWPOWER", "Next raw power", 60, mod:GetSetting("SoundMidphase"))
  end
end
