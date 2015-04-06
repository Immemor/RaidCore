--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpFrostFire", 52)
if not mod then return end

--mod:RegisterEnableMob("Hydroflux")
mod:RegisterEnableBossPair("Hydroflux", "Pyrobane")
mod:RegisterRestrictZone("EpFrostFire", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Hydroflux"] = "Hydroflux",
	["Pyrobane"] = "Pyrobane",
	["Ice Tomb"] = "Ice Tomb",
	-- Datachron messages.
	-- NPCSay messages.
	["Burning mortals... such sweet agony"] = "Burning mortals... such sweet agony",
	["Run! Soon my fires will destroy you"] = "Run! Soon my fires will destroy you",
	["Ah! The smell of seared flesh"] = "Ah! The smell of seared flesh",
	["Enshrouded in deadly flame"] = "Enshrouded in deadly flame",
	["Pyrobane ignites you"] = "Pyrobane ignites you",
	-- Cast.
	["Flame Wave"] = "Flame Wave",
	-- Bar and messages.
	["Frost Bomb"] = "Frost\nBomb",
	["BOMBS"] = "BOMBS",
	["BOMBS UP !"] = "BOMBS UP !",
	["Bomb Explosion"] = "Bomb Explosion",
	["ICE TOMB"] = "ICE TOMB",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})
mod:RegisterGermanLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})

--------------------------------------------------------------------------------
-- Locals
--
local DEBUFFID_ICE_TOMB = 74326
local DEBUFFID_FROSTBOMB = 75058
local DEBUFFID_FIREBOMB = 75059

local GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage

local groupCount = 0
local uPlayer = nil
local strMyName = ""
local prev = 0
local prevBomb = 0

local firebomb_players = {}
local frostbomb_players = {}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	rpollo.RegisterEventHandler("CHAT_NPCSAY", "OnChatNPCSay", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", "OnDebuffAppliedDose", self)
	Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
	Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
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

function mod:OnReset()
	core:ResetMarks()
	firebomb_players = {}
	frostbomb_players = {}
	prevBomb = 0
end

function mod:RemoveBombMarker(bomb_type, unit)
	if not unit then return end
	local unitName = unit:GetName()
	local unitId = unit:GetId()
	if not unitId or not unitName then return end -- stupid carbine api likes to return nil...
	core:DropMark(unitId)
	core:RemoveUnit(unitId)
	if bomb_type == "fire" then
		firebomb_players[unitName] = nil
		core:DropPixie(unitId .. "_BOMB")
	elseif bomb_type == "frost" then
		frostbomb_players[unitName] = nil
		core:DropPixie(unitId .. "_BOMB")
	end
end

function mod:ApplyBombLines(bomb_type)
	if bomb_type == "fire" then
		for key, value in pairs(frostbomb_players) do
			local unitId = value:GetId()
			if unitId then
				core:AddPixie(unitId .. "_BOMB", 1, uPlayer, value, "Blue", 5, 10, 10)
			end
		end
	elseif bomb_type == "frost" then
		for key, value in pairs(firebomb_players) do
			local unitId = value:GetId()
			if unitId then
				core:AddPixie(unitId .. "_BOMB", 1, uPlayer, value, "Red", 5, 10, 10)
			end
		end
	end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
	if splId == DEBUFFID_FIREBOMB then
		mod:RemoveBombMarker("fire", unit)
	elseif splId == DEBUFFID_FROSTBOMB then
		mod:RemoveBombMarker("frost", unit)
	elseif splId == DEBUFFID_ICE_TOMB then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId .. "_TOMB")
		end
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName
		if tSpell then
			strSpellName = tostring(tSpell:GetName())
		else
			Print("Unknown tSpell")
	end

	if splId == DEBUFFID_FIREBOMB then
		core:MarkUnit(unit, nil, "Fire\nBomb")
		--core:AddPixie(unit:GetId() .. "_BOMB", 2, unit, nil, "Red", 7, 10, 0, 50)
		core:AddUnit(unit)
		firebomb_players[unitName] = unit
		if unitName == strMyName then
			core:AddMsg("BOMB", self.L["BOMBS UP !"], 5, "RunAway")
			self:ScheduleTimer("ApplyBombLines", 1, "fire")
		end
		self:ScheduleTimer("RemoveBombMarker", 10, "fire", unit)
	elseif splId == DEBUFFID_FROSTBOMB then
		core:MarkUnit(unit, nil, self.L["Frost Bomb"])
		--core:AddPixie(unit:GetId() .. "_BOMB", 2, unit, nil, "Blue", 7, 10, 0, 50)
		core:AddUnit(unit)
		frostbomb_players[unitName] = unit
		if unitName == strMyName then
			core:AddMsg("BOMB", self.L["BOMBS UP !"], 5, "RunAway")
			self:ScheduleTimer("ApplyBombLines", 1, "frost")
		end
		self:ScheduleTimer("RemoveBombMarker", 10, "frost", unit)
	elseif splId == DEBUFFID_ICE_TOMB and dist2unit(uPlayer, unit) < 45 then -- Ice Tomb Debuff
		local unitId = unit:GetId()
		if unitId then
			core:AddPixie(unitId .. "_TOMB", 1, uPlayer, unit, "Blue", 5, 10, 10)
		end
	end
	if splId == DEBUFFID_FIREBOMB or splId == DEBUFFID_FROSTBOMB then
		if eventTime - prevBomb > 10 then
			prevBomb = eventTime
			core:AddBar("BEXPLODE", self.L["Bomb Explosion"], 10, true)
		end
	end
	--Print(eventTime .. " " .. unitName .. "has debuff: " .. strSpellName .. " with splId: " .. splId .. " - type: DebuffNormal")
