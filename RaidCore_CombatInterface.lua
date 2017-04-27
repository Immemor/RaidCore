----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Combat Interface object have the responsability to catch carbine events and interpret them.
-- Thus result will be send to upper layer, trough ManagerCall function. Every events are logged.
--
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local ApolloTimer = require "ApolloTimer"
local GameLib = require "GameLib"
local ChatSystemLib = require "ChatSystemLib"
local ActionSetLib = require "ActionSetLib"
local ICCommLib = require "ICCommLib"
local ICComm = require "ICComm" -- luacheck: ignore
local bit32 = require "bit32"
local table = require "table"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local Log = Apollo.GetPackage("Log-1.0").tPackage

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local RegisterEventHandler = Apollo.RegisterEventHandler
local RemoveEventHandler = Apollo.RemoveEventHandler
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById
local GetSpell = GameLib.GetSpell
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local next, pcall = next, pcall
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local SCAN_PERIOD = 0.1 -- in seconds.
local TRACKED_BUFFS_PERIOD = 0.25 -- in seconds.
-- Array with chat permission.
local CHANNEL_HANDLERS = {
  [ChatSystemLib.ChatChannel_Say] = nil,
  [ChatSystemLib.ChatChannel_Party] = nil,
  [ChatSystemLib.ChatChannel_NPCSay] = RaidCore.E.NPC_SAY,
  [ChatSystemLib.ChatChannel_NPCYell] = RaidCore.E.NPC_YELL,
  [ChatSystemLib.ChatChannel_NPCWhisper] = RaidCore.E.NPC_WHISPER,
  [ChatSystemLib.ChatChannel_Datachron] = RaidCore.E.DATACHRON,
}
local SPELLID_BLACKLISTED = {
  [79757] = "Kinetic Rage: Augmented Blade", -- Warrior
  [70161] = "Atomic Spear", -- Warrior T4
  [70162] = "Atomic Spear", --T5
  [70163] = "Atomic Spear", --T6
  [70164] = "Atomic Spear", --T7
  [70165] = "Atomic Spear", --T8
  [79671] = "Empower", --Warrior whirlwind
  [41137] = "To the Pain", -- Warrior cheat death
  [84397] = "Unbreakable", -- Engineer cheat death
  [82748] = "Unbreakable", -- Engineer cheat death cooldown
}
local SPELLID_WHITELIST = {
  [82133] = "Realm of the Living", -- Laveka Player Buff
  [87767] = "Spirit Ire", -- Laveka Debuff
  [87774] = "Barrier of Souls", -- Laveka Debuff
  [87545] = "Catastrophic Solar Event", -- Starmap Debuff
  [84322] = "Solar Surface", -- Starmap Debuff
  [85458] = "Growing Singularity", -- Starmap Debuff
}

local EXTRA_HANDLER_ALLOWED = {
  [RaidCore.E.EVENT_COMBAT_LOG_HEAL] = "CI_OnCombatLogHeal",
}

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _bDetectAllEnable = false
local _bUnitInCombatEnable = false
local _bRunning = false
local _tScanTimer = nil
local _tTrackedDebuffTimer = nil
local _CommChannelTimer = nil
local _nCommChannelRetry = 5
local _tAllUnits = {}
local _tTrackedUnits = {}
local _tTrackedBuffs = {}
local _RaidCoreChannelComm = nil
local _nNumShortcuts
local _CI_State
local _CI_Extra = {}

----------------------------------------------------------------------------------------------------
-- Privates functions: Log
----------------------------------------------------------------------------------------------------
local function ManagerCall(sMethod, ...)
  -- Trace all call to upper layer for debugging purpose.
  Log:Add(sMethod, ...)
  -- Protected call.
  local s, e = pcall(RaidCore.GlobalEventHandler, RaidCore, sMethod, ...)
  RaidCore:HandlePcallResult(s, e)
end

