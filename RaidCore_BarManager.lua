----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--
-- Bar Manager is in lead of Timers, Units and Messages bars.
-- Each type is contain in a simple containers, but the style of each bar is different.
-- They are updated slowly, if at least one bar exist.
--
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local ApolloTimer = require "ApolloTimer"
local GameLib = require "GameLib"
local Window = require "Window"
local Unit = require "Unit"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

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
local VULNERABILITY = Unit.CodeEnumCCState.Vulnerability
local BAR_UPDATE_PERIOD = 0.1
local DEFAULT_SETTINGS = {
  ['**'] = {
    bEnabled = true,
    bAnchorFromTop = true,
    bSortInversed = false,
    nBarHeight = 35,
    tAnchorOffsets = { -150, -200, 150, 200 },
    tSizingMinimum = { 200, 100 },
  },
  ["Timer"] = {
    nBarHeight = 25,
    bEnableCountDownMessage = true,
    bEnableCountDownSound = true,
    tAnchorPoints = { 0.25, 0.5, 0.25, 0.5 },
    tSizingMinimum = { 150, 250 },
  },
  ["Progress"] = {
    nBarHeight = 25,
    tAnchorPoints = { 0.25, 0.5, 0.25, 0.5 },
    tAnchorOffsets = { -150, -300, 150, -50 },
    tSizingMinimum = { 150, 250 },
  },
  ["Message"] = {
    bAutofadeEnable = true,
    tAnchorPoints = { 0.5, 0.5, 0.5, 0.5 },
    tAnchorOffsets = { -250, 0, 250, 100 },
    tSizingMinimum = { 300, 100 },
  },
  ["Health"] = {
    bPourcentWith2Digits = false,
    nBarHeight = 32,
    tAnchorPoints = { 0.75, 0.5, 0.75, 0.5 },
    tSizingMinimum = { 300, 200 },
    bDisplayCast = true,
    bDisplayAbsorb = true,
    bDisplayShield = true,
    bDisplayMidphase = true,
  },
}

----------------------------------------------------------------------------------------------------
-- local function.
----------------------------------------------------------------------------------------------------
local function NewManager(sText)
  local new = setmetatable({}, TEMPLATE_MANAGER_META)
  new.tSettings = {}
  new.sText = sText
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
  if tManager.tSettings.bAnchorFromTop then
    nSort = Window.CodeEnumArrangeOrigin.LeftOrTop
  end
  local fSort = SortContentByTime
  if tManager.tSettings.bSortInversed then
    fSort = SortContentByInvTime
  end
  tManager.wndParent:ArrangeChildrenVert(nSort, fSort)
end

local function BuildProgressbarMarker(tMarker, parent, context)
  local wndMarker = Apollo.LoadForm(RaidCore.xmlDoc, "ProgressbarMarkerTemplate", parent, context)
  wndMarker:SetBGColor(tMarker.color)
  wndMarker:SetBGOpacity(tMarker.opacity)
  local left = tMarker.startPercent / 100
  local right = tMarker.endPercent / 100
  wndMarker:SetAnchorPoints(left , 0, right, 1)
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

----------------------------------------------------------------------------------------------------
-- Template Class.
----------------------------------------------------------------------------------------------------
function TemplateManager:Init(tSettings)
  assert(tSettings)
  self.tSettings = tSettings
  self.wndParent = Apollo.LoadForm(RaidCore.xmlDoc, "BarContainer", nil, self)
  self.wndParent:SetText(self.sText)
  local MinX, MinY = unpack(tSettings.tSizingMinimum)
  self.wndParent:SetSizingMinimum(MinX, MinY)

  if tSettings.tAnchorOffsets then
    local left, top, right, bottom = unpack(tSettings.tAnchorOffsets)
    self.wndParent:SetAnchorOffsets(left, top, right, bottom)
  end
  if tSettings.tAnchorPoints then
    local left, top, right, bottom = unpack(tSettings.tAnchorPoints)
    self.wndParent:SetAnchorPoints(left, top, right, bottom)
  end
end

function TemplateManager:_AddBar(...)
  if self.tSettings.bEnabled then
    self:AddBar(...)
  end
end

