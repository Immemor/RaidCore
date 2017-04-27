----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--
-- Draw Manager will manage many type of graphic objects:
-- * Line between two unit,
-- * Line from 1 unit or a specific position,
-- * Polygon attached to an unit or a specific position,
-- * Sprite attached to an unit or a specific position,
--
-- FeedBack:
-- The GameLib.GetUnitScreenPosition API function return wrong values when Unit is out of screen.
--
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"
local Vector3 = require "Vector3"
local math = require "math"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local Assert = Apollo.GetPackage("RaidCore:Assert-1.0").tPackage

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local next, pcall, assert = next, pcall, assert
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local WorldLocToScreenPoint = GameLib.WorldLocToScreenPoint
local Races = GameLib.CodeEnumRace
local NewVector3 = Vector3.New

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------
local _bDrawManagerRunning = false
local _nPreviousTime = 0
local _wndOverlay = nil
local _tDrawManagers = {}
local _nDrawManagers
local TemplateManager = {}
local TemplateDraw = {}

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local TEMPLATE_MANAGER_META = { __index = TemplateManager }
local TEMPLATE_DRAW_META = { __index = TemplateDraw }
local DOT_IS_A_LINE = 1
local FPOINT_NULL = { 0, 0, 0, 0 }
local DEFAULT_LINE_COLOR = { a = 1.0, r = 1.0, g = 0.0, b = 0.0 } -- Red
local DEFAULT_NORTH_FACING = { x = 0, y = 0, z = -1.0 }
local HEIGHT_PER_RACEID = {
  [Races.Human] = 1.2,
  [Races.Granok] = 1.6,
  [Races.Aurin] = 1.1,
  [Races.Draken] = 1.4,
  [Races.Mechari] = 1.75,
  [Races.Chua] = 1.0,
  [Races.Mordesh] = 1.85,
}
local DEFAULT_SETTINGS = {
  ['**'] = {
    bEnabled = true,
  },
  ["LineBetween"] = {},
  ["SimpleLine"] = {},
  ["Polygon"] = {},
  ["Picture"] = {},

  RefreshFrequencyMax = 60,
}

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------
local function NewDraw()
  local new = {
    nSpriteSize = 4,
    sSprite = "BasicSprites:WhiteCircle",
    sColor = DEFAULT_LINE_COLOR,
    tUnitIds = {},
  }
  return setmetatable(new, TEMPLATE_DRAW_META)
end

local function BuildPublicDraw(t)
  -- Create an empty metatable, with a write protection.
  local function readonly()
    error("Attempt to update a read-only graphical object", 2)
  end
  local mt = {
    __index = t,
    __newindex = readonly
  }
  -- Create a proxy table, which will be the public interface.
  return setmetatable({}, mt)
end

local function NewManager(sText)
  local new = setmetatable({}, TEMPLATE_MANAGER_META)
  new.sManagerName = sText
  new.tDraws = {}
  new.tDrawsPerUnit = {}
  table.insert(_tDrawManagers, new)
  _nDrawManagers = #_tDrawManagers
  return new
end

local function CreateRotationMatrixY(nRotation)
  if not nRotation or nRotation%360 == 0 then return nil end

  local nRad = math.rad(nRotation)
  local nCos = math.cos(nRad)
  local nSin = math.sin(nRad)
  return {
    x = NewVector3({ nCos, 0, - nSin }),
    y = NewVector3({ 0, 1, 0 }),
    z = NewVector3({ nSin, 0, nCos }),
  }
end

local function RotationY(tVector, tMatrixTeta)
  if not tMatrixTeta then return tVector end
  return NewVector3(
    tMatrixTeta.x.x * tVector.x + tMatrixTeta.x.z * tVector.z,
    tVector.y,
    tMatrixTeta.z.x * tVector.x + tMatrixTeta.z.z * tVector.z
  )
end

local function StartDrawing()
  if not _bDrawManagerRunning then
    _bDrawManagerRunning = true
    RaidCore:StartNextFrame()
  end
end

local function StopDrawing()
  if _bDrawManagerRunning then
    _bDrawManagerRunning = false
    RaidCore:StopNextFrame()
  end
end

