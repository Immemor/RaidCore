--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Ohmna", 67)
if not mod then return end

mod:RegisterEnableMob("Dreadphage Ohmna")
mod:RegisterRestrictEventObjective("Ohmna", "Defeat Dreadphage Ohmna")
mod:RegisterEnableEventObjective("Ohmna", "Defeat Dreadphage Ohmna")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Dreadphage Ohmna"] = "Dreadphage Ohmna",
	["Tentacle of Ohmna"] = "Tentacle of Ohmna",
	["Ravenous Maw of the Dreadphage"] = "Ravenous Maw of the Dreadphage",
	-- Datachron messages.
	["A plasma leech begins draining"] = "A plasma leech begins draining",
	["Dreadphage Ohmna submerges"] = "Dreadphage Ohmna submerges",
	["Dreadphage Ohmna is bored"] = "Dreadphage Ohmna is bored",
	["The Archives tremble as Dreadphage Ohmna"] = "The Archives tremble as Dreadphage Ohmna",
	["The Archives quake with the furious might"] = "The Archives quake with the furious might",
	-- Objectifs.
	["North Power Core Energy"] = "North Power Core Energy",
	["South Power Core Energy"] = "South Power Core Energy",
	["East Power Core Energy"] = "East Power Core Energy",
	["West Power Core Energy"] = "West Power Core Energy",
	-- Cast.
	["Erupt"] = "Erupt",
	["Genetic Torrent"] = "Genetic Torrent",
	-- Bar and messages.
	["Next Tentacles"] = "Next Tentacles",
	["Tentacles"] = "Tentacles",
	["P2 SOON !"] = "P2 SOON !",
	["P2: TENTACLES"] = "P2: TENTACLES",
	["PHASE 2"] = "PHASE 2",
	["P3 SOON !"] = "P3 SOON !",
	["P3: RAVENOUS"] = "P3: RAVENOUS",
	["P3 REALLY SOON !"] = "P3 REALLY SOON !",
	["PILLAR %u : %u"] = "PILLAR %u : %u",
	["PILLAR %u"] = "PILLAR %u",
	["SWITCH TANK"] = "SWITCH TANK",
	["BIG SPEW"] = "BIG SPEW",
	["NEXT BIG SPEW"] = "NEXT BIG SPEW",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	["Dreadphage Ohmna"] = "Ohmna la Terriphage",
	["Tentacle of Ohmna"] = "Tentacule d'Ohmna",
	["Ravenous Maw of the Dreadphage"] = "Gueule vorace de la Terriphage",
	-- Datachron messages.
--	["A plasma leech begins draining"] = "A plasma leech begins draining",	-- TODO: French translation missing !!!!
--	["Dreadphage Ohmna submerges"] = "Dreadphage Ohmna submerges",	-- TODO: French translation missing !!!!
--	["Dreadphage Ohmna is bored"] = "Dreadphage Ohmna is bored",	-- TODO: French translation missing !!!!
--	["The Archives tremble as Dreadphage Ohmna"] = "The Archives tremble as Dreadphage Ohmna",	-- TODO: French translation missing !!!!
--	["The Archives quake with the furious might"] = "The Archives quake with the furious might",	-- TODO: French translation missing !!!!
	-- Objectifs.
--	["North Power Core Energy"] = "North Power Core Energy",	-- TODO: French translation missing !!!!
--	["South Power Core Energy"] = "South Power Core Energy",	-- TODO: French translation missing !!!!
--	["East Power Core Energy"] = "East Power Core Energy",	-- TODO: French translation missing !!!!
--	["West Power Core Energy"] = "West Power Core Energy",	-- TODO: French translation missing !!!!
	-- Cast.
	["Erupt"] = "Erupt",
	["Genetic Torrent"] = "Torrent génétique",
	-- Bar and messages.
--	["Next Tentacles"] = "Next Tentacles",	-- TODO: French translation missing !!!!
	["Tentacles"] = "Tentacule",
	["P2 SOON !"] = "P2 SOON !",
