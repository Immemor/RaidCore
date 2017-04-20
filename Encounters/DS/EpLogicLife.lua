---------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Description:
-- Elemental Pair after the Logic wings.
---------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"
local Unit = require "Unit"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("EpLogicLife", 52, 98, 119)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "Mnemesis", "Visceralus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Essence of Life"] = "Essence of Life",
    ["Essence of Logic"] = "Essence of Logic",
    ["Alphanumeric Hash"] = "Alphanumeric Hash",
    ["Life Force"] = "Life Force",
    ["Wild Brambles"] = "Wild Brambles",
    ["Mnemesis"] = "Mnemesis",
    ["Visceralus"] = "Visceralus",
    -- Datachron messages.
    ["Time to die, sapients!"] = "Time to die, sapients!",
    -- Cast.
    ["Blinding Light"] = "Blinding Light",
    ["Defragment"] = "Defragment",
    -- Timer bars.
    ["Next defragment"] = "Next defragment",
    ["Next thorns"] = "Next thorns",
    ["Avatus incoming"] = "Avatus incoming",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["SPREAD"] = "SPREAD",
    ["No-Healing Debuff!"] = "No-Healing Debuff!",
    ["SNAKE ON YOU!"] = "SNAKE ON YOU!",
    ["SNAKE ON %s!"] = "SNAKE ON %s!",
    ["MARKER North"] = "North",
    ["MARKER South"] = "South",
    ["MARKER East"] = "East",
    ["MARKER West"] = "West",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Essence of Life"] = "Essence de vie",
    ["Essence of Logic"] = "Essence de logique",
    ["Alphanumeric Hash"] = "Alphanumeric Hash",
    ["Life Force"] = "Force vitale",
    ["Wild Brambles"] = "Ronces sauvages",
    ["Mnemesis"] = "Mnémésis",
    ["Visceralus"] = "Visceralus",
    -- Datachron messages.
    ["Time to die, sapients!"] = "Maintenant c'est l'heure de mourir, misérables !",
    -- Cast.
    ["Blinding Light"] = "Lumière aveuglante",
    ["Defragment"] = "Défragmentation",
    -- Timer bars.
    ["Next defragment"] = "Prochaine defragmentation",
    ["Next thorns"] = "Prochaine épine",
    ["Avatus incoming"] = "Avatus arrivé",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["SPREAD"] = "SEPAREZ-VOUS",
    ["No-Healing Debuff!"] = "No-Healing Debuff!",
    ["SNAKE ON YOU!"] = "SERPENT SUR VOUS!",
    ["SNAKE ON %s!"] = "SERPENT SUR %s!",
    ["MARKER North"] = "Nord",
    ["MARKER South"] = "Sud",
    ["MARKER East"] = "Est",
    ["MARKER West"] = "Ouest",
  })
mod:RegisterGermanLocale({
    -- Unit names.
    ["Essence of Life"] = "Lebensessenz",
    ["Essence of Logic"] = "Logikessenz",
    ["Alphanumeric Hash"] = "Alphanumerische Raute",
    ["Life Force"] = "Lebenskraft",
    ["Mnemesis"] = "Mnemesis",
    ["Visceralus"] = "Viszeralus",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blendendes Licht",
    ["Defragment"] = "Defragmentieren",
    -- Timer bars.
    -- Message bars.
    ["MARKER North"] = "N",
    ["MARKER South"] = "S",
    ["MARKER East"] = "O",
    ["MARKER West"] = "W",
  })
-- Default settings.
mod:RegisterDefaultSetting("SoundSnakeOnYou")
mod:RegisterDefaultSetting("SoundSnakeOnOther")
mod:RegisterDefaultSetting("SoundNoHealDebuff")
mod:RegisterDefaultSetting("SoundBlindingLight")
mod:RegisterDefaultSetting("SoundDefrag")
mod:RegisterDefaultSetting("SoundEnrageCountDown")
mod:RegisterDefaultSetting("OtherSnakePlayerMarkers")
mod:RegisterDefaultSetting("OtherNoHealDebuffPlayerMarkers")
mod:RegisterDefaultSetting("OtherRootedPlayersMarkers")
mod:RegisterDefaultSetting("OtherDirectionMarkers")
mod:RegisterDefaultSetting("LineTetrisBlocks")
mod:RegisterDefaultSetting("LineLifeOrbs")
mod:RegisterDefaultSetting("LineCleaveVisceralus")
mod:RegisterDefaultSetting("PolygonDefrag")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["DEFRAG"] = { sColor = "xkcdAlgaeGreen" },
    ["THORNS"] = { sColor = "xkcdAlgaeGreen" },
    ["AVATUS_INCOMING"] = { sColor = "xkcdAmethyst" },
    ["ENRAGE"] = { sColor = "xkcdBloodRed" },
  })