local function GetOriginType(origin)
  local originType = type(origin)
  if originType == "userdata" then
    if origin.GetRaceId then
      originType = "unit"
    elseif origin.Normal then
      originType = "vector"
    end
  end
  return originType
end

local function ProcessOrigin(origin)
  local originType = GetOriginType(origin)
  local originUnit = nil
  local originVector = nil
  if originType == "number" then
    originUnit = GetUnitById(origin)
  elseif originType == "unit" then
    originUnit = origin
  elseif originType == "table" then
    originVector = NewVector3(origin)
  elseif originType == "vector" then
    originVector = origin
  end
  return originUnit, originVector
end

local function ShouldDrawBeVisible(tDraw, tVectorFrom, tVectorTo)
  local bShouldBeVisible = true
  if tDraw.nMaxLengthVisible or tDraw.nMinLengthVisible then
    local len = (tVectorTo - tVectorFrom):Length()
    if tDraw.nMaxLengthVisible and tDraw.nMaxLengthVisible < len then
      bShouldBeVisible = false
    elseif tDraw.nMinLengthVisible and tDraw.nMinLengthVisible > len then
      bShouldBeVisible = false
    end
  end
  return bShouldBeVisible
end

local function DestroyPixie(tDraw)
  if tDraw.nPixieIdFull then
    _wndOverlay:DestroyPixie(tDraw.nPixieIdFull)
    tDraw.nPixieIdFull = nil
  end
  if next(tDraw.nPixieIdDot) then
    for _, nPixieIdDot in next, tDraw.nPixieIdDot do
      _wndOverlay:DestroyPixie(nPixieIdDot)
    end
    tDraw.nPixieIdDot = {}
  end
end

local function UpdatePixie(tDraw, tScreenLocFrom, tScreenLocTo, nPixieIdFull)
  tDraw.tPixieAttributes.loc.nOffsets = {
    tScreenLocFrom.x,
    tScreenLocFrom.y,
    tScreenLocTo.x,
    tScreenLocTo.y
  }
  if nPixieIdFull then
    _wndOverlay:UpdatePixie(nPixieIdFull, tDraw.tPixieAttributes)
  else
    nPixieIdFull = _wndOverlay:AddPixie(tDraw.tPixieAttributes)
  end
  return nPixieIdFull
end

local function UpdatePixieDots(tDraw, tScreenLocFrom, tScreenLocTo, tVectorFrom, tVectorTo)
  local tVectorPlayer = NewVector3(GetPlayerUnit():GetPosition())
  for i = 1, tDraw.nNumberOfDot do
    local nRatio = (i - 1) / (tDraw.nNumberOfDot - 1)
    local tVectorDot = Vector3.InterpolateLinear(tVectorFrom, tVectorTo, nRatio)
    local tScreenLocDot = WorldLocToScreenPoint(tVectorDot)
    if tScreenLocDot.z > 0 then
      local nDistance2Player = (tVectorPlayer - tVectorDot):Length()
      local nScale = math.min(40 / nDistance2Player, 1)
      nScale = math.max(nScale, 0.5) * tDraw.nSpriteSize
      local tVector = tScreenLocTo - tScreenLocFrom
      tDraw.tPixieAttributes.fRotation = math.deg(math.atan2(tVector.y, tVector.x)) + 90
      tDraw.tPixieAttributes.loc.nOffsets = {
        tScreenLocDot.x - nScale,
        tScreenLocDot.y - nScale,
        tScreenLocDot.x + nScale,
        tScreenLocDot.y + nScale
      }
      if tDraw.nPixieIdDot[i] then
        _wndOverlay:UpdatePixie(tDraw.nPixieIdDot[i], tDraw.tPixieAttributes)
      else
        tDraw.nPixieIdDot[i] = _wndOverlay:AddPixie(tDraw.tPixieAttributes)
      end
    else
      _wndOverlay:DestroyPixie(tDraw.nPixieIdDot[i])
      tDraw.nPixieIdDot[i] = nil
    end
  end
end