--	["P2: TENTACLES"] = "P2: TENTACLES",	-- TODO: French translation missing !!!!
--	["PHASE 2"] = "PHASE 2",	-- TODO: French translation missing !!!!
--	["P3 SOON !"] = "P3 SOON !",	-- TODO: French translation missing !!!!
--	["P3: RAVENOUS"] = "P3: RAVENOUS",	-- TODO: French translation missing !!!!
--	["P3 REALLY SOON !"] = "P3 REALLY SOON !",	-- TODO: French translation missing !!!!
--	["PILLAR %u : %u"] = "PILLAR %u : %u",	-- TODO: French translation missing !!!!
--	["PILLAR %u"] = "PILLAR %u",	-- TODO: French translation missing !!!!
	["SWITCH TANK"] = "CHANGEMENT TANK",
--	["BIG SPEW"] = "BIG SPEW",	-- TODO: French translation missing !!!!
--	["NEXT BIG SPEW"] = "NEXT BIG SPEW",	-- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
	-- Unit names.
	["Dreadphage Ohmna"] = "Schreckensphage Ohmna",
	["Tentacle of Ohmna"] = "Tentakel von Ohmna",
	["Ravenous Maw of the Dreadphage"] = "Unersättliches Maul der Schreckensphage",
	-- Datachron messages.
	["A plasma leech begins draining"] = "Ein Plasmaegel beginnt, den",
	["Dreadphage Ohmna submerges"] = "Die Schreckensphage Ohmna taucht in den",
	["Dreadphage Ohmna is bored"] = "Die Schreckensphage Ohmna langweilt sich",
	["The Archives tremble as Dreadphage Ohmna"] = "Die Archive beben, als die Tentakeln der Schreckensphage Ohmna um dich herum auftauchen",
	["The Archives quake with the furious might"] = "Die Archive beben unter der wütenden Macht der Schreckensphage",
	-- Objectifs.
	["North Power Core Energy"] = "Nördliche Kraftkernenergie",
	["South Power Core Energy"] = "Südliche Kraftkernenergie",
	["East Power Core Energy"] = "Östliche Kraftkernenergie",
	["West Power Core Energy"] = "Westliche Kraftkernenergie",
	-- Cast.
	["Erupt"] = "Ausbrechen",
	["Genetic Torrent"] = "Genetische Strömung",
	-- Bar and messages.
	["Next Tentacles"] = "NÄCHSTE TENTAKEL",
	["Tentacles"] = "TENTAKEL",
	["P2 SOON !"] = "GLEICH PHASE 2 !",
--	["P2: TENTACLES"] = "P2: TENTACLES",	-- TODO: German translation missing !!!!
	["PHASE 2"] = "PHASE 2",
	["P3 SOON !"] = "GLEICH PHASE 3 !",
--	["P3: RAVENOUS"] = "P3: RAVENOUS",	-- TODO: German translation missing !!!!
	["P3 REALLY SOON !"] = "17 % | VORSICHT MIT DAMAGE",
--	["PILLAR %u : %u"] = "PILLAR %u : %u",	-- TODO: German translation missing !!!!
--	["PILLAR %u"] = "PILLAR %u",	-- TODO: German translation missing !!!!
	["SWITCH TANK"] = "AGGRO ZIEHEN !!!",
	["BIG SPEW"] = "GROßES BRECHEN",
	["NEXT BIG SPEW"] = "NÄCHSTES GROßES BRECHEN",
})


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

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit, sName)
	if sName == self.L["Tentacle of Ohmna"] then
		if not OhmnaP4 then
			core:AddMsg("OTENT", self.L["Tentacles"], 5, "Info", "Blue")
			core:AddBar("OTENT", self.L["Next Tentacles"], 20)
		end
	elseif sName == self.L["Ravenous Maw of the Dreadphage"] then
		core:MarkUnit(unit, 0)
		core:AddLine(unit:GetId(), 2, unit, nil, 3, 25, 0)
	elseif sName == self.L["Dreadphage Ohmna"] then
		core:AddUnit(unit)
	end
end

