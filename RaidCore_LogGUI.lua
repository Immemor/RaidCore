------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Description:
--   File related to the Log windows. And the exportation to clipboard too.
------------------------------------------------------------------------------

require "Apollo"

local GeminiAddon = Apollo.GetPackage("Gemini:Addon-1.1").tPackage
local LogPackage = Apollo.GetPackage("Log-1.0").tPackage
local RaidCore = GeminiAddon:GetAddon("RaidCore")
local LogGUI = {}

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local COPY_TO_CLIPBOARD = GameLib.CodeEnumConfirmButtonType.CopyToClipboard
local COPY_SIZE = 200000 -- 200Ko max per action

------------------------------------------------------------------------------
-- Privates data.
------------------------------------------------------------------------------
local _sJSONData
local _nJSONCopied
local _nJSONLen
-- Windows objects.
local _wndRCLog
local _wndCopyProgress
local _wndUploadAction

local function CopyLog2Clipboard()
    local nEnd = _nJSONCopied + COPY_SIZE
    if nEnd > _nJSONLen then
        nEnd = _nJSONLen
    end
    local string = _sJSONData:sub(_nJSONCopied + 1, nEnd)
    _nJSONCopied = nEnd
    _wndUploadAction:SetActionData(COPY_TO_CLIPBOARD, string)
end

local function StartLog2Clipboard(tDumpLog)
    local JSONPackage = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
    _sJSONData = JSONPackage.encode(tDumpLog)
    _nJSONLen = _sJSONData:len()
    _nJSONCopied = 0
    _wndCopyProgress:SetProgress(0)
    _wndCopyProgress:SetMax(_nJSONLen)
    if _sJSONData and _nJSONLen > 0 then
        CopyLog2Clipboard()
    end
end

------------------------------------------------------------------------------
-- Logs Functions
------------------------------------------------------------------------------
function LogGUI:OnLogSlashCommand()
    _wndRCLog:Show(true)
end

function LogGUI:RCLogClose(wndHandler, wndControl, eMouseButton)
    _wndRCLog:Show(false)
end

function LogGUI:RCLogGet(wndHandler, wndControl, eMouseButton)
    local wndGrid = _wndRCLog:FindChild("Grid")
    local Log = LogPackage:GetNamespace("CombatInterface")
    assert(Log)
    local tDumpLog = Log:Dump()

    if wndGrid then
        -- Clear current Grid data.
        wndGrid:DeleteAll()
    end
    if tDumpLog and next(tDumpLog) then
        if wndGrid then
            -- Set grid data.
            for _, tLog in next, tDumpLog do
                local idx = wndGrid:AddRow("")
                wndGrid:SetCellSortText(idx, 1, ("%08u"):format(idx))
                wndGrid:SetCellText(idx, 1, ("%.3f"):format(tLog[1]))
                wndGrid:SetCellText(idx, 2, tLog[2])
                wndGrid:SetCellText(idx, 3, tLog[3])
            end
        end
        _wndUploadAction:Show(true)
        StartLog2Clipboard(tDumpLog)
    else
        _wndUploadAction:Show(false)
    end
end

function LogGUI:OnStringCopiedToClipboard(wndHandler, wndControl)
    _wndCopyProgress:SetProgress(_nJSONCopied)
    if _nJSONCopied < _nJSONLen then
        CopyLog2Clipboard()
    else
        _wndUploadAction:Show(false)
    end
end

function LogGUI:OnWindowManagementReady()
    local param = {wnd = _wndRCLog, strName = "RaidCore_Logs"}
    Event_FireGenericEvent('WindowManagementAdd', param)
end

------------------------------------------------------------------------------
-- Relation between LogGUI and RaidCore.
------------------------------------------------------------------------------
function RaidCore:LogGUI_init()
    _wndRCLog = Apollo.LoadForm(self.xmlDoc, "Logs", nil, LogGUI)
    local wndFooter = _wndRCLog:FindChild("Footer")
    local wndClipboard = wndFooter:FindChild("Clipboard")
    _wndUploadAction = wndFooter:FindChild("UploadAction")
    _wndCopyProgress = wndClipboard:FindChild("CopyProgress")
    Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", LogGUI)
    Apollo.RegisterSlashCommand("rclog", "OnLogSlashCommand", LogGUI)
end
