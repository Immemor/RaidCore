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
local Vector3 = require "Vector3"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("PhageMaw", 67, 147, 149)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Phage Maw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Phage Maw"] = "Phage Maw",
    ["Detonation Bomb"] = "Detonation Bomb",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "The augmented shield has been destroyed",
    ["Phage Maw begins charging an orbital strike"] = "Phage Maw begins charging an orbital strike",
    -- Timer bars.
    ["Bombs wave #1"] = "Bombs wave #1",
    ["Bombs wave #2"] = "Bombs wave #2",
    ["Bombs wave #3"] = "Bombs wave #3",
    ["Timeout all bombs!"] = "Timeout all bombs!",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Phage Maw"] = "Phagegueule",
    ["Detonation Bomb"] = "Bombe à détonateur",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "Le bouclier augmenté a été détruit",
    ["Phage Maw begins charging an orbital strike"] = "La Méga Gueule d'acier commence à charger une frappe orbitale",
    -- Timer bars.
    ["Bombs wave #1"] = "Vague de bombes n°1",
    ["Bombs wave #2"] = "Vague de bombes n°2",
    ["Bombs wave #3"] = "Vague de bombes n°3",
    ["Timeout all bombs!"] = "Timeout toutes les bombes!",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Phage Maw"] = "Phagenschlund",
    ["Detonation Bomb"] = "Sprengbombe",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "Der augmentierte Schild wurde zerstört",
    ["Phage Maw begins charging an orbital strike"] = "Phagenschlund beginnt einen Orbitalschlag aufzuladen",
  })
-- Default settings.
mod:RegisterDefaultSetting("OtherBombsMarkers")
mod:RegisterDefaultSetting("PillarNumber")
mod:RegisterDefaultSetting("LineBombs")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BombsWave1"] = { sColor = "xkcdBarneyPurple" },
    ["BombsWave2"] = { sColor = "xkcdBluePurple" },
    ["BombsWave3"] = { sColor = "xkcdDeepPurple" },
    ["TimeoutBombs"] = { sColor = "xkcdBloodRed" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
--TODO: Set the correct coordonate!
local GROUND_Y = -800.51
local PILLAR_POSITIONS = {
  ["P1"] = Vector3.New(1234.56, GROUND_Y, 896.48),
  ["P2"] = Vector3.New(1268.17, GROUND_Y, 838.32),
  ["P3"] = Vector3.New(1301.67, GROUND_Y, 896.48),
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  if self:GetSetting("PillarNumber") then
    for n, vector in next, PILLAR_POSITIONS do
      -- core:SetWorldMarker(n, n, vector)
    end
  end
end

function mod:OnUnitCreated(nId, unit, sName)
  local nPlayerId = GetPlayerUnit():GetId()

  if sName == self.L["Phage Maw"] then
    core:AddUnit(unit)
    core:WatchUnit(unit)
  elseif sName == self.L["Detonation Bomb"] then
    if mod:GetSetting("OtherBombsMarkers") then
      core:MarkUnit(unit, 1)
      core:AddUnit(unit)
    end
    if mod:GetSetting("LineBombs") then
      local o = core:AddLineBetweenUnits("Bomb" .. nId, nPlayerId, nId, nil, "xkcdBrightLightGreen")
      o:SetMaxLengthVisible(40)
    end
  end
end

function mod:OnDatachron(sMessage)
  if sMessage:find(self.L["The augmented shield has been destroyed"]) then
    mod:AddTimerBar("BombsWave1", "Bombs wave #1", 20)
    mod:AddTimerBar("BombsWave2", "Bombs wave #2", 49)
    mod:AddTimerBar("BombsWave3", "Bombs wave #3", 78)
    mod:AddTimerBar("TimeoutBombs", "Timeout all bombs!", 104)
  elseif sMessage:find(self.L["Phage Maw begins charging an orbital strike"]) then
    if mod:GetSetting("OtherBombsMarkers") then
      core:ResetMarks()
    end
  end
end
