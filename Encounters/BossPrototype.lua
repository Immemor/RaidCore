------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--
-- EncounterPrototype contains all services useable by encounters itself.
--
------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GroupLib = require "GroupLib"
local Vector3 = require "Vector3"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local Assert = Apollo.GetPackage("RaidCore:Assert-1.0").tPackage
local EncounterPrototype = {}

------------------------------------------------------------------------------
-- Locals
------------------------------------------------------------------------------
local function RegisterLocale(tBoss, sLanguage, Locales)
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local sName = "RaidCore_" .. tBoss:GetName()
  local L = GeminiLocale:NewLocale(sName, sLanguage, sLanguage == "enUS", true)
  if L then
    for key, val in next, Locales do
      L[key] = val
    end
  end
end

local function DeepInit (obj, ...)
  if obj == nil then
    obj = {}
  end
  local root = obj
  for i = 1, select('#', ...) do
    local key = select(i, ...)
    if obj[key] == nil then
      obj[key] = {}
    end
    obj = obj[key]
  end
  return root
end

------------------------------------------------------------------------------
-- Encounter Prototype.
------------------------------------------------------------------------------
function EncounterPrototype:RegisterTrigMob(nTrigType, tTrigList)
  tTrigList = type(tTrigList) == "string" and {tTrigList} or tTrigList
  Assert:Table(tTrigList, "Trigger names is not a table: %s, %s", self.name, tostring(tTrigList))
  Assert:EmptyTable(tTrigList, "Trigger names table is empty: %s", self.name)
  Assert:EqualOr(nTrigType, {RaidCore.E.TRIGGER_ALL, RaidCore.E.TRIGGER_ANY},
    "Invalid trigger type: %s, %s", self.name, tostring(nTrigType)
  )
  if nTrigType == RaidCore.E.TRIGGER_ANY then
    self.OnTrigCheck = self.OnTrigAny
  elseif nTrigType == RaidCore.E.TRIGGER_ALL then
    self.OnTrigCheck = self.OnTrigAll
  end
  self.tTriggerNames = tTrigList
end

-- Register a default config for bar manager.
-- @param tConfig Array of Timer Options indexed by the timer's key.
function EncounterPrototype:RegisterDefaultTimerBarConfigs(tConfig)
  Assert:Table(tConfig)
  self.tDefaultTimerBarsOptions = tConfig
end

-- Register a default setting which will be saved in user profile file.
-- @param sKey key to save/restore and use a setting.
-- @param bDefaultSetting default setting.
function EncounterPrototype:RegisterDefaultSetting(sKey, bDefaultSetting)
  Assert:NotNilOrFalse(sKey, "Key is empty: %s", self.name)
  Assert:Nil(self.tDefaultSettings[sKey], "Default setting already set: %s, %s", self.name, sKey)
  self.tDefaultSettings[sKey] = bDefaultSetting == nil or bDefaultSetting
end

-- Bind a message and sound settings to a message id to internally check
-- if they should be displayed or sound not played.
-- @param sKey key of the message.
-- @param compareType Comparism type, RaidCore.E.COMPARE_EQUAL, RaidCore.E.COMPARE_MATCH, RaidCore.E.COMPARE_FIND.
-- @param sMsgSetting Message setting id.
-- @param sSoundSetting Sound setting id.
function EncounterPrototype:RegisterMessageSetting(sKey, compareType, sMsgSetting, sSoundSetting)
  Assert:NotNilOrFalse(sKey, "Key is empty: %s", self.name)
  Assert:EqualOr(compareType, {RaidCore.E.COMPARE_MATCH, RaidCore.E.COMPARE_FIND, RaidCore.E.COMPARE_EQUAL},
    "Invalid comparism type: %s, %s", self.name, tostring(compareType)
  )
  --Most of the matches will be EQUAL so use a faster hashtable to look up settings
  if compareType == RaidCore.E.COMPARE_EQUAL then
    self.tSettingBindsEqual[sKey] = {
      sMsgSetting = sMsgSetting,
      sSoundSetting = sSoundSetting,
    }
  else
    table.insert(self.tSettingBinds, {
        sKey = sKey,
        compareType = compareType,
        sMsgSetting = sMsgSetting,
        sSoundSetting = sSoundSetting,
      }
    )
  end