end

function mod:OnUnitCreated(unit, sName)
	if sName == self.L["Ice Tomb"] then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 13 then
			prev = timeOfEvent
			core:AddMsg("TOMB", self.L["ICE TOMB"], 5, "Alert", "Blue")
			core:AddBar("TOMB", self.L["ICE TOMB"], 15)
		end
		core:AddUnit(unit)
	elseif sName == self.L["Flame Wave"] then
		local unitId = unit:GetId()
		if unitId then
			core:AddPixie(unitId, 2, unit, nil, "Green", 10, 20, 0)
		end
	end
end

function mod:OnUnitDestroyed(unit, sName)
	if sName == self.L["Flame Wave"] then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId)
		end
	end
end

function mod:OnDebuffAppliedDose(unitName, splId, stack)
	if (splId == 52874 or splId == 52876) and ((self:Tank() and stack == 13) or (not self:Tank() and stack == 10)) then
		if unitName == strMyName then
			local msgString = stack .. " STACKS!"
			core:AddMsg("STACK", msgString, 5, "Beware")
		end
	end
end

function mod:OnChatNPCSay(message)
	if message:find(self.L["Burning mortals... such sweet agony"])
	or message:find(self.L["Run! Soon my fires will destroy you"])
	or message:find(self.L["Ah! The smell of seared flesh"])
	or message:find(self.L["Enshrouded in deadly flame"])
	or message:find(self.L["Pyrobane ignites you"]) then
		core:AddBar("BOMBS", self.L["BOMBS"], 30)
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Hydroflux"] then
			core:AddUnit(unit)
			local unitId = unit:GetId()
			if unitId then
				core:AddPixie(unitId .. "_1", 2, unit, nil, "Yellow", 3, 7, 0)
				core:AddPixie(unitId .. "_2", 2, unit, nil, "Yellow", 3, 7, 180)
			end
		elseif sName == self.L["Pyrobane"] then
			self:Start()
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			groupCount = 1
			prev = 0
			prevBomb = 0

			core:AddUnit(unit)
			core:RaidDebuff()
			core:AddBar("BOMBS", self.L["BOMBS"], 30)
			core:StartScan()
		end
	end
end
