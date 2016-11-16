----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description: TODO
----------------------------------------------------------------------------------------------------
require "Apollo"
require "Window"
require "GameLib"
require "ChatSystemLib"

local GeminiAddon = Apollo.GetPackage("Gemini:Addon-1.1").tPackage
local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
local RaidCore = GeminiAddon:NewAddon("RaidCore", false, {}, "Gemini:Timer-1.0")
local Log = Apollo.GetPackage("Log-1.0").tPackage

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetCurrentZoneMap = GameLib.GetCurrentZoneMap
local next, pcall = next, pcall

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Should be 5.23 when replacement tokens will works (see #88 issue).
local RAIDCORE_CURRENT_VERSION = "6.3.0-beta"
-- Should be deleted.
local ADDON_DATE_VERSION = 16111619

-- State Machine.
local MAIN_FSM__SEARCH = 1
local MAIN_FSM__RUNNING = 2

RaidCore.E = {
  -- Events.
  UNIT_CREATED = "OnUnitCreated",
  UNIT_DESTROYED = "OnUnitDestroyed",
  ENTERED_COMBAT = "OnEnteredCombat",
  BUFF_ADD = "OnBuffAdd",
  BUFF_UPDATE = "OnBuffUpdate",
  BUFF_REMOVE = "OnBuffRemove",
  DEBUFF_ADD = "OnDebuffAdd",
  DEBUFF_UPDATE = "OnDebuffUpdate",
  DEBUFF_REMOVE = "OnDebuffRemove",
  CAST_START = "OnCastStart",
  CAST_END = "OnCastEnd",
  HEALTH_CHANGED = "OnHealthChanged",
  DATACHRON = "OnDatachron",
  NPC_SAY = "OnNPCSay",
  NPC_YELL = "OnNPCYell",
  NPC_WHISPER = "OnNPCWhisper",
  COMBAT_LOG_HEAL = "OnCombatLogHeal",
  SHOW_SHORTCUT_BAR = "OnShowShortcutBar",
  -- Special Keywords.
  ALL_UNITS = "**",
  NO_BREAK_SPACE = string.char(194, 160),
  -- Tracking.
  TRACK_ALL = 0xFF,
  TRACK_BUFFS = 0x01,
  TRACK_CASTS = 0x02,
  TRACK_HEALTH = 0x04,
  -- Locations.
  LOCATION_STATIC_FLOOR = 0,
  LOCATION_STATIC_NAME = 1,
  LOCATION_LEFT_ASS = 34,
  LOCATION_RIGHT_ASS = 35,
  LOCATION_STATIC_CHEST = 40,
  -- Core Events.
  CHANGE_WORLD = "OnChangeWorld",
  SUB_ZONE_CHANGE = "OnSubZoneChanged",
  RECEIVED_MESSAGE = "OnReceivedMessage",
  CHARACTER_CREATED = "OnCharacterCreated",
  -- Combat Interface States.
  INTERFACE_DISABLE = 1,
  INTERFACE_DETECTCOMBAT = 2,
  INTERFACE_DETECTALL = 3,
  INTERFACE_LIGHTENABLE = 4,
  INTERFACE_FULLENABLE = 5,
  -- Comparism types.
  COMPARE_EQUAL = 1,
  COMPARE_FIND = 2,
  COMPARE_MATCH = 3,
  -- Log.
  ERROR = "ERROR",
  CURRENT_ZONE_MAP = "CurrentZoneMap",
  TRACK_UNIT = "TrackThisUnit",
  UNTRACK_UNIT = "UnTrackThisUnit",
  JOIN_CHANNEL_TRY = "JoinChannelTry",
  JOIN_CHANNEL_STATUS = "JoinChannelStatus",
  CHANNEL_COMM_STATUS = "ChannelCommStatus",
  SEND_MESSAGE = "SendMessage",
  SEND_MESSAGE_RESULT = "SendMessageResult",
  -- Carbine Events.
  EVENT_COMBAT_LOG_HEAL = "CombatLogHeal",
  EVENT_UNIT_ENTERED_COMBAT = "UnitEnteredCombat",
  EVENT_UNIT_CREATED = "UnitCreated",
  EVENT_UNIT_DESTROYED = "UnitDestroyed",
  EVENT_CHAT_MESSAGE = "ChatMessage",
  EVENT_SHOW_ACTION_BAR_SHORTCUT = "ShowActionBarShortcut",
  EVENT_BUFF_ADDED = "BuffAdded",
  EVENT_BUFF_UPDATED = "BuffUpdated",
  EVENT_BUFF_REMOVED = "BuffRemoved",
  EVENT_CHANGE_WORLD = "ChangeWorld",
  EVENT_SUB_ZONE_CHANGED = "SubZoneChanged",
  EVENT_NEXT_FRAME = "NextFrame",
  EVENT_WINDOWS_MANAGEMENT_READY = "WindowManagementReady",
  EVENT_CHARACTER_CREATED = "CharacterCreated",
  -- Comm events. Using numbers for these instead to save bandwidth would break
  -- compatibility with older versions of raidcore.
  COMM_VERSION_CHECK_REQUEST = "VersionCheckRequest",
  COMM_VERSION_CHECK_REPLY = "VersionCheckReply",
  COMM_NEWEST_VERSION = "NewestVersion",
  COMM_LAUNCH_PULL = "LaunchPull",
  COMM_LAUNCH_BREAK = "LaunchBreak",
  COMM_SYNC_SUMMON = "SyncSummon",
  COMM_ENCOUNTER_IND = "Encounter_IND",
  -- Triggers
  TRIGGER_ALL = 1,
  TRIGGER_ANY = 2,
}

local EVENT_UNIT_NAME_INDEX = {
  [RaidCore.E.UNIT_CREATED] = 3,
  [RaidCore.E.UNIT_DESTROYED] = 3,
  [RaidCore.E.CAST_START] = 4,
  [RaidCore.E.CAST_END] = 5,
  [RaidCore.E.HEALTH_CHANGED] = 3,
  [RaidCore.E.ENTERED_COMBAT] = 3,
  [RaidCore.E.BUFF_ADD] = 5,
  [RaidCore.E.BUFF_UPDATE] = 5,
  [RaidCore.E.BUFF_REMOVE] = 3,
  [RaidCore.E.DEBUFF_ADD] = 5,
  [RaidCore.E.DEBUFF_UPDATE] = 5,
  [RaidCore.E.DEBUFF_REMOVE] = 3,
  [RaidCore.E.NPC_SAY] = 2,
  [RaidCore.E.NPC_YELL] = 2,
  [RaidCore.E.NPC_WHISPER] = 2,
}

local EVENT_UNIT_SPELL_ID_INDEX = {
  [RaidCore.E.CAST_START] = 2,
  [RaidCore.E.CAST_END] = 2,
  [RaidCore.E.BUFF_ADD] = 2,
  [RaidCore.E.BUFF_UPDATE] = 2,
  [RaidCore.E.BUFF_REMOVE] = 2,
  [RaidCore.E.DEBUFF_ADD] = 2,
  [RaidCore.E.DEBUFF_UPDATE] = 2,
  [RaidCore.E.DEBUFF_REMOVE] = 2,
  [RaidCore.E.NPC_SAY] = 1,
  [RaidCore.E.NPC_YELL] = 1,
  [RaidCore.E.NPC_WHISPER] = 1,
}

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _tWipeTimer
local _tTrigPerZone = {}
local _tEncountersPerZone = {}
local _tDelayedUnits = {}
local _bIsEncounterInProgress = false
local _tCurrentEncounter = nil
local _eCurrentFSM
local _tMainFSMHandlers
local markCount = 0
local VCReply, VCtimer = {}, nil

----------------------------------------------------------------------------------------------------
-- Privates functions
----------------------------------------------------------------------------------------------------
local function OnEncounterUnitEvents(sMethod, ...)
  if EVENT_UNIT_NAME_INDEX[sMethod] == nil then
    return
  end
  local sName = select(EVENT_UNIT_NAME_INDEX[sMethod], ...)

  -- Check if any events are bound
  local tUnitEvents = _tCurrentEncounter.tUnitEvents
  tUnitEvents = tUnitEvents and tUnitEvents[sMethod]

  if not tUnitEvents then return end

  -- Check for events bound by name
  local tHandlers = tUnitEvents[sName] or {}
  local nSize = #tHandlers
  for i = 1, nSize do
    tHandlers[i](_tCurrentEncounter, ...)
  end

  -- Check for events bound for all units
  local tAnyHandlers = tUnitEvents[RaidCore.E.ALL_UNITS] or {}
  nSize = #tAnyHandlers
  for i = 1, nSize do
    tAnyHandlers[i](_tCurrentEncounter, ...)
  end
end

local function OnEncounterUnitSpellEvents(sMethod, ...)
  if EVENT_UNIT_NAME_INDEX[sMethod] == nil or EVENT_UNIT_SPELL_ID_INDEX[sMethod] == nil then
    return
  end
  local sName = select(EVENT_UNIT_NAME_INDEX[sMethod], ...)
  local spellId = select(EVENT_UNIT_SPELL_ID_INDEX[sMethod], ...)

  -- Check if any events are bound
  local tUnitSpellEvents = _tCurrentEncounter.tUnitSpellEvents
  tUnitSpellEvents = tUnitSpellEvents and tUnitSpellEvents[sMethod]

  if not tUnitSpellEvents then return end

  -- Check for events bound by name
  local tUnitHandlers = tUnitSpellEvents[sName]
  tUnitHandlers = tUnitHandlers and tUnitHandlers[spellId] or {}
  local nSize = #tUnitHandlers
  for i = 1, nSize do
    tUnitHandlers[i](_tCurrentEncounter, ...)
  end

  -- Check for events bound for all units
  local tAnyHandlers = tUnitSpellEvents[RaidCore.E.ALL_UNITS]
  tAnyHandlers = tAnyHandlers and tAnyHandlers[spellId] or {}
  nSize = #tAnyHandlers
  for i = 1, nSize do
    tAnyHandlers[i](_tCurrentEncounter, ...)
  end
end

local function OnEncounterDatachronEvents(sMethod, ...)
  if sMethod ~= RaidCore.E.DATACHRON then
    return
  end
  local sMessage = ...
  local tDatachronEvents = _tCurrentEncounter.tDatachronEvents or {}
  local tDatachronEventsEqual = _tCurrentEncounter.tDatachronEventsEqual or {}
  tDatachronEventsEqual = tDatachronEventsEqual and tDatachronEventsEqual[sMessage] or {}

  local nSize = #tDatachronEventsEqual
  for i = 1, nSize do
    tDatachronEventsEqual[i](_tCurrentEncounter, sMessage, true)
  end

  for sSearchMessage, tEvents in next, tDatachronEvents do
    nSize = #tEvents
    for i = 1, nSize do
      local tEvent = tEvents[i]
      local compareType = tEvent.compareType
      local fHandler = tEvent.fHandler
      local result = nil

      if compareType == RaidCore.E.COMPARE_FIND then
        result = sMessage:find(sSearchMessage)
      elseif compareType == RaidCore.E.COMPARE_MATCH then
        result = sMessage:match(sSearchMessage)
      end

      if result ~= nil then
        fHandler(_tCurrentEncounter, sMessage, result)
      end
    end
  end
end

local function OnEncounterHookGeneric(sMethod, ...)
  local fEncounter = _tCurrentEncounter[sMethod]
  if fEncounter then
    fEncounter(_tCurrentEncounter, ...)
  end

  OnEncounterUnitEvents(sMethod, ...)
  OnEncounterUnitSpellEvents(sMethod, ...)
  OnEncounterDatachronEvents(sMethod, ...)
end

local function RemoveDelayedUnit(nId, sName)
  if _tDelayedUnits[sName] then
    if _tDelayedUnits[sName][nId] then
      _tDelayedUnits[sName][nId] = nil
    end
    if next(_tDelayedUnits[sName]) == nil then
      _tDelayedUnits[sName] = nil
    end
  end
end

local function AddDelayedUnit(nId, tUnit, sName)
  local tMap = GetCurrentZoneMap()
  if tMap then
    local tTrig = _tTrigPerZone[tMap.continentId]
    tTrig = tTrig and tTrig[tMap.parentZoneId]
    tTrig = tTrig and tTrig[tMap.id]
    tTrig = tTrig and tTrig[sName]
    if tTrig then
      if not _tDelayedUnits[sName] then
        _tDelayedUnits[sName] = {}
      end
      _tDelayedUnits[sName][nId] = tUnit
    end
  end
end

local function SearchEncounter()
  local tMap = GetCurrentZoneMap()
  if tMap then
    local tEncounters = _tEncountersPerZone[tMap.continentId]
    tEncounters = tEncounters and tEncounters[tMap.parentZoneId]
    tEncounters = tEncounters and tEncounters[tMap.id] or {}
    local nSize = #tEncounters
    for i = 1, nSize do
      local tEncounter = tEncounters[i]
      if tEncounter:OnTrig(_tDelayedUnits) then
        _tCurrentEncounter = tEncounter
        break
      end
    end
  end
end

local function CleanDelayedUnits()
  for sName, tDelayedList in next, _tDelayedUnits do
    for nId, tUnit in next, tDelayedList do
      if not tUnit:IsValid() or tUnit:IsDead() then
        RemoveDelayedUnit(nId, sName)
      end
    end
  end
end

local function ProcessDelayedUnit()
  for nDelayedName, tDelayedList in next, _tDelayedUnits do
    for nDelayedId, tUnit in next, tDelayedList do
      if tUnit:IsValid() then
        local bInCombat = tUnit:IsInCombat()
        local s, e = pcall(OnEncounterHookGeneric, RaidCore.E.UNIT_CREATED, nDelayedId, tUnit, nDelayedName)
        RaidCore:HandlePcallResult(s, e)
        if bInCombat then
          s, e = pcall(OnEncounterHookGeneric, RaidCore.E.ENTERED_COMBAT, nDelayedId, tUnit, nDelayedName, bInCombat)
          RaidCore:HandlePcallResult(s, e)
        end
      end
    end
  end

  CleanDelayedUnits()
end

local function InitModuleZones(module, id1, id2, id3)
  _tTrigPerZone[id1] = _tTrigPerZone[id1] or {}
  _tTrigPerZone[id1][id2] = _tTrigPerZone[id1][id2] or {}
  _tTrigPerZone[id1][id2][id3] = _tTrigPerZone[id1][id2][id3] or {}
  _tEncountersPerZone[id1] = _tEncountersPerZone[id1] or {}
  _tEncountersPerZone[id1][id2] = _tEncountersPerZone[id1][id2] or {}
  _tEncountersPerZone[id1][id2][id3] = _tEncountersPerZone[id1][id2][id3] or {}

  table.insert(_tEncountersPerZone[id1][id2][id3], module)
  for _, Mob in next, module.tTriggerNames do
    _tTrigPerZone[id1][id2][id3][Mob] = true
  end
end
----------------------------------------------------------------------------------------------------
-- RaidCore Initialization
----------------------------------------------------------------------------------------------------
function RaidCore:Print(sMessage)
  ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug, tostring(sMessage), "RaidCore")
