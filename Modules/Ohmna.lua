--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Ohmna", 67)
if not mod then return end

mod:RegisterEnableMob("Dreadphage Ohmna", "Schreckensphage Ohmna")
mod:RegisterRestrictEventObjective("Ohmna", "Defeat Dreadphage Ohmna")
mod:RegisterEnableEventObjective("Ohmna", "Defeat Dreadphage Ohmna")

--------------------------------------------------------------------------------
-- Locals
--
 
local pilarCount, boreCount, submergeCount = 0, 0, 0
local firstPull, OhmnaP3, OhmnaP4 = true, false, false
 
local function getMax(t)
    --if #t == 0 then return nil end
    local max_val, key = -1000, ""
    for k, v in pairs(t) do
    	--Print(k.. " " .. v)
        if max_val < v then
            max_val, key = v, k
        elseif max_val == v then
        	key = key .. " / " .. k
        end
    end
    return max_val, key
end
 
local function getMin(t)
    --if #t == 0 then return nil end
    local min_val, key = 1000, ""
    for k, v in pairs(t) do
-- Ignore pillars that are on 0%
	if min_val > v and v > 0 then
		min_val, key = v, k
	elseif min_val == v then
		key = key .. " / " .. k
		end
	end
return min_val, key
end
 
local locale = core:GetLocale()
local msgStrings = {
	["enUS"] = {
		module = "Module %s loaded",
		unitName = "Dreadphage Ohmna",
		unitNameTentacle = "Tentacle of Ohmna",
		unitNameMaw = "Ravenous Maw of the Dreadphage",
		tentacleWarn = "Tentacles",
		tentacleBar = "Next Tentacles",
		p2SoonWarn = "P2 SOON !",
		p3SoonWarn = "P3 SOON !",
		p3Warn = "P3 REALLY SOON !",
		eruptCast = "Erupt",
		pilierBar = "PILIER %s : %s",
		pilarBar = "PILAR %s",
		tankSwitchBar = "SWITCH TANK",
		torrentCast = "Genetic Torrent",
		spewWarn = "BIG SPEW",
		spewBar = "NEXT BIG SPEW",
		nCoreDesc = "North Power Core Energy",
		nStatus = "NORTH",
		sCoreDesc = "South Power Core Energy",
		sStatus = "SOUTH",
		eCoreDesc = "East Power Core Energy",
		eStatus = "EAST",
		wCoreDesc = "West Power Core Energy",
		wStatus = "WEST",
		plasmaMsg = "A plasma leech begins draining",
		p2Bar = "PHASE 2",
		submergeMsg = "Dreadphage Ohmna submerges",
		boredMsg = "Dreadphage Ohmna is bored",
		aTentaclesMsg = "The Archives tremble as Dreadphage Ohmna",
		aTentaclesWarn = "P2 : TENTACLES",
		ravenousMsg = "The Archives quake with the furious might",
		ravenousWarn = "P3 : RAVENOUS",
	},
	["deDE"] = {
		module = "Modul %s geladen",
		unitName = "Schreckensphage Ohmna",
		unitNameTentacle = "Tentakel von Ohmna",
		unitNameMaw = "Unersättliches Maul der Schreckensphage",
		tentacleWarn = "TENTAKEL",
		tentacleBar = "NÄCHSTE TENTAKEL",
		p2SoonWarn = "GLEICH PHASE 2 !",
		p3SoonWarn = "GLEICH PHASE 3 !",
		p3Warn = "17 % | VORSICHT MIT DAMAGE",
		eruptCast = "Ausbrechen",
		pilierBar = "GENERATOR %s : %s",
		pilarBar = "GENERATOR %s",
		tankSwitchBar = "AGGRO ZIEHEN !!!",
		torrentCast = "Genetische Strömung",
		spewWarn = "GROßES BRECHEN",
		spewBar = "NÄCHSTES GROßES BRECHEN",
		nCoreDesc = "Nördliche Kraftkernenergie",
		nStatus = "N",
		sCoreDesc = "Südliche Kraftkernenergie",
		sStatus = "S",
		eCoreDesc = "Östliche Kraftkernenergie",
		eStatus = "E",
		wCoreDesc = "Westliche Kraftkernenergie",
		wStatus = "W",
		plasmaMsg = "Ein Plasmaegel beginnt, den",
		p2Bar = "PHASE 2",
		submergeMsg = "Die Schreckensphage Ohmna taucht in den",
		boredMsg = "Die Schreckensphage Ohmna langweilt sich",
		aTentaclesMsg = "Die Archive beben, als die Tentakeln der Schreckensphage Ohmna um dich herum auftauchen",
		aTentaclesWarn = "P2 : TENTAKEL",
		ravenousMsg = "Die Archive beben unter der wütenden Macht der Schreckensphage",
		ravenousWarn = "P3 : GROßE WÜRMER",
	},
}
 
--------------------------------------------------------------------------------
-- Initialization
--
 