function mod:OnHealthChanged(unitName, health)
	if unitName == self.L["Dreadphage Ohmna"] then
		if health == 52 then
			core:AddMsg("OP2", self.L["P2 SOON !"], 5, "Alert")
		elseif health == 20 then
			core:AddMsg("OP3", self.L["P3 SOON !"], 5, "Alert")
		elseif health == 17 then
			core:AddMsg("OP3", self.L["P3 REALLY SOON !"], 5, "Alert")
		end
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Dreadphage Ohmna"] then
		if castName == self.L["Erupt"] then
			if OhmnaP3 then return end
			local pilarActivated = self:OhmnaPE(pilarCount % 2)
			core:AddBar("OPILAR", self.L["pillar %u : %u"]:format(pilarCount, pilarActivated), 32, 1)
			if self:Tank() then
				core:AddBar("OBORE", self.L["SWITCH TANK"], 45)
			end
			core:StopScan()
		elseif castName == self.L["Genetic Torrent"] then
			core:AddMsg("SPEW", self.L["BIG SPEW"], 5, "RunAway")
			core:AddBar("OSPEW", self.L["NEXT BIG SPEW"], OhmnaP4 and 40 or 60, 1)
		end
	end
end

function mod:OhmnaPE(lowest)
	local tStatus = {}
	local strResult = ""
	local max_val
	local tActiveEvents = PublicEvent.GetActiveEvents()
	for idx, peEvent in pairs(tActiveEvents) do
		for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
			if peObjective:GetShortDescription() == self.L["North Power Core Energy"] then
				tStatus["NORTH"] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == self.L["South Power Core Energy"] then
				tStatus["SOUTH"] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == self.L["East Power Core Energy"] then
				tStatus["EAST"] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == self.L["West Power Core Energy"] then
				tStatus["WEST"] = peObjective:GetCount()
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
		if message:find(self.L["A plasma leech begins draining"]) then
			if OhmnaP3 then return end
			pilarCount = pilarCount + 1
			if submergeCount < 2 and pilarCount > 4 then
				core:AddBar("OPILAR", self.L["PHASE 2"], firstPull and 27 or 22)
				firstPull = false
			else
				local pilarActivated = self:OhmnaPE(pilarCount % 2)
				core:AddBar("OPILAR", self.L["PILLAR %u : %u"]:format(pilarCount, pilarActivated), 25, 1)
			end
		elseif message:find(self.L["Dreadphage Ohmna submerges"]) then
			pilarCount, boreCount = 1, 0
			submergeCount = submergeCount + 1
			core:StopBar("OTENT")
			core:StartScan()
		elseif message:find(self.L["Dreadphage Ohmna is bored"]) then
			boreCount = boreCount + 1
			if boreCount < 2 and self:Tank() then
				core:AddBar("OBORE", self.L["SWITCH TANK"], 42)
			end
		elseif message:find(self.L["The Archives tremble as Dreadphage Ohmna"]) then
			core:AddMsg("OP2", self.L["P2: TENTACLES"], 5, "Alert")
		elseif message:find(self.L["The Archives quake with the furious might"]) then
			core:AddMsg("OP3", self.L["P3: RAVENOUS"], 5, "Alert")
			OhmnaP3 = true
			core:StopBar("OPILAR")
			core:StopBar("OBORE")
			core:AddBar("OSPEW", self.L["NEXT BIG SPEW"], 45, 1)
			core:StartScan()
		end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Dreadphage Ohmna"] then
			self:Start()
			pilarCount, boreCount, submergeCount = 1, 0, 0
			firstPull, OhmnaP3, OhmnaP4 = true, false, false
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:AddBar("OPILAR", self.L["PILLAR %u"]:format(pilarCount), 25, 1)
			core:AddLine("Ohmna1", 2, unit, nil, 3, 25, 0)
			core:AddLine("Ohmna2", 2, unit, nil, 1, 25, 120)
			core:AddLine("Ohmna3", 2, unit, nil, 1, 25, -120)
			if self:Tank() then
				core:AddBar("OBORE", self.L["SWITCH TANK"], 45)
			end
		end
	end
end
