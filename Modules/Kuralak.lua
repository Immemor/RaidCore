--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Kuralak", 67)
if not mod then return end

mod:RegisterEnableMob("Kuralak the Defiler")
mod:RegisterRestrictZone("Kuralak", "Archive Access Core")
mod:RegisterEnableZone("Kuralak", "Archive Access Core")

--------------------------------------------------------------------------------
-- Locals
--

local eggsCount, siphonCount, outbreakCount = 0, 0, 0


--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", 	self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", 			"OnHealthChanged", 		self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 				self)
	Apollo.RegisterEventHandler("CHAT_NPCSAY", 			"OnChatNPCSay", 			self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", 			self)
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Kuralak the Defiler" then
		core:AddUnit(unit)
	end
end

function mod:OnHealthChanged(unitName, health)
	if health == 74 and unitName == "Kuralak the Defiler" then
		core:AddMsg("P2", "P2 SOON !", 5, "Info")
	end
end


function mod:OnChatDC(message)
	if message:find("Kuralak the Defiler returns to the Archive Core") then
		core:AddMsg("VANISH", "VANISH", 5, "Alert")
		core:AddBar("VANISH", "Vanish", 47, 1)
	elseif message:find("Kuralak the Defiler causes a violent outbreak of corruption") then
		core:AddMsg("OUTBREAK", "OUTBREAK", 5, "RunAway")
		outbreakCount = outbreakCount + 1
		if outbreakCount <= 5 then
			core:AddBar("OUTBREAK", ("Outbreak (%s)"):format(outbreakCount + 1), 45)
		end
		if outbreakCount == 4 then
			core:StopScan()
		end
	elseif message:find("The corruption begins to fester") then
		if eggsCount < 2 then eggsCount = 2 end
		core:AddMsg("EGGS", ("EGGS (%s)"):format(math.pow(2, eggsCount-1)), 5, "Alert")
		eggsCount = eggsCount + 1
		if eggsCount == 5 then
			core:AddBar("EGGS", "BERSERK !!", 66)
			eggsCount = 2
		else
			core:AddBar("EGGS", ("Eggs (%s)"):format(math.pow(2, eggsCount-1)), 66)
		end
	elseif message:find("has been anesthetized") then
		if siphonCount == 0 then siphonCount = 1 end
		siphonCount = siphonCount + 1
		if self:Tank() then
			core:AddMsg("SIPHON", "SWITCH TANK", 5, "Alarm")
			if siphonCount < 4 then
				core:AddBar("SIPHON", ("Switch Tank (%s)"):format(siphonCount), 88)
			end
		end
	end
end

function mod:OnChatNPCSay(message)
		if message:find("Through the Strain you will be transformed") 
		or message:find("Your form is flawed, but I will make you beautiful")
		or message:find("Let the Strain perfect you")  
		or message:find("The Experiment has failed")  
		or message:find("Join us... become one with the Strain") 
		or message:find("One of us... you will become one of us") then
			eggsCount, siphonCount, outbreakCount = 2, 1, 0
			core:StopBar("VANISH")
			core:AddMsg("KP2", "PHASE 2 !", 5, "Alert")
			core:AddBar("OUTBREAK", ("Outbreak (%s)"):format(outbreakCount + 1), 15)
			core:AddBar("EGGS", ("Eggs (%s)"):format(eggsCount), 73)
			if self:Tank() then
				core:AddBar("SIPHON", ("Switch Tank (%s)"):format(siphonCount), 37)
			end
			local estpos = { x = 194.44, y = -110.80034637451, z = -483.20 }
			core:SetWorldMarker(estpos, "E")		
			local sudpos = { x = 165.79222106934, y = -110.80034637451, z = -464.8489074707 }
			core:SetWorldMarker(sudpos, "S")
			local ouestpos = { x = 144.20, y = -110.80034637451, z = -494.38 }
			core:SetWorldMarker(ouestpos, "W")
			local nordpos = { x = 175.00, y = -110.80034637451, z = -513.31 }
			core:SetWorldMarker(nordpos, "N")
			core:RaidDebuff()
			core:StartScan()
		end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	if splId == 56652 then
		core:MarkUnit(unit)
		core:AddUnit(unit)
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Kuralak the Defiler" then
			self:Start()
			core:AddUnit(unit)
			eggsCount, siphonCount, outbreakCount = 2, 1, 0		
		end
	end
end