end

function EncounterPrototype:GetSettingsForKey(sKey)
  if self.tSettingBindsEqual[sKey] then
    return self.tSettingBindsEqual[sKey]
  end

  local nCount = #self.tSettingBinds
  for i = 1, nCount do
    local tSettingBind = self.tSettingBinds[i]
    local compareType = tSettingBind.compareType
    local sMsgKey = tSettingBind.sKey
    local result = nil

    if compareType == RaidCore.E.COMPARE_EQUAL then
      result = sMsgKey == sKey or nil
    elseif compareType == RaidCore.E.COMPARE_FIND then
      result = sKey:find(sMsgKey)
    elseif compareType == RaidCore.E.COMPARE_MATCH then
      result = sKey:match(sMsgKey)
    end
    if result ~= nil then
      return tSettingBind
    end
  end

  return {}
end

function EncounterPrototype:AddUnit(tUnit, barColor, nPriority, tMarkers)
  Assert:Userdata(tUnit, "Not a unit: %s, %s", self.name, tostring(tUnit))
  local tUnitBarConfig = self.tUnitBarConfig[tUnit:GetName()] or {}
  RaidCore:AddUnit(tUnit,
    tUnitBarConfig.barColor or barColor,
    tUnitBarConfig.nPriority or nPriority,
    tUnitBarConfig.tMidphases or tMarkers
  )
end

-- Set default settings for a unit bar
-- @param sUnitName Name of the unit
-- @param tUnitBarConfig Table of configs containing: barColor, nPriority, table of midphases
function EncounterPrototype:RegisterUnitBarConfig(sUnitName, tUnitBarConfig)
  Assert:String(sUnitName, "Unit name not a string: %s, %s", self.name, tostring(sUnitName))
  Assert:Table(tUnitBarConfig, "Unit config not a table: %s, %s", self.name, tostring(tUnitBarConfig))
  sUnitName = self.L[sUnitName]
  self.tUnitBarConfig = DeepInit(self.tUnitBarConfig, sUnitName)
  self.tUnitBarConfig[sUnitName].barColor = tUnitBarConfig.barColor
  self.tUnitBarConfig[sUnitName].nPriority = tUnitBarConfig.nPriority

  if tUnitBarConfig.tMidphases then
    self:RegisterMidphases(sUnitName, tUnitBarConfig.tMidphases)
  end
end

function EncounterPrototype:IsMidphaseClose(sUnitName, nPercent)
  local tUnitBarConfig = self.tUnitBarConfig[self.L[sUnitName]] or {}
  if tUnitBarConfig.tMidphases then
    for i = 1, #tUnitBarConfig.tMidphases do
      local tMidphase = tUnitBarConfig.tMidphases[i]
      if nPercent >= tMidphase.lower and nPercent <= tMidphase.upper then
        return true
      end
    end
  end
  return false
end

-- Set midphases for a unit
-- @param sUnitName Name of the unit
-- @param tMidphases Table containing midphases.
function EncounterPrototype:RegisterMidphases(sUnitName, tMidphases)
  Assert:String(sUnitName, "Unit name not a string: %s, %s", self.name, tostring(sUnitName))
  Assert:Table(tMidphases, "Phases not a table: %s, %s", self.name, tostring(tMidphases))
  for i = 1, #tMidphases do
    self:RegisterMidphase(sUnitName, tMidphases[i])
  end
end

