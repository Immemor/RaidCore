require "Window"
require "GameLib"
require "GroupLib"
require "Vector3"

local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local math = math
local tonumber = tonumber
local string = string
local Print = Print
local select = select
local CColor = CColor
local GameLib = GameLib
local GroupLib = GroupLib
local Apollo = Apollo
local ApolloColor = ApolloColor
local Vector3 = Vector3

local GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage

local tOverlayDef = {
  AnchorOffsets = { 0, 1, 0, 1 },
  AnchorPoints = { 0, 0, 1, 1 },
  Class = "WorldFixedWindow",
  RelativeToClient = true,
  BGColor = "UI_WindowBGDefault",
  TextColor = "UI_WindowTextDefault",
  Name = "RaidCoreOverlay",
  SwallowMouseClicks = true,
  IgnoreMouse = true,
  Overlapped = false,
}

local tPixieLocPoints = { 0, 0, 0, 0 }


local ColorStringToHex = {
  Blue = "FF0000ff",
  Green = "FF00ff00",
  Yellow = "FFff9933",
  Red = "FFDC143C",
}

local DisplayLine = {} 
local addon = DisplayLine

DisplayLine.__index = DisplayLine

setmetatable(DisplayLine, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function DisplayLine.new(xmlDoc)
    local self = setmetatable({}, DisplayLine)

    self.xmlDoc = xmlDoc
    self.tDB = {}
    self.tDB.nAlpha = 1
    self.tDB.nDPL = 20

    self.markers = {}
    self.setup = {}

    self.pixie = {}

    self.wOverlay = GeminiGUI:Create("WorldFixedWindow", tOverlayDef):GetInstance()
    self.wOverlay:Show(false)

    return self
end


local function hexToCColor(color, a)
  if not a then a = 1 end
  local r = tonumber(string.sub(color,1,2), 16) / 255
  local g = tonumber(string.sub(color,3,4), 16) / 255
  local b = tonumber(string.sub(color,5,6), 16) / 255
  return CColor.new(r,g,b,a)
end

local function colorGradient(perc, ...)
  if perc >= 1 then
    local r, g, b = select(select("#", ...) - 2, ...)
    return r, g, b
  elseif perc <= 0 then
    local r, g, b = ...
    return r, g, b
  end
  local num = select("#", ...) / 3
  local segment, relperc = math.modf(perc*(num-1))
  local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)
  return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

function addon:SetupMarks(key, colorSetting)
  if not self.markers[key] then
    --Print("Creating Line " .. key)
    self.markers[key] = {}

    local color
    if colorSetting == 1 then
      color = hexToCColor("00ff00", self.tDB.nAlpha)
    elseif colorSetting == 2 then
      color = hexToCColor("ff9933", self.tDB.nAlpha)
    elseif colorSetting == 3 then
      color = hexToCColor("0000ff", self.tDB.nAlpha)
    end

    for i = 1, self.setup[key].nDPL do
      --Print("Creating Point " .. i .. " for " .. key)
      self.markers[key][i] = Apollo.LoadForm(self.xmlDoc, "Marker", "InWorldHudStratum", self)
      self.markers[key][i]:Show(true)
      self.markers[key][i]:SetBGColor(color)
    end
  end
end

function addon:DestroyMarks(key)
  if self.markers[key] then
    for i = 1, #self.markers[key] do
      self.markers[key][i]:Destroy()
    end
    --Print("Destroying Line " .. key)
    self.markers[key] = nil
  end
end

function addon:DestroyAllMarks()
    for k, v in pairs(self.markers) do
        self:DestroyMarks(k)
    end
end

function addon:AddLine(key, type, uStart, uTarget, color, distance, rotation, nDPL)
  if not self.setup[key] then
    --Print("adding " .. key)
      self.setup[key] = {}
      self.setup[key].type = type
      self.setup[key].uStart = uStart
      self.setup[key].uTarget = uTarget
      self.setup[key].color = color
      self.setup[key].distance = distance
      self.setup[key].rotation = rotation
      self.setup[key].nDPL = nDPL or 20
      self:StartDrawing()
  end
end

function addon:AddPixie(key, type, uStart, uTarget, color, width, distance, rotation, heading)
  if not self.pixie[key] then
    --Print("adding " .. key)
      --if not self.wOverlay then
      --    self.wOverlay = GeminiGUI:Create("WorldFixedWindow", tOverlayDef):GetInstance()
      --    self.wOverlay:Show(false)
      --end
      self.pixie[key] = {}
      self.pixie[key].type = type
      self.pixie[key].uStart = uStart
      self.pixie[key].uTarget = uTarget
      self.pixie[key].color = color
      self.pixie[key].width = width or 5
      self.pixie[key].distance = distance
      self.pixie[key].rotation = rotation
      self.pixie[key].heading = heading or 0
      self:StartDrawing()
  end
end

function addon:DropLine(key)
  if self.setup[key] then
      --Print("Destroying Line : " .. key)
      self:DestroyMarks(key)
      self.setup[key] = nil
  end
end

