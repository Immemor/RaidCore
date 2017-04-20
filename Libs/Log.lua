----------------------------------------------------------------------------------------------------
-- Lua Library Script for WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--  Description:
--    This library build a complete trace of the system.
--  On each call of Add function, this last can record an unlimited number of parameters. Every
--  entry is saved inside an array with the current time. And this array can be partially or
--  totally dump later.
--
--  By default, there is 2 buffers, one which record current events. A second, which have been
--  filled previously.
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"
local table = require "table"

local MAJOR, MINOR = "Log-1.0", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then
    return -- no upgrade is needed
end
local Lib = APkg and APkg.tPackage or {}

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the CPU load.
-- Because all local objects are faster in LUA.
----------------------------------------------------------------------------------------------------
local next = next
local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local NB_BUFFERS = 2
-- Description of an entry log.
local LOG_ENTRY__TIME = 1
local LOG_ENTRY__TEXT = 2
local LOG_ENTRY__EXTRAINFO = 3
local LOG_ENTRIES = {
    ["TIME"] = LOG_ENTRY__TIME,
    ["TEXT"] = LOG_ENTRY__TEXT,
    ["EXTRAINFO"] = LOG_ENTRY__EXTRAINFO,
}

----------------------------------------------------------------------------------------------------
-- Private variables.
----------------------------------------------------------------------------------------------------
local _tAllLog = {}
local _nBufferIdx = 1
local _tRefTime = {}
local _tBuffers = {}

----------------------------------------------------------------------------------------------------
-- Privates functions
----------------------------------------------------------------------------------------------------
local function LogGetLastBufferIndex()
    if NB_BUFFERS > 0 then
        local prev = _nBufferIdx - 1
        if prev == 0 then
            return NB_BUFFERS
        else
            return prev
        end
    end
    return 0
end

local function ResetBuffer(nIndex)
    _tBuffers[nIndex] = {}
end

----------------------------------------------------------------------------------------------------
-- Library itself.
----------------------------------------------------------------------------------------------------
function Lib:Add(sText, ...)
    if NB_BUFFERS > 0 then
        local tBuffer = _tBuffers[_nBufferIdx]
        local tExtraInfo = { ... }
        -- Add an entry in current buffer.
        table.insert(tBuffer, {
            [LOG_ENTRY__TIME] = GetGameTime(),
            [LOG_ENTRY__TEXT] = sText,
            [LOG_ENTRY__EXTRAINFO] = tExtraInfo,
        })
    end
end

function Lib:SetExtra2String(fCallback)
    assert(type(fCallback) == "function")
    self.fExtra2String = fCallback
end

function Lib:CurrentDump()
    local fExtra2String = self.fExtra2String
    local tBuffer = _tBuffers[_nBufferIdx]
    local tDump = {}
    local nRefTime = _tRefTime[_nBufferIdx]

    if tBuffer and fExtra2String then
        for _, tEntry in next, tBuffer do
            local o = {
                tEntry[LOG_ENTRY__TIME] - nRefTime,
                tEntry[LOG_ENTRY__TEXT],
                fExtra2String(tEntry[LOG_ENTRY__TEXT], nRefTime, tEntry[LOG_ENTRY__EXTRAINFO]),
            }
            table.insert(tDump, o)
        end
    end
    return tDump
end

function Lib:PreviousDump()
    local fExtra2String = self.fExtra2String
    local nBufferIdx = LogGetLastBufferIndex()
    local tBuffer = _tBuffers[nBufferIdx]
    local tDump = {}
    local nRefTime = _tRefTime[nBufferIdx]

    if tBuffer and fExtra2String then
        for _, tEntry in next, tBuffer do
            local o = {
                tEntry[LOG_ENTRY__TIME] - nRefTime,
                tEntry[LOG_ENTRY__TEXT],
                fExtra2String(tEntry[LOG_ENTRY__TEXT], nRefTime, tEntry[LOG_ENTRY__EXTRAINFO]),
            }
            table.insert(tDump, o)
        end
    end
    return tDump
end

function Lib:NextBuffer()
    if NB_BUFFERS > 0 then
        -- Increase current index.
        _nBufferIdx = _nBufferIdx + 1
        -- Variable must be between 1 to MAX.
        if _nBufferIdx > NB_BUFFERS then
            _nBufferIdx = 1
        end
        -- Reset buffers pointed by current index.
        ResetBuffer(_nBufferIdx)
    end
end

function Lib:SetRefTime(nTime)
    if NB_BUFFERS > 0 then
        _tRefTime[_nBufferIdx] = nTime
    end
end

function Lib:OnLoad()
    for i = 1, NB_BUFFERS do
        _tRefTime[i] = 0
        ResetBuffer(i)
    end
end

function Lib:OnDependencyError(strDep, strError)
    return false
end

Apollo.RegisterPackage(Lib, MAJOR, MINOR, {})