local function ExtraLog2Text(k, nRefTime, tParam)
  local sResult = ""
  if k == RaidCore.E.ERROR then
    sResult = tParam[1]
  elseif k == RaidCore.E.DEBUFF_ADD or k == RaidCore.E.BUFF_ADD then
    local sSpellName = RaidCore:ReplaceNoBreakSpace(GetSpell(tParam[2]):GetName())
    local sFormat = "Id=%u SpellName='%s' SpellId=%u Stack=%d fTimeRemaining=%.2f sName=\"%s\""
    sResult = sFormat:format(tParam[1], sSpellName, tParam[2], tParam[3], tParam[4], tParam[5])
  elseif k == RaidCore.E.DEBUFF_REMOVE or k == RaidCore.E.BUFF_REMOVE then
    local sSpellName = RaidCore:ReplaceNoBreakSpace(GetSpell(tParam[2]):GetName())
    local sFormat = "Id=%u SpellName='%s' SpellId=%u sName=\"%s\""
    sResult = sFormat:format(tParam[1], sSpellName, tParam[2], tParam[3])
  elseif k == RaidCore.E.DEBUFF_UPDATE or k == RaidCore.E.BUFF_UPDATE then
    local sSpellName = RaidCore:ReplaceNoBreakSpace(GetSpell(tParam[2]):GetName())
    local sFormat = "Id=%u SpellName='%s' SpellId=%u Stack=%d fTimeRemaining=%.2f sName=\"%s\""
    sResult = sFormat:format(tParam[1], sSpellName, tParam[2], tParam[3], tParam[4], tParam[5])
  elseif k == RaidCore.E.CAST_START then
    local nCastEndTime = tParam[3] - nRefTime
    local sFormat = "Id=%u CastName='%s' CastEndTime=%.3f sName=\"%s\""
    sResult = sFormat:format(tParam[1], tParam[2], nCastEndTime, tParam[4])
  elseif k == RaidCore.E.CAST_END then
    local nCastEndTime = tParam[4] - nRefTime
    local sFormat = "Id=%u CastName='%s' IsInterrupted=%s CastEndTime=%.3f sName=\"%s\""
    sResult = sFormat:format(tParam[1], tParam[2], tostring(tParam[3]), nCastEndTime, tParam[5])
  elseif k == RaidCore.E.UNIT_CREATED then
    local sFormat = "Id=%u Unit='%s'"
    sResult = sFormat:format(tParam[1], tParam[3])
  elseif k == RaidCore.E.UNIT_DESTROYED then
    local sFormat = "Id=%u Unit='%s'"
    sResult = sFormat:format(tParam[1], tParam[3])
  elseif k == RaidCore.E.ENTERED_COMBAT then
    local sFormat = "Id=%u Unit='%s' InCombat=%s"
    sResult = sFormat:format(tParam[1], tParam[3], tostring(tParam[4]))
  elseif k == RaidCore.E.NPC_SAY or k == RaidCore.E.NPC_YELL or k == RaidCore.E.NPC_WHISPER or k == RaidCore.E.DATACHRON then
    local sFormat = "sMessage='%s' sSender='%s'"
    sResult = sFormat:format(tParam[1], tParam[2])
  elseif k == RaidCore.E.TRACK_UNIT or k == RaidCore.E.UNTRACK_UNIT then
    sResult = ("Id='%s'"):format(tParam[1])
  elseif k == RaidCore.E.SHOW_SHORTCUT_BAR then
    sResult = "sIcon=" .. table.concat(tParam[1], ", ")
  elseif k == RaidCore.E.SEND_MESSAGE then
    local sFormat = "sMsg=\"%s\" to=\"%s\""
    sResult = sFormat:format(tParam[1], tostring(tParam[2]))
  elseif k == RaidCore.E.RECEIVED_MESSAGE then
    local sFormat = "sMsg=\"%s\" SenderId=%s"
    sResult = sFormat:format(tParam[1], tostring(tParam[2]))
  elseif k == RaidCore.E.CHANNEL_COMM_STATUS then
    sResult = tParam[1]
  elseif k == RaidCore.E.SEND_MESSAGE_RESULT then
    sResult = ("sResult=\"%s\" MsgId=%d"):format(tParam[1], tParam[2])
  elseif k == RaidCore.E.JOIN_CHANNEL_TRY then
    sResult = ("ChannelName=\"%s\" ChannelType=\"%s\""):format(tParam[1], tParam[2])
  elseif k == RaidCore.E.JOIN_CHANNEL_STATUS then
    local sFormat = "Result=\"%s\""
    sResult = sFormat:format(tParam[1])
  elseif k == RaidCore.E.COMBAT_LOG_HEAL then
    local sFormat = "CasterId=%s TargetId=%s sCasterName=\"%s\" sTargetName=\"%s\" nHealAmount=%u nOverHeal=%u nSpellId=%u"
    sResult = sFormat:format(tostring(tParam[1]), tostring(tParam[2]), tParam[3], tParam[4], tParam[5], tParam[6], tParam[7])
  elseif k == RaidCore.E.HEALTH_CHANGED then
    local sFormat = "Id=%u nPercent=%.2f sName=\"%s\""
    sResult = sFormat:format(tParam[1], tParam[2], tParam[3])
  elseif k == RaidCore.E.SUB_ZONE_CHANGE then
    local sFormat = "ZoneId=%u ZoneName=\"%s\""
    sResult = sFormat:format(tParam[1], tParam[2])
  elseif k == RaidCore.E.CURRENT_ZONE_MAP then
    local sFormat = "ContinentId=%u ZoneId=%u Id=%u"
    sResult = sFormat:format(tParam[1], tParam[2], tParam[3])
  elseif k == RaidCore.E.SPAWN_LOCATION then
    local sFormat = "Id=%u sName=\"%s\" x=%f y=%f z=%f"
    sResult = sFormat:format(tParam[1], tParam[2], tParam[3], tParam[4], tParam[5])
  end
  return sResult
end
Log:SetExtra2String(ExtraLog2Text)

----------------------------------------------------------------------------------------------------
-- Privates functions: unit processing
----------------------------------------------------------------------------------------------------
local function LogUnitSpawnLocation(nId, sName, tPosition)
  if RaidCore.db.profile.bLogSpawnLocations then
    Log:Add(RaidCore.E.SPAWN_LOCATION, nId, sName, tPosition.x, tPosition.y, tPosition.z)
  end
