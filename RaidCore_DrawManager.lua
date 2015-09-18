----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--  Description:
--
--  Draw Manager will manage many type of graphic objects:
--   * Line between two unit,
--   * Line from 1 unit or a specific position,
--   * Polygon attached to an unit or a specific position,
--   * Sprite attached to an unit or a specific position,
--
--   FeedBack:
--    The GameLib.GetUnitScreenPosition API function return wrong values when Unit is out of screen.
--
----------------------------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "GroupLib"
require "Vector3"

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local next, pcall, assert = next, pcall, assert
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById
local WorldLocToScreenPoint = GameLib.WorldLocToScreenPoint
local Races = GameLib.CodeEnumRace
local Vector3 = Vector3
local NewVector3 = Vector3.New
local math = math

----------------------------------------------------------------------------------------------------
-- local data.
----------------------------------------------------------------------------------------------------
local _nPreviousTime = 0
local _wndOverlay = nil
local _tDrawManagers = {}
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
    }
    return setmetatable(new, TEMPLATE_DRAW_META)
end

local function BuildPublicDraw(t)
    -- Create an empty metatable, with a write protection.
    local mt = {
        __index = t,
        __newindex = function(t, k, v)
            error("Attempt to update a read-only graphical object", 2)
        end
    }
    -- Create a proxy table, which will be the public interface.
    return setmetatable({}, mt)
end

local function NewManager(sText)
    local new = setmetatable({}, TEMPLATE_MANAGER_META)
    new.sManagerName = sText
    new.tDraws = {}
    table.insert(_tDrawManagers, new)
    return new
end

local function Rotation(tVector, tMatrixTeta)
    local r = {}
    for axis1, R in next, tMatrixTeta do
        r[axis1] = tVector.x * R.x + tVector.y * R.y + tVector.z * R.z
    end
    return NewVector3(r)
end


local function StartDrawing()
    if _bDrawManagerRunning ~= true then
        _bDrawManagerRunning = true
        Apollo.RegisterEventHandler("NextFrame", "OnDrawUpdate", RaidCore)
    end
end

local function StopDrawing()
    if _bDrawManagerRunning == true then
        _bDrawManagerRunning = false
        Apollo.RemoveEventHandler("NextFrame", RaidCore)
    end
end

local function UpdateLine(tDraw, tVectorFrom, tVectorTo)
    local tScreenLocTo, tScreenLocFrom = nil, nil
    if tVectorFrom and tVectorTo then
        local bShouldBeVisible = true
        if tDraw.nMaxLengthVisible or tDraw.nMinLengthVisible then
            local len = (tVectorTo - tVectorFrom):Length()
            if tDraw.nMaxLengthVisible and tDraw.nMaxLengthVisible < len then
                bShouldBeVisible = false
            elseif tDraw.nMinLengthVisible and tDraw.nMinLengthVisible > len then
                bShouldBeVisible = false
            end
        end
        if bShouldBeVisible then
            tScreenLocTo = WorldLocToScreenPoint(tVectorTo)
            tScreenLocFrom = WorldLocToScreenPoint(tVectorFrom)
        end
    end
    if tScreenLocFrom and tScreenLocTo and (tScreenLocFrom.z > 0 or tScreenLocTo.z > 0) then
        if tDraw.nNumberOfDot == DOT_IS_A_LINE then
            local tPixieAttributs = {
                bLine = true,
                fWidth = tDraw.nWidth,
                cr = tDraw.sColor,
                loc = {
                    fPoints = FPOINT_NULL,
                    nOffsets = {
                        tScreenLocFrom.x,
                        tScreenLocFrom.y,
                        tScreenLocTo.x,
                        tScreenLocTo.y,
                    },
                },
            }
            if tDraw.nPixieIdFull then
                _wndOverlay:UpdatePixie(tDraw.nPixieIdFull, tPixieAttributs)
            else
                tDraw.nPixieIdFull = _wndOverlay:AddPixie(tPixieAttributs)
            end
        else
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
                    local tPixieAttributs = {
                        bLine = false,
                        strSprite = tDraw.sSprite,
                        cr = tDraw.sColor,
                        fRotation = math.deg(math.atan2(tVector.y, tVector.x)) + 90,
                        loc = {
                            fPoints = FPOINT_NULL,
                            nOffsets = {
                                tScreenLocDot.x - nScale,
                                tScreenLocDot.y - nScale ,
                                tScreenLocDot.x + nScale,
                                tScreenLocDot.y + nScale,
                            },
                        },
                    }
                    if tDraw.nPixieIdDot[i] then
                        _wndOverlay:UpdatePixie(tDraw.nPixieIdDot[i], tPixieAttributs)
                    else
                        tDraw.nPixieIdDot[i] = _wndOverlay:AddPixie(tPixieAttributs)
                    end
                else
                    _wndOverlay:DestroyPixie(tDraw.nPixieIdDot[i])
                    tDraw.nPixieIdDot[i] = nil
                end
            end
        end
    else
        -- Remove the pixie if:
        --  * At least one unit is not available.
        --  * The Line is out of sight.
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

