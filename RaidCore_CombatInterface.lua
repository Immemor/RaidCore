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
require "Apollo"
require "GameLib"
require "ApolloTimer"
require "ChatSystemLib"
require "ActionSetLib"
require "Spell"
require "GroupLib"
require "ICCommLib"
require "ICComm"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local Log = Apollo.GetPackage("Log-1.0").tPackage

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local RegisterEventHandler = Apollo.RegisterEventHandler
local RemoveEventHandler = Apollo.RemoveEventHandler
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local GetSpell = GameLib.GetSpell
local next, string, pcall  = next, string, pcall
local tinsert = table.insert

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with French language.
local NO_BREAK_SPACE = string.char(194, 160)
local SCAN_PERIOD = 0.1 -- in seconds.
-- Array with chat permission.
local CHANNEL_HANDLERS = {
    [ChatSystemLib.ChatChannel_Say] = nil,
    [ChatSystemLib.ChatChannel_Party] = nil,
    [ChatSystemLib.ChatChannel_NPCSay] = "OnNPCSay",
    [ChatSystemLib.ChatChannel_NPCYell] = "OnNPCYell",
    [ChatSystemLib.ChatChannel_NPCWhisper] = "OnNPCWhisper",
    [ChatSystemLib.ChatChannel_Datachron] = "OnDatachron",
}
local SPELLID_BLACKLISTED = {
    [60883] = "Irradiate", -- On war class.
    [79671] = "Empower", -- On war class.
    [72651] = "Surge Focus Drain", -- On arcanero class.
    [72652] = "Surge Focus Drain", -- On arcanero class.
}
-- State Machine.
local INTERFACE__DISABLE = 1
local INTERFACE__DETECTCOMBAT = 2
local INTERFACE__DETECTALL = 3
local INTERFACE__LIGHTENABLE = 4
local INTERFACE__FULLENABLE = 5
local INTERFACE_STATES = {
    ["Disable"] = INTERFACE__DISABLE,
    ["DetectCombat"] = INTERFACE__DETECTCOMBAT,
    ["DetectAll"] = INTERFACE__DETECTALL,
    ["LightEnable"] = INTERFACE__LIGHTENABLE,
    ["FullEnable"] = INTERFACE__FULLENABLE,
}
local EXTRA_HANDLER_ALLOWED = {
    ["CombatLogHeal"] = "CI_OnCombatLogHeal",
}

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _bDetectAllEnable = false
local _bUnitInCombatEnable = false
local _bRunning = false
local _tScanTimer = nil
local _CommChannelTimer = nil
local _DelayShowShortcutBar = nil
local _nCommChannelRetry = 5
local _tAllUnits = {}
local _tTrackedUnits = {}
local _tMembers = {}
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
    local s, sErrMsg = pcall(RaidCore.GlobalEventHandler, RaidCore, sMethod, ...)
    if not s then
        --@alpha@
        Print(sMethod .. ": " .. sErrMsg)
        --@end-alpha@
        Log:Add("ERROR", sErrMsg)
    end
end

