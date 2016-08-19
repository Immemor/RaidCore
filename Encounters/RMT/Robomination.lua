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
    --Datachron
    ["Robomination tries to crush"] = "Robomination tries to crush",
    ["The Robomination sinks down into the trash"] = "The Robomination sinks down into the trash",
    ["The Robomination erupts back into the fight"] = "The Robomination erupts back into the fight",
    --Message bars
    ["SNAKE ON %s"] = "SNAKE ON %s",
    ["SNAKE ON YOU"] = "SNAKE ON YOU",
    ["SNAKE NEAR YOU ON %s"] = "SNAKE NEAR YOU ON %s",
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
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local GetPlayerUnit = GameLib.GetPlayerUnit
local phase
----------------------------------------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("CrosshairSnake")
mod:RegisterDefaultSetting("SoundSnake")
mod:RegisterDefaultSetting("SoundSnakeNear")
mod:RegisterDefaultSetting("SoundPhaseChange")
mod:RegisterDefaultSetting("SoundPhaseChangeClose")

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
  phase = DPS_PHASE
  mod:AddTimerBar("ARMS_TIMER", "Arms spawning in", 45)
  mod:AddTimerBar("NEXT_SNAKE_TIMER", "Next snake in", FIRST_SNAKE_TIMER)
end

function mod:OnDatachron(sMessage)
  --The Robomination tries to incinerate x
  if sMessage:find(self.L["Robomination tries to crush"]) then
    local sSnakeTarget = GetPlayerUnitByName(string.match(sMessage, self.L["Robomination tries to crush"].." ".."([^%s]+%s[^!]+)!$"))
    local bIsOnMyself = sSnakeTarget == GetPlayerUnit()
    local bSnakeNearYou = not bIsOnMyself and mod:GetDistanceBetweenUnits(GetPlayerUnit(), sSnakeTarget) < 7.5
    local sSound = "RunAway"
    local sSnakeOnX = ""
    if bIsOnMyself then
      sSound = mod:GetSetting("SoundSnake") and sSound
      sSnakeOnX = self.L["SNAKE ON YOU"]
    elseif bSnakeNearYou then
      sSound = mod:GetSetting("SoundSnakeNear") and sSound
      sSnakeOnX = self.L["SNAKE NEAR YOU ON %s"]:format(sSnakeTarget:GetName())
    else
      sSnakeOnX = self.L["SNAKE ON %s"]:format(sSnakeTarget:GetName())
    end
    -- mod:AddTimerBar("SNAKE_TIMER", sSnakeOnX, 11)
    core:AddPicture("SNAKE_CROSSHAIR", sSnakeTarget:GetId(), "Crosshair", 20)

    mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
    mod:AddTimerBar("NEXT_SNAKE_TIMER", "Next snake in", SNAKE_TIMER)
    mod:AddMsg("SNAKE_MSG", sSnakeOnX, 5, sSound, "Blue")
  elseif self.L["The Robomination sinks down into the trash"] == sMessage then
    phase = MAZE_PHASE
    core:RemoveMsg("ROBO_MAZE")
    mod:RemoveTimerBar("NEXT_SNAKE_TIMER")
    mod:AddMsg("ROBO_MAZE", "RUN TO THE CENTER !", 5, mod:GetSetting("SoundSnakeNear") and "Info")
  elseif self.L["The Robomination erupts back into the fight"] == sMessage then
    phase = DPS_PHASE
    mod:AddTimerBar("NEXT_SNAKE_TIMER", "Next snake in", FIRST_SNAKE_TIMER)
    mod:AddTimerBar("NEXT_INCINERATE_TIMER", "Next incinerate in", FIRST_INCINERATE_TIMER)
  end
end

function mod:OnUnitCreated (nId, tUnit, sName)

end

-- function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
-- if nSpellId == DEBUFF_SNAKE then
-- core:AddPicture("SNAKE_CROSSHAIR", nId, "Crosshair", 20)
-- end
-- end

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
  }
)

-- mod:RegisterUnitEvents("Trash Compactor",{
-- ["OnUnitCreated"] = function (self, nId, tUnit, sName)
-- core:WatchUnit(tUnit)
-- core:AddPolygon(nId, nId, 7.5, 45, 6, "Green", 4)
-- end,
-- }
-- )