function mod:OnBossEnable()
	Print((msgStrings[locale]["module"]):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", 	self)
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", 			self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", 			"OnHealthChanged", 		self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 				self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", 		self)
end
 
 
--------------------------------------------------------------------------------
-- Event Handlers
--
 
 
function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == msgStrings[locale]["unitNameTentacle"] then
		if not OhmnaP4 then
			core:AddMsg("OTENT", msgStrings[locale]["tentacleWarn"], 5, "Info", "Blue")
			core:AddBar("OTENT", msgStrings[locale]["tentacleBar"], 20)
		end
	elseif sName == msgStrings[locale]["unitNameMaw"] then
		core:MarkUnit(unit, 0)
		core:AddLine(unit:GetId(), 2, unit, nil, 3, 25, 0)
	elseif sName == msgStrings[locale]["unitName"] then
		core:AddUnit(unit)
	end
end
 
function mod:OnHealthChanged(unitName, health)
	if unitName == msgStrings[locale]["unitName"] and health == 52 then
		core:AddMsg("OP2", msgStrings[locale]["p2SoonWarn"], 5, "Alert")
	elseif unitName == msgStrings[locale]["unitName"] and health == 20 then
		core:AddMsg("OP3", msgStrings[locale]["p3SoonWarn"], 5, "Alert")
	elseif unitName == msgStrings[locale]["unitName"] and health == 17 then
		core:AddMsg("OP3", msgStrings[locale]["p3Warn"], 5, "Alert")
	end
end
 
 
function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == msgStrings[locale]["unitName"] and castName == msgStrings[locale]["eruptCast"] then
		if OhmnaP3 then return end
		local pilarActivated = self:OhmnaPE(pilarCount % 2)
		core:AddBar("OPILAR", (msgStrings[locale]["pilierBar"]):format(pilarCount, pilarActivated), 32, 1)
		if self:Tank() then
			core:AddBar("OBORE", msgStrings[locale]["tankSwitchBar"], 45)
		end
		core:StopScan()
	elseif unitName == msgStrings[locale]["unitName"] and castName == msgStrings[locale]["torrentCast"] then
		core:AddMsg("SPEW", msgStrings[locale]["spewWarn"], 5, "RunAway")
		core:AddBar("OSPEW", msgStrings[locale]["spewBar"], OhmnaP4 and 40 or 60, 1)
	end
end
 
function mod:OhmnaPE(lowest)
	local tStatus = {}
	local strResult = ""
	local max_val
	local tActiveEvents = PublicEvent.GetActiveEvents()
	for idx, peEvent in pairs(tActiveEvents) do
		for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
			if peObjective:GetShortDescription() == msgStrings[locale]["nCoreDesc"] then
				tStatus[msgStrings[locale]["nStatus"]] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == msgStrings[locale]["sCoreDesc"] then
				tStatus[msgStrings[locale]["sStatus"]] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == msgStrings[locale]["eCoreDesc"] then
				tStatus[msgStrings[locale]["eStatus"]] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == msgStrings[locale]["wCoreDesc"] then
				tStatus[msgStrings[locale]["wStatus"]] = peObjective:GetCount()				
			end
		end
	end
 
	if lowest == 1 then
		max_val, strResult = getMin(tStatus)
	else
		max_val, strResult = getMax(tStatus)
	end
 
	return strResult
end
 
function mod:OnChatDC(message)
		if message:find(msgStrings[locale]["plasmaMsg"]) then
			if OhmnaP3 then return end
			pilarCount = pilarCount + 1
			if submergeCount < 2 and pilarCount > 4 then
				core:AddBar("OPILAR", msgStrings[locale]["p2Bar"], firstPull and 27 or 22)
				firstPull = false
			else
				local pilarActivated = self:OhmnaPE(pilarCount % 2)
				core:AddBar("OPILAR", (msgStrings[locale]["pilierBar"]):format(pilarCount, pilarActivated), 25, 1)
			end
		elseif message:find(msgStrings[locale]["submergeMsg"]) then
			pilarCount, boreCount = 1, 0
			submergeCount = submergeCount + 1
			core:StopBar("OTENT")
			core:StartScan()
		elseif message:find(msgStrings[locale]["boredMsg"]) then
			boreCount = boreCount + 1
			if boreCount < 2 and self:Tank() then
				core:AddBar("OBORE", msgStrings[locale]["tankSwitchBar"], 42)
			end
		elseif message:find(msgStrings[locale]["aTentaclesMsg"]) then
			core:AddMsg("OP2", msgStrings[locale]["aTentaclesWarn"], 5, "Alert")
		elseif message:find(msgStrings[locale]["ravenousMsg"]) then
			core:AddMsg("OP3", msgStrings[locale]["ravenousWarn"], 5, "Alert")
			OhmnaP3 = true
			core:StopBar("OPILAR")
			core:StopBar("OBORE")
			core:AddBar("OSPEW", msgStrings[locale]["spewBar"], 45, 1)
			core:StartScan()
		end
end
 
 
 
function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == msgStrings[locale]["unitName"] then
			self:Start()
			pilarCount, boreCount, submergeCount = 1, 0, 0
			firstPull, OhmnaP3, OhmnaP4 = true, false, false
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:AddBar("OPILAR", (msgStrings[locale]["pilarBar"]):format(pilarCount), 25, 1)
			core:AddLine("Ohmna1", 2, unit, nil, 3, 25, 0)
			core:AddLine("Ohmna2", 2, unit, nil, 1, 25, 120)
			core:AddLine("Ohmna3", 2, unit, nil, 1, 25, -120)
			if self:Tank() then
				core:AddBar("OBORE", msgStrings[locale]["tankSwitchBar"], 45)
			end	
		end
	end
end
