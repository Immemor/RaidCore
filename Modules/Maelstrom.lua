--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Maelstrom", 52)
if not mod then return end

mod:RegisterEnableMob("Weather Control Station")

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local stationCount = 0
local bossPos = {}
mod:RegisterEnglishLocale({
	-- Unit names.
	["Wind Wall"] = "Wind Wall",
	["Avatus Hologram"] = "Avatus Hologram",
	["Weather Station"] = "Weather Station",
	["Maelstrom Authority"] = "Maelstrom Authority",
	-- Datachron messages.
	["The platform trembles"] = "The platform trembles",
	-- Cast.
	["Activate Weather Cycle"] = "Activate Weather Cycle",
	["Ice Breath"] = "Ice Breath",
	["Crystallize"] = "Crystallize",
	["Typhoon"] = "Typhoon",
	-- Bar and messages.
	["[%u] STATION: %s %s"] = "[%u] STATION: %s %s",
	["[%u] STATION"] = "[%u] STATION",
	["ICE BREATH"] = "ICE BREATH",
	["TYPHOON"] = "TYPHOON",
	["JUMP"] = "JUMP",
	["Encounter Start"] = "Encounter Start",
	["NORTH"] = "NORTH",
	["SOUTH"] = "SOUTH",
	["EAST"] = "EAST",
	["WEST"] = "WEST",
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
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

local function GetSetting(key)
	return core:GetSettings()["DS"]["Maelstrom"][key]
end

local function GetSoundSetting(sound, key)
	if core:GetSettings()["DS"]["Maelstrom"][key] then return sound else return nil end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit, sName)
	--Print(sName)
	if sName == self.L["Avatus Hologram"] then
		self:Start()
		core:AddBar("JUMP", self.L["Encounter Start"], 8.5, 1)
		bossPos = {}
	elseif sName == self.L["Wind Wall"] and GetSetting("LineWindWalls") then
		core:AddPixie(unit:GetId().."_1", 2, unit, nil, "Green", 10, 20, 0)
		core:AddPixie(unit:GetId().."_2", 2, unit, nil, "Green", 10, 20, 180)
		--core:AddLine(unit:GetId().."_1", 2, unit, nil, 1, 20, 0)
		--core:AddLine(unit:GetId().."_2", 2, unit, nil, 1, 20, 180)
	elseif sName == self.L["Weather Station"] then
		-- Todo see if we can concat position to display in unit monitor.
		local stationPos = unit:GetPosition()
		--local Rover = Apollo.GetAddon("Rover")
		--Rover:AddWatch("stationPos", stationPos, 0)
		--local posStr = (stationPos.z > bossPos.z) and "S" or "N", (stationPos.x > bossPos.x) and "E" or "W"
		core:AddUnit(unit)
		if GetSetting("LineWeatherStations") then
			local playerUnit = GameLib.GetPlayerUnit()
			core:AddPixie(unit:GetId(), 1, playerUnit, unit, "Blue", 5, 10, 10)
		end
	end
end

function mod:OnUnitDestroyed(unit, sName)
	--Print(sName)
	if sName == self.L["Wind Wall"] then
		--core:DropLine(unit:GetId().."_1")
		--core:DropLine(unit:GetId().."_2")
		core:DropPixie(unit:GetId().."_1")
		core:DropPixie(unit:GetId().."_2")
	elseif sName == self.L["Weather Station"] then
		core:DropPixie(unit:GetId())
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Maelstrom Authority"] then
		if castName == self.L["Activate Weather Cycle"] then
			bossPos = unit:GetPosition()
			--local Rover = Apollo.GetAddon("Rover")
			--Rover:AddWatch("bossPoss", bossPos, 0)
			stationCount = 0
			core:AddBar("STATION", self.L["[%u] STATION"]:format(stationCount + 1), 13)
		elseif castName == self.L["Ice Breath"] then
			core:AddMsg("BREATH", self.L["ICE BREATH"], 5, GetSoundSetting("RunAway", "SoundIcyBreath"))
		elseif castName == self.L["Crystallize"] then
			core:AddMsg("BREATH", self.L["ICE BREATH"], 5, GetSoundSetting("Beware", "SoundCrystallize"))
		elseif castName == self.L["Typhoon"] then
			core:AddMsg("BREATH", self.L["TYPHOON"], 5, GetSoundSetting("Beware", "SoundTyphoon"))
		end
	end
end

function mod:OnChatDC(message)
	if message:find(self.L["The platform trembles"]) then
		core:AddBar("JUMP", self.L["JUMP"], 7, 14)
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Maelstrom Authority"] then
			stationCount = 0
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			if GetSetting("LineCleaveBoss") then
				core:AddPixie(unit:GetId(), 2, unit, nil, "Red", 10, 15, 0)
			end
		elseif sName == self.L["Weather Station"] then
			stationCount = stationCount + 1
			local station_name = "STATION" .. tostring(stationCount)

			local posStr = ""
			local stationPos = unit:GetPosition()
			if stationPos and bossPos then
				local text = self.L["[%u] STATION: %s %s"]:format(
					stationCount,
					(stationPos.z > bossPos.z) and self.L["SOUTH"] or self.L["NORTH"],
					(stationPos.x > bossPos.x) and self.L["EAST"] or self.L["WEST"])
				core:AddMsg(station_name, text, 5, GetSoundSetting("Info", "SoundWeatherStationSwitch"), "Blue")
			else
				local text = self.L["[%u] STATION"]:format(stationCount)
				core:AddMsg(station_name, text, 5, GetSoundSetting("Info", "SoundWeatherStationSwitch"), "Blue")
			end
			local text = self.L["[%u] STATION"]:format(stationCount + 1)
			core:AddBar(station_name, text, 10)
		end
	end
end
