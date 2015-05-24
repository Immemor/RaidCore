----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--  Description:
--
--  Bar Manager is in lead of Timers, Units and Messages bars.
--  Each type is contain in a simple containers, but the style of each bar is different.
--  They are updated slowly, if at least one bar exist.
--
----------------------------------------------------------------------------------------------------
require "Apollo"
require "GameLib"
require "ApolloTimer"
require "Window"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local LogPackage = Apollo.GetPackage("Log-1.0").tPackage
local Log = LogPackage:CreateNamespace("BarsManager")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local next, pcall, assert = next, pcall, assert
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------
local _tUpdateBarTimer = nil
local _tManagers = {}
local _bTimerRunning = false
local TemplateManager = {}

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local TEMPLATE_MANAGER_META = { __index = TemplateManager }
local BAR_UPDATE_PERIOD = 0.1
local NO_BREAK_SPACE = string.char(194, 160)
local DEFAULT_BLOCK_CONFIG = {
    bEnabled = true,
    bAnchorFromTop = true,
    bSortInversed = false,
    bAutofadeEnable = true,
    BarHeight = 35, -- Will replace barSize later.
    -- This sub array will be deleted soon.
    barSize = {
        Width = 300,
        Height = 25,
    },
}

----------------------------------------------------------------------------------------------------
-- local function.
----------------------------------------------------------------------------------------------------
local function ExtraLog2Text(k, nRefTime, tParam)
    local sResult = ""
    if k == "ERROR" then
        sResult = tParam[1]
    end
    return sResult
end
Log:SetExtra2String(ExtraLog2Text)

local function NewManager(sText)
    local new = setmetatable({}, TEMPLATE_MANAGER_META)
    new.tConfig = {}
    new.sText = sText
    for k, v in next, DEFAULT_BLOCK_CONFIG do
        if v ~= table then
            new.tConfig[k] = v
        else
            for a, b in next, v do
                new.tConfig[k][a] = b
            end
        end
    end
    new.tBars = {}

    table.insert(_tManagers, new)
    return new
end

local function TimerStart()
    if not _bTimerRunning then
        _bTimerRunning = true
        _tUpdateBarTimer:Start()
    end
end

local function SortContentByTime(a, b)
    return a:GetData() < b:GetData()
end

local function SortContentByInvTime(a, b)
    return a:GetData() > b:GetData()
end

local function ArrangeBar(tManager)
    local nSort = Window.CodeEnumArrangeOrigin.RightOrBottom
    if tManager.tConfig.bAnchorFromTop then
        nSort = Window.CodeEnumArrangeOrigin.LeftOrTop
    end
    local fSort = SortContentByTime
    if tManager.tConfig.bSortInversed then
        fSort = SortContentByInvTime
    end
    tManager.wndParent:ArrangeChildrenVert(nSort, fSort)
end

local function Number2ShortString(val)
    local r
    if val < 1000 then
        r = ("%d"):format(val)
    elseif val < 1000000 then
        r = ("%.1fk"):format(val / 1000)
    else
        r = ("%.1fm"):format(val / 1000000)
    end
    return r
end