end

local function GetAllBuffs(tBuffs, r)
  if not tBuffs then
    return r
  end
  local nBuffs = #tBuffs
  for i = 1, nBuffs do
    local obj = tBuffs[i]
    local nSpellId = obj.splEffect:GetId()
    if nSpellId then
      r[obj.idBuff] = {
        nCount = obj.nCount,
        nSpellId = nSpellId,
        fTimeRemaining = obj.fTimeRemaining,
        unitCaster = obj.unitCaster,
      }
    end
  end
  return r
end

local function GetWhitelistedDebuffs(tBuffs, r)
  if not tBuffs then
    return r
  end
  local nBuffs = #tBuffs
  for i = 1, nBuffs do
    local obj = tBuffs[i]
    local nSpellId = obj.splEffect:GetId()
    if nSpellId and SPELLID_WHITELIST[nSpellId] then
      r[obj.idBuff] = {
        nCount = obj.nCount,
        nSpellId = nSpellId,
        fTimeRemaining = obj.fTimeRemaining,
        unitCaster = obj.unitCaster,
      }
    end
  end
  return r
end

local function GetBuffs(tUnit)
  local r = {}
  if not tUnit then
    return r
  end

  local tBuffs = tUnit:GetBuffs()
  r = GetAllBuffs(tBuffs.arBeneficial, r)
  r = GetWhitelistedDebuffs(tBuffs.arHarmful, r)
  return r
end

local function TrackThisUnit(tUnit, nTrackingType)
  local nId = tUnit:GetId()
  if RaidCore.db.profile.bDisableSelectiveTracking then
    nTrackingType = RaidCore.E.TRACK_ALL
  else
    nTrackingType = nTrackingType or RaidCore.E.TRACK_ALL
  end

  if not _tTrackedUnits[nId] and not tUnit:IsInYourGroup() then
    Log:Add(RaidCore.E.TRACK_UNIT, nId)
    local MaxHealth = tUnit:GetMaxHealth()
    local Health = tUnit:GetHealth()
    local tBuffs = GetBuffs(tUnit)
    local nPercent = Health and MaxHealth and math.floor(100 * Health / MaxHealth)
    _tAllUnits[nId] = true
    _tTrackedUnits[nId] = {
      tUnit = tUnit,
      sName = RaidCore:ReplaceNoBreakSpace(tUnit:GetName()),
      nId = nId,
      bIsACharacter = false,
      tBuffs = tBuffs,
      tCast = {
        bCasting = false,
        sCastName = "",
        nCastEndTime = 0,
        bSuccess = false,
      },
      nPreviousHealthPercent = nPercent,
      bTrackBuffs = bit32.band(nTrackingType, RaidCore.E.TRACK_BUFFS) ~= 0,
      bTrackCasts = bit32.band(nTrackingType, RaidCore.E.TRACK_CASTS) ~= 0,
      bTrackHealth = bit32.band(nTrackingType, RaidCore.E.TRACK_HEALTH) ~= 0,
    }
  end
end

local function UnTrackThisUnit(nId)
  if _tTrackedUnits[nId] then
    Log:Add(RaidCore.E.UNTRACK_UNIT, nId)
    _tTrackedUnits[nId] = nil
  end
end

local function PollUnitBuffs(tMyUnit)
  local nId = tMyUnit.nId
  local tNewBuffs = GetBuffs(tMyUnit.tUnit)
  local tBuffs = tMyUnit.tBuffs
  if not tNewBuffs then
    return
  end
  local sName = tMyUnit.sName

  for nIdBuff,current in next, tBuffs do
    if tNewBuffs[nIdBuff] then
      local tNew = tNewBuffs[nIdBuff]
      if tNew.nCount ~= current.nCount then
        tBuffs[nIdBuff].nCount = tNew.nCount
        tBuffs[nIdBuff].fTimeRemaining = tNew.fTimeRemaining
        ManagerCall(RaidCore.E.BUFF_UPDATE, nId, current.nSpellId, tNew.nCount, tNew.fTimeRemaining, sName, current.unitCaster)
      end
      -- Remove this entry for second loop.
      tNewBuffs[nIdBuff] = nil
    else
      tBuffs[nIdBuff] = nil
      ManagerCall(RaidCore.E.BUFF_REMOVE, nId, current.nSpellId, sName, current.unitCaster)
    end
  end

  for nIdBuff, tNew in next, tNewBuffs do
    tBuffs[nIdBuff] = tNew
    ManagerCall(RaidCore.E.BUFF_ADD, nId, tNew.nSpellId, tNew.nCount, tNew.fTimeRemaining, sName, tNew.unitCaster)
  end
end