local function UpdateLine(tDraw, tVectorFrom, tVectorTo)
  local tScreenLocTo = WorldLocToScreenPoint(tVectorTo)
  local tScreenLocFrom = WorldLocToScreenPoint(tVectorFrom)

  if tScreenLocFrom.z <= 0 and tScreenLocTo.z <= 0 then
    DestroyPixie(tDraw)
    return
  end

  if tDraw.nNumberOfDot == DOT_IS_A_LINE then
    tDraw.nPixieIdFull = UpdatePixie(tDraw, tScreenLocFrom, tScreenLocTo, tDraw.nPixieIdFull)
  else
    UpdatePixieDots(tDraw, tScreenLocTo, tScreenLocFrom, tVectorFrom, tVectorTo)
  end
end

local function RemoveDraw(tDraw)
  assert(type(tDraw) == "table")
  if tDraw.nPixieIdFull then
    _wndOverlay:DestroyPixie(tDraw.nPixieIdFull)
  elseif next(tDraw.nPixieIdDot) then
    for _, nPixieIdDot in next, tDraw.nPixieIdDot do
      _wndOverlay:DestroyPixie(nPixieIdDot)
    end
    tDraw.nPixieIdDot = {}
  end
end

----------------------------------------------------------------------------------------------------
-- Template Class.
----------------------------------------------------------------------------------------------------
function TemplateManager:GetDraw(sKey)
  local tDraw = self.tDraws[sKey]
  if tDraw then
    return BuildPublicDraw(tDraw)
  end
  return nil
end

function TemplateManager:_AddDraw(...)
  if self.tSettings.bEnabled then
    return self:AddDraw(...)
  end
end

function TemplateManager:SaveDraw(tDraw, key, tUnits)
  self.tDraws[key] = tDraw

  if next(tUnits) == nil then return end
  for i = 1, #tUnits do
    local tUnit = tUnits[i]
    local nId = tUnit:GetId()
    table.insert(tDraw.tUnitIds, nId)
    self.tDrawsPerUnit[nId] = self.tDrawsPerUnit[nId] or {}
    self.tDrawsPerUnit[nId][key] = true
  end
end

function TemplateManager:RemoveDrawsPerUnit(tDraw, key)
  for i = 1, #tDraw.tUnitIds do
    local nId = tDraw.tUnitIds[i]
    if self.tDrawsPerUnit[nId] then
      self.tDrawsPerUnit[nId][key] = nil
      if next(self.tDrawsPerUnit[nId]) == nil then
        self.tDrawsPerUnit[nId] = nil
      end
    end
  end
end

function TemplateDraw:SetColor(sColor)
  local mt = getmetatable(self)
  mt.__index.sColor = sColor or DEFAULT_LINE_COLOR
  if mt.__index.tPixieAttributes then
    mt.__index.tPixieAttributes.cr = mt.__index.sColor
  end
end

function TemplateDraw:SetSprite(sSprite, nSize)
  local mt = getmetatable(self)
  mt.__index.sSprite = sSprite or mt.__index.sSprite or "BasicSprites:WhiteCircle"
  mt.__index.nSpriteSize = nSize or mt.__index.nSpriteSize or 4
  if mt.__index.tPixieAttributes and mt.__index.tPixieAttributes.strSprite then
    mt.__index.tPixieAttributes.strSprite = mt.__index.sSprite
  end
end

function TemplateDraw:SetMaxLengthVisible(nMax)
  local mt = getmetatable(self)
  mt.__index.nMaxLengthVisible = nMax
end

function TemplateDraw:SetMinLengthVisible(nMin)
  local mt = getmetatable(self)
  mt.__index.nMinLengthVisible = nMin
end

----------------------------------------------------------------------------------------------------
-- Line between 2 units.
----------------------------------------------------------------------------------------------------
local LineBetween = NewManager("LineBetween")

function LineBetween:UpdateDraw(tDraw)
  local tVectorFrom, tVectorTo = tDraw.tVectorFrom, tDraw.tVectorTo
  if tDraw.tUnitFrom then
    tVectorFrom = NewVector3(tDraw.tUnitFrom:GetPosition())
  end
  if tDraw.tUnitTo then
    tVectorTo = NewVector3(tDraw.tUnitTo:GetPosition())
  end
  if tDraw.nOffset > 0 or tDraw.nLength > 0 then
    local tNormal = (tVectorTo - tVectorFrom):Normal()
    local tVectorA = tNormal * (tDraw.nOffset)
    if tDraw.nLength > 0 then
      local tVectorB = tNormal * (tDraw.nLength + tDraw.nOffset)
      tVectorTo = tVectorFrom + tVectorB
    end
    tVectorFrom = tVectorFrom + tVectorA
  end

  if ShouldDrawBeVisible(tDraw, tVectorFrom, tVectorTo) then
    UpdateLine(tDraw, tVectorFrom, tVectorTo)
  else
    DestroyPixie(tDraw)
  end
