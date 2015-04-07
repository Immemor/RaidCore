--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("DSFrostWing", 52)
if not mod then return end

mod:RegisterEnableMob("Frost-Boulder Avalanche", "Frostbringer Warlock")

--------------------------------------------------------------------------------
-- Locals
--

local icicleSpell = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
end
mod:RegisterEnglishLocale({
	-- Unit names.
	["Frost-Boulder Avalanche"] = "Frost-Boulder Avalanche",
	["Frostbringer Warlock"] = "Frostbringer Warlock",
	-- Cast.
	["Icicle Storm"] = "Icicle Storm",
	["Shatter"] = "Shatter",
	["Cyclone"] = "Cyclone",
	-- Bar and messages.
	["CYCLONE SOON"] = "CYCLONE SOON",
	["ICICLE"] = "ICICLE",
	["PHASE 2 SOON"] = "PHASE 2 SOON",
	["1ST ABILITY"] = "1ST ABILITY",
	["2ND ABILITY"] = "2ND ABILITY",
	["3RD ABILITY"] = "3RD ABILITY",
	["FROST WAVE"] = "FROST WAVE",
	["RUNNNN"] = "RUNNNN",
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
-- Event Handlers
--

function mod:OnHealthChanged(unitName, health)
	if unitName == self.L["Frost-Boulder Avalanche"] and (health == 85 or health == 55 or health == 31) then
		core:AddMsg("CYCLONE", self.L["CYCLONE SOON"], 5, "Info", "Blue")
	elseif unitName == self.L["Frost-Boulder Avalanche"] and health == 22 then
		core:AddMsg("PHASE2", self.L["PHASE 2 SOON"], 5, "Info", "Blue")
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Frost-Boulder Avalanche"] then
		if castName == self.L["Icicle Storm"] then
			core:StopBar("SHATTER")
			core:AddMsg("ICICLE", self.L["ICICLE"].." !!", 5, "Alert")
			core:AddBar("ICICLE", self.L["ICICLE"], 22)
			icicleSpell = true
		elseif castName == self.L["Shatter"] then
			core:AddMsg("SHATTER", self.L["Shatter"]:upper().." !!", 5, "Alert")
			core:AddBar("SHATTER", self.L["Shatter"]:upper(), 30)
		elseif castName == self.L["Cyclone"] then
			core:AddMsg("CYCLONE", self.L["Cyclone"]:upper(), 5, "RunAway")
			core:AddBar("RUN", self.L["RUNNNN"], 23, 1)
			if icicleSpell then
				core:AddBar("1ST", self.L["1ST ABILITY"], 33)
				core:AddBar("2ND", self.L["2ND ABILITY"], 40.5)
				core:AddBar("3RD", self.L["3RD ABILITY"], 48)
				--core:AddBar("ICICLE", self.L["ICICLE"], 48)
			else
				core:AddBar("SHATTER", self.L["Shatter"]:upper(), 50)
			end
			core:AddBar("CYCLONE", self.L["Cyclone"]:upper(), 90, 1)
		end
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Frost-Boulder Avalanche"] then
			self:Start()
			icicleSpell = false
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:AddBar("ICICLE", "~" .. self.L["ICICLE"], 17)
			core:AddBar("SHATTER", "~" .. self.L["Shatter"]:upper(), 30)
			core:StartScan()
		elseif sName == self.L["Frostbringer Warlock"] then
			self:Start()
			core:AddUnit(unit)
			core:AddBar("WAVES", self.L["FROST WAVE"], 30)
		end
	end
end
