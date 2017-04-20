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
local mod = core:NewEncounter("EpFireWater", 52, 98, 118)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "Hydroflux", "Pyrobane" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Pyrobane"] = "Pyrobane",
    ["Ice Tomb"] = "Ice Tomb",
    -- Cast.
    ["Flame Wave"] = "Flame Wave",
    -- Timer bars.
    ["Next bombs"] = "Next bombs",
    ["Bomb explosion"] = "Bomb explosion",
    ["Next ice tomb"] = "Next ice tomb",
    -- Message bars.
    ["Fire Bomb"] = "Fire",
    ["Frost Bomb"] = "Frost",
    ["BOMBS ON YOU!"] = "BOMBS ON YOU!",
    ["ICE TOMB"] = "ICE TOMB",
    ["%d STACKS!"] = "%d STACKS!",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Pyrobane"] = "Pyromagnus",
    ["Ice Tomb"] = "Tombeau de glace",
    -- Cast.
    ["Flame Wave"] = "Vague de feu",
    -- Timer bars.
    ["Next bombs"] = "Prochaine bombes",
    ["Bomb explosion"] = "Bombe explosion",
    ["Next ice tomb"] = "Prochain tombeau de glace",
    -- Message bars.
    ["Fire Bomb"] = "Feu",
    ["Frost Bomb"] = "Givre",
    ["BOMBS ON YOU!"] = "BOMBES SUR VOUS !",
    ["ICE TOMB"] = "TOMBEAU DE GLACE",
    ["%d STACKS!"] = "%d STACKS!",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Pyrobane"] = "Pyroman",
    ["Ice Tomb"] = "Eisgrab",
    -- Cast.
    ["Flame Wave"] = "Flammenwelle",
    -- Timer bars.
    -- Message bars.
    ["ICE TOMB"] = "EISGRAB",
    ["%d STACKS!"] = "%d STACKS!",
  })