function TemplateDraw:SetColor(sColor)
    local mt = getmetatable(self)
    mt.__index.sColor = sColor or DEFAULT_LINE_COLOR
end

function TemplateDraw:SetSprite(sSprite, nSize)
    local mt = getmetatable(self)
    mt.__index.sSprite = sSprite or mt.__index.sSprite or "BasicSprites:WhiteCircle"
    mt.__index.nSpriteSize = nSize or mt.__index.nSpriteSize or 4
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
    local tVectorFrom, tVectorTo = nil, nil
    if tDraw.nIdFrom then
        local tUnitFrom = GetUnitById(tDraw.nIdFrom)
        if tUnitFrom and tUnitFrom:IsValid() then
            tVectorFrom = NewVector3(tUnitFrom:GetPosition())
        end
    else
        tVectorFrom = tDraw.tVectorFrom
    end
    if tDraw.nIdTo then
        local tUnitTo = GetUnitById(tDraw.nIdTo)
        if tUnitTo and tUnitTo:IsValid() then
            tVectorTo = NewVector3(tUnitTo:GetPosition())
        end
    else
        tVectorTo = tDraw.tVectorTo
    end

    UpdateLine(tDraw, tVectorFrom, tVectorTo)
end

function LineBetween:AddDraw(Key, FromOrigin, ToOrigin, nWidth, sColor, nNumberOfDot)
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
    -- Preprocessing of the 'From'.
    if type(FromOrigin) == "number" then
        -- FromOrigin is the Id of an unit.
        tDraw.nIdFrom = FromOrigin
        tDraw.tVectorFrom = nil
    else
        -- FromOrigin is the result of a GetPosition()
        tDraw.nIdFrom = nil
        tDraw.tVectorFrom = NewVector3(FromOrigin)
    end
    -- Preprocessing of the 'To'.
    if type(ToOrigin) == "number" then
        -- ToOrigin is the Id of an unit.
        tDraw.nIdTo = ToOrigin
        tDraw.tVectorTo = nil
    else
        -- ToOrigin is the result of a GetPosition()
        tDraw.nIdTo = nil
        tDraw.tVectorTo = NewVector3(ToOrigin)
    end
    -- Save this object (new or not).
    self.tDraws[Key] = tDraw
    -- Start the draw update service.
    StartDrawing()
    return BuildPublicDraw(tDraw)
end

function LineBetween:RemoveDraw(Key)
    local tDraw = self.tDraws[Key]
    if tDraw then
        RemoveDraw(tDraw)
        self.tDraws[Key] = nil
    end
end

----------------------------------------------------------------------------------------------------
-- Line from a unit.
----------------------------------------------------------------------------------------------------
local SimpleLine = NewManager("SimpleLine")

function SimpleLine:UpdateDraw(tDraw)
    local tVectorTo, tVectorFrom = nil, nil
    if tDraw.nOriginId then
        local tOriginUnit = GetUnitById(tDraw.nOriginId)
        if tOriginUnit and tOriginUnit:IsValid() then
            local tOriginVector = NewVector3(tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tOriginUnit:GetFacing())
            local tVectorA = tFacingVector * (tDraw.nOffset)
            local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)
            tVectorA = Rotation(tVectorA, tDraw.RotationMatrix)
            tVectorB = Rotation(tVectorB, tDraw.RotationMatrix)
            tVectorFrom = tOriginVector + tVectorA
            tVectorTo = tOriginVector + tVectorB
        end
    else
        tVectorTo = tDraw.tToVector
        tVectorFrom = tDraw.tFromVector
    end

    UpdateLine(tDraw, tVectorFrom, tVectorTo)
end