-- Set midphases for a unit
-- @param sUnitName Name of the unit
-- @param tMidphase Table containing possible attributes:
-- percent, color(optional), startPercent(optional), endPercent(optional), opacity(optional)
function EncounterPrototype:RegisterMidphase(sUnitName, tMidphase)
  Assert:String(sUnitName, "Unit name not a string: %s, %s", self.name, tostring(sUnitName))
  Assert:Table(tMidphase, "Phase not a table: %s, %s", self.name, tostring(tMidphase))
  Assert:Number(tMidphase.percent, "Missing midphase percent: %s, %s", self.name, tostring(tMidphase.percent))

  if not tMidphase.startPercent then
    tMidphase.startPercent = tMidphase.percent - 0.75
  end
  if not tMidphase.endPercent then
    tMidphase.endPercent = tMidphase.percent + 0.75
  end
  tMidphase.color = tMidphase.color or "xkcdRed"
  tMidphase.opacity = tMidphase.opacity or 1
  --TODO add these thresholds to some variable for adjustable calls?
  tMidphase.lower = tMidphase.percent + 1 - 0.05
  tMidphase.upper = tMidphase.percent + 1 + 0.05

  sUnitName = self.L[sUnitName]
  self.tUnitBarConfig = DeepInit(self.tUnitBarConfig, sUnitName, "tMidphases")
  table.insert(self.tUnitBarConfig[sUnitName].tMidphases, tMidphase)
end

-- Register events to a single unit or a list of units
-- @param sUnitName String or table of Strings of unit names.
-- @param tEventsHandlers Table of Events/Handlers pairs
function EncounterPrototype:RegisterUnitEvents(tUnitNames, tEventsHandlers)
  tUnitNames = type(tUnitNames) == "string" and {tUnitNames} or tUnitNames
  Assert:Table(tUnitNames, "Unit names not a table: %s, %s", self.name, tostring(tUnitNames))
  Assert:Table(tEventsHandlers, "Event handlers not a table: %s, %s", self.name, tostring(tEventsHandlers))
  Assert:EmptyTable(tEventsHandlers, "Event handlers table empty: %s, %s", self.name, tostring(tEventsHandlers))

  local nSize = #tUnitNames
  for i = 1, nSize do
    local sUnitName = tUnitNames[i]
    for sMethodName, fHandler in next, tEventsHandlers do
      if type(fHandler) == "table" then
        self:RegisterUnitSpellEvents(sUnitName, sMethodName, fHandler)
      else
        self:RegisterUnitEvent(sUnitName, sMethodName, fHandler)
      end
    end
  end
end

-- Register cast events to a single unit or a list of units
-- @param tUnitNames String or table of Strings of unit names.
-- @param primaryKey Parent key of the table OnCastStart or castName/buffId
-- @param tEventsHandlers Table of Events/Handlers pairs
local SPELL_EVENTS = {
  [RaidCore.E.CAST_START] = true,
  [RaidCore.E.CAST_END] = true,
  [RaidCore.E.BUFF_ADD] = true,
  [RaidCore.E.BUFF_UPDATE] = true,
  [RaidCore.E.BUFF_REMOVE] = true,
  [RaidCore.E.DEBUFF_ADD] = true,
  [RaidCore.E.DEBUFF_UPDATE] = true,
  [RaidCore.E.DEBUFF_REMOVE] = true,
  [RaidCore.E.NPC_SAY] = true, -- Not really spells but the format is the same:
  [RaidCore.E.NPC_YELL] = true, -- Bind by name and a second string
  [RaidCore.E.NPC_WHISPER] = true,
}
function EncounterPrototype:RegisterUnitSpellEvents(tUnitNames, primaryKey, tEventHandlers)
  tUnitNames = type(tUnitNames) == "string" and {tUnitNames} or tUnitNames
  Assert:Table(tUnitNames, "Unit names not a table: %s, %s", self.name, tostring(tUnitNames))
  Assert:Table(tEventHandlers, "Event handlers not a table: %s, %s", self.name, tostring(tEventHandlers))
  Assert:EmptyTable(tEventHandlers, "Event handlers table empty: %s, %s", self.name, tostring(tEventHandlers))
  Assert:TypeOr(primaryKey, {Assert.TYPES.STRING, Assert.TYPES.NUMBER},
    "Invalid type for primary key: %s, %s", self.name, tostring(primaryKey)
  )

  local nSize = #tUnitNames
  for i = 1, nSize do
    local sUnitName = tUnitNames[i]
    local isEventFirst = SPELL_EVENTS[primaryKey] == true
    for secondaryKey, fHandler in next, tEventHandlers do
      local sMethodName = secondaryKey
      local sCastName = primaryKey
      if isEventFirst then
        sMethodName = primaryKey
        sCastName = secondaryKey
      end
      self:RegisterUnitSpellEvent(sUnitName, sMethodName, sCastName, fHandler)
    end
  end