function TemplateManager:HasBar(key)
  assert(key)
  return self.tBars[key] ~= nil
end

function TemplateManager:RemoveBar(key)
  assert(key)
  local tBar = self.tBars[key]
  if tBar then
    self.tBars[key] = nil
    if tBar.wndMain then
      tBar.wndMain:Destroy()
    end
    ArrangeBar(self)
  end
end

function TemplateManager:RemoveAllBars()
  self.wndParent:DestroyChildren()
  self.tBars = {}
end

----------------------------------------------------------------------------------------------------
-- Timer Class.
----------------------------------------------------------------------------------------------------
local TimerManager = NewManager("Timer")

function TimerManager:AddBar(sKey, sText, nDuration, tCallback, tOptions)
  assert(type(sKey) == "string")
  assert(type(sText) == "string")
  assert(type(nDuration) == "number")
  assert(not tCallback or tCallback.fHandler)

  if nDuration > 0 then
    -- Manage windows objects.
    local wndMain
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
    wndMain:SetAnchorOffsets(0, 0, 0, self.tSettings.nBarHeight)
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

function TimerManager:ExtendBar(sKey, nDurationToAdd)
  -- TODO Make it work on dead timers.
  assert(type(sKey) == "string")
  assert(type(nDurationToAdd) == "number")
  if nDurationToAdd > 0 then
    local tBar = self.tBars[sKey]
    if tBar ~= nil then
      local nNewDuration = tBar.nDuration + nDurationToAdd
      local nNewEndTime = tBar.nEndTime + nDurationToAdd
      tBar.nEndTime = nNewEndTime
      tBar.wndProgressBar:SetMax(nNewDuration)
      tBar.wndMain:SetData(nNewEndTime)

      local nCurrentTime = GetGameTime()
      self:UpdateBar(sKey, tBar, nCurrentTime)
    end
  end
end

function TimerManager:UpdateBar(sKey, tBar, nCurrentTime)
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
          if self.tSettings.bEnableCountDownMessage then
            RaidCore:AddMsg("COUNTDOWN", sCountDown, 1, nil, "green")
          end
          if self.tSettings.bEnableCountDownSound then
            RaidCore:PlaySound(sCountDown)
          end
        end
      end
    end
    tBar.nPrevRemaining = nRemaining
  else
    if tBar.tCallback then
      table.insert(self.tTimeout, tBar.tCallback)
    end
    self:RemoveBar(sKey)
  end
end

function TimerManager:OnTimerUpdate()
  self.tTimeout = {}
  local nCurrentTime = GetGameTime()

  -- Update each bar timer.
  for sKey, tBar in next, self.tBars do
    self:UpdateBar(sKey, tBar, nCurrentTime)
  end
  -- Process all callback of ended timer.
  for _, tCallback in next, self.tTimeout do
    if tCallback.tClass then
      -- Call a function in a class.
      tCallback.fHandler(tCallback.tClass, tCallback.tData)
    else
      -- Call a function ouside a class.
      tCallback.fHandler(tCallback.tData)
    end
  end
  self.tTimeout = nil
end

----------------------------------------------------------------------------------------------------
-- Progress Class.
----------------------------------------------------------------------------------------------------
local ProgressManager = NewManager("Progress")

