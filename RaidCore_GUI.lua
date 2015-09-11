----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--  Description:
--
--  TODO
--
----------------------------------------------------------------------------------------------------
require "Window"
require "GameLib"

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Log = Apollo.GetPackage("Log-1.0").tPackage
local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local next, pcall, assert, error, ipairs = next, pcall, assert, error, ipairs
local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------
local ShowHideClass = {}
local _wndUploadAction
local _wndLogGrid
local _TestTimer = nil

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local COPY_TO_CLIPBOARD = GameLib.CodeEnumConfirmButtonType.CopyToClipboard
local SHOW_HIDE_PANEL_ENCOUNTER_DURATION = 0.60
local SHOW_HIDE_PANEL_ENCOUNTER_MOVE = 155
local SHOW_HIDE_PANEL_LOG_MOVE = 120
local SHOW_HIDE_PANEL_GENERAL_MOVE = 120

----------------------------------------------------------------------------------------------------
-- local functions.
----------------------------------------------------------------------------------------------------
local function OnMenuLeft_CheckUncheck(wndButton, bIsChecked)
    local sButtonName = wndButton:GetName()
    local wnd = bIsChecked and RaidCore.LeftMenu2wndBody[sButtonName] or RaidCore.wndBodyTarget:GetData()
    if wnd then
        wnd:Show(bIsChecked)
        wnd = bIsChecked and wnd
    end
    RaidCore.wndBodyTarget:SetData(wnd)
end

local function CopyLog2Clipboard(tDumpLog)
    local JSONPackage = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
    local sJSONData = JSONPackage.encode(tDumpLog)
    if sJSONData then
        local JSONLen = sJSONData:len()
        if JSONLen < 1000 then
            _wndLogSize:SetText(("(%u B)"):format(JSONLen))
        elseif JSONLen < (1000 * 1000) then
            _wndLogSize:SetText(("(%.1f kB)"):format(JSONLen / 1000.0))
        else
            _wndLogSize:SetText(("(%.1f MB)"):format(JSONLen / (1000.0 * 1000.0)))
        end
        if JSONLen > 0 then
            _wndUploadAction:SetActionData(COPY_TO_CLIPBOARD, sJSONData)
            _wndUploadAction:Show(true)
        end
    end
end

local function ClearLogGrid()
    -- Clear current Grid data.
    _wndLogGrid:DeleteAll()
    _wndLogErrorCount:SetText("0")
    _wndLogEventsCount:SetText("0")
    _wndLogSize:SetText("")
    _wndUploadAction:Show(false)
end

