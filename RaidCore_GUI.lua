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

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local next, pcall, assert, error = next, pcall, assert, error
local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------
local ShowHideClass = {}

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local SHOW_HIDE_PANEL_ENCOUNTER_DURATION = 0.60
local SHOW_HIDE_PANEL_ENCOUNTER_MOVE = 155

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

----------------------------------------------------------------------------------------------------
-- ShowHide Class manager.
----------------------------------------------------------------------------------------------------
function ShowHideClass:OnShowHideUpdate()
    local left, top, right, bottom
    local nCurrentTime = GetGameTime()
    local nEncounterDelta = RaidCore.nShowHideEncounterPanelTime - nCurrentTime
    nEncounterDelta = nEncounterDelta > 0 and nEncounterDelta or 0

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

    if nEncounterDelta == 0 then
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
        General = Apollo.LoadForm(self.xmlDoc, "ConfigForm_General", self.wndBodyTarget, self),
        About_Us = Apollo.LoadForm(self.xmlDoc, "ConfigForm_About_Us", self.wndBodyTarget, self),
        Encounters = Apollo.LoadForm(self.xmlDoc, "ConfigBody_Encounters", self.wndBodyTarget, self),
    }
    self.wndEncounterTarget = self.LeftMenu2wndBody.Encounters:FindChild("Encounter_Target")
    self.wndEncounterList = self.LeftMenu2wndBody.Encounters:FindChild("Encounter_List")
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
