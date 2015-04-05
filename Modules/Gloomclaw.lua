--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Gloomclaw", 52)
if not mod then return end

mod:RegisterEnableMob("Gloomclaw")

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local waveCount, ruptCount, essenceUp = 0, 0, {}
local first = true
local section = 1
local leftSpawn = {
	{x = 4288.5, y = -568.48095703125, z = -16765.66796875 },
	{x = 4288.5, y = -568.30078125, z = -16858.9765625 },
	{x = 4288.5, y = -568.95300292969, z = -16949.40234375 },
	{x = 4288.5, y = -568.95300292969, z = -17040.22265625 },
	{x = 4288.5, y = -568.95300292969, z = -17040.099609375 }
}

local rightSpawn = {
	{x = 4332.5, y = -568.4833984375, z = -16765.66796875 },
	{x = 4332.5, y = -568.45147705078, z = -16858.9765625 },
	{x = 4332.5, y = -568.95300292969, z = -16949.40234375 },
	{x = 4332.5, y = -568.95300292969, z = -17040.22265625 },
	{x = 4332.5, y = -568.95300292969, z = -17040.099609375 }
}

local spawnTimer = {
	26,
	33,
	25,
	14,
	20.5
}

local spawnCount = {
	4,
	3,
	4,
	5,
	5
}

local maulerSpawn = {
	["northwest"] = { x = 4288, y = -568, z = -17040 },
	["northeast"] = { x = 4332, y = -568, z = -17040 },
	["southwest"] = { x = 4288, y = -568, z = -16949 }, --todo check if these 2 are sw/se or other way around
	["southeast"] = { x = 4332, y = -568, z = -16949 },
}
--[[
L1 : 4288.5, -568.48095703125, -16765.66796875
R1 : 4332.5, -568.4833984375, -16765.66796875

L2 : 4288.5, -568.30078125, -16858.9765625
R2 : 4332.5, -568.45147705078, -16858.9765625

L3 : 4288.5, -568.95300292969, -16949.40234375
R3 : 4332.5, -568.95300292969, -16949.40234375

L4 : 4288.5, -568.95300292969, -17040.22265625
R4 : 4332.5, -568.95300292969, -17040.22265625

L5 : 4288.5, -568.95300292969, -17054.87109375
R5 : 4332.5, -568.95300292969, -17054.87109375
]]--

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

local function GetSetting(key)
	return core:GetSettings()["DS"]["Gloomclaw"][key]
end

local function GetSoundSetting(sound, key)
	if core:GetSettings()["DS"]["Gloomclaw"][key] then return sound else return nil end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function dist2unit(unitSource, unitTarget)
	if not unitSource or not unitTarget then return 999 end
	local sPos = unitSource:GetPosition()
	local tPos = unitTarget:GetPosition()

	local sVec = Vector3.New(sPos.x, sPos.y, sPos.z)
	local tVec = Vector3.New(tPos.x, tPos.y, tPos.z)

	local dist = (tVec - sVec):Length()

	return tonumber(dist)
end

function mod:OnWipe()
	Apollo.RemoveEventHandler("CombatLogHeal", self)
	core:ResetWorldMarkers()
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--Print(sName .. " Created")
	--[[
	if sName == "Datascape Corruption Pool" then
		core:MarkUnit(unit)
	end--]]
	if sName == "Corrupted Ravager" or sName == "Empowered Ravager" then
		core:WatchUnit(unit)
	elseif sName == "Volatile Mauler" then
		--local Rover = Apollo.GetAddon("Rover")
		--Rover:AddWatch("Mauler", unit:GetPosition(), 0)
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	--Print(castName .. " by " .. unitName)
	if unitName == "Gloomclaw" and castName == "Rupture" then
		ruptCount = ruptCount + 1
		core:AddMsg("RUPTURE", "INTERRUPT BOSS", 5, GetSoundSetting("Destruction", "SoundRuptureInterrupt"))
		if ruptCount == 1 then
			core:AddBar("RUPTURE", "RUPTURE", 43, GetSoundSetting(true, "SoundRuptureCountdown"))
		end
	elseif (unitName == "Corrupted Ravager" or unitName == "Empowered Ravager") and castName == "Corrupting Rays" then
		local playerUnit = GameLib.GetPlayerUnit()
		local distance_to_unit = dist2unit(playerUnit, unit)
		if distance_to_unit < 35 then
			core:AddMsg("RAYS", "INTERRUPT SPIDER", 5, GetSoundSetting("Inferno", "SoundCorruptingRays"))
		end
	end
end

