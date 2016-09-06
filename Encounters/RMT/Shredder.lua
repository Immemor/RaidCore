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
local mod = core:NewEncounter("Shredder", 104, 548, 549)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- TODO
----------------------------------------------------------------------------------------------------
--make tether visible, probably have to add rectangles to raidcore
--add phases are different later on

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Swabbie Ski'Li" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Swabbie Ski'Li"] = "Swabbie Ski'Li",
    ["Sawblade"] = "Sawblade", -- big saw
    ["Saw"] = "Saw", -- little saw
    ["Noxious Nabber"] = "Noxious Nabber",
    ["Risen Redmoon Grunt"] = "Risen Redmoon Grunt",
    ["Regor the Rancid"] = "Regor the Rancid",
    ["Braugh the Bloated"] = "Braugh the Bloated",
    ["Bilious Brute"] = "Bilious Brute",
    ["Putrid Pouncer"] = "Putrid Pouncer",
    ["Risen Redmoon Plunderer"] = "Risen Redmoon Plunderer",
    ["Risen Redmoon Cadet"] = "Risen Redmoon Cadet",
    ["Tether Anchor"] = "Tether Anchor",
    ["Junk Trap"] = "Junk Trap",
    -- Datachron messages.
    ["WARNING: THE SHREDDER IS STARTING!"] = "WARNING: THE SHREDDER IS STARTING!",
    -- Cast names.
    ["Swabbie Swoop"] = "Swabbie Swoop",
    ["Risen Repellent"] = "Risen Repellent",
    ["Crush"] = "Crush",
    ["Gravedigger"] = "Gravedigger",
    ["Deathwail"] = "Deathwail",
    ["Necrotic Lash"] = "Necrotic Lash",
    -- Messages.
    ["boss.knockback"] = "KNOCKBACK",
    ["boss.walking"] = "Walking %s",
    ["boss.walking.direction.north"] = "North",
    ["boss.walking.direction.south"] = "South",
    ["bile.stacks.amount"] = "%d BILE STACKS!",
    ["saw.middle"] = "SAW IN MIDDLE",
    ["saw.safe_spot"] = "SAFE SPOT %s",
    ["saw.safe_spot.left"] = "LEFT",
    ["saw.safe_spot.middle"] = "MIDDLE",
    ["saw.safe_spot.right"] = "RIGHT",
    ["adds.spawning"] = "ADDS SPAWNING",
    ["adds.next"] = "Next wave of adds spawning ...",
    ["nabber.spawned"] = "NOXIOUS NABBER SPAWNED",
    ["nabber.interrupt"] = "INTERRUPT NECROTIC LASH!",
    ["miniboss.spawned"] = "MINIBOSS SPAWNED",
    ["miniboss.interrupt"] = "INTERRUPT MINIBOSS!",
  })