local function ExtraLog2Text(k, nRefTime, tParam)
    local sResult = ""
    if k == "ERROR" then
        sResult = tParam[1]
    elseif k == "OnDebuffAdd" or k == "OnBuffAdd" then
        local sSpellName = GetSpell(tParam[2]):GetName():gsub(NO_BREAK_SPACE, " ")
        local sFormat = "Id=%u SpellName='%s' SpellId=%u Stack=%d fTimeRemaining=%.2f"
        sResult = sFormat:format(tParam[1], sSpellName, tParam[2], tParam[3], tParam[4])
    elseif k == "OnDebuffRemove" or k == "OnBuffRemove" then
        local sSpellName = GetSpell(tParam[2]):GetName():gsub(NO_BREAK_SPACE, " ")
        local sFormat = "Id=%u SpellName='%s' SpellId=%u"
        sResult = sFormat:format(tParam[1], sSpellName, tParam[2])
    elseif k == "OnDebuffUpdate" or k == "OnBuffUpdate" then
        local sSpellName = GetSpell(tParam[2]):GetName():gsub(NO_BREAK_SPACE, " ")
        local sFormat = "Id=%u SpellName='%s' SpellId=%u OldStack=%d NewStack=%d fTimeRemaining=%.2f"
        sResult = sFormat:format(tParam[1], sSpellName, tParam[2], tParam[3], tParam[4], tParam[5])
    elseif k == "OnCastStart" then
        local nCastEndTime = tParam[3] - nRefTime
        local sFormat = "Id=%u CastName='%s' CastEndTime=%.3f sName=\"%s\""
        sResult = sFormat:format(tParam[1], tParam[2], nCastEndTime, tParam[4])
    elseif k == "OnCastEnd" then
        local nCastEndTime = tParam[4] - nRefTime
        local sFormat = "Id=%u CastName='%s' IsInterrupted=%s CastEndTime=%.3f sName=\"%s\""
        sResult = sFormat:format(tParam[1], tParam[2], tostring(tParam[3]), nCastEndTime, tParam[5])
    elseif k == "OnUnitCreated" then
        local sFormat = "Id=%u Unit='%s'"
        sResult = sFormat:format(tParam[1], tParam[3])
    elseif k == "OnUnitDestroyed" then
        local sFormat = "Id=%u Unit='%s'"
        sResult = sFormat:format(tParam[1], tParam[3])
    elseif k == "OnEnteredCombat" then
        local sFormat = "Id=%u Unit='%s' InCombat=%s"
        sResult = sFormat:format(tParam[1], tParam[3], tostring(tParam[4]))
    elseif k == "OnNPCSay" or k == "OnNPCYell" or k == "OnNPCWhisper" or k == "OnDatachron" then
        local sFormat = "sMessage='%s' sSender='%s'"
        sResult = sFormat:format(tParam[1], tParam[2])
    elseif k == "TrackThisUnit" or k == "UnTrackThisUnit" then
        sResult = ("Id='%s'"):format(tParam[1])
    elseif k == "WARNING tUnit reference changed" then
        sResult = ("OldId=%u NewId=%u"):format(tParam[1], tParam[2])
    elseif k == "OnShowShortcutBar" then
        sResult = "sIcon=" .. table.concat(tParam[1], ", ")
    elseif k == "SendMessage" then
        local sFormat = "sMsg=\"%s\" to=\"%s\""
        sResult = sFormat:format(tParam[1], tostring(tParam[2]))
    elseif k == "OnReceivedMessage" then
        local sFormat = "sMsg=\"%s\" SenderId=%s"
        sResult = sFormat:format(tParam[1], tostring(tParam[2]))
    elseif k == "ChannelCommStatus" then
        sResult = tParam[1]
    elseif k == "SendMessageResult" then
        sResult = ("sResult=\"%s\" MsgId=%d"):format(tParam[1], tParam[2])
    elseif k == "JoinChannelTry" then
        sResult = ("ChannelName=\"%s\" ChannelType=\"%s\""):format(tParam[1], tParam[2])
    elseif k == "JoinChannelStatus" then
        local sFormat = "Result=\"%s\""
        sResult = sFormat:format(tParam[1])
    elseif k == "OnCombatLogHeal" then
        local sFormat = "CasterId=%s TargetId=%s sCasterName=\"%s\" sTargetName=\"%s\" nHealAmount=%u nOverHeal=%u nSpellId=%u"
        sResult = sFormat:format(tostring(tParam[1]), tostring(tParam[2]), tParam[3], tParam[4], tParam[5], tParam[6], tParam[7])
    elseif k == "OnHealthChanged" then
        local sFormat = "Id=%u nPourcent=%.2f sName=\"%s\""
        sResult = sFormat:format(tParam[1], tParam[2], tParam[3])
    elseif k == "OnSubZoneChanged" then
        local sFormat = "ZoneId=%u ZoneName=\"%s\""
        sResult = sFormat:format(tParam[1], tParam[2])
    elseif k == "CurrentZoneMap" then
        local sFormat = "ContinentId=%u ZoneId=%u Id=%u"
        sResult = sFormat:format(tParam[1], tParam[2], tParam[3])
    end
    return sResult
end
Log:SetExtra2String(ExtraLog2Text)

