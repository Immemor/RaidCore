--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("SystemDeamons", 52)
if not mod then return end

mod:RegisterRestrictZone("SystemDeamons", "Halls of the Infinite Mind", "Infinite Generator Core")
mod:RegisterEnableMob("Binary System Daemon","Null System Daemon")

--------------------------------------------------------------------------------
-- Locals
--

local discoCount, sdwaveCount, probeCount, sdSurgeCount, PurgeLast = 0, 0, 0, {}, {}
local phase2warn, phase2 = false, false
local intNorth, intSouth = nil, nil
local prev = 0
local nbKick = 2

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("SPELL_CAST_END", 		"OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", 			"OnHealthChanged", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
	Apollo.RegisterEventHandler("RAID_SYNC", 			"OnSyncRcv", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 		"OnZoneChanged", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Brute Force Algorithm" or sName == "Encryption Program" or sName == "Radiation Dispersion Unit" or sName == "Defragmentation Unit" then
		if phase2 then return end
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 48 then
			prev = timeOfEvent
			sdwaveCount = sdwaveCount + 1
			probeCount = 0
			if sdwaveCount == 1 then
				core:AddMsg("SDWAVE", ("[%s] WAVE"):format(sdwaveCount), 5, "Info", "Blue")
				core:AddBar("SDWAVE", ("[%s] WAVE"):format(sdwaveCount + 1), 50, 1)
			elseif sdwaveCount % 2 == 0 then
				core:AddMsg("SDWAVE", ("[%s] WAVE"):format(sdwaveCount), 5, "Info", "Blue")
				core:AddBar("SDWAVE", ("[%s] MINIBOSS"):format(sdwaveCount + 1), 50, 1)
			else
				core:AddMsg("SDWAVE", ("[%s] MINIBOSS"):format(sdwaveCount), 5, "Info", "Blue")
				core:AddBar("SDWAVE", ("[%s] WAVE"):format(sdwaveCount + 1), 50, 1)
			end
		end
	elseif sName == "Null System Daemon" or sName == "Binary System Daemon" then
		--core:MarkUnit(unit, 0, ("N%s"):format(sdSurgeCount[unit:GetId()] or 0))
		core:MarkUnit(unit, 0, ("%s%s"):format(sName:find("Null") and "S" or "N", sdSurgeCount[unit:GetId()] or 0))
		core:AddUnit(unit)
		core:WatchUnit(unit)
	--elseif sName == "Null System Daemon"  then
	--	core:MarkUnit(unit, 0, ("S%s"):format(sdSurgeCount[unit:GetId()] or 0))
	--	core:AddUnit(unit)
	--	core:WatchUnit(unit)
	elseif sName == "Conduction Unit Mk. I" then
		if probeCount == 0 then probeCount = 1 end
		if GetCurrentSubZoneName():find("Infinite Generator Core") then core:MarkUnit(unit, 1, 1) end
	elseif sName == "Conduction Unit Mk. II" then
		if probeCount == 1 then probeCount = 2 end
		if GetCurrentSubZoneName():find("Infinite Generator Core") then core:MarkUnit(unit, 1, 2) end
	elseif sName == "Conduction Unit Mark III" then
		if probeCount == 2 then probeCount = 3 end
		if GetCurrentSubZoneName():find("Infinite Generator Core") then core:MarkUnit(unit, 1, 3) end
	elseif sName == "Enhancement Module" then
		--Print("Adding Lines for " .. unit:GetId())
		core:MarkUnit(unit, 0)
		core:AddUnit(unit)
		core:AddLine(unit:GetId().."_1", 2, unit, nil, 1, 25, 90)
		core:AddLine(unit:GetId().."_2", 2, unit, nil, 2, 25, -90)
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	if sName == "Enhancement Module" then
		--Print("Dropping Lines for " .. unit:GetId())
		core:DropLine(unit:GetId().."_1")
		core:DropLine(unit:GetId().."_2")
	end	
end

function mod:OnHealthChanged(unitName, health)
	if health >= 70 and health <= 72 and not phase2warn and not phase2 then
		phase2warn = true
		core:AddMsg("SDP2", "P2 SOON !", 5, "Info")
	elseif health >= 70 and health <= 32 and not phase2warn and not phase2 then
		phase2warn = true
		core:AddMsg("SDP2", "P2 SOON !", 5, "Info")		
	end
end

local function dist2unit(unitSource, unitTarget)
	if not unitSource or not unitTarget then return 999 end
	local sPos = unitSource:GetPosition()
	local tPos = unitTarget:GetPosition()

	local sVec = Vector3.New(sPos.x, sPos.y, sPos.z)
	local tVec = Vector3.New(tPos.x, tPos.y, tPos.z)

	local dist = (tVec - sVec):Length()

	return tonumber(dist)
end


function mod:OnSpellCastEnd(unitName, castName, unit)
	if unitName == "Binary System Daemon" and castName == "Power Surge" then
		core:MarkUnit(unit, 0, ("N%s"):format(sdSurgeCount[unit:GetId()]))
	elseif unitName == "Null System Daemon" and castName == "Power Surge" then	
		core:MarkUnit(unit, 0, ("S%s"):format(sdSurgeCount[unit:GetId()]))	
	end
end


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Binary System Daemon" and castName == "Power Surge" then
		core:SendSync("NORTH_SURGE", unit:GetId())
		if phase2 and dist2unit(GameLib.GetPlayerUnit(), unit) < 40 then
			core:AddMsg("PURGE", "INTERRUPT NORTH", 5, "Alert")
		end		
	elseif unitName == "Null System Daemon" and castName == "Power Surge" then
		core:SendSync("SOUTH_SURGE", unit:GetId())
		if phase2 and dist2unit(GameLib.GetPlayerUnit(), unit) < 40 then
			core:AddMsg("PURGE", "INTERRUPT SOUTH", 5, "Alert")
		end			
	elseif castName == "Purge" then
		PurgeLast[unit:GetId()] = GameLib.GetGameTime()
		if dist2unit(GameLib.GetPlayerUnit(), unit) < 40 then
			core:AddMsg("PURGE", "AIDDDDDDDS !", 5, "Beware")
			core:AddBar("PURGE_"..unit:GetId(), ("PURGE - %s"):format(unitName:find("Null") and "NULL" or "BINARY"), 27)
		elseif phase2 then
			core:AddBar("PURGE_"..unit:GetId(), ("PURGE - %s"):format(unitName:find("Null") and "NULL" or "BINARY"), 27)
		end
	elseif unitName == "Defragmentation Unit" and castName == "Black IC" then
		core:AddMsg("BLACKIC", "INTERRUPT !", 5, "Alert")
		core:AddBar("BLACKIC", "BLACK IC", 30)
	end
end


function mod:OnZoneChanged(zoneId, zoneName)
	if zoneName == "Datascape" then
		return
	elseif zoneName == "Halls of the Infinite Mind" then
		local timeOfEvent = GameLib.GetGameTime()
		for id, timer in pairs(PurgeLast) do
			local unit = GameLib.GetUnitById(id)
			if unit and (dist2unit(GameLib.GetPlayerUnit(), unit) < 40 or phase2) then
				if timeOfEvent - timer < 27 then
					core:AddBar("PURGE_".. id, ("PURGE - %s"):format(unit:GetName():find("Null") and "NULL" or "BINARY"), timer + 27 - timeOfEvent)
				end
			end
		end
	elseif zoneName:find("Infinite Generator Core") then
		for id, timer in pairs(PurgeLast) do
			core:StopBar("PURGE_" .. id)
		end		
	end
end


function mod:NextWave()
	Print("ProbeCount : ".. probeCount)
	if probeCount == 3 then
		if sdwaveCount % 2 == 0 then
			core:AddBar("SDWAVE", ("[%s] MINIBOSS"):format(sdwaveCount + 1), 90, 1)
		else
			core:AddBar("SDWAVE", ("[%s] WAVE"):format(sdwaveCount + 1), 90, 1)
		end
	else
		core:AddBar("SDP1", ("[%s] PROBE %s"):format(sdwaveCount, probeCount + 1), 90, 1)
		if sdwaveCount % 2 == 0 then
			core:AddBar("SDWAVE", ("[%s] MINIBOSS"):format(sdwaveCount + 1), 110 + (2 - probeCount) * 10, 1)
		else
			core:AddBar("SDWAVE", ("[%s] WAVE"):format(sdwaveCount + 1), 110 + (2 - probeCount) * 10, 1)
		end
	end
end

function mod:OnChatDC(message)
	if message:find("INVALID SIGNAL. DISCONNECTING") then
		if phase2 then phase2 = false end
		discoCount = discoCount + 1
		if self:Tank() then
			core:AddBar("DISC", ("DISCONNECT (%s)"):format(discoCount + 1), 60)
		end
	elseif message:find("COMMENCING ENHANCEMENT SEQUENCE") then
		phase2, phase2warn = true, false
		core:StopBar("DISC")
		core:StopBar("SDWAVE")
		core:AddMsg("SDP2", "PHASE 2 !", 5, "Alarm")
		if self:Tank() then
			core:AddBar("DISC", ("DISCONNECT (%s)"):format(discoCount + 1), 85)
		end

		self:ScheduleTimer("NextWave", 5)
	end
end

function mod:OnSyncRcv(sync, parameter)
	if sync == "NORTH_SURGE" then
		if intNorth and intNorth == sdSurgeCount[parameter] and not phase2 then
			core:AddMsg("SURGE", "INTERRUPT NORTH", 5, "Alert")
		end

		sdSurgeCount[parameter] = sdSurgeCount[parameter] + 1
		if sdSurgeCount[parameter] > nbKick then sdSurgeCount[parameter] = 1 end
		--Print("NORTH : "..sdSurgeCount[parameter])
		--local unit = GameLib.GetUnitById(parameter)
		--if unit then core:MarkUnit(unit, 0, sdSurgeCount[parameter]) end

		if intNorth and intNorth == sdSurgeCount[parameter] then
			core:AddMsg("SURGE", "YOU ARE NEXT ON NORTH !", 5, "Long", "Blue")
		end
	elseif sync == "SOUTH_SURGE" then
		if intSouth and intSouth == sdSurgeCount[parameter] and not phase2 then
			core:AddMsg("SURGE", "INTERRUPT SOUTH", 5, "Alert")
		end

		sdSurgeCount[parameter] = sdSurgeCount[parameter] + 1
		if sdSurgeCount[parameter] > nbKick then sdSurgeCount[parameter] = 1 end
		--Print("SOUTH : "..sdSurgeCount[parameter])
		--local unit = GameLib.GetUnitById(parameter)
		--if unit then core:MarkUnit(unit, 0, sdSurgeCount[parameter]) end

		if intSouth and intSouth == sdSurgeCount[parameter] then
			core:AddMsg("SURGE", "YOU ARE NEXT ON SOUTH !", 5, "Long", "Blue")
		end
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Null System Daemon"  or  sName == "Binary System Daemon" then
			self:Start()
			discoCount, sdwaveCount, probeCount = 0, 0, 0
			phase2warn, phase2 = false, false
			sdSurgeCount[unit:GetId()] = 1
			PurgeLast[unit:GetId()] = 0
			core:MarkUnit(unit, 0, ("%s%s"):format(sName:find("Null") and "S" or "N", sdSurgeCount[unit:GetId()]))
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:AddSync("NORTH_SURGE", 5)
			core:AddSync("SOUTH_SURGE", 5)
			if self:Tank() then
				core:AddBar("DISC", ("DISCONNECT (%s)"):format(discoCount + 1), 41)
			end
			core:AddBar("SDWAVE", ("[%s] WAVE"):format(sdwaveCount + 1), 15, 1)
			core:StartScan()
		elseif sName == "Defragmentation Unit" then
			if GetCurrentSubZoneName():find("Infinite Generator Core") then
				core:WatchUnit(unit)
			end
		end
	end
end

function mod:SetInterrupter(position, num)
	if num > nbKick then 
		Print("MORON ! Set a good number")
		return
	end
	if position:lower() == "north" then
		intNorth = num
		Print(("Position %s set for North Boss"):format(num))
	elseif position:lower() == "south" then
		intSouth = num
		Print(("Position %s set for South Boss"):format(num))
	else 
		Print(("Bad Position : %s"):format(position))
	end
end