local function UpdateUnitBar(tBar)
    local tUnit = GetUnitById(tBar.nId)
    if tUnit and tUnit:IsValid() then
        local MaxHealth = tUnit:GetMaxHealth()
        local Health = tUnit:GetHealth()
        local sName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        if Health and MaxHealth then
            local nPourcent = 100.0 * Health / MaxHealth
            -- Update progress bar.
            tBar.wndUnitHPProgressBar:SetMax(MaxHealth)
            tBar.wndUnitHPProgressBar:SetProgress(Health)
            -- Update the percent text.
            tBar.wndUnitHPPercent:SetText(("%.1f%%"):format(nPourcent))
            -- Update the short health text.
            tBar.wndUnitHPValue:SetText(Number2ShortString(Health))

            nPourcent = math.floor(nPourcent)
            if tBar.nPreviousPourcent ~= nPourcent then
                tBar.nPreviousPourcent = nPourcent
                Event_FireGenericEvent("UNIT_HEALTH", sName, nPourcent)
            end
        else
            tBar.wndUnitHPPercent:SetText("")
            tBar.wndUnitHPValue:SetText("")
        end
        -- Update the name.
        tBar.wndUnitName:SetText(sName)
        -- Update the marker indication.
        if tBar.sMark then
            tBar.wndMarkValue:SetText(tBar.sMark:sub(1,4))
            tBar.wndMark:Show(true)
        else
            tBar.wndMark:Show(false)
        end

        -- Process cast bar
        local bProcessCast = false
        local nCastDuration, nCastElapsed, sCastName
        if tUnit:IsCasting() then
            nCastDuration = tUnit:GetCastDuration() / 1000.0
            nCastElapsed = tUnit:GetCastElapsed() / 1000.0
            sCastName = tUnit:GetCastName()
            if tUnit:IsCasting() and nCastElapsed < nCastDuration then
                bProcessCast = true
            end
        end
        if bProcessCast then
            tBar.wndCastProgressBar:SetProgress(nCastElapsed)
            tBar.wndCastProgressBar:SetMax(nCastDuration)
            tBar.wndCastText:SetText(sCastName)
            tBar.wndCast:Show(true)
        else
            tBar.wndCast:Show(false)
        end
        -- Process shield bar
        local nShieldCapacity = tUnit:GetShieldCapacity()
        local nShieldCapacityMax = tUnit:GetShieldCapacityMax()
        if Health ~= 0 and nShieldCapacity and nShieldCapacity ~= 0 then
            tBar.wndShieldProgressBar:SetProgress(nShieldCapacity)
            tBar.wndShieldProgressBar:SetMax(nShieldCapacityMax)
            tBar.wndShieldValue:SetText(Number2ShortString(nShieldCapacity))
            tBar.wndShield:Show(true)
        else
            tBar.wndShield:Show(false)
        end
        -- Process absorb bar
        local nAbsorptionValue = tUnit:GetAbsorptionValue()
        local nAbsorptionMax = tUnit:GetAbsorptionMax()
        if Health ~= 0 and nAbsorptionValue and nAbsorptionValue ~= 0 then
            tBar.wndAbsorbProgressBar:SetProgress(nAbsorptionValue)
            tBar.wndAbsorbProgressBar:SetMax(nAbsorptionMax)
            tBar.wndAbsorbValue:SetText(Number2ShortString(nAbsorptionValue))
            tBar.wndAbsorb:Show(true)
        else
            tBar.wndAbsorb:Show(false)
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Template Class.
----------------------------------------------------------------------------------------------------
function TemplateManager:Init()
    self.wndParent = Apollo.LoadForm(RaidCore.xmlDoc, "BarContainer", nil, self)
    self.wndParent:SetText(self.sText)
    self.wndParent:SetSizingMinimum(200, 100)
    if self.SetCustomConfig then
        self:SetCustomConfig()
    end
end

function TemplateManager:AddBar(...)
    if self.tConfig.bEnabled then
        local r, sErr = pcall(self._AddBar, self, ...)
        if not r then
            --@alpha@
            Print(sErr)
            --@end-alpha@
            Log:Add("ERROR", sErr)
        end
    end
end

function TemplateManager:RemoveBar(key)
    assert(key)
    local tBar = self.tBars[key]
    if tBar then
        self.tBars[key] = nil
        tBar.wndMain:Destroy()
        ArrangeBar(self)
    end
end

function TemplateManager:RemoveAllBars()
    self.wndParent:DestroyChildren()
    self.tBars = {}
end

function TemplateManager:SetPosition(l, t)
    self.wndParent:SetAnchorPoints(l, t, l, t)
    self.wndParent:SetAnchorOffsets(-150, -200, 150, 200)
end

