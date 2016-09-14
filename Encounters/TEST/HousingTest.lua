----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- Using the Large Training Grounds fabkit it is possible to spawn enemies.
-- There are 4 different modes: easy, normal, hard, elite. In each mode you get
-- a random enemy out of 3 possibilities.
-- These enemies have atleast one cast each and some of them have buffs and debuffs
-- Easy:
-- Chompacabra: Applies bleed debuff on the player
-- Chompacabra: Applies melt debuff on the player
-- Moodie: Applies melt debuff on the player
-- Hard:
-- Krogg: Applies a crit buff on himself
--
-- It's not possible to control what enemy you want to get so it's recommended
-- to use the easy mode since there are 2 mobs there that will apply debuffs
-- on the player.
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
--@alpha@
local mod = core:NewEncounter("HousingTest", 36, 0, 60)
--@end-alpha@
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
local TRIG_MOBS = {
  -- Easy.
  "unit.chompacabra",
  "unit.moodie",
  "unit.aggressorbot",
  -- Normal.
  "unit.bandit",
  "unit.girrok",
  "unit.shootbot",
  -- Hard.
  "unit.pumera",
  "unit.osun",
  "unit.krogg",
  -- Elite.
  "unit.ravenok",
  "unit.pell",
  "unit.titan",
}

mod:RegisterTrigMob("ANY", TRIG_MOBS)
mod:RegisterEnglishLocale({
    -- Unit names.
    -- Easy.
    ["unit.chompacabra"] = "Holographic Chompacabra",
    ["unit.moodie"] = "Holographic Moodie",
    ["unit.aggressorbot"] = "Holographic Aggressorbot",
    -- Normal.
    ["unit.bandit"] = "Holographic Bandit",
    ["unit.girrok"] = "Holographic Girrok",
    ["unit.shootbot"] = "Holographic Shootbot",
    -- Hard.
    ["unit.pumera"] = "Holographic Pumera",
    ["unit.osun"] = "Holographic Osun",
    ["unit.krogg"] = "Holographic Krogg",
    -- Elite.
    ["unit.ravenok"] = "Holographic Ravenok",
    ["unit.pell"] = "Holographic Pell",
    ["unit.titan"] = "Holographic Titan",
    ["unit.buffer"] = "Invisible Unit s71975 - Aquatic Buffer", -- titan cast,

    ["unit.invis.0"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    -- Cast names.
    ["cast.chompacabra.frenzy"] = "Feeding Frenzy",
    ["cast.chompacabra.trap"] = "Snap Trap",
    ["cast.moodie.firestorm"] = "Firestorm",
    ["cast.moodie.fissure"] = "Erupting Fissure",
    ["cast.shootbot.dash"] = "Slasher Dash",
    ["cast.shootbot.jump"] = "Jump Shot",

    ["unit.bandit.blast"] = "Blast Shot",
    ["unit.girrok.roar"] = "Roar",
    ["unit.aggressorbot.spin"] = "Mauling Spin",

    ["unit.pumera.pounce"] = "Pride Pounce",
    ["unit.pumera.frenzy"] = "Frenzy of the Feline",
    ["unit.osun.firestorm"] = "Firestorm",
    ["unit.osun.fisure"] = "Erupting Fissure",
    ["unit.krogg.rush"] = "Crushing Rush",
    ["unit.krogg.flurry"] = "Crushing Flurry",
    ["unit.krogg.assault"] = "Focused Assault",

    ["unit.ravenok.head_shoulders"] = "Head and Shoulders",
    ["unit.ravenok.tooth_nail"] = "Tooth and Nail",
    ["unit.ravenok.winds"] = "Tail Winds",
    ["unit.ravenok.rush"] = "Ravenok Rush",
    ["unit.titan.slash"] = "Shellark Slash",
    ["unit.titan.strike"] = "Trident Strike",
    ["unit.titan.buffer"] = "Aquatic Buffer",
    ["unit.pell.vortex"] = "Swirling Vortex",

    -- Datachron.
    ["chron.equal.first"] = "First simulated datachron.",
    ["chron.equal.second"] = "Second simulated datachron.",
    ["chron.find.first.partial"] = "find me first",
    ["chron.find.second.partial"] = "find me second",
    ["chron.find.first.full"] = "Do find me first.",
    ["chron.find.second.full"] = "And then find me second.",
    ["chron.match.first.partial"] = "First match this name: ([^%s]+%s[^%s]+) hopefully%.",
    ["chron.match.second.partial"] = "Secondly match this name: ([^%s]+%s[^%s]+) please%.",
    ["chron.match.first.full"] = "First match this name: Zod Bain hopefully.",
    ["chron.match.second.full"] = "Secondly match this name: Zod Bain please.",
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local BUFF_KROGG_FOCUSED_ASSAULT = 72202
--moodie and chompacabra debuff
local DEBUFF_MELT = 50233
local DEBUFF_CHOMPACABRA_BLEED = 43759
local EXPECTED_DATACHRON_RESULTS = {
  {
    registerMessage = "chron.equal.first",
    message = "chron.equal.first",
    match = "EQUAL",
    result = true,
    },{
    registerMessage = "chron.equal.second",
    message = "chron.equal.second",
    match = "EQUAL",
    result = true,
    },{
    registerMessage = "chron.find.first.partial",
    message = "chron.find.first.full",
    match = "FIND",
    result = 4,
    },{
    registerMessage = "chron.find.second.partial",
    message = "chron.find.second.full",
    match = "FIND",
    result = 10,
    },{
    registerMessage = "chron.match.first.partial",
    message = "chron.match.first.full",
    match = "MATCH",
    result = "Zod Bain",
    },{
    registerMessage = "chron.match.second.partial",
    message = "chron.match.second.full",
    match = "MATCH",
    result = "Zod Bain",
  },
}

local ALL_MOBS = {
  -- Easy.
  "unit.chompacabra",
  "unit.moodie",
  "unit.aggressorbot",
  -- Normal.
  "unit.bandit",
  "unit.girrok",
  "unit.shootbot",
  -- Hard.
  "unit.pumera",
  "unit.osun",
  "unit.krogg",
  -- Elite.
  "unit.ravenok",
  "unit.pell",
  "unit.titan",
  "unit.buffer",
  "unit.invis.0",
}

local EVENTS_TO_TEST = {
  "OnUnitCreated",
  "OnUnitDestroyed",
  "OnCastStart",
  "OnCastEnd",
  "OnHealthChanged",
  "OnEnteredCombat",
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local FakeDatachron = {}
function FakeDatachron:GetType()
  return ChatSystemLib.ChatChannel_Datachron
end

local datachronResult
local datachronExpected
local datachronTestNumber
local eventCounter
local unitEventCounter
local events
----------------------------------------------------------------------------------------------------
-- Functions.
----------------------------------------------------------------------------------------------------
local next = next
local function SimulateDatachron(message)
  core:CI_OnChatMessage(FakeDatachron, {
      strSender = "TestEncounter",
      arMessageSegments = {{strText = message}},
    }
  )
end

local function RegisterDatachronTestResult(registerMessage, message, result, oldEvent)
  --Add a event result that occured
  table.insert(datachronResult, {
      registerMessage = registerMessage,
      message = message,
      result = result,
      oldEvent = oldEvent,
    })
end

local function RegisterDatachronTestEvent(registerMessage, match)
  --Bind datachron events based on the expected results
  mod:RegisterDatachronEvent(registerMessage, match, function (_, message, result)
      RegisterDatachronTestResult(registerMessage, message, result, false)
    end
  )
end

local function RegisterTestEvent(eventName)
  --Register old events and unit events and keep count of how many events
  --happened and remove them in the same order again.
  mod[eventName] = function(...)
    eventCounter[eventName] = eventCounter[eventName] or 0
    local eventKey = eventName .. tostring(eventCounter[eventName])
    events[eventKey] = {...}
    eventCounter[eventName] = eventCounter[eventName] + 1
  end
  mod:RegisterUnitEvents(ALL_MOBS, {
      [eventName] = function(...)
        unitEventCounter[eventName] = unitEventCounter[eventName] or 0
        local eventKey = eventName .. tostring(unitEventCounter[eventName])
        mod:CompareEvents(eventName, events[eventKey], {...})
        events[eventKey] = nil
        unitEventCounter[eventName] = unitEventCounter[eventName] + 1
      end
    }
  )
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
for _, result in next, EXPECTED_DATACHRON_RESULTS do
  RegisterDatachronTestEvent(result.registerMessage, result.match)
end

function mod:OnBossEnable()
  eventCounter = {}
  unitEventCounter = {}
  events = {}
  table.insert(ALL_MOBS, GameLib.GetPlayerUnit():GetName())
  for _, eventName in next, EVENTS_TO_TEST do
    RegisterTestEvent(eventName)
  end
  --Start datachron test cycles.
  datachronTestNumber = 0
  mod:AddTimerBar("DATACHRON", "Simulate datachron", 0.5, false, nil, mod.SimulateDatachron, mod)
  --Start unit events cycle.
  mod:AddTimerBar("UNIT_EVENTS", "Check if events have not been caught", 0.5, false, nil, mod.CheckEvents, mod)
end

function mod:SimulateDatachron()
  --Cycle through datachron tests until we finished them all
  datachronTestNumber = datachronTestNumber + 1
  datachronResult = {}
  datachronExpected = EXPECTED_DATACHRON_RESULTS[datachronTestNumber]
  if datachronExpected then
    SimulateDatachron(self.L[datachronExpected.message])
    --Check results after a short timer to make sure all the events got caught
    mod:AddTimerBar("DATACHRON", "Check datachron result", 0.5, false, nil, mod.CheckDatachronResult, mod)
  end
end

function mod:CheckDatachronResult()
  --Check the results from the last simulated datachron.
  local expectedFound = false
  local expectedOldFound = false
  local nCount = #datachronResult
  for i = 1, nCount do
    local testResult = datachronResult[i]
    local message = testResult.message
    local result = testResult.result
    local registerMessage = testResult.registerMessage
    if registerMessage == datachronExpected.registerMessage then
      --Test against the expected result
      assert(self.L[datachronExpected.message] == message, "Messages are not the same: "..message.." == "..self.L[datachronExpected.message])
      assert(result == datachronExpected.result, "Results are not the same: "..tostring(result).." == "..tostring(datachronExpected.result))
      expectedFound = true
    elseif testResult.oldEvent then
      --Test message passthrough of old datachron events.
      assert(self.L[datachronExpected.message] == message, "Messages are not the same: "..message.." == "..self.L[datachronExpected.message])
      expectedOldFound = true
    else
      --This should never happen. Too many results have been found.
      assert(registerMessage == nil, registerMessage.." should not be here, expected: "..datachronExpected.registerMessage)
    end
  end
  --No results are found = bad
  assert(expectedFound == true, "Expected result for "..datachronExpected.registerMessage.." has not been found.")
  assert(expectedOldFound == true, "Expected old result for "..datachronExpected.registerMessage.." has not been found.")

  --Start next cycle
  mod:AddTimerBar("DATACHRON", "Simulate datachron", 0.5, false, nil, mod.SimulateDatachron, mod)
end

function mod:OnDatachron (message)
  --Register old datachron events just to make sure they still get passed through too
  RegisterDatachronTestResult(nil, message, nil, true)
end

function mod:CompareEvents(eventName, args1, args2)
  --Compare the amount of arguments and the arguments themselves
  local count1 = #args1
  local count2 = #args2
  assert(count1 == count2, "Different amount of parameters in "..eventName.." "..tostring(count1).." == "..tostring(count2))

  for i = 1, count1 do
    local arg1 = args1[i]
    local arg2 = args2[i]
    assert(arg1 == arg2, "Arguments are not equal "..eventName.." "..tostring(arg1).." == "..tostring(arg2))
  end
end

function mod:CheckEvents()
  --Check if any events have not been caught by unit events.
  --If this ever causes a race condition add a flag to the events and then
  --do the assert on the second pass if they are still there
  for eventName, _ in next, events do
    assert(eventName == nil, eventName.." has not been detected by unit events")
  end

  mod:AddTimerBar("UNIT_EVENTS", "Check if events have not been caught", 1, false, nil, mod.CheckEvents, mod)
end

mod:RegisterUnitEvents(ALL_MOBS, {
    ["OnUnitCreated"] = function (_, _, unit)
      core:WatchUnit(unit)
      core:AddUnit(unit)
    end,
  }
)
