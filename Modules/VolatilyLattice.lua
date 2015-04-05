--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("VolatilityLattice", 52)
if not mod then return end

mod:RegisterEnableMob("Big Red Button")

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local waveCount, beamCount = 0, 0
local playerName
local phase2 = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStateChanged", self)
	--Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
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

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Data Devourer" and dist2unit(unit, GameLib.GetPlayerUnit()) < 45 then
		core:AddPixie(unit:GetId(), 1, GameLib.GetPlayerUnit(), unit, "Blue", 5, 10, 10)
	end
end

function mod:RemoveLaserMark(unit)
	core:DropMark(unit:GetId())
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	if sName == "Big Red Button" then
		self:Start()
		playerName = GameLib.GetPlayerUnit():GetName()
		prev = 0
		waveCount, beamCount = 0, 0
		phase2 = false
		core:AddBar("BEAM", "NEXT BEAM", 24)
		core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 24, 1)
		core:Berserk(600)
	elseif sName == "Data Devourer" then
		core:DropPixie(unit:GetId())
	end
end

function mod:OnChatDC(message)
	if message:find("Avatus sets his focus on") then
		beamCount = beamCount + 1
		local pName = string.gsub(string.sub(message, 26), "!", "")
		local pUnit = GameLib.GetPlayerUnitByName(pName)
		if pUnit then
			core:MarkUnit(pUnit, nil, "LASER")
			self:ScheduleTimer("RemoveLaserMark", 15, pUnit)
		end
		if pName == playerName then
			core:AddMsg("BEAM", "BEAM on YOU !!!", 5, "RunAway")
		else
			core:AddMsg("BEAM", ("[%s] BEAM on %s"):format(beamCount, pName), 5, "Info", "Blue")
		end
		if phase2 then
			core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 15, 1)
			phase2 = false
		else
			core:AddBar("BEAM", ("[%s] BEAM %s"):format(beamCount, pName), 15)
			if beamCount == 3 then
				core:AddBar("WAVE", ("[%s] WAVE"):format(waveCount + 1), 15, 1)
			end
		end
	elseif message:find("Avatus prepares to delete all data") then
		core:StopBar("BEAM")
		core:StopBar("WAVE")
		core:AddMsg("BIGC", "BIG CAST !!", 5, "Beware")
		core:AddBar("BIGC", "BIG CAST", 10)
		beamCount = 0
	elseif message:find("The Secure Sector Enhancement Ports have been activated") then
		core:StopBar("BEAM")
		core:StopBar("WAVE")
		phase2 = true
		waveCount, beamCount = 0, 0
		core:AddMsg("P2", "P2 : SHIELD PHASE", 5, "Alert")
		core:AddBar("P2", "LASER", 15, 1)
		core:AddBar("BEAM", "NEXT BEAM", 44)
	elseif message:find("The Vertical Locomotion Enhancement Ports have been activated") then
		core:StopBar("BEAM")
		core:StopBar("WAVE")
		phase2 = true
		waveCount, beamCount = 0, 0
		core:AddMsg("P2", "P2 : JUMP PHASE", 5, "Alert")
		core:AddBar("P2", "EXPLOSION", 15, 1)
		core:AddBar("BEAM", "NEXT BEAM", 58)
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Obstinate Logic Wall" then
			local timeOfEvent = GameLib.GetGameTime()
			core:MarkUnit(unit)
			core:AddUnit(unit)
			if timeOfEvent - prev > 20 and not phase2 then
				prev = timeOfEvent
				waveCount = waveCount + 1
				core:AddMsg("WAVE", ("[%s] WAVE"):format(waveCount), 5, "Alert")
			end
		end
	end
end