function ProgressManager:AddBar(sKey, sText, tUpdate, tOptions, tCallback)
  assert(type(sKey) == "string")
  assert(type(sText) == "string")
  assert(tUpdate and tUpdate.fHandler)
  assert(not tCallback or tCallback.fHandler)
  local nProgress
  if tUpdate.tClass then
    nProgress = tUpdate.fHandler(tUpdate.tClass, 0)
  else
    nProgress = tUpdate.fHandler(0)
  end

  -- Manage windows objects.
  local wndMain
  if self.tBars[sKey] then
    wndMain = self.tBars[sKey].wndMain
  else
    wndMain = Apollo.LoadForm(RaidCore.xmlDoc, "BarProgressTemplate", self.wndParent, self)
  end
  local wndBar = wndMain:FindChild("Border"):FindChild("bg")
  local wndText = wndBar:FindChild("Text")
  local wndProgress = wndBar:FindChild("Progress")
  local wndProgressBar = wndBar:FindChild("ProgressBar")
  local nPriority = 99
  -- Manage bar itself.
  wndMain:SetAnchorOffsets(0, 0, 0, self.tSettings.nBarHeight)
  wndProgressBar:SetMax(100)
  wndProgressBar:SetProgress(nProgress)
  wndProgress:SetText(("%.1f%%"):format(nProgress))
  wndText:SetText(sText)
  if tOptions then
    if tOptions.sColor then
      wndProgressBar:SetBarColor(tOptions.sColor)
    end
    nPriority = tOptions.nPriority or nPriority
  end
  wndMain:SetData(nPriority)

  self.tBars[sKey] = {
    -- About timer itself.
    sText = sText,
    nPriority = nPriority,
    -- Get progress
    tUpdate = tUpdate,
    tCallback = tCallback,
    -- Windows objects.
    wndMain = wndMain,
    wndText = wndText,
    wndProgress = wndProgress,
    wndProgressBar = wndProgressBar,
    nPrevProgress = nProgress
  }
  ArrangeBar(self)
  TimerStart()
end

function ProgressManager:UpdateBar(sKey, tBar)
  local nProgress
  local barColor
  if tBar.tUpdate.tClass then
    nProgress, barColor = tBar.tUpdate.fHandler(tBar.tUpdate.tClass, tBar.nPrevProgress)
  else
    nProgress, barColor = tBar.tUpdate.fHandler(tBar.nPrevProgress)
  end
  if nProgress < 100 then
    tBar.wndProgressBar:SetProgress(nProgress)
    tBar.wndProgress:SetText(("%.1f%%"):format(nProgress))
    tBar.nPrevProgress = nProgress
    if barColor then
      tBar.wndProgressBar:SetBarColor(barColor)
    end
  else
    if tBar.tCallback then
      table.insert(self.tTimeout, tBar.tCallback)
    end
    self:RemoveBar(sKey)
  end
end

function ProgressManager:OnTimerUpdate()
  self.tTimeout = {}

  -- Update each bar progress
  for sKey, tBar in next, self.tBars do
    self:UpdateBar(sKey, tBar)
  end
  -- Process all callback of ended timer.
  for _, tCallback in next, self.tTimeout do
    if tCallback.tClass then
      -- Call a function in a class.
      tCallback.fHandler(tCallback.tClass)
    else
      -- Call a function ouside a class.
      tCallback.fHandler()
    end
  end
  self.tTimeout = nil
end

----------------------------------------------------------------------------------------------------
-- UnitManager Class.
----------------------------------------------------------------------------------------------------
local UnitManager = NewManager("Health")

function UnitManager:AddBar(nId, sColor, nPriority, tMarkers)
  assert(GetUnitById(nId))
  if (self.tBars[nId] and self.tBars[nId].isSpacer) or not self.tBars[nId] then
    local sMark = RaidCore.mark[nId] and RaidCore.mark[nId].number
    if self.tSettings.bEnabled then
      local wndMain = Apollo.LoadForm(RaidCore.xmlDoc, "BarUnitTemplate", self.wndParent, self)
      local wndBody = wndMain:FindChild("Body")
      local wndUnit = wndBody:FindChild("Unit"):FindChild("bg")
      local wndShield = wndBody:FindChild("Shield")
      local wndCast = wndBody:FindChild("Cast")
      local wndAbsorb = wndBody:FindChild("Absorb")
      local wndMark = wndMain:FindChild("Mark")
      local wndArmor = wndMain:FindChild("Armor")
      if self.tSettings.bDisplayMidphase and tMarkers then
        local wndMarkerContainer = wndUnit:FindChild("MarkerContainer")
        for i = 1, #tMarkers do
          BuildProgressbarMarker(tMarkers[i], wndMarkerContainer, self)
        end
      end
      self.tBars[nId] = {
        nId = nId,
        sMark = sMark,
        sCustomBarColor = sColor,
        -- Windows objects.
        wndMain = wndMain,
        wndBody = wndBody,
        wndUnit = wndUnit,
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

        wndArmor = wndArmor,
        wndArmorValue = wndArmor:FindChild("Value"),
      }
      wndMain:SetData(nPriority or GetGameTime())
      wndMain:SetAnchorOffsets(0, 0, 0, self.tSettings.nBarHeight)
      self:UpdateBar(self.tBars[nId])
      ArrangeBar(self)
    else
      self.tBars[nId] = {
        nId = nId,
        sMark = sMark,
      }
    end
    TimerStart()
  end