end

-- Register cast events to a single unit or a list of units
-- @param sUnitName String or table of Strings of unit names.
-- @param sMethodName OnCastStart or OnCastEnd
-- @param sCastName Name of the cast or id of the buff
-- @param fHandler Function to handle the event
function EncounterPrototype:RegisterUnitSpellEvent(sUnitName, sMethodName, spellId, fHandler)
  Assert:String(sUnitName, "Unit name not a string: %s, %s", self.name, tostring(sUnitName))
  Assert:String(sMethodName, "Method name not a string: %s, %s", self.name, tostring(sMethodName))
  Assert:Function(fHandler, "Handler not a function: %s, %s", self.name, tostring(fHandler))
  Assert:TypeOr(spellId, {Assert.TYPES.STRING, Assert.TYPES.NUMBER},
    "Invalid type for spell id: %s, %s", self.name, tostring(spellId)
  )

  sUnitName = self.L[sUnitName]
  if type(spellId) == "string" then
    spellId = self.L[spellId]
  end
  self.tUnitSpellEvents = DeepInit(self.tUnitSpellEvents, sMethodName, sUnitName, spellId)
  table.insert(self.tUnitSpellEvents[sMethodName][sUnitName][spellId], fHandler)
end

-- Register events to a datachron message
-- @param sSearchMessage The message or parts of it
-- @param compareType COMPARE_EQUAL, COMPARE_FIND or COMPARE_MATCH for comparing the sSearchMessage
-- @param fHandler Function to handle the event
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:RegisterDatachronEvent(sSearchMessage, compareType, fHandler)
  Assert:String(sSearchMessage, "Datachron message not a string: %s, %s", self.name, tostring(sSearchMessage))
  Assert:Function(fHandler, "Handler not a function: %s, %s", self.name, tostring(fHandler))
  Assert:EqualOr(compareType, {RaidCore.E.COMPARE_MATCH, RaidCore.E.COMPARE_FIND, RaidCore.E.COMPARE_EQUAL},
    "Invalid comparism type: %s, %s", self.name, tostring(compareType)
  )

  sSearchMessage = self.L[sSearchMessage]
  if compareType == RaidCore.E.COMPARE_EQUAL then
    self.tDatachronEventsEqual = DeepInit(self.tDatachronEventsEqual, sSearchMessage)
    table.insert(self.tDatachronEventsEqual[sSearchMessage], fHandler)
  else
    self.tDatachronEvents = DeepInit(self.tDatachronEvents, sSearchMessage)
    table.insert(self.tDatachronEvents[sSearchMessage], {fHandler = fHandler, compareType = compareType })
  end
end

-- Register events to a single unit
-- @param sUnitName Name of the unit
-- @param sMethodName Name of the event
-- @param fHandler Function to handle the event
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:RegisterUnitEvent(sUnitName, sMethodName, fHandler)
  Assert:String(sUnitName, "Unit name not a string: %s, %s", self.name, tostring(sUnitName))
  Assert:String(sMethodName, "Method name not a string: %s, %s", self.name, tostring(sMethodName))
  Assert:Function(fHandler, "Handler not a function: %s, %s", self.name, tostring(fHandler))

  sUnitName = self.L[sUnitName]
  self.tUnitEvents = DeepInit(self.tUnitEvents, sMethodName, sUnitName)
  table.insert(self.tUnitEvents[sMethodName][sUnitName], fHandler)
end

-- Add a message to screen.
-- @param sKey Index which will be used to match on AddMsg.
-- @param sEnglishText English text to search in language dictionnary.
-- @param nDuration Timer duration.
-- @param sSound The sound to be played back.
-- @param sColor The color of the message.
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddMsg(sKey, sEnglishText, nDuration, sSound, sColor)
  local bPlaySound = sSound and true
  local bShowMessage = sEnglishText and true
  local tSettings = self:GetSettingsForKey(sKey)
  if bPlaySound and type(tSettings.sSoundSetting) == "string" then
    bPlaySound = self:GetSetting(tSettings.sSoundSetting)
  end
  if bShowMessage and type(tSettings.sMsgSetting) == "string" then
    bShowMessage = self:GetSetting(tSettings.sMsgSetting)
  end

  if bShowMessage then
    sSound = bPlaySound == true and sSound
    RaidCore:AddMsg(sKey, self.L[sEnglishText], nDuration, sSound, sColor)
  elseif bPlaySound then
    RaidCore:PlaySound(sSound)
  end
