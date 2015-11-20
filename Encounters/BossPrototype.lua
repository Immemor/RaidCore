------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--
-- EncounterPrototype contains all services useable by encounters itself.
--
------------------------------------------------------------------------------

local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local EncounterPrototype = {}

------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------
-- Register state allowed.
local TRIG__ALL = 1
local TRIG__ANY = 2
local TRIG_STATES = {
    ["ALL"] = TRIG__ALL,
    ["ANY"] = TRIG__ANY,
}

------------------------------------------------------------------------------
-- Locals
------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit

local function RegisterLocale(tBoss, sLanguage, Locales)
    local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
    local sName = "RaidCore_" .. tBoss:GetName()
    local L = GeminiLocale:NewLocale(sName, sLanguage, sLanguage == "enUS", true)
    if L then
        for key, val in next, Locales do
            L[key] = val
        end
    end
end

------------------------------------------------------------------------------
-- Encounter Prototype.
------------------------------------------------------------------------------
function EncounterPrototype:RegisterTrigMob(sTrigType, tTrigList)
    assert(type(tTrigList) == "table")
    local nTrigType = TRIG_STATES[sTrigType:upper()]
    assert(nTrigType)
    self.nTrigType = nTrigType
    self.EnableMob = tTrigList
end

-- Register a default config for bar manager.
-- @param tConfig  Array of Timer Options indexed by the timer's key.
function EncounterPrototype:RegisterDefaultTimerBarConfigs(tConfig)
    assert(type(tConfig) == "table")
    self.tDefaultTimerBarsOptions = tConfig
end

-- Register a default setting which will be saved in user profile file.
-- @param sKey  key to save/restore and use a setting.
-- @param bDefaultSetting  default setting.
function EncounterPrototype:RegisterDefaultSetting(sKey, bDefaultSetting)
    assert(sKey)
    assert(self.tDefaultSettings[sKey] == nil)
    self.tDefaultSettings[sKey] = bDefaultSetting == nil or bDefaultSetting
end

-- Add a message to screen.
-- @param sKey  Index which will be used to match on AddMsg.
-- @param sEnglishText  English text to search in language dictionnary.
-- @param nDuration  Timer duration.
-- @param sSound  The sound to be played back.
-- @param sColor  The color of the message.
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddMsg(sKey, sEnglishText, nDuration, sSound, sColor)
    RaidCore:AddMsg(sKey, self.L[sEnglishText], nDuration, sSound, sColor)
end

-- Create a timer bar.
-- @param sKey  Index which will be used to match on AddTimerBar.
-- @param sEnglishText  English text to search in language dictionnary.
-- @param nDuration  Timer duration.
-- @param bEmphasize  Timer count down requested (nil take the default one).
-- @param fHandler  function to call on timeout
-- @param tClass  Class used by callback action on timeout
-- @param tData  Data forwarded by callback action on timeout
--
-- Note: If the English translation is not found, the current string will be used like that.
function EncounterPrototype:AddTimerBar(sKey, sEnglishText, nDuration, bEmphasize, fHandler, tClass, tData)
    local tOptions = nil
    local sLocalText = self.L[sEnglishText]
    if self.tDefaultTimerBarsOptions[sKey] then
        tOptions = self.tDefaultTimerBarsOptions[sKey]
    else
        tOptions = {}
    end
    if bEmphasize ~= nil then
        tOptions["bEmphasize"] = bEmphasize and true
    end
    local tCallback = nil
    if type(fHandler) == "function" then
        tCallback = {
            fHandler = fHandler,
            tClass = tClass,
            tData = tData,
        }
    end
    RaidCore:AddTimerBar(sKey, sLocalText, nDuration, tCallback, tOptions)
end

-- Remove a timer bar if exist.
-- @param sKey  Index to remove.
function EncounterPrototype:RemoveTimerBar(sKey)
    RaidCore:RemoveTimerBar(sKey)
end

function EncounterPrototype:PrepareEncounter()
    local tmp = {}
    -- Translate trigger names.
    if self.EnableMob then
        -- Replace english data by local data.
        for _, EnglishKey in next, self.EnableMob do
            table.insert(tmp, self.L[EnglishKey])
        end
    end
    self.EnableMob = tmp
end

function EncounterPrototype:OnEnable()
    -- Copy settings for fast and secure access.
    self.tSettings = {}
    local tSettings = RaidCore.db.profile.Encounters[self:GetName()]
    if tSettings then
        for k,v in next, tSettings do
            self.tSettings[k] = v
        end
    end
    -- TODO: Redefine this part.
    self.tDispelInfo = {}
    if self.SetupOptions then self:SetupOptions() end
    if type(self.OnBossEnable) == "function" then self:OnBossEnable() end
end

function EncounterPrototype:OnDisable()
    if type(self.OnBossDisable) == "function" then self:OnBossDisable() end
    self:CancelAllTimers()
    if type(self.OnWipe) == "function" then self:OnWipe() end
    self.tDispelInfo = nil
end

function EncounterPrototype:Reboot(isWipe)
    -- Reboot covers everything including hard module reboots (clicking the minimap icon)
    self:Disable()
    self:Enable()
end

function EncounterPrototype:RegisterEnglishLocale(Locales)
    RegisterLocale(self, "enUS", Locales)
