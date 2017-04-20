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
local mod = core:NewEncounter("Kuralak", 67, 147, 148)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Kuralak the Defiler" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Kuralak the Defiler"] = "Kuralak the Defiler",
    -- Datachron messages.
    ["Kuralak the Defiler returns to the Archive Core"] = "Kuralak the Defiler returns to the Archive Core",
    ["Kuralak the Defiler causes a violent outbreak of corruption"] = "Kuralak the Defiler causes a violent outbreak of corruption",
    ["The corruption begins to fester"] = "The corruption begins to fester",
    ["has been anesthetized"] = "has been anesthetized",
    -- Cast.
    ["Vanish into Darkness"] = "Vanish into Darkness",
    ["Chromosome Corruption"] = "Chromosome Corruption",
    -- Bar and messages.
    ["Next outbreak"] = "Next outbreak",
    ["Next eggs"] = "Next eggs",
    ["Next switch tank"] = "Next switch tank",
    ["Next vanish"] = "Next vanish",
    ["P2 SOON !"] = "P2 SOON !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["VANISH"] = "VANISH",
    ["OUTBREAK"] = "OUTBREAK",
    ["EGGS"] = "EGGS",
    ["SWITCH TANK"] = "SWITCH TANK",
    ["MARKER north"] = "North",
    ["MARKER south"] = "South",
    ["MARKER east"] = "Est",
    ["MARKER west"] = "West",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Kuralak the Defiler"] = "Kuralak la Profanatrice",
    -- Datachron messages.
    ["Kuralak the Defiler returns to the Archive Core"] = "Kuralak la Profanatrice retourne au Noyau d'accès aux archives pour reprendre des forces",
    ["Kuralak the Defiler causes a violent outbreak of corruption"] = "Kuralak la Profanatrice provoque une violente éruption de Corruption",
    ["The corruption begins to fester"] = "La Corruption commence à se répandre",
    ["has been anesthetized"] = "est sous anesthésie",
    -- Cast.
    ["Vanish into Darkness"] = "Disparaître dans les ténèbres",
    ["Chromosome Corruption"] = "Corruption chromosomique",
    -- Bar and messages.
    ["Next outbreak"] = "Prochaine invasion",
    ["Next eggs"] = "Prochain oeufs",
    ["Next switch tank"] = "Prochain changement de tank",
    ["Next vanish"] = "Prochaine disparition",
    ["P2 SOON !"] = "P2 PROCHE !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["VANISH"] = "DISPARITION",
    ["OUTBREAK"] = "INVASION",
    ["EGGS"] = "OEUFS",
    ["SWITCH TANK"] = "CHANGEMENT TANK",
    ["MARKER north"] = "Nord",
    ["MARKER south"] = "Sud",
    ["MARKER east"] = "Est",
    ["MARKER west"] = "Ouest",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Kuralak the Defiler"] = "Kuralak die Schänderin",
    -- Datachron messages.
    ["Kuralak the Defiler returns to the Archive Core"] = "Kuralak die Schänderin kehrt zum Archivkern zurück",
    ["Kuralak the Defiler causes a violent outbreak of corruption"] = "Kuralak die Schänderin verursacht einen heftigen Ausbruch der Korrumpierung",
    ["The corruption begins to fester"] = "Die Korrumpierung beginnt zu eitern",
    ["has been anesthetized"] = "wurde narkotisiert",
    -- Cast.
    ["Vanish into Darkness"] = "In der Dunkelheit verschwinden",
    -- Bar and messages.
    ["Next outbreak"] = "Das nächste ausbruch",
    ["Next eggs"] = "Das nächste eier",
    ["Next switch tank"] = "Das nächste tankwechsel",
    ["Next vanish"] = "Das nächste Verschwinden",
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["VANISH"] = "VERSCHWINDEN",
    ["OUTBREAK"] = "AUSBRUCH",
    ["EGGS"] = "EIER",
    ["SWITCH TANK"] = "AGGRO ZIEHEN !!!",
    ["MARKER north"] = "Norden",
    ["MARKER south"] = "Süden",
    ["MARKER east"] = "Osten",
    ["MARKER west"] = "Westen",
  })
-- Default settings.
mod:RegisterDefaultSetting("PictureCorruption")
mod:RegisterDefaultSetting("SoundOutbreak")
mod:RegisterDefaultSetting("SoundSiphon")
mod:RegisterDefaultSetting("SoundVanish")
mod:RegisterDefaultSetting("SoundPhase2Switch")
mod:RegisterDefaultSetting("OtherPillarMarkers")
mod:RegisterDefaultSetting("OtherRecommendedPositions")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["EGGS"] = { sColor = "xkcdOrangered" },
    ["VANISH"] = { sColor = "xkcdReddishPink" },
    ["OUTBREAK"] = { sColor = "xkcdBlueyGreen" },
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- A player have incubation when he is transform in egg.
local DEBUFFID_INCUBATION = 58564
-- Chromosome corruption is when a player is twice powerfull, and have a dot.
local DEBUFFID_CHROMOSOME_CORRUPTION = 56652
-- Pillar Markers.
local PILLAR_POSITIONS = {
  ["EST"] = { x = 194.44, y = -110.80, z = -483.20 },
  ["SOUTH"] = { x = 165.79, y = -110.80, z = -464.84 },
  ["WEST"] = { x = 144.20, y = -110.80, z = -494.38 },
  ["NORTH"] = { x = 175.00, y = -110.80, z = -513.31 },
}

