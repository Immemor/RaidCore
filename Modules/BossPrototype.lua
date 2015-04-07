local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

-------------------------------------------------------------------------------
-- Debug
--
local debug = false -- Set to true to get (very spammy) debug messages.
local dbg = function(self, msg) Print(format("[DBG:%s] %s", self.displayName, msg)) end

local function wipe(t)
	for k,v in pairs(t) do
		t[k] = nil
	end
end

local boss = {}

function boss:IsBossModule() return true end

function boss:OnInitialize()
	core:RegisterBossModule(self)
	-- Create an empty locale table.
	local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
	local sName = "RaidCore_" .. self:GetName()
	GeminiLocale:NewLocale(sName)
	self.L = GeminiLocale:GetLocale(sName)
end

function boss:OnEnable()
	if debug then dbg(self, "OnEnable()") end
	if self.SetupOptions then self:SetupOptions() end
	if type(self.OnBossEnable) == "function" then self:OnBossEnable() end
	Apollo.RegisterEventHandler("RAID_WIPE", "OnRaidWipe", self)
	self.isEngaged = false
	self.delayedmsg = {}
	--Print("Enabled Boss Module : " .. self.ModuleName)
end

function boss:OnDisable()
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

--function boss:GetOption(spellId)
--	return self.db.profile[spells[spellId]]
--end

function boss:Reboot(isWipe)
	-- Reboot covers everything including hard module reboots (clicking the minimap icon)
	--self:SendMessage("BigWigs_OnBossReboot", self)
	--if isWipe then
	--	-- Devs, in 99% of cases you'll want to use OnBossWipe
	--	self:SendMessage("BigWigs_OnBossWipe", self)
	--end
	self:Disable()
	self:Enable()
end

function boss:RegisterEnableMob(...) core:RegisterEnableMob(self, ...) end
function boss:RegisterEnableBossPair(...) core:RegisterEnableBossPair(self, ...) end
function boss:RegisterRestrictZone(...) core:RegisterRestrictZone(self, ...) end
function boss:RegisterRestrictEventObjective(...) core:RegisterRestrictEventObjective(self, ...) end
function boss:RegisterEnableEventObjective(...) core:RegisterEnableEventObjective(self, ...) end
function boss:RegisterEnableZone(...) core:RegisterEnableZone(self, ...) end
--function boss:RegisterEnableYell(...) core:RegisterEnableYell(self, ...) end

function boss:Start()
	if not self.isEngaged then
		self.isEngaged = true
		core:StartCombat(self.ModuleName)
		Print("Fight started : " .. self.ModuleName)
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

function boss:RegisterEnglishLocale(Locales)
  RegisterLocale(self, "enUS", Locales)
end

function boss:RegisterGermanLocale(Locales)
  RegisterLocale(self, "deDE", Locales)
end

function boss:RegisterFrenchLocale(Locales)
  RegisterLocale(self, "frFR", Locales)
end

function boss:OnRaidWipe()
	self.isEngaged = false
	self:CancelAllTimers()
	wipe(self.delayedmsg)
	if type(self.OnWipe) == "function" then self:OnWipe() end
end

function boss:Tank()
	local unit = GroupLib.GetGroupMember(1)
	if unit then return unit.bTank end
end

function boss:Msg(key, message, duration, sound, color)
	if not self.isEngaged then return end
	core:AddMsg(key, message, duration, sound, color)
end

function boss:DelayedMsg(key, delay, message, duration, sound, color)
	if not self.isEngaged then return end
	if self.delayedmsg[key] then
		self:CancelTimer(self.delayedmsg[key])
		self.delayedmsg[key] = nil
	end
	self.delayedmsg[key] = self:ScheduleTimer("Msg", delay, key, message, duration, sound, color)
end

local bossCore = core:NewModule("Bosses")
bossCore:SetDefaultModuleState(false)
bossCore:SetDefaultModulePrototype(boss)
bossCore:SetDefaultModulePackages("Gemini:Timer-1.0")
core.bossCore = bossCore
