--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpLifeFire", 52)
if not mod then return end

--mod:RegisterEnableMob("Visceralus")
mod:RegisterEnableBossPair("Visceralus", "Pyrobane")
mod:RegisterRestrictZone("EpLifeFire", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")

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
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", 	"OnDebuffAppliedDose", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
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
				if debuff.splEffect:GetId() == 73179 then -- the root ability, Primal Entanglement
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

	if splId == 73179 or splId == 73177 then -- the root ability, Primal Entanglement
		--Print(unitName .. " has debuff: Primal Entanglement")
		if unitName == strMyName then
			core:AddMsg("ROOT", "You are rooted", 5, "Info")
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

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()
	
	if sName == "Life Force" then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 10, -40, 0)
	elseif sName == "Essence of Life" then
		--Print("Life essence spawned")
		--core:AddUnit(unit)
	elseif sName == "Flame Wave" then
		local unitId = unit:GetId()
		if unitId then
			core:AddPixie(unitId, 2, unit, nil, "Green", 10, 20, 0)	
		end
	end	
	--Print(eventTime .. " - " .. sName)
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()

	if sName == "Life Force" then
		core:DropPixie(unit:GetId())
	elseif sName == "Flame Wave" then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId)
		end
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == "Visceralus" and castName == "Blinding Light" then
		local playerUnit = GameLib.GetPlayerUnit()
		if dist2unit(unit, playerUnit) < 33 then
			core:AddMsg("BLIND", "Blinding Light", 5, "Beware")
		end
	end
	--Print(eventTime .. " " .. unitName .. " is casting " .. castName)
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Visceralus" then
			core:AddUnit(unit)
			core:WatchUnit(unit)
		elseif sName == "Pyrobane" then
			self:Start()
			rooted_units = {}
			CheckRootTimer = nil
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			core:AddUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("MID", "MIDPHASE", 90)
		end
	end
end