function RaidCore:CI_OnBuff(tUnit, tBuff, sMsgBuff, sMsgDebuff)
  local bBeneficial = tBuff.splEffect:IsBeneficial()
  local nSpellId = tBuff.splEffect:GetId()
  local sEvent = bBeneficial and sMsgBuff or sMsgDebuff
  local bProcessDebuffs = tUnit:IsACharacter()
  local nUnitId
  local sName

  -- Track debuffs for players and buffs for enemies
  if bProcessDebuffs and (not bBeneficial or SPELLID_WHITELIST[nSpellId]) then
    if not SPELLID_BLACKLISTED[nSpellId] and self:IsUnitInGroup(tUnit) then
      nUnitId = tUnit:GetId()
      sName = tUnit:GetName()
    end
    --NOTE: Tracking other units with these events is currently buggy
    --elseif not bProcessDebuffs and bBeneficial then
    --nUnitId = tUnit:GetId()
    --sName = self:ReplaceNoBreakSpace(tUnit:GetName())
  end
  return sEvent, nUnitId, nSpellId, sName
end

local function UpdateTrackedBuff(sEvent, nUnitId, nSpellId, sName, tBuff)
  if tBuff.fTimeRemaining == 0 then
    return -- Filter out permanent buffs
  end
  _tTrackedBuffs[nUnitId..nSpellId] = {
    sEvent = sEvent,
    nUnitId = nUnitId,
    nSpellId = nSpellId,
    sName = sName,
    tBuff = tBuff,
    nEndTime = GetGameTime() + tBuff.fTimeRemaining + TRACKED_BUFFS_PERIOD * 2,
  }
end

local function DeleteTrackedBuff(nUnitId, nSpellId)
  _tTrackedBuffs[nUnitId..nSpellId] = nil
end

local function DelayFireTrackedDebuff(tTrackedBuff)
  local sEvent = RaidCore.E.DEBUFF_REMOVE
  if tTrackedBuff.sEvent == RaidCore.E.BUFF_ADD or tTrackedBuff.sEvent == RaidCore.E.BUFF_UPDATE then
    sEvent = RaidCore.E.BUFF_REMOVE
  end
  ManagerCall(sEvent, tTrackedBuff.nUnitId, tTrackedBuff.nSpellId, tTrackedBuff.sName, tTrackedBuff.tBuff.unitCaster)
  DeleteTrackedBuff(tTrackedBuff.nUnitId, tTrackedBuff.nSpellId)
end

function RaidCore:CI_OnBuffAdded(tUnit, tBuff)
  local sEvent, nUnitId, nSpellId, sName = self:CI_OnBuff(tUnit, tBuff, RaidCore.E.BUFF_ADD, RaidCore.E.DEBUFF_ADD)
  if nUnitId then
    UpdateTrackedBuff(sEvent, nUnitId, nSpellId, sName, tBuff)
    ManagerCall(sEvent, nUnitId, nSpellId, tBuff.nCount, tBuff.fTimeRemaining, sName, tBuff.unitCaster)
  end
end

function RaidCore:CI_OnBuffUpdated(tUnit, tBuff)
  local sEvent, nUnitId, nSpellId, sName = self:CI_OnBuff(tUnit, tBuff, RaidCore.E.BUFF_UPDATE, RaidCore.E.DEBUFF_UPDATE)
  if nUnitId then
    UpdateTrackedBuff(sEvent, nUnitId, nSpellId, sName, tBuff)
    ManagerCall(sEvent, nUnitId, nSpellId, tBuff.nCount, tBuff.fTimeRemaining, sName, tBuff.unitCaster)
  end
end

function RaidCore:CI_OnBuffRemoved(tUnit, tBuff)
  local sEvent, nUnitId, nSpellId, sName = self:CI_OnBuff(tUnit, tBuff, RaidCore.E.BUFF_REMOVE, RaidCore.E.DEBUFF_REMOVE)
  if nUnitId then
    DeleteTrackedBuff(nUnitId, nSpellId)
    ManagerCall(sEvent, nUnitId, nSpellId, sName, tBuff.unitCaster)
  end
end

function RaidCore:IsUnitInGroup(tUnit)
  return tUnit:IsInYourGroup() or tUnit:IsThePlayer()
end

----------------------------------------------------------------------------------------------------
-- Privates functions: State Machine
----------------------------------------------------------------------------------------------------
local function UnitInCombatActivate(bEnable)
  if _bUnitInCombatEnable == false and bEnable == true then
    RegisterEventHandler(RaidCore.E.EVENT_UNIT_ENTERED_COMBAT, "CI_OnEnteredCombat", RaidCore)
  elseif _bUnitInCombatEnable == true and bEnable == false then
    RemoveEventHandler(RaidCore.E.EVENT_UNIT_ENTERED_COMBAT, RaidCore)
  end
  _bUnitInCombatEnable = bEnable
end

local function UnitScanActivate(bEnable)
  if _bDetectAllEnable == false and bEnable == true then
    RegisterEventHandler(RaidCore.E.EVENT_UNIT_CREATED, "CI_OnUnitCreated", RaidCore)
    RegisterEventHandler(RaidCore.E.EVENT_UNIT_DESTROYED, "CI_OnUnitDestroyed", RaidCore)
  elseif _bDetectAllEnable == true and bEnable == false then
    RemoveEventHandler(RaidCore.E.EVENT_UNIT_CREATED, RaidCore)
    RemoveEventHandler(RaidCore.E.EVENT_UNIT_DESTROYED, RaidCore)
  end
  _bDetectAllEnable = bEnable