----------------------------------------------------------------------------------------------------
-- Timer Class.
----------------------------------------------------------------------------------------------------
local TimerManager = NewManager("Timer Bars")

function TimerManager:SetCustomConfig()
    self.BarMinHeight = 25
    self.tConfig.BarHeight = 25
    self.wndParent:SetSizingMinimum(150, 250)
end

function TimerManager:_AddBar(sKey, sText, nDuration, tCallback, tOptions)
    assert(type(sKey) == "string")
    assert(type(sText) == "string")
    assert(type(nDuration) == "number")
    assert(not tCallback or tCallback.fHandler)

    if nDuration > 0 then
        -- Manage windows objects.
        local wndMain = nil
        if self.tBars[sKey] then
            -- Retrieve existing windows object.
            wndMain = self.tBars[sKey].wndMain
        else
            -- Create a new bar.
            wndMain = Apollo.LoadForm(RaidCore.xmlDoc, "BarTimerTemplate", self.wndParent, self)
        end
        local wndBar = wndMain:FindChild("Border"):FindChild("bg")
        local wndText = wndBar:FindChild("Text")
        local wndTimeLeft = wndBar:FindChild("TimeLeft")
        local wndProgressBar = wndBar:FindChild("ProgressBar")

        -- Manage bar itself.
        local nEndTime = GetGameTime() + nDuration
        local EnableCountDown = false
        wndMain:SetData(nEndTime)
        wndMain:SetAnchorOffsets(0, 0, 0, self.tConfig.BarHeight)
        wndProgressBar:SetMax(nDuration)
        wndProgressBar:SetProgress(nDuration)
        wndTimeLeft:SetText(("%.1fs"):format(nDuration))
        wndText:SetText(sText)
        if tOptions then
            if tOptions.sColor then
                wndProgressBar:SetBarColor(tOptions.sColor)
            end
            if tOptions.bEmphasize then
                EnableCountDown = true
            end
        end

        self.tBars[sKey] = {
            -- About timer itself.
            sText = sText,
            nDuration = nDuration,
            nEndTime = nEndTime,
            EnableCountDown = EnableCountDown,
            -- Callback to use on timeout.
            tCallback = tCallback,
            -- Windows objects.
            wndMain = wndMain,
            wndText = wndText,
            wndTimeLeft = wndTimeLeft,
            wndProgressBar = wndProgressBar,
            -- Working variables attached to this timer.
            nPrevRemaining = nDuration + 2 * BAR_UPDATE_PERIOD,
        }
        ArrangeBar(self)
        TimerStart()
    else
        -- Delete the bar, check if exist is done in this function.
        self:RemoveBar(sKey)
    end
end

function TimerManager:OnTimerUpdate()
    local Timeout = {}
    local nCurrentTime = GetGameTime()

    -- Update each bar timer.
    for sKey, tBar in next, self.tBars do
        -- Is the timeout have been reached?
        if nCurrentTime < tBar.nEndTime then
            local nRemaining = tBar.nEndTime - nCurrentTime
            tBar.wndProgressBar:SetProgress(nRemaining)
            tBar.wndTimeLeft:SetText(("%.1fs"):format(nRemaining))
            if tBar.EnableCountDown then
                if nRemaining < 5 then
                    local nCountDown = math.floor(tBar.nPrevRemaining)
                    local nFloorRemain = math.floor(nRemaining)
                    if nCountDown ~= nFloorRemain then
                        local sCountDown = tostring(nCountDown)
                        RaidCore:AddMsg("COUNTDOWN", sCountDown, 1, sCountDown, "green")
                    end
                end
            end
            tBar.nPrevRemaining = nRemaining
        else
            if tBar.tCallback then
                table.insert(Timeout, tBar.tCallback)
            end
            self:RemoveBar(sKey)
        end
    end
    -- Process all callback of ended timer.
    for _, tCallback in next, Timeout do
        if tCallback.tClass then
            -- Call a function in a class.
            tCallback.fHandler(tCallback.tClass, tCallback.tData)
        else
            -- Call a function ouside a class.
            tCallback.fHandler(tCallback.tData)
        end
    end
