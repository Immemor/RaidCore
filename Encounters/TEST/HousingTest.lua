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
local Apollo = require "Apollo"
local ChatSystemLib = require "ChatSystemLib"
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
--@alpha@
local mod = core:NewEncounter("HousingTest", 36, 0, 60, true)
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
  -- Extra units
  "unit.ai",
  "unit.computer",
}

mod:RegisterTrigMob(core.E.TRIGGER_ANY, TRIG_MOBS)
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
    -- Extra units.
    ["unit.ai"] = "SDC-AI",
    ["unit.computer"] = "Super Duper Computer",

    ["unit.invis.0"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    -- Cast names.
    ["cast.chompacabra.frenzy"] = "Feeding Frenzy",
    ["cast.chompacabra.trap"] = "Snap Trap",
    ["cast.moodie.firestorm"] = "Firestorm",
    ["cast.moodie.fissure"] = "Erupting Fissure",
    ["cast.shootbot.dash"] = "Slasher Dash",
    ["cast.shootbot.jump"] = "Jump Shot",

    ["cast.bandit.blast"] = "Blast Shot",
    ["cast.girrok.roar"] = "Roar",
    ["cast.aggressorbot.spin"] = "Mauling Spin",

    ["cast.pumera.pounce"] = "Pride Pounce",
    ["cast.pumera.frenzy"] = "Frenzy of the Feline",
    ["cast.pumera.swipe"] = "Leaping Swipe",
    ["cast.osun.firestorm"] = "Firestorm",
    ["cast.osun.fisure"] = "Erupting Fissure",
    ["cast.osun.superheated"] = "Superheated",
    ["cast.krogg.rush"] = "Crushing Rush",
    ["cast.krogg.flurry"] = "Crushing Flurry",
    ["cast.krogg.assault"] = "Focused Assault",

    ["cast.ravenok.head_shoulders"] = "Head and Shoulders",
    ["cast.ravenok.tooth_nail"] = "Tooth and Nail",
    ["cast.ravenok.winds"] = "Tail Winds",
    ["cast.ravenok.rush"] = "Ravenok Rush",
    ["cast.titan.slash"] = "Shellark Slash",
    ["cast.titan.strike"] = "Trident Strike",
    ["cast.titan.buffer"] = "Aquatic Buffer",
    ["cast.pell.vortex"] = "Swirling Vortex",

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
-- Settings.
----------------------------------------------------------------------------------------------------
mod:RegisterDefaultSetting("TestEnabledSettingOne")
mod:RegisterDefaultSetting("TestDisabledSettingOne", false)
mod:RegisterDefaultSetting("TestEnabledSettingTwo")
mod:RegisterDefaultSetting("TestDisabledSettingTwo", false)
mod:RegisterDefaultSetting("TestEnabledSettingThree")
mod:RegisterDefaultSetting("TestDisabledSettingThree", false)

mod:RegisterMessageSetting("MSG_1", core.E.COMPARE_EQUAL, "TestEnabledSettingOne", "TestEnabledSettingTwo")
mod:RegisterMessageSetting("MSG_2", core.E.COMPARE_EQUAL, "TestEnabledSettingOne", "TestDisabledSettingTwo")
mod:RegisterMessageSetting("MSG_3", core.E.COMPARE_EQUAL, "TestDisabledSettingOne", "TestEnabledSettingTwo")
mod:RegisterMessageSetting("MSG_4", core.E.COMPARE_EQUAL, "TestDisabledSettingOne", "TestDisabledSettingTwo")
mod:RegisterMessageSetting("MSG_5", core.E.COMPARE_EQUAL, nil, "TestEnabledSettingThree")
mod:RegisterMessageSetting("MSG_6", core.E.COMPARE_EQUAL, "TestEnabledSettingThree", nil)
mod:RegisterMessageSetting("MSG_7", core.E.COMPARE_EQUAL, nil, "TestDisabledSettingThree")
mod:RegisterMessageSetting("MSG_8", core.E.COMPARE_EQUAL, "TestDisabledSettingThree", nil)

mod:RegisterDefaultSetting("TestEqualOne")
mod:RegisterDefaultSetting("TestEqualTwo")

mod:RegisterDefaultSetting("TestFindOne")
mod:RegisterDefaultSetting("TestFindTwo")

mod:RegisterDefaultSetting("TestMatchOne")
mod:RegisterDefaultSetting("TestMatchTwo")

mod:RegisterMessageSetting("MSG_TEST_ONE", core.E.COMPARE_EQUAL, "TestEqualOne", "TestEqualTwo")
mod:RegisterMessageSetting("MSG_FIND_ME", core.E.COMPARE_FIND, "TestFindOne", "TestFindTwo")
mod:RegisterMessageSetting("MSG_MATCH_%d_ME", core.E.COMPARE_MATCH, "TestMatchOne", "TestMatchTwo")
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local BUFF_KROGG_FOCUSED_ASSAULT = 72202
local BUFF_OSUN_SUPERHEAT = 71236
--moodie and chompacabra debuff
local DEBUFF_MELT = 50233
local DEBUFF_CHOMPACABRA_BLEED = 43759
local EXPECTED_DATACHRON_RESULTS = {
  {
    registerMessage = "chron.equal.first",
    message = "chron.equal.first",
    match = core.E.COMPARE_EQUAL,
    result = true,
    },{
    registerMessage = "chron.equal.second",
    message = "chron.equal.second",
    match = core.E.COMPARE_EQUAL,
    result = true,
    },{
    registerMessage = "chron.find.first.partial",
    message = "chron.find.first.full",
    match = core.E.COMPARE_FIND,
    result = 4,
    },{
    registerMessage = "chron.find.second.partial",
    message = "chron.find.second.full",
    match = core.E.COMPARE_FIND,
    result = 10,
    },{
    registerMessage = "chron.match.first.partial",
    message = "chron.match.first.full",
    match = core.E.COMPARE_MATCH,
    result = "Zod Bain",
    },{
    registerMessage = "chron.match.second.partial",
    message = "chron.match.second.full",
    match = core.E.COMPARE_MATCH,
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

local ALL_SPELLS = {
  ["unit.chompacabra"] = {
    "cast.chompacabra.frenzy",
    "cast.chompacabra.trap",
  },
  ["unit.moodie"] = {
    "cast.moodie.firestorm",
    "cast.moodie.fissure",
  },
  ["unit.shootbot"] = {
    "cast.shootbot.dash",
    "cast.shootbot.jump",
  },
  ["unit.bandit"] = {
    "cast.bandit.blast",
  },
  ["unit.girrok"] = {
    "cast.girrok.roar",
  },
  ["unit.aggressorbot"] = {
    "cast.aggressorbot.spin",
  },
  ["unit.pumera"] = {
    "cast.pumera.pounce",
    "cast.pumera.frenzy",
    "cast.pumera.swipe",
  },
  ["unit.osun"] = {
    "cast.osun.firestorm",
    "cast.osun.fisure",
    "cast.osun.superheated",
    BUFF_OSUN_SUPERHEAT,
  },
  ["unit.krogg"] = {
    "cast.krogg.rush",
    "cast.krogg.flurry",
    "cast.krogg.assault",
    BUFF_KROGG_FOCUSED_ASSAULT,
  },
  ["unit.ravenok"] = {
    "cast.ravenok.head_shoulders",
    "cast.ravenok.tooth_nail",
    "cast.ravenok.rush",
    "cast.ravenok.winds",
  },
  ["unit.titan"] = {
    "cast.titan.slash",
    "cast.titan.strike",
    "cast.titan.buffer",
  },
  ["unit.pell"] = {
    "cast.pell.vortex",
  },
}

local EVENTS_TO_TEST = {
  core.E.UNIT_CREATED,
  core.E.UNIT_DESTROYED,
  core.E.HEALTH_CHANGED,
  core.E.ENTERED_COMBAT,
  core.E.CAST_START,
  core.E.CAST_END,
  core.E.DEBUFF_ADD,
  core.E.DEBUFF_UPDATE,
  core.E.DEBUFF_REMOVE,
  core.E.BUFF_ADD,
  core.E.BUFF_UPDATE,
  core.E.BUFF_REMOVE,
}
local SPELL_EVENTS = {
  [core.E.CAST_START] = true,
  [core.E.CAST_END] = true,
  [core.E.BUFF_ADD] = true,
  [core.E.BUFF_UPDATE] = true,
  [core.E.BUFF_REMOVE] = true,
  [core.E.DEBUFF_ADD] = true,
  [core.E.DEBUFF_UPDATE] = true,
  [core.E.DEBUFF_REMOVE] = true,
}

local MESSAGE_SETTINGS_TESTS = {
  {key = "MSG_1", msg = true, sound = true},
  {key = "MSG_2", msg = true, sound = false},
  {key = "MSG_3", msg = false, sound = true},
  {key = "MSG_4", msg = false, sound = false},
  {key = "MSG_5", msg = true, sound = true},
  {key = "MSG_6", msg = true, sound = true},
  {key = "MSG_7", msg = true, sound = false},
  {key = "MSG_8", msg = false, sound = true},
  {key = "MSG_TEST_ONE", msg = true, sound = true},
  {key = "MSG_FIND_ME_SOMEWHERE", msg = true, sound = true},
  {key = "MSG_MATCH_123_ME", msg = true, sound = true},
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
local unitEventsInitialized = false
local messageTestCounter
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
    --Handle normal events
    eventCounter[eventName] = eventCounter[eventName] or 0
    local eventKey = eventName .. tostring(eventCounter[eventName])
    events[eventKey] = {...}
    eventCounter[eventName] = eventCounter[eventName] + 1

    --Handle buff and cast events
    if SPELL_EVENTS[eventName] then
      local primaryEventName = eventName .. "_Primary"
      eventCounter[primaryEventName] = eventCounter[primaryEventName] or 0
      eventKey = primaryEventName .. tostring(eventCounter[primaryEventName])
      events[eventKey] = {...}
      eventCounter[primaryEventName] = eventCounter[primaryEventName] + 1

      local secondaryEventName = eventName .. "_Secondary"
      eventCounter[secondaryEventName] = eventCounter[secondaryEventName] or 0
      eventKey = secondaryEventName .. tostring(eventCounter[secondaryEventName])
      events[eventKey] = {...}
      eventCounter[secondaryEventName] = eventCounter[secondaryEventName] + 1
    end
  end
  mod:RegisterUnitEvents(core.E.ALL_UNITS, {
      [eventName] = function(...)
        unitEventCounter[eventName] = unitEventCounter[eventName] or 0
        local eventKey = eventName .. tostring(unitEventCounter[eventName])
        mod:CompareEvents(eventName, events[eventKey], {...})
        events[eventKey] = nil
        unitEventCounter[eventName] = unitEventCounter[eventName] + 1
      end
    }
  )
  if not SPELL_EVENTS[eventName] then
    return
  end

  for mob, spellIds in next, ALL_SPELLS do
    local size = #spellIds
    for i = 1, size do
      local spellId = spellIds[i]
      mod:RegisterUnitEvents(mob, {
          [eventName] = {
            [spellId] = function(...)
              local primaryEventName = eventName .. "_Primary"
              unitEventCounter[primaryEventName] = unitEventCounter[primaryEventName] or 0
              local eventKey = primaryEventName .. tostring(unitEventCounter[primaryEventName])
              mod:CompareEvents(primaryEventName, events[eventKey], {...})
              events[eventKey] = nil
              unitEventCounter[primaryEventName] = unitEventCounter[primaryEventName] + 1
            end
          },
          [spellId] = {
            [eventName] = function(...)
              local secondaryEventName = eventName .. "_Secondary"
              unitEventCounter[secondaryEventName] = unitEventCounter[secondaryEventName] or 0
              local eventKey = secondaryEventName .. tostring(unitEventCounter[secondaryEventName])
              mod:CompareEvents(secondaryEventName, events[eventKey], {...})
              events[eventKey] = nil
              unitEventCounter[secondaryEventName] = unitEventCounter[secondaryEventName] + 1
            end
          },
        }
      )
    end
  end
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
  if not unitEventsInitialized then
    local playerName = GameLib.GetPlayerUnit():GetName()
    ALL_SPELLS[playerName] = {
      DEBUFF_MELT,
      DEBUFF_CHOMPACABRA_BLEED,
    }
    table.insert(ALL_MOBS, playerName)
    for _, eventName in next, EVENTS_TO_TEST do
      RegisterTestEvent(eventName)
    end
    unitEventsInitialized = true
  end
  --Start datachron test cycles.
  datachronTestNumber = 0
  mod:AddTimerBar("DATACHRON", "Simulate datachron", 0.5, false, nil, mod.SimulateDatachron, mod)
  --Start unit events cycle.
  mod:AddTimerBar("UNIT_EVENTS", "Check if events have not been caught", 0.5, false, nil, mod.CheckEvents, mod)

  messageTestCounter = 1
  mod:AddTimerBar("MSG_SETTINGS", "Start message tests", 0.5, false, nil, mod.MessageTest, mod)
end

function mod:MessageTest()
  local msgTest = MESSAGE_SETTINGS_TESTS[messageTestCounter]
  messageTestCounter = messageTestCounter + 1
  if not msgTest then
    return
  end
  local key = msgTest.key
  local msg = msgTest.msg and key or "You should not see this "..key
  local sound = msgTest.sound and "Info" or "Inferno"
  mod:AddMsg(key, msg, 1, sound)

  mod:AddTimerBar("MSG_SETTINGS", "Next message tests", 1, false, nil, mod.MessageTest, mod)
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
  assert(args1 ~= nil, "Old args for "..eventName.." not found")
  assert(args2 ~= nil, "Unit event args for "..eventName.." not found")
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