local function FillLogGrid(tDumpLog)
    local nErrorCount = 0
    for _, tLog in ipairs(tDumpLog) do
        local idx = _wndLogGrid:AddRow("")
        _wndLogGrid:SetCellSortText(idx, 1, ("%08u"):format(idx))
        _wndLogGrid:SetCellText(idx, 1, ("%.3f"):format(tLog[1]))
        _wndLogGrid:SetCellText(idx, 2, tLog[2])
        _wndLogGrid:SetCellText(idx, 3, tLog[3])
        -- Increase error counter on error logged.
        if tLog[2] == "ERROR" then
            nErrorCount = nErrorCount + 1
        end
    end
    _wndLogErrorCount:SetText(tostring(nErrorCount))
    _wndLogEventsCount:SetText(tostring(#tDumpLog))
end

local function Split(str, sep)
    assert(str)
    sep = sep or "%s"
    local r = {}
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(r, str)
    end
    return r
end

----------------------------------------------------------------------------------------------------
-- ShowHide Class manager.
----------------------------------------------------------------------------------------------------
function ShowHideClass:OnShowHideUpdate()
    local left, top, right, bottom
    local nCurrentTime = GetGameTime()
    local nEncounterDelta = RaidCore.nShowHideEncounterPanelTime - nCurrentTime
    local nLogDelta = RaidCore.nShowHideLogPanelTime - nCurrentTime
    local nSettingsDelta = RaidCore.nShowHideSettingsPanelTime - nCurrentTime

    nEncounterDelta = nEncounterDelta > 0 and nEncounterDelta or 0
    nLogDelta = nLogDelta > 0 and nLogDelta or 0
    nSettingsDelta = nSettingsDelta > 0 and nSettingsDelta or 0

    -- Manage ENCOUNTER panels.
    local nPourcentAction = 1 - nEncounterDelta / SHOW_HIDE_PANEL_ENCOUNTER_DURATION
    -- Manage the encounter panel list.
    if RaidCore.bIsEncounterPanelsToShow then
        left = RaidCore.tEncounterListAnchorOffsets[1] - SHOW_HIDE_PANEL_ENCOUNTER_MOVE * nPourcentAction
        left = left > -SHOW_HIDE_PANEL_ENCOUNTER_MOVE and left or -SHOW_HIDE_PANEL_ENCOUNTER_MOVE
        right = RaidCore.tEncounterListAnchorOffsets[3] - SHOW_HIDE_PANEL_ENCOUNTER_MOVE * nPourcentAction
        right = right > (200 - SHOW_HIDE_PANEL_ENCOUNTER_MOVE) and right or (200 - SHOW_HIDE_PANEL_ENCOUNTER_MOVE)
    else
        left = RaidCore.tEncounterListAnchorOffsets[1] + SHOW_HIDE_PANEL_ENCOUNTER_MOVE * nPourcentAction
        left = left < 0 and left or 0
        right = RaidCore.tEncounterListAnchorOffsets[3] + SHOW_HIDE_PANEL_ENCOUNTER_MOVE * nPourcentAction
        right = right < 200 and right or 200
    end
    RaidCore.wndEncounterList:SetAnchorOffsets(left, RaidCore.tEncounterListAnchorOffsets[2], right, RaidCore.tEncounterListAnchorOffsets[4])
    -- Manage the encounter panel target.
    if RaidCore.bIsEncounterPanelsToShow then
        left = RaidCore.tEncounterTargetAnchorOffsets[1] - SHOW_HIDE_PANEL_ENCOUNTER_MOVE * nPourcentAction
        left = left > (205 - SHOW_HIDE_PANEL_ENCOUNTER_MOVE) and left or (205 - SHOW_HIDE_PANEL_ENCOUNTER_MOVE)
    else
        left = RaidCore.tEncounterTargetAnchorOffsets[1] + SHOW_HIDE_PANEL_ENCOUNTER_MOVE * nPourcentAction
        left = left < 205 and left or 205
    end
    RaidCore.wndEncounterTarget:SetAnchorOffsets(left, RaidCore.tEncounterTargetAnchorOffsets[2], RaidCore.tEncounterTargetAnchorOffsets[3], RaidCore.tEncounterTargetAnchorOffsets[4])

    -- Manage LOGS panels.
    local nLogPourcentAction = 1 - nLogDelta / SHOW_HIDE_PANEL_ENCOUNTER_DURATION
    -- Manage the log panel list.
    if RaidCore.bIsLogsPanelsToShow then
        left = RaidCore.tLogsListAnchorOffsets[1] - SHOW_HIDE_PANEL_LOG_MOVE * nLogPourcentAction
        left = left > -SHOW_HIDE_PANEL_LOG_MOVE and left or -SHOW_HIDE_PANEL_LOG_MOVE
        right = RaidCore.tLogsListAnchorOffsets[3] - SHOW_HIDE_PANEL_LOG_MOVE * nLogPourcentAction
        right = right > (150 - SHOW_HIDE_PANEL_LOG_MOVE) and right or (150 - SHOW_HIDE_PANEL_LOG_MOVE)
    else
        left = RaidCore.tLogsListAnchorOffsets[1] + SHOW_HIDE_PANEL_LOG_MOVE * nLogPourcentAction
        left = left < 0 and left or 0
        right = RaidCore.tLogsListAnchorOffsets[3] + SHOW_HIDE_PANEL_LOG_MOVE * nLogPourcentAction
        right = right < 150 and right or 150
    end
    RaidCore.wndLogSubMenu:SetAnchorOffsets(left, RaidCore.tLogsListAnchorOffsets[2], right, RaidCore.tLogsListAnchorOffsets[4])
    -- Manage the log panel target.
    if RaidCore.bIsLogsPanelsToShow then
        left = RaidCore.tLogsTargetAnchorOffsets[1] - SHOW_HIDE_PANEL_LOG_MOVE * nLogPourcentAction
        left = left > (155 - SHOW_HIDE_PANEL_LOG_MOVE) and left or (155 - SHOW_HIDE_PANEL_LOG_MOVE)
    else
        left = RaidCore.tLogsTargetAnchorOffsets[1] + SHOW_HIDE_PANEL_LOG_MOVE * nLogPourcentAction
        left = left < 155 and left or 155
    end
    RaidCore.wndLogTarget:SetAnchorOffsets(left, RaidCore.tLogsTargetAnchorOffsets[2], RaidCore.tLogsTargetAnchorOffsets[3], RaidCore.tLogsTargetAnchorOffsets[4])

    -- Manage SETTINGS panels.
    local nSettingsPourcentAction = 1 - nSettingsDelta / SHOW_HIDE_PANEL_ENCOUNTER_DURATION
    -- Manage the settings sub menu.
    if RaidCore.bIsSettingsPanelsToShow then
        left = RaidCore.tSettingsListAnchorOffsets[1] - SHOW_HIDE_PANEL_GENERAL_MOVE * nSettingsPourcentAction
        left = left > -SHOW_HIDE_PANEL_GENERAL_MOVE and left or -SHOW_HIDE_PANEL_GENERAL_MOVE
        right = RaidCore.tSettingsListAnchorOffsets[3] - SHOW_HIDE_PANEL_GENERAL_MOVE * nSettingsPourcentAction
        right = right > (150 - SHOW_HIDE_PANEL_GENERAL_MOVE) and right or (150 - SHOW_HIDE_PANEL_GENERAL_MOVE)
    else
        left = RaidCore.tSettingsListAnchorOffsets[1] + SHOW_HIDE_PANEL_GENERAL_MOVE * nSettingsPourcentAction
        left = left < 0 and left or 0
        right = RaidCore.tSettingsListAnchorOffsets[3] + SHOW_HIDE_PANEL_GENERAL_MOVE * nSettingsPourcentAction
        right = right < 150 and right or 150
    end
    RaidCore.wndSettingsSubMenu:SetAnchorOffsets(left, RaidCore.tSettingsListAnchorOffsets[2], right, RaidCore.tSettingsListAnchorOffsets[4])
    -- Manage the settings panel target.
    if RaidCore.bIsSettingsPanelsToShow then
        left = RaidCore.tSettingsTargetAnchorOffsets[1] - SHOW_HIDE_PANEL_GENERAL_MOVE * nSettingsPourcentAction
        left = left > (155 - SHOW_HIDE_PANEL_GENERAL_MOVE) and left or (155 - SHOW_HIDE_PANEL_GENERAL_MOVE)
    else
        left = RaidCore.tSettingsTargetAnchorOffsets[1] + SHOW_HIDE_PANEL_GENERAL_MOVE * nSettingsPourcentAction
        left = left < 155 and left or 155
    end
    RaidCore.wndSettingsTarget:SetAnchorOffsets(left, RaidCore.tSettingsTargetAnchorOffsets[2], RaidCore.tSettingsTargetAnchorOffsets[3], RaidCore.tSettingsTargetAnchorOffsets[4])

    if nEncounterDelta == 0 and nLogDelta == 0 and nSettingsDelta == 0 then
        _bShowHidePanelActive = false
        Apollo.RemoveEventHandler("NextFrame", self)
    end
end


function ShowHideClass:StartUpdate()
    if not _bShowHidePanelActive then
        _bShowHidePanelActive = true
        Apollo.RegisterEventHandler("NextFrame", "OnShowHideUpdate", self)
    end
end


----------------------------------------------------------------------------------------------------
-- Public functions.
----------------------------------------------------------------------------------------------------
function RaidCore:GUI_init(sVersion)
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ConfigMain", nil, self)
    self.wndMain:FindChild("Tag"):SetText(sVersion)
    self.wndMain:SetSizingMinimum(950, 500)
    self.wndBodyTarget = self.wndMain:FindChild("BodyTarget")
    self.LeftMenu2wndBody = {
        General = Apollo.LoadForm(self.xmlDoc, "ConfigBody_Settings", self.wndBodyTarget, self),
        Encounters = Apollo.LoadForm(self.xmlDoc, "ConfigBody_Encounters", self.wndBodyTarget, self),
        Logs = Apollo.LoadForm(self.xmlDoc, "ConfigBody_Logs", self.wndBodyTarget, self),
        About_Us = Apollo.LoadForm(self.xmlDoc, "ConfigBody_AboutUs", self.wndBodyTarget, self),
    }
    for _, wnd in next, self.LeftMenu2wndBody do
        GeminiLocale:TranslateWindow(self.L, wnd)
    end
    self.wndEncounterTarget = self.LeftMenu2wndBody.Encounters:FindChild("Encounter_Target")
    self.wndEncounterList = self.LeftMenu2wndBody.Encounters:FindChild("Encounter_List")
    self.tEncounterListAnchorOffsets = { self.wndEncounterList:GetAnchorOffsets() }
    self.tEncounterTargetAnchorOffsets = { self.wndEncounterTarget:GetAnchorOffsets() }
    self.wndLogTarget = self.LeftMenu2wndBody.Logs:FindChild("Log_Target")
    self.wndLogSubMenu = self.LeftMenu2wndBody.Logs:FindChild("Log_SubMenu")
    self.tLogsListAnchorOffsets = { self.wndLogSubMenu:GetAnchorOffsets() }
    self.tLogsTargetAnchorOffsets = { self.wndLogTarget:GetAnchorOffsets() }
    self.wndSettingsSubMenu = self.LeftMenu2wndBody.General:FindChild("SettingsSubMenu")
    self.wndSettingsTarget = self.LeftMenu2wndBody.General:FindChild("SettingsTarget")
    self.tSettingsListAnchorOffsets = { self.wndSettingsSubMenu:GetAnchorOffsets() }
    self.tSettingsTargetAnchorOffsets = { self.wndSettingsTarget:GetAnchorOffsets() }
    self.wndEncounters = {
        PrimeEvolutionaryOperant = Apollo.LoadForm(self.xmlDoc, "ConfigForm_CoreY83", self.wndEncounterTarget, self),
        ExperimentX89 = Apollo.LoadForm(self.xmlDoc, "ConfigForm_ExperimentX89", self.wndEncounterTarget, self),
        Kuralak = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Kuralak", self.wndEncounterTarget, self),
        Prototypes = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Prototypes", self.wndEncounterTarget, self),
        Phagemaw = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Phagemaw", self.wndEncounterTarget, self),
        PhageCouncil = Apollo.LoadForm(self.xmlDoc, "ConfigForm_PhageCouncil", self.wndEncounterTarget, self),
        Ohmna = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Ohmna", self.wndEncounterTarget, self),
        Minibosses = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Minibosses", self.wndEncounterTarget, self),
        SystemDaemons = Apollo.LoadForm(self.xmlDoc, "ConfigForm_SystemDaemons", self.wndEncounterTarget, self),
        Gloomclaw = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Gloomclaw", self.wndEncounterTarget, self),
        Maelstrom = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Maelstrom", self.wndEncounterTarget, self),
        Lattice = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Lattice", self.wndEncounterTarget, self),
        LimboInfomatrix = Apollo.LoadForm(self.xmlDoc, "ConfigForm_LimboInfomatrix", self.wndEncounterTarget, self),
        AirEarth = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpAirEarth", self.wndEncounterTarget, self),
        AirLife = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpAirLife", self.wndEncounterTarget, self),
        AirWater = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpAirWater", self.wndEncounterTarget, self),
        FireEarth = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpFireEarth", self.wndEncounterTarget, self),
        FireLife = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpFireLife", self.wndEncounterTarget, self),
        FireWater = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpFireWater", self.wndEncounterTarget, self),
        LogicEarth = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpLogicEarth", self.wndEncounterTarget, self),
        LogicLife = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpLogicLife", self.wndEncounterTarget, self),
        LogicWater = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpLogicWater", self.wndEncounterTarget, self),
        Avatus = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Avatus", self.wndEncounterTarget, self),
    }
    -- Initialize Left Menu in Main RaidCore window.
    local wndGeneralButton = self.wndMain:FindChild("Static"):FindChild("General")
    wndGeneralButton:SetCheck(true)
    OnMenuLeft_CheckUncheck(wndGeneralButton, true)
    -- Initialize the Show/Hide button in "encounter" body.
    self.LeftMenu2wndBody.Encounters:FindChild("ShowHidePanel"):SetCheck(true)
    self.nShowHideEncounterPanelTime = 0
    -- Initialize the Show/Hide button in "log" body.
    self.LeftMenu2wndBody.Logs:FindChild("ShowHidePanel"):SetCheck(true)
    self.nShowHideLogPanelTime = 0
    -- Initialize the Show/Hide button in "settings" body.
    self.LeftMenu2wndBody.General:FindChild("ShowHidePanel"):SetCheck(true)
    self.nShowHideSettingsPanelTime = 0
    self.wndSettingsSubMenu:FindChild("Bars"):SetCheck(true)
    self.wndSettingsTarget:SetData(self.wndSettingsTarget:FindChild("Bars"))
    -- Initialize the "log" windows.
    _wndUploadAction = self.LeftMenu2wndBody.Logs:FindChild("UploadAction")
    _wndLogGrid = self.wndLogTarget:FindChild("Log_Grid")
    _wndLogErrorCount = self.wndLogTarget:FindChild("ErrorsCount")
    _wndLogEventsCount = self.wndLogTarget:FindChild("EventsCount")
    _wndLogSize = self.wndLogTarget:FindChild("LogSize")

    -- Registering to Windows Manager.
    Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
end

function RaidCore:OnWindowManagementReady()
    local param = { wnd = self.wndMain, strName = "RaidCore" }
    Event_FireGenericEvent('WindowManagementAdd', param)
end

----------------------------------------------------------------------------------------------------
-- Public "form" functions.
----------------------------------------------------------------------------------------------------
function RaidCore:DisplayMainWindow()
    self.wndMain:Invoke()
end

function RaidCore:OnClose()
    self.wndMain:Close()
end

function RaidCore:OnMenuLeft_Check(wndHandler, wndControl, eMouseButton)
    OnMenuLeft_CheckUncheck(wndControl, true)
end

function RaidCore:OnMenuLeft_Uncheck(wndHandler, wndControl, eMouseButton)
    OnMenuLeft_CheckUncheck(wndControl, false)
end

function RaidCore:OnEncounterListShowHide(wndHandler, wndControl, eMouseButton)
    local bState = wndControl:IsChecked()
    self.tEncounterListAnchorOffsets = { self.wndEncounterList:GetAnchorOffsets() }
    self.tEncounterTargetAnchorOffsets = { self.wndEncounterTarget:GetAnchorOffsets() }
    self.bIsEncounterPanelsToShow = not bState
    self.nShowHideEncounterPanelTime = GetGameTime() + SHOW_HIDE_PANEL_ENCOUNTER_DURATION
    self:PlaySound("DoorFutur")
    ShowHideClass:StartUpdate()
end

function RaidCore:OnEncounterCheck(wndHandler, wndControl, eMouseButton)
    local wnd = self.wndEncounters[wndControl:GetName()]
    if wnd then
        wnd:Show(true)
    end
    self.wndEncounterTarget:SetData(wnd)
end

function RaidCore:OnEncounterUncheck(wndHandler, wndControl, eMouseButton)
    local wnd = self.wndEncounterTarget:GetData()
    if wnd then
        wnd:Show(false)
    end
    self.wndEncounterTarget:SetData(nil)
end

function RaidCore:OnLogListShowHide(wndHandler, wndControl, eMouseButton)
    self.tLogsListAnchorOffsets = { self.wndLogSubMenu:GetAnchorOffsets() }
    self.tLogsTargetAnchorOffsets = { self.wndLogTarget:GetAnchorOffsets() }
    self.bIsLogsPanelsToShow = not wndControl:IsChecked()
    self.nShowHideLogPanelTime = GetGameTime() + SHOW_HIDE_PANEL_ENCOUNTER_DURATION
    self:PlaySound("DoorFutur")
    ShowHideClass:StartUpdate()
end

function RaidCore:OnLogLoadCurrentBuffer(wndHandler, wndControl, eMouseButton)
    -- Clear current Grid data.
    ClearLogGrid()
    -- Retrieve current buffer.
    local tDumpLog = Log:CurrentDump()
    -- Update GUI
    if tDumpLog and next(tDumpLog) then
        FillLogGrid(tDumpLog)
        CopyLog2Clipboard(tDumpLog)
    end
end

function RaidCore:OnLogLoadPreviousBuffer(wndHandler, wndControl, eMouseButton)
    -- Clear current Grid data.
    ClearLogGrid()
    -- Retrieve previous buffer.
    local tDumpLog = Log:PreviousDump()
    -- Update GUI
    if tDumpLog and next(tDumpLog) then
        FillLogGrid(tDumpLog)
        CopyLog2Clipboard(tDumpLog)
    end
end

function RaidCore:OnSettingsListShowHide(wndHandler, wndControl, eMouseButton)
    self.tSettingsListAnchorOffsets = { self.wndSettingsSubMenu:GetAnchorOffsets() }
    self.tSettingsTargetAnchorOffsets = { self.wndSettingsTarget:GetAnchorOffsets() }
    self.bIsSettingsPanelsToShow = not wndControl:IsChecked()
    self.nShowHideSettingsPanelTime = GetGameTime() + SHOW_HIDE_PANEL_ENCOUNTER_DURATION
    self:PlaySound("DoorFutur")
    ShowHideClass:StartUpdate()
end

function RaidCore:OnSettingsCheck(wndHandler, wndControl, eMouseButton)
    local sTargetName = wndControl:GetName()
    local wndTarget = self.wndSettingsTarget:FindChild(sTargetName)
    if wndTarget then
        wndTarget:Show(true)
        self.wndSettingsTarget:SetData(wndTarget)
    end
end

function RaidCore:OnSettingsUncheck(wndHandler, wndControl, eMouseButton)
    local wndTarget = self.wndSettingsTarget:GetData()
    if wndTarget then
        wndTarget:Show(false)
    end
end

-- When the Test button is pushed.
function RaidCore:OnTestScenarioButton(wndHandler, wndControl, eMouseButton)
    local bIsChecked = wndControl:IsChecked()
    if bIsChecked then
        wndControl:SetText(self.L["Stop test scenario"])
        self:OnStartTestScenario()
        _TestTimer = self:ScheduleTimer(function(wndControl)
            wndControl:SetCheck(false)
            wndControl:SetText(self.L["Start test scenario"])
            self:OnStopTestScenario()
        end, 60, wndControl)
    else
        self:CancelTimer(_TestTimer, true)

        wndControl:SetText(self.L["Start test scenario"])
        self:OnStopTestScenario()
    end
end

-- When the Reset button is clicked.
function RaidCore:OnResetBarsButton(wndHandler, wndControl, eMouseButton)
    self:BarsResetAnchors()
end

-- When the Move button is pushed.
function RaidCore:OnMoveBarsButton(wndHandler, wndControl, eMouseButton)
    local bIsChecked = wndControl:IsChecked()
    if bIsChecked then
        wndControl:SetText(self.L["Lock Bars"])
        self:BarsAnchorUnlock(true)
    else
        wndControl:SetText(self.L["Move Bars"])
        self:BarsAnchorUnlock(false)
    end
end

function RaidCore:OnWindowLoad(wndHandler, wndControl)
    local a, b, c = unpack(Split(wndControl:GetName(), '_'))
    local val = nil
    if c then
        val = self.db.profile[a][b][c]
    elseif b then
        val = self.db.profile[a][b]
    elseif a then
        val = self.db.profile[a]
    end
    if val == nil then
        error((("Value not found in DB for keys: [%s][%s][%s]"):format(tostring(a), tostring(b), tostring(c))))
    end
    if wndControl.SetCheck then
        wndControl:SetCheck(val)
    end
    if type(val) == "boolean"  or a == "Encounters" then
        wndControl:SetCheck(val)
    elseif type(val) == "number" or type(val) == "string" then
        wndControl:SetText(val)
        if wndControl.SetValue and type(val) == "number" then
            wndControl:SetValue(val)
        end
    end
end

function RaidCore:OnButtonCheckBoxSwitched(wndHandler, wndControl, eMouseButton)
    local a, b, c = unpack(Split(wndControl:GetName(), '_'))
    if c then
        self.db.profile[a][b][c] = wndControl:IsChecked()
    elseif b then
        self.db.profile[a][b] = wndControl:IsChecked()
    else
        self.db.profile[a] = wndControl:IsChecked()
    end
end

function RaidCore:OnEditBoxChanged(wndHandler, wndControl, eMouseButton)
    local a, b, c = unpack(Split(wndControl:GetName(), '_'))
    if c then
        self.db.profile[a][b][c] = wndControl:GetText()
    elseif b then
        self.db.profile[a][b] = wndControl:GetText()
    else
        self.db.profile[a] = wndControl:GetText()
    end
end

function RaidCore:OnGeneralSettingsSliderBarChanged(wndHandler, wndControl, nNewValue, fOldValue)
    local sName = wndControl:GetName()
    local a, b, c = unpack(Split(sName, '_'))
    nNewValue = math.floor(nNewValue)
    for _, wnd in next, wndControl:GetParent():GetParent():GetChildren() do
        if wnd:GetName() == sName then
            wnd:SetText(nNewValue)
            break
        end
    end
    if c then
        self.db.profile[a][b][c] = nNewValue
    elseif b then
        self.db.profile[a][b] = nNewValue
    else
        self.db.profile[a] = nNewValue
    end
end