end

-- Create a timer bar.
-- @param sKey Index which will be used to match on AddTimerBar.
-- @param sEnglishText English text to search in language dictionnary.
-- @param nDuration Timer duration.
-- @param bEmphasize Timer count down requested (nil take the default one).
-- @param sColor Color for the timer bar (nil take the default one)..
-- @param fHandler function to call on timeout
-- @param tClass Class used by callback action on timeout
-- @param tData Data forwarded by callback action on timeout
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddTimerBar(sKey, sEnglishText, nDuration, bEmphasize, sColor, fHandler, tClass, tData)
  local tOptions = {}
  local sLocalText = self.L[sEnglishText]
  if self.tDefaultTimerBarsOptions[sKey] then
    tOptions = self.tDefaultTimerBarsOptions[sKey]
  end
  if bEmphasize ~= nil then
    tOptions["bEmphasize"] = bEmphasize and true
  end
  if sColor ~= nil then
    assert(type(sColor) == "string")
    tOptions["sColor"] = sColor
  end
  local tCallback = nil
  if type(fHandler) == "function" then
    tCallback = {
      fHandler = fHandler,
      tClass = tClass,
      tData = tData,
    }
  end
  RaidCore:AddTimerBar(sKey, sLocalText, nDuration, tCallback, tOptions)
end

function EncounterPrototype:ExtendTimerBar(sKey, nDurationToAdd)
  RaidCore:ExtendTimerBar(sKey, nDurationToAdd)
end

-- Remove a timer bar if exist.
-- @param sKey Index to remove.
function EncounterPrototype:RemoveTimerBar(sKey)
  RaidCore:RemoveTimerBar(sKey)
end

-- Create a progress bar.
-- @param sKey Index which will be used to match on AddTimerBar.
-- @param sEnglishText English text to search in language dictionnary.
-- @param fHandler function to call to get progress
-- @param tClass Class used by update action on a timer
-- @param fHandler function to call to get progress
-- @param tClass Class used by update action on a timer
-- @param sColor Color of the bar
-- @param nPriority Order index of the bar compared to others 1-99
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddProgressBar(sKey, sEnglishText, fHandler, tClass, fHandler2, sColor, nPriority)
  local tOptions = {}
  local sLocalText = self.L[sEnglishText]
  if self.tDefaultTimerBarsOptions[sKey] then
    tOptions = self.tDefaultTimerBarsOptions[sKey]
  end
  tOptions.sColor = sColor or tOptions.sColor
  tOptions.nPriority = nPriority or tOptions.nPriority
  local tUpdate = nil
  if type(fHandler) == "function" then
    tUpdate = {
      fHandler = fHandler,
      tClass = tClass,
    }
  end
  local tCallback = nil
  if type(fHandler2) == "function" then
    tCallback = {
      fHandler = fHandler2,
      tClass = tClass,
    }
  end
  RaidCore:AddProgressBar(sKey, sLocalText, tUpdate, tOptions, tCallback)
end

-- Remove a progress bar if exist.
-- @param sKey Index to remove.
function EncounterPrototype:RemoveProgressBar(sKey)
  RaidCore:RemoveProgressBar(sKey)
end

-- Marks a unit with text
-- @param tUnit the unit
-- @param nLocation location of the mark
-- @param sEnglishText English text
-- @param sColor Color of the text
function EncounterPrototype:MarkUnit(tUnit, nLocation, sText, sColor)
  RaidCore:MarkUnit(tUnit, nLocation, self.L[sText], sColor)
end

function EncounterPrototype:TranslateTriggerNames()
  local tmp = {}
  for _, EnglishKey in next, self.tTriggerNames do
    table.insert(tmp, self.L[EnglishKey])
  end
  self.tTriggerNames = tmp
