--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Kuralak", 67)
if not mod then return end

mod:RegisterEnableMob("Kuralak the Defiler", "Kuralak die Schänderin")
mod:RegisterRestrictZone("Kurulak", "Archive Access Core")
mod:RegisterEnableZone("Kurulak", "Archive Access Core")

--------------------------------------------------------------------------------
-- Locals
--

local eggsCount, siphonCount, outbreakCount = 0, 0, 0
local locale = core:GetLocale()
local msgStrings = {
	["enUS"] = {
		unitName = "Kuralak the Defiler",
		p2warn = "P2 SOON !",
		vanishMsg = "Kuralak the Defiler returns to the Archive Core",
		vanishWarn = "VANISH",
		vanishBar = "Vanish",
		outbreakMsg = "Kuralak the Defiler causes a violent outbreak of corruption",
		outbreakWarn = "OUTBREAK",
		outbreakBar = "Outbreak",
		eggMsg = "The corruption begins to fester",
		eggWarn = "EGGS",
		eggBar = "Eggs",
		berserkMsg = "BERSERK !!",
		siphonMsg = "has been anesthetized",
		tankSwitchWarn = "SWITCH TANK",
		tankSwitchBar = "Switch Tank",
		phase2Msg1 = "Through the Strain you will be transformed",
		phase2Msg2 = "Your form is flawed, but I will make you beautiful",
		phase2Msg3 = "Let the Strain perfect you",
		phase2Msg4 = "The Experiment has failed",
		phase2Msg5 = "Join us... become one with the Strain",
		phase2Msg6 = "One of us... you will become one of us",
		phase2Msg7 = "One of us... you will become one of us", -- duplicates because lazy, german has more
		phase2Msg8 = "One of us... you will become one of us",
		phase2Msg9 = "One of us... you will become one of us",
	},
	["deDE"] = {
		unitName = "Kuralak die Schänderin",
		p2warn = "GLEICH PHASE 2 !",
		vanishMsg = "Kuralak die Schänderin kehrt zum Archivkern zurück",
		vanishWarn = "VERSCHWINDEN",
		vanishBar = "Verschwinden",
		outbreakMsg = "Kuralak die Schänderin verursacht einen heftigen Ausbruch der Korrumpierung",
		outbreakWarn = "AUSBRUCH",
		outbreakBar = "Ausbruch",
		eggMsg = "Die Korrumpierung beginnt zu eitern",
		eggWarn = "EIER",
		eggBar = "Eier",
		berserkMsg = "DAS WARS !!",
		siphonMsg = "wurde narkotisiert",
		tankSwitchWarn = "TANKWECHSEL",
		tankSwitchBar = "Wechsel Tank",
		phase2Msg1 = "Durch die Transformation wirst du",
		phase2Msg2 = "aber ich werde dich schön machen",
		phase2Msg3 = "Dies ist mein Reich! Daraus gibt es kein Entrinnen ...",
		phase2Msg4 = "Lass dich von der Transmutation perfektionieren",
		phase2Msg5 = "Die Transmutation ... Lass dich von ihr verschlingen ...",
		phase2Msg6 = "Komm zu uns... werde eins mit der Transmutation",
		phase2Msg7 = "Das Experiment ist fehlgeschlagen",
		phase2Msg8 = "Schließ dich uns an ... Werde eins mit der Transmutation",
		phase2Msg9 = "Einer von uns ...",
	},
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", 	self)
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
	if sName == msgStrings[locale]["unitName"] then
		core:AddUnit(unit)
	end
end

function mod:OnHealthChanged(unitName, health)
	if health == 74 and unitName == msgStrings[locale]["unitName"] then
		core:AddMsg("P2", msgStrings[locale]["p2warn"], 5, "Info")
	end
end


function mod:OnChatDC(message)
	if message:find(msgStrings[locale]["vanishMsg"]) then
		core:AddMsg("VANISH", msgStrings[locale]["vanishWarn"], 5, "Alert")
		core:AddBar("VANISH", msgStrings[locale]["vanishBar"], 47, 1)
	elseif message:find(msgStrings[locale]["outbreakMsg"]) then
		core:AddMsg("OUTBREAK", msgStrings[locale]["outbreakWarn"], 5, "RunAway")
		outbreakCount = outbreakCount + 1
		if outbreakCount <= 5 then
			core:AddBar("OUTBREAK", ("%s (%s)"):format(msgStrings[locale]["outbreakBar"], outbreakCount + 1), 45)
		end
		if outbreakCount == 4 then
			core:StopScan()
		end
	elseif message:find(msgStrings[locale]["eggMsg"]) then
		if eggsCount < 2 then eggsCount = 2 end
		core:AddMsg("EGGS", ("%s (%s)"):format(msgStrings[locale]["eggWarn"], math.pow(2, eggsCount-1)), 5, "Alert")
		eggsCount = eggsCount + 1
		if eggsCount == 5 then
			core:AddBar("EGGS", msgStrings[locale]["berserkMsg"], 66)
			eggsCount = 2
		else
			core:AddBar("EGGS", ("%s (%s)"):format(msgStrings[locale]["eggBar"], math.pow(2, eggsCount-1)), 66)
		end
	elseif message:find(msgStrings[locale]["siphonMsg"]) then
		if siphonCount == 0 then siphonCount = 1 end
		siphonCount = siphonCount + 1
		if self:Tank() then
			core:AddMsg("SIPHON", msgStrings[locale]["tankSwitchWarn"], 5, "Alarm")
			if siphonCount < 4 then
				core:AddBar("SIPHON", ("%s (%s)"):format(msgStrings[locale]["tankSwitchBar"], siphonCount), 88)
			end
		end
	end
end

function mod:OnChatNPCSay(message)
		if message:find(msgStrings[locale]["phase2Msg1"])
		or message:find(msgStrings[locale]["phase2Msg2"])
		or message:find(msgStrings[locale]["phase2Msg3"])
		or message:find(msgStrings[locale]["phase2Msg4"])
		or message:find(msgStrings[locale]["phase2Msg5"])
		or message:find(msgStrings[locale]["phase2Msg6"])
		or message:find(msgStrings[locale]["phase2Msg7"])
		or message:find(msgStrings[locale]["phase2Msg8"])
		or message:find(msgStrings[locale]["phase2Msg9"]) then
			eggsCount, siphonCount, outbreakCount = 2, 1, 0
			core:StopBar("VANISH")
			core:AddMsg("KP2", "PHASE 2 !", 5, "Alert")
			core:AddBar("OUTBREAK", ("%s (%s)"):format(msgStrings[locale]["outbreakBar"], outbreakCount + 1), 15)
			core:AddBar("EGGS", ("%s (%s)"):format(msgStrings[locale]["eggBar"], eggsCount), 73)
			if self:Tank() then
				core:AddBar("SIPHON", ("%s (%s)"):format(msgStrings[locale]["tankSwitchBar"], siphonCount), 37)
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
		locale = core:GetLocale()
		if sName == msgStrings[locale]["unitName"] then
			self:Start()
			core:AddUnit(unit)
			eggsCount, siphonCount, outbreakCount = 2, 1, 0		
		end
	end
end
