--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("DS_EpLogicWater", 52)
if not mod then return end

mod:RegisterEnableBossPair("Hydroflux", "Mnemesis")
mod:RegisterRestrictZone("DS_EpLogicWater", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Mnemesis"] = "Mnemesis",
	["Hydroflux"] = "Hydroflux",
	["Alphanumeric Hash"] = "Alphanumeric Hash",
	["Hydro Disrupter - DNT"] = "Hydro Disrupter - DNT",
	-- Datachron messages.
	-- Cast.
	["Circuit Breaker"] = "Circuit Breaker",
	["Imprison"] = "Imprison",
	["Defragment"] = "Defragment",
	["Watery Grave"] = "Watery Grave",
	-- Bar and messages.
	["Middle Phase"] = "Middle Phase",
	["SPREAD"] = "SPREAD",
	["~Defrag"] = "~Defrag",
	["Defrag"] = "Defrag",
	["Stay away from boss with buff!"] = "Stay away from boss with buff!",
	["ORB"] = "ORB",
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

local uPlayer = nil
local strMyName = ""
local midphase = false
local encounter_started = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
	--Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
	Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnReset()
	core:StopBar("MIDPHASE")
	core:StopBar("GRAVE")
	core:StopBar("PRISON")
	core:StopBar("DEFRAG")
	midphase = false
	encounter_started = false
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Mnemesis"] then
		if castName == self.L["Circuit Breaker"] then
			core:StopBar("MIDPHASE")
			core:AddBar("MIDPHASE", self.L["Middle Phase"], 100, mod:GetSetting("SoundMidphase"))
			midphase = true
		elseif castName == self.L["Imprison"] then
			core:StopBar("PRISON")
			core:AddBar("PRISON", self.L["Imprison"], 19)
		elseif castName == self.L["Defragment"] then
			core:StopBar("DEFRAG")
			core:AddMsg("DEFRAG", self.L["SPREAD"], 5, mod:GetSetting("SoundDefrag", "Beware"))
			core:AddBar("DEFRAG", self.L["~Defrag"], 40, mod:GetSetting("SoundDefrag"))
		end
	elseif unitName == self.L["Hydroflux"] then
		if castName == self.L["Watery Grave"] and mod:GetSetting("OtherWateryGraveTimer") then
			core:StopBar("GRAVE")
			core:AddBar("GRAVE", self.L["Watery Grave"], 10)
		end
	end
end

function mod:OnSpellCastEnd(unitName, castName)
	if unitName == self.L["Mnemesis"] and castName == self.L["Circuit Breaker"] then
		midphase = false
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local splName = GameLib.GetSpell(splId):GetName()
	if splName == "Data Disruptor" then
		if unitName == strMyName then
			core:AddMsg("DISRUPTOR", self.L["Stay away from boss with buff!"], 5, mod:GetSetting("SoundDataDisruptorDebuff", "Beware"))
		end
		if mod:GetSetting("OtherOrbMarkers") then
			core:MarkUnit(unit, nil, self.L["ORB"])
		end
	end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName = tSpell:GetName()
	if strSpellName == "Data Disruptor" then
		local unitId = unit:GetId()
		if unitId then
			core:DropMark(unit:GetId())
		end
	end
end

function mod:OnUnitCreated(unit, sName)
	if sName == self.L["Alphanumeric Hash"] then
		local unitId = unit:GetId()
		if unitId and mod:GetSetting("LineTetrisBlocks") then
			core:AddPixie(unitId, 2, unit, nil, "Red", 10, 20, 0)
		end
	elseif sName == self.L["Hydro Disrupter - DNT"] and not midphase and mod:GetSetting("LineOrbs") then
		local unitId = unit:GetId()
		if unitId then
			core:AddPixie(unitId, 1, unit, uPlayer, "Blue", 5, 10, 10)
		end
	elseif sName == self.L["Hydroflux"] or sName == self.L["Mnemesis"] then
		core:AddUnit(unit)
		core:WatchUnit(unit)
	end
end

function mod:OnUnitDestroyed(unit, sName)
	if sName == self.L["Alphanumeric Hash"] then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId)
		end
	elseif sName == self.L["Hydro Disrupter - DNT"] then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId)
		end
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Hydroflux"] then
			core:AddUnit(unit)
			core:WatchUnit(unit)
		elseif sName == self.L["Mnemesis"] then
			self:Start()
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			midphase = false
			encounter_started = true
			--core:UnitDebuff(uPlayer)
			core:RaidDebuff()
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			core:AddBar("MIDPHASE", self.L["Middle Phase"], 75, mod:GetSetting("SoundMidphase"))
			core:AddBar("PRISON", self.L["Imprison"], 16)
			core:AddBar("DEFRAG", self.L["Defrag"], 20, mod:GetSetting("SoundDefrag"))

			if mod:GetSetting("OtherWateryGraveTimer") then
				core:AddBar("GRAVE", self.L["Watery Grave"], 10)
			end
		end
	end
end