end

function EncounterPrototype:RegisterGermanLocale(Locales)
    RegisterLocale(self, "deDE", Locales)
end

function EncounterPrototype:RegisterFrenchLocale(Locales)
    RegisterLocale(self, "frFR", Locales)
end

-- Get setting value through the key.
-- @param sKey  index in the array.
-- @return  the key itself or false.
function EncounterPrototype:GetSetting(sKey)
    if self.tSettings[sKey] == nil then
        Print(("RaidCore warning: In '%s', setting \"%s\" don't exist."):format(self:GetName(), tostring(sKey)))
        self.tSettings[sKey] = false
    end
    return self.tSettings[sKey]
end

function EncounterPrototype:Tank()
    local unit = GroupLib.GetGroupMember(1)
    if unit then return unit.bTank end
end

--- Compute the distance between 2 unit.
-- @param tUnitFrom  userdata object from carbine.
-- @param tUnitTo  userdata object from carbine.
-- @return  The distance in meter.
function EncounterPrototype:GetDistanceBetweenUnits(tUnitFrom, tUnitTo)
    -- XXX If unit are unreachable, the distance should be nil.
    local r = 999
    if tUnitFrom and tUnitTo then
        local positionA = tUnitFrom:GetPosition()
        local positionB = tUnitTo:GetPosition()
        if positionA and positionB then
            local vectorA = Vector3.New(positionA)
            local vectorB = Vector3.New(positionB)
            r = (vectorB - vectorA):Length()
        end
    end
    return r
end

function EncounterPrototype:IsSpell2Dispel(nId)
    if self.tDispelInfo[nId] then
        for k,v in next, self.tDispelInfo[nId] do
            return true
        end
    end
    return false
end

function EncounterPrototype:AddSpell2Dispel(nId, nSpellId)
    if not self.tDispelInfo[nId] then
        self.tDispelInfo[nId] = {}
    end
    self.tDispelInfo[nId][nSpellId] = true
    RaidCore:AddPicture(("DISPEL%d"):format(nId), nId, "DispelWord", 30)
end

function EncounterPrototype:RemoveSpell2Dispel(nId, nSpellId)
    if self.tDispelInfo[nId] and self.tDispelInfo[nId][nSpellId] then
        self.tDispelInfo[nId][nSpellId] = nil
    end
    if not self:IsSpell2Dispel(nId) then
        RaidCore:RemovePicture(("DISPEL%d"):format(nId))
    end
end

function EncounterPrototype:SendIndMessage(sReason, tData)
    local msg = {
        action = "Encounter_IND",
        reason = sReason,
        data = tData,
    }
    RaidCore:SendMessage(msg)
end

--- Default trigger function to start an encounter.
-- @param tNames  Names of units without break space.
-- @return  Any unit registered can start the encounter.
function EncounterPrototype:OnTrig(tNames)
    if next(self.EnableMob) == nil then
        return false
    end
    if self.nTrigType == TRIG__ANY then
        for _, sMobName in next, self.EnableMob do
            if tNames[sMobName] then
                for nId, bInCombat in next, tNames[sMobName] do
                    if bInCombat then
                        return true
                    end
                end
            end
        end
        return false
    elseif self.nTrigType == TRIG__ALL then
        for _, sMobName in next, self.EnableMob do
            if not tNames[sMobName] then
                return false
            else
                local bResult = false
                for nId, bInCombat in next, tNames[sMobName] do
                    if bInCombat then
                        bResult = true
                    end
                end
                if not bResult then
                    return false
                end
            end
        end
        return true
    end
    return false
end

------------------------------------------------------------------------------
-- RaidCore interaction
------------------------------------------------------------------------------
do
    -- Sub modules are created when lua files are loaded by the WildStar.
    -- Default setting must be done before encounter loading so.
    RaidCore:SetDefaultModulePrototype(EncounterPrototype)
    RaidCore:SetDefaultModuleState(false)
    RaidCore:SetDefaultModulePackages("Gemini:Timer-1.0")
end

--- Registering a new encounter as a sub module of RaidCore.
--@param name  Name of the encounter to create
--@param continentId  Id list or id number
--@param parentMapId  Id list or id number
--@param mapId  Id list or id number
function RaidCore:NewEncounter(name, continentId, parentMapId, mapId)
    assert(name and continentId and parentMapId and mapId)
    -- Transform an unique key into a list with 1 entry, if needed.
    local continentIdList = type(continentId) == "table" and continentId or { continentId }
    local parentMapIdList = type(parentMapId) == "table" and parentMapId or { parentMapId }
    local mapIdList = type(mapId) == "table" and mapId or { mapId }

    -- Create the new encounter, and set zone identifiers.
    -- Library already manage unique name.
    new = self:NewModule(name)
    new.continentIdList = continentIdList
    new.parentMapIdList = parentMapIdList
    new.mapIdList = mapIdList
    new.displayName = name
    new.tDefaultTimerBarsOptions = {}
    -- Register an empty locale table.
    new:RegisterEnglishLocale({})
    -- Retrieve Locale.
    local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
    new.L = GeminiLocale:GetLocale("RaidCore_" .. name)
    -- Create a empty array for settings.
    new.tDefaultSettings = {}
    return new
end
