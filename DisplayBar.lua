local DisplayBar = {} 

DisplayBar.__index = DisplayBar

setmetatable(DisplayBar, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function DisplayBar.new(xmlDoc, key, message, maxTime, type, block)
    local self = setmetatable({}, DisplayBar)
    self.Key = key
    self.Type = type
    self.MaxTime = maxTime
    self.lastPct = 100
    self.Message = message

    self.Frame = Apollo.LoadForm(xmlDoc, "BarTemplate", block.barsFrame:FindChild("ItemList"), self)
    self.Frame:FindChild("Text"):SetText(message)
    if type < 3 then
        self.Frame:FindChild("RemainingOverlay"):SetMax(maxTime)
        self.Frame:SetSprite("RaidCoreMinimalist")
        self.Frame:FindChild("RemainingOverlay"):SetFullSprite("RaidCoreMinimalist")
    end
    return self
end

function DisplayBar:FormatNumber(nArg)
    if not nArg then return end
    local strResult
    if nArg >= 1000000 then
        if math.floor(nArg%1000000/100000) == 0 then
            strResult = string.format("%sm", math.floor(nArg / 1000000))
        else
            strResult = string.format("%s.%sm", math.floor(nArg / 1000000), math.floor(nArg % 1000000 / 100000))
        end
    elseif nArg >= 1000 then
        if math.floor(nArg%1000/100) == 0 then
            strResult = string.format("%sk", math.floor(nArg / 1000))
        else
            strResult = string.format("%s.%sk", math.floor(nArg / 1000), math.floor(nArg % 1000 / 100))
        end
    else
        strResult = nArg
    end

    return strResult
end

function DisplayBar:ReloadBar(message, maxTime)
    self.MaxTime = maxTime
    self.Frame:FindChild("Text"):SetText(message)
    self.Frame:FindChild("RemainingOverlay"):SetMax(maxTime)
end

function DisplayBar:UpdateProgress(timeRemaining) 
    self.Frame:FindChild("RemainingOverlay"):SetProgress(timeRemaining)
    if timeRemaining ~= 0 then
        if self.Type == 1 then
            self.Frame:FindChild("Timer"):SetText(string.format("%.1fs", timeRemaining))
        elseif self.Type == 2 then
            local percent = math.floor(timeRemaining / self.MaxTime * 100)
            if percent ~= self.lastPct then
                self.lastPct = percent
                Event_FireGenericEvent("UNIT_HEALTH", self.Message, percent)
            end
            local hundreds = math.floor(timeRemaining / self.MaxTime) % 10
            if hundreds == 0 then
                self.Frame:FindChild("Timer"):SetText(string.format("%.1f%%", timeRemaining / self.MaxTime * 100))
            else
                self.Frame:FindChild("Timer"):SetText(string.format("%.0f%%", math.floor(timeRemaining / self.MaxTime) * 100))
            end
        end
    else
        self.Frame:FindChild("Timer"):SetText("")
    end
end

function DisplayBar:SetHeight(height)
    local left, top, right, bottom = self.Frame:GetAnchorOffsets()
    self.Frame:SetAnchorOffsets(left, top, right, top + height)

    local mark = self.Frame:FindChild("Mark")
    local markHeight = mark:GetHeight()
    local left, top, right, bottom = mark:GetAnchorOffsets()
    mark:SetAnchorOffsets(left-12, top, right-12, bottom)

    local text = self.Frame:FindChild("Text")
    local left, top, right, bottom = text:GetAnchorOffsets()
    text:SetAnchorOffsets(left, top, right, bottom)
end

function DisplayBar:SetBGColor(color)
    self.Frame:SetBGColor(color)
end

function DisplayBar:SetBarColor(color)
    test = self.Frame:FindChild("RemainingOverlay")
    self.Frame:FindChild("RemainingOverlay"):SetBarColor(color)
end

function DisplayBar:SetMark(mark)
    self.Frame:FindChild("Mark"):SetText(mark)
end

if _G["RaidCoreLibs"] == nil then
    _G["RaidCoreLibs"] = { }
end

_G["RaidCoreLibs"]["DisplayBar"] = DisplayBar