----------------------------------------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("LineSawblade")
mod:RegisterDefaultSetting("SquareTethers")
mod:RegisterDefaultSetting("CrosshairAdds")
mod:RegisterDefaultSetting("CrosshairPriority")
mod:RegisterDefaultSetting("CrosshairTether")
mod:RegisterDefaultSetting("SoundAdds")
mod:RegisterDefaultSetting("SoundMiniboss")
mod:RegisterDefaultSetting("SoundNecroticLash")
mod:RegisterDefaultSetting("SoundMinibossCast")
mod:RegisterDefaultSetting("SoundOozeStacksWarning")
mod:RegisterDefaultSetting("SoundMidSawWarning")
mod:RegisterDefaultSetting("SoundSawSafeSpot")
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- circular array metatable
local function wrap(t, k)
  return ((k-1)%(#t))+1
end
local lmt = {
  __index = function(t, k)
    if type(k) == "number" then
      return rawget(t, wrap(t, k))
    else
      return nil
    end
  end
}
-- turns a table into a circular array
local function circular(t)
  return setmetatable(t, lmt)
end

-- Coordinates
local START_POSITION = Vector3.New({x = -20.054916381836,y = 597.66021728516,z = -809.42694091797})
local END_POSITION = Vector3.New({x = -20.499969482422,y = 597.88836669922,z = -973.21472167969})
local WALKING_DISTANCE = (END_POSITION-START_POSITION):Length()

-- Phases.
local WALKING = 0
local SHREDDER = 1
local ADD_PHASES = circular{ 11, 45, 66, 0 }

-- Spell ids.
local DEBUFF_OOZING_BILE = 84321

-- Saw stuff.
local WEST_POSITION = -42
local MIDDLE_WEST_POSITION = -28
local MIDDLE_EAST_POSITION = -14
local EAST_POSITION = 0
local SAW_WEST = 1
local SAW_MID = 2
local SAW_EAST = 4
local SAW_SAFESPOT = {
  [SAW_WEST + SAW_MID] = "saw.safe_spot.left",
  [SAW_WEST + SAW_EAST] = "saw.safe_spot.middle",
  [SAW_MID + SAW_EAST] = "saw.safe_spot.right",
}
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local phase
local addPhase
local previousAddPhase
local firstShredderSaw
local secondShredderSaw
local playerUnit
local startProgressBarTimer
----------------------------------------------------------------------------------------------------
-- Encounter description.
-----------------------------------------------------------------------------------------------------

function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  phase = WALKING
  addPhase = 4
  previousAddPhase = 0
  firstShredderSaw = nil
  secondShredderSaw = nil
end

function mod:OnDebuffUpdate(id, spellId, stack)
  if DEBUFF_OOZING_BILE == spellId then
    if playerUnit:GetId() == id and stack >= 8 then
      mod:AddMsg("OOZE_MSG", string.format(self.L["bile.stacks.amount"], stack), 5, stack == 8 and mod:GetSetting("SoundOozeStacksWarning") and "Beware")
    end
  end
end

function mod:GetWalkingProgress()
  local pos1
  local pos2
  if phase == WALKING then
    pos1 = Vector3.New(mod.swabbieUnit:GetPosition())
    pos2 = START_POSITION
  elseif phase == SHREDDER then
    pos1 = END_POSITION
    pos2 = Vector3.New(mod.swabbieUnit:GetPosition())
  end
  local walkedDistance = (pos1 - pos2):Length()
  local progress = (walkedDistance / WALKING_DISTANCE) * 100
  return progress
end

function mod:GetAddSpawnProgess()
  local currentProgress = mod:GetWalkingProgress() - previousAddPhase
  local waveSpawn = ADD_PHASES[addPhase] - previousAddPhase
  return (currentProgress/waveSpawn)*100
end

function mod:NextAddWave()
  if ADD_PHASES[addPhase] ~= 0 then
    mod:AddMsg("ADDS_MSG", self.L["adds.spawning"], 5, mod:GetSetting("SoundAdds") and "Info")
  end
  previousAddPhase = ADD_PHASES[addPhase]
  addPhase = addPhase + 1
  if ADD_PHASES[addPhase] ~= 0 then
    mod:AddProgressBar("ADDS_PROGRESS", self.L["adds.next"], mod.GetAddSpawnProgess, mod, mod.NextAddWave)
  end
end

function mod:PhaseChange()
  local text = self.L["boss.walking"]
  local walkingDirection
  if phase == SHREDDER then
    phase = WALKING
    walkingDirection = self.L["boss.walking.direction.north"]
    mod:NextAddWave()
  else
    walkingDirection = self.L["boss.walking.direction.south"]
    phase = SHREDDER
    firstShredderSaw = nil
    secondShredderSaw = nil
  end
  local messageText = text:format(walkingDirection)
  mod:AddProgressBar("WALKING_PROGRESS", messageText, mod.GetWalkingProgress, mod, mod.PhaseChange)
end

function mod:StartProgressBar()
  local messageText = self.L["boss.walking"]:format(self.L["boss.walking.direction.north"])
  mod:AddProgressBar("WALKING_PROGRESS", messageText, mod.GetWalkingProgress, mod, mod.PhaseChange)
  mod:NextAddWave()
  startProgressBarTimer:Stop()
  startProgressBarTimer = nil
end

mod:RegisterUnitEvents({
    "Noxious Nabber",
    "Risen Redmoon Grunt",
    "Regor the Rancid",
    "Braugh the Bloated",
    "Bilious Brute",
    "Putrid Pouncer",
    "Risen Redmoon Plunderer",
    "Risen Redmoon Cadet"
    },{
    ["OnUnitCreated"] = function (_, _, unit)
      core:WatchUnit(unit)
    end,
    ["OnUnitDestroyed"] = function (_, id)
      core:RemovePicture(id)
    end,
    ["OnHealthChanged"] = function (_, id, percent)
      if percent <= 1 and mod:GetSetting("CrosshairAdds") then
        core:AddPicture(id, id, "Crosshair", 20)
      end
    end,
  }
)

mod:RegisterUnitEvents({ "Bilious Brute", "Noxious Nabber" },{
    ["OnUnitCreated"] = function (_, id)
      if mod:GetSetting("CrosshairPriority") then
        core:AddPicture(id, id, "Crosshair", 30, 0, 0, nil, "red")
      end
    end,
  }
)

mod:RegisterUnitEvents("Swabbie Ski'Li",{
    ["OnUnitCreated"] = function (self, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
      self.swabbieUnit = unit
    end,
    ["OnUnitDestroyed"] = function (self, _, unit)
      core:RemoveUnit(unit)
      self:RemoveProgressBar("WALKING_PROGRESS")
      self:RemoveProgressBar("ADDS_PROGRESS")
    end,
    ["OnCastStart"] = function (self, _, castName)
      if self.L["Risen Repellent"] == castName then
        mod:AddMsg("KNOCKBACK", self.L["boss.knockback"], 2)
      end
    end,
    ["OnCastEnd"] = function (self, _, castName)
      if self.L["Swabbie Swoop"] == castName then
        startProgressBarTimer = ApolloTimer.Create(1, true, "StartProgressBar", mod)
        startProgressBarTimer:Start()
      end
    end,
  }
)

function mod:DetermineSawLocation(unit)
  local x = unit:GetPosition().x
  if WEST_POSITION < x and x < MIDDLE_WEST_POSITION then
    return SAW_WEST
  elseif MIDDLE_WEST_POSITION < x and x < MIDDLE_EAST_POSITION then
    return SAW_MID
  elseif MIDDLE_EAST_POSITION < x and x < EAST_POSITION then
    return SAW_EAST
  end
end

function mod:HandleShredderSaw(sawLocation)
  if firstShredderSaw == nil then
    firstShredderSaw = sawLocation
    return
  elseif secondShredderSaw == nil then
    secondShredderSaw = sawLocation
  else
    return
  end

  local safeSpotLocation = SAW_SAFESPOT[firstShredderSaw + secondShredderSaw]
  local message = string.format(self.L["saw.safe_spot"], self.L[safeSpotLocation])
  local sound = mod:GetSetting("SoundSawSafeSpot") == true and "Info"
  mod:AddMsg("SAW_MSG", message, 5, sound)
end

mod:RegisterUnitEvents("Sawblade",{
    ["OnUnitCreated"] = function (self, id, unit)
      if mod:GetSetting("LineSawblade") then
        core:AddPixie(id, 2, unit, nil, "Red", 10, 60, 0)
      end
      local sawLocation = mod:DetermineSawLocation(unit)
      if phase == WALKING and sawLocation == SAW_MID then
        mod:AddMsg("SAW_MSG", self.L["saw.middle"], 5,
          mod:GetSetting("SoundMidSawWarning") == true and "Beware"
        )
      elseif phase == SHREDDER then
        mod:HandleShredderSaw(sawLocation)
      end
    end,
    ["OnUnitDestroyed"] = function (_, id)
      core:DropPixie(id)
    end,
  }
)

mod:RegisterUnitEvents("Noxious Nabber",{
    ["OnUnitCreated"] = function (self)
      core:RemoveMsg("ADDS_MSG")
      mod:AddMsg("ADDS_MSG", self.L["nabber.spawned"], 5, mod:GetSetting("SoundAdds") and "Info")
    end,
    ["OnCastStart"] = function (self, id, castName)
      if self.L["Necrotic Lash"] == castName then
        local unit = GetUnitById(id)
        if mod:GetDistanceBetweenUnits(playerUnit, unit) < 45 then
          mod:AddMsg("NABBER", self.L["nabber.interrupt"], 5, mod:GetSetting("SoundNecroticLash") == true and "Inferno")
        end
      end
    end,
  }
)

mod:RegisterUnitEvents({"Regor the Rancid", "Braugh the Bloated"},{
    ["OnUnitCreated"] = function (self)
      mod:AddMsg("MINIBOSS", self.L["miniboss.spawned"], 5, mod:GetSetting("SoundMiniboss") and "Info")
    end,
    ["OnCastStart"] = function (self, _, castName)
      if self.L["Gravedigger"] == castName or
      self.L["Deathwail"] == castName or
      self.L["Crush"] == castName then
        core:RemoveMsg("MINIBOSS")
        mod:AddMsg("MINIBOSS", self.L["miniboss.interrupt"], 5, mod:GetSetting("SoundMinibossCast") and "Inferno")
      end
    end,
  }
)

mod:RegisterUnitEvents("Tether Anchor",{
    ["OnUnitCreated"] = function (_, id)
      if mod:GetSetting("CrosshairTether") then
        core:AddPicture(id, id, "Crosshair", 25, 0, 0, nil, "FFFFF569")
      end
    end,
    ["OnUnitDestroyed"] = function (_, id)
      core:RemovePicture(id)
    end,
  }
)

mod:RegisterUnitEvents("Junk Trap",{
    ["OnUnitCreated"] = function (_, id)
      if mod:GetSetting("SquareTethers") then
        core:AddPolygon(id, id, 5, 45, 6, nil, 4)
      end
    end,
    ["OnUnitDestroyed"] = function (_, id)
      core:RemovePolygon(id)
    end,
  }
)