----------------------------------------------------------------------------------------------------
-- Privates functions: unit processing
----------------------------------------------------------------------------------------------------
local function GetAllBuffs(tUnit)
    local r = {}
    if tUnit then
        local tAllBuffs = tUnit:GetBuffs()
        if tAllBuffs then
            for sType, tBuffs in next, tAllBuffs do
                r[sType] = {}
                for _,obj in next, tBuffs do
                    local nSpellId = obj.splEffect:GetId()
                    if nSpellId and not SPELLID_BLACKLISTED[nSpellId] then
                        r[sType][obj.idBuff] = {
                            nCount = obj.nCount,
                            nSpellId = nSpellId,
                            fTimeRemaining = obj.fTimeRemaining,
                        }
                    end
                end
            end
        end
    end
    return r
end

local function TrackThisUnit(nId)
    local tUnit = GetUnitById(nId)
    if not _tTrackedUnits[nId] and tUnit and not tUnit:IsInYourGroup() then
        Log:Add("TrackThisUnit", nId)
        local tAllBuffs = GetAllBuffs(tUnit)
        local MaxHealth = tUnit:GetMaxHealth()
        local Health = tUnit:GetHealth()
        local nPourcent = Health and MaxHealth and math.floor(100 * Health / MaxHealth)
        _tAllUnits[nId] = true
        _tTrackedUnits[nId] = {
            tUnit = tUnit,
            sName = tUnit:GetName():gsub(NO_BREAK_SPACE, " "),
            nId = nId,
            tBuffs = tAllBuffs["arBeneficial"] or {},
            tDebuffs = {},
            bIsACharacter = false,
            tCast = {
                bCasting = false,
                sCastName = "",
                nCastEndTime = 0,
                bSuccess = false,
            },
            nPreviousHealthPourcent = nPourcent,
        }
    end
end

local function UnTrackThisUnit(nId)
    if _tTrackedUnits[nId] then
        Log:Add("UnTrackThisUnit", nId)
        _tTrackedUnits[nId] = nil
    end
end

local function ProcessAllBuffs(tMyUnit)
    local tAllBuffs = GetAllBuffs(tMyUnit.tUnit)
    local bProcessDebuffs = tMyUnit.bIsACharacter
    local bProcessBuffs = not bProcessDebuffs
    local nId = tMyUnit.nId

    local tNewDebuffs = tAllBuffs["arHarmful"]
    local tDebuffs = tMyUnit.tDebuffs
    if bProcessDebuffs and tNewDebuffs then
        for nIdBuff,current in next, tDebuffs do
            if tNewDebuffs[nIdBuff] then
                local tNew = tNewDebuffs[nIdBuff]
                if tNew.nCount ~= current.nCount then
                    local nOld = current.nCount
                    tDebuffs[nIdBuff].nCount = tNew.nCount
                    tDebuffs[nIdBuff].fTimeRemaining = tNew.fTimeRemaining
                    ManagerCall("OnDebuffUpdate", nId, current.nSpellId, nOld, tNew.nCount, tNew.fTimeRemaining)
                end
                -- Remove this entry for second loop.
                tNewDebuffs[nIdBuff] = nil
            else
                tDebuffs[nIdBuff] = nil
                ManagerCall("OnDebuffRemove", nId, current.nSpellId)
            end
        end
        for nIdBuff,tNew in next, tNewDebuffs do
            tDebuffs[nIdBuff] = tNew
            ManagerCall("OnDebuffAdd", nId, tNew.nSpellId, tNew.nCount, tNew.fTimeRemaining)
        end
    end

    local tNewBuffs = tAllBuffs["arBeneficial"]
    local tBuffs = tMyUnit.tBuffs
    if bProcessBuffs and tNewBuffs then
        for nIdBuff,current in next, tBuffs do
            if tNewBuffs[nIdBuff] then
                local tNew = tNewBuffs[nIdBuff]
                if tNew.nCount ~= current.nCount then
                    local nOld = current.nCount
                    tBuffs[nIdBuff].nCount = tNew.nCount
                    tBuffs[nIdBuff].fTimeRemaining = tNew.fTimeRemaining
                    ManagerCall("OnBuffUpdate", nId, current.nSpellId, nOld, tNew.nCount, tNew.fTimeRemaining)
                end
                -- Remove this entry for second loop.
                tNewBuffs[nIdBuff] = nil
            else
                tBuffs[nIdBuff] = nil
                ManagerCall("OnBuffRemove", nId, current.nSpellId)
            end
        end
        for nIdBuff, tNew in next, tNewBuffs do
            tBuffs[nIdBuff] = tNew
            ManagerCall("OnBuffAdd", nId, tNew.nSpellId, tNew.nCount, tNew.fTimeRemaining)
        end
    end