-- Default settings.
mod:RegisterDefaultSetting("SoundBomb")
mod:RegisterDefaultSetting("SoundIceTomb")
mod:RegisterDefaultSetting("SoundHighDebuffStacks")
mod:RegisterDefaultSetting("OtherBombPlayerMarkers")
mod:RegisterDefaultSetting("LineBombPlayers")
mod:RegisterDefaultSetting("LineIceTomb")
mod:RegisterDefaultSetting("LineFlameWaves")
mod:RegisterDefaultSetting("LineCleaveHydroflux")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["TOMB"] = { sColor = "xkcdBrightLightBlue" },
    ["BOMBS"] = { sColor = "xkcdRed" },
    ["BEXPLODE"] = { sColor = "xkcdOrangered" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_ICE_TOMB = 74326
local DEBUFFID_FROSTBOMB = 75058
local DEBUFFID_FIREBOMB = 75059
local DEBUFFID_DRENCHED = 52874
local DEBUFFID_ENGULFED = 52876

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime
local nLastIceTombTime
local nLastBombTime
local tFireBombPlayersList
local tFrostBombPlayersList
local playerUnit
local lastStack

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  lastStack = 0
  nLastIceTombTime = 0
  nLastBombTime = 0
  tFireBombPlayersList = {}
  tFrostBombPlayersList = {}
  mod:AddTimerBar("BOMBS", "Next bombs", 30)
  mod:AddTimerBar("TOMB", "Next ice tomb", 26)
end

function mod:RemoveBombMarker(bomb_type, unit)
  if unit and unit:IsValid() then
    local sName = unit:GetName()
    local nId = unit:GetId()
    core:DropMark(nId)
    core:RemoveUnit(nId)
    if bomb_type == "fire" then
      tFireBombPlayersList[sName] = nil
      core:RemoveLineBetweenUnits(nId .. "_BOMB")
    elseif bomb_type == "frost" then
      tFrostBombPlayersList[sName] = nil
      core:RemoveLineBetweenUnits(nId .. "_BOMB")
    end
  end
end

function mod:ApplyBombLines(bomb_type)
  if bomb_type == "fire" then
    for key, value in pairs(tFrostBombPlayersList) do
      local unitId = value:GetId()
      if unitId then
        core:AddLineBetweenUnits(unitId .. "_BOMB", playerUnit, value, 5, "Blue")
      end
    end
  elseif bomb_type == "frost" then
    for key, value in pairs(tFireBombPlayersList) do
      local unitId = value:GetId()
      if unitId then
        core:AddLineBetweenUnits(unitId .. "_BOMB", playerUnit, value, 5, "Red")
      end
    end
  end
end

function mod:OnUnitCreated(nId, unit, sName)
  if sName == self.L["Hydroflux"] then
    core:AddUnit(unit)
    if mod:GetSetting("LineCleaveHydroflux") then
      core:AddSimpleLine(nId .. "_1", unit, nil, 7, 0, 3, "Yellow")
      core:AddSimpleLine(nId .. "_2", unit, nil, 7, 180, 3, "Yellow")
    end
  elseif sName == self.L["Pyrobane"] then
    core:AddUnit(unit)
  elseif sName == self.L["Ice Tomb"] then
    local nCurrentTime = GetGameTime()
    if nCurrentTime - nLastIceTombTime > 13 then
      nLastIceTombTime = nCurrentTime
      mod:AddMsg("TOMB", "ICE TOMB", 5, mod:GetSetting("SoundIceTomb") and "Alert", "Blue")
      mod:AddTimerBar("TOMB", "Next ice tomb", 15)
    end
    core:AddUnit(unit)
  end
end

function mod:OnFlameWaveCreated(id, unit, name)
  if mod:GetSetting("LineFlameWaves") then
    core:AddSimpleLine(id, unit, nil, 20, nil, 10, "Green")
  end
end

mod:RegisterUnitEvents("Flame Wave", {
    [core.E.UNIT_CREATED] = mod.OnFlameWaveCreated,
  }
)

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  local tUnit = GetUnitById(nId)
  local sUnitName = tUnit:GetName()

  if nSpellId == DEBUFFID_FIREBOMB then
    if mod:GetSetting("OtherBombPlayerMarkers") then
      core:MarkUnit(tUnit, nil, self.L["Fire Bomb"])
    end
    core:AddUnit(tUnit)
    tFireBombPlayersList[sUnitName] = tUnit
    if nId == playerUnit:GetId() then
      mod:AddMsg("BOMB", "BOMBS ON YOU!", 5, mod:GetSetting("SoundBomb") and "RunAway")
      if mod:GetSetting("LineBombPlayers") then
        self:ScheduleTimer("ApplyBombLines", 1, "fire")
      end
    end
    self:ScheduleTimer("RemoveBombMarker", 10, "fire", tUnit)
  elseif nSpellId == DEBUFFID_FROSTBOMB then
    if mod:GetSetting("OtherBombPlayerMarkers") then
      core:MarkUnit(tUnit, nil, self.L["Frost Bomb"])
    end
    core:AddUnit(tUnit)
    tFrostBombPlayersList[sUnitName] = tUnit
    if nId == playerUnit:GetId() then
      mod:AddMsg("BOMB", "BOMBS ON YOU!", 5, mod:GetSetting("SoundBomb") and "RunAway")
      if mod:GetSetting("LineBombPlayers") then
        self:ScheduleTimer("ApplyBombLines", 1, "frost")
      end
    end
    self:ScheduleTimer("RemoveBombMarker", 10, "frost", tUnit)
  elseif nSpellId == DEBUFFID_ICE_TOMB then
    if mod:GetSetting("LineIceTomb") and self:GetDistanceBetweenUnits(playerUnit, tUnit) < 45 then
      core:AddLineBetweenUnits(nId .. "_TOMB", playerUnit, tUnit, 5, "Blue")
    end
  end

  if nSpellId == DEBUFFID_FIREBOMB or nSpellId == DEBUFFID_FROSTBOMB then
    local nCurrentTime = GetGameTime()
    if nCurrentTime - nLastBombTime > 10 then
      nLastBombTime = nCurrentTime
      mod:AddTimerBar("BOMBS", "Next bombs", 30)
      mod:AddTimerBar("BEXPLODE", "Bomb explosion", 10, mod:GetSetting("SoundBomb"))
    end
  end
end

function mod:OnStacksUpdate(nId, nSpellId, nStack, fTimeRemaining)
  if nStack >= 10 and nId == playerUnit:GetId() then
    if nStack > lastStack then -- Stacks dropping off
      local sMessage = self.L["%d STACKS!"]:format(nStack)
      mod:AddMsg("STACK", sMessage, 5, mod:GetSetting("SoundHighDebuffStacks") and "Beware")
    end
    lastStack = nStack
  end
end

mod:RegisterUnitEvents(core.E.ALL_UNITS, {
    [core.E.DEBUFF_UPDATE] = {
      [DEBUFFID_DRENCHED] = mod.OnStacksUpdate,
      [DEBUFFID_ENGULFED] = mod.OnStacksUpdate,
    }
  }
)

function mod:OnDebuffRemove(nId, nSpellId)
  local tUnit = GetUnitById(nId)

  if nSpellId == DEBUFFID_FIREBOMB then
    mod:RemoveBombMarker("fire", tUnit)
  elseif nSpellId == DEBUFFID_FROSTBOMB then
    mod:RemoveBombMarker("frost", tUnit)
  elseif nSpellId == DEBUFFID_ICE_TOMB then
    core:RemoveLineBetweenUnits(nId .. "_TOMB")
  end
end
