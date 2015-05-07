local ColorPicker = {}

ColorPicker.__index = ColorPicker

setmetatable(ColorPicker, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function ColorPicker.new(xmlDoc)
    local self = setmetatable({}, ColorPicker)

    self.colorPicker = Apollo.LoadForm(xmlDoc, "ColorPicker", nil, self)
    self.colorPicker:Show(false, true)
    Apollo.LoadSprites("Sprites.xml")
    self.colorPicker:FindChild("Color"):SetSprite("ColorPicker_Colors")
    self.colorPicker:FindChild("Gradient"):SetSprite("ColorPicker_Gradient")

    return self
end

function ColorPicker:OpenColorPicker(color, callback)
    self.colorPicker:Show(true)
    self.colorPicker:ToFront()
    self.editingColor = color
    self.originalColor = CColor.new(color.r, color.g, color.b, color.a)
    self.onColorChange = callback

    self.colorPicker:FindChild("PreviewOld"):SetBGColor(self.originalColor)
    self.colorPicker:FindChild("PreviewNew"):SetBGColor(self.editingColor)

    self.colorPicker:FindChild("Red"):SetText(string.format("%.f", math.max(0, color.r * 255)))
    self.colorPicker:FindChild("Green"):SetText(string.format("%.f", math.max(0, color.g * 255)))
    self.colorPicker:FindChild("Blue"):SetText(string.format("%.f", math.max(0, color.b * 255)))
    self.colorPicker:FindChild("AlphaText"):SetText(string.format("%.f", math.max(0, color.a * 100)))
    self.colorPicker:FindChild("AlphaSlider"):SetValue(string.format("%.f", math.max(0, color.a * 100)))
    self:UnpackColor()
end

function ColorPicker:OnCloseColorPicker( wndHandler, wndControl, eMouseButton )
    self.editingColor.r, self.editingColor.g, self.editingColor.b = self.originalColor.r, self.originalColor.g ,self.originalColor.b
    self.onColorChange()
    self.colorPicker:Show(false)
end

function ColorPicker:OnColorPickerOk( wndHandler, wndControl, eMouseButton )
    self.editingColor = nil
    self.originalColor = nil
    self.colorPicker:Show(false)
end

function ColorPicker:OnColorPickerColorStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
    if wndHandler == wndControl then
        self.colorPickerColorSelected = true
        self:OnColorMove(nLastRelativeMouseX, nLastRelativeMouseY)
    end
end

function ColorPicker:OnColorPickerColorStop( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    if wndHandler == wndControl then
        self.colorPickerColorSelected = false
    end
end

function ColorPicker:OnColorPickerColorMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
    if wndHandler == wndControl then
        if self.colorPickerColorSelected then
            self:OnColorMove(nLastRelativeMouseX, nLastRelativeMouseY)
        end
    end
end

function ColorPicker:OnColorMove(x, y)
    local indicator = self.colorPicker:FindChild("Color"):FindChild("SelectIndicator")
    local offset = math.max(0, math.min(1, y / self.colorPicker:FindChild("Color"):GetHeight()))
    indicator:SetAnchorPoints(0, offset, 1, offset)
    self:UpdateColorPicker()
end

local function ConvertRGBToHSV(r, g, b)
    local h, s, v
    local min, max, delta

    min = math.min(r, g, b)
    max = math.max(r, g, b)

    v = max;
    delta = max - min;
    if max > 0.0 then
        s = (delta / max)
    else
        r, g ,b = 0, 0, 0
        s = 0.0
        h = nil
        return h, s, v
    end
    if r >= max then
        h = ( g - b ) / delta
    else
        if g >= max then
            h = 2.0 + ( b - r ) / delta
        else
            h = 4.0 + ( r - g ) / delta
        end
    end

    h = h * 60.0

    if h < 0.0 then
        h = h + 360.0
    end

    return h, s, v
end

local function ConvertHSVToRGB(h, s, v)
    local hh, p, q, t, ff
    local i
    local r, g, b

    if s <= 0.0 then
        r, g, b = v, v, v
        return r, g, b
    end

    hh = h
    if hh >= 360.0 then hh = 0.0 end
    hh = hh / 60.0
    i = math.floor(hh)
    ff = hh - i;
    p = v * (1.0 - s);
    q = v * (1.0 - (s * ff));
    t = v * (1.0 - (s * (1.0 - ff)));

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end
    return r, g, b
end

function ColorPicker:UpdateColorPicker()
    local colorOffsetX, h = self.colorPicker:FindChild("Color"):FindChild("SelectIndicator"):GetAnchorPoints()
    local s, v = self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator"):GetAnchorPoints()

    h = math.max(0, math.min(1, h))
    s = math.max(0, math.min(1, s))
    v = math.max(0, math.min(1, v))

    h = (1 - h) * 360
    v = (1 - v) * 255
    local r, g, b = ConvertHSVToRGB(h, s, v)

    self.colorPicker:FindChild("Red"):SetText(string.format("%.f", r))
    self.colorPicker:FindChild("Green"):SetText(string.format("%.f", g))
    self.colorPicker:FindChild("Blue"):SetText(string.format("%.f", b))
    local gr, gg, gb = ConvertHSVToRGB(h, 1, 255)
    self.colorPicker:FindChild("Gradient"):SetBGColor(CColor.new(gr / 255, gg / 255, gb / 255, 1))

    self.editingColor.r = r / 255
    self.editingColor.g = g / 255
    self.editingColor.b = b / 255
    self:UpdateColor()
end

function ColorPicker:UnpackColor()
    local r = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Red"):GetText()) or 0))
    local g = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Green"):GetText()) or 0))
    local b = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Blue"):GetText()) or 0))

    local h, s, v = ConvertRGBToHSV(r, g, b)
    local gradOffsetY = 1 - (v / 255)

    local gr, gg, gb = ConvertHSVToRGB(h, 1, 255)
    self.colorPicker:FindChild("Gradient"):SetBGColor(CColor.new(gr / 255, gg / 255, gb / 255, 1))

    self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator"):SetAnchorPoints(s, gradOffsetY, s, gradOffsetY)
    local colorPos = 1 - (h / 360)
    self.colorPicker:FindChild("Color"):FindChild("SelectIndicator"):SetAnchorPoints(0, colorPos, 1, colorPos)

    self.editingColor.r = r / 255
    self.editingColor.g = g / 255
    self.editingColor.b = b / 255

    self:UpdateColor()
end

function ColorPicker:UpdateColor()
    self.colorPicker:FindChild("PreviewNew"):SetBGColor(self.editingColor)
    self.colorPicker:FindChild("HexCode"):SetText(string.format("%02x%02x%02x%02x", self.editingColor.r * 255, self.editingColor.g * 255, self.editingColor.b * 255, self.editingColor.a * 255))

    self.onColorChange()
end

function ColorPicker:OnColorChange( wndHandler, wndControl, strText )
    self:UnpackColor()
end

function ColorPicker:OnColorPickerGradientStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    if wndHandler == wndControl then
        self.colorPickerGradientSelected = true
        self:UpdateGradientPosition(nLastRelativeMouseX, nLastRelativeMouseY)
    end
end

function ColorPicker:OnColorPickerGradientStop( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
    if wndHandler == wndControl then
        self.colorPickerGradientSelected = false
    end
end

function ColorPicker:OnColorPickerGradientMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
    if wndHandler == wndControl then
        if self.colorPickerGradientSelected then
            self:UpdateGradientPosition(nLastRelativeMouseX, nLastRelativeMouseY)
        end
    end
end

function ColorPicker:UpdateGradientPosition(x, y)
    local indicator = self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator")
    local offsetX = math.max(0, math.min(1, x / self.colorPicker:FindChild("Gradient"):GetWidth()))
    local offsetY = math.max(0, math.min(1, y / self.colorPicker:FindChild("Gradient"):GetHeight()))

    indicator:SetAnchorPoints(offsetX, offsetY, offsetX, offsetY)

    self:UpdateColorPicker()
end

function ColorPicker:OnAlphaSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
    self.colorPicker:FindChild("AlphaText"):SetText(string.format("%i", fNewValue))
    self.editingColor.a = fNewValue / 100
    self:UpdateColor()
end

function ColorPicker:OnAlphaTextChanged( wndHandler, wndControl, strText )
    local alpha = math.min(255, math.max(0, self.colorPicker:FindChild("AlphaText"):GetText() or 0))
    self.colorPicker:FindChild("AlphaSlider"):SetValue(alpha)
    self.editingColor.a = alpha / 100
    self:UpdateColor()
end

function ColorPicker:OnHexCodeChanged( wndHandler, wndControl, strText )
    if string.len(strText) == 8 then
        local r = tonumber(string.sub(strText, 1, 2), 16)
        local g = tonumber(string.sub(strText, 3, 4), 16)
        local b = tonumber(string.sub(strText, 5, 6), 16)
        local a = tonumber(string.sub(strText, 7, 8), 16)
        self.editingColor.r, self.editingColor.g, self.editingColor.b, self.editingColor.a = r / 255, g / 255, b / 255, a / 255


        self.colorPicker:FindChild("AlphaText"):SetText(string.format("%i", self.editingColor.a * 100))
        self.colorPicker:FindChild("AlphaSlider"):SetValue(self.editingColor.a * 100)

        self:UpdateColor()
    end
end

if _G["RaidCoreLibs"] == nil then
    _G["RaidCoreLibs"] = { }
end
_G["RaidCoreLibs"]["ColorPicker"] = ColorPicker
