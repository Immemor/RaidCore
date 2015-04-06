--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpFrostAir", 52)
if not mod then return end

--mod:RegisterEnableMob("Hydroflux")
mod:RegisterEnableBossPair("Hydroflux", "Aileron")
mod:RegisterRestrictZone("EpFrostAir", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Hydroflux"] = "Hydroflux",
	["Aileron"] = "Aileron",
	["Landing Volume"] = "Landing Volume",
	["Wind Wall"] = "Wind Wall",
	-- Datachron messages.
	["Hydroflux evaporates"] = "Hydroflux evaporates",
	["Aileron dissipates with a flurry"] = "Aileron dissipates with a flurry",
	["The wind starts to blow faster and faster"] = "The wind starts to blow faster and faster",
	-- Cast.
	["Tsunami"] = "Tsunami",
	["Glacial Icestorm"] = "Glacial Icestorm",
	-- Bar and messages.
	["EYE OF THE STORM"] = "EYE OF THE STORM",
	["MOO !"] = "MOO !",
	["MOO PHASE"] = "MOO PHASE",
	["ICESTORM"] = "ICESTORM",
	["~Middle Phase"] = "~Middle Phase",
	["~Frost Tombs"] = "~Frost Tombs",
	["TWIRL ON YOU!"] = "TWIRL ON YOU!",
	["TWIRL"] = "TWIRL",
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

local prev = 0
local mooCount = 0
local phase2 = false
local myName
local CheckTwirlTimer = nil

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	--Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnReset()
	if CheckTwirlTimer then
		self:CancelTimer(CheckTwirlTimer)
	end
	core:ResetMarks()
	twirl_units = {}
end

function mod:OnUnitCreated(unit, sName)
	--Print(sName)
	if sName == self.L["Landing Volume"] then
		core:MarkUnit(unit, 0, "LAND")
	end
end

function mod:OnUnitDestroyed(unit, sName)
	--Print(sName)
	if sName == self.L["Wind Wall"] then
		core:DropLine(unit:GetId().."_1")
		core:DropLine(unit:GetId().."_2")
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Hydroflux"] then
		if castName == self.L["Tsunami"] then
			phase2 = true
			mooCount = mooCount + 1
			core:AddMsg("PHASE2", self.L["Tsunami"]:upper(), 5, "Alert")
		elseif castName == self.L["Glacial Icestorm"] then
			core:AddMsg("ICESTORM", self.L["ICESTORM"], 5, "RunAway")
		end
	end
end

function mod:OnSpellCastEnd(unitName, castName)
	if unitName == self.L["Hydroflux"] and castName == self.L["Tsunami"] then
		core:AddBar("MIDPHASE", self.L["~Middle Phase"], 88, true)
		core:AddBar("TOMB", self.L["~Frost Tombs"], 30, true)
	end
	--Print(unitName .. " - " .. castName)
end

function mod:OnChatDC(message)
	if message:find(self.L["Hydroflux evaporates"]) then
		--core:AddMsg("PHASE1", "MOO !", 5, "Info", "Blue")
		core:AddBar("PHASE2", self.L["EYE OF THE STORM"], 45, 1)
	elseif message:find(self.L["Aileron dissipates with a flurry"]) then
		core:AddBar("PHASE2", self.L["Tsunami"]:upper(), 45, 1)
	elseif message:find(self.L["The wind starts to blow faster and faster"]) then
		phase2 = true
		mooCount = mooCount + 1
		core:AddMsg("PHASE2", self.L["EYE OF THE STORM"], 5, "Alert")
	end
end

function mod:OnBuffApplied(unitName, splId, unit)
	if phase2 and (splId == 69959 or splId == 47075) then
		phase2 = false
		core:AddMsg("MOO", self.L["MOO !"], 5, "Info", "Blue")
		core:AddBar("MOO", self.L["MOO PHASE"], 10, 1)
		if mooCount == 2 then
			mooCount = 0
			core:AddBar("ICESTORM", self.L["ICESTORM"], 15)
		end
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " debuff applied on unit: " .. unitName .. " - " .. splId)
	if splId == 70440 then -- Twirl ability
		--Print(eventTime .. " debuff applied on unit: " .. unitName .. " - " .. splId)

		if unitName == myName then
			core:AddMsg("TWIRL", self.L["TWIRL ON YOU!"], 5, "Inferno")
		end

		core:MarkUnit(unit, nil, self.L["TWIRL"])
		core:AddUnit(unit)
		twirl_units[unitName] = unit
		if not CheckTwirlTimer then
			CheckTwirlTimer = self:ScheduleRepeatingTimer("CheckTwirlTimer", 1)
		end
	end
end

function mod:CheckTwirlTimer()
	for unitName, unit in pairs(twirl_units) do
		if unit and unit:GetBuffs() then
			local bUnitHasTwirl = false
			local debuffs = unit:GetBuffs().arHarmful
			for _, debuff in pairs(debuffs) do
				if debuff.splEffect:GetId() == 70440 then -- the Twirl ability
					bUnitHasTwirl = true
				end
			end
			if not bUnitHasTwirl then
				-- else, if the debuff is no longer present, no need to track anymore.
				core:DropMark(unit:GetId())
				core:RemoveUnit(unit:GetId())
				twirl_units[unitName] = nil
			end
		end
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local eventTime = GameLib.GetGameTime()
		local playerUnit = GameLib.GetPlayerUnit()
		myName = playerUnit:GetName()

		if sName == self.L["Hydroflux"] then
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:UnitBuff(unit)
		elseif sName == self.L["Aileron"] then
			self:Start()
			mooCount = 0
			phase2 = false
			twirl_units = {}
			CheckTwirlTimer = nil
			core:AddUnit(unit)
			core:UnitBuff(unit)
			core:UnitDebuff(playerUnit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("MIDPHASE", self.L["Middle Phase"], 60, true)
			core:AddBar("TOMB", self.L["~Frost Tombs"], 30, true)

			--Print(eventTime .. " " .. sName .. " FIGHT STARTED ")
		end
	end
end