-- TODO: Set values when found.
local EGG_BEST_POSITIONS

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local tCorruptedPlayerList
local bIsPhase2

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  tCorruptedPlayerList = {}
  bIsPhase2 = false
  -- TODO: Remove this init, when values will be found.
  EGG_BEST_POSITIONS = nil
  if mod:GetSetting("OtherPillarMarkers") then
    core:SetWorldMarker("EAST", self.L["MARKER east"], PILLAR_POSITIONS["EST"])
    core:SetWorldMarker("SOUTH", self.L["MARKER south"], PILLAR_POSITIONS["SOUTH"])
    core:SetWorldMarker("WEST", self.L["MARKER west"], PILLAR_POSITIONS["WEST"])
    core:SetWorldMarker("NORTH", self.L["MARKER north"], PILLAR_POSITIONS["NORTH"])
  end
end

function mod:OnUnitCreated(nId, tUnit, sName)
  local nHealth = tUnit:GetHealth()
  if sName == self.L["Kuralak the Defiler"] then
    if nHealth then
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
      -- TODO: Remove this init, when values will be found.
      if EGG_BEST_POSITIONS == nil then
        local tPosition = tUnit:GetPosition()
        local nDistance = 9.5
        local tRad = { 0, 180, 90, 270, 45, 135, 225, 315 }
        EGG_BEST_POSITIONS = {}
        for i = 1, #tRad do
          local nRad = math.rad(tRad[i])
          EGG_BEST_POSITIONS[i] = {
            x = tPosition.x + math.cos(nRad) * nDistance,
            y = tPosition.y,
            z = tPosition.z - math.sin(nRad) * nDistance,
          }
        end
      end
    end
  end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
  if sName == self.L["Kuralak the Defiler"] then
    if nPourcent == 74 then
      mod:AddMsg("P2", "P2 SOON !", 5, mod:GetSetting("SoundPhase2Switch") and "Info")
    end
  end
end

function mod:RemoveEggBestPosition()
  for i, nId in ipairs(tCorruptedPlayerList) do
    core:RemoveLineBetweenUnits(nId)
  end
end

function mod:DisplayEggBestPosition()
  if mod:GetSetting("OtherRecommendedPositions") then
    local nIdPlayer = GetPlayerUnit():GetId()
    for i, nId in ipairs(tCorruptedPlayerList) do
      if EGG_BEST_POSITIONS[i] then
        local sColor = nIdPlayer == nId and "red" or "800000ff"
        core:AddLineBetweenUnits(nId, nId, EGG_BEST_POSITIONS[i], 4, sColor)
      end
    end
    mod:ScheduleTimer("RemoveEggBestPosition", 7)
  end
end

function mod:OnDatachron(sMessage)
  if sMessage:find(self.L["Kuralak the Defiler returns to the Archive Core"]) then
    mod:AddMsg("VANISH", "VANISH", 3, mod:GetSetting("SoundVanish") and "Alert")
    mod:AddTimerBar("VANISH", "Next vanish", 47)
  elseif sMessage:find(self.L["Kuralak the Defiler causes a violent outbreak of corruption"]) then
    mod:AddMsg("OUTBREAK", "OUTBREAK", 3, "RunAway")
    mod:AddTimerBar("OUTBREAK", "Next outbreak", 45, mod:GetSetting("SoundOutbreak"))
  elseif sMessage:find(self.L["The corruption begins to fester"]) then
    mod:AddMsg("EGGS", "EGGS", 5, "Alert")
    mod:AddTimerBar("EGGS", "Next eggs", 66)
    mod:DisplayEggBestPosition()
  elseif sMessage:find(self.L["has been anesthetized"]) then
    if mod:IsPlayerTank() then
      mod:AddMsg("SIPHON", "SWITCH TANK", 5, mod:GetSetting("SoundSiphon") and "Alarm")
    end
    mod:AddTimerBar("SIPHON", "Next switch tank", 88)
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if self.L["Kuralak the Defiler"] == sName then
    if self.L["Chromosome Corruption"] == sCastName then
      if not bIsPhase2 then
        bIsPhase2 = true
        core:RemoveTimerBar("VANISH")
        mod:AddMsg("KP2", "PHASE 2 !", 3, mod:GetSetting("SoundPhase2Switch") and "Long")
        mod:AddTimerBar("OUTBREAK", "Next outbreak", 15)
        mod:AddTimerBar("EGGS", "Next eggs", 73)
        mod:AddTimerBar("SIPHON", "Next switch tank", 37)
        if mod:GetSetting("OtherRecommendedPositions") then
          for i, vector in next, EGG_BEST_POSITIONS do
            core:SetWorldMarker("EggBest" .. i, i, vector)
          end
        end
      end
    end
  end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  if DEBUFFID_CHROMOSOME_CORRUPTION == nSpellId then
    table.insert(tCorruptedPlayerList, nId)
    if mod:GetSetting("PictureCorruption") then
      core:AddPicture(nId, nId, "Crosshair", 30)
    end
  elseif DEBUFFID_INCUBATION == nSpellId then
    mod:RemoveEggBestPosition()
  end
end

function mod:OnDebuffRemove(nId, nSpellId)
  if nSpellId == DEBUFFID_CHROMOSOME_CORRUPTION then
    core:RemovePicture(nId)
    for i, nPlayerId in next, tCorruptedPlayerList do
      if nPlayerId == nId then
        core:RemoveLineBetweenUnits(nId)
        table.remove(tCorruptedPlayerList, i)
        break
      end
    end
  end
end