end

function LineBetween:AddDraw(Key, FromOrigin, ToOrigin, nWidth, sColor, nNumberOfDot, nOffset, nLength)
  if self.tDraws[Key] then
    -- To complex to manage new definition with nNumberOfDot which change,
    -- simplest to remove previous.
    local bNumberOfDot = nNumberOfDot and self.tDraws[Key].nNumberOfDot ~= nNumberOfDot
    -- The width update for a Pixie don't work. It's a carbine bug.
    local bWidthChanged = nWidth and self.tDraws[Key].nWidth ~= nWidth
    if bNumberOfDot or bWidthChanged then
      self:RemoveDraw(Key)
    end
  end
  -- Get saved object or create a new table.
  local tDraw = self.tDraws[Key] or NewDraw()
  tDraw.nWidth = nWidth or 4.0
  tDraw.sColor = sColor or tDraw.sColor
  tDraw.nNumberOfDot = nNumberOfDot or DOT_IS_A_LINE
  tDraw.nPixieIdDot = tDraw.nPixieIdDot or {}
  tDraw.nOffset = nOffset or 0
  tDraw.nLength = nLength or 0
  tDraw.tPixieAttributes = {
    bLine = tDraw.nNumberOfDot == DOT_IS_A_LINE,
    fWidth = tDraw.nWidth,
    cr = tDraw.sColor,
    loc = {
      fPoints = FPOINT_NULL,
      nOffsets = {}
    }
  }

  if not tDraw.tPixieAttributes.bLine then
    tDraw.tPixieAttributes.strSprite = tDraw.sSprite
    tDraw.tPixieAttributes.fRotation = 0
  end

  local tFromOriginUnit, tFromOriginVector = ProcessOrigin(FromOrigin)
  if tFromOriginVector then
    tDraw.tUnitFrom = nil
    tDraw.tVectorFrom = tFromOriginVector
  elseif tFromOriginUnit then
    tDraw.tUnitFrom = tFromOriginUnit
    tDraw.tVectorFrom = nil
  else
    Assert:Assert(false, "No valid from origin found: %s", tostring(FromOrigin))
  end

  local tToOriginUnit, tToOriginVector = ProcessOrigin(ToOrigin)
  if tToOriginVector then
    tDraw.tUnitTo = nil
    tDraw.tVectorTo = tToOriginVector
  elseif tToOriginUnit then
    tDraw.tUnitTo = tToOriginUnit
    tDraw.tVectorTo = nil
  else
    Assert:Assert(false, "No valid to origin found: %s", tostring(ToOrigin))
  end

  -- Save this object (new or not).
  self:SaveDraw(tDraw, Key, {tFromOriginUnit, tToOriginUnit})
  -- Start the draw update service.
  StartDrawing()
  return BuildPublicDraw(tDraw)
end

function LineBetween:RemoveDraw(Key)
  local tDraw = self.tDraws[Key]
  if tDraw then
    self:RemoveDrawsPerUnit(tDraw, Key)
    RemoveDraw(tDraw)
    self.tDraws[Key] = nil
  end
end

----------------------------------------------------------------------------------------------------
-- Line from a unit.
----------------------------------------------------------------------------------------------------
local SimpleLine = NewManager("SimpleLine")

function SimpleLine:UpdateDraw(tDraw)
  local tVectorTo, tVectorFrom = tDraw.tToVector, tDraw.tFromVector
  if tDraw.tOriginUnit then
    local tOriginVector = NewVector3(tDraw.tOriginUnit:GetPosition())
    local tFacingVector = NewVector3(tDraw.tOriginUnit:GetFacing())
    if tDraw.nOffsetOrigin then
      tOriginVector = tOriginVector + RotationY(tFacingVector, tDraw.RotationMatrix90) * tDraw.nOffsetOrigin
    end
    local tVectorA = tFacingVector * (tDraw.nOffset)
    local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)
    tVectorA = RotationY(tVectorA, tDraw.RotationMatrix)
    tVectorB = RotationY(tVectorB, tDraw.RotationMatrix)
    tVectorFrom = tOriginVector + tVectorA
    tVectorTo = tOriginVector + tVectorB
  end

  UpdateLine(tDraw, tVectorFrom, tVectorTo)
