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

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStateChanged", self)
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

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Avatus Hologram" then
		self:Start()
		core:AddBar("JUMP", "Encounter Start", 8.5, 1)
		bossPos = {}
	elseif sName == "Wind Wall" and GetSetting("LineWindWalls") then
		core:AddPixie(unit:GetId().."_1", 2, unit, nil, "Green", 10, 20, 0)
		core:AddPixie(unit:GetId().."_2", 2, unit, nil, "Green", 10, 20, 180)
		--core:AddLine(unit:GetId().."_1", 2, unit, nil, 1, 20, 0)
		--core:AddLine(unit:GetId().."_2", 2, unit, nil, 1, 20, 180)
	elseif sName == "Weather Station" then
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

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Wind Wall" then
		--core:DropLine(unit:GetId().."_1")
		--core:DropLine(unit:GetId().."_2")
		core:DropPixie(unit:GetId().."_1")
		core:DropPixie(unit:GetId().."_2")
	elseif sName == "Weather Station" then
		core:DropPixie(unit:GetId())
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Maelstrom Authority" and castName == "Activate Weather Cycle" then
		bossPos = unit:GetPosition()
		--local Rover = Apollo.GetAddon("Rover")
		--Rover:AddWatch("bossPoss", bossPos, 0)
		stationCount = 0
		core:AddBar("STATION", ("[%s] STATION"):format(stationCount + 1), 13)
	elseif unitName == "Maelstrom Authority" and castName == "Ice Breath" then
		core:AddMsg("BREATH", "ICE BREATH", 5, GetSoundSetting("RunAway", "SoundIcyBreath"))
	elseif unitName == "Maelstrom Authority" and castName == "Crystallize" then
		core:AddMsg("BREATH", "ICE BREATH", 5, GetSoundSetting("Beware", "SoundCrystallize"))
	elseif unitName == "Maelstrom Authority" and castName == "Typhoon" then
		core:AddMsg("BREATH", "TYPHOON", 5, GetSoundSetting("Beware", "SoundTyphoon"))
	end
end

function mod:OnChatDC(message)
	if message:find("The platform trembles") then
		core:AddBar("JUMP", "JUMP", 7, 14)
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Maelstrom Authority" then
			stationCount = 0
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			if GetSetting("LineCleaveBoss") then
				core:AddPixie(unit:GetId(), 2, unit, nil, "Red", 10, 15, 0)
			end
		elseif sName == "Weather Station" then
			stationCount = stationCount + 1
			local station_name = "STATION" .. tostring(stationCount)

			local posStr = ""
			local stationPos = unit:GetPosition()
			if stationPos and bossPos then
				core:AddMsg(station_name, ("[%s] STATION : %s %s"):format(stationCount, (stationPos.z > bossPos.z) and "SOUTH" or "NORTH", (stationPos.x > bossPos.x) and "EAST" or "WEST"), 5, GetSoundSetting("Info", "SoundWeatherStationSwitch"), "Blue")
			else
				core:AddMsg(station_name, ("[%s] STATION"):format(stationCount), 5, GetSoundSetting("Info", "SoundWeatherStationSwitch"), "Blue")
			end
			core:AddBar(station_name, ("[%s] STATION"):format(stationCount + 1), 10)
		end
	end
end