function addon:DropPixie(key)
  if self.pixie[key] then
      --Print("Destroying Line : " .. key)
      self.pixie[key] = nil
  end
end

function addon:ResetLines()
    for k, v in pairs(self.setup) do
        self:DropLine(k)
    end
    for k, v in pairs(self.pixie) do
        self:DropPixie(k)
    end
    self:StopDrawing()
    self.wOverlay:DestroyAllPixies()
end

function addon:StartDrawing()
    self.wOverlay:Show(true)
    Apollo.RegisterEventHandler("NextFrame",                    "OnUpdate", self)
    --Apollo.RegisterEventHandler("UnitDestroyed",                "OnUnitDestroyed", self)
end

function addon:StopDrawing()
  self.wOverlay:Show(false)
  Apollo.RemoveEventHandler("NextFrame", self)
  --Apollo.RemoveEventHandler("UnitDestroyed", self)
end



function addon:DrawLine(key, vectorStart, vectorEnd, colorSetting)
    if not self.markers[key] then self:SetupMarks(key, colorSetting) end

--[[
    local color
    if colorSetting == 1 then
      color = hexToCColor("00ff00", self.tDB.nAlpha)
    elseif colorSetting == 2 then
      color = hexToCColor("ff9933", self.tDB.nAlpha)
    elseif colorSetting == 3 then
      color = hexToCColor("0000ff", self.tDB.nAlpha)
    end
]]--
    if not Vector3.Is(vectorStart) then
      vectorStart = Vector3.New(vectorStart.x, vectorStart.y, vectorStart.z)
    end

     if not Vector3.Is(vectorEnd) then
      vectorEnd = Vector3.New(vectorEnd.x, vectorEnd.y, vectorEnd.z)
    end   

    for i = 1, #self.markers[key] do
      --self.markers[key][i]:Show(true)
      --self.markers[key][i]:SetBGColor(color)
      self.markers[key][i]:SetWorldLocation(Vector3.InterpolateLinear(vectorStart, vectorEnd, (1/#self.markers[key]) * i))
    end
end

function addon:DrawPixie(vectorStart, vectorEnd, color, width)

    local hexColor = ColorStringToHex[color]

    if not Vector3.Is(vectorStart) then
      vectorStart = Vector3.New(vectorStart.x, vectorStart.y, vectorStart.z)
    end

    if not Vector3.Is(vectorEnd) then
      vectorEnd = Vector3.New(vectorEnd.x, vectorEnd.y, vectorEnd.z)
    end   

    local scrStart = GameLib.WorldLocToScreenPoint(vectorStart)
    local scrEnd = GameLib.WorldLocToScreenPoint(vectorEnd)

    --Print("DRAW : " .. hexColor .. " " .. width)

    self.wOverlay:AddPixie( { bLine = true, fWidth = width, cr = hexColor, loc = { fPoints = tPixieLocPoints, nOffsets = { scrStart.x, scrStart.y, scrEnd.x, scrEnd.y }}} )
end


function addon:Heading(unit)
  if unit and not unit:IsDead() then
    local unitHeading = unit:GetHeading()
    if unitHeading < 0 then
      unitHeading = unitHeading * -1
    else
      unitHeading = 2 * math.pi - unitHeading
    end
    return unitHeading + 3 * math.pi / 2
  end
end

function addon:OnUpdate()
    local uPlayer = GameLib.GetPlayerUnit()
    if not uPlayer then return end 
    local uTarget  

    self.wOverlay:DestroyAllPixies()
    --Print("OnUpdate")

    for k, v in pairs(self.setup) do
      if v.type == 1 then
          if v.uStart and v.uTarget and not v.uStart:IsDead() and not v.uTarget:IsDead() then
            local pStart = v.uStart:GetPosition()
            local pTarget = v.uTarget:GetPosition()
            self:DrawLine(k, pStart, pTarget, v.color)
          else
            self:DropLine(k)
          end
      elseif v.type == 2 then
          if v.uStart and not v.uStart:IsDead() then
            local pStart = v.uStart:GetPosition()
            local vectorStart = Vector3.New(pStart.x, pStart.y, pStart.z)
            local rotation = self:Heading(v.uStart) + v.rotation/180 * math.pi
            local vectorEnd = vectorStart + Vector3.New(v.distance * math.cos(rotation), 0, v.distance * math.sin(rotation)) 
            self:DrawLine(k, vectorStart, vectorEnd, v.color)
          else
            self:DropLine(k)
          end            
      end 
    end

    for k, v in pairs(self.pixie) do
      if v.type == 1 then
          if v.uStart and v.uTarget and not v.uStart:IsDead() and not v.uTarget:IsDead() then
            local pStart = v.uStart:GetPosition()
            local pTarget = v.uTarget:GetPosition()
            self:DrawPixie(pStart, pTarget, v.color, v.width)
          else
            self:DropPixie(k)
          end
      elseif v.type == 2 then
          --Print("UPD : " .. k)
          if v.uStart and not v.uStart:IsDead() then
            local pStart = v.uStart:GetPosition()
            local vectorStart = Vector3.New(pStart.x, pStart.y, pStart.z)
            local rotation = self:Heading(v.uStart) + v.rotation/180 * math.pi
            local vectorEnd = vectorStart + Vector3.New(v.distance * math.cos(rotation), v.heading, v.distance * math.sin(rotation)) 
            self:DrawPixie(vectorStart, vectorEnd, v.color, v.width)
          else
            self:DropPixie(k)
          end            
      end 
    end

end


--[[
function addon:DistanceBetweenTwo3DPoints(vector1, vector2)
  return math.sqrt(math.pow(vector2.x-vector1.x, 2)+math.pow(vector2.y-vector1.y, 2)+math.pow(vector2.z-vector1.z, 2))
end


function addon:CacheMarkerOffsets()
  for i = 0, 20 do
    self.marker[i]:SetData(Vector3.New(
      self.distance * math.cos(((2 * math.pi) / 20) * i),
      0,
      self.distance * math.sin(((2 * math.pi) / 20) * i)))
  end
end

function addon:CalculateRotation(target, player)
  return self:OffsetPlayerHeading(math.atan2(target.z - player.z, target.x - player.x))
end

function addon:UpdateRotation()
  self.updateRotation = true
end

function addon:OffsetPlayerHeading(rotation)
  --local playerHeading = GameLib.GetPlayerUnit():GetHeading()
  local playerHeading = self.tracked:GetHeading()
  if playerHeading < 0 then
    playerHeading = playerHeading * -1
  else
    playerHeading = 2 * math.pi - playerHeading
  end
  return math.deg(rotation - playerHeading) + 90
end

function addon:DrawCircleAround(playerVec, targetVec)
  local totalDistance = (playerVec - targetVec):Length()
  
  for i = 0, 20 do
    local pos = targetVec + self.marker[i]:GetData()

    self.marker[i]:SetWorldLocation(pos)
    if not self.marker[i]:IsOnScreen() then
      self.marker[i]:Show(false, true)
    else
      self.marker[i]:Show(true, true)
      self.marker[i]:SetBGColor(self.bgColor)
      if self.updateRotation then
        self.marker[i]:SetRotation(self:CalculateRotation(targetVec, pos))
      end
    end
  end
  self.updateRotation = false
end

function addon:CalculateAngle(nX, nZ)
  return math.atan2(nX, -nZ)
end

function addon:CalculateDistanceAndXZDeltaBetweenPositions2D(tPosition1, tPosition2)
  if not tPosition1 or not tPosition2 then
    return
  end
  
  local nDeltaX = tPosition2.x - tPosition1.x
  local nDeltaZ = tPosition2.z - tPosition1.z
  return math.sqrt(math.pow(nDeltaX, 2) + math.pow(nDeltaZ, 2)), nDeltaX, nDeltaZ
end

function addon:CalculateDistanceBetweenPositions2D(tPosition1, tPosition2)
  if not tPosition1 or not tPosition2 then
    return
  end
  
  local nDistance, nDeltaX, nDeltaZ = self:CalculateDistanceAndXZDeltaBetweenPositions2D(tPosition1, tPosition2)
  return nDistance
end
  
function addon:GetVectorBetweenPositions2D(tPosition1, tPosition2)  
  if not tPosition1 or not tPosition2 then
    return
  end

  local nDistance, nDeltaX, nDeltaZ = self:CalculateDistanceAndXZDeltaBetweenPositions2D(tPosition1, tPosition2)
  return nDistance, self:CalculateAngle(nDeltaX, nDeltaZ)     
end


function addon:GetAngle(playerVec, targetVec)
    local nDistance, nAngle = self:GetVectorBetweenPositions2D(tPlayerPosition, tTrackedPlayerPosition)

    local nPlayerFacingAngle = unitPlayer:GetHeading()
    if nPlayerFacingAngle < 0 then
      nPlayerFacingAngle = nPlayerFacingAngle * -1
    else
      nPlayerFacingAngle = 2 * math.pi - nPlayerFacingAngle
    end

    local nArrowFacingAngle = nAngle - nPlayerFacingAngle

    -- calculate new window-position
    local nPositionHorizontal = math.sin(nArrowFacingAngle) * self.nArrowPosition * 4
    local nPositionVertical = -math.cos(nArrowFacingAngle) * self.nArrowPosition * 4
    local nOffsetRigt = nPositionHorizontal + 75
    local nOffsetLeft = nPositionHorizontal - 75
    local nOffsetTop = nPositionVertical
    local nOffsetBottom = nPositionVertical + 150
    
    -- set rotation and position
    --oArrow:FindChild("Arrow"):SetRotation((nArrowFacingAngle * (180 / math.pi)) + self.aArrowStyles[self.nArrowStyle].degreesOffset)
    --oArrow:SetAnchorOffsets(nOffsetLeft, nOffsetTop, nOffsetRigt, nOffsetBottom)
end
 --  x(t) = r * cos(t) + j       
 --  y(t) = r * sin(t) + k


]]--


if _G["RaidCoreLibs"] == nil then
    _G["RaidCoreLibs"] = { }
end
_G["RaidCoreLibs"]["DisplayLine"] = DisplayLine
