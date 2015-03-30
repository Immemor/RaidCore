local DisplayMsg = {} 

DisplayMsg.__index = DisplayMsg

setmetatable(DisplayMsg, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function DisplayMsg.new(xmlDoc, key, message, maxTime, block)
    local self = setmetatable({}, DisplayMsg)
    self.Key = key
    self.Type = type
    self.MaxTime = maxTime

    self.Frame = Apollo.LoadForm(xmlDoc, "MsgTemplate", block.barsFrame:FindChild("ItemList"), self)
    --self.Frame:SetFont("CRB_Header20_O")
    self.Frame:SetText(message)
    --Print("Message loaded : " .. message)
    return self
end
--[[
function DisplayMsg:OnGenerateSpellTooltip( wndHandler, wndControl, eToolTipType, x, y )
    if wndControl == wndHandler then
        Tooltip.GetSpellTooltipForm(self, wndHandler, GameLib.GetSpell(self.spell:GetId()), false)
    end
end
]]--


function DisplayMsg:SetHeight(height)
    local left, top, right, bottom = self.Frame:GetAnchorOffsets()
    self.Frame:SetAnchorOffsets(left, top, right, top + height)
end

function DisplayMsg:SetWidth(width)
    local left, top, right, bottom = self.Frame:GetAnchorOffsets()
    self.Frame:SetAnchorOffsets(left, top, left + width, bottom)
end

function DisplayMsg:SetBGColor(color)
    --self.Frame:SetBGColor(color)
end

function DisplayMsg:SetTextColor(color)
    self.Frame:SetTextColor(color)
end

function DisplayMsg:SetBarColor(color)
    --self.Frame:SetBarColor(color)
end


if _G["RaidCoreLibs"] == nil then
    _G["RaidCoreLibs"] = { }
end
_G["RaidCoreLibs"]["DisplayMsg"] = DisplayMsg