end

local function FullActivate(bEnable)
  if _bRunning == false and bEnable == true then
    Log:SetRefTime(GetGameTime())
    RegisterEventHandler(RaidCore.E.EVENT_CHAT_MESSAGE, "CI_OnChatMessage", RaidCore)
    RegisterEventHandler(RaidCore.E.EVENT_SHOW_ACTION_BAR_SHORTCUT, "CI_ShowShortcutBar", RaidCore)
    RegisterEventHandler(RaidCore.E.EVENT_BUFF_ADDED, "CI_OnBuffAdded", RaidCore)
    RegisterEventHandler(RaidCore.E.EVENT_BUFF_UPDATED, "CI_OnBuffUpdated", RaidCore)
    RegisterEventHandler(RaidCore.E.EVENT_BUFF_REMOVED, "CI_OnBuffRemoved", RaidCore)
    _tScanTimer:Start()
    _tTrackedDebuffTimer:Start()
  elseif _bRunning == true and bEnable == false then
    _tScanTimer:Stop()
    _tTrackedDebuffTimer:Stop()
    RemoveEventHandler(RaidCore.E.EVENT_CHAT_MESSAGE, RaidCore)
    RemoveEventHandler(RaidCore.E.EVENT_SHOW_ACTION_BAR_SHORTCUT, RaidCore)
    RemoveEventHandler(RaidCore.E.EVENT_BUFF_ADDED, RaidCore)
    RemoveEventHandler(RaidCore.E.EVENT_BUFF_UPDATED, RaidCore)
    RemoveEventHandler(RaidCore.E.EVENT_BUFF_REMOVED, RaidCore)
    Log:NextBuffer()
    -- Clear private data.
    _tTrackedUnits = {}
    _tAllUnits = {}
    _tTrackedBuffs = {}
  end
  _bRunning = bEnable
end

local function RemoveAllExtraActivation()
  for sEvent, _ in next, _CI_Extra do
    RemoveEventHandler(sEvent, RaidCore)
    _CI_Extra[sEvent] = nil
  end
end

local function InterfaceSwitch(to)
  RemoveAllExtraActivation()
  if to == RaidCore.E.INTERFACE_DISABLE then
    UnitInCombatActivate(false)
    UnitScanActivate(false)
    FullActivate(false)
  elseif to == RaidCore.E.INTERFACE_DETECTCOMBAT then
    UnitInCombatActivate(true)
    UnitScanActivate(false)
    FullActivate(false)
  elseif to == RaidCore.E.INTERFACE_DETECTALL then
    UnitInCombatActivate(true)
    UnitScanActivate(true)
    FullActivate(false)
  elseif to == RaidCore.E.INTERFACE_LIGHTENABLE then
    UnitInCombatActivate(true)
    UnitScanActivate(false)
    FullActivate(true)
  elseif to == RaidCore.E.INTERFACE_FULLENABLE then
    UnitInCombatActivate(true)
    UnitScanActivate(true)
    FullActivate(true)
  end
  _CI_State = to
end

----------------------------------------------------------------------------------------------------
-- ICCom functions.
----------------------------------------------------------------------------------------------------
local function JoinSuccess()
  Log:Add(RaidCore.E.JOIN_CHANNEL_STATUS, "Join Success")
  _CommChannelTimer:Stop()
  _RaidCoreChannelComm:SetReceivedMessageFunction("CI_OnReceivedMessage", RaidCore)
  _RaidCoreChannelComm:SetSendMessageResultFunction("CI_OnSendMessageResult", RaidCore)
end

function RaidCore:CI_JoinChannelTry()
  local eChannelType = ICCommLib.CodeEnumICCommChannelType.Group
  local sChannelName = "RaidCore"

  -- Log this try.
  Log:Add(RaidCore.E.JOIN_CHANNEL_TRY, sChannelName, "Group")
  -- Request to join the channel.
  _RaidCoreChannelComm = ICCommLib.JoinChannel(sChannelName, eChannelType)
  -- Start a timer to retry to join.
  _CommChannelTimer = ApolloTimer.Create(_nCommChannelRetry, false, "CI_JoinChannelTry", RaidCore)
  _nCommChannelRetry = _nCommChannelRetry < 30 and _nCommChannelRetry + 5 or 30

  if _RaidCoreChannelComm then
    if _RaidCoreChannelComm:IsReady() then
      JoinSuccess()
    else
      Log:Add(RaidCore.E.JOIN_CHANNEL_STATUS, "In Progress")
      _RaidCoreChannelComm:SetJoinResultFunction("CI_OnJoinResultFunction", RaidCore)
    end
  end
end

function RaidCore:CI_OnJoinResultFunction(tChannel, eResult)
  if eResult == ICCommLib.CodeEnumICCommJoinResult.Join then
    JoinSuccess()
  else
    for sJoinResult, ResultId in next, ICCommLib.CodeEnumICCommJoinResult do
      if ResultId == eResult then
        Log:Add(RaidCore.E.JOIN_CHANNEL_STATUS, sJoinResult)
        break
      end
    end
  end
end