end

function SimpleLine:AddDraw(Key, Origin, nOffset, nLength, nRotation, nWidth, sColor, nNumberOfDot, nOffsetOrigin)
  if self.tDraws[Key] then
    -- To complex to manage new definition with nNumberOfDot which change,
    -- simplest to remove previous.
    local bNumberOfDot = nNumberOfDot and self.tDraws[Key].nNumberOfDot ~= nNumberOfDot
    -- The width update for a Pixie don't work. It's a carbine bug.
    local bWidthChanged = nWidth and self.tDraws[Key].nWidth ~= nWidth
    if bNumberOfDot or bWidthChanged then
      self:RemoveDraw(Key)
    end
  end
  -- Get saved object or create a new table.
  local tDraw = self.tDraws[Key] or NewDraw()
  tDraw.nOffset = nOffset or 0
  tDraw.nLength = nLength or 10
  tDraw.nWidth = nWidth or 4
  tDraw.nRotation = nRotation or 0
  tDraw.sColor = sColor or tDraw.sColor
  tDraw.nNumberOfDot = nNumberOfDot or DOT_IS_A_LINE
  tDraw.nPixieIdDot = tDraw.nPixieIdDot or {}
  tDraw.nOffsetOrigin = nOffsetOrigin or nil
  tDraw.tPixieAttributes = {
    bLine = tDraw.nNumberOfDot == DOT_IS_A_LINE,
    fWidth = tDraw.nWidth,
    cr = tDraw.sColor,
    loc = {
      fPoints = FPOINT_NULL,
      nOffsets = {}
    }
  }

  if not tDraw.tPixieAttributes.bLine then
    tDraw.tPixieAttributes.strSprite = tDraw.sSprite
    tDraw.tPixieAttributes.fRotation = 0
  end

  -- Preprocessing.
  tDraw.RotationMatrix = CreateRotationMatrixY(tDraw.nRotation)
  tDraw.RotationMatrix90 = CreateRotationMatrixY(90)

  local tOriginUnit, tOriginVector = ProcessOrigin(Origin)
  if tOriginVector then
    local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
    local tVectorA = tFacingVector * (tDraw.nOffset)
    local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)
    if tDraw.nOffsetOrigin then
      tOriginVector = tOriginVector + RotationY(tFacingVector, tDraw.RotationMatrix90) * tDraw.nOffsetOrigin
    end
    tVectorA = RotationY(tVectorA, tDraw.RotationMatrix)
    tVectorB = RotationY(tVectorB, tDraw.RotationMatrix)
    tDraw.tOriginUnit = nil
    tDraw.tFromVector = tOriginVector + tVectorA
    tDraw.tToVector = tOriginVector + tVectorB
  elseif tOriginUnit then
    tDraw.tOriginUnit = tOriginUnit
    tDraw.tFromVector = nil
    tDraw.tToVector = nil
  else
    Assert:Assert(false, "No valid origin found: %s", tostring(Origin))
  end
  -- Save this object (new or not).
  self:SaveDraw(tDraw, Key, {tOriginUnit})
  -- Start the draw update service.
  StartDrawing()
  return BuildPublicDraw(tDraw)
end

function SimpleLine:RemoveDraw(Key)
  local tDraw = self.tDraws[Key]
  if tDraw then
    self:RemoveDrawsPerUnit(tDraw, Key)
    RemoveDraw(tDraw)
    self.tDraws[Key] = nil
  end
end

----------------------------------------------------------------------------------------------------
-- Polygon from a unit or Position.
----------------------------------------------------------------------------------------------------
local Polygon = NewManager("Polygon")