end

local function UpdateMemberList()
    for i = 1, GroupLib.GetMemberCount() do
        local tUnit = GroupLib.GetUnitForGroupMember(i)
        -- A Friend out of range have a tUnit object equal to nil.
        -- And if you have the tUnit object, the IsValid flag can change.
        if tUnit then
            local sName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
            if not _tMembers[sName] then
                local tAllBuffs = GetAllBuffs(tUnit)
                _tMembers[sName] = {
                    tUnit = tUnit,
                    nId = tUnit:GetId(),
                    tDebuffs = tAllBuffs["arHarmful"] or {},
                    tBuffs = {},
                    bIsACharacter = true,
                }
            elseif _tMembers[sName].tUnit ~= tUnit then
                local nOldId = _tMembers[sName].nId
                local nNewId = tUnit:GetId()
                Log:Add("WARNING tUnit reference changed", nOldId, nNewId)
                _tMembers[sName].tUnit = tUnit
                _tMembers[sName].nId = nNewId
            end
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Privates functions: State Machine
----------------------------------------------------------------------------------------------------
local function UnitInCombatActivate(bEnable)
    if _bUnitInCombatEnable == false and bEnable == true then
        RegisterEventHandler("UnitEnteredCombat", "CI_OnEnteredCombat", RaidCore)
    elseif _bUnitInCombatEnable == true and bEnable == false then
        RemoveEventHandler("UnitEnteredCombat", RaidCore)
    end
    _bUnitInCombatEnable = bEnable
end

local function UnitScanActivate(bEnable)
    if _bDetectAllEnable == false and bEnable == true then
        RegisterEventHandler("UnitCreated", "CI_OnUnitCreated", RaidCore)
        RegisterEventHandler("UnitDestroyed", "CI_OnUnitDestroyed", RaidCore)
    elseif _bDetectAllEnable == true and bEnable == false then
        RemoveEventHandler("UnitCreated", RaidCore)
        RemoveEventHandler("UnitDestroyed", RaidCore)
    end
    _bDetectAllEnable = bEnable
end

local function FullActivate(bEnable)
    if _bRunning == false and bEnable == true then
        Log:SetRefTime(GetGameTime())
        RegisterEventHandler("ChatMessage", "CI_OnChatMessage", RaidCore)
        RegisterEventHandler("ShowActionBarShortcut", "CI_ShowShortcutBar", RaidCore)
        _tScanTimer:Start()
    elseif _bRunning == true and bEnable == false then
        _tScanTimer:Stop()
        RemoveEventHandler("ChatMessage", RaidCore)
        RemoveEventHandler("ShowActionBarShortcut", RaidCore)
        Log:NextBuffer()
        -- Clear private data.
        _tTrackedUnits = {}
        _tAllUnits = {}
        _tMembers = {}
    end
    _bRunning = bEnable
end

local function RemoveAllExtraActivation()
    for sEvent, v in next, _CI_Extra do
        RemoveEventHandler(sEvent, RaidCore)
        _CI_Extra[sEvent] = nil
    end
end

local function InterfaceSwitch(to)
    RemoveAllExtraActivation()
    if to == INTERFACE__DISABLE then
        UnitInCombatActivate(false)
        UnitScanActivate(false)
        FullActivate(false)
    elseif to == INTERFACE__DETECTCOMBAT then
        UnitInCombatActivate(true)
        UnitScanActivate(false)
        FullActivate(false)
    elseif to == INTERFACE__DETECTALL then
        UnitInCombatActivate(true)
        UnitScanActivate(true)
        FullActivate(false)
    elseif to == INTERFACE__LIGHTENABLE then
        UnitInCombatActivate(true)
        UnitScanActivate(false)
        FullActivate(true)
    elseif to == INTERFACE__FULLENABLE then
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
    Log:Add("JoinChannelStatus", "Join Success")
    _CommChannelTimer:Stop()
    _RaidCoreChannelComm:SetReceivedMessageFunction("CI_OnReceivedMessage", RaidCore)
    _RaidCoreChannelComm:SetSendMessageResultFunction("CI_OnSendMessageResult", RaidCore)
end

