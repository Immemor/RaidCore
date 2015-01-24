--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpFrostFire", 52)
if not mod then return end

--mod:RegisterEnableMob("Hydroflux")
mod:RegisterEnableBossPair("Hydroflux", "Pyrobane")

--------------------------------------------------------------------------------
-- Locals
--
local GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage

local groupCount = 0
local groupTimer = 10
local uPlayer = nil
local strMyName = ""
local prev = 0

local splId_frostbomb = 75058
local splId_firebomb = 75059
local firebomb_players = {}
local frostbomb_players = {}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("CHAT_NPCSAY", 			"OnChatNPCSay", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", 	"OnDebuffAppliedDose", self)
	Apollo.RegisterEventHandler("DEBUFF_REMOVED", 		"OnDebuffRemoved", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnReset()
	core:ResetMarks()
	firebomb_players = {}
	frostbomb_players = {}
end

function mod:RemoveBombMarker(bomb_type, unit)
	if not unit then return end
	local unitName = unit:GetName()
	local unitId = unit:GetId()
	core:DropMark(unitId)
	core:RemoveUnit(unitId)
	if bomb_type == "fire" then
		firebomb_players[unitName] = nil
	elseif bomb_type == "frost" then
		frostbomb_players[unitName] = nil
	end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
	if splId == splId_firebomb then
		mod:RemoveBombMarker("fire", unit)
	elseif splId == splId_frostbomb then
		mod:RemoveBombMarker("frost", unit)
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	--[[local eventTime = GameLib.GetGameTime()
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName
		if tSpell then
			strSpellName = tostring(tSpell:GetName())
		else
			Print("Unknown tSpell")
	end--]]
	if splId == splId_firebomb then
		core:MarkUnit(unit, nil, "Fire\nBomb")
		core:AddUnit(unit)
		firebomb_players[unitName] = unit
		if unitName == strMyName then
			core:AddMsg("BOMB", "BOMBS UP !", 5, "RunAway")
		end
		self:ScheduleTimer("RemoveBombMarker", 10, "fire", unit)
	elseif splId == splId_frostbomb then
		core:MarkUnit(unit, nil, "Frost\nBomb")
		core:AddUnit(unit)
		frostbomb_players[unitName] = unit
		if unitName == strMyName then
			core:AddMsg("BOMB", "BOMBS UP !", 5, "RunAway")
		end
		self:ScheduleTimer("RemoveBombMarker", 10, "frost", unit)
	end
	--Print(eventTime .. " " .. unitName .. "has debuff: " .. strSpellName .. " with splId: " .. splId .. " - type: DebuffNormal")
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Ice Tomb" then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 13 then
			prev = timeOfEvent
			core:AddMsg("TOMB", "ICE TOMB", 5, "Alert", "Blue")
			core:AddBar("TOMB", "ICE TOMB", 15)
			core:AddUnit(unit)
		end
	elseif sName == "Flame Wave" then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 20, 40, 0)	
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	if sName == "Flame Wave" then
		core:DropPixie(unit:GetId())
	end	
end

function mod:OnDebuffAppliedDose(unitName, splId, stack)
	if (splId == 52874 or splId == 52876) and ((self:Tank() and stack == 13) or (not self:Tank() and stack == 10)) then
		core:AddMsg("STACK", "HIGH STACKS !", 5, "Beware")
	end
end

function mod:OnChatNPCSay(message)
	if message:find("Burning mortals... such sweet agony") 
	or message:find("Run! Soon my fires will destroy you")
	or message:find("Ah! The smell of seared flesh") 
	or message:find("Enshrouded in deadly flame")  
	or message:find("Pyrobane ignites you")   then
		core:AddBar("SWITCH", "GROUP ENGAGE", groupTimer, 1)
		core:AddBar("BOMBS", "BOMBS", 30)
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Hydroflux" then
			core:AddUnit(unit)
		elseif sName == "Pyrobane" then
			self:Start()
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			groupCount = 1
			prev = 0
			core:AddUnit(unit)
			core:RaidDebuff()
			core:AddBar("BOMBS", "BOMBS", 30)
			core:AddBar("SWITCH", "GROUP ENGAGE", groupTimer, 1)
			core:StartScan()
		end
	end
end


function mod:SwitchGroup()
	core:AddMsg("SWITCH", ("GROUP %s GO"):format(groupCount), 5, "Info", "Blue")
	if groupCount == 3 then groupCount = 0 end
	groupCount = groupCount + 1
	core:AddBar("SWITCH", ("GROUP %s GO"):format(groupCount), groupTimer, 1)
	self:ScheduleTimer("SwitchGroup", groupTimer)
end