end

function EncounterPrototype:PrepareEncounter()
  self:TranslateTriggerNames()
end

function EncounterPrototype:CallIfExists(sFunctionName)
  if type(self[sFunctionName]) == "function" then
    self[sFunctionName](self)
  end
end

function EncounterPrototype:CopySettings()
  self.tSettings = {}
  local tSettings = RaidCore.db.profile.Encounters[self:GetName()]
  if tSettings then
    for k,v in next, tSettings do
      self.tSettings[k] = v
    end
  end
end

function EncounterPrototype:OnEnable()
  self:CopySettings()
  -- TODO: Redefine this part.
  self.tDispelInfo = {}
  self:CallIfExists("SetupOptions")
  self:CallIfExists("OnBossEnable")
end

function EncounterPrototype:OnDisable()
  self:CallIfExists("OnBossDisable")
  self:CancelAllTimers()
  self:CallIfExists("OnWipe")
  self.tDispelInfo = nil
end

function EncounterPrototype:RegisterEnglishLocale(Locales)
  RegisterLocale(self, "enUS", Locales)
end

function EncounterPrototype:RegisterGermanLocale(Locales)
  RegisterLocale(self, "deDE", Locales)
end

function EncounterPrototype:RegisterFrenchLocale(Locales)
  RegisterLocale(self, "frFR", Locales)
end

-- Get setting value through the key.
-- @param sKey index in the array.
-- @return the key itself or false.
function EncounterPrototype:GetSetting(sKey)
  if self.tSettings[sKey] == nil then
    Print(("RaidCore warning: In '%s', setting \"%s\" don't exist."):format(self:GetName(), tostring(sKey)))
    self.tSettings[sKey] = false
  end
  return self.tSettings[sKey]
end

function EncounterPrototype:IsPlayerTank()
  local unit = GroupLib.GetGroupMember(1)
  if unit then return unit.bTank end
end

--- Compute the distance between 2 unit.
-- @param tUnitFrom userdata object from carbine.
-- @param tUnitTo userdata object from carbine.
-- @return The distance in meter.
function EncounterPrototype:GetDistanceBetweenUnits(tUnitFrom, tUnitTo)
  -- XXX If unit are unreachable, the distance should be nil.
  local r = 999
  if tUnitFrom and tUnitTo then
    local positionA = tUnitFrom:GetPosition()
    local positionB = tUnitTo:GetPosition()
    if positionA and positionB then
      local vectorA = Vector3.New(positionA)
      local vectorB = Vector3.New(positionB)
      r = (vectorB - vectorA):Length()
    end
  end
  return r
end

function EncounterPrototype:IsSpell2Dispel(nId)
  if self.tDispelInfo[nId] then
    return next(self.tDispelInfo[nId]) ~= nil
  end
  return false
end

function EncounterPrototype:AddSpell2Dispel(nId, nSpellId)
  if not self.tDispelInfo[nId] then
    self.tDispelInfo[nId] = {}
  end
  self.tDispelInfo[nId][nSpellId] = true
  RaidCore:AddPicture(("DISPEL%d"):format(nId), nId, "DispelWord", 30)
end

function EncounterPrototype:RemoveSpell2Dispel(nId, nSpellId)
  if self.tDispelInfo[nId] and self.tDispelInfo[nId][nSpellId] then
    self.tDispelInfo[nId][nSpellId] = nil
  end
  if not self:IsSpell2Dispel(nId) then
    RaidCore:RemovePicture(("DISPEL%d"):format(nId))
  end
end

function EncounterPrototype:SendIndMessage(sReason, tData)
  local msg = {
    action = RaidCore.E.COMM_ENCOUNTER_IND,
    reason = sReason,
    data = tData,
  }
  RaidCore:SendMessage(msg)
end

function EncounterPrototype:OnTrigAny(tNames)
  for _, sMobName in next, self.tTriggerNames do
    if tNames[sMobName] then
      for _, tUnit in next, tNames[sMobName] do
        if tUnit:IsValid() and tUnit:IsInCombat() then
          return true
        end
      end
    end
  end
  return false