----------------------------------------------------------------------------------------------------
-- Relations between RaidCore and CombatInterface.
----------------------------------------------------------------------------------------------------
function RaidCore:CombatInterface_Init()
  _tAllUnits = {}
  _tTrackedUnits = {}
  _tScanTimer = ApolloTimer.Create(SCAN_PERIOD, true, "CI_OnScanUpdate", self)
  _tScanTimer:Stop()
  _tTrackedDebuffTimer = ApolloTimer.Create(TRACKED_BUFFS_PERIOD, true, "CI_OnCheckTrackedBuffs", self)
  _tTrackedDebuffTimer:Stop()

  -- Permanent registering.
  RegisterEventHandler(RaidCore.E.EVENT_CHANGE_WORLD, "CI_OnChangeWorld", self)
  RegisterEventHandler(RaidCore.E.EVENT_CHARACTER_CREATED, "CI_OnCharacterCreated", self)
  RegisterEventHandler(RaidCore.E.EVENT_SUB_ZONE_CHANGED, "CI_OnSubZoneChanged", self)

  InterfaceSwitch(RaidCore.E.INTERFACE_DISABLE)
  self.wndBarItem = Apollo.LoadForm(self.xmlDoc, "ActionBarShortcutItem", "FixedHudStratum", self)
  self.ActionBarShortcutBtn = self.wndBarItem:FindChild("ActionBarShortcutBtn")
end

function RaidCore:CombatInterface_Activate(nState)
  InterfaceSwitch(nState)
end

function RaidCore:CombatInterface_ExtraActivate(sEvent, bNewState)
  assert(type(sEvent) == "string")
  if _CI_State == RaidCore.E.INTERFACE_LIGHTENABLE or _CI_State == RaidCore.E.INTERFACE_FULLENABLE then
    if EXTRA_HANDLER_ALLOWED[sEvent] then
      if not _CI_Extra[sEvent] and bNewState then
        _CI_Extra[sEvent] = true
        RegisterEventHandler(sEvent, EXTRA_HANDLER_ALLOWED[sEvent], RaidCore)
      elseif _CI_Extra[sEvent] and not bNewState then
        RemoveEventHandler(sEvent, RaidCore)
        _CI_Extra[sEvent] = nil
      end
    else
      Log:Add(RaidCore.E.ERROR, ("Extra event '%s' is not supported"):format(sEvent))
    end

  end
end

-- Track buff and cast of this unit.
-- @param unit userdata object related to an unit in game.
-- @param nTrackingType describes what kind of events should be tracked for this unit
-- and different tracking types can be added together to enable multiple ones.
-- After discovering what kind of events are needed for a unit it is advised to
-- disable the other events to skip unneeded and performance intensive code.
-- Currently supports TRACK_ALL, TRACK_BUFFS, TRACK_CASTS and TRACK_HEALTH
-- :WatchUnit(unit, core.E.TRACK_ALL)
-- :WatchUnit(unit, core.E.TRACK_CASTS + core.E.TRACK_BUFFS)
function RaidCore:WatchUnit(unit, nTrackingType)
  TrackThisUnit(unit, nTrackingType)
end

-- Untrack buff and cast of this unit.
-- @param unit userdata object related to an unit in game.
function RaidCore:UnwatchUnit(unit)
  UnTrackThisUnit(unit:GetId())
end

function RaidCore:CombatInterface_GetTrackedById(nId)
  return _tTrackedUnits[nId]
end

function RaidCore:CombatInterface_SendMessage(sMessage, tDPlayerId)
  assert(type(sMessage) == "string")
  assert(type(tDPlayerId) == "number" or tDPlayerId == nil)

  if not _RaidCoreChannelComm then
    Log:Add(RaidCore.E.CHANNEL_COMM_STATUS, "Channel not found")
  elseif tDPlayerId == nil then
    -- Broadcast the message on RaidCore Channel (type: Group).
    _RaidCoreChannelComm:SendMessage(sMessage)
    Log:Add(RaidCore.E.SEND_MESSAGE, sMessage, tDPlayerId)
  else
    -- Send the message to this player.
    local tPlayerUnit = GetUnitById(tDPlayerId)
    if not tPlayerUnit then
      Log:Add(RaidCore.E.CHANNEL_COMM_STATUS, "Send aborded by Unknown ID")
    elseif not tPlayerUnit:IsInYourGroup() then
      Log:Add(RaidCore.E.CHANNEL_COMM_STATUS, "Send aborded by invalid PlayerUnit")
    else
      _RaidCoreChannelComm:SendPrivateMessage(tPlayerUnit:GetName(), sMessage)
      Log:Add(RaidCore.E.SEND_MESSAGE, sMessage, tDPlayerId)
    end
  end
end

