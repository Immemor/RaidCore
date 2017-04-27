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
local mod = core:NewEncounter("EpFireLife", 52, 98, 119)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "Visceralus", "Pyrobane" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Visceralus"] = "Visceralus",
    ["Pyrobane"] = "Pyrobane",
    ["Life Force"] = "Life Force",
    ["Essence of Life"] = "Essence of Life",
    ["Flame Wave"] = "Flame Wave",
    -- Cast.
    ["Blinding Light"] = "Blinding Light",
    -- Timer bars.
    ["Next middle phase"] = "Next middle phase",
    -- Message bars.
    ["No-Healing DEBUFF!"] = "No-Healing DEBUFF!",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Visceralus"] = "Visceralus",
    ["Pyrobane"] = "Pyromagnus",
    ["Life Force"] = "Force vitale",
    ["Essence of Life"] = "Essence de vie",
    ["Flame Wave"] = "Vague de feu",
    -- Cast.
    ["Blinding Light"] = "Lumière aveuglante",
    -- Timer bars.
    ["Next middle phase"] = "Prochaine phase milieu",
    -- Message bars.
    ["No-Healing DEBUFF!"] = "Aucun-Soin DEBUFF!",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Visceralus"] = "Viszeralus",
    ["Pyrobane"] = "Pyroman",
    ["Life Force"] = "Lebenskraft",
    ["Essence of Life"] = "Lebensessenz",
    ["Flame Wave"] = "Flammenwelle",
    -- Cast.
    ["Blinding Light"] = "Blendendes Licht",
    -- Timer bars.
    -- Message bars.
  })
-- Default settings.
mod:RegisterDefaultSetting("SoundNoHealDebuff")
mod:RegisterDefaultSetting("SoundBlindingLight")
mod:RegisterDefaultSetting("SoundCountDownMidPhase")
mod:RegisterDefaultSetting("LineLifeOrbs")
mod:RegisterDefaultSetting("LineFlameWaves")
mod:RegisterDefaultSetting("LineBlindVisceralus")
mod:RegisterDefaultSetting("PictureLifeForceShackle")
mod:RegisterDefaultSetting("PictureBeforeRoot")
mod:RegisterDefaultSetting("PictureRoot")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["MID"] = { sColor = "xkcdLightOrange" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_PRIMAL_ENTANGLEMENT1 = 73179 -- After the root ability.
local DEBUFFID_PRIMAL_ENTANGLEMENT2 = 73177 -- Before the root ability.
local DEBUFFID_LIFE_FORCE_SHACKLE = 74366
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById

local nEssenceofLifeCount

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  nEssenceofLifeCount = 0
  mod:AddTimerBar("MID", "Next middle phase", 90, mod:GetSetting("SoundCountDownMidPhase"))
end

function mod:OnUnitCreated(nId, tUnit, sName)
  local nHealth = tUnit:GetHealth()

  if sName == self.L["Visceralus"] then
    if nHealth and nHealth > 0 then
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit, core.E.TRACK_CASTS)
      if mod:GetSetting("LineBlindVisceralus") then
        core:AddSimpleLine("Visc1", nId, 0, 25, 0, 4, "blue", 10)
        core:AddSimpleLine("Visc2", nId, 0, 25, 72, 4, "green", 20)
        core:AddSimpleLine("Visc3", nId, 0, 25, 144, 4, "green", 20)
        core:AddSimpleLine("Visc4", nId, 0, 25, 216, 4, "green", 20)
        core:AddSimpleLine("Visc5", nId, 0, 25, 288, 4, "green", 20)
      end
    end
  elseif sName == self.L["Pyrobane"] then
    if nHealth and nHealth > 0 then
      core:AddUnit(tUnit)
    else
      -- Other units called Pyrobane are in fact the wall of fire un phase 2.
      -- The positions retrieve of these wall of fire, are always the middle.
      -- So that can't be used to detect hole in the wall.
    end
  elseif sName == self.L["Life Force"] then
    if mod:GetSetting("LineLifeOrbs") then
      core:AddSimpleLine(nId, nId, 0, 40, 0, 10, "blue")
    end
  elseif sName == self.L["Flame Wave"] then
    if mod:GetSetting("LineFlameWaves") then
      core:AddSimpleLine(nId, nId, 0, 20, 0, 10, "green")
    end
  elseif self.L["Essence of Life"] == sName then
    nEssenceofLifeCount = nEssenceofLifeCount + 1
  end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
  if self.L["Essence of Life"] == sName then
    nEssenceofLifeCount = nEssenceofLifeCount - 1
    if nEssenceofLifeCount == 0 then
      mod:AddTimerBar("MID", "Next middle phase", 90, mod:GetSetting("SoundCountDownMidPhase"))
    end
  end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  if nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT1 then
    if mod:GetSetting("PictureRoot") then
      core:AddPicture("ROOT" .. nId, nId, "Crosshair", 40, nil, nil, nil, "red")
    end
  elseif nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT2 then
    if mod:GetSetting("PictureBeforeRoot") then
      core:AddPicture("BEFORE_ROOT" .. nId, nId, "Crosshair", 60, nil, nil, nil, "green")
    end
  elseif nSpellId == DEBUFFID_LIFE_FORCE_SHACKLE then
    if GetPlayerUnit():GetId() == nId then
      mod:AddMsg("NOHEAL", "No-Healing DEBUFF!", 3, mod:GetSetting("SoundNoHealDebuff") and "Alarm")
    end
    if mod:GetSetting("PictureLifeForceShackle") then
      mod:AddSpell2Dispel(nId, DEBUFFID_LIFE_FORCE_SHACKLE)
    end
  end
end

function mod:OnDebuffRemove(nId, nSpellId)
  if nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT1 then
    core:RemovePicture("ROOT" .. nId)
  elseif nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT2 then
    core:RemovePicture("BEFORE_ROOT" .. nId)
  elseif nSpellId == DEBUFFID_LIFE_FORCE_SHACKLE then
    mod:RemoveSpell2Dispel(nId, DEBUFFID_LIFE_FORCE_SHACKLE)
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if self.L["Visceralus"] == sName then
    local tUnit = GetUnitById(nId)
    local bIsClose = self:GetDistanceBetweenUnits(tUnit, GetPlayerUnit()) < 50
    if self.L["Blinding Light"] == sCastName and bIsClose then
      mod:AddMsg("BLIND", "Blinding Light", 3, mod:GetSetting("SoundBlindingLight") and "Beware")
    end
  end
end