function Polygon:UpdateDraw(tDraw)
  local tVectors = tDraw.tVectors
  local tOriginUnit = tDraw.tOriginUnit
  if tOriginUnit then
    local tOriginVector = NewVector3(tOriginUnit:GetPosition())
    local tFacingVector = NewVector3(tOriginUnit:GetFacing())
    local tRefVector = tFacingVector * tDraw.nRadius
    tVectors = {}
    for i = 1, tDraw.nSide do
      local CornerRotate = CreateRotationMatrixY(360 * i / tDraw.nSide + tDraw.nRotation)
      tVectors[i] = tOriginVector + RotationY(tRefVector, CornerRotate)
    end
  end

  -- Convert all 3D coordonate of game in 2D coordonnate of screen
  local tScreenLoc = {}
  for i = 1, tDraw.nSide do
    tScreenLoc[i] = WorldLocToScreenPoint(tVectors[i])
  end
  for i = 1, tDraw.nSide do
    local j = i == tDraw.nSide and 1 or i + 1
    if tScreenLoc[i].z > 0 or tScreenLoc[j].z > 0 then
      tDraw.nPixieIds[i] = UpdatePixie(tDraw, tScreenLoc[i], tScreenLoc[j], tDraw.nPixieIds[i])
    else
      -- The Line is out of sight.
      if tDraw.nPixieIds[i] then
        _wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
        tDraw.nPixieIds[i] = nil
      end
    end
  end
end

function Polygon:AddDraw(Key, Origin, nRadius, nRotation, nWidth, sColor, nSide)
  if self.tDraws[Key] then
    -- To complex to manage new definition with nSide which change,
    -- simplest to remove previous.
    local bSideChanged = nSide and self.tDraws[Key].nSide ~= nSide
    -- The width update for a Pixie don't work. It's a carbine bug.
    local bWidthChanged = nWidth and self.tDraws[Key].nWidth ~= nWidth
    if bSideChanged or bWidthChanged then
      self:RemoveDraw(Key)
    end
  end
  -- Register a new object to manage.
  local tDraw = self.tDraws[Key] or NewDraw()
  tDraw.nRadius = nRadius or 10
  tDraw.nWidth = nWidth or 4
  tDraw.nRotation = nRotation or 0
  tDraw.sColor = sColor or tDraw.sColor
  tDraw.nSide = nSide or 5
  tDraw.nPixieIds = tDraw.nPixieIds or {}
  tDraw.tVectors = tDraw.tVectors or {}
  tDraw.tPixieAttributes = {
    bLine = true,
    fWidth = tDraw.nWidth,
    cr = tDraw.sColor,
    loc = {
      fPoints = FPOINT_NULL,
      nOffsets = {}
    }
  }

  local tOriginUnit, tOriginVector = ProcessOrigin(Origin)
  if tOriginVector then
    tDraw.tOriginUnit = nil
    -- Precomputing coordonate of the polygon with constant origin.
    local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
    local tRefVector = tFacingVector * tDraw.nRadius
    for i = 1, tDraw.nSide do
      local CornerRotate = CreateRotationMatrixY(360 * i / tDraw.nSide + tDraw.nRotation)
      tDraw.tVectors[i] = tOriginVector + RotationY(tRefVector, CornerRotate)
    end
  elseif tOriginUnit then
    tDraw.tOriginUnit = tOriginUnit
  else
    Assert:Assert(false, "No valid origin found: %s", tostring(Origin))
  end

  -- Save this object (new or not).
  self:SaveDraw(tDraw, Key, {tOriginUnit})
  -- Start the draw update service.
  StartDrawing()
  return BuildPublicDraw(tDraw)
end

function Polygon:RemoveDraw(Key)
  local tDraw = self.tDraws[Key]
  if tDraw then
    self:RemoveDrawsPerUnit(tDraw, Key)
    for i = 1, tDraw.nSide do
      if tDraw.nPixieIds[i] then
        _wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
        tDraw.nPixieIds[i] = nil
      end
    end
    self.tDraws[Key] = nil
  end
end

----------------------------------------------------------------------------------------------------
-- Picture from a unit or Position.
----------------------------------------------------------------------------------------------------
local Picture = NewManager("Picture")