end

----------------------------------------------------------------------------------------------------
-- UnitManager Class.
----------------------------------------------------------------------------------------------------
local UnitManager = NewManager("Unit Bars")

function UnitManager:SetCustomConfig()
    self.BarMinHeight = 25
    self.wndParent:SetSizingMinimum(300, 200)
    self.tConfig.bAutofadeEnable = true
    self.tConfig.BarHeight = 32
end

function UnitManager:_AddBar(nId)
    assert(GetUnitById(nId))
    if not self.tBars[nId] then
        local sMark = RaidCore.mark[nId] and RaidCore.mark[nId].number
        local wndMain = Apollo.LoadForm(RaidCore.xmlDoc, "BarUnitTemplate", self.wndParent, self)
        local wndUnit = wndMain:FindChild("Body"):FindChild("Unit"):FindChild("bg")
        local wndShield = wndMain:FindChild("Body"):FindChild("Shield")
        local wndCast = wndMain:FindChild("Body"):FindChild("Cast")
        local wndAbsorb = wndMain:FindChild("Body"):FindChild("Absorb")
        local wndMark = wndMain:FindChild("Mark")
        self.tBars[nId] = {
            nId = nId,
            sMark = sMark,
            -- Windows objects.
            wndMain = wndMain,
            wndUnitHPProgressBar = wndUnit:FindChild("HP_ProgressBar"),
            wndUnitHPPercent = wndUnit:FindChild("HP_Percent"),
            wndUnitHPValue = wndUnit:FindChild("HP_Value"),
            wndUnitName = wndUnit:FindChild("Name"),

            wndMark = wndMark,
            wndMarkValue = wndMark:FindChild("bg"):FindChild("Value"),

            wndShield = wndShield,
            wndShieldProgressBar = wndShield:FindChild("bg"):FindChild("ProgressBar"),
            wndShieldValue = wndShield:FindChild("bg"):FindChild("Value"),

            wndCast = wndCast,
            wndCastProgressBar = wndCast:FindChild("bg"):FindChild("ProgressBar"),
            wndCastText = wndCast:FindChild("bg"):FindChild("Text"),

            wndAbsorb = wndAbsorb,
            wndAbsorbProgressBar = wndAbsorb:FindChild("bg"):FindChild("ProgressBar"),
            wndAbsorbValue = wndAbsorb:FindChild("bg"):FindChild("Value"),
        }
        wndMain:SetData(GetGameTime())
        wndMain:SetAnchorOffsets(0, 0, 0, self.tConfig.BarHeight)
        UpdateUnitBar(self.tBars[nId])
        ArrangeBar(self)
        TimerStart()
    end
end

function UnitManager:OnTimerUpdate()
    for _, Bar in next, self.tBars do
        UpdateUnitBar(Bar)
    end
end

----------------------------------------------------------------------------------------------------
-- Message Class.
----------------------------------------------------------------------------------------------------
local MessageManager = NewManager("Message Bars")

function MessageManager:SetCustomConfig()
    self.BarMinHeight = 35
    self.wndParent:SetSizingMinimum(300, 100)
end