function RaidCore:CI_JoinChannelTry()
    local eChannelType = ICCommLib.CodeEnumICCommChannelType.Group
    local sChannelName = "RaidCore"

    -- Log this try.
    Log:Add("JoinChannelTry", sChannelName, "Group")
    -- Request to join the channel.
    _RaidCoreChannelComm = ICCommLib.JoinChannel(sChannelName, eChannelType)
    -- Start a timer to retry to join.
    _CommChannelTimer = ApolloTimer.Create(_nCommChannelRetry, false, "CI_JoinChannelTry", RaidCore)
    _nCommChannelRetry = _nCommChannelRetry < 30 and _nCommChannelRetry + 5 or 30

    if _RaidCoreChannelComm then
        if _RaidCoreChannelComm:IsReady() then
            JoinSuccess()
        else
            Log:Add("JoinChannelStatus", "In Progress")
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
                Log:Add("JoinChannelStatus", sJoinResult)
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
    _tMembers = {}
    _tScanTimer = ApolloTimer.Create(SCAN_PERIOD, true, "CI_OnScanUpdate", self)
    _tScanTimer:Stop()

    -- Permanent registering.
    RegisterEventHandler("ChangeWorld", "CI_OnChangeWorld", self)
    RegisterEventHandler("SubZoneChanged", "CI_OnSubZoneChanged", self)

    InterfaceSwitch(INTERFACE__DISABLE)
    self.wndBarItem = Apollo.LoadForm(self.xmlDoc, "ActionBarShortcutItem", "FixedHudStratum", self)
    self.ActionBarShortcutBtn = self.wndBarItem:FindChild("ActionBarShortcutBtn")
end

function RaidCore:CombatInterface_Activate(sState)
    local nState = INTERFACE_STATES[sState]
    if nState then
        InterfaceSwitch(nState)
    end
end

function RaidCore:CombatInterface_ExtraActivate(sEvent, bNewState)
    assert(type(sEvent) == "string")
    if _CI_State == INTERFACE__LIGHTENABLE or _CI_State == INTERFACE__FULLENABLE then
        if EXTRA_HANDLER_ALLOWED[sEvent] then
            if not _CI_Extra[sEvent] and bNewState then
                _CI_Extra[sEvent] = true
                RegisterEventHandler(sEvent, EXTRA_HANDLER_ALLOWED[sEvent], RaidCore)
            elseif _CI_Extra[sEvent] and not bNewState then
                RemoveEventHandler(sEvent, RaidCore)
                _CI_Extra[sEvent] = nil
            end
        else
            Log:Add("ERROR", ("Extra event '%s' is not supported"):format(sEvent))
        end

    end
end

function RaidCore:CombatInterface_Untrack(nId)
    UnTrackThisUnit(nId)
end

function RaidCore:CombatInterface_Track(nId)
    TrackThisUnit(nId)
    return _tTrackedUnits[nId]
end

function RaidCore:CombatInterface_GetTrackedById(nId)
    return _tTrackedUnits[nId]
end

function RaidCore:CombatInterface_SendMessage(sMessage, tDPlayerId)
    assert(type(sMessage) == "string")
    assert(type(tDPlayerId) == "number" or tDPlayerId == nil)

    if not _RaidCoreChannelComm then
        Log:Add("ChannelCommStatus", "Channel not found")
    elseif tDPlayerId == nil then
        -- Broadcast the message on RaidCore Channel (type: Group).
        _RaidCoreChannelComm:SendMessage(sMessage)
        Log:Add("SendMessage", sMessage, tDPlayerId)
    else
        -- Send the message to this player.
        local tPlayerUnit = GetUnitById(tDPlayerId)
        if not tPlayerUnit then
            Log:Add("ChannelCommStatus", "Send aborded by Unknown ID")
        elseif not tPlayerUnit:IsInYourGroup() then
            Log:Add("ChannelCommStatus", "Send aborded by invalid PlayerUnit")
        else
            _RaidCoreChannelComm:SendPrivateMessage(tPlayerUnit:GetName(), sMessage)
            Log:Add("SendMessage", sMessage, tDPlayerId)
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Combat Interface layer.
----------------------------------------------------------------------------------------------------
function RaidCore:CI_OnEnteredCombat(tUnit, bInCombat)
    local tOwner = tUnit.GetUnitOwner and tUnit:GetUnitOwner()
    local tPlayerUnit = GetPlayerUnit()
    local bIsPetPlayer = tOwner and (tOwner:IsInYourGroup() or tOwner == tPlayerUnit)
    if not bIsPetPlayer then
        local nId = tUnit:GetId()
        local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")
        if not tUnit:IsInYourGroup() and tUnit ~= tPlayerUnit then
            if not _tAllUnits[nId] then
                ManagerCall("OnUnitCreated", nId, tUnit, sName)
            end
            _tAllUnits[nId] = true
        end
        ManagerCall("OnEnteredCombat", nId, tUnit, sName, bInCombat)
    end