end

function UnitManager:UpdateBar(tBar)
  if tBar.isSpacer then return end
  local tUnit = GetUnitById(tBar.nId)
  if tUnit and tUnit:IsValid() then
    local MaxHealth = tUnit:GetMaxHealth()
    local Health = tUnit:GetHealth()
    local sName = RaidCore:ReplaceNoBreakSpace(tUnit:GetName())
    local bVunerable = tUnit:IsInCCState(VULNERABILITY)
    if Health and MaxHealth then
      local nPourcent = 100.0 * Health / MaxHealth
      if tBar.wndUnitHPProgressBar then
        -- Update progress bar.
        tBar.wndUnitHPProgressBar:SetMax(MaxHealth)
        tBar.wndUnitHPProgressBar:SetProgress(Health)
        if bVunerable then
          tBar.wndUnitHPProgressBar:SetBarColor("FF7E00FF")
          tBar.wndUnit:SetBGColor("A0300062")
        else
          tBar.wndUnitHPProgressBar:SetBarColor(tBar.sCustomBarColor or "FF004000")
          tBar.wndUnit:SetBGColor("A0131313")
        end
        -- Update the percent text.
        local sPourcentFormat = "%.1f%%"
        if self.tSettings.bPourcentWith2Digits then
          sPourcentFormat = "%.2f%%"
        end
        tBar.wndUnitHPPercent:SetText(sPourcentFormat:format(nPourcent))
        -- Update the short health text.
        tBar.wndUnitHPValue:SetText(Number2ShortString(Health))
      end
    elseif tBar.wndUnitHPPercent then
      tBar.wndUnitHPPercent:SetText("")
      tBar.wndUnitHPValue:SetText("")
    end
    if tBar.wndUnitName then
      -- Update the name.
      tBar.wndUnitName:SetText(sName)
      -- Update the marker indication.
      if tBar.sMark then
        tBar.wndMarkValue:SetText(tBar.sMark:sub(1, 4))
        tBar.wndMark:Show(true)
      else
        tBar.wndMark:Show(false)
      end

      local bProcessMiddleBar = false
      local nMidDuration, nMidElapsed, sMidName
      if bVunerable then
        bProcessMiddleBar = true
        nMidDuration = tUnit:GetCCStateTotalTime(VULNERABILITY)
        nMidElapsed = nMidDuration - tUnit:GetCCStateTimeRemaining(VULNERABILITY)
        tBar.wndCastProgressBar:SetBarColor("xkcdVeryLightPurple")
        sMidName = "Vunerable"
      elseif tUnit:IsCasting() then
        -- Process cast bar
        nMidDuration = tUnit:GetCastDuration()
        nMidElapsed = tUnit:GetCastElapsed()
        sMidName = tUnit:GetCastName()
        tBar.wndCastProgressBar:SetBarColor("darkgray")
        if tUnit:IsCasting() and nMidElapsed < nMidDuration then
          bProcessMiddleBar = true
        end
      end
      if bProcessMiddleBar and self.tSettings.bDisplayCast then
        tBar.wndCastProgressBar:SetProgress(nMidElapsed)
        tBar.wndCastProgressBar:SetMax(nMidDuration)
        tBar.wndCastText:SetText(sMidName)
        tBar.wndCast:Show(true)
      else
        tBar.wndCast:Show(false)
      end
      -- Process shield bar
      local nShieldCapacity = tUnit:GetShieldCapacity()
      local nShieldCapacityMax = tUnit:GetShieldCapacityMax()
      if Health ~= 0 and nShieldCapacity and nShieldCapacity ~= 0 and self.tSettings.bDisplayShield then
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
      if Health ~= 0 and nAbsorptionValue and nAbsorptionValue ~= 0 and self.tSettings.bDisplayAbsorb then
        tBar.wndAbsorbProgressBar:SetProgress(nAbsorptionValue)
        tBar.wndAbsorbProgressBar:SetMax(nAbsorptionMax)
        tBar.wndAbsorbValue:SetText(Number2ShortString(nAbsorptionValue))
        tBar.wndAbsorb:Show(true)
      else
        tBar.wndAbsorb:Show(false)
      end
      -- Process Armor bar
      local nArmorValue = tUnit:GetInterruptArmorValue()
      if nArmorValue and nArmorValue > 0 then
        local left, top, _, bottom = tBar.wndBody:GetAnchorOffsets()
        tBar.wndBody:SetAnchorOffsets(left, top, -32, bottom)
        tBar.wndArmor:Show(true)
        tBar.wndArmorValue:SetText(nArmorValue)
      else
        local left, top, _, bottom = tBar.wndBody:GetAnchorOffsets()
        tBar.wndBody:SetAnchorOffsets(left, top, 0, bottom)
        tBar.wndArmor:Show(false)
      end
    end
  end
