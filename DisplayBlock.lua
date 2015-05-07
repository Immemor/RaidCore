local DisplayBlock = {}
local NO_BREAK_SPACE = string.char(194, 160)

DisplayBlock.__index = DisplayBlock

setmetatable(DisplayBlock, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function DisplayBlock.new(xmlDoc)
    local self = setmetatable({}, DisplayBlock)

    self.xmlDoc = xmlDoc
    self.infos = { }
    self.barsFrame = Apollo.LoadForm(self.xmlDoc, "RaidBars", nil, self)
    self.itemList = self.barsFrame:FindChild("ItemList")
    self.RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

    self.bgColor = CColor.new(1,1,1,0.8)
    self.barColor = CColor.new(1,0,0,0.5)
    self.isEnabled = true
    self.anchorFromTop = true
    self.barSize = {
        Width = 300,
        Height = 25
    }

    Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
    return self
end

local function hexToCColor(color, a)
    if not a then a = 1 end
    local r = tonumber(string.sub(color,1,2), 16) / 255
    local g = tonumber(string.sub(color,3,4), 16) / 255
    local b = tonumber(string.sub(color,5,6), 16) / 255
    return CColor.new(r,g,b,a)
end

function DisplayBlock:Load(saveData)
    if saveData.bgColor ~= nil then
        self:SetBGColor(saveData.bgColor)
    end

    if saveData.barColor ~= nil then
        self:SetBarColor(saveData.barColor)
    end

    if saveData.isEnabled ~= nil then
        self:SetEnabled(saveData.isEnabled)
    end

    if saveData.barSize ~= nil then
        self.barSize = saveData.barSize
    end

    if saveData.Position ~= nil then
        self:SetBarHeight(saveData.barSize.Height)
        self.barsFrame:SetAnchorOffsets(saveData.Position[1], saveData.Position[2], saveData.Position[1] + self.barSize.Width, saveData.Position[2] + self.barsFrame:GetHeight())
    end

    if saveData.anchorFromTop ~= nil then
        self.anchorFromTop = saveData.anchorFromTop
    end

end

function DisplayBlock:GetSaveData()
    local left, top, right, bottom = self.barsFrame:GetAnchorOffsets()
    local saveData = {
        bgColor = self.bgColor,
        barColor = self.barColor,
        isEnabled = self.isEnabled,
        Position = { left, top },
        anchorFromTop = self.anchorFromTop,
        barSize = self.barSize,
    }
    return saveData
end

function DisplayBlock:SetName(name)
    self.barsFrame:FindChild("MoveAnchor"):SetText(name)
end

function DisplayBlock:SetPosition(x, y)
    self.barsFrame:SetAnchorPoints(x, y, x, y)
end

function DisplayBlock:ResetPosition()
    self.barsFrame:SetAnchorOffsets(-150, -200, 150, 200)
    self:SetBarWidth(self.barSize.Width)
    if not self.anchorFromTop then
        self:AnchorFromTop(false, true)
    end
end

function DisplayBlock:SetEnabled(isEnabled)
    self.isEnabled = isEnabled
    if not isEnabled then
        for _, bar in pairs(self.infos) do
            local raidBar = bar.barFrame
            self.infos[raidBar.Key] = nil
            raidBar.Frame:Destroy()
        end
        self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
    end
end

function DisplayBlock:IsEnabled()
    return self.isEnabled
end

function DisplayBlock:SetMovable(isMovable)
    self.barsFrame:FindChild("MoveAnchor"):Show(isMovable)
    self.barsFrame:SetStyle("Picture", isMovable)
    self.barsFrame:SetStyle("Moveable", isMovable)
end

function DisplayBlock:SetBarWidth(width)
    local left, top, right, bottom = self.barsFrame:GetAnchorOffsets()
    right = left + width
    self.barsFrame:SetAnchorOffsets(left, top, right, bottom)
    self.barSize.Width = width
end

function DisplayBlock:SetBarHeight(height)
    self.barSize.Height = height
    for _, bar in pairs(self.infos) do
        local raidBar = bar.barFrame
        raidBar:SetHeight(height)
    end
    self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
end

function DisplayBlock:AddBar(key, message, duration)
    if self.isEnabled then
        local timeOfEvent = GameLib.GetGameTime()
        if self.infos[key] == nil then
            self.infos[key] = {}
            self.infos[key].key = key
            self.infos[key].endTime = timeOfEvent + duration
            self.infos[key].duration = duration
            self.infos[key].message = message
            local raidBar = self:CreateBar(key, message, duration, 1)
            self.infos[key].barFrame = raidBar
            self.infos[key].type = 1
        else
            self.infos[key].endTime = timeOfEvent + duration
            self.infos[key].duration = duration
            self.infos[key].message = message
            local raidBar = self.infos[key].barFrame
            raidBar:ReloadBar(message, duration)
        end

        self:RebuildList()

        local raidBar = self.infos[key].barFrame
        raidBar:UpdateProgress(duration)
    end
end

function DisplayBlock:RefreshBars()
    if self.isEnabled then
        local timeOfEvent = GameLib.GetGameTime()
        for _, bar in pairs(self.infos) do
            local duration = bar.endTime - timeOfEvent
            local raidBar = bar.barFrame
            if duration > 0 then
                raidBar:UpdateProgress(duration)
            else
                self.infos[raidBar.Key] = nil
                raidBar.Frame:Destroy()
                self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
            end
        end
    end
end

function DisplayBlock:RebuildList()
    if self.isEnabled then
        local tabSorted = {}
        for k, v in pairs(self.infos) do
            table.insert(tabSorted, v)
        end
        table.sort(tabSorted, function(a,b) return a.endTime < b.endTime end)

        self.itemList:DestroyChildren()

        for i, info in pairs(tabSorted) do
            local raidBar = self:CreateBar(info.key, info.message, info.duration, info.type)
            self.infos[info.key].barFrame = raidBar
        end

        self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
    end
end

function DisplayBlock:AddUnit(unit, mark)
    if self.isEnabled then
        local key = unit:GetId()
        if self.infos[key] == nil and not unit:IsDead() then

            local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
            local maxHealth = unit:GetMaxHealth()
            if maxHealth then
                self.infos[key] = {}
                self.infos[key].unit = unit
                local raidBar = self:CreateBar(key, unitName, maxHealth, 2, mark)
                self.infos[key].barFrame = raidBar
                local health = unit:GetHealth()
                if health then
                    raidBar:UpdateProgress(health)
                    self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
                end
            end
        end
    end
end

function DisplayBlock:RemoveUnit(key)
    if self.isEnabled then
        if self.infos[key] then
            local raidBar = self.infos[key].barFrame
            self.infos[raidBar.Key] = nil
            raidBar.Frame:Destroy()
            self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
        end
    end
end

function DisplayBlock:SetMarkUnit(unit, mark)
    if self.isEnabled then
        local key = unit:GetId()
        if self.infos[key] and not unit:IsDead() and mark then
            self.infos[key].barFrame:SetMark(mark)
        end
    end
end

function DisplayBlock:RefreshUnits()
    if self.isEnabled then
        for _, bar in pairs(self.infos) do
            local unit = bar.unit
            local raidBar = bar.barFrame
            if not unit:IsDead() then
                local health = unit:GetHealth()
                if health then raidBar:UpdateProgress(health) end
            else
                self.infos[raidBar.Key] = nil
                raidBar.Frame:Destroy()
                self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
            end
        end
    end
end

function DisplayBlock:AddMsg(key, message, duration, sound, color)
    if self.isEnabled then
        local timeOfEvent = GameLib.GetGameTime()
        if self.infos[key] == nil then
            self.infos[key] = {}
            self.infos[key].key = key
            self.infos[key].endTime = timeOfEvent + duration
            self.infos[key].duration = duration
            self.infos[key].message = message
            local raidBar = self:CreateMsg(key, message, duration)
            raidBar:SetWidth(self.barSize.Width)
            if color then
                if color == "Blue" then
                    local CCcolor = hexToCColor("0066FF", 1)
                    raidBar:SetTextColor(CCcolor)
                elseif color == "Green" then
                    local CCcolor = hexToCColor("00CC00", 1)
                    raidBar:SetTextColor(CCcolor)
                end
            end
            self.infos[key].barFrame = raidBar
            self.infos[key].type = 3
            self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
            local bSoundEnabled = self.RaidCore:GetSettings()["General"]["bSoundEnabled"]
            if sound and bSoundEnabled then
                Sound.PlayFile("..\\RaidCore\\Sounds\\"..sound .. ".wav")
            end
        end
    end
end


function DisplayBlock:RefreshMsg()
    if self.isEnabled then
        local timeOfEvent = GameLib.GetGameTime()
        for _, bar in pairs(self.infos) do
            local duration = bar.endTime - timeOfEvent
            local raidBar = bar.barFrame
            if duration <= 0 then
                self.infos[raidBar.Key] = nil
                raidBar.Frame:Destroy()
                self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
            end
        end
    end
end

function DisplayBlock:OnUnitDestroyed(unit)
    if self.isEnabled then
        local key = unit:GetId()
        if self.infos[key] then
            local raidBar = self.infos[key].barFrame
            self.infos[raidBar.Key] = nil
            raidBar.Frame:Destroy()
            self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
        end
    end
end


function DisplayBlock:ClearBar(key)
    if self.infos[key] then
        local raidBar = self.infos[key].barFrame
        self.infos[key] = nil
        raidBar.Frame:Destroy()
        self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
    end
end

function DisplayBlock:ClearAll()
    for _, bar in pairs(self.infos) do
        local raidBar = bar.barFrame
        self.infos[raidBar.Key] = nil
        raidBar.Frame:Destroy()
    end
    self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
end

function DisplayBlock:CreateBar(key, message, maxTime, type, mark)
    local bar = RaidCoreLibs.DisplayBar.new(self.xmlDoc, key, message, maxTime, type, self)
    bar:SetBGColor(self.bgColor)
    bar:SetBarColor(self.barColor)
    bar:SetHeight(self.barSize.Height)
    if mark then
        bar:SetMark(mark)
    end
    return bar
end

function DisplayBlock:CreateMsg(key, message, maxTime)
    local bar = RaidCoreLibs.DisplayMsg.new(self.xmlDoc, key, message, maxTime, self)
    bar:SetHeight(self.barSize.Height)
    return bar
end

function DisplayBlock:SetBGColor(color)
    if not color then return end
    self.bgColor = color
    for _, bar in pairs(self.infos) do
        local raidBar = bar.barFrame
        raidBar:SetBGColor(color)
    end
end

function DisplayBlock:SetBarColor(color)
    if not color then return end
    self.barColor = color
    for _, bar in pairs(self.infos) do
        local raidBar = bar.barFrame
        raidBar:SetBarColor(color)
    end
end

function DisplayBlock:AnchorFromTop(anchorTop, force)
    if self.anchorFromTop ~= anchorTop or force then
        self.anchorFromTop = anchorTop
        local left, top, right, bottom = self.barsFrame:GetAnchorOffsets()
        if anchorTop then
            self.barsFrame:SetAnchorOffsets(left, top + self.barsFrame:GetHeight(), right, top + self.barsFrame:GetHeight() + self.barsFrame:GetHeight())
        else
            self.barsFrame:SetAnchorOffsets(left, top - self.barsFrame:GetHeight(), right, top - self.barsFrame:GetHeight() + self.barsFrame:GetHeight())
        end
        self.itemList:ArrangeChildrenVert(self:GetAnchorPoint())
    end
end

function DisplayBlock:GetAnchorPoint()
    return self.anchorFromTop and Window.CodeEnumArrangeOrigin.LeftOrTop or Window.CodeEnumArrangeOrigin.RightOrBottom
end

if _G["RaidCoreLibs"] == nil then
    _G["RaidCoreLibs"] = { }
end

_G["RaidCoreLibs"]["DisplayBlock"] = DisplayBlock
