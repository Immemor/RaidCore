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
local ApolloTimer = require "ApolloTimer"
local GameLib = require "GameLib"
local Vector3 = require "Vector3"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Shredder", 104, 548, 549)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ALL, { "unit.swabbie" })
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
    ["unit.bubble"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",
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
    ["msg.bile.stacks"] = "%d STACKS",
    ["msg.saw.middle"] = "SAW MIDDLE",
    ["msg.saw.safe_spot"] = "GAP %s",
    ["msg.saw.safe_spot.left"] = "LEFT",
    ["msg.saw.safe_spot.middle"] = "MIDDLE",
    ["msg.saw.safe_spot.right"] = "RIGHT",
    ["msg.adds.spawning"] = "ADDS",
    ["msg.adds.next"] = "Next wave of adds spawning ...",
    ["msg.nabber.spawned"] = "NABBER SPAWNED",
    ["msg.nabber.interrupt"] = "INTERRUPT NABBER",
    ["msg.miniboss.spawned"] = "MINIBOSS SPAWNED",
    ["msg.miniboss.interrupt"] = "INTERRUPT MINIBOSS",
  }
)
mod:RegisterGermanLocale({
    -- Unit names.
    ["unit.saw.big"] = "Sägeblatt",
    ["unit.miniboss.braugh"] = "Braugh der Blähbauch",
    ["unit.tether"] = "Haltestrickverankerung",
    ["unit.bubble"] = "Feindselige unsichtbare Einheit für Felder (Trefferradius 1.2)",
    -- Datachron messages.
    ["chron.shredder.starting"] = "WARNUNG: DER SCHREDDER WIRD GESTARTET!",
    -- Cast names.
    ["cast.swabbie.knockback"] = "Untoten-Abwehrmittel",
    -- ["cast.miniboss.crush"] = "TODO",
    -- ["cast.miniboss.gravedigger"] = "TODO",
    ["cast.miniboss.deathwail"] = "Totenklage",
    ["cast.nabber.lash"] = "Nekrotisches Peitschen",
    -- Messages.
    ["msg.swabbie.walking"] = "Läuft richtung %s",
    ["msg.swabbie.walking.direction.north"] = "norden",
    ["msg.swabbie.walking.direction.south"] = "süden",
    ["msg.saw.middle"] = "SÄGE MITTE",
    ["msg.saw.safe_spot"] = "LÜCKE %s",
    ["msg.saw.safe_spot.left"] = "LINKS",
    ["msg.saw.safe_spot.middle"] = "MITTE",
    ["msg.saw.safe_spot.right"] = "RECHTS",
    ["msg.adds.next"] = "Nächste Welle von adds kommt ...",
    ["msg.nabber.spawned"] = "NABBER GESPAWNT",
    ["msg.miniboss.spawned"] = "MINIBOSS GESPAWNT",
  }
)
mod:RegisterFrenchLocale({
    -- Unit names.
    ["unit.saw.big"] = "Lamescie",
    -- ["unit.miniboss.braugh"] = "TODO",
    ["unit.tether"] = "Ancre de Bride",
    ["unit.bubble"] = "Unité hostile invisible de terrain (zone d'effet 1,2)",
    -- Datachron messages.
    ["chron.shredder.starting"] = "ATTENTION : DÉMARRAGE DU BROYEUR !",
    -- Cast names.
    ["cast.swabbie.knockback"] = "Répulsif pour revenant",
    -- ["cast.miniboss.crush"] = "TODO",
    ["cast.miniboss.gravedigger"] = "Fossoyeur",
    ["cast.miniboss.deathwail"] = "Gémissement mortel",
    ["cast.nabber.lash"] = "Fouet nécrotique",
  }
)
----------------------------------------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------------------------------------
-- Visuals.
mod:RegisterDefaultSetting("LineSawblade")
mod:RegisterDefaultSetting("SquareTethers")
mod:RegisterDefaultSetting("CrosshairAdds")
mod:RegisterDefaultSetting("CrosshairPriority")
mod:RegisterDefaultSetting("CrosshairTether")
mod:RegisterDefaultSetting("CircleBubble")
-- Sound.
mod:RegisterDefaultSetting("SoundAdds")
mod:RegisterDefaultSetting("SoundMiniboss")
mod:RegisterDefaultSetting("SoundNecroticLash")
mod:RegisterDefaultSetting("SoundMinibossCast")
mod:RegisterDefaultSetting("SoundOozeStacksWarning")
mod:RegisterDefaultSetting("SoundMidSawWarning")
mod:RegisterDefaultSetting("SoundSawSafeSpot")
-- Messages.
mod:RegisterDefaultSetting("MessageAdds")
mod:RegisterDefaultSetting("MessageMiniboss")
mod:RegisterDefaultSetting("MessageNecroticLash")
mod:RegisterDefaultSetting("MessageMinibossCast")
mod:RegisterDefaultSetting("MessageOozeStacksWarning")
mod:RegisterDefaultSetting("MessageMidSawWarning")
mod:RegisterDefaultSetting("MessageSawSafeSpot")
-- Binds.
mod:RegisterMessageSetting("ADDS_MSG", core.E.COMPARE_EQUAL, "MessageAdds", "SoundAdds")
mod:RegisterMessageSetting("MINIBOSS_SPAWN", core.E.COMPARE_EQUAL, "MessageMiniboss", "SoundMiniboss")
mod:RegisterMessageSetting("MINIBOSS_CAST", core.E.COMPARE_EQUAL, "MessageMinibossCast", "SoundMinibossCast")
mod:RegisterMessageSetting("NABBER", core.E.COMPARE_EQUAL, "MessageNecroticLash", "SoundNecroticLash")
mod:RegisterMessageSetting("OOZE_MSG", core.E.COMPARE_EQUAL, "MessageOozeStacksWarning", "SoundOozeStacksWarning")
mod:RegisterMessageSetting("SAW_MSG_MID", core.E.COMPARE_EQUAL, "MessageMidSawWarning", "SoundMidSawWarning")
mod:RegisterMessageSetting("SAW_MSG_MID", core.E.COMPARE_EQUAL, "MessageSawSafeSpot", "SoundSawSafeSpot")
-- Progressbar defaults
mod:RegisterDefaultTimerBarConfigs({
    ["WALKING_PROGRESS"] = { sColor = "xkcdBrown", nPriority = 1},
    ["ADDS_PROGRESS"] = { sColor = "xkcdOrange", nPriority = 2},
  }
)
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
local DEBUFFS = {
  OOZING_BILE = 84321,
}

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
-- Locals.
----------------------------------------------------------------------------------------------------
local phase
local addPhase
local previousAddPhase
local firstShredderSaw
local secondShredderSaw
local playerUnit
local prevShredderProgress
local startProgressBarTimer = ApolloTimer.Create(4, false, "StartProgressBar", mod)
startProgressBarTimer:Stop() --thanks carbine
local nabbers
local lastOozingBileStack
----------------------------------------------------------------------------------------------------
-- Encounter description.
-----------------------------------------------------------------------------------------------------

