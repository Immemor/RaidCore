--================================================================================================
--
--										GeminiColor
--
--			An Apollo Package for producing UI controls for picking colors, picking colors,
--			and working with color data in multiple formats.
--
--================================================================================================

--[[
The MIT License (MIT)

Copyright (c) 2014 2014 Wildstar NASA

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local MAJOR, MINOR = "GeminiColor", 11
-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

require "Window"

-----------------------------------------------------------------------------------------------
-- GeminiColor Module Definition
-----------------------------------------------------------------------------------------------
local GeminiColor = APkg and APkg.tPackage or {}

-----------------------------------------------------------------------------------------------
-- Upvalues
-----------------------------------------------------------------------------------------------
local ipairs, pairs, strmatch, strlen = ipairs, pairs, string.match, string.len
local error, select, strformat, type, unpack = error, select, string.format, type, unpack
local strsub, tonumber, mathmax, mathmin = string.sub, tonumber, math.max, math.min
local setmetatable, tinsert, tremove = setmetatable, table.insert, table.remove
local strlower = string.lower

-- Wildstar APIs
local Apollo, Print, XmlDoc = Apollo, Print, XmlDoc

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local ktColors = {
	{ colorName = "IndianRed", strColor = "CD5C5C"}, { colorName = "LightCoral", strColor = "F08080"}, { colorName = "Salmon", strColor = "FA8072"},
	{ colorName = "DarkSalmon", strColor = "E9967A"}, { colorName = "Red", strColor = "FF0000"}, { colorName = "Crimson", strColor = "DC143C"},
	{ colorName = "FireBrick", strColor = "B22222"}, { colorName = "DarkRed", strColor = "8B0000"}, { colorName = "Pink", strColor = "FFC0CB"},
	{ colorName = "LightPink", strColor = "FFB6C1"}, { colorName = "HotPink", strColor = "FF69B4"}, { colorName = "DeepPink", strColor = "FF1493"},
	{ colorName = "MediumVioletRed", strColor = "C71585"}, { colorName = "PaleVioletRed", strColor = "DB7093"}, { colorName = "LightSalmon", strColor = "FFA07A"},
	{ colorName = "Coral", strColor = "FF7F50"}, { colorName = "Tomato", strColor = "FF6347"}, { colorName = "OrangeRed", strColor = "FF4500"},
	{ colorName = "DarkOrange", strColor = "FF8C00"}, { colorName = "Orange", strColor = "FFA500"}, { colorName = "Gold", strColor = "FFD700"},
	{ colorName = "Yellow", strColor = "FFFF00"}, { colorName = "LightYellow", strColor = "FFFFE0"}, { colorName = "LemonChiffon", strColor = "FFFACD"},
	{ colorName = "LightGoldenrodYellow", strColor = "FAFAD2"}, { colorName = "PapayaWhip", strColor = "FFEFD5"}, { colorName = "Moccasin", strColor = "FFE4B5"},
	{ colorName = "PeachPuff", strColor = "FFDAB9"}, { colorName = "PaleGoldenrod", strColor = "EEE8AA"}, { colorName = "Khaki", strColor = "F0E68C"},
	{ colorName = "DarkKhaki", strColor = "BDB76B"}, { colorName = "Lavender", strColor = "E6E6FA"}, { colorName = "Thistle", strColor = "D8BFD8"},
	{ colorName = "Plum", strColor = "DDA0DD"}, { colorName = "Violet", strColor = "EE82EE"}, { colorName = "Orchid", strColor = "DA70D6"},
	{ colorName = "Magenta", strColor = "FF00FF"}, { colorName = "MediumOrchid", strColor = "BA55D3"}, { colorName = "MediumPurple", strColor = "9370DB"},
	{ colorName = "BlueViolet", strColor = "8A2BE2"}, { colorName = "DarkViolet", strColor = "9400D3"}, { colorName = "DarkOrchid", strColor = "9932CC"},
	{ colorName = "DarkMagenta", strColor = "8B008B"}, { colorName = "Purple", strColor = "800080"}, { colorName = "Indigo", strColor = "4B0082"},
	{ colorName = "DarkSlateBlue", strColor = "483D8B"}, { colorName = "SlateBlue", strColor = "6A5ACD"}, { colorName = "MediumSlateBlue", strColor = "7B68EE"},
	{ colorName = "GreenYellow", strColor = "ADFF2F"}, { colorName = "Chartreuse", strColor = "7FFF00"}, { colorName = "LawnGreen", strColor = "7CFC00"},
	{ colorName = "Lime", strColor = "00FF00"}, { colorName = "LimeGreen", strColor = "32CD32"}, { colorName = "PaleGreen", strColor = "98FB98"},
	{ colorName = "LightGreen", strColor = "90EE90"}, { colorName = "MediumSpringGreen", strColor = "00FA9A"}, { colorName = "SpringGreen", strColor = "00FF7F"},
	{ colorName = "MediumSeaGreen", strColor = "3CB371"}, { colorName = "SeaGreen", strColor = "2E8B57"}, { colorName = "ForestGreen", strColor = "228B22"},
	{ colorName = "Green", strColor = "008000"}, { colorName = "DarkGreen", strColor = "006400"}, { colorName = "YellowGreen", strColor = "9ACD32"},
	{ colorName = "OliveDrab", strColor = "6B8E23"}, { colorName = "Olive", strColor = "808000"}, { colorName = "DarkOliveGreen", strColor = "556B2F"},
	{ colorName = "MediumAquamarine", strColor = "66CDAA"}, { colorName = "DarkSeaGreen", strColor = "8FBC8F"}, { colorName = "LightSeaGreen", strColor = "20B2AA"},
	{ colorName = "DarkCyan", strColor = "008B8B"}, { colorName = "Teal", strColor = "008080"}, { colorName = "Cyan", strColor = "00FFFF"},
	{ colorName = "LightCyan", strColor = "E0FFFF"}, { colorName = "PaleTurquoise", strColor = "AFEEEE"}, { colorName = "Aquamarine", strColor = "7FFFD4"},
	{ colorName = "Turquoise", strColor = "40E0D0"}, { colorName = "MediumTurquoise", strColor = "48D1CC"}, { colorName = "DarkTurquoise", strColor = "00CED1"},
	{ colorName = "CadetBlue", strColor = "5F9EA0"}, { colorName = "SteelBlue", strColor = "4682B4"}, { colorName = "LightSteelBlue", strColor = "B0C4DE"},
	{ colorName = "PowderBlue", strColor = "B0E0E6"}, { colorName = "LightBlue", strColor = "ADD8E6"}, { colorName = "SkyBlue", strColor = "87CEEB"},
	{ colorName = "LightSkyBlue", strColor = "87CEFA"}, { colorName = "DeepSkyBlue", strColor = "00BFFF"}, { colorName = "DodgerBlue", strColor = "1E90FF"},
	{ colorName = "CornflowerBlue", strColor = "6495ED"}, { colorName = "RoyalBlue", strColor = "4169E1"}, { colorName = "Blue", strColor = "0000FF"},
	{ colorName = "MediumBlue", strColor = "0000CD"}, { colorName = "DarkBlue", strColor = "00008B"}, { colorName = "Navy", strColor = "000080"},
	{ colorName = "MidnightBlue", strColor = "191970"}, { colorName = "Cornsilk", strColor = "FFF8DC"}, { colorName = "BlanchedAlmond", strColor = "FFEBCD"},
	{ colorName = "Bisque", strColor = "FFE4C4"}, { colorName = "NavajoWhite", strColor = "FFDEAD"}, { colorName = "Wheat", strColor = "F5DEB3"},
	{ colorName = "BurlyWood", strColor = "DEB887"}, { colorName = "Tan", strColor = "D2B48C"}, { colorName = "RosyBrown", strColor = "BC8F8F"},
	{ colorName = "SandyBrown", strColor = "F4A460"}, { colorName = "Goldenrod", strColor = "DAA520"}, { colorName = "DarkGoldenrod", strColor = "B8860B"},
	{ colorName = "Peru", strColor = "CD853F"}, { colorName = "Chocolate", strColor = "D2691E"}, { colorName = "SaddleBrown", strColor = "8B4513"},
	{ colorName = "Sienna", strColor = "A0522D"}, { colorName = "Brown", strColor = "A52A2A"}, { colorName = "Maroon", strColor = "800000"},
	{ colorName = "White", strColor = "FFFFFF"}, { colorName = "Snow", strColor = "FFFAFA"}, { colorName = "Honeydew", strColor = "F0FFF0"},
	{ colorName = "MintCream", strColor = "F5FFFA"}, { colorName = "Azure", strColor = "F0FFFF"}, { colorName = "AliceBlue", strColor = "F0F8FF"},
	{ colorName = "GhostWhite", strColor = "F8F8FF"}, { colorName = "WhiteSmoke", strColor = "F5F5F5"}, { colorName = "Seashell", strColor = "FFF5EE"},
	{ colorName = "Beige", strColor = "F5F5DC"}, { colorName = "OldLace", strColor = "FDF5E6"}, { colorName = "FloralWhite", strColor = "FFFAF0"},
	{ colorName = "Ivory", strColor = "FFFFF0"}, { colorName = "AntiqueWhite", strColor = "FAEBD7"}, { colorName = "Linen", strColor = "FAF0E6"},
	{ colorName = "LavenderBlush", strColor = "FFF0F5"}, { colorName = "MistyRose", strColor = "FFE4E1"}, { colorName = "Gainsboro", strColor = "DCDCDC"},
	{ colorName = "LightGrey", strColor = "D3D3D3"}, { colorName = "Silver", strColor = "C0C0C0"}, { colorName = "DarkGray", strColor = "A9A9A9"},
	{ colorName = "Gray", strColor = "808080"}, { colorName = "DimGray", strColor = "696969"}, { colorName = "LightSlateGray", strColor = "778899"},
	{ colorName = "SlateGray", strColor = "708090"}, { colorName = "DarkSlateGray", strColor = "2F4F4F"}, { colorName = "Black", strColor = "000000"},
}

-----------------------------------------------------------------------------------------------
-- GeminiColor Upvalues
-----------------------------------------------------------------------------------------------

local floor = math.floor
local GetCurrentColor

-----------------------------------------------------------------------------------------------
-- GeminiColor OnLoad
-----------------------------------------------------------------------------------------------

function GeminiColor:OnLoad()
	local strPrefix = Apollo.GetAssetFolder()
	local tToc = XmlDoc.CreateFromFile("toc.xml"):ToTable()
	for k,v in ipairs(tToc) do
		local strPath = strmatch(v.Name, "(.*)[\\/]GeminiColor")
		if strPath ~= nil and strPath ~= "" then
			strPrefix = strPrefix .. "\\" .. strPath .. "\\"
			break
		end
	end
	local tSpritesXML = {
		__XmlNode = "Sprites",
		{ -- Form
			__XmlNode="Sprite", Name="Hue", Cycle="1",
			{
				__XmlNode="Frame", Texture= strPrefix .."textures\\GCHSL.tga",
				x0="0", x1="0", x2="0", x3="0", x4="256", x5="256",
				y0="0", y1="0", y2="0", y3="0", y4="8", y5="8",
				HotspotX="0", HotspotY="0", Duration="1.000",
				StartColor="white", EndColor="white",
			},
		},
	}
	local xmlSprites = XmlDoc.CreateFromTable(tSpritesXML)
	Apollo.LoadSprites(xmlSprites, "GeminiColorSprites")
	self.xmlDoc = XmlDoc.CreateFromFile(strPrefix.."GeminiColor.xml")
end

----------------------------------------------------------------------------------------------
-- GeminiColor Functions
-----------------------------------------------------------------------------------------------

function GeminiColor:CreateColorPicker(taOwner, oCallbackOrOpt, ...)
	local wndChooser = Apollo.LoadForm(self.xmlDoc, "GeminiChooserForm", nil, self)
	wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_Hue"):SetSprite("GeminiColorSprites:Hue")

	local wndSwatches = wndChooser:FindChild("wnd_SwatchContainer")
	for i, v in pairs(ktColors) do
		local wndCurrColor = Apollo.LoadForm(self.xmlDoc, "SwatchButtonForm", wndSwatches, self)
		local xmlDocTT = XmlDoc.new()
		xmlDocTT:AddLine(v.colorName, "ff"..v.strColor, "CRB_InterfaceMediumBBO")
		wndCurrColor:SetTooltipDoc(xmlDocTT)
		wndCurrColor:SetBGColor("ff"..v.strColor)
	end
	wndSwatches:ArrangeChildrenTiles()

	local strInitialColor, tData
	if type(oCallbackOrOpt) == "table" then
		if not oCallbackOrOpt.callback then
			error("GeminiColor: Missing callback function")
		end
		strInitialColor = oCallbackOrOpt.strInitialColor
		tData = {
			owner = taOwner,
			callback = oCallbackOrOpt.callback,
			bCustomColor = oCallbackOrOpt.bCustomColor or false,
			bAlpha = oCallbackOrOpt.bAlpha or false,
			strInitialColor = strInitialColor,
			args = {...},
			tColorList = {strInitialColor},
		}
	elseif type(oCallbackOrOpt) == "nil" then
		error("GeminiColor: Missing callback function")
	else
		-- Previous Signature: taOwner, fnstrCallback, bCustomColor, strInitialColor, ...
		local tArg
		local bCustomColor = select(1,...)
		if type(bCustomColor) ~= "boolean" then
			strInitialColor = bCustomColor
			tArg = select(2,...)
		else
			strInitialColor = select(2,...)
			tArg = {select(3,...)}
		end

		tData = {
			owner = taOwner,
			callback = oCallbackOrOpt,
			bCustomColor = bCustomColor or false,
			strInitialColor = strInitialColor,
			args = tArg,
			tColorList = {strInitialColor},
		}
	end

	wndChooser:SetData(tData)

	local sValForm
	if tData.bAlpha then
		sValForm = "RGBADisplay"
	else
		sValForm = "RGBDisplay"
		wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_Alpha"):Show(false)
	end
	Apollo.LoadForm(self.xmlDoc, sValForm, wndChooser:FindChild("wnd_Custom"), self)

	if not tData.bCustomColor then
		wndChooser:FindChild("wnd_Custom"):Show(false)
		local left, top, right, bottom = wndChooser:GetAnchorOffsets()
		wndChooser:SetAnchorOffsets(right - 420, top, right, bottom)
	end

	if type(strInitialColor) == "string" then
		self:SetRGB(wndChooser, self:HexToRGBA(strInitialColor))
		self:SetHSV(wndChooser, strInitialColor)
		self:UpdateCurrPrevColors(wndChooser)
	else
		self:SetRGB(wndChooser, self:HexToRGBA("ffffffff"))
		wndChooser:FindChild("wnd_ColorSwatch_Current"):SetBGColor("ffffffff")
		wndChooser:FindChild("wnd_ColorSwatch_Previous"):SetBGColor("ff000000")
	end

	return wndChooser
end

function GeminiColor:OnGCOn()
	self:ShowColorPicker({Test = function(self, strColor) Print(strColor) end}, "Test", true)
end

function GeminiColor:ShowColorPicker(taOwner, oCallbackOrOpt, ...)
	local wndChooser = self:CreateColorPicker(taOwner, oCallbackOrOpt, ...)
	wndChooser:AddEventHandler("WindowHide", "OnColorChooserHide", self)

	wndChooser:Show(true)
	wndChooser:ToFront()
end

function GeminiColor:OnColorChooserHide(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	wndControl:Destroy()
end

function GeminiColor:GetColorList()
	-- returns a table containing sub entries for all X11 colors.
	-- colorName, strColor
	return ktColors
end

function GeminiColor:GetColorStringByName(strColorName)
	-- returns the hexadecimal string for an x11 color based on name.
	for i, color in pairs(ktColors) do
		if color.colorName == strColorName then
			return color.strColor
		end
	end
end

function GeminiColor:RGBAPercToHex(r, g, b, a)
	-- Returns a hexadecimal string for the RGBA values passed.
	if not(a) then a = 1 end
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	a = a <= 1 and a >= 0 and a or 1
	-- return hex string
	return strformat("%02x%02x%02x%02x",a*255 ,r*255, g*255, b*255)
end

function GeminiColor:HexToRGBAPerc(hex)
	-- Returns RGBA values for the a hexadecimal string passed.
	if strlen(hex) == 6 then
		local rhex, ghex, bhex = strsub(hex, 1,2), strsub(hex, 3, 4), strsub(hex, 5, 6)
		-- return R,G,B number list
		return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255, 1
	else
		local ahex, rhex, ghex, bhex = strsub(hex, 1,2), strsub(hex, 3, 4), strsub(hex, 5, 6), strsub(hex, 7, 8)
		-- return R, G, B, A number list
		return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255, tonumber(ahex, 16)/255
	end
end

function GeminiColor:HexToRGBA(hex)
	if strlen(hex) == 6 then
		local rhex, ghex, bhex = strsub(hex, 1,2), strsub(hex, 3, 4), strsub(hex, 5, 6)
		-- return R,G,B number list
		return tonumber(rhex, 16), tonumber(ghex, 16), tonumber(bhex, 16), 255
	else
		local ahex, rhex, ghex, bhex = strsub(hex, 1,2), strsub(hex, 3, 4), strsub(hex, 5, 6), strsub(hex, 7, 8)
		-- return R, G, B, A number list
		return tonumber(rhex, 16), tonumber(ghex, 16), tonumber(bhex, 16), tonumber(ahex, 16)
	end
end

function GeminiColor:RGBAToHex(r, g, b, a)
	a = a or 255
	return strformat("%02x%02x%02x%02x", a, r, g, b)
end

function GeminiColor:RGBpercToRGB(r,g,b,a)
	--Converts 0 - 1 RGB to 0 - 255 RGB
	return r * 255, g * 255, b * 255, a * 255
end

function GeminiColor:RGBtoRGBperc(r,g,b,a)
	--Converts 0 - 255 RGB to 0 - 1 RGB
	return r / 255, g / 255, b / 255, a / 255
end

-----------------------------------------------------------------------------------------------
-- Color Utility Functions
-- Adapted From https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
-----------------------------------------------------------------------------------------------
function GeminiColor:RGBtoHSV(r, g, b, a)
	--[[
	 * Converts an RGB color value to HSV. Conversion formula
	 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
	 * Assumes r, g, and b are contained in the set [0, 255] and
	 * returns h, s, and v in the set [0, 1].
	 *
	 * @param   Number  r       The red color value
	 * @param   Number  g       The green color value
	 * @param   Number  b       The blue color value
	 * @return  Array           The HSV representation
	]]
	a = a or 255
	r, g, b, a = r / 255, g / 255, b / 255, a / 255
	local max, min = mathmax(r, g, b), mathmin(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then s = 0 else s = d / max end

	if max == min then
		h = 0 -- achromatic
	else
		if max == r then
			h = (g - b) / d
			if g < b then h = h + 6 end
			elseif max == g then h = (b - r) / d + 2
			elseif max == b then h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, v, a
end

function GeminiColor:HSVtoRGB(h, s, v, a)
	--[[
	 * Converts an HSV color value to RGB. Conversion formula
	 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
	 * Assumes h, s, and v are contained in the set [0, 1] and
	 * returns r, g, and b in the set [0, 255].
	 *
	 * @param   Number  h       The hue
	 * @param   Number  s       The saturation
	 * @param   Number  v       The value
	 * @return  Array           The RGB representation
	]]
	local r, g, b

	a = a or 1

	local i = floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);

	i = i % 6

	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end

	return floor(r * 255), floor(g * 255), floor(b * 255), floor(a * 255)
end

---------------------------------------------------------------------------------------------------
-- GeminiChooserForm Functions
---------------------------------------------------------------------------------------------------
local function FireCallback(wndChooser)
	local data = wndChooser:GetData()

	local owner = data.owner
	local callback

	if type(data.callback) == "function" then
		callback = data.callback
	else
		callback = owner[data.callback]
	end

	local strColor = GetCurrentColor(wndChooser)

	if data.args ~= nil then
		callback(owner, strColor, unpack(data.args))
	else
		callback(owner, strColor)
	end
end

function GeminiColor:OnOK(wndHandler, wndControl, eMouseButton)
	local wndChooser = wndControl:GetParent()

	wndChooser:Show(false) -- hide the window
end

function GeminiColor:OnCancel(wndHandler, wndControl, eMouseButton )
	local wndChooser = wndControl:GetParent()
	local data = wndChooser:GetData()
	data.tColorList = {data.strInitialColor}

	FireCallback(wndChooser)

	wndChooser:Show(false) -- hide the window
end

function GeminiColor:OnColorSwatchClick(wndHandler, wndControl)
	local crColor = wndControl:GetBGColor():ToTable()
	local strColorCode = self:RGBAPercToHex(crColor.r, crColor.g, crColor.b, 1)
	local wndChooser = wndControl:GetParent():GetParent()	-- parent path: button -> wnd_SwatchContainer -> GeminiChooserForm
	self:SetHSV(wndChooser,strColorCode)
	self:SetNewColor(wndChooser, strColorCode)
end

function GeminiColor:SetRGB(wndChooser, R,G,B,A) -- update the RGB boxes in the color picker
	wndChooser:FindChild("input_Red"):SetText(R)
	wndChooser:FindChild("input_Green"):SetText(G)
	wndChooser:FindChild("input_Blue"):SetText(B)
	local inputAlpha = wndChooser:FindChild("input_Alpha")
	if inputAlpha then
		inputAlpha:SetText(A)
	end
	local strHex = self:RGBAToHex(R,G,B,A)
	if not wndChooser:GetData().bAlpha then
		strHex = strsub(strHex, 3)
	end
	wndChooser:FindChild("input_Hex"):SetText(strHex)
end

function GeminiColor:UndoColorChange(wndHandler, wndControl, eMouseButton )
	local wndChooser = wndControl:GetParent()
	local data = wndChooser:GetData()
	tremove(data.tColorList, 1)
	self:SetRGB(wndChooser, self:HexToRGBA(data.tColorList[1]))
	self:SetHSV(wndChooser, data.tColorList[1])
	self:UpdateCurrPrevColors(wndChooser)
	FireCallback(wndChooser)
end

function GetCurrentColor(wndChooser)
	local data = wndChooser:GetData()
	return data.tColorList[1]
end

function GeminiColor:SetHSV(wndChooser, strHexColor)
	local wndSatVal = wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_SatValue")
	local wndHue = wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_Hue")
	local wndAlpha = wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_Alpha")

	local h, s, v, a = self:RGBtoHSV(self:HexToRGBA(strHexColor))
	local left, top, right, bottom = wndSatVal:FindChild("wnd_Loc"):GetAnchorOffsets()

	left = floor((s * 256) - 10)
	top = floor(((-v + 1) * 256) - 10)
	wndSatVal:FindChild("wnd_Loc"):SetAnchorOffsets(left, top, left + 20, top + 20)

	wndHue:FindChild("SliderBar"):SetValue(h * 100)
	wndAlpha:FindChild("SliderBar"):SetValue(a * 100)

	local clrOverlay = self:RGBAToHex(self:HSVtoRGB(h, 1, 1))
	wndSatVal:SetBGColor(clrOverlay)
end

function GeminiColor:UpdateHSV(wndChooser, bUpdatePrev)
	local wndSatVal = wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_SatValue")
	local wndHue = wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_Hue")
	local wndAlpha = wndChooser:FindChild("wnd_Custom:wnd_WidgetContainer:wnd_Alpha")

	--Saturation and Lightness
	local fSaturation, fLightness  = wndSatVal:FindChild("wnd_Loc"):GetAnchorOffsets()
	fLightness = 1 - ((fLightness + 10) / 256)
	fSaturation = ((fSaturation + 10) / 256)
	if fLightness > 1 then fLightness = 1 elseif fLightness < 0 then fLightness = 0 end
	if fSaturation > 1 then fSaturation = 1 elseif fSaturation < 0 then fSaturation = 0 end
	-- Hue
	local fHue = floor(wndHue:FindChild("SliderBar"):GetValue()) / 100
	local clrOverlay = self:RGBAToHex(self:HSVtoRGB(fHue, 1,1))
	wndSatVal:SetBGColor(clrOverlay)

	-- Alpha
	local fAlpha = floor(wndAlpha:FindChild("SliderBar"):GetValue()) / 100

	-- Update Colors
	local clrCode = self:RGBAToHex(self:HSVtoRGB(fHue, fSaturation, fLightness, fAlpha))
	wndChooser:FindChild("wnd_ColorSwatch_Current"):SetBGColor(clrCode)

	self:SetRGB(wndChooser, self:HexToRGBA(clrCode))

	if bUpdatePrev then
		self:SetNewColor(wndChooser, clrCode)
	else
		wndChooser:GetData().tColorList[1] = clrCode
		FireCallback(wndChooser)
	end
end

function GeminiColor:SatLightClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	wndControl:FindChild("wnd_Loc"):SetAnchorOffsets(nLastRelativeMouseX - 10, nLastRelativeMouseY - 10, nLastRelativeMouseX + 10, nLastRelativeMouseY + 10)
	local wndChooser = wndControl:GetParent():GetParent():GetParent()	-- ancestor chain: wnd_SatValue -> wnd_WidgetContainer -> wnd_Custom -> GeminiChooserForm
	self:UpdateHSV(wndChooser, true)
end

function GeminiColor:OnSatValueMove(wndHandler, wndControl)
	-- Constrain to SatValue
	local left,top,right,bottom = wndControl:GetAnchorOffsets()
	local rightEdge = wndControl:GetParent():GetWidth() - 10
	local bottomEdge = wndControl:GetParent():GetHeight() - 10
	if left < -10 then
		left = -10
	elseif left > rightEdge then
		left = rightEdge
	end

	if top < -10 then
		top = -10
	elseif top > bottomEdge then
		top = bottomEdge
	end

	wndControl:SetAnchorOffsets(left,top,left + 20, top + 20)
	local wndChooser = wndControl:GetParent():GetParent():GetParent():GetParent()	-- ancestor chain: wnd_Loc -> wnd_SatValue -> wnd_WidgetContainer -> wnd_Custom -> wGeminiChooserForm
	self:UpdateHSV(wndChooser, true)
end

function GeminiColor:OnHueSliderChanged( wndHandler, wndControl, fNewValue, fOldValue)
	local wndChooser = wndControl:GetParent():GetParent():GetParent():GetParent()	-- ancestor chain: SliderBar -> wnd_Hue -> wnd_WidgetContainer -> wnd_Custom -> GeminiChooserForm
	self:UpdateHSV(wndChooser, false)
end

function GeminiColor:OnAlphaSliderChanged( wndHandler, wndControl, fNewValue, fOldValue)
	local wndChooser = wndControl:GetParent():GetParent():GetParent():GetParent()	-- ancestor chain: SliderBar -> wnd_Alpha -> wnd_WidgetContainer -> GeminiChooserForm
	self:UpdateHSV(wndChooser, false)
end

function GeminiColor:UpdateCurrPrevColors(wndChooser)
	local data = wndChooser:GetData()
	local tColorList = data.tColorList
	if #tColorList > 1 then
		local currColor = tColorList[1]
		local prevColor = tColorList[2]
		local wndCurrColor = wndChooser:FindChild("wnd_ColorSwatch_Current")
		local wndPrevColor = wndChooser:FindChild("wnd_ColorSwatch_Previous")
		wndCurrColor:SetBGColor(currColor)
		wndPrevColor:SetBGColor(prevColor)
	else
		local currColor = tColorList[1]
		local prevColor = "ff000000"
		local wndCurrColor = wndChooser:FindChild("wnd_ColorSwatch_Current")
		local wndPrevColor = wndChooser:FindChild("wnd_ColorSwatch_Previous")
		wndCurrColor:SetBGColor(currColor)
		wndPrevColor:SetBGColor(prevColor)
	end
end

function GeminiColor:SetNewColor(wndChooser, strColorCode)
	local data = wndChooser:GetData()
	tinsert(data.tColorList, 1, strColorCode)
	self:UpdateCurrPrevColors(wndChooser)
	FireCallback(wndChooser)
end

function GeminiColor:OnRGBAReturn(wndHandler, wndControl, strText)
	local wndChooser = wndControl:GetParent():GetParent():GetParent()  -- ancestor chain: input -> DisplayContainer -> wnd_Custom-> GeminiChooserForm
	local nText = tonumber(strmatch(strText, "(%d+)"))
	if not nText or nText < 0 or nText > 255 then
		self:SetRGB(wndChooser, self:HexToRGBA(wndChooser:GetData().tColorList[1]))
		return
	end
	local wndParent = wndControl:GetParent()
	local strNewHex = self:RGBAToHex(
		wndParent:FindChild("input_Red"):GetText(),
		wndParent:FindChild("input_Green"):GetText(),
		wndParent:FindChild("input_Blue"):GetText(),
		wndChooser:GetData().bAlpha and wndParent:FindChild("input_Alpha"):GetText() or nil
	)
	self:SetHSV(wndChooser, strNewHex)
	self:SetNewColor(wndChooser, strNewHex)
end

function GeminiColor:OnHexReturn(wndHandler, wndControl, strText)
	local wndChooser = wndControl:GetParent()
	local strHex = strmatch(strText, "(%x+)")
	local bAlpha = wndChooser:GetData().bAlpha
	local nStrSize = bAlpha and 8 or 6

	if not strHex or strlen(strHex) ~= nStrSize then
		local strNewHex = wndChooser:GetData().tColorList[1]
		if not bAlpha then strNewHex = strsub(strNewHex, 3) end
		wndControl:SetText(strNewHex)
		return
	end

	local strNewHex = bAlpha and strHex or ("ff" .. strHex)
	self:SetHSV(wndChooser, strNewHex)
	self:SetRGB(wndChooser, self:HexToRGBA(strNewHex))
	self:SetNewColor(wndChooser, strNewHex)
end

---------------------------------------------------------------------------------------------------
-- GeminiColor Dropdown Functions
---------------------------------------------------------------------------------------------------
function GeminiColor:CreateColorDropdown(wndHost, strSkin)
	-- wndHost = place holder window, used to get Window Name, Anchors and Offsets, and Parent
	-- strSkin = "Holo" or "Metal" -- not case sensitive

	if wndHost == nil then Print("You must supply a valid window for argument #1."); return end

	local fLeftAnchor, fTopAnchor, fRightAnchor, fBottomAnchor = wndHost:GetAnchorPoints()
	local fLeftOffset, fTopOffset, fRightOffset, fBottomOffset = wndHost:GetAnchorOffsets()
	local strName = wndHost:GetName()
	local wndParent = wndHost:GetParent()
	wndHost:Destroy()

	local wndDD = Apollo.LoadForm(self.xmlDoc, "ColorDDForm", wndParent, self)

	if strlower(strSkin) == strlower("metal") then
		wndDD:ChangeArt("CRB_Basekit:kitBtn_Dropdown_TextBaseHybrid")
		--CRB_Basekit:kitBtn_List_MetalContextMenu
	end

	local wndDDMenu = wndDD:FindChild("wnd_DDList")
	for i, v in pairs(ktColors) do
		local wndCurrColor = Apollo.LoadForm(self.xmlDoc,"ColorListItemForm",wndDDMenu,self)
		wndCurrColor:SetText(v.colorName)
		wndCurrColor:SetTextColor("ff"..v.strColor)
		wndCurrColor:FindChild("swatch"):SetBGColor("ff"..v.strColor)
		if strlower(strSkin) == strlower("metal") then
			wndDD:ChangeArt("CRB_Basekit:kitBtn_List_MetalContextMenu")
		end
	end
	wndDDMenu:ArrangeChildrenVert()
	wndDDMenu:Show(false)

	wndDD:SetAnchorPoints(fLeftAnchor, fTopAnchor, fRightAnchor, fBottomAnchor)
	wndDD:SetAnchorOffsets(fLeftOffset, fTopOffset, fRightOffset, fBottomOffset)
	wndDD:SetName(strName)

	return wndDD
end

function GeminiColor:OnColorDD(wndHandler, wndControl) -- Show DD List
	local wndDD = wndControl:FindChild("wnd_ColorDD")
	wndDD:Show(not wndDD:IsShown())
end

function GeminiColor:OnColorClick(wndHandler, wndControl) -- choose from DD list
	local strColorName = wndControl:GetText()
	local strColorCode = self:GetColorStringByName(strColorName)
	strColorCode = "FF"..strColorCode

	local wndChooser = wndControl:GetParent():GetParent()		-- parent path: button -> list window -> Dropdown
	wndChooser:FindChild("wnd_Text"):SetText(strColorName)
	wndChooser:FindChild("wnd_Text"):SetTextColor(strColorCode)

	wndChooser:SetData({
		strColor = strColorCode,
		strName = strColorName,
	})
	wndControl:GetParent():Show(false)
end

function GeminiColor:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

Apollo.RegisterPackage(GeminiColor:new(), MAJOR, MINOR, {})
