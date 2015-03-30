GeminiColor
===========

 A tool designed for adding color picking capabilities. Has options for preset or custom colors.


## To Call: ##
    GeminiColor = Apollo.GetPackage("GeminiColor").tPackage


## GeminiColor:ShowColorPicker(owner, callback [, bCustomColor] [, strInitialColor] [,...]) ##
-  owner - The owner that has the callback handler - typically your addon
-  callback - Either a string reference to the callback hander (or a function). Will be invoked with at least two  arguments - _owner_ & _strColor_, a hexadecimal string of the color - plus any additional arguments passed to _ShowColorPicker_.
-  bCustomColor - Optional If true, will offer a color picker window instead of just the preset colors. if false, only dropdown with all X11 colors is available.
-  strInitialColor - Optional initial color for the picker
-  ... - optional additional arguments to pass back to the callback handler


Shows a single use color picker

## GeminiColor:CreateColorPicker(owner, callback [, bCustomColor] [, strInitialColor] [,...]) ##
-  owner - The owner that has the callback handler - typically your addon
-  callback - Either a string reference to the callback hander (or a function). Will be invoked with at least two  arguments - _owner_ & _strColor_, a hexadecimal string of the color - plus any additional arguments passed to _CreateColorPicker_.
-  bCustomColor - Optional If true, will offer a color picker window instead of just the preset colors. if false, only dropdown with all X11 colors is available.
-  strInitialColor - Optional initial color for the picker
-  ... - optional additional arguments to pass back to the callback handler


This method returns a _reusable_ color picker. It does *not* show the picker, it only returns a window that represents the picker.
It is up to the caller to call _Show_ and possibly other methods (like _Destroy_) on the window as desired.

Example:
```Lua
function MyAddon:OnInitialize()
  GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  self.picker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", true, "ffff0000", "some", 4, "userdefined", "values")
end

function MyAddon:Method1()
  self.picker:Show(true)
end

function MyAddon:Method2()
  self.picker:Show(true)
end

function MyAddon:Cleanup()
  self.picker:Destroy()
  self.picker = nil
end


function MyAddon:ColorPickerCallback(strColor, ...)
  local text = "ColorPickerCallback - color = " .. strColor .. " Extra args = "
  for i,v in ipairs(arg) do
    printResult = printResult .. tostring(v) .. "\t"
  end
  Print(printResult)
end
```

## GeminiColor:CreateColorDropdown(wndHost, strSkin) ##

- wndHost = place holder window, used to get Window Name, Anchors and Offsets, and Parent
- strSkin = "Holo" or "Metal" -- not case sensitive
- Returns reference to dropdown window. Call GetData method of this window to retrieve color code and name.
```lua
{
	strColor = "ffffffff",
	strName = "White",
}
```

## GeminiColor:GetColorList() ##
- returns - Table of all X11 colors, each entry is as follows:
- { colorName = "IndianRed", strColor = "CD5C5C"},

## GeminiColor:GetColorStringByName(strColorName) ##

- strColorName - string name of the X11 color.
- returns - Hexadecimal color string

## GeminiColor:HSVtoRGB(h, s, l, a) ##

-  h - Hue 0 - 1
-  s - Saturation 0 - 1
-  l - Lightness 0 - 1
-  a - Alpha 0 - 1
-  returns - List of RGBA percentage values


## GeminiColor:RGBtoHSV(r, g, b, a) ##

-  r - Red 0 - 1
-  g - Green 0 - 1
-  b - Blue 0 - 1
-  a - Alpha 0 - 1
-  returns - List of HSLA percentage values

## GeminiColor:RGBAPercToHex(r, g, b, a) ##

-  r - Red 0 - 1
-  g - Green 0 - 1
-  b - Blue 0 - 1
-  a - Alpha 0 - 1
-  returns - Hexadecimal color string

## GeminiColor:HexToRGBAPerc(hex) ##

-  hex - hexadecmial color string
-  returns - RGBA list

## GeminiColor:RGBpercToRGB(r,g,b,a) ##

-  r - Red 0 - 1
-  g - Green 0 - 1
-  b - Blue 0 - 1
-  a - Alpha 0 - 1
-  returns - RGBA list, from 0 - 255

## GeminiColor:RGBtoRGBperc(r,g,b,a) ##

-  r - Red 0 - 255
-  g - Green 0 - 255
-  b - Blue 0 - 255
-  a - Alpha 0 - 255
-  returns - RGBA list, from 0 - 1