function mod:OnBossEnable()
  playerUnit = GameLib.GetPlayerUnit()
  phase = WALKING
  addPhase = 4
  previousAddPhase = 0
  prevShredderProgress = 0
  firstShredderSaw = nil
  secondShredderSaw = nil
  lastOozingBileStack = 0
  nabbers = {}
  startProgressBarTimer:Start()
end

function mod:OnBossDisable()
  mod:RemoveProgressBar("WALKING_PROGRESS")
  mod:RemoveProgressBar("ADDS_PROGRESS")
end

function mod:OnOozingBileUpdate(id, spellId, stack)
  if playerUnit:GetId() == id then
    if stack > lastOozingBileStack and stack == 8 then
      mod:AddMsg("OOZE_MSG", string.format(self.L["msg.bile.stacks"], stack), 5, "Beware", "xkcdAcidGreen")
    end
    lastOozingBileStack = stack
  end
end

function mod:GetWalkingProgress(oldProgress)
  local pos1
  local pos2
  if not mod.swabbieUnit then --voidslip
    return oldProgress
  end
  if phase == WALKING then
    pos1 = Vector3.New(mod.swabbieUnit:GetPosition())
    pos2 = START_POSITION
  elseif phase == SHREDDER then
    pos1 = END_POSITION
    pos2 = Vector3.New(mod.swabbieUnit:GetPosition())
  end
  local walkedDistance = (pos1 - pos2):Length()
  local progress = (walkedDistance / WALKING_DISTANCE) * 100
  prevShredderProgress = progress
  return progress