function MessageManager:_AddBar(sKey, sText, nDuration, tOptions)
    assert(sKey)
    assert(sText)
    assert(nDuration)

    if nDuration > 0 then
        -- Manage windows objects.
        local wndMain = nil
        if self.tBars[sKey] then
            -- Retrieve existing windows object.
            wndMain = self.tBars[sKey].wndMain
            -- Restore opacity quickly.
            wndMain:SetOpacity(1, 200)
        else
            -- Create a new bar.
            wndMain = Apollo.LoadForm(RaidCore.xmlDoc, "BarMessageTemplate", self.wndParent, self)
        end
        local nCurrentTime = GetGameTime()
        local nEndTime = nCurrentTime + nDuration
        wndMain:SetData(nCurrentTime)
        wndMain:SetAnchorOffsets(0, 0, 0, self.tConfig.BarHeight)
        wndMain:SetText(sText)
        if tOptions then
            if tOptions.sColor then
                wndMain:SetTextColor(tOptions.sColor)
            end
        end
        self.tBars[sKey] = {
            -- About timer itself.
            sText = sText,
            bAutoFade = false,
            nDuration = nDuration,
            nEndTime = nEndTime,
            -- Windows objects.
            wndMain = wndMain,
        }
        ArrangeBar(self)
        TimerStart()
    else
        -- Delete the bar, check if exist is done in this function.
        self:RemoveBar(sKey)
    end
end

function MessageManager:OnTimerUpdate()
    local nCurrentTime = GetGameTime()
    for k, tBar in next, self.tBars do
        local bAutofade = self.tConfig.bAutofadeEnable and not tBar.bAutoFade
        if nCurrentTime >= tBar.nEndTime then
            self:RemoveBar(k)
        elseif bAutofade and nCurrentTime + 0.5 >= tBar.nEndTime then
            tBar.bAutoFade = true
            -- Decrease opacity slowly (default is 2s, when second arg is 1).
            tBar.wndMain:SetOpacity(0, 4)
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Relations between RaidCore and Bar Managers.
----------------------------------------------------------------------------------------------------
function RaidCore:BarManagersInit()
    for _, tManager in next, _tManagers do
        tManager:Init()
    end
    -- Create the update timer.
    _tUpdateBarTimer = ApolloTimer.Create(BAR_UPDATE_PERIOD, true, "OnBarsUpdate", self)
    _tUpdateBarTimer:Stop()
    _bTimerRunning = false
    -- Load default configuration
    self:BarsAnchorUnlock(false)
    self:ResetPosition()
end

function RaidCore:OnBarsUpdate()
    for _, tManager in next, _tManagers do
        local r, sErr = pcall(tManager.OnTimerUpdate, tManager)
        if not r then
            --@alpha@
            Print(sErr)
            --@end-alpha@
            Log:Add("ERROR", sErr)
        end
    end
    -- Is there at least 1 bar remaining somewhere?
    local bIsEmpty = true
    for _, tManager in next, _tManagers do
        if next(tManager.tBars) ~= nil then
            bIsEmpty = false
        end
    end
    if bIsEmpty then
        _tUpdateBarTimer:Stop()
        _bTimerRunning = false
    end
end

-- Keep compatibility
function RaidCore:BarsSaveConfig()
    local Save = function(tManager)
        local wndParent = tManager.wndParent
        tDST = {}
        for key, _ in next, DEFAULT_BLOCK_CONFIG do
            tDST[key] = tManager.tConfig[key]
        end
        tDST.Position = { wndParent:GetAnchorOffsets() }
        return tDST
    end
    self.settings["General"]["raidbars"] = Save(TimerManager)
    self.settings["General"]["message"] = Save(MessageManager)
    self.settings["General"]["unitmoni"] = Save(UnitManager)
end

-- Keep compatibility
function RaidCore:BarsLoadConfig()
    local Update = function(tManager, tSRC)
        local wnd = tManager.wndParent
        local copy = function(reg, new, x)
            if new[x] ~= nil then
                reg[x] = new[x]
            end
        end
        if tSRC then
            for key, _ in next, DEFAULT_BLOCK_CONFIG do
                copy(tManager.tConfig, tSRC, key)
            end
            if tSRC.Position then
                local left = tSRC.Position[1] or -150
                local top = tSRC.Position[2] or -200
                local right = tSRC.Position[3] or left + wnd:GetWidth()
                local bottom = tSRC.Position[4] or top + wnd:GetHeight()
                wnd:SetAnchorOffsets(left, top, right, bottom)
            end
            if tManager.BarMinHeight > tSRC.barSize.Height then
                tSRC.barSize.Height = tManager.BarMinHeight
            end
            tSRC.BarHeight = tSRC.barSize.Height
        end
    end
    -- Update data in window objects.
    Update(TimerManager, self.settings["General"]["raidbars"])
    Update(MessageManager, self.settings["General"]["message"])
    Update(UnitManager, self.settings["General"]["unitmoni"])