end

function UnitManager:OnTimerUpdate()
  for _, tBar in next, self.tBars do
    self:UpdateBar(tBar)
  end
end

function UnitManager:AddSpacer(key, nHeight, nPriority)
  assert(key)
  if nHeight == nil then
    nHeight = self.tSettings.nBarHeight
  end

  local wndMain
  if self.tBars[key] and self.tBars[key].isSpacer then
    -- Retrieve existing windows object.
    wndMain = self.tBars[key].wndMain
  else
    -- Create a new bar.
    wndMain = Apollo.LoadForm(RaidCore.xmlDoc, "BarSpacerTemplate", self.wndParent, self)
  end
  wndMain:SetData(nPriority or GetGameTime())
  wndMain:SetAnchorOffsets(0, 0, 0, nHeight)

  self.tBars[key] = {
    wndMain = wndMain,
    isSpacer = true,
  }
end

----------------------------------------------------------------------------------------------------
-- Message Class.
----------------------------------------------------------------------------------------------------
local MessageManager = NewManager("Message")

function MessageManager:AddBar(sKey, sText, nDuration, tOptions)
  assert(sKey)
  assert(sText)
  assert(nDuration)

  if nDuration > 0 then
    -- Manage windows objects.
    local wndMain
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
    wndMain:SetAnchorOffsets(0, 0, 0, self.tSettings.nBarHeight)
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

function MessageManager:RemoveOrFade(sKey)
  if self.tSettings.bAutofadeEnable then
    local tBar = self.tBars[sKey]
    if tBar then
      if not tBar.bAutoFade then
        tBar.nEndTime = GetGameTime() + 0.5
      else
        self:RemoveBar(sKey)
      end
    end
  else
    self:RemoveBar(sKey)
  end
end

function MessageManager:UpdateBar(sKey, tBar, nCurrentTime)
  local bAutofade = self.tSettings.bAutofadeEnable and not tBar.bAutoFade
  if nCurrentTime >= tBar.nEndTime then
    self:RemoveBar(sKey)
  elseif bAutofade and nCurrentTime + 0.5 >= tBar.nEndTime then
    tBar.bAutoFade = true
    -- Decrease opacity slowly (default is 2s, when second arg is 1).
    tBar.wndMain:SetOpacity(0, 4)
  end
end

function MessageManager:OnTimerUpdate()
  local nCurrentTime = GetGameTime()
  for sKey, tBar in next, self.tBars do
    self:UpdateBar(sKey, tBar, nCurrentTime)
  end
end

----------------------------------------------------------------------------------------------------
-- Relations between RaidCore and Bar Managers.
----------------------------------------------------------------------------------------------------
function RaidCore:BarManagersInit(tSettings)
  assert(tSettings)
  -- Load default configuration
  for _, tManager in next, _tManagers do
    tManager:Init(tSettings[tManager.sText])
  end
  -- Set windows in locked state.
  self:BarsAnchorUnlock(false)
  -- Create the update timer.
  _tUpdateBarTimer = ApolloTimer.Create(BAR_UPDATE_PERIOD, true, "OnBarsUpdate", self)
  _tUpdateBarTimer:Stop()
  _bTimerRunning = false