end

function mod:GetAddSpawnProgess()
  local currentProgress = mod:GetWalkingProgress(prevShredderProgress) - previousAddPhase
  local waveSpawn = ADD_PHASES[addPhase] - previousAddPhase
  return (currentProgress/waveSpawn)*100
end

function mod:NextAddWave()
  if ADD_PHASES[addPhase] ~= 0 and not core:IsMessageActive("ADDS_MSG") then
    mod:AddMsg("ADDS_MSG", "msg.adds.spawning", 5, "Info", "xkcdWhite")
  end
  previousAddPhase = ADD_PHASES[addPhase]
  addPhase = addPhase + 1
  if ADD_PHASES[addPhase] ~= 0 then
    mod:AddProgressBar("ADDS_PROGRESS", "msg.adds.next", mod.GetAddSpawnProgess, mod, mod.NextAddWave)
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
end

function mod:OnTrashWithCastsCreated(id, unit, name)
  core:WatchUnit(unit, core.E.TRACK_CASTS + core.E.TRACK_HEALTH)
end

function mod:OnTrashCreated(id, unit, name)
  core:WatchUnit(unit, core.E.TRACK_HEALTH)
end

function mod:OnTrashHealthChanged(id, percent)
  if percent <= 1 and mod:GetSetting("CrosshairAdds") then
    core:AddPicture(id, id, "Crosshair", 20)
  end
end

function mod:OnPriorityTrashCreated(id, unit, name)
  if mod:GetSetting("CrosshairPriority") then
    core:AddPicture(id, unit, "Crosshair", 30, 0, 0, nil, "red")
  end
end

function mod:OnSwabbieCreated(id, unit, name)
  -- filter out second unit that's there for some reason
  if not unit:GetHealth() then return end
  core:AddUnit(unit)
  core:WatchUnit(unit, core.E.TRACK_CASTS)
  self.swabbieUnit = unit
end

function mod:OnSwabbieDestroyed(id, unit, name)
  self.swabbieUnit = nil
  core:RemoveUnit(unit)
end

function mod:OnSwabbieKnockStart()
  mod:AddMsg("KNOCKBACK", "msg.swabbie.knockback", 2, nil, "xkcdRed")
end

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

function mod:ProcessMidphaseSaw(sawLocation)
  if firstShredderSaw == nil then
    firstShredderSaw = sawLocation
    return
  elseif secondShredderSaw == nil then
    secondShredderSaw = sawLocation
  else
    return
  end

  local safeSpot = SAW_SAFESPOT[firstShredderSaw + secondShredderSaw]
  local msg = string.format(self.L["msg.saw.safe_spot"], self.L[safeSpot])
  mod:AddMsg("SAW_MSG_SAFE", msg, 5, "Info", "xkcdGreen")
end

function mod:OnBigSawCreated(id, unit, name)
  if mod:GetSetting("LineSawblade") then
    core:AddSimpleLine(id, unit, nil, 60, nil, 10, "Red")
  end
  local sawLocation = mod:DetermineSawLocation(unit)
  if phase == WALKING and sawLocation == SAW_MID then
    mod:AddMsg("SAW_MSG_MID", "msg.saw.middle", 5, "Beware", "xkcdRed")
  elseif phase == SHREDDER then
    mod:ProcessMidphaseSaw(sawLocation)
  end
end

function mod:OnNabberCreated(id, unit, name)
  nabbers[id] = unit
  core:RemoveMsg("ADDS_MSG")
  mod:AddMsg("ADDS_MSG", "msg.nabber.spawned", 5, "Info", "xkcdWhite")
end

function mod:OnNabberDestroyed(id, unit, name)
  nabbers[id] = nil
end

function mod:OnNabberLashStart(id)
  if mod:GetDistanceBetweenUnits(playerUnit, nabbers[id]) < 45 then
    mod:AddMsg("NABBER", "msg.nabber.interrupt", 5, "Inferno", "xkcdOrange")
  end