----------------------------------------------------------------------------------------------------
-- Combat Interface layer.
----------------------------------------------------------------------------------------------------
function RaidCore:CI_OnEnteredCombat(tUnit, bInCombat)
  local tOwner = tUnit.GetUnitOwner and tUnit:GetUnitOwner()
  local bIsPetPlayer = tOwner and self:IsUnitInGroup(tOwner)
  if not bIsPetPlayer then
    local nId = tUnit:GetId()
    local sName = self:ReplaceNoBreakSpace(tUnit:GetName())
    if not self:IsUnitInGroup(tUnit) then
      if not _tAllUnits[nId] then
        ManagerCall(RaidCore.E.UNIT_CREATED, nId, tUnit, sName)
      end
      _tAllUnits[nId] = true
    end
    ManagerCall(RaidCore.E.ENTERED_COMBAT, nId, tUnit, sName, bInCombat)
  end
end

function RaidCore:CI_OnUnitCreated(tUnit)
  local nId = tUnit:GetId()
  if not self:IsUnitInGroup(tUnit) then
    local sName = self:ReplaceNoBreakSpace(tUnit:GetName())
    local tOwner = tUnit.GetUnitOwner and tUnit:GetUnitOwner()
    local bIsPetPlayer = tOwner and self:IsUnitInGroup(tOwner)
    if not bIsPetPlayer and not _tAllUnits[nId] then
      _tAllUnits[nId] = true
      ManagerCall(RaidCore.E.UNIT_CREATED, nId, tUnit, sName)
      LogUnitSpawnLocation(nId, sName, tUnit:GetPosition())
    end
  end
end

function RaidCore:CI_OnUnitDestroyed(tUnit)
  local nId = tUnit:GetId()
  if _tAllUnits[nId] then
    _tAllUnits[nId] = nil
    UnTrackThisUnit(nId)
    local sName = self:ReplaceNoBreakSpace(tUnit:GetName())
    ManagerCall(RaidCore.E.UNIT_DESTROYED, nId, tUnit, sName)
  end
end

function RaidCore:CI_UpdateBuffs(myUnit)
  -- Process buff tracking.
  local s, e = pcall(PollUnitBuffs, myUnit)
  self:HandlePcallResult(s, e)
end

function RaidCore:CI_UpdateCasts(myUnit, nId, nCurrentTime)
  -- Process cast tracking.
  local bCasting = myUnit.tUnit:IsCasting()
  local sCastName
  local nCastDuration
  local nCastElapsed
  local nCastEndTime
  if bCasting then
    sCastName = myUnit.tUnit:GetCastName()
    nCastDuration = myUnit.tUnit:GetCastDuration()
    nCastElapsed = myUnit.tUnit:GetCastElapsed()
    nCastEndTime = nCurrentTime + (nCastDuration - nCastElapsed) / 1000
    -- Refresh needed if the function is called at the end of cast.
    -- Like that, previous myUnit retrieved are valid.
    bCasting = myUnit.tUnit:IsCasting()
  end
  if bCasting then
    sCastName = self:ReplaceNoBreakSpace(sCastName)
    if not myUnit.tCast.bCasting then
      -- New cast
      myUnit.tCast = {
        bCasting = true,
        sCastName = sCastName,
        nCastEndTime = nCastEndTime,
        bSuccess = false,
      }
      ManagerCall(RaidCore.E.CAST_START, nId, sCastName, nCastEndTime, myUnit.sName)
    elseif myUnit.tCast.bCasting then
      if sCastName ~= myUnit.tCast.sCastName then
        -- New cast just after a previous one.
        if myUnit.tCast.bSuccess == false then
          ManagerCall(RaidCore.E.CAST_END, nId, myUnit.tCast.sCastName, false, myUnit.tCast.nCastEndTime, myUnit.sName)
        end
        myUnit.tCast = {
          bCasting = true,
          sCastName = sCastName,
          nCastEndTime = nCastEndTime,
          bSuccess = false,
        }
        ManagerCall(RaidCore.E.CAST_START, nId, sCastName, nCastEndTime, myUnit.sName)
      elseif not myUnit.tCast.bSuccess and nCastElapsed >= nCastDuration then
        -- The have reached the end.
        ManagerCall(RaidCore.E.CAST_END, nId, myUnit.tCast.sCastName, false, myUnit.tCast.nCastEndTime, myUnit.sName)
        myUnit.tCast = {
          bCasting = true,
          sCastName = sCastName,
          nCastEndTime = 0,
          bSuccess = true,
        }
      end
    end
  elseif myUnit.tCast.bCasting then
    if not myUnit.tCast.bSuccess then
      -- Let's compare with the nCastEndTime
      local nThreshold = nCurrentTime + SCAN_PERIOD
      local bIsInterrupted
      if nThreshold < myUnit.tCast.nCastEndTime then
        bIsInterrupted = true
      else
        bIsInterrupted = false
      end
      ManagerCall(RaidCore.E.CAST_END, nId, myUnit.tCast.sCastName, bIsInterrupted, myUnit.tCast.nCastEndTime, myUnit.sName)
    end
    myUnit.tCast = {
      bCasting = false,
      sCastName = "",
      nCastEndTime = 0,
      bSuccess = false,
    }
  end
end