end

function RaidCore:OnBarsUpdate()
  for _, tManager in next, _tManagers do
    local s, e = pcall(tManager.OnTimerUpdate, tManager)
    self:HandlePcallResult(s, e)
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

function RaidCore:GetBarsDefaultSettings()
  return DEFAULT_SETTINGS
end

-- Add a message to screen.
function RaidCore:AddMsg(sKey, sText, nDuration, sSound, sColor)
  local tOptions = {
    sColor = sColor,
  }
  MessageManager:_AddBar(sKey, sText, nDuration, tOptions)
  if sSound then
    self:PlaySound(sSound)
  end
end

function RaidCore:IsUnitActive(key)
  return UnitManager:HasBar(key)
end

function RaidCore:IsProgessActive(key)
  return ProgressManager:HasBar(key)
end

function RaidCore:IsTimerActive(key)
  return TimerManager:HasBar(key)
end

function RaidCore:IsMessageActive(key)
  return MessageManager:HasBar(key)
end

function RaidCore:RemoveMsg(key)
  MessageManager:RemoveOrFade(key)
end

-- Add a timer bar on screen.
-- @param sKey timer identification, can be used to overwrite a timer.
-- @param sText Text to display in the timer bar.
-- @param nDuration Time to decrease.
-- @param tCallback structure about a callback action to do on timeout only.
-- @param tOptions structure with many graphical options.
function RaidCore:AddTimerBar(sKey, sText, nDuration, tCallBack, tOptions)
  TimerManager:_AddBar(sKey, sText, nDuration, tCallBack, tOptions)
end

function RaidCore:ExtendTimerBar(sKey, nDurationToAdd)
  TimerManager:ExtendBar(sKey, nDurationToAdd)
end

function RaidCore:RemoveTimerBar(sKey)
  TimerManager:RemoveBar(sKey)
end

-- Add a timer bar on screen.
-- @param sKey timer identification, can be used to overwrite a timer.
-- @param sText Text to display in the timer bar.
-- @param tUpdate structure about a update action to do get the progress from.
-- @param tOptions structure with many graphical options.
-- @param tCallback structure about a callback action to do when the progress is full.
function RaidCore:AddProgressBar(sKey, sText, tUpdate, tOptions, tCallback)
  ProgressManager:_AddBar(sKey, sText, tUpdate, tOptions, tCallback)
end

function RaidCore:RemoveProgressBar(sKey)
  ProgressManager:RemoveBar(sKey)
end

function RaidCore:AddUnit(tUnit, sColor, nPriority, tMarkers)
  assert(type(tUnit) == "userdata")
  local nId = tUnit:GetId()
  UnitManager:AddBar(nId, sColor, nPriority, tMarkers)
end

function RaidCore:AddUnitSpacer(key, nHeight, nPriority)
  UnitManager:AddSpacer(key, nHeight, nPriority)
end

function RaidCore:RemoveUnit(nId)
  UnitManager:RemoveBar(nId)
end

function RaidCore:SetMark2UnitBar(nId, sMark)
  local tBar = UnitManager.tBars[nId]
  if tBar and sMark then
    tBar.sMark = sMark
  end
end

function RaidCore:BarsRemoveAll()
  for _, tManager in next, _tManagers do
    tManager:RemoveAllBars()
  end
end

function RaidCore:BarsAnchorUnlock(bLock)
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
      tManager.tSettings.tAnchorOffsets = { wnd:GetAnchorOffsets() }
    end
  end
end

function RaidCore:BarsResetAnchors()
  for _, tManager in next, _tManagers do
    local left, top, right, bottom
    if DEFAULT_SETTINGS[tManager.sText].tAnchorOffsets then
      left, top, right, bottom = unpack(DEFAULT_SETTINGS[tManager.sText].tAnchorOffsets)
    else
      left, top, right, bottom = unpack(DEFAULT_SETTINGS["**"].tAnchorOffsets)
    end
    tManager.tSettings.tAnchorOffsets = { left, top, right, bottom }
    tManager.wndParent:SetAnchorOffsets(left, top, right, bottom)
  end
end