function mod:OnChatDC(message)
	if message:find("Gloomclaw is pushed back by the purification of the essences") or message:find("Gloomclaw is moving forward to corrupt more essences!") then
		if not first then
			waveCount, ruptCount, prev = 0, 0, 0
			core:StopBar("RUPTURE")
			core:StopBar("CORRUPTION")
			core:StopBar("WAVE")
			if message:find("pushed") then
				section = section + 1
			else
				section = section - 1
			end
			core:AddMsg("PHASE", ("SECTION %s"):format(section), 5, GetSoundSetting("Info", "SoundSectionSwitch"), "Blue")
			if section ~= 4 then 
				core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 11)
				core:AddBar("RUPTURE", "RUPTURE", 39, GetSoundSetting(true, "SoundRuptureCountdown"))
			end
			core:AddBar("CORRUPTION", "FULL CORRUPTION", 111, GetSoundSetting(true, "SoundCorruptionCountdown"))
		else
			first = false
		end
		core:ResetWorldMarkers()
		if GetSetting("OtherMaulerMarkers") then
			core:SetWorldMarker(maulerSpawn["northwest"], "FROG 1")
			core:SetWorldMarker(maulerSpawn["northeast"], "FROG 2")
			core:SetWorldMarker(maulerSpawn["southeast"], "FROG 3")
			core:SetWorldMarker(maulerSpawn["southwest"], "FROG 4")
		end
		if GetSetting("OtherLeftRightMarkers") and leftSpawn[section] then
			core:SetWorldMarker(leftSpawn[section], "LEFT")
		end
		if GetSetting("OtherLeftRightMarkers") and rightSpawn[section] then
			core:SetWorldMarker(rightSpawn[section], "RIGHT")
		end
		Apollo.RegisterEventHandler("CombatLogHeal", "OnCombatLogHeal", self)
	elseif message:find("Gloomclaw is reduced to a weakened state") then
		core:StopBar("RUPTURE")
		core:StopBar("CORRUPTION")
		core:StopBar("WAVE")
		core:AddMsg("TRANSITION", "TRANSITION", 5, GetSoundSetting("Alert", "SoundMoOWarning"))
		core:AddBar("MOO", "MOO PHASE", 15)
		for unitId, v in pairs(essenceUp) do
			core:RemoveUnit(unitId)
			essenceUp[unitId] = nil
		end
		--essenceUp = {}
	elseif message:find("Gloomclaw is vulnerable") then
		core:StopBar("RUPTURE")
		core:StopBar("CORRUPTION")
		core:StopBar("WAVE")
		core:AddMsg("TRANSITION", "BURN HIM HARD", 5, GetSoundSetting("Alert", "SoundMoOWarning"))
		core:AddBar("MOO", "MOO PHASE", 20, GetSoundSetting(true, "SoundMoOWarning"))
		for unitId, v in pairs(essenceUp) do
			core:RemoveUnit(unitId)
			essenceUp[unitId] = nil
		end
		--essenceUp = {}
	end
end

function mod:OnCombatLogHeal(tArgs)
	if tArgs.unitTarget and tArgs.unitTarget:GetName() == "Essence of Logic" then
		if not essenceUp[tArgs.unitTarget:GetId()] then
			--Print("Found EssLogic : ".. tArgs.unitTarget:GetId())
			essenceUp[tArgs.unitTarget:GetId()] = true
			local essPos = tArgs.unitTarget:GetPosition()
			core:MarkUnit(tArgs.unitTarget, 0, (essPos.x < 4310) and "L" or "R")
			core:AddUnit(tArgs.unitTarget)
			if #essenceUp == 2 then
				--Print("Found 2 essences")
				Apollo.RemoveEventHandler("CombatLogHeal", self)
			end
		end
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Gloomclaw" then
			self:Start()
			waveCount, ruptCount, prev = 0, 0, 0
			section = 1
			first = true
			for unitId, v in pairs(essenceUp) do
				core:RemoveUnit(unitId)
				essenceUp[unitId] = nil
			end
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:AddBar("RUPTURE", "~RUPTURE", 35, GetSoundSetting(true, "SoundRuptureCountdown"))
			core:AddBar("CORRUPTION", "FULL CORRUPTION", 106, GetSoundSetting(true, "SoundCorruptionCountdown"))
			core:StartScan()
		elseif sName == "Strain Parasite" or sName == "Gloomclaw Skurge" or sName == "Corrupted Fraz" then
			local timeOfEvent = GameLib.GetGameTime()
			if timeOfEvent - prev > 10 then
				prev = timeOfEvent
				waveCount = waveCount + 1
				core:AddMsg("WAVE", ("[%s] WAVE"):format(waveCount), 5, GetSoundSetting("Info", "SoundWaveWarning"), "Blue")
				if section < 5 then
					if waveCount < spawnCount[section] then
						core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), spawnTimer[section])
					end
				else
					if waveCount == 1 then
						core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 20.5)
					elseif waveCount == 2 then
						core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 30)
					elseif waveCount == 3 then
						core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 15)
					end
				end
			end
		end
	end
end