function RaidCore:CI_UpdateHealth(myUnit, nId)
  -- Process Health tracking.
  local MaxHealth = myUnit.tUnit:GetMaxHealth()
  local Health = myUnit.tUnit:GetHealth()
  if Health and MaxHealth then
    local nPercent = math.floor(100 * Health / MaxHealth)
    if myUnit.nPreviousHealthPercent ~= nPercent then
      myUnit.nPreviousHealthPercent = nPercent
      ManagerCall(RaidCore.E.HEALTH_CHANGED, nId, nPercent, myUnit.sName)
    end
  end
end

function RaidCore:CI_OnCheckTrackedBuffs()
  local nCurrentTime = GetGameTime()
  for id, tTrackedBuff in next, _tTrackedBuffs do
    if tTrackedBuff.nEndTime < nCurrentTime then
      DelayFireTrackedDebuff(tTrackedBuff)
    end
  end
end

function RaidCore:CI_OnScanUpdate()
  local nCurrentTime = GetGameTime()
  for nId, data in next, _tTrackedUnits do
    if data.tUnit:IsValid() then
      -- Process name update.
      data.sName = self:ReplaceNoBreakSpace(data.tUnit:GetName())

      if data.bTrackBuffs then
        self:CI_UpdateBuffs(data, nId)
      end
      if data.bTrackCasts then
        self:CI_UpdateCasts(data, nId, nCurrentTime)
      end
      if data.bTrackHealth then
        self:CI_UpdateHealth(data, nId)
      end
    end
  end
end

function RaidCore:CI_OnChatMessage(tChannelCurrent, tMessage)
  local nChannelType = tChannelCurrent:GetType()
  local sHandler = CHANNEL_HANDLERS[nChannelType]
  if sHandler then
    local sSender = self:ReplaceNoBreakSpace(tMessage.strSender or "")
    local sMessage = ""
    for _, tSegment in next, tMessage.arMessageSegments do
      sMessage = sMessage .. self:ReplaceNoBreakSpace(tSegment.strText)
    end
    ManagerCall(sHandler, sMessage, sSender)
  end
end

function RaidCore:CI_OnReceivedMessage(sChannel, sMessage, sSender)
  local tSender = sSender and GetPlayerUnitByName(sSender)
  local nSenderId = tSender and tSender:GetId()
  ManagerCall(RaidCore.E.RECEIVED_MESSAGE, sMessage, nSenderId)
end

function RaidCore:CI_OnSendMessageResult(iccomm, eResult, nMessageId)
  local sResult = tostring(eResult)
  for stext, key in next, ICCommLib.CodeEnumICCommMessageResult do
    if eResult == key then
      sResult = stext
      break
    end
  end
  Log:Add(RaidCore.E.SEND_MESSAGE_RESULT, sResult, nMessageId)
end

function RaidCore:CI_ShowShortcutBar(eWhichBar, bIsVisible, nNumShortcuts)
  if eWhichBar == ActionSetLib.CodeEnumShortcutSet.FloatingSpellBar then
    -- The GetContent function is not ready... A delay must be added.
    _nNumShortcuts = nNumShortcuts
    ApolloTimer.Create(1, false, "CI_ShowShortcutBarDelayed", RaidCore)
  end
end

function RaidCore:CI_ShowShortcutBarDelayed()
  local eWhichBar = ActionSetLib.CodeEnumShortcutSet.FloatingSpellBar
  local tIconFloatingSpellBar = {}
  for iBar = 0, _nNumShortcuts do
    self.ActionBarShortcutBtn:SetContentId(eWhichBar * 12 + iBar)
    local tButtonContent = self.ActionBarShortcutBtn:GetContent()
    local strIcon = tButtonContent and tButtonContent.strIcon
    if strIcon == nil or strIcon == "" then
      break
    end
    table.insert(tIconFloatingSpellBar, strIcon)
  end
  ManagerCall(RaidCore.E.SHOW_SHORTCUT_BAR, tIconFloatingSpellBar)
end

function RaidCore:CI_OnCombatLogHeal(tArgs)
  local nCasterId = tArgs.unitCaster and tArgs.unitCaster:GetId()
  local nTargetId = tArgs.unitTarget and tArgs.unitTarget:GetId()
  local sCasterName = tArgs.unitCaster and self:ReplaceNoBreakSpace(tArgs.unitCaster:GetName()) or ""
  local sTargetName = tArgs.unitTarget and self:ReplaceNoBreakSpace(tArgs.unitTarget:GetName()) or ""
  local nHealAmount = tArgs.nHealAmount or 0
  local nOverHeal = tArgs.nOverHeal or 0
  local nSpellId = tArgs.splCallingSpell and tArgs.splCallingSpell:GetId()
  ManagerCall(RaidCore.E.COMBAT_LOG_HEAL, nCasterId, nTargetId, sCasterName, sTargetName, nHealAmount, nOverHeal, nSpellId)
end

function RaidCore:CI_OnChangeWorld()
  ManagerCall(RaidCore.E.CHANGE_WORLD)
end

function RaidCore:CI_OnCharacterCreated()
  ManagerCall(RaidCore.E.CHARACTER_CREATED)
end

function RaidCore:CI_OnSubZoneChanged(nZoneId, sZoneName)
  ManagerCall(RaidCore.E.SUB_ZONE_CHANGE, nZoneId, sZoneName)
end
