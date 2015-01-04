--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpLifeFire", 52)
if not mod then return end

mod:RegisterEnableMob("Visceralus")

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
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

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
	--[[local tSpell = GameLib.GetSpell(splId)
	local strSpellName
		if tSpell then
			strSpellName = tostring(tSpell:GetName())
		else
			Print("Unknown tSpell")
	end--]]
	if splId == 73179 then -- the root ability, Primal Entanglement
		--Print(unitName .. " has debuff: Primal Entanglement")
		if unitName == strMyName then
			core:AddMsg("ROOT", "You are rooted", 5, "Info")
		end
		core:MarkUnit(unit, nil, "Rooted")
		core:AddUnit(unit)
		rooted_units[unitName] = unit
		if not CheckRootTimer then
			CheckRootTimer = self:ScheduleRepeatingTimer("CheckRootTracker", 1)
		end
	end
	--Print(eventTime .. " " .. unitName .. "has debuff: " .. strSpellName .. " with splId: " .. splId)
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Visceralus" then
			core:AddUnit(unit)
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