function SimpleLine:AddDraw(Key, Origin, nOffset, nLength, nRotation, nWidth, sColor, nNumberOfDot)
    local OriginType = type(Origin)
    assert(OriginType == "number" or OriginType == "table" or OriginType == "userdata")

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
    tDraw.sColor = sColor or tDraw.sColor
    tDraw.nNumberOfDot = nNumberOfDot or DOT_IS_A_LINE
    tDraw.nPixieIdDot = tDraw.nPixieIdDot or {}
    -- Preprocessing.
    local nRad = math.rad(nRotation or 0)
    local nCos = math.cos(nRad)
    local nSin = math.sin(nRad)
    tDraw.RotationMatrix = {
        x = NewVector3({ nCos, 0, -nSin }),
        y = NewVector3({ 0, 1, 0 }),
        z = NewVector3({ nSin, 0, nCos }),
    }
    if OriginType == "number" then
        -- Origin is the Id of an unit.
        tDraw.nOriginId = Origin
        tDraw.tFromVector = nil
        tDraw.tToVector = nil
    else
        -- Origin is the result of a GetPosition()
        local tOriginVector = NewVector3(Origin)
        local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
        local tVectorA = tFacingVector * (tDraw.nOffset)
        local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)
        tVectorA = Rotation(tVectorA, tDraw.RotationMatrix)
        tVectorB = Rotation(tVectorB, tDraw.RotationMatrix)
        tDraw.nOriginId = nil
        tDraw.tFromVector = tOriginVector + tVectorA
        tDraw.tToVector = tOriginVector + tVectorB
    end
    -- Save this object (new or not).
    self.tDraws[Key] = tDraw
    -- Start the draw update service.
    StartDrawing()
    return BuildPublicDraw(tDraw)
end

function SimpleLine:RemoveDraw(Key)
    local tDraw = self.tDraws[Key]
    if tDraw then
        RemoveDraw(tDraw)
        self.tDraws[Key] = nil
    end
end

----------------------------------------------------------------------------------------------------
-- Polygon from a unit or Position.
----------------------------------------------------------------------------------------------------
local Polygon = NewManager("Polygon")

function Polygon:UpdateDraw(tDraw)
    local tVectors = nil
    if tDraw.nOriginId then
        local tOriginUnit = GetUnitById(tDraw.nOriginId)
        if tOriginUnit and tOriginUnit:IsValid() then
            local tOriginVector = NewVector3(tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tOriginUnit:GetFacing())
            local tRefVector = tFacingVector * tDraw.nRadius
            tVectors = {}
            for i = 1, tDraw.nSide do
                local nRad = math.rad(360 * i / tDraw.nSide + tDraw.nRotation)
                local nCos = math.cos(nRad)
                local nSin = math.sin(nRad)
                local CornerRotate = {
                    x = NewVector3({ nCos, 0, -nSin }),
                    y = NewVector3({ 0, 1, 0 }),
                    z = NewVector3({ nSin, 0, nCos }),
                }
                tVectors[i] = tOriginVector + Rotation(tRefVector, CornerRotate)
            end
        end
    else
        tVectors = tDraw.tVectors
    end
    if tVectors then
        -- Convert all 3D coordonate of game in 2D coordonnate of screen
        local tScreenLoc = {}
        for i = 1, tDraw.nSide do
            tScreenLoc[i] = WorldLocToScreenPoint(tVectors[i])
        end
        for i = 1, tDraw.nSide do
            local j = i == tDraw.nSide and 1 or i + 1
            if tScreenLoc[i].z > 0 or tScreenLoc[j].z > 0 then
                local tPixieAttributs = {
                    bLine = true,
                    fWidth = tDraw.nWidth,
                    cr = tDraw.sColor,
                    loc = {
                        fPoints = FPOINT_NULL,
                        nOffsets = {
                            tScreenLoc[i].x,
                            tScreenLoc[i].y,
                            tScreenLoc[j].x,
                            tScreenLoc[j].y,
                        },
                    },
                }
                if tDraw.nPixieIds[i] then
                    _wndOverlay:UpdatePixie(tDraw.nPixieIds[i], tPixieAttributs)
                else
                    tDraw.nPixieIds[i] = _wndOverlay:AddPixie(tPixieAttributs)
                end
            else
                -- The Line is out of sight.
                if tDraw.nPixieIds[i] then
                    _wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
                    tDraw.nPixieIds[i] = nil
                end
            end
        end
    else
        -- Unit is not valid.
        for i = 1, tDraw.nSide do
            if tDraw.nPixieIds[i] then
                _wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
                tDraw.nPixieIds[i] = nil
            end
        end
    end
end

function Polygon:AddDraw(Key, Origin, nRadius, nRotation, nWidth, sColor, nSide)
    local OriginType = type(Origin)
    assert(OriginType == "number" or OriginType == "table" or OriginType == "userdata")

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

    if OriginType == "number" then
        -- Origin is the Id of an unit.
        tDraw.nOriginId = Origin
    else
        -- Origin is the result of a GetPosition()
        tDraw.nOriginId = nil
        -- Precomputing coordonate of the polygon with constant origin.
        local tOriginVector = NewVector3(Origin)
        local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
        local tRefVector = tFacingVector * tDraw.nRadius
        for i = 1, tDraw.nSide do
            local nRad = math.rad(360 * i / tDraw.nSide + tDraw.nRotation)
            local nCos = math.cos(nRad)
            local nSin = math.sin(nRad)
            local CornerRotate = {
                x = NewVector3({ nCos, 0, -nSin }),
                y = NewVector3({ 0, 1, 0 }),
                z = NewVector3({ nSin, 0, nCos }),
            }
            tDraw.tVectors[i] = tOriginVector + Rotation(tRefVector, CornerRotate)
        end
    end
    -- Save this object (new or not).
    self.tDraws[Key] = tDraw
    -- Start the draw update service.
    StartDrawing()
    return BuildPublicDraw(tDraw)
end

function Polygon:RemoveDraw(Key)
    local tDraw = self.tDraws[Key]
    if tDraw then
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
    local tVector = nil
    if tDraw.nOriginId then
        local tOriginUnit = GetUnitById(tDraw.nOriginId)
        if tOriginUnit and tOriginUnit:IsValid() then
            local tOriginVector = NewVector3(tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tOriginUnit:GetFacing())
            local tRefVector = tFacingVector * tDraw.nDistance
            tVector = tOriginVector + Rotation(tRefVector, tDraw.RotationMatrix)
            tVector.y = tVector.y + tDraw.nHeight
        end
    else
        tVector = tDraw.tVector
    end
    if tVector then
        -- Convert the 3D coordonate of game in 2D coordonnate of screen
        local tScreenLoc = WorldLocToScreenPoint(tVector)
        if tScreenLoc.z > 0 then
            local tVectorPlayer = NewVector3(GetPlayerUnit():GetPosition())
            local nDistance2Player = (tVectorPlayer - tVector):Length()
            local nScale = math.min(40 / nDistance2Player, 1)
            nScale = math.max(nScale, 0.5) * tDraw.nSpriteSize
            local tPixieAttributs = {
                bLine = false,
                strSprite = tDraw.sSprite,
                cr = tDraw.sColor,
                loc = {
                    fPoints = FPOINT_NULL,
                    nOffsets = {
                        tScreenLoc.x - nScale,
                        tScreenLoc.y - nScale,
                        tScreenLoc.x + nScale,
                        tScreenLoc.y + nScale,
                    },
                },
            }
            if tDraw.nPixieId then
                _wndOverlay:UpdatePixie(tDraw.nPixieId, tPixieAttributs)
            else
                tDraw.nPixieId = _wndOverlay:AddPixie(tPixieAttributs)
            end
        else
            -- The Line is out of sight.
            if tDraw.nPixieId then
                _wndOverlay:DestroyPixie(tDraw.nPixieId)
                tDraw.nPixieId = nil
            end
        end
    end
end

function Picture:AddDraw(Key, Origin, sSprite, nSpriteSize, nRotation, nDistance, nHeight, sColor)
    local OriginType = type(Origin)
    assert(OriginType == "number" or OriginType == "table" or OriginType == "userdata")

    -- Register a new object to manage.
    local tDraw = self.tDraws[Key] or NewDraw()
    tDraw.sSprite = sSprite or tDraw.sSprite
    tDraw.nRotation = nRotation or 0
    tDraw.nDistance = nDistance or 0
    tDraw.nHeight = nHeight or 0
    tDraw.nSpriteSize = nSpriteSize or 30
    tDraw.sColor = sColor or "white"
    -- Preprocessing.
    local nRad = math.rad(tDraw.nRotation or 0)
    local nCos = math.cos(nRad)
    local nSin = math.sin(nRad)
    tDraw.RotationMatrix = {
        x = NewVector3({ nCos, 0, -nSin }),
        y = NewVector3({ 0, 1, 0 }),
        z = NewVector3({ nSin, 0, nCos }),
    }

    if OriginType == "number" then
        -- Origin is the Id of an unit.
        tDraw.nOriginId = Origin
        local tUnit = GetUnitById(Origin)
        local nRaceId = tUnit and tUnit:GetRaceId()
        if nRaceId and HEIGHT_PER_RACEID[nRaceId] then
            tDraw.nHeight = HEIGHT_PER_RACEID[nRaceId]
        end
    else
        -- Origin is the result of a GetPosition()
        tDraw.nOriginId = nil
        -- Precomputing coordonate of the polygon with constant origin.
        local tOriginVector = NewVector3(Origin)
        local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
        local tRefVector = tFacingVector * tDraw.nDistance
        tDraw.tVector = tOriginVector + Rotation(tRefVector, tDraw.RotationMatrix)
        tDraw.tVector.y = tDraw.tVector.y + tDraw.nHeight
    end
    -- Save this object (new or not).
    self.tDraws[Key] = tDraw
    -- Start the draw update service.
    StartDrawing()
    return BuildPublicDraw(tDraw)