end

function mod:OnMinibossCreated(id, unit, name)
  mod:AddMsg("MINIBOSS", "msg.miniboss.spawned", 5, "Info", "xkcdWhite")
end

function mod:OnMinibossCastStart()
  core:RemoveMsg("MINIBOSS_SPAWN")
  mod:AddMsg("MINIBOSS_CAST", "msg.miniboss.interrupt", 5, "Inferno", "xkcdOrange")
end

function mod:OnBubbleCreated(id, unit, name)
  if mod:GetSetting("CircleBubble") then
    core:AddPolygon(id, unit, 6.5, nil, 5, "white", 20)
  end
end

function mod:OnTetherCreated(id, unit, name)
  if mod:GetSetting("CrosshairTether") then
    core:AddPicture(id, unit, "Crosshair", 25, 0, 0, nil, "FFFFF569")
  end
end

function mod:OnJunkTrapCreated(id, unit, name)
  if mod:GetSetting("SquareTethers") then
    core:AddPolygon(id, unit, 5, 45, 6, nil, 4)
  end
end

----------------------------------------------------------------------------------------------------
-- Bind event handlers.
----------------------------------------------------------------------------------------------------
mod:RegisterUnitSpellEvent(core.E.ALL_UNITS, core.E.DEBUFF_UPDATE, DEBUFFS.OOZING_BILE, mod.OnOozingBileUpdate)
mod:RegisterUnitEvents({
    "unit.add.nabber",
    "unit.miniboss.regor",
    "unit.miniboss.braugh",
    },{
    [core.E.UNIT_CREATED] = mod.OnTrashWithCastsCreated,
  }
)
mod:RegisterUnitEvents({
    "unit.add.grunt",
    "unit.add.brute",
    "unit.add.pouncer",
    "unit.add.plunderer",
    "unit.add.cadet"
    },{
    [core.E.UNIT_CREATED] = mod.OnTrashCreated,
  }
)
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
    [core.E.HEALTH_CHANGED] = mod.OnTrashHealthChanged,
  }
)
mod:RegisterUnitEvents({"unit.add.brute", "unit.add.nabber"},{
    [core.E.UNIT_CREATED] = mod.OnPriorityTrashCreated,
  }
)
mod:RegisterUnitEvents("unit.swabbie",{
    [core.E.UNIT_CREATED] = mod.OnSwabbieCreated,
    [core.E.UNIT_DESTROYED] = mod.OnSwabbieDestroyed,
    [core.E.CAST_START] = {
      ["cast.swabbie.knockback"] = mod.OnSwabbieKnockStart,
    },
  }
)
mod:RegisterUnitEvents("unit.saw.big",{
    [core.E.UNIT_CREATED] = mod.OnBigSawCreated,
  }
)
mod:RegisterUnitEvents("unit.add.nabber",{
    [core.E.UNIT_CREATED] = mod.OnNabberCreated,
    [core.E.UNIT_DESTROYED] = mod.OnNabberDestroyed,
    [core.E.CAST_START] = {
      ["cast.nabber.lash"] = mod.OnNabberLashStart,
    },
  }
)
mod:RegisterUnitEvents({"unit.miniboss.regor", "unit.miniboss.braugh"},{
    [core.E.UNIT_CREATED] = mod.OnMinibossCreated,
    [core.E.CAST_START] = {
      ["cast.miniboss.gravedigger"] = mod.OnMinibossCastStart,
      ["cast.miniboss.deathwail"] = mod.OnMinibossCastStart,
      ["cast.miniboss.crush"] = mod.OnMinibossCastStart,
    },
  }
)
mod:RegisterUnitEvents("unit.bubble",{
    [core.E.UNIT_CREATED] = mod.OnBubbleCreated,
  }
)
mod:RegisterUnitEvents("unit.tether",{
    [core.E.UNIT_CREATED] = mod.OnTetherCreated,
  }
)
mod:RegisterUnitEvents("unit.junk_trap",{
    [core.E.UNIT_CREATED] = mod.OnJunkTrapCreated,
  }
)
