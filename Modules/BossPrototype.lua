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
local DEBUG = false -- Set to true to get (very spammy) debug messages.

------------------------------------------------------------------------------
-- Privates
------------------------------------------------------------------------------
local function assertfalse()
	assert(false)
end

local function dbg(self, msg)
	Print(format("[DBG:%s] %s", self.displayName, msg))
end

local function wipe(t)
	for k,v in pairs(t) do
		t[k] = nil
	end
end

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
function EncounterPrototype:RegisterEnableMob(...)
	self.EnableMob = { ... }
end

function EncounterPrototype:RegisterRestrictZone(todrop, ...)
	self.RestrictZone = { ... }
end

function EncounterPrototype:RegisterEnableZone(todrop, ...)
	self.EnableZone = { ... }
end

function EncounterPrototype:RegisterRestrictEventObjective(todrop, ...)
	self.RestrictEventObjective = { ... }
end

function EncounterPrototype:RegisterEnableEventObjective(todrop, ...)
	self.EnableEventObjective = { ... }
end

function EncounterPrototype:RegisterEnableBossPair(...)
	self.EnableBossPair = { ... }
end

function EncounterPrototype:PrepareEncounter()
	-- Invalid registering functions.
	self.RegisterEnableMob = assertfalse
	self.RegisterRestrictZone = assertfalse
	self.RegisterEnableZone = assertfalse
	self.RegisterRestrictEventObjective = assertfalse
	self.RegisterEnableEventObjective = assertfalse
	self.RegisterEnableBossPair = assertfalse

	local keys = {
		"EnableMob", "EnableBossPair",
		"RestrictZone", "EnableZone",
		"RestrictEventObjective", "EnableEventObjective",
	}
	-- Translate all fields.
	for _, field in next, keys do
		if self[field] then
			local tmp = {}
			-- Global dictionnary or encounter dictionnary.
			local ref = RaidCore
			if field == "EnableMob" or field == "EnableBossPair" then
				ref = self
			end
			for _, EnglishKey in next, self[field] do
				table.insert(tmp, ref.L[EnglishKey])
			end
			-- Replace english data by local data.
			self[field] = tmp
			-- Do the link with current RaidCore implementation.
			local handler = RaidCore[("Register%s"):format(field)]
			handler(RaidCore, self, self[field])
		end
	end
end

function EncounterPrototype:IsBossModule()
	return true
end

function EncounterPrototype:OnInitialize()
end

function EncounterPrototype:OnEnable()
	if DEBUG then dbg(self, "OnEnable()") end
	if self.SetupOptions then self:SetupOptions() end
	if type(self.OnBossEnable) == "function" then self:OnBossEnable() end
	Apollo.RegisterEventHandler("RAID_WIPE", "OnRaidWipe", self)
	self.isEngaged = false
	self.delayedmsg = {}
	--Print("Enabled Boss Module : " .. self.ModuleName)
end

function EncounterPrototype:OnDisable()
	if type(self.OnBossDisable) == "function" then self:OnBossDisable() end
	self.isEngaged = nil
	Apollo.RemoveEventHandler("UnitCreated",self)
	Apollo.RemoveEventHandler("UnitEnteredCombat", self)
	Apollo.RemoveEventHandler("UnitDestroyed", self)
	Apollo.RemoveEventHandler("RC_UnitCreated", self)
	Apollo.RemoveEventHandler("RC_UnitStateChanged", self)
	Apollo.RemoveEventHandler("RC_UnitDestroyed", self)
	Apollo.RemoveEventHandler("SPELL_CAST_START", self)
	Apollo.RemoveEventHandler("SPELL_CAST_END", self)
	Apollo.RemoveEventHandler("UNIT_HEALTH", self)
	Apollo.RemoveEventHandler("CHAT_DATACHRON", self)
	Apollo.RemoveEventHandler("CHAT_NPCSAY", self)
	Apollo.RemoveEventHandler("RAID_WIPE", self)
	Apollo.RemoveEventHandler("RAID_SYNC", self)
	Apollo.RemoveEventHandler("DEBUFF_APPLIED", self)
	Print("Unloaded Boss Module : " .. self.ModuleName)
end

--function EncounterPrototype:GetOption(spellId)
--	return self.db.profile[spells[spellId]]
--end

function EncounterPrototype:Reboot(isWipe)
	-- Reboot covers everything including hard module reboots (clicking the minimap icon)
	--self:SendMessage("BigWigs_OnBossReboot", self)
	--if isWipe then
	--	-- Devs, in 99% of cases you'll want to use OnBossWipe
	--	self:SendMessage("BigWigs_OnBossWipe", self)
	--end
	self:Disable()
	self:Enable()
end

function EncounterPrototype:Start()
	if not self.isEngaged then
		self.isEngaged = true
		RaidCore:StartCombat(self.ModuleName)
		Print("Fight started : " .. self.ModuleName)
	end
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

function EncounterPrototype:GetSetting(setting, returnString)
	if not setting then return false end
	local settingValue = core.settings[self:GetName() ..  "_" .. setting]
	if returnString and settingValue then
		return returnString
	else
		return settingValue
	end
end

function EncounterPrototype:OnRaidWipe()
	self.isEngaged = false
	self:CancelAllTimers()
	wipe(self.delayedmsg)
	if type(self.OnWipe) == "function" then self:OnWipe() end
end

function EncounterPrototype:Tank()
	local unit = GroupLib.GetGroupMember(1)
	if unit then return unit.bTank end
end

function EncounterPrototype:Msg(key, message, duration, sound, color)
	if not self.isEngaged then return end
	RaidCore:AddMsg(key, message, duration, sound, color)
end

function EncounterPrototype:DelayedMsg(key, delay, message, duration, sound, color)
	if not self.isEngaged then return end
	if self.delayedmsg[key] then
		self:CancelTimer(self.delayedmsg[key])
		self.delayedmsg[key] = nil
	end
	self.delayedmsg[key] = self:ScheduleTimer("Msg", delay, key, message, duration, sound, color)
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
	-- Register an empty locale table.
	new:RegisterEnglishLocale({})
	-- Retrieve Locale.
	local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
	new.L = GeminiLocale:GetLocale("RaidCore_" .. name)
	return new
end