end

function Picture:RemoveDraw(Key)
    local tDraw = self.tDraws[Key]
    if tDraw then
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
    _wndOverlay = Apollo.LoadForm(self.xmlDoc, "Overlay", "InWorldHudStratum", tClass)
    tSettings = tSettings or {}
    for _, tDrawManager in next, _tDrawManagers do
        tDrawManager.tSettings = tSettings[tDrawManager.sManagerName] or {}
    end
end

function RaidCore:GetDrawDefaultSettings()
    return DEFAULT_SETTINGS
end

function RaidCore:OnDrawUpdate()
    local nCurrentTime = GetGameTime()
    local nDeltaTime = nCurrentTime - _nPreviousTime
    local nRefreshPeriodMin = 1.0 / self.db.profile.DrawManagers.RefreshFrequencyMax

    if nDeltaTime >= nRefreshPeriodMin then
        if nRefreshPeriodMin > 0 then
            _nPreviousTime = nCurrentTime - nDeltaTime % nRefreshPeriodMin
        else
            _nPreviousTime = nCurrentTime
        end

        local bIsEmpty = true
        for _, tDrawManager in next, _tDrawManagers do
            local fHandler
            if tDrawManager.tSettings.bEnabled then
                fHandler = tDrawManager.UpdateDraw
            else
                fHandler = tDrawManager.RemoveDraw
            end
            for Key, tDraw in next, tDrawManager.tDraws do
                local tArg = tDrawManager.tSettings.bEnabled and tDraw or Key
                local bStatus, sResult = pcall(fHandler, tDrawManager, tArg)
                if not bStatus then
                    --@alpha@
                    RaidCore:Print(sResult)
                    --@end-alpha@
                end
            end
            if next(tDrawManager.tDraws) then
                bIsEmpty = false
            end
        end
        if bIsEmpty then
            StopDrawing()
        end
    end
end

function RaidCore:ResetLines()
    for _, tDrawManager in next, _tDrawManagers do
        for Key, tDraw in next, tDrawManager.tDraws do
            tDrawManager:RemoveDraw(Key)
        end
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

----------------------------------------------------------------------------------------------------
-- XXX: DEPRECATED FUNCTIONS, Keep for compatibility.
-- If a 'Line' have the same key as a 'Pixie', we will have a problem to distinct them on erase.
----------------------------------------------------------------------------------------------------
function RaidCore:AddLine(Key, nType, uStart, uTarget, nColor, nLength, nRotation, nDPL)
    local nFromId = uStart and uStart:GetId()
    local sColor = nil
    if nColor == 1 then
        sColor = "ff00ff00"
    elseif nColor == 2 then
        sColor = "ffff9933"
    elseif nColor == 3 then
        sColor = "ff0000ff"
    end
    nDPL = nDPL or 20
    if nType == 1 then
        local nToId = uTarget and uTarget:GetId()
        LineBetween:AddDraw(Key, nFromId, nToId, nil, sColor, nDPL)
    elseif nType == 2 then
        SimpleLine:AddDraw(Key, nFromId, nil, nLength, nRotation, nil, sColor, nDPL)
    end
end

function RaidCore:DropLine(Key)
    LineBetween:RemoveDraw(Key)
    SimpleLine:RemoveDraw(Key)
end

function RaidCore:AddPixie(Key, nType, uStart, uTarget, sColor, nWidth, nLength, nRotation)
    local nFromId = uStart and uStart:GetId()
    if sColor == "Blue" then
        sColor = "FF0000FF"
    elseif sColor == "Green" then
        sColor = "FF00FF00"
    elseif sColor == "Yellow" then
        sColor = "FFFF9933"
    elseif sColor == "Red" then
        sColor = "FFDC143C"
    end

    if nType == 1 then
        local nToId = uTarget and uTarget:GetId()
        LineBetween:AddDraw(Key, nFromId, nToId, nWidth, sColor)
    elseif nType == 2 then
        SimpleLine:AddDraw(Key, nFromId, nil, nLength, nRotation, nWidth, sColor)
    end
end

function RaidCore:DropPixie(Key)
    LineBetween:RemoveDraw(Key)
    SimpleLine:RemoveDraw(Key)
end