end

-- Add a message to screen.
function RaidCore:AddMsg(sKey, sText, nDuration, sSound, sColor)
    Log:Add("AddMsg", sKey, sText, nDuration, sSound, sColor)
    local tOptions = {
        sColor = sColor,
    }
    MessageManager:AddBar(sKey, sText, nDuration, tOptions)
    if sSound then
        self:PlaySound(sSound)
    end
end

-- Deprecated function, will be replaced by AddTimerBar.
function RaidCore:AddBar(sKey, sText, nDuration, bEmphasize)
    Log:Add("AddBar", sKey, sText, nDuration, bEmphasize)
    local tOptions = {
        bEmphasize = bEmphasize
    }
    TimerManager:AddBar(sKey, sText, nDuration, nil, tOptions)
end

-- Add a timer bar on screen.
-- @param sKey  timer identification, can be used to overwrite a timer.
-- @param sText  Text to display in the timer bar.
-- @param nDuration  Time to decrease.
-- @param tCallback  structure about a callback action to do on timeout only.
-- @param tOptions  structure with many graphical options.
function RaidCore:AddTimerBar(sKey, sText, nDuration, tCallBack, tOptions)
    TimerManager:AddBar(sKey, sText, nDuration, tCallBack, tOptions)
end

function RaidCore:StopBar(sKey)
    Log:Add("StopBar", sKey)
    TimerManager:RemoveBar(sKey)
end

function RaidCore:AddUnit(tUnit)
    assert(type(tUnit) == "userdata")
    local nId = tUnit:GetId()
    Log:Add("AddUnit", nId)
    UnitManager:AddBar(nId)
end

function RaidCore:RemoveUnit(nId)
    Log:Add("RemoveUnit", nId)
    UnitManager:RemoveBar(nId)
end

function RaidCore:SetMark2UnitBar(nId, sMark)
    local tBar = UnitManager.tBars[nId]
    if tBar and sMark then
        tBar.sMark = sMark
    end
end

function RaidCore:BarsRemoveAll()
    Log:Add("BarsRemoveAll")
    for _, tManager in next, _tManagers do
        tManager:RemoveAllBars()
    end
end

function RaidCore:BarsAnchorUnlock(bLock)
    Log:Add("BarsAnchorUnlock", bLock)
    if bLock then
        for _, tManager in next, _tManagers do
            local wnd = tManager.wndParent
            wnd:SetBGColor('b0606060')
            wnd:SetTextColor('ffffffff')
            wnd:SetStyle("Picture", true)
            wnd:SetStyle("Moveable", true)
            wnd:SetStyle("Sizable", true)
            wnd:SetStyle("IgnoreMouse", false)
        end
    else
        for _, tManager in next, _tManagers do
            local wnd = tManager.wndParent
            wnd:SetBGColor('00000000')
            wnd:SetTextColor('00000000')
            wnd:SetStyle("Picture", false)
            wnd:SetStyle("Moveable", false)
            wnd:SetStyle("Sizable", false)
            wnd:SetStyle("IgnoreMouse", true)
        end
    end
end

function RaidCore:ResetPosition()
    Log:Add("ResetPosition")
    TimerManager:SetPosition(0.3, 0.5)
    TimerManager.tConfig.BarHeight = 25
    MessageManager:SetPosition(0.5, 0.5)
    MessageManager.tConfig.BarHeight = 35
    UnitManager:SetPosition(0.7, 0.5)
    UnitManager.tConfig.BarHeight = 32
end
