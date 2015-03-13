--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Ohmna", 67)
if not mod then return end

mod:RegisterEnableMob("Dreadphage Ohmna")
mod:RegisterRestrictEventObjective("Defeat Dreadphage Ohmna")
mod:RegisterEnableEventObjective("Defeat Dreadphage Ohmna")

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
        if min_val > v  and v > 0 then
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
	if sName == "Tentacle of Ohmna" then
		if not OhmnaP4 then
			core:AddMsg("OTENT", "Tentacles", 5, "Info", "Blue")
			core:AddBar("OTENT", "Next Tentacles", 20)
		end
	elseif sName == "Ravenous Maw of the Dreadphage" then
		core:MarkUnit(unit, 0)
		core:AddLine(unit:GetId(), 2, unit, nil, 3, 25, 0)
	elseif sName == "Dreadphage Ohmna" then
		core:AddUnit(unit)
	end
end

function mod:OnHealthChanged(unitName, health)
	if unitName == "Dreadphage Ohmna" and health == 52 then
		core:AddMsg("OP2", "P2 SOON !", 5, "Alert")
	elseif unitName == "Dreadphage Ohmna" and health == 20 then
		core:AddMsg("OP3", "P3 SOON !", 5, "Alert")
	elseif unitName == "Dreadphage Ohmna" and health == 17 then
		core:AddMsg("OP3", "P3 REALLY SOON !", 5, "Alert")
	end
end


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Dreadphage Ohmna" and castName == "Erupt" then
		if OhmnaP3 then return end
		local pilarActivated = self:OhmnaPE(pilarCount % 2)
		core:AddBar("OPILAR", ("PILLAR %s : %s"):format(pilarCount, pilarActivated), 32, 1)
		if self:Tank() then
			core:AddBar("OBORE", "SWITCH TANK", 45)
		end
		core:StopScan()
	elseif unitName == "Dreadphage Ohmna" and castName == "Genetic Torrent" then
		core:AddMsg("SPEW", "BIG SPEW", 5, "RunAway")
		core:AddBar("OSPEW", "NEXT BIG SPEW", OhmnaP4 and 40 or 60, 1)
	end
end

function mod:OhmnaPE(lowest)
	local tStatus = {}
	local strResult = ""
	local max_val
	local tActiveEvents = PublicEvent.GetActiveEvents()
	for idx, peEvent in pairs(tActiveEvents) do
		for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
			if peObjective:GetShortDescription() == "North Power Core Energy" then
				tStatus["NORTH"] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == "South Power Core Energy" then
				tStatus["SOUTH"] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == "East Power Core Energy" then
				tStatus["EAST"] = peObjective:GetCount()
			elseif peObjective:GetShortDescription() == "West Power Core Energy" then
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
		if message:find("A plasma leech begins draining") then
			if OhmnaP3 then return end
			pilarCount = pilarCount + 1
			if submergeCount < 2 and pilarCount > 4 then
				core:AddBar("OPILAR", "PHASE 2", firstPull and 27 or 22)
				firstPull = false
			else
				local pilarActivated = self:OhmnaPE(pilarCount % 2)
				core:AddBar("OPILAR", ("PILLAR %s : %s"):format(pilarCount, pilarActivated), 25, 1)
			end
		elseif message:find("Dreadphage Ohmna submerges") then
			pilarCount, boreCount = 1, 0
			submergeCount = submergeCount + 1
			core:StopBar("OTENT")
			core:StartScan()
		elseif message:find("Dreadphage Ohmna is bored") then
			boreCount = boreCount + 1
			if boreCount < 2 and self:Tank() then
				core:AddBar("OBORE", "SWITCH TANK", 42)
			end
		elseif message:find("The Archives tremble as Dreadphage Ohmna") then
			core:AddMsg("OP2", "P2 : TENTACLES", 5, "Alert")
		elseif message:find("The Archives quake with the furious might") then
			core:AddMsg("OP3", "P3 : RAVENOUS", 5, "Alert")
			OhmnaP3 = true
			core:StopBar("OPILAR")
			core:StopBar("OBORE")
			core:AddBar("OSPEW", "NEXT BIG SPEW", 45, 1)
			core:StartScan()
		end
end



function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Dreadphage Ohmna" then
			self:Start()
			pilarCount, boreCount, submergeCount = 1, 0, 0
			firstPull, OhmnaP3, OhmnaP4 = true, false, false
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:AddBar("OPILAR", ("PILLAR %s"):format(pilarCount), 25, 1)
			core:AddLine("Ohmna1", 2, unit, nil, 3, 25, 0)
			core:AddLine("Ohmna2", 2, unit, nil, 1, 25, 120)
			core:AddLine("Ohmna3", 2, unit, nil, 1, 25, -120)
			if self:Tank() then
				core:AddBar("OBORE", "SWITCH TANK", 45)
			end
		end
	end
end
