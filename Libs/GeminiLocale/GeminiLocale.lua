-------------------------------------------------------------------------------
-- GeminiLocale
-- Author: daihenka
-- Localization library based on AceLocale.
-- Parts of this library was inspired and/or contains snippets from 
-- AceLocale-3.0.lua by Kaelten
-------------------------------------------------------------------------------

local MAJOR, MINOR = "Gemini:Locale-1.0", 4
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade is needed
end
local Lib = APkg and APkg.tPackage or {}

local assert, tostring, error, pcall = assert, tostring, error, pcall
local getmetatable, setmetatable, rawset, rawget, pairs = getmetatable, setmetatable, rawset, rawget, pairs

-- this locale lookup table is accurate for build 6512
local ktLocales = {
	[1] = "enUS",
	[2] = "deDE",
	[3] = "frFR",
	[4] = "koKR",
}

-- access to read the locale.languageId console variable has been disabled
-- check what the Apollo.GetString(1) (aka "Cancel") is translated into and 
-- return the language locale
local function GetLocale()
	local strCancel = Apollo.GetString(1)
	
	-- German
	if strCancel == "Abbrechen" then 
		return ktLocales[2]
	end
	
	-- French
	if strCancel == "Annuler" then
		return ktLocales[3]
	end
	
	-- Other
	return ktLocales[1]
--	return ktLocales[(Apollo.GetConsoleVariable("locale.languageId") or 1)]
end

Lib.apps = Lib.apps or {}
Lib.appnames = Lib.appnames or {}

local readmeta = {
	__index = function(self, key)
		rawset(self, key, key)
		Print(MAJOR .. ": " .. tostring(Lib.appnames[self]) .. ": Missing entry for '" .. tostring(key) .. "'")
		return key
	end
}

local readmetasilent = {
	__index = function(self, key)
		rawset(self, key, key)
		return key
	end
}

-- Remember the locale table being registered (set by :NewLocale())
-- NOTE: Never try to register 2 locale tables at one and mix their definition.
local registering
local assertfalse = function() assert(false) end

-- This metatable proxy is used when registering nondefault locales
local writeproxy = setmetatable({}, {
	__newindex = function(self, key, value)
		rawset(registering, key, value == true and key or value) -- assigning values: replace 'true' with key string
	end,
	__index = assertfalse
})

-- This metatable proxy is used when registering the default locale.
-- It refuses to overwrite existing values
-- Reason 1: Allows loading locales in any order
-- Reason 2: If 2 modules have the same string, but only the first one to be
--           loaded has a translation for the current locale, the translation
--           doesn't get overwritten.
--

local writedefaultproxy = setmetatable({}, {
	__newindex = function(self, key, value)
		if not rawget(registering, key) then
			rawset(registering, key, value == true and key or value)
		end
	end,
	__index = assertfalse
})
-- Register a new locale (or extend an existing one) for the specified application.
-- :NewLocale will return a table you can fill your locale into, or nil if the locale isn't needed for the players
-- game locale.
-- @paramsig application, locale[, isDefault[, silent]]
-- @param application Unique name of addon / module
-- @param locale Name of the locale to register, e.g. "enUS", "deDE", etc.
-- @param isDefault If this is the default locale being registered (your addon is written in this language, generally enUS)
-- @param silent If true, the locale will not issue warnings for missing keys. Must be set on the first locale registered. If set to "raw", nils will be returned for unknown keys (no metatable used).
-- @return Locale Table to add localizations to, or nil if the current locale is not required.
--
-- @usage
-- -- enUS.lua
-- local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("TestLocale", "enUS", true)
-- L["string1"] = true
--
-- -- deDE.lua
-- local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("TestLocale", "deDE")
-- if not L then return end
-- L["string1"] = "Zeichenkette1"

function Lib:NewLocale(application, locale, isDefault, silent)
	local app = Lib.apps[application]
	
	if silent and app and getmetatable(app) ~= readmetasilent then
		error("Usage: NewLocale(application, locale[, isDefault[, silent]]): 'silent' must be specified for the first locale registered")
	end
	
	if not app then
		if silent == "raw" then
			app = {}
		else
			app = setmetatable({}, silent and readmetasilent or readmeta)
		end
		Lib.apps[application] = app
		Lib.appnames[app] = application
	end
	
	if locale ~= GetLocale() and not isDefault then
		return -- translations are not needed
	end
	
	registering = app -- remember globally for writeproxy and writedefaultproxy
	
	if isDefault then
		return writedefaultproxy
	end
	
	return writeproxy
end



--- Returns localizations for the current locale (or default locale if translations are missing).
-- Errors if nothing is registered (spank developer, not just a missing translation)
-- @param application Unique name of addon / module
-- @param silent If true, the locale is optional, silently return nil if it's not found (defaults to false, optional)
-- @return The locale table for the current language.
function Lib:GetLocale(application, silent)
	if not silent and not Lib.apps[application] then
		error("Usage: GetLocale(application[, silent]): 'application' - No locales registered for '" .. tostring(application) .. "'", 2)
	end
	return Lib.apps[application]
end

--- Walks a window and translates text to the current locale (or default locale if translations are missing).
-- @param locale table for the current language
-- @param the window object to translate
function Lib:TranslateWindow(tLocale, wndParent)
	if wndParent == nil or tLocale == nil then
		return
	end
  
  
	do -- text fields
		-- ignore any errors thrown due to the control not having a GetText method
		local _, strText = pcall(function() return wndParent:GetText() end)
		if strText ~= nil then
			local bFound, _, strKey = strText:find("^___(.*)___$")
			if bFound then
				-- found a string to translate
				wndParent:SetText(tLocale[strKey])
			end
		end
	end
  
  -- This code block will probably not do anything except loop through each pixie as strText is never(?) returned
  -- Once GetPixieInfo returns a complete table, this should spring to life (and hopefully not bug out).
	local nPixieId = 1
	while true do
		local _, tPixieInfo = pcall(function() return wndParent:GetPixieInfo(nPixieId) end)
		if tPixieInfo ~= nil then
      if tPixieInfo.strText ~= nil then
        local bFound, _, strKey = string.find(tPixieInfo.strText, "^___(.*)___$")
        if bFound then
          -- found a string to translate
          tPixieInfo.strText = tLocale[strKey]
          wndParent:UpdatePixie(nPixieId, tPixieInfo)
        end
      end
		else
			-- no pixie dust left :(
			break
		end
		nPixieId = nPixieId + 1
	end
	
	-- recursively translate the controls
  local _, tChildren = pcall(function() return wndParent:GetChildren() end)
  if tChildren ~= nil then
    for idx, wndCurr in pairs(tChildren) do
      self:TranslateWindow(tLocale, wndCurr)
    end
  end
end

function Lib:OnLoad()
end

function Lib:OnDependencyError(strDep, strError)
  return false
end

Apollo.RegisterPackage(Lib, MAJOR, MINOR, {})