---------------------------------------------------------------------------------------------------
-- Constants.
---------------------------------------------------------------------------------------------------
local DEBUFF__SNAKE_SNACK = 74570
local DEBUFF__THORNS = 75031
local DEBUFF__LIFE_FORCE_SHACKLE = 74366
local MID_POSITIONS = {
  ["north"] = { x = 9741.53, y = -518, z = 17823.81 },
  ["west"] = { x = 9691.53, y = -518, z = 17873.81 },
  ["south"] = { x = 9741.53, y = -518, z = 17923.81 },
  ["east"] = { x = 9791.53, y = -518, z = 17873.81 },
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local bIsMidPhase = false
local nLastThornsTime

---------------------------------------------------------------------------------------------------
-- Encounter description.
---------------------------------------------------------------------------------------------------

function mod:OnBossEnable()
  bIsMidPhase = false
  nLastThornsTime = 0

  mod:AddTimerBar("DEFRAG", "Next defragment", 21, mod:GetSetting("SoundDefrag"))
  mod:AddTimerBar("AVATUS_INCOMING", "Avatus incoming", 480, mod:GetSetting("SoundEnrageCountDown"))
end

function mod:OnDatachron(sMessage)
  if self.L["Time to die, sapients!"] == sMessage then
    mod:RemoveTimerBar("AVATUS_INCOMING")
    mod:AddTimerBar("ENRAGE", "Enrage", 34)
  end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
  local tUnit = GetUnitById(nId)
  if DEBUFF__SNAKE_SNACK == nSpellId then
    local sName = tUnit:GetName()
    if tUnit == GetPlayerUnit() then
      mod:AddMsg("SNAKE", "SNAKE ON YOU!", 5, mod:GetSetting("SoundSnakeOnYou") and "RunAway")
    else
      mod:AddMsg("SNAKE", self.L["SNAKE ON %s!"]:format(sName), 5, mod:GetSetting("SoundSnakeOnOther") and "Info")
    end
    if mod:GetSetting("OtherSnakePlayerMarkers") then
      core:AddPicture(("SNAKE_TARGET_%d"):format(nId), nId, "Crosshair", 40, nil, nil, nil, "red")
    end
  elseif DEBUFF__LIFE_FORCE_SHACKLE == nSpellId then
    if mod:GetSetting("OtherNoHealDebuffPlayerMarkers") then
      mod:AddSpell2Dispel(nId, DEBUFF__LIFE_FORCE_SHACKLE)
    end
    if tUnit == GetPlayerUnit() then
      mod:AddMsg("NOHEAL", "No-Healing Debuff!", 5, mod:GetSetting("SoundNoHealDebuff") and "Alarm")
    end
  elseif DEBUFF__THORNS == nSpellId then
    if mod:GetSetting("OtherRootedPlayersMarkers") then
      mod:AddSpell2Dispel(nId, DEBUFF__THORNS)
    end
  end
end

function mod:OnDebuffRemove(nId, nSpellId)
  if DEBUFF__SNAKE_SNACK == nSpellId then
    core:RemovePicture(("SNAKE_TARGET_%d"):format(nId))
  elseif DEBUFF__LIFE_FORCE_SHACKLE == nSpellId then
    mod:RemoveSpell2Dispel(nId, DEBUFF__LIFE_FORCE_SHACKLE)
  elseif DEBUFF__THORNS == nSpellId then
    mod:RemoveSpell2Dispel(nId, DEBUFF__THORNS)
  end
end

function mod:OnUnitCreated(nId, tUnit, sName)
  local nHealth = tUnit:GetHealth()
  local nCurrentTime = GetGameTime()

  if sName == self.L["Visceralus"] then
    if nHealth then
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit, core.E.TRACK_CASTS)
      if mod:GetSetting("LineCleaveVisceralus") then
        core:AddSimpleLine("Visc1", nId, 0, 25, 0, 4, "blue", 10)
        core:AddSimpleLine("Visc2", nId, 0, 25, 72, 4, "green", 20)
        core:AddSimpleLine("Visc3", nId, 0, 25, 144, 4, "green", 20)
        core:AddSimpleLine("Visc4", nId, 0, 25, 216, 4, "green", 20)
        core:AddSimpleLine("Visc5", nId, 0, 25, 288, 4, "green", 20)
      end
    end
  elseif sName == self.L["Mnemesis"] then
    if nHealth then
      core:WatchUnit(tUnit, core.E.TRACK_CASTS)
      core:AddUnit(tUnit)
    end
  elseif sName == self.L["Essence of Life"] then
    core:AddUnit(tUnit)
    if not bIsMidPhase then
      bIsMidPhase = true
      if mod:GetSetting("OtherDirectionMarkers") then
        core:SetWorldMarker("NORTH", self.L["MARKER North"], MID_POSITIONS["north"])
        core:SetWorldMarker("EAST", self.L["MARKER East"], MID_POSITIONS["east"])
        core:SetWorldMarker("SOUTH", self.L["MARKER South"], MID_POSITIONS["south"])
        core:SetWorldMarker("WEST", self.L["MARKER West"], MID_POSITIONS["west"])
      end
      core:RemoveTimerBar("DEFRAG")
      core:RemoveTimerBar("THORNS")
    end
  elseif sName == self.L["Essence of Logic"] then
    core:AddUnit(tUnit)
  elseif sName == self.L["Alphanumeric Hash"] then
    if mod:GetSetting("LineTetrisBlocks") then
      core:AddSimpleLine(nId, nId, 0, 20, 0, 10, "red")
    end
  elseif sName == self.L["Life Force"] and mod:GetSetting("LineLifeOrbs") then
    core:AddSimpleLine(nId, tUnit, nil, 15, nil, 3, "Blue")
  elseif sName == self.L["Wild Brambles"] then
    if nLastThornsTime + 5 < nCurrentTime then
      nLastThornsTime = nCurrentTime
      mod:AddTimerBar("THORNS", "Next thorns", 30)
    end
  end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
  if sName == self.L["Essence of Logic"] then
    bIsMidPhase = false
    core:ResetWorldMarkers()
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  local tUnit = GetUnitById(nId)

  if self.L["Visceralus"] == sName then
    if self.L["Blinding Light"] == sCastName then
      if self:GetDistanceBetweenUnits(tUnit, GetPlayerUnit()) < 33 then
        mod:AddMsg("BLIND", "Blinding Light", 5, mod:GetSetting("SoundBlindingLight") and "Beware")
      end
    end
  elseif self.L["Mnemesis"] == sName then
    if self.L["Defragment"] == sCastName then
      mod:AddMsg("DEFRAG", "SPREAD", 3, mod:GetSetting("SoundDefrag") and "Alarm")
      mod:AddTimerBar("DEFRAG", "Next defragment", 50, mod:GetSetting("SoundDefrag"))
      if mod:GetSetting("PolygonDefrag") then
        core:AddPolygon("DEFRAG_SQUARE", GetPlayerUnit():GetId(), 13, 0, 4, "xkcdBloodOrange", 4)
        local nRepeatingTimerId = self:ScheduleRepeatingTimer(function(tMnemesisUnit)
            local square = core:GetPolygon("DEFRAG_SQUARE")
            local bIsMOO = tMnemesisUnit:IsInCCState(Unit.CodeEnumCCState.Vulnerability)
            if square and bIsMOO then
              square:SetColor("8000ff00")
            end
            end, 1, tUnit)
          self:ScheduleTimer(function(SquareRepeatingTimerId)
              core:RemovePolygon("DEFRAG_SQUARE")
              self:CancelTimer(SquareRepeatingTimerId)
              end, 10, nRepeatingTimerId)
          end
        end
      end
    end
