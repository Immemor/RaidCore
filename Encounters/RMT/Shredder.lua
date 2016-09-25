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
mod:RegisterTrigMob("ALL", { "unit.swabbie" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["unit.swabbie"] = "Swabbie Ski'Li",
    ["unit.saw.big"] = "Sawblade", -- big saw
    ["unit.saw.small"] = "Saw", -- little saw
    ["unit.miniboss.regor"] = "Regor the Rancid",
    ["unit.miniboss.braugh"] = "Braugh the Bloated",
    ["unit.add.nabber"] = "Noxious Nabber",
    ["unit.add.grunt"] = "Risen Redmoon Grunt",
    ["unit.add.brute"] = "Bilious Brute",
    ["unit.add.pouncer"] = "Putrid Pouncer",
    ["unit.add.plunderer"] = "Risen Redmoon Plunderer",
    ["unit.add.cadet"] = "Risen Redmoon Cadet",
    ["unit.tether"] = "Tether Anchor",
    ["unit.junk_trap"] = "Junk Trap",
    -- Datachron messages.
    ["chron.shredder.starting"] = "WARNING: THE SHREDDER IS STARTING!",
    -- Cast names.
    ["cast.swabbie.swoop"] = "Swabbie Swoop",
    ["cast.swabbie.knockback"] = "Risen Repellent",
    ["cast.miniboss.crush"] = "Crush",
    ["cast.miniboss.gravedigger"] = "Gravedigger",
    ["cast.miniboss.deathwail"] = "Deathwail",
    ["cast.nabber.lash"] = "Necrotic Lash",
    -- Messages.
    ["msg.swabbie.knockback"] = "KNOCKBACK",
    ["msg.swabbie.walking"] = "Walking %s",
    ["msg.swabbie.walking.direction.north"] = "North",
    ["msg.swabbie.walking.direction.south"] = "South",
    ["msg.bile.stacks"] = "%d BILE STACKS!",
    ["msg.saw.middle"] = "SAW IN MIDDLE",
    ["msg.saw.safe_spot"] = "SAFE SPOT %s",
    ["msg.saw.safe_spot.left"] = "LEFT",
    ["msg.saw.safe_spot.middle"] = "MIDDLE",
    ["msg.saw.safe_spot.right"] = "RIGHT",
    ["msg.adds.spawning"] = "ADDS SPAWNING",
    ["msg.adds.next"] = "Next wave of adds spawning ...",
    ["msg.nabber.spawned"] = "NOXIOUS NABBER SPAWNED",
    ["msg.nabber.interrupt"] = "INTERRUPT NECROTIC LASH!",
    ["msg.miniboss.spawned"] = "MINIBOSS SPAWNED",
    ["msg.miniboss.interrupt"] = "INTERRUPT MINIBOSS!",
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
  [SAW_WEST + SAW_MID] = "msg.saw.safe_spot.left",
  [SAW_WEST + SAW_EAST] = "msg.saw.safe_spot.middle",
  [SAW_MID + SAW_EAST] = "msg.saw.safe_spot.right",
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
      mod:AddMsg("OOZE_MSG", string.format(self.L["msg.bile.stacks"], stack), 5, stack == 8 and mod:GetSetting("SoundOozeStacksWarning") and "Beware")
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
    mod:AddMsg("ADDS_MSG", self.L["msg.adds.spawning"], 5, mod:GetSetting("SoundAdds") and "Info")
  end
  previousAddPhase = ADD_PHASES[addPhase]
  addPhase = addPhase + 1
  if ADD_PHASES[addPhase] ~= 0 then
    mod:AddProgressBar("ADDS_PROGRESS", self.L["msg.adds.next"], mod.GetAddSpawnProgess, mod, mod.NextAddWave)
  end
end

function mod:PhaseChange()
  local text = self.L["msg.swabbie.walking"]
  local walkingDirection
  if phase == SHREDDER then
    phase = WALKING
    walkingDirection = self.L["msg.swabbie.walking.direction.north"]
    mod:NextAddWave()
  else
    walkingDirection = self.L["msg.swabbie.walking.direction.south"]
    phase = SHREDDER
    firstShredderSaw = nil
    secondShredderSaw = nil
  end
  mod:AddProgressBar("WALKING_PROGRESS", text:format(walkingDirection), mod.GetWalkingProgress, mod, mod.PhaseChange)
end

function mod:StartProgressBar()
  local messageText = self.L["msg.swabbie.walking"]:format(self.L["msg.swabbie.walking.direction.north"])
  mod:AddProgressBar("WALKING_PROGRESS", messageText, mod.GetWalkingProgress, mod, mod.PhaseChange)
  mod:NextAddWave()
  startProgressBarTimer:Stop()
  startProgressBarTimer = nil
end

mod:RegisterUnitEvents({
    "unit.add.nabber",
    "unit.add.grunt",
    "unit.miniboss.regor",
    "unit.miniboss.braugh",
    "unit.add.brute",
    "unit.add.pouncer",
    "unit.add.plunderer",
    "unit.add.cadet"
    },{
    [core.E.UNIT_CREATED] = function(_, _, unit)
      core:WatchUnit(unit)
    end,
    [core.E.UNIT_DESTROYED] = function(_, id)
      core:RemovePicture(id)
    end,
    [core.E.HEALTH_CHANGED] = function(_, id, percent)
      if percent <= 1 and mod:GetSetting("CrosshairAdds") then
        core:AddPicture(id, id, "Crosshair", 20)
      end
    end,
  }
)

mod:RegisterUnitEvents({ "unit.add.brute", "unit.add.nabber" },{
    [core.E.UNIT_CREATED] = function(_, id)
      if mod:GetSetting("CrosshairPriority") then
        core:AddPicture(id, id, "Crosshair", 30, 0, 0, nil, "red")
      end
    end,
  }
)

mod:RegisterUnitEvents("unit.swabbie",{
    [core.E.UNIT_CREATED] = function(self, _, unit)
      core:AddUnit(unit)
      core:WatchUnit(unit)
      self.swabbieUnit = unit
    end,
    [core.E.UNIT_DESTROYED] = function(self, _, unit)
      core:RemoveUnit(unit)
      self:RemoveProgressBar("WALKING_PROGRESS")
      self:RemoveProgressBar("ADDS_PROGRESS")
    end,
    [core.E.CAST_START] = {
      ["cast.swabbie.knockback"] = function(self, _)
        mod:AddMsg("KNOCKBACK", self.L["msg.swabbie.knockback"], 2)
      end
    },
    [core.E.CAST_END] = {
      ["cast.swabbie.swoop"] = function(_, _)
        startProgressBarTimer = ApolloTimer.Create(1, true, "StartProgressBar", mod)
        startProgressBarTimer:Start()
      end
    },
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
  local message = string.format(self.L["msg.saw.safe_spot"], self.L[safeSpotLocation])
  local sound = mod:GetSetting("SoundSawSafeSpot") == true and "Info"
  mod:AddMsg("SAW_MSG", message, 5, sound)
end

mod:RegisterUnitEvents("unit.saw.big",{
    [core.E.UNIT_CREATED] = function(self, id, unit)
      if mod:GetSetting("LineSawblade") then
        core:AddPixie(id, 2, unit, nil, "Red", 10, 60, 0)
      end
      local sawLocation = mod:DetermineSawLocation(unit)
      if phase == WALKING and sawLocation == SAW_MID then
        mod:AddMsg("SAW_MSG", self.L["msg.saw.middle"], 5,
          mod:GetSetting("SoundMidSawWarning") == true and "Beware"
        )
      elseif phase == SHREDDER then
        mod:HandleShredderSaw(sawLocation)
      end
    end,
    [core.E.UNIT_DESTROYED] = function(_, id)
      core:DropPixie(id)
    end,
  }
)

mod:RegisterUnitEvents("unit.add.nabber",{
    [core.E.UNIT_CREATED] = function(self)
      core:RemoveMsg("ADDS_MSG")
      mod:AddMsg("ADDS_MSG", self.L["msg.nabber.spawned"], 5, mod:GetSetting("SoundAdds") and "Info")
    end,
    [core.E.CAST_START] = {
      ["cast.nabber.lash"] = function(self, id)
        local unit = GetUnitById(id)
        if mod:GetDistanceBetweenUnits(playerUnit, unit) < 45 then
          mod:AddMsg("NABBER", self.L["msg.nabber.interrupt"], 5, mod:GetSetting("SoundNecroticLash") == true and "Inferno")
        end
      end
    },
  }
)

mod:RegisterUnitEvents({"unit.miniboss.regor", "unit.miniboss.braugh"},{
    [core.E.UNIT_CREATED] = function(self)
      mod:AddMsg("MINIBOSS", self.L["msg.miniboss.spawned"], 5, mod:GetSetting("SoundMiniboss") and "Info")
    end,
    [core.E.CAST_START] = function(self, _, castName)
      if self.L["cast.miniboss.gravedigger"] == castName or
      self.L["cast.miniboss.deathwail"] == castName or
      self.L["cast.miniboss.crush"] == castName then
        core:RemoveMsg("MINIBOSS")
        mod:AddMsg("MINIBOSS", self.L["msg.miniboss.interrupt"], 5, mod:GetSetting("SoundMinibossCast") and "Inferno")
      end
    end,
  }
)

mod:RegisterUnitEvents("unit.tether",{
    [core.E.UNIT_CREATED] = function(_, id)
      if mod:GetSetting("CrosshairTether") then
        core:AddPicture(id, id, "Crosshair", 25, 0, 0, nil, "FFFFF569")
      end
    end,
    [core.E.UNIT_DESTROYED] = function(_, id)
      core:RemovePicture(id)
    end,
  }
)

mod:RegisterUnitEvents("unit.junk_trap",{
    [core.E.UNIT_CREATED] = function(_, id)
      if mod:GetSetting("SquareTethers") then
        core:AddPolygon(id, id, 5, 45, 6, nil, 4)
      end
    end,
    [core.E.UNIT_DESTROYED] = function(_, id)
      core:RemovePolygon(id)
    end,
  }
)