function Picture:UpdateDraw(tDraw)
  local tVector = tDraw.tVector
  local tOriginUnit = tDraw.tOriginUnit
  if tOriginUnit then
    local tOriginVector = NewVector3(tOriginUnit:GetPosition())
    local tFacingVector = NewVector3(tOriginUnit:GetFacing())
    local tRefVector = tFacingVector * tDraw.nDistance
    tRefVector = RotationY(tRefVector, tDraw.RotationMatrix)
    tVector = tOriginVector + tRefVector
    tVector.y = tVector.y + tDraw.nHeight
  end

  local tScreenLoc = WorldLocToScreenPoint(tVector)
  if tScreenLoc.z > 0 then
    local tVectorPlayer = NewVector3(GetPlayerUnit():GetPosition())
    local nDistance2Player = (tVectorPlayer - tVector):Length()
    local nScale = math.min(40 / nDistance2Player, 1)
    nScale = math.max(nScale, 0.5) * tDraw.nSpriteSize
    tDraw.tPixieAttributes.loc.nOffsets = {
      tScreenLoc.x - nScale,
      tScreenLoc.y - nScale,
      tScreenLoc.x + nScale,
      tScreenLoc.y + nScale
    }
    if tDraw.nPixieId then
      _wndOverlay:UpdatePixie(tDraw.nPixieId, tDraw.tPixieAttributes)
    else
      tDraw.nPixieId = _wndOverlay:AddPixie(tDraw.tPixieAttributes)
    end
  else
    -- The Line is out of sight.
    if tDraw.nPixieId then
      _wndOverlay:DestroyPixie(tDraw.nPixieId)
      tDraw.nPixieId = nil
    end
  end
end

function Picture:AddDraw(Key, Origin, sSprite, nSpriteSize, nRotation, nDistance, nHeight, sColor)
  local tDraw = self.tDraws[Key] or NewDraw()
  tDraw.sSprite = sSprite or tDraw.sSprite
  tDraw.nRotation = nRotation or 0
  tDraw.nDistance = nDistance or 0
  tDraw.nHeight = nHeight or 0
  tDraw.nSpriteSize = nSpriteSize or 30
  tDraw.sColor = sColor or "white"
  tDraw.tPixieAttributes = {
    bLine = false,
    strSprite = tDraw.sSprite,
    cr = tDraw.sColor,
    loc = {
      fPoints = FPOINT_NULL,
      nOffsets = {}
    }
  }

  if not tDraw.tPixieAttributes.bLine then
    tDraw.tPixieAttributes.strSprite = tDraw.sSprite
    tDraw.tPixieAttributes.fRotation = 0
  end

  -- Preprocessing.
  tDraw.RotationMatrix = CreateRotationMatrixY(tDraw.nRotation)

  local tOriginUnit, tOriginVector = ProcessOrigin(Origin)
  if tOriginVector then
    tDraw.tOriginUnit = nil
    -- Precomputing coordonate of the polygon with constant origin.
    local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
    local tRefVector = tFacingVector * tDraw.nDistance
    if tDraw.RotationMatrix then
      tRefVector = RotationY(tRefVector, tDraw.RotationMatrix)
    end
    tDraw.tVector = tOriginVector + tRefVector
    tDraw.tVector.y = tDraw.tVector.y + tDraw.nHeight
  elseif tOriginUnit then
    tDraw.tOriginUnit = tOriginUnit
    local nRaceId = tOriginUnit and tOriginUnit:GetRaceId()
    if nRaceId and HEIGHT_PER_RACEID[nRaceId] then
      tDraw.nHeight = HEIGHT_PER_RACEID[nRaceId]
    end
  else
    Assert:Assert(false, "No valid origin found: %s", tostring(Origin))
  end
  -- Save this object (new or not).
  self:SaveDraw(tDraw, Key, {tOriginUnit})
  -- Start the draw update service.
  StartDrawing()
  return BuildPublicDraw(tDraw)
end

function Picture:RemoveDraw(Key)
  local tDraw = self.tDraws[Key]
  if tDraw then
    self:RemoveDrawsPerUnit(tDraw, Key)
    if tDraw.nPixieId then
      _wndOverlay:DestroyPixie(tDraw.nPixieId)
      tDraw.nPixieId = nil
    end
    self.tDraws[Key] = nil
  end
end