end

function EncounterPrototype:OnTrigAll(tNames)
  for _, sMobName in next, self.tTriggerNames do
    if not tNames[sMobName] then
      return false
    else
      local bResult = false
      for _, tUnit in next, tNames[sMobName] do
        if tUnit:IsValid() and tUnit:IsInCombat() then
          bResult = true
        end
      end
      if not bResult then
        return false
      end
    end
  end
  return true
end

--- Default trigger function to start an encounter.
-- @param tNames Names of units without break space.
-- @return Any unit registered can start the encounter.
function EncounterPrototype:OnTrig(tNames)
  if not self:IsTestEncounterEnabled() and self:IsTestEncounter() then return false end
  if not self:IsEncounterEnabled() then return false end
  return self:OnTrigCheck(tNames)
end

function EncounterPrototype:IsTestEncounter()
  return self.isTestEncounter
end

function EncounterPrototype:IsTestEncounterEnabled()
  return RaidCore.db.profile.bEnableTestEncounters
end

function EncounterPrototype:IsEncounterEnabled()
  return RaidCore.db.profile.Encounters[self:GetName()].Enabled
end

-- Create a world marker.
-- @param sKey Index which will be used to match on SetMarker.
-- @param sText Text key to search in language dictionnary.
-- @param tPosition Position of the marker
--
-- Note: If the Text key is not found, the current string will be used like that.
function EncounterPrototype:SetWorldMarker(sKey, sText, tPosition, sColor)
  RaidCore:SetWorldMarker(sKey, self.L[sText], tPosition, sColor)
end

function EncounterPrototype:DropWorldMarker(sKey)
  RaidCore:DropWorldMarker(sKey)
end

function EncounterPrototype:ResetWorldMarkers()
  RaidCore:ResetWorldMarkers()
end

------------------------------------------------------------------------------
-- RaidCore interaction
------------------------------------------------------------------------------
do
  -- Sub modules are created when lua files are loaded by the WildStar.
  -- Default setting must be done before encounter loading so.
  RaidCore:SetDefaultModulePrototype(EncounterPrototype)
  RaidCore:SetDefaultModuleState(false)
  RaidCore:SetDefaultModulePackages("Gemini:Timer-1.0")
end

--- Registering a new encounter as a sub module of RaidCore.
--@param name Name of the encounter to create
--@param continentId Id list or id number
--@param parentMapId Id list or id number
--@param mapId Id list or id number
--@param isTestEncounter
function RaidCore:NewEncounter(name, continentId, parentMapId, mapId, isTestEncounter)
  continentId = type(continentId) == "number" and {continentId} or continentId
  parentMapId = type(parentMapId) == "number" and {parentMapId} or parentMapId
  mapId = type(mapId) == "number" and {mapId} or mapId
  Assert:String(name, "Encounter name not a string: %s", tostring(name))
  Assert:Table(continentId, "continentId not a table: %s, %s", tostring(name), tostring(continentId))
  Assert:Table(parentMapId, "parentMapId not a table: %s, %s", tostring(name), tostring(parentMapId))
  Assert:Table(mapId, "mapId not a table: %s, %s", tostring(name), tostring(mapId))

  -- Create the new encounter, and set zone identifiers.
  -- Library already manage unique name.
  local new = self:NewModule(name)
  new.continentIdList = continentId
  new.parentMapIdList = parentMapId
  new.mapIdList = mapId
  new.name = name
  new.isTestEncounter = isTestEncounter
  new.tDefaultTimerBarsOptions = {}
  new.tTriggerNames = {}
  -- Register an empty locale table.
  new:RegisterEnglishLocale({})
  -- Retrieve Locale.
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  new.L = GeminiLocale:GetLocale("RaidCore_" .. name)
  -- Create a empty array for settings.
  new.tDefaultSettings = {Enabled = true}
  new.tUnitEvents = {}
  new.tDatachronEvents = {}
  new.tDatachronEventsEqual = {}
  new.tUnitSpellEvents = {}
  new.tSettingBinds = {}
  new.tSettingBindsEqual = {}
  new.tUnitBarConfig = {}
  return new
end
