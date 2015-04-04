GeminiLocale
============

Library for managing localization in addons, allowing for multiple locale to be registered with fallback to the base locale for untranslated strings.

#### Example Usage

```lua
-- enUS.lua
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("MyAddon", "enUS", true)
L["string1"] = true

-- deDE.lua
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("MyAddon", "deDE")
if not L then return end
L["string1"] = "Zeichenkette1" 

-- addon.lua
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("MyAddon", true)
self.wndMain:FindChild("SomeLabel"):SetText(L["string1"])
```

### Window Translation

Window translation is limited to translating the text field on a control.

* Tooltips are not supported.  
* Pixies are not supported.

For window translation support to work, you will need to wrap your text to be translated with 3 underscores: `___Sample String___`
 
When you call GeminiLocale:TranslateWindow, it will look for "Sample String" in your locale table and apply the translation.

#### Example Usage

```lua
-- addon.lua
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage

self.wndMain = ... -- load your window/form here
self.wndMain:FindChild("SomeLabel"):SetText("___string1___") -- this can be set when designing the window in Houston.

local L = GeminiLocale:GetLocale("TestLocale", true)
GeminiLocale:TranslateWindow(L, self.wndMain)
```

SomeLabel will have it's text set to "string1" for enUS or "Zeichenkette1" for deDE.
