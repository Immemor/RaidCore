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
--------------------------------------------------------------------B--------------------------------
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local GetCurrentZoneMap = GameLib.GetCurrentZoneMap
local next, pcall = next, pcall

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Should be 5.23 when replacement tokens will works (see #88 issue).
local RAIDCORE_CURRENT_VERSION = "6.1.2"
-- Should be deleted.
local ADDON_DATE_VERSION = 16090617
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with French language. This problem is not present in English.
local NO_BREAK_SPACE = string.char(194, 160)

local MYCOLORS = {
  ["Blue"] = "FF0066FF",
  ["Green"] = "FF00CC00",
}

-- State Machine.
local MAIN_FSM__SEARCH = 1
local MAIN_FSM__RUNNING = 2

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _wndrclog = nil
local _tWipeTimer
local _tTrigPerZone = {}
local _tEncountersPerZone = {}
local _tDelayedUnits = {}
local _bIsEncounterInProgress = false
local _tCurrentEncounter = nil
local _eCurrentFSM
local _tEncounterHookHandlers
local _tMainFSMHandlers
local trackMaster = Apollo.GetAddon("TrackMaster")
local markCount = 0
local VCReply, VCtimer = {}, nil
local empCD, empTimer = 5, nil

----------------------------------------------------------------------------------------------------
-- Privates functions
----------------------------------------------------------------------------------------------------
local function OnEncounterUnitEvents(sMethod, ...)
  if _tCurrentEncounter == nil or _tCurrentEncounter.tUnitEvents == nil or
  _tCurrentEncounter.tUnitEvents[sMethod] == nil then
    return
  end

  local tEncounter = nil
  if sMethod == "OnUnitCreated" then
    local nId, tUnit, sName = ...
    tEncounter = _tCurrentEncounter.tUnitEvents[sMethod][sName]
  elseif sMethod == "OnUnitDestroyed" then
    local nId, tUnit, sName = ...
    tEncounter = _tCurrentEncounter.tUnitEvents[sMethod][sName]
  elseif sMethod == "OnCastStart" then
    local nId, sCastName, nCastEndTime, sName = ...
    tEncounter = _tCurrentEncounter.tUnitEvents[sMethod][sName]
  elseif sMethod == "OnCastEnd" then
    local nId, sCastName, isInterrupted, nCastEndTime, sName = ...
    tEncounter = _tCurrentEncounter.tUnitEvents[sMethod][sName]
  elseif sMethod == "OnHealthChanged" then
    local nId, nPourcent, sName = ...
    tEncounter = _tCurrentEncounter.tUnitEvents[sMethod][sName]
  elseif sMethod == "OnEnteredCombat" then
    local nId, tUnit, sName, bInCombat = ...
    tEncounter = _tCurrentEncounter.tUnitEvents[sMethod][sName]
  end

  if tEncounter then
    for _, fEncounter in pairs(tEncounter) do
      fEncounter(_tCurrentEncounter, ...)
    end
  end
end

local function OnEncounterDatachronEvents(sMethod, ...)
  if sMethod ~= "OnDatachron" or _tCurrentEncounter == nil or
  _tCurrentEncounter.tDatachronEvents == nil then
    return
  end

  for sSearchMessage, tEvents in pairs(_tCurrentEncounter.tDatachronEvents) do
    for _, tEvent in pairs(tEvents) do
      local sMessage = ...
      local sMatch = tEvent.sMatch
      local fHandler = tEvent.fHandler
      local result = nil

      if sMatch == "EQUAL" then
        result = sSearchMessage == sMessage
      elseif sMatch == "FIND" then
        result = sMessage:find(sSearchMessage)
      elseif sMatch == "MATCH" then
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

local function AddDelayedUnit(nId, sName, bInCombat)
  local tMap = GetCurrentZoneMap()
  if tMap then
    local id1 = tMap.continentId
    local id2 = tMap.parentZoneId
    local id3 = tMap.id
    local tTrig = _tTrigPerZone[id1] and _tTrigPerZone[id1][id2] and _tTrigPerZone[id1][id2][id3]
    if tTrig and tTrig[sName] then
      if not _tDelayedUnits[sName] then
        _tDelayedUnits[sName] = {}
      end
      _tDelayedUnits[sName][nId] = bInCombat
    end
  end
end

local function SearchEncounter()
  local tMap = GetCurrentZoneMap()
  if tMap then
    local id1 = tMap.continentId
    local id2 = tMap.parentZoneId
    local id3 = tMap.id
    local tEncounters = _tEncountersPerZone[id1] and _tEncountersPerZone[id1][id2] and _tEncountersPerZone[id1][id2][id3]
    if tEncounters then
      for _, tEncounter in next, tEncounters do
        if tEncounter:OnTrig(_tDelayedUnits) then
          _tCurrentEncounter = tEncounter
          break
        end
      end
    end
  end
end

local function ProcessDelayedUnit()
  for nDelayedName, tDelayedList in next, _tDelayedUnits do
    for nDelayedId, bInCombat in next, tDelayedList do
      local tUnit = GetUnitById(nDelayedId)
      if tUnit then
        local s, sErrMsg = pcall(OnEncounterHookGeneric, "OnUnitCreated", nDelayedId, tUnit, nDelayedName)
        if not s then
          if RaidCore.db.profile.bLUAErrorMessage then
            RaidCore:Print(sErrMsg)
          end
          Log:Add("ERROR", sErrMsg)
        end
        if bInCombat then
          s, sErrMsg = pcall(OnEncounterHookGeneric, "OnEnteredCombat", nDelayedId, tUnit, nDelayedName, bInCombat)
          if not s then
            if RaidCore.db.profile.bLUAErrorMessage then
              RaidCore:Print(sErrMsg)
            end
            Log:Add("ERROR", sErrMsg)
          end
        end
      end
    end
  end
  _tDelayedUnits = {}
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
      ["OnChangeWorld"] = self.SEARCH_OnCheckMapZone,
      ["OnSubZoneChanged"] = self.SEARCH_OnCheckMapZone,
      ["OnUnitCreated"] = self.SEARCH_OnUnitCreated,
      ["OnEnteredCombat"] = self.SEARCH_OnEnteredCombat,
      ["OnUnitDestroyed"] = self.SEARCH_OnUnitDestroyed,
      ["OnReceivedMessage"] = self.SEARCH_OnReceivedMessage,
    },
    [MAIN_FSM__RUNNING] = {
      ["OnEnteredCombat"] = self.RUNNING_OnEnteredCombat,
      ["OnReceivedMessage"] = self.RUNNING_OnReceivedMessage,
      ["OnUnitDestroyed"] = self.RUNNING_OnUnitDestroyed,
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
    }
  }
  -- Final parsing about encounters.
  for name, module in self:IterateModules() do
    local r, e = pcall(module.PrepareEncounter, module)
    if not r then
      self:Print(e)
    else
      for _, id1 in next, module.continentIdList do
        if _tTrigPerZone[id1] == nil then
          _tTrigPerZone[id1] = {}
          _tEncountersPerZone[id1] = {}
        end
        for _, id2 in next, module.parentMapIdList do
          if _tTrigPerZone[id1][id2] == nil then
            _tTrigPerZone[id1][id2] = {}
            _tEncountersPerZone[id1][id2] = {}
          end
          for _, id3 in next, module.mapIdList do
            if _tTrigPerZone[id1][id2][id3] == nil then
              _tTrigPerZone[id1][id2][id3] = {}
              _tEncountersPerZone[id1][id2][id3] = {}
            end
            table.insert(_tEncountersPerZone[id1][id2][id3], module)
            if module.EnableMob then
              for _, Mob in next, module.EnableMob do
                _tTrigPerZone[id1][id2][id3][Mob] = true
              end
            end
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
  self.lines = {}
  -- Initialize the Zone Detection.
  self:SEARCH_OnCheckMapZone()
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

  local tAction2function = {
    ["VersionCheckRequest"] = self.VersionCheckRequest,
    ["VersionCheckReply"] = self.VersionCheckReply,
    ["NewestVersion"] = self.NewestVersionRequest,
    ["LaunchPull"] = self.LaunchPullRequest,
    ["LaunchBreak"] = self.LaunchBreakRequest,
    ["SyncSummon"] = self.SyncSummonRequest,
    ["Encounter_IND"] = self.EncounterInd,
  }
  local func = tAction2function[tMessage.action]
  if func then
    func(self, tMessage, nSenderId)
  end
end

function RaidCore:VersionCheckRequest(tMessage, nSenderId)
  local msg = {
    action = "VersionCheckReply",
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
    self:AddMsg("PULL", ("PULL in %s"):format(tMessage.cooldown), 2, MYCOLORS["Green"])
  end
end

function RaidCore:LaunchBreakRequest(tMessage, nSenderId)
  if tMessage.cooldown and tMessage.cooldown > 0 then
    local tOptions = { bEmphasize = true }
    self:AddTimerBar("BREAK", "BREAK", tMessage.cooldown, nil, tOptions)
    self:AddMsg("BREAK", ("BREAK for %ss"):format(tMessage.cooldown), 5, MYCOLORS["Green"])
    self:PlaySound("Long")
  else
    self:RemoveTimerBar("BREAK")
    self:RemoveMsg("BREAK")
  end
end

function RaidCore:SyncSummonRequest(tMessage, nSenderId)
  if not self.db.profile.bAcceptSummons or not self:isRaidManagement(strSender) then
    return false
  end
  self:Print(tMessage.sender .. " requested that you accept a summon. Attempting to accept now.")
  local CSImsg = CSIsLib.GetActiveCSI()
  if not CSImsg or not CSImsg["strContext"] then return end

  if CSImsg["strContext"] == "Teleport to your group member?" then
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

  for eventId, event in pairs(activeEvents) do
    local objectives = event:GetObjectives()
    if objectives ~= nil then
      for id, objective in pairs(objectives) do
        if objective:GetShortDescription() == objectiveString then
          return objective:GetStatus() == 1
        end
      end
    end
  end
  return false
end

function RaidCore:hasActiveEvent(tblEvents)
  for key, value in pairs(tblEvents) do
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

-- Track buff and cast of this unit.
-- @param unit userdata object related to an unit in game.
function RaidCore:WatchUnit(unit)
  local id = unit:GetId()
  self:CombatInterface_Track(id)
end

function RaidCore:MarkUnit(unit, location, mark)
  if unit and not unit:IsDead() then
    local nId = unit:GetId()
    if not self.mark[nId] then
      self.mark[nId] = {}
      self.mark[nId]["unit"] = unit
      if not mark then
        markCount = markCount + 1
        self.mark[nId].number = tostring(markCount)
      else
        self.mark[nId].number = tostring(mark)
      end

      local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
      markFrame:SetUnit(unit, location)
      markFrame:FindChild("Name"):SetText(self.mark[nId].number)
      self:MarkerVisibilityHandler(markFrame)

      self.mark[nId].frame = markFrame
    elseif mark then
      self.mark[nId].number = tostring(mark)
      self.mark[nId].frame:FindChild("Name"):SetText(self.mark[nId].number)
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
  for k, over in pairs(self.worldmarker) do
    over:Destroy()
    self.worldmarker[k] = nil
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
    return true
  end
end

function RaidCore:SetWorldMarker(key, sText, tPosition)
  assert(key)
  local tWorldMarker = self.worldmarker[key]
  if not tWorldMarker and sText and tPosition then
    self:CreateWorldMarker(key, sText, tPosition)
  elseif tWorldMarker and (sText or tPosition) then
    self:UpdateWorldMarker(key, sText, tPosition)
  elseif tWorldMarker and not sText and not tPosition then
    self:DropWorldMarker(key)
  end
end

function RaidCore:SetTarget(position)
  if trackMaster ~= nil then
    trackMaster:SetTarget(position)
  end
end

function RaidCore:OnMarkUpdate()
  for k, v in pairs(self.mark) do
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
  for k, over in pairs(self.mark) do
    over.frame:SetUnit(nil)
    over.frame:Destroy()
    self.mark[k] = nil
  end
  markCount = 0
end

-- Obsolete way to test. PublicEventObjectif will be reworked later.
function RaidCore:TestPE()
  local tActiveEvents = PublicEvent.GetActiveEvents()
  local i = RaidCore:isPublicEventObjectiveActive("Talk to Captain Tero")
  self:Print("result ".. tostring(i))
  i = RaidCore:isPublicEventObjectiveActive("Talk to Captain Teroxx")
  self:Print("result ".. tostring(i))
  for idx, peEvent in pairs(tActiveEvents) do
    local test = peEvent:GetName()
    local truc
    self:Print(test)
    for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
      test = peObjective:GetShortDescription()
      if test == "North Power Core Energy" then
        truc = peObjective:GetCount()
        self:Print(test)
        self:Print(truc)
      end
    end
  end
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
    if tGroupMember and tGroupMember["strCharacterName"] == strName then
      if tGroupMember["bIsLeader"] or tGroupMember["bRaidAssistant"] then
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
  if self.mark[nId] then
    local markFrame = self.mark[nId].frame
    markFrame:SetUnit(nil)
    markFrame:Destroy()
    self.mark[nId] = nil
  end
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

  local tCMD2function = {
    ["config"] = self.DisplayMainWindow,
    ["reset"] = self.ResetAll,
    ["versioncheck"] = self.VersionCheck,
    ["pull"] = self.LaunchPull,
    ["break"] = self.LaunchBreak,
    ["summon"] = self.SyncSummon,
  }

  local func = tCMD2function[command]
  if func then
    func(self, tArgc)
  else
    self:Print(("Unknown command: %s"):format(command))
    local tAllCommands = {}
    for k, v in pairs(tCMD2function) do
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
      action = "VersionCheckRequest",
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
    for sPlayerVersion, tList in pairs(tOutdated) do
      self:Print((" - '%s': %s"):format(sPlayerVersion, table.concat(tList, ", ")))
    end
  end
  self:Print(self.L["%d members are up to date."]:format(nMemberWithLasted))
  -- Send Msg to oudated players.
  local msg = {action = "NewestVersion", version = nMaxVersion}
  self:SendMessage(msg)
  self:ProcessMessage(msg)
  VCtimer = nil
end

function RaidCore:LaunchPull(tArgc)
  local nTime = #tArgc >= 1 and tonumber(tArgc[1])
  nTime = nTime and nTime > 2 and nTime or 10
  local msg = {
    action = "LaunchPull",
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
      action = "LaunchBreak",
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
          end, nTime)
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
      action = "SyncSummon",
    }
    self:SendMessage(msg)
  end

  ----------------------------------------------------------------------------------------------------
  -- Relation between: CombatInterface <-> RaidCore <-> Encounter
  ----------------------------------------------------------------------------------------------------
  function RaidCore:GlobalEventHandler(sMethod, ...)
    -- Call the encounter handler if we were in RUNNING.
    if _eCurrentFSM == MAIN_FSM__RUNNING then
      local s, sErrMsg = pcall(OnEncounterHookGeneric, sMethod, ...)
      if not s then
        if self.db.profile.bLUAErrorMessage then
          self:Print(sErrMsg)
        end
        Log:Add("ERROR", sErrMsg)
      end
    end
    -- Call the FSM handler, if needed.
    local fFSMHandler = _tMainFSMHandlers[_eCurrentFSM][sMethod]
    if fFSMHandler then
      fFSMHandler(self, ...)
    end
  end

  function RaidCore:SEARCH_OnCheckMapZone()
    if not _bIsEncounterInProgress then
      local tMap = GetCurrentZoneMap()
      if tMap then
        Log:Add("CurrentZoneMap", tMap.continentId, tMap.parentZoneId, tMap.id)
        local tTrigInZone = _tTrigPerZone[tMap.continentId]
        local bSearching = false
        if tTrigInZone then
          tTrigInZone = tTrigInZone[tMap.parentZoneId]
          if tTrigInZone then
            tTrigInZone = tTrigInZone[tMap.id]
            if tTrigInZone then
              bSearching = true
            end
          end
        end
        if bSearching then
          self:CombatInterface_Activate("DetectAll")
        else
          self:CombatInterface_Activate("Disable")
        end
      else
        self:ScheduleTimer("SEARCH_OnCheckMapZone", 5)
      end
    end
  end

  function RaidCore:SEARCH_OnUnitCreated(nId, tUnit, sName)
    local bInCombat = tUnit:IsInCombat()
    AddDelayedUnit(nId, sName, bInCombat)
  end

  function RaidCore:SEARCH_OnEnteredCombat(nId, tUnit, sName, bInCombat)
    -- Manage the lower layer.
    if tUnit == GetPlayerUnit() then
      if bInCombat then
        -- Player entering in combat.
        _bIsEncounterInProgress = true
        -- Enable CombatInterface now to be able to log a combat
        -- not registered.
        self:CombatInterface_Activate("FullEnable")
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
        AddDelayedUnit(nId, sName, bInCombat)
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
    RemoveDelayedUnit(nId, tUnit)
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
    self:CombatInterface_Activate("DetectAll")
    _bIsEncounterInProgress = false
    if _tCurrentEncounter then
      _tCurrentEncounter:Disable()
      _tCurrentEncounter = nil
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
    self:AddMsg("TEST1", self.L["Start test scenario"], 5, "red")
    for i = 1, 36 do
      local nForce = 1 - i / 36.0
      local tColor = { a = 1.0, r = 1 - nForce, g = nRandomGreen, b = nForce }
      self:AddSimpleLine(("TEST%d"):format(i), nPlayerId, i / 6, i / 8 + 2, nForce * 360, i / 4 + 1, tColor)
    end
    self.tScenarioTestTimers = {}
    self.tScenarioTestTimers[1] = self:ScheduleTimer(function()
        self:AddPolygon("TEST1", GetPlayerUnit():GetPosition(), 8, 0, 3, "xkcdBrightPurple", 16)
        end, 15)
      self.tScenarioTestTimers[2] = self:ScheduleTimer(function()
          self:AddPicture("TEST1", GetPlayerUnit():GetId(), "Crosshair", 55)
          end, 30)
      end

      function RaidCore:OnStopTestScenario()
        for _, timer in next, self.tScenarioTestTimers do
          self:CancelTimer(timer, true)
        end
        self:RemovePolygon("TEST1")
        self:RemovePicture("TEST1")
        for i = 1, 36 do
          local nForce = i / 36.0
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
        self:RemoveProgressBar("PROGRESS")
        self:RemoveProgressBar("PROGRESS2")

      end