----------------------------------------------------------------------------------------------------
-- Relations between RaidCore and Draw Manager.
----------------------------------------------------------------------------------------------------
function RaidCore:DrawManagersInit(tSettings)
  _wndOverlay = Apollo.LoadForm(self.xmlDoc, "Overlay", "InWorldHudStratum", self)
  tSettings = tSettings or {}
  for i = 1, _nDrawManagers do
    local tDrawManager = _tDrawManagers[i]
    tDrawManager.tSettings = tSettings[tDrawManager.sManagerName] or {}
  end
end

function RaidCore:GetDrawDefaultSettings()
  return DEFAULT_SETTINGS
end

function RaidCore:OnDrawUpdate(nCurrentTime)
  if not _bDrawManagerRunning then return end

  local nDeltaTime = nCurrentTime - _nPreviousTime
  local nRefreshPeriodMin = 1.0 / self.db.profile.DrawManagers.RefreshFrequencyMax

  if nDeltaTime < nRefreshPeriodMin then return end

  if nRefreshPeriodMin > 0 then
    _nPreviousTime = nCurrentTime - nDeltaTime % nRefreshPeriodMin
  else
    _nPreviousTime = nCurrentTime
  end

  local bIsEmpty = true
  local tDrawsToRemove = {}
  for i = 1, _nDrawManagers do
    local tDrawManager = _tDrawManagers[i]
    local fHandler = tDrawManager.UpdateDraw
    for Key, tDraw in next, tDrawManager.tDraws do
      local s, e = pcall(fHandler, tDrawManager, tDraw)
      if not self:HandlePcallResult(s, e, " - DrawKey: "..Key) then
        table.insert(tDrawsToRemove, {
          tDrawManager = tDrawManager,
          Key = Key,
        })
      end
    end
    if next(tDrawManager.tDraws) then
      bIsEmpty = false
    end
  end
  for i = 1, #tDrawsToRemove do
    local tDrawToRemove = tDrawsToRemove[i]
    tDrawToRemove.tDrawManager:RemoveDraw(tDrawToRemove.Key)
  end
  if bIsEmpty then
    StopDrawing()
  end
end

function RaidCore:ResetLines()
  for i = 1, _nDrawManagers do
    local tDrawManager = _tDrawManagers[i]
    for Key, _ in next, tDrawManager.tDraws do
      tDrawManager:RemoveDraw(Key)
    end
  end
end

function RaidCore:CleanDrawsOnUnitDestroyed(nDestroyedId)
  local tDrawsToRemove = {}
  for i = 1, _nDrawManagers do
    local tDrawManager = _tDrawManagers[i]
    local tDraws = tDrawManager.tDrawsPerUnit[nDestroyedId]
    if tDraws and next(tDraws) ~= nil then
      for Key, _ in next, tDraws do
        table.insert(tDrawsToRemove, {
          tDrawManager = tDrawManager,
          Key = Key,
        })
      end
    end
  end
  for i = 1, #tDrawsToRemove do
    local tDrawToRemove = tDrawsToRemove[i]
    tDrawToRemove.tDrawManager:RemoveDraw(tDrawToRemove.Key)
  end
end

----------------------------------------------------------------------------------------------------
-- API to use in encounters.
----------------------------------------------------------------------------------------------------
function RaidCore:AddLineBetweenUnits(...)
  return LineBetween:_AddDraw(...)
end

function RaidCore:GetLineBetweenUnits(...)
  return LineBetween:GetDraw(...)
end

function RaidCore:RemoveLineBetweenUnits(...)
  LineBetween:RemoveDraw(...)
end

function RaidCore:AddSimpleLine(...)
  return SimpleLine:_AddDraw(...)
end

function RaidCore:GetSimpleLine(...)
  return SimpleLine:GetDraw(...)
end

function RaidCore:RemoveSimpleLine(...)
  SimpleLine:RemoveDraw(...)
end

function RaidCore:AddPolygon(...)
  return Polygon:_AddDraw(...)
end

function RaidCore:GetPolygon(...)
  return Polygon:GetDraw(...)
end

function RaidCore:RemovePolygon(...)
  Polygon:RemoveDraw(...)
end

function RaidCore:AddPicture(...)
  return Picture:_AddDraw(...)
end

function RaidCore:GetPicture(...)
  return Picture:GetDraw(...)
end

function RaidCore:RemovePicture(...)
  Picture:RemoveDraw(...)
end