end

function RaidCore:OnInitialize()
  _tMainFSMHandlers = {
    [MAIN_FSM__SEARCH] = {
      [RaidCore.E.CHANGE_WORLD] = self.SEARCH_OnCheckMapZone,
      [RaidCore.E.SUB_ZONE_CHANGE] = self.SEARCH_OnCheckMapZone,
      [RaidCore.E.CHARACTER_CREATED] = self.SEARCH_OnCheckMapZone,
      [RaidCore.E.UNIT_CREATED] = self.SEARCH_OnUnitCreated,
      [RaidCore.E.ENTERED_COMBAT] = self.SEARCH_OnEnteredCombat,
      [RaidCore.E.UNIT_DESTROYED] = self.SEARCH_OnUnitDestroyed,
      [RaidCore.E.RECEIVED_MESSAGE] = self.SEARCH_OnReceivedMessage,
    },
    [MAIN_FSM__RUNNING] = {
      [RaidCore.E.ENTERED_COMBAT] = self.RUNNING_OnEnteredCombat,
      [RaidCore.E.RECEIVED_MESSAGE] = self.RUNNING_OnReceivedMessage,
      [RaidCore.E.UNIT_DESTROYED] = self.RUNNING_OnUnitDestroyed,
    },
  }
  _eCurrentFSM = MAIN_FSM__SEARCH
  self.xmlDoc = XmlDoc.CreateFromFile("RaidCore.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
  Apollo.LoadSprites("Textures_GUI.xml")
  Apollo.LoadSprites("Textures_Bars.xml")
  Apollo.LoadSprites("RaidCore_Draw.xml")
  Apollo.LoadTemplates("RaidCore_Templates.xml")

  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  self.L = GeminiLocale:GetLocale("RaidCore")
  local GeminiDB = Apollo.GetPackage("Gemini:DB-1.0").tPackage
  self.db = GeminiDB:New(self, nil, true)

  -- Create default settings to provide to GeminiDB.
  local tDefaultSettings = {
    profile = {
      version = RAIDCORE_CURRENT_VERSION,
      Encounters = {},
      BarsManagers = self:GetBarsDefaultSettings(),
      DrawManagers = self:GetDrawDefaultSettings(),
      -- Simple and general settings.
      bSoundEnabled = true,
      bAcceptSummons = true,
      bLUAErrorMessage = false,
      bReadyCheckOnBreakTimeout = true,
      sReadyCheckMessage = self.L["Raid Resume"],
      bEnableTestEncounters = false,
      bDisableSelectiveTracking = false,
    }
  }

  self.tCMD2function = {
    ["config"] = self.DisplayMainWindow,
    ["reset"] = self.ResetAll,
    ["versioncheck"] = self.VersionCheck,
    ["pull"] = self.LaunchPull,
    ["break"] = self.LaunchBreak,
    ["summon"] = self.SyncSummon,
  }

  for sCommand, fHandler in next, self.tCMD2function do
    self.tCMD2function[self.L[sCommand]] = fHandler
  end

  self.tAction2function = {
    [RaidCore.E.COMM_VERSION_CHECK_REQUEST] = self.VersionCheckRequest,
    [RaidCore.E.COMM_VERSION_CHECK_REPLY] = self.VersionCheckReply,
    [RaidCore.E.COMM_NEWEST_VERSION] = self.NewestVersionRequest,
    [RaidCore.E.COMM_LAUNCH_PULL] = self.LaunchPullRequest,
    [RaidCore.E.COMM_LAUNCH_BREAK] = self.LaunchBreakRequest,
    [RaidCore.E.COMM_SYNC_SUMMON] = self.SyncSummonRequest,
    [RaidCore.E.COMM_ENCOUNTER_IND] = self.EncounterInd,
  }

  -- Final parsing about encounters.
  for name, module in self:IterateModules() do
    local s, e = pcall(module.PrepareEncounter, module)
    if self:HandlePcallResult(s, e) then
      for i = 1, #module.continentIdList do
        for ii = 1, #module.parentMapIdList do
          for iii = 1, #module.mapIdList do
            InitModuleZones(
              module,
              module.continentIdList[i],
              module.parentMapIdList[ii],
              module.mapIdList[iii]
            )
          end
        end
      end
    end

    -- Fill Default setting with encounters definitions.
    tDefaultSettings.profile.Encounters[name] = module.tDefaultSettings or {}
  end
  -- Initialize GeminiDB with the default table.
  self.db:RegisterDefaults(tDefaultSettings)

  -- Load every software block.
  self:CombatInterface_Init()
  -- Do additional initialization.
  self.mark = {}
  self.worldmarker = {}
  _tWipeTimer = ApolloTimer.Create(0.5, true, "RUNNING_WipeCheck", self)
  _tWipeTimer:Stop()
  -- Initialize the Zone Detection.
  self:SEARCH_OnCheckMapZone()
end

function RaidCore:HandlePcallResult(success, error)
  if not success then
    if self.db.profile.bLUAErrorMessage then
      self:Print(error)
    end
    Log:Add(RaidCore.E.ERROR, error)
  end
  return success
end

----------------------------------------------------------------------------------------------------
-- RaidCore OnDocLoaded
----------------------------------------------------------------------------------------------------
function RaidCore:OnDocLoaded()
  -- Send version information to OneVersion Addon.
  local fNumber = RAIDCORE_CURRENT_VERSION:gmatch("%d+")
  local sSuffix = RAIDCORE_CURRENT_VERSION:gmatch("%a+")()
  local nMajor, nMinor = fNumber(), fNumber()
  local nSuffix = sSuffix == "alpha" and -2 or sSuffix == "beta" and -1 or 0
  Event_FireGenericEvent("OneVersion_ReportAddonInfo", "RaidCore", nMajor, nMinor, 0, nSuffix)

  -- Load every software block.
  self:BarManagersInit(self.db.profile.BarsManagers)
  self:DrawManagersInit(self.db.profile.DrawManagers)
  self:GUI_init(RAIDCORE_CURRENT_VERSION)
  self:CI_JoinChannelTry()

  -- Register handlers for events, slash commands and timer, etc.
  Apollo.RegisterSlashCommand("raidc", "OnRaidCoreOn", self)
end

----------------------------------------------------------------------------------------------------
-- RaidCore Channel Communication functions.
----------------------------------------------------------------------------------------------------
function RaidCore:SendMessage(tMessage, tDPlayerId)
  assert(type(tMessage) == "table")
  tMessage.sender = GetPlayerUnit():GetName()
  self:CombatInterface_SendMessage(JSON.encode(tMessage), tDPlayerId)
end

function RaidCore:ProcessMessage(tMessage, nSenderId)
  if type(tMessage) ~= "table" or type(tMessage.action) ~= "string" then
    -- Silent error.
    return
  end

  local func = self.tAction2function[tMessage.action]
  if func then
    func(self, tMessage, nSenderId)
  end
end

function RaidCore:VersionCheckRequest(tMessage, nSenderId)
  local msg = {
    action = RaidCore.E.COMM_VERSION_CHECK_REPLY,
    version = ADDON_DATE_VERSION,
    tag = RAIDCORE_CURRENT_VERSION,
  }
  self:SendMessage(msg, nSenderId)
end

function RaidCore:VersionCheckReply(tMessage, nSenderId)
  if tMessage.sender and tMessage.version and VCtimer then
    VCReply[tMessage.sender] = tMessage.version
  end
end

function RaidCore:NewestVersionRequest(tMessage, nSenderId)
  if tMessage.version and ADDON_DATE_VERSION < tMessage.version then
    self:Print("Your RaidCore version is outdated. Please get " .. tMessage.version)
  end
end

function RaidCore:LaunchPullRequest(tMessage, nSenderId)
  if tMessage.cooldown then
    local tOptions = { bEmphasize = true }
    self:AddTimerBar("PULL", "PULL", tMessage.cooldown, nil, tOptions)
    self:AddMsg("PULL", ("PULL in %s"):format(tMessage.cooldown), 2, nil, "Green")
  end
end

function RaidCore:LaunchBreakRequest(tMessage, nSenderId)
  if tMessage.cooldown and tMessage.cooldown > 0 then
    local tOptions = { bEmphasize = true }
    self:AddTimerBar("BREAK", "BREAK", tMessage.cooldown, nil, tOptions)
    self:AddMsg("BREAK", ("BREAK for %ss"):format(tMessage.cooldown), 5, "Long", "Green")
  else
    self:RemoveTimerBar("BREAK")
    self:RemoveMsg("BREAK")
  end
end

function RaidCore:SyncSummonRequest(tMessage, nSenderId)
  if not self.db.profile.bAcceptSummons or not self:isRaidManagement(tMessage.sender) then
    return false
  end
  local CSImsg = CSIsLib.GetActiveCSI()
  if not CSImsg or not CSImsg.strContext then return end

  if CSImsg.strContext == self.L["message.summon.csi"] then
    self:Print(self.L["message.summon.request"]:format(tMessage.sender))
    if CSIsLib.IsCSIRunning() then
      CSIsLib.CSIProcessInteraction(true)
    end
  end
end

function RaidCore:EncounterInd(tMessage, nSenderId)
  if _tCurrentEncounter and _tCurrentEncounter.ReceiveIndMessage then
    _tCurrentEncounter:ReceiveIndMessage(tMessage.sender, tMessage.reason, tMessage.data)
  end
end

---------------------------------------------------------------------------------------------------
---- Some Functions
-----------------------------------------------------------------------------------------------------
function RaidCore:isPublicEventObjectiveActive(objectiveString)
  local activeEvents = PublicEvent:GetActiveEvents()
  if activeEvents == nil then
    return false
  end

  for eventId, event in next, activeEvents do
    local objectives = event:GetObjectives()
    if objectives ~= nil then
      for id, objective in next, objectives do
        if objective:GetShortDescription() == objectiveString then
          return objective:GetStatus() == 1
        end
      end
    end
  end
  return false
end

function RaidCore:hasActiveEvent(tblEvents)
  for key, value in next, tblEvents do
    if self:isPublicEventObjectiveActive(key) then
      return true
    end
  end
  return false
end

function RaidCore:PlaySound(sFilename)
  assert(type(sFilename) == "string")
  if self.db.profile.bSoundEnabled then
    Sound.PlayFile("Sounds\\".. sFilename .. ".wav")
  end
end

function RaidCore:MarkUnit(unit, location, mark, color)
  if unit and not unit:IsDead() then
    local nId = unit:GetId()
    if not self.mark[nId] then
      self.mark[nId] = {}
      if not mark then
        markCount = markCount + 1
        self.mark[nId].number = tostring(markCount)
      else
        self.mark[nId].number = tostring(mark)
      end

      local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
      markFrame:SetUnit(unit, location)
      markFrame:FindChild("Name"):SetText(self.mark[nId].number)
      if color then
        markFrame:FindChild("Name"):SetTextColor(color)
      end

      self:MarkerVisibilityHandler(markFrame)

      self.mark[nId].frame = markFrame
    elseif mark or color then
      if mark then
        self.mark[nId].number = tostring(mark)
        self.mark[nId].frame:FindChild("Name"):SetText(self.mark[nId].number)
      end
      if color then
        self.mark[nId].frame:FindChild("Name"):SetTextColor(color)
      end
    end
    self:SetMark2UnitBar(nId, self.mark[nId].number)
  end
end

function RaidCore:MarkerVisibilityHandler(markFrame)
  -- If marker was never on screen it might already have been destroyed again
  -- so we'll check if it still exists
  if not markFrame or not markFrame:IsValid() then return end
  if markFrame:IsOnScreen() then
    markFrame:Show(true)
  else
    -- run check again later
    self:ScheduleTimer("MarkerVisibilityHandler", 1, markFrame)
  end
end

-- Removes all the world markers
function RaidCore:ResetWorldMarkers()
  for nId, _ in next, self.worldmarker do
    self:DropWorldMarker(nId)
  end
end

function RaidCore:CreateWorldMarker(key, sText, tPosition)
  local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
  markFrame:SetWorldLocation(tPosition)
  markFrame:FindChild("Name"):SetText(sText)
  self.worldmarker[key] = markFrame
  self:MarkerVisibilityHandler(markFrame)
end

function RaidCore:UpdateWorldMarker(key, sText, tPosition)
  if sText then
    local wndText = self.worldmarker[key]:FindChild("Name")
    if wndText:GetText() ~= sText then
      wndText:SetText(sText)
    end
  end

  if tPosition then
    self.worldmarker[key]:SetWorldLocation(tPosition)
  end
end

function RaidCore:DropWorldMarker(key)
  if self.worldmarker[key] then
    self.worldmarker[key]:Destroy()
    self.worldmarker[key] = nil
  end
end

function RaidCore:SetWorldMarker(key, sText, tPosition)
  assert(key)
  local sLocalizedTest = self.L[sText]
  local tWorldMarker = self.worldmarker[key]
  if not tWorldMarker and sText and tPosition then
    self:CreateWorldMarker(key, sLocalizedTest, tPosition)
  elseif tWorldMarker and (sText or tPosition) then
    self:UpdateWorldMarker(key, sLocalizedTest, tPosition)
  elseif tWorldMarker and not sLocalizedTest and not tPosition then
    self:DropWorldMarker(key)
  end
end

function RaidCore:OnMarkUpdate()
  for k, v in next, self.mark do
    if v.unit:GetPosition() then
      v.frame:SetWorldLocation(v.unit:GetPosition())
    end
  end
end

function RaidCore:DropMark(key)
  if self.mark[key] then
    local markFrame = self.mark[key].frame
    markFrame:SetUnit(nil)
    markFrame:Destroy()
    self.mark[key] = nil
  end
end

function RaidCore:ResetMarks()
  for nId, _ in next, self.mark do
    self:DropMark(nId)
  end
  markCount = 0
end

function RaidCore:ResetAll()
  _tWipeTimer:Stop()
  self:BarsRemoveAll()
  self:ResetMarks()
  self:ResetWorldMarkers()
  self:ResetLines()
end

function RaidCore:isRaidManagement(strName)
  if not GroupLib.InGroup() then return false end
  for nIdx=0, GroupLib.GetMemberCount() do
    local tGroupMember = GroupLib.GetGroupMember(nIdx)
    if tGroupMember and tGroupMember.strCharacterName == strName then
      if tGroupMember.bIsLeader or tGroupMember.bRaidAssistant then
        return true
      else
        return false
      end
    end
  end
  return false -- just in case
end

function RaidCore:AutoCleanUnitDestroyed(nId, tUnit, sName)
  self:RemoveUnit(nId)
  self:DropMark(nId)
end

----------------------------------------------------------------------------------------------------
-- Commands Line:
----------------------------------------------------------------------------------------------------
function RaidCore:OnRaidCoreOn(cmd, args)
  local tArgc = {}
  for sWord in string.gmatch(args, "[^%s]+") do
    table.insert(tArgc, sWord)
  end
  -- Default command.
  local command = "config"
  -- Extract the first argument.
  if #tArgc >= 1 then
    command = string.lower(tArgc[1])
    table.remove(tArgc, 1)
  end

  local func = self.tCMD2function[command]
  if func then
    func(self, tArgc)
  else
    self:Print(("Unknown command: %s"):format(command))
    local tAllCommands = {}
    for k, v in next, self.tCMD2function do
      table.insert(tAllCommands, k)
    end
    local sAllCommands = table.concat(tAllCommands, ", ")
    self:Print(("Available commands are: %s"):format(sAllCommands))
  end
end

function RaidCore:VersionCheck()
  if VCtimer then
    self:Print(self.L["VersionCheck already running ..."])
  elseif GroupLib.GetMemberCount() == 0 then
    self:Print(self.L["Command available only in group."])
  else
    self:Print(self.L["Checking version on group member."])
    VCReply[GetPlayerUnit():GetName()] = ADDON_DATE_VERSION
    local msg = {
      action = RaidCore.E.COMM_VERSION_CHECK_REQUEST,
    }
    VCtimer = ApolloTimer.Create(5, false, "VersionCheckResults", self)
    self:SendMessage(msg)
  end
end

function RaidCore:VersionCheckResults()
  local nMaxVersion = ADDON_DATE_VERSION
  for _, v in next, VCReply do
    if v > nMaxVersion then
      nMaxVersion = v
    end
  end

  local tNotInstalled = {}
  local tOutdated = {}
  local nMemberWithLasted = 0
  for i = 1, GroupLib.GetMemberCount() do
    local tMember = GroupLib.GetGroupMember(i)
    if tMember then
      local sPlayerName = tMember.strCharacterName
      local sPlayerVersion = VCReply[sPlayerName]
      if not sPlayerVersion then
        table.insert(tNotInstalled, sPlayerName)
      elseif sPlayerVersion < nMaxVersion then
        if tOutdated[sPlayerVersion] == nil then
          tOutdated[sPlayerVersion] = {}
        end
        table.insert(tOutdated[sPlayerVersion], sPlayerName)
      else
        nMemberWithLasted = nMemberWithLasted + 1
      end
    end
  end

  if next(tNotInstalled) then
    self:Print(self.L["Not installed: %s"]:format(table.concat(tNotInstalled, ", ")))
  end
  if next(tOutdated) then
    self:Print("Outdated RaidCore Version:")
    for sPlayerVersion, tList in next, tOutdated do
      self:Print((" - '%s': %s"):format(sPlayerVersion, table.concat(tList, ", ")))
    end
  end
  self:Print(self.L["%d members are up to date."]:format(nMemberWithLasted))
  -- Send Msg to oudated players.
  local msg = {action = RaidCore.E.COMM_NEWEST_VERSION, version = nMaxVersion}
  self:SendMessage(msg)
  self:ProcessMessage(msg)
  VCtimer = nil
end

function RaidCore:LaunchPull(tArgc)
  local nTime = #tArgc >= 1 and tonumber(tArgc[1])
  nTime = nTime and nTime > 2 and nTime or 10
  local msg = {
    action = RaidCore.E.COMM_LAUNCH_PULL,
    cooldown = nTime,
  }
  self:SendMessage(msg)
  self:ProcessMessage(msg)
end

function RaidCore:LaunchBreak(tArgc)
  local sPlayerName = GetPlayerUnit():GetName()
  if not self:isRaidManagement(sPlayerName) then
    self:Print("You must be a raid leader or assistant to use this command!")
  else
    local nTime = #tArgc >= 1 and tonumber(tArgc[1])
    nTime = nTime and nTime > 2 and nTime or 600
    local msg = {
      action = RaidCore.E.COMM_LAUNCH_BREAK,
      cooldown = nTime
    }
    self:SendMessage(msg)
    self:ProcessMessage(msg)
    -- Cancel previous timer if started.
    if self.LaunchBreakTimerId then
      self:CancelTimer(self.LaunchBreakTimerId)
    end
    -- Start a timer for Ready Check call..
    if nTime > 0 and self.db.profile.bReadyCheckOnBreakTimeout then
      self.LaunchBreakTimerId = self:ScheduleTimer(function()
          self.LaunchBreakTimerId = nil
          GroupLib.ReadyCheck(self.db.profile.sReadyCheckMessage or "")
        end,
        nTime
      )
    end
  end
end

function RaidCore:SyncSummon()
  local myName = GetPlayerUnit():GetName()
  if not self:isRaidManagement(myName) then
    self:Print("You must be a raid leader or assistant to use this command!")
    return false
  end
  local msg = {
    action = RaidCore.E.COMM_SYNC_SUMMON,
  }
  self:SendMessage(msg)
end

----------------------------------------------------------------------------------------------------
-- Relation between: CombatInterface <-> RaidCore <-> Encounter
----------------------------------------------------------------------------------------------------
function RaidCore:GlobalEventHandler(sMethod, ...)
  -- Call the encounter handler if we were in RUNNING.
  if _eCurrentFSM == MAIN_FSM__RUNNING then
    local s, e = pcall(OnEncounterHookGeneric, sMethod, ...)
    self:HandlePcallResult(s, e)
  end
  -- Call the FSM handler, if needed.
  local fFSMHandler = _tMainFSMHandlers[_eCurrentFSM][sMethod]
  if fFSMHandler then
    fFSMHandler(self, ...)
  end
end

function RaidCore:SEARCH_OnUnitCreated(nId, tUnit, sName)
  AddDelayedUnit(nId, tUnit, sName)
end

function RaidCore:SEARCH_OnCheckMapZone()
  if not _bIsEncounterInProgress then
    local tMap = GetCurrentZoneMap()
    if tMap then
      Log:Add(RaidCore.E.CURRENT_ZONE_MAP, tMap.continentId, tMap.parentZoneId, tMap.id)
      local tTrigInZone = _tTrigPerZone[tMap.continentId]
      tTrigInZone = tTrigInZone and tTrigInZone[tMap.parentZoneId]
      tTrigInZone = tTrigInZone and tTrigInZone[tMap.id]
      if tTrigInZone then
        self:CombatInterface_Activate(RaidCore.E.INTERFACE_DETECTALL)
      else
        self:CombatInterface_Activate(RaidCore.E.INTERFACE_DISABLE)
      end
    else
      self:ScheduleTimer("SEARCH_OnCheckMapZone", 5)
    end
  end
end

function RaidCore:SEARCH_OnEnteredCombat(nId, tUnit, sName, bInCombat)
  -- Manage the lower layer.
  if tUnit == GetPlayerUnit() then
    if bInCombat then
      -- Player entering in combat.
      _bIsEncounterInProgress = true
      -- Enable CombatInterface now to be able to log a combat
      -- not registered.
      self:CombatInterface_Activate(RaidCore.E.INTERFACE_FULLENABLE)
      SearchEncounter()
      if _tCurrentEncounter and not _tCurrentEncounter:IsEnabled() then
        _eCurrentFSM = MAIN_FSM__RUNNING
        _tCurrentEncounter:Enable()
        ProcessDelayedUnit()
      end
    else
      -- Player is dead or left the combat.
      _tWipeTimer:Start()
    end
  elseif not tUnit:IsInYourGroup() then
    if not _tCurrentEncounter then
      AddDelayedUnit(nId, tUnit, sName)
      if _bIsEncounterInProgress then
        SearchEncounter()
        if _tCurrentEncounter and not _tCurrentEncounter:IsEnabled() then
          _eCurrentFSM = MAIN_FSM__RUNNING
          _tCurrentEncounter:Enable()
          ProcessDelayedUnit()
        end
      end
    end
  end
end

function RaidCore:SEARCH_OnUnitDestroyed(nId, tUnit, sName)
  RemoveDelayedUnit(nId, sName)
  self:AutoCleanUnitDestroyed(nId, tUnit, sName)
end

function RaidCore:SEARCH_OnReceivedMessage(sMessage, nSenderId)
  local tMessage = JSON.decode(sMessage)
  self:ProcessMessage(tMessage, nSenderId)
end

function RaidCore:RUNNING_OnReceivedMessage(sMessage, nSenderId)
  local tMessage = JSON.decode(sMessage)
  self:ProcessMessage(tMessage, nSenderId)
end

function RaidCore:RUNNING_OnEnteredCombat(nId, tUnit, sName, bInCombat)
  if tUnit == GetPlayerUnit() then
    if bInCombat == false then
      -- Player is dead or left the combat.
      _tWipeTimer:Start()
    end
  end
end

function RaidCore:RUNNING_OnUnitDestroyed(nId, tUnit, sName)
  self:AutoCleanUnitDestroyed(nId, tUnit, sName)
end

function RaidCore:RUNNING_WipeCheck()
  local tPlayerDeathState = GameLib.GetPlayerDeathState()

  if tPlayerDeathState and not tPlayerDeathState.bAcceptCasterRez then
    return
  end
  for i = 1, GroupLib.GetMemberCount() do
    local tUnit = GroupLib.GetUnitForGroupMember(i)
    if tUnit and tUnit:IsInCombat() then
      return
    end
  end
  self:CombatInterface_Activate(RaidCore.E.INTERFACE_DETECTALL)
  _bIsEncounterInProgress = false
  if _tCurrentEncounter then
    _tCurrentEncounter:Disable()
    _tCurrentEncounter = nil
    CleanDelayedUnits()
  end
  self:ResetAll()
  -- Set the FSM in SEARCH mode.
  _eCurrentFSM = MAIN_FSM__SEARCH
  self:SEARCH_OnCheckMapZone()
end

----------------------------------------------------------------------------------------------------
-- TEST features functions
----------------------------------------------------------------------------------------------------
local targetId = 0
function RaidCore:OnStartTestScenario()
  local tPlayerUnit = GetPlayerUnit()
  local nPlayerId = tPlayerUnit:GetId()
  local nRandomGreen = math.random()
  local function GetProgress(nProgress)
    return nProgress + 1.3
  end
  local function GetProgress2(nProgress)
    return nProgress + 0.5
  end
  self:AddTimerBar("TEST1", "End of test scenario", 60, nil, { sColor = "red" })
  self:AddTimerBar("TEST2", "Timer with count down", 8, nil, { sColor = "blue", bEmphasize = true })
  self:AddTimerBar("TEST3", "Timer for a static circle", 15, nil, { sColor = "xkcdBarneyPurple" })
  self:AddTimerBar("TEST4", "Timer for the crosshair on you", 30, nil, { sColor = "xkcdBrown" })
  self:AddProgressBar("PROGRESS", "Progress", { fHandler = GetProgress }, nil)
  self:AddProgressBar("PROGRESS2", "Progress2", { fHandler = GetProgress2 }, nil)
  self:AddUnit(GetPlayerUnit())
  if GetPlayerUnit():GetTarget() then
    self:AddUnitSpacer("UNIT_SPACER")
    self:AddUnit(GetPlayerUnit():GetTarget())
    targetId = GetPlayerUnit():GetTarget():GetId()
  end
  self:AddMsg("TEST1", self.L["Start test scenario"], 5, nil, "red")
  for i = 1, 36 do
    local nForce = 1 - i / 36.0
    local tColor = { a = 1.0, r = 1 - nForce, g = nRandomGreen, b = nForce }
    self:AddSimpleLine(("TEST%d"):format(i), nPlayerId, i / 6, i / 8 + 2, nForce * 360, i / 4 + 1, tColor)
  end
  self.tScenarioTestTimers = {}
  self.tScenarioTestTimers[1] = self:ScheduleTimer(function()
      self:AddPolygon("TEST1", GetPlayerUnit():GetPosition(), 8, 0, 3, "xkcdBrightPurple", 16)
    end,
    15
  )
  self.tScenarioTestTimers[2] = self:ScheduleTimer(function()
      self:AddPicture("TEST1", GetPlayerUnit():GetId(), "Crosshair", 55)
    end,
    30
  )
  self:AddTimerBar("TEST6", "Extended timer", 25, nil, { bEmphasize = true })
  self.tScenarioTestTimers[3] = self:ScheduleTimer(function()
      self:ExtendTimerBar("TEST6", 20)
    end,
    10
  )
  self:SetWorldMarker("TEST80", "1", GetPlayerUnit():GetPosition())
end

function RaidCore:OnStopTestScenario()
  for _, timer in next, self.tScenarioTestTimers do
    self:CancelTimer(timer, true)
  end
  self:RemovePolygon("TEST1")
  self:RemovePicture("TEST1")
  for i = 1, 36 do
    self:RemoveSimpleLine(("TEST%d"):format(i))
  end
  self:RemoveMsg("TEST1")
  self:RemoveUnit(GetPlayerUnit():GetId())
  if targetId ~= 0 then
    self:RemoveUnit("UNIT_SPACER")
    self:RemoveUnit(targetId)
    targetId = nil
  end
  self:RemoveTimerBar("TEST1")
  self:RemoveTimerBar("TEST2")
  self:RemoveTimerBar("TEST3")
  self:RemoveTimerBar("TEST4")
  self:RemoveTimerBar("TEST6")
  self:RemoveProgressBar("PROGRESS")
  self:RemoveProgressBar("PROGRESS2")
  self:DropWorldMarker("TEST80")
end
