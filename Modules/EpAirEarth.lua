--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpAirEarth", 52)
if not mod then return end

--mod:RegisterEnableMob("Megalith")
mod:RegisterEnableBossPair("Megalith", "Aileron")
mod:RegisterRestrictZone("EpAirEarth", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Megalith"] = "Megalith",
	["Aileron"] = "Aileron",
	["Air Column"] = "Air Column",
	-- Datachron messages.
	["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith",
	["fractured crust leaves it exposed"] = "fractured crust leaves it exposed",
	-- Cast.
	["Supercell"] = "Supercell",
	["Raw Power"] = "Raw Power",
	-- Bar and messages.
	["MOO !"] = "MOO !",
	["EARTH"] = "EARTH",
	["~Tornado Spawn"] = "~Tornado Spawn",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})
mod:RegisterGermanLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local midphase = false
local startTime

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	--Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
end

local function GetSetting(key)
	return core:GetSettings()["DS"]["AirEarth"][key]
end

local function GetSoundSetting(sound, key)
	if core:GetSettings()["DS"]["AirEarth"][key] then return sound else return nil end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit, sName)
	local eventTime = GameLib.GetGameTime()
	--Print(sName)
	if sName == self.L["Air Column"] then
		if GetSetting("LineTornado") then
			core:AddLine(unit:GetId(), 2, unit, nil, 3, 30, 0, 10)
		end
		if eventTime > startTime + 10 then
			core:StopBar("TORNADO")
			core:AddBar("TORNADO", self.L["~Tornado Spawn"], 17, GetSetting("SoundTornadoCountdown"))
		end
	end
end

function mod:OnUnitDestroyed(unit, sName)
	local sName = unit:GetName()
	--Print(sName)
	if sName == self.L["Air Column"] then
		core:DropLine(unit:GetId())
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Megalith"] and castName == self.L["Raw Power"] then
			midphase = true
			core:AddMsg("RAW", self.L["Raw Power"]:upper(), 5, GetSoundSetting("Alert", "SoundMidphase"))
	elseif unitName == self.L["Aileron"] and castName == self.L["Supercell"] then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 30 then
			prev = timeOfEvent
			core:AddMsg("CELL", self.L["Supercell"]:upper(), 5, GetSoundSetting("Alarm", "SoundSupercell"))
			core:AddBar("CELL", self.L["Supercell"]:upper(), 80)
		end
	end
end

function mod:OnChatDC(message)
	if message:find(self.L["The ground shudders beneath Megalith"]) then
		core:AddMsg("QUAKE", "JUMP !", 3, GetSoundSetting("Beware", "SoundQuakeJump"))
	elseif message:find(self.L["fractured crust leaves it exposed"]) and midphase then
		midphase = false
		core:AddMsg("MOO", self.L["MOO !"], 5, "Info", GetSoundSetting("Blue", "SoundMoO"))
		core:AddBar("RAW", self.L["Raw Power"]:upper(), 60, GetSetting("SoundMidphase"))
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local eventTime = GameLib.GetGameTime()
		startTime = eventTime

		if sName == self.L["Megalith"] then
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:MarkUnit(unit, nil, self.L["EARTH"])
		elseif sName == self.L["Aileron"] then
			self:Start()
			prev = 0
			midphase = false
			if GetSetting("LineCleaveAileron") then
				core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 15, 0)
			end
			core:AddBar("SCELL", self.L["Supercell"], 65, GetSetting("SoundSupercell"))
			core:AddBar("TORNADO", self.L["~Tornado Spawn"], 16, GetSetting("SoundTornadoCountdown"))
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			--Print(eventTime .. "FIGHT STARTED")
		end
	end
end