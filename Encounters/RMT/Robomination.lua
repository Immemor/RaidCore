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
local mod = core:NewEncounter("Robomination", 104, {548, 0}, {551, 548})
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Robomination" })
mod:RegisterEnglishLocale({
    --Unit names.
    ["Robomination"] = "Robomination",
    ["Trash Compactor"] = "Trash Compactor",
    ["Cannon Arm"] = "Cannon Arm",
    ["Flailing Arm"] = "Flailing Arm",
    --Casts
    ["Cannon Fire"] = "Cannon Fire",
    ["Incineration Laser"] = "Incineration Laser",
    ["Noxious Belch"] = "Noxious Belch",
    --Datachron
    ["Robomination tries to crush"] = "Robomination tries to crush",
    ["The Robomination tries to incinerate"] = "The Robomination tries to incinerate",
    ["The Robomination sinks down into the trash."] = "The Robomination sinks down into the trash.",
    ["The Robomination erupts back into the fight!"] = "The Robomination erupts back into the fight!",
    --Message bars
    ["SNAKE ON %s"] = "SNAKE ON %s",
    ["SNAKE ON YOU"] = "SNAKE ON YOU",
    ["SNAKE NEAR YOU ON %s"] = "SNAKE NEAR YOU ON %s",
    ["Cannon arm spawned"] = "Cannon arm spawned",
    ["LASER ON %s"] = "LASER ON %s",
    ["LASER ON YOU"] = "LASER ON YOU",
  })
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)
local DEBUFF_SNAKE = 75126
local DPS_PHASE = 1
local MAZE_PHASE = 2
local FIRST_SNAKE_TIMER = 7.5
local SNAKE_TIMER = 17.5
local FIRST_INCINERATE_TIMER = 18.5
local INCINERATE_TIMER = 42.5
local COMPACTORS_EDGE = {
  { y = -203.4208984375, x = 0.71257400512695, z = -1349.8697509766 },
  { y = -203.4208984375, x = 10.955376625061, z = -1339.6927490234 },
  { y = -203.4208984375, x = -19.743923187256, z = -1339.6927490234 },
  { y = -203.4208984375, x = -9.5010261535645, z = -1349.8697509766 },
  { y = -203.4208984375, x = 0.71258544921875, z = -1319.4196777344 },
  { y = -203.4208984375, x = 10.955380439758, z = -1329.5698242188 },
  { y = -203.4208984375, x = -19.743919372559, z = -1329.5698242188 },
  { y = -203.4208984375, x = -9.5010147094727, z = -1319.4196777344 },
}
local COMPACTORS_CORNER = {
  { y = -203.4208984375, x = 10.955372810364, z = -1349.8697509766 },
  { y = -203.4208984375, x = -19.743927001953, z = -1349.8697509766 },
  { y = -203.4208984375, x = -19.743915557861, z = -1319.4196777344 },
  { y = -203.4208984375, x = 10.95538520813, z = -1319.4196777344 },
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local GetPlayerUnit = GameLib.GetPlayerUnit
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local phase
----------------------------------------------------------------------------------------------------
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CrosshairSnake")
mod:RegisterDefaultSetting("SoundSnake")
mod:RegisterDefaultSetting("SoundSnakeNear")
mod:RegisterDefaultSetting("SoundPhaseChange")
mod:RegisterDefaultSetting("SoundPhaseChangeClose")
mod:RegisterDefaultSetting("CompactorGridCorner")
mod:RegisterDefaultSetting("CompactorGridEdge", false)
mod:RegisterDefaultSetting("SoundArmSpawn")
mod:RegisterDefaultSetting("SoundCannonInterrupt")
mod:RegisterDefaultSetting("SoundLaser")
mod:RegisterDefaultSetting("CrosshairLaser")
mod:RegisterDefaultSetting("SoundSpew")
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  phase = DPS_PHASE
  mod:AddTimerBar("ARMS_TIMER", "Arms spawning in", 45)
  mod:AddTimerBar("NEXT_SNAKE_TIMER", "Next snake in", FIRST_SNAKE_TIMER)
  mod:DrawCompactorGrid()
end

mod:RegisterDatachronEvent("Robomination tries to crush", "FIND", function (self, sMessage)
    local sSnakeTarget = GetPlayerUnitByName(string.match(sMessage, self.L["Robomination tries to crush"].." ".."([^%s]+%s[^!]+)!$"))
    local bIsOnMyself = sSnakeTarget == GetPlayerUnit()
    local bSnakeNearYou = not bIsOnMyself and mod:GetDistanceBetweenUnits(GetPlayerUnit(), sSnakeTarget) < 10
    local sSound = "RunAway"
    local sSnakeOnX = ""
    if bIsOnMyself then
      sSound = mod:GetSetting("SoundSnake") and sSound
      sSnakeOnX = self.L["SNAKE ON YOU"]
    elseif bSnakeNearYou then
      sSound = mod:GetSetting("SoundSnakeNear") and sSound
      sSnakeOnX = self.L["SNAKE NEAR YOU ON %s"]:format(sSnakeTarget:GetName())
    else
      sSound = nil
      sSnakeOnX = self.L["SNAKE ON %s"]:format(sSnakeTarget:GetName())
    end

    if mod:GetSetting("CrosshairSnake") then
      core:AddPicture("SNAKE_CROSSHAIR", sSnakeTarget:GetId(), "Crosshair", 20)
    end

    mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
    mod:AddTimerBar("NEXT_SNAKE_TIMER", "Next snake in", SNAKE_TIMER)
    mod:AddMsg("SNAKE_MSG", sSnakeOnX, 5, sSound, "Blue")
  end
)

mod:RegisterDatachronEvent("The Robomination sinks down into the trash.", "MATCH", function (self, sMessage)
    phase = MAZE_PHASE
    core:RemoveMsg("ROBO_MAZE")
    mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
    mod:RemoveTimerBar("NEXT_INCINERATE_TIMER")
    mod:AddMsg("ROBO_MAZE", "RUN TO THE CENTER !", 5, mod:GetSetting("SoundSnakeNear") and "Info")
    mod:RemoveCompactorGrid()
  end
)

mod:RegisterDatachronEvent("The Robomination erupts back into the fight!", "MATCH", function (self, sMessage)
    phase = DPS_PHASE
    mod:AddTimerBar("NEXT_SNAKE_TIMER", "Next snake in", FIRST_SNAKE_TIMER)
    mod:AddTimerBar("NEXT_INCINERATE_TIMER", "Next incinerate in", FIRST_INCINERATE_TIMER)
    mod:DrawCompactorGrid()
  end
)

mod:RegisterDatachronEvent("Robomination tries to incinerate", "FIND", function (self, sMessage)
    local tLaserTarget = GetPlayerUnitByName(string.match(sMessage, self.L["Robomination tries to incinerate"].." ".."([^%s]+%s+)$"))
    local bIsOnMyself = sSnakeTarget == GetPlayerUnit()
    local sSound = mod:GetSetting("SoundLaser") == true and "Burn"
    local sLaserOnX = ""
    if bIsOnMyself then
      sLaserOnX = self.L["LASER ON YOU"]
    else
      sLaserOnX = self.L["LASER ON %s"]:format(sSnakeTarget:GetName())
    end

    if mod:GetSetting("CrosshairLaser") then
      core:AddPicture("LASER_CROSSHAIR", tLaserTarget:GetId(), "Crosshair", 30, 0, 0, nil, "Red")
    end

    mod:RemoveTimerBar("NEXT_INCINERATE_TIMER")
    mod:AddTimerBar("NEXT_INCINERATE_TIMER", "Next laser in", INCINERATE_TIMER, mod:GetSetting("SoundLaser"))
    mod:AddMsg("LASER_MSG", sLaserOnX, 5, sSound, "Red")
  end
)

function mod:DrawCompactorGrid()
  mod:HelperCompactorGrid(COMPACTORS_EDGE, false, true)
  mod:HelperCompactorGrid(COMPACTORS_CORNER, true, true)
end

function mod:RemoveCompactorGrid()
  mod:HelperCompactorGrid(COMPACTORS_EDGE, false, false)
  mod:HelperCompactorGrid(COMPACTORS_CORNER, true, false)
end

function mod:HelperCompactorGrid(compactors, isCorner, isAdding)
  local color = (isCorner == true and "Green") or "Red"
  local idString = (isCorner == true and "COMPACTOR_CORNER_%d") or "COMPACTOR_EDGE_%d"
  local setting = (isCorner == true and "CompactorGridCorner") or "CompactorGridEdge"
  if not mod:GetSetting(setting) then
    return
  end
  for i, position in pairs(compactors) do
    local id = string.format(idString, i)
    if isAdding then
      core:AddPolygon(id, position, 7, 45, 4, color, 4)
    else
      core:RemovePolygon(id)
    end
  end
end

function mod:OnDebuffRemove(nId, nSpellId, nStack, fTimeRemaining)
  if nSpellId == DEBUFF_SNAKE then
    core:RemovePicture("SNAKE_CROSSHAIR")
  end
end

mod:RegisterUnitEvents("Cannon Arm",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:WatchUnit(tUnit)
      if phase == DPS_PHASE then
        mod:AddTimerBar("ARMS_TIMER", "Arms spawning in", 45)
      end
      mod:AddMsg("ARMS_MSG", self.L["Cannon arm spawned"], 5, mod:GetSetting("SoundArmSpawn") == true and "Info", "Red")
    end,
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Cannon Fire"] == sCastName then
        mod:AddMsg("ARMS_MSG", "INTERRUPT CANNON!", 2, mod:GetSetting("SoundCannonInterrupt") == true and "Inferno")
      end
    end,
  }
)

mod:RegisterUnitEvents("Robomination",{
    ["OnUnitCreated"] = function (self, nId, tUnit, sName)
      core:AddUnit(tUnit)
      core:WatchUnit(tUnit)
    end,
    ["OnHealthChanged"] = function (self, nId, nPourcent, sName)
      if nPourcent >= 75.5 and nPourcent <= 76.5 then
        mod:AddMsg("ROBO_MAZE", "MAZE SOON !", 5, mod:GetSetting("SoundPhaseChangeClose") and "Info")
      end
    end,
    ["OnCastStart"] = function (self, nId, sCastName, nCastEndTime, sName)
      if self.L["Noxious Belch"] == sCastName then
        mod:AddMsg("SPEW_MSG", "Spew!", 4, mod:GetSetting("SoundSpew") == true and "Beware")
      end
    end,
    ["OnCastEnd"] = function (self, nId, sCastName, isInterrupted, nCastEndTime, sName)
      if self.L["Incineration Laser"] == sCastName then
        core:RemovePicture("LASER_CROSSHAIR")
      end
    end,
  }
)
