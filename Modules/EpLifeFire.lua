--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpLifeFire", 52)
if not mod then return end

--mod:RegisterEnableMob("Visceralus")
mod:RegisterEnableBossPair("Visceralus", "Pyrobane")
mod:RegisterRestrictZone("EpLifeFire", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Visceralus"] = "Visceralus",
	["Pyrobane"] = "Pyrobane",
	["Life Force"] = "Life Force",
	["Essence of Life"] = "Essence of Life",
	["Flame Wave"] = "Flame Wave",
	-- Datachron messages.
	-- Cast.
	["Blinding Light"] = "Blinding Light",
	-- Bar and messages.
	["You are rooted"] = "You are rooted",
	["MIDPHASE"] = "MIDPHASE",
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

local DEBUFFID_PRIMAL_ENTANGLEMENT = 73179 -- A root ability.
local DEBUFFIF__TODO__ = 73177 -- TODO: set english debuff name as define name.

--------------------------------------------------------------------------------
-- Locals
--

local rooted_units = {}
local uPlayer = nil
local strMyName = ""
local CheckRootTimer = nil

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", "OnDebuffAppliedDose", self)
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
	if CheckRootTimer then
		self:CancelTimer(CheckRootTimer)
	end
	core:ResetMarks()
	rooted_units = {}
end

function mod:CheckRootTracker()
	for unitName, unit in pairs(rooted_units) do
		if unit and unit:GetBuffs() then
			local bUnitIsRooted = false
			local debuffs = unit:GetBuffs().arHarmful
			for _, debuff in pairs(debuffs) do
				if debuff.splEffect:GetId() == DEBUFFID_PRIMAL_ENTANGLEMENT then
					bUnitIsRooted = true
				end
			end
			if not bUnitIsRooted then
				-- else, if the debuff is no longer present, no need to track anymore.
				core:DropMark(unit:GetId())
				core:RemoveUnit(unit:GetId())
				rooted_units[unitName] = nil
			end
		end
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName = tSpell:GetName()
	--[[
	local strSpellName
		if tSpell then
			strSpellName = tostring(tSpell:GetName())
		else
			Print("Unknown tSpell")
	end--]]

	if splId == DEBUFFID_PRIMAL_ENTANGLEMENT or splId == DEBUFFIF__TODO__ then
		--Print(unitName .. " has debuff: Primal Entanglement")
		if unitName == strMyName then
			core:AddMsg("ROOT", self.L["You are rooted"], 5, "Info")
		end
		core:MarkUnit(unit, nil, "ROOT")
		core:AddUnit(unit)
		rooted_units[unitName] = unit
		if not CheckRootTimer then
			CheckRootTimer = self:ScheduleRepeatingTimer("CheckRootTracker", 1)
		end
	elseif strSpellName == "Life Force Shackle" and unitName == strMyName then
		--Print("Debuff!")
		core:AddMsg("NOHEAL", "No-Healing Debuff!", 5, "Alarm")
	end
	--Print(eventTime .. " " .. unitName .. "has debuff: " .. strSpellName .. " with splId: " .. splId)
end

function mod:OnUnitCreated(unit, sName)
	if sName == self.L["Life Force"] then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 10, -40, 0)
	elseif sName == self.L["Essence of Life"] then
		--Print("Life essence spawned")
		--core:AddUnit(unit)
	elseif sName == self.L["Flame Wave"] then
		local unitId = unit:GetId()
		if unitId then
			core:AddPixie(unitId, 2, unit, nil, "Green", 10, 20, 0)
		end
	end
end

function mod:OnUnitDestroyed(unit, sName)
	if sName == self.L["Life Force"] then
		core:DropPixie(unit:GetId())
	elseif sName == self.L["Flame Wave"] then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId)
		end
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == self.L["Visceralus"] and castName == self.L["Blinding Light"] then
		local playerUnit = GameLib.GetPlayerUnit()
		if dist2unit(unit, playerUnit) < 33 then
			core:AddMsg("BLIND", self.L["Blinding Light"], 5, "Beware")
		end
	end
	--Print(eventTime .. " " .. unitName .. " is casting " .. castName)
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Visceralus"] then
			core:AddUnit(unit)
			core:WatchUnit(unit)
		elseif sName == self.L["Pyrobane"] then
			self:Start()
			rooted_units = {}
			CheckRootTimer = nil
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			core:AddUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("MID", self.L["MIDPHASE"], 90)
		end
	end
end