end

function RaidCore:CI_OnUnitCreated(tUnit)
    local nId = tUnit:GetId()
    local tPlayerUnit = GetPlayerUnit()
    if not tUnit:IsInYourGroup() and tUnit ~= tPlayerUnit then
        local sName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        local tOwner = tUnit.GetUnitOwner and tUnit:GetUnitOwner()
        local bIsPetPlayer = tOwner and (tOwner:IsInYourGroup() or tOwner == tPlayerUnit)
        if not bIsPetPlayer and not _tAllUnits[nId] then
            _tAllUnits[nId] = true
            ManagerCall("OnUnitCreated", nId, tUnit, sName)
        end
    end
end

function RaidCore:CI_OnUnitDestroyed(tUnit)
    local nId = tUnit:GetId()
    if _tAllUnits[nId] then
        _tAllUnits[nId] = nil
        UnTrackThisUnit(nId)
        local sName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        ManagerCall("OnUnitDestroyed", nId, tUnit, sName)
    end
end

function RaidCore:CI_OnScanUpdate()
    UpdateMemberList()
    for sName,tMember in next, _tMembers do
        if tMember.tUnit:IsValid() then
            local f, err = pcall(ProcessAllBuffs, tMember)
            if not f then
                Print(err)
            end
        end
    end

    for nId, data in next, _tTrackedUnits do
        if data.tUnit:IsValid() then
            -- Process buff tracking.
            local f, err = pcall(ProcessAllBuffs, data)
            if not f then
                Print(err)
            end

            -- Process name update.
            data.sName = data.tUnit:GetName():gsub(NO_BREAK_SPACE, " ")

            -- Process cast tracking.
            local bCasting = data.tUnit:IsCasting()
            local nCurrentTime
            local sCastName
            local nCastDuration
            local nCastElapsed
            local nCastEndTime
            if bCasting then
                nCurrentTime = GetGameTime()
                sCastName = data.tUnit:GetCastName()
                nCastDuration = data.tUnit:GetCastDuration()
                nCastElapsed = data.tUnit:GetCastElapsed()
                nCastEndTime = nCurrentTime + (nCastDuration - nCastElapsed) / 1000
                -- Refresh needed if the function is called at the end of cast.
                -- Like that, previous data retrieved are valid.
                bCasting = data.tUnit:IsCasting()
            end
            if bCasting then
                sCastName = string.gsub(sCastName, NO_BREAK_SPACE, " ")
                if not data.tCast.bCasting then
                    -- New cast
                    data.tCast = {
                        bCasting = true,
                        sCastName = sCastName,
                        nCastEndTime = nCastEndTime,
                        bSuccess = false,
                    }
                    ManagerCall("OnCastStart", nId, sCastName, nCastEndTime, data.sName)
                elseif data.tCast.bCasting then
                    if sCastName ~= data.tCast.sCastName then
                        -- New cast just after a previous one.
                        if data.tCast.bSuccess == false then
                            ManagerCall("OnCastEnd", nId, data.tCast.sCastName, false, data.tCast.nCastEndTime, data.sName)
                        end
                        data.tCast = {
                            bCasting = true,
                            sCastName = sCastName,
                            nCastEndTime = nCastEndTime,
                            bSuccess = false,
                        }
                        ManagerCall("OnCastStart", nId, sCastName, nCastEndTime, data.sName)
                    elseif not data.tCast.bSuccess and nCastElapsed >= nCastDuration then
                        -- The have reached the end.
                        ManagerCall("OnCastEnd", nId, data.tCast.sCastName, false, data.tCast.nCastEndTime, data.sName)
                        data.tCast = {
                            bCasting = true,
                            sCastName = sCastName,
                            nCastEndTime = 0,
                            bSuccess = true,
                        }
                    end
                end
            elseif data.tCast.bCasting then
                if not data.tCast.bSuccess then
                    -- Let's compare with the nCastEndTime
                    local nThreshold = GetGameTime() + SCAN_PERIOD
                    local bIsFailed
                    if nThreshold < data.tCast.nCastEndTime then
                        bIsInterrupted = true
                    else
                        bIsInterrupted = false
                    end
                    ManagerCall("OnCastEnd", nId, data.tCast.sCastName, bIsInterrupted, data.tCast.nCastEndTime, data.sName)
                end
                data.tCast = {
                    bCasting = false,
                    sCastName = "",
                    nCastEndTime = 0,
                    bSuccess = false,
                }
            end

            -- Process Health tracking.
            local MaxHealth = data.tUnit:GetMaxHealth()
            local Health = data.tUnit:GetHealth()
            if Health and MaxHealth then
                local nPourcent = math.floor(100 * Health / MaxHealth)
                if data.nPreviousHealthPourcent ~= nPourcent then
                    data.nPreviousHealthPourcent = nPourcent
                    ManagerCall("OnHealthChanged", nId, nPourcent, data.sName)
                end
            end

        end
    end
end

function RaidCore:CI_OnChatMessage(tChannelCurrent, tMessage)
    local nChannelType = tChannelCurrent:GetType()
    local sHandler = CHANNEL_HANDLERS[nChannelType]
    if sHandler then
        local sSender = tMessage.strSender or ""
        sSender:gsub(NO_BREAK_SPACE, " ")
        local sMessage = ""
        for _, tSegment in next, tMessage.arMessageSegments do
            sMessage = sMessage .. tSegment.strText:gsub(NO_BREAK_SPACE, " ")
        end
        ManagerCall(sHandler, sMessage, sSender)
    end
end

function RaidCore:CI_OnReceivedMessage(sChannel, sMessage, sSender)
    local tSender = sSender and GetPlayerUnitByName(sSender)
    local nSenderId = tSender and tSender:GetId()
    ManagerCall("OnReceivedMessage", sMessage, nSenderId)
end

function RaidCore:CI_OnSendMessageResult(iccomm, eResult, nMessageId)
    local sResult = tostring(eResult)
    for stext, key in next, ICCommLib.CodeEnumICCommMessageResult do
        if eResult == key then
            sResult = stext
            break
        end
    end
    Log:Add("SendMessageResult", sResult, nMessageId)
end

function RaidCore:CI_ShowShortcutBar(eWhichBar, bIsVisible, nNumShortcuts)
    if eWhichBar == ActionSetLib.CodeEnumShortcutSet.FloatingSpellBar then
        -- The GetContent function is not ready... A delay must be added.
        _nNumShortcuts = nNumShortcuts
        _DelayShowShortcutBar = ApolloTimer.Create(1, false, "CI_ShowShortcutBarDelayed", RaidCore)
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
    ManagerCall("OnShowShortcutBar", tIconFloatingSpellBar)
end

function RaidCore:CI_OnCombatLogHeal(tArgs)
    local nCasterId = tArgs.unitCaster and tArgs.unitCaster:GetId()
    local nTargetId = tArgs.unitTarget and tArgs.unitTarget:GetId()
    local sCasterName = tArgs.unitCaster and tArgs.unitCaster:GetName():gsub(NO_BREAK_SPACE, " ") or ""
    local sTargetName = tArgs.unitTarget and tArgs.unitTarget:GetName():gsub(NO_BREAK_SPACE, " ") or ""
    local nHealAmount = tArgs.nHealAmount or 0
    local nOverHeal = tArgs.nOverHeal or 0
    local nSpellId = tArgs.splCallingSpell and tArgs.splCallingSpell:GetId()
    ManagerCall("OnCombatLogHeal", nCasterId, nTargetId, sCasterName, sTargetName, nHealAmount, nOverHeal, nSpellId)
end

function RaidCore:CI_OnChangeWorld()
    ManagerCall("OnChangeWorld")
end

function RaidCore:CI_OnSubZoneChanged(nZoneId, sZoneName)
    ManagerCall("OnSubZoneChanged", nZoneId, sZoneName)
end
