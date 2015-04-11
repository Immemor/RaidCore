--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("DS_EpLogicLife", 52)
if not mod then return end

mod:RegisterEnableBossPair("Mnemesis", "Visceralus")
mod:RegisterRestrictZone("DS_EpLogicLife", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Essence of Life"] = "Essence of Life",
	["Essence of Logic"] = "Essence of Logic",
	["Alphanumeric Hash"] = "Alphanumeric Hash",
	["Life Force"] = "Life Force",
	["Mnemesis"] = "Mnemesis",
	["Visceralus"] = "Visceralus",
	-- Datachron messages.
	-- Cast.
	["Blinding Light"] = "Blinding Light",
	["Defragment"] = "Defragment",
	-- Bar and messages.
	["Defrag Explosion"] = "Defrag Explosion",
	["~DEFRAG CD"] = "~DEFRAG CD",
	["DEFRAG"] = "DEFRAG",
	["ENRAGE"] = "ENRAGE",
	["No-Healing Debuff!"] = "No-Healing Debuff!",
	["NO HEAL DEBUFF"] = "NO HEAL\nDEBUFF",
	["SNAKE ON YOU!"] = "SNAKE ON YOU!",
	["SNAKE ON %s!"] = "SNAKE ON %s!",
	["SNAKE"] = "SNAKE",
	["THORNS DEBUFF"] = "THORNS\nDEBUFF",
	["MARKER North"] = "North",
	["MARKER South"] = "South",
	["MARKER East"] = "East",
	["MARKER West"] = "West",
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
local midpos = {
	["north"] = {x = 9741.53, y = -518, z = 17823.81},
	["west"] = {x = 9691.53, y = -518, z = 17873.81},
	["south"] = {x = 9741.53, y = -518, z = 17923.81},
	["east"] = {x = 9791.53, y = -518, z = 17873.81},
}

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
	midphase = false
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName = tSpell:GetName()

	if strSpellName == "Snake Snack" then
		if unitName == strMyName then
			core:AddMsg("SNAKE", self.L["SNAKE ON YOU!"], 5, mod:GetSetting("SoundSnake", "RunAway"))
		else
			core:AddMsg("SNAKE", self.L["SNAKE ON %s!"]:format(unitName), 5, mod:GetSetting("SoundSnake", "Info"))
		end
		if mod:GetSetting("OtherSnakePlayerMarkers") then
			core:MarkUnit(unit, nil, self.L["SNAKE"]) 
		end
	elseif strSpellName == "Life Force Shackle" then
		if mod:GetSetting("OtherNoHealDebuffPlayerMarkers") then
			core:MarkUnit(unit, nil, self.L["NO HEAL DEBUFF"])
		end
		if unitName == strMyName then
			core:AddMsg("NOHEAL", self.L["No-Healing Debuff!"], 5, mod:GetSetting("SoundNoHealDebuff", "Alarm"))
		end
	elseif strSpellName == "Thorns" then
		if mod:GetSetting("OtherRootedPlayersMarkers") then
			core:MarkUnit(unit, nil, self.L["THORNS\nDEBUFF"])
		end
	end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName = tSpell:GetName()

	if strSpellName == "Snake Snack" then
		core:DropMark(unit:GetId())
	elseif strSpellName == "Life Force Shackle" then
		core:DropMark(unit:GetId())
	elseif strSpellName == "Thorns" then
		core:DropMark(unit:GetId())
	end
end

function mod:OnUnitCreated(unit, sName)
	if sName == self.L["Essence of Life"] then
		core:AddUnit(unit)
		if not midphase then
			midphase = true
			if mod:GetSetting("OtherDirectionMarkers") then
				core:SetWorldMarker(midpos["north"], self.L["MARKER North"])
				core:SetWorldMarker(midpos["east"], self.L["MARKER East"])
				core:SetWorldMarker(midpos["south"], self.L["MARKER South"])
				core:SetWorldMarker(midpos["west"], self.L["MARKER West"])
			end
			core:StopBar("DEFRAG")
		end
	elseif sName == self.L["Essence of Logic"] then
		core:AddUnit(unit)
	elseif sName == self.L["Alphanumeric Hash"] then
		local unitId = unit:GetId()
		if unitId then
			if mod:GetSetting("LineTetrisBlocks") then
				core:AddPixie(unitId, 2, unit, nil, "Red", 10, 20, 0)
			end
		end
	elseif sName == self.L["Life Force"] and mod:GetSetting("LineLifeOrbs") then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 3, 15, 0)
	end
end

function mod:OnUnitDestroyed(unit, sName)
	if sName == self.L["Essence of Logic"] then
		midphase = false
		core:ResetWorldMarkers()
	elseif sName == self.L["Alphanumeric Hash"] then
		local unitId = unit:GetId()
		if unitId then
			core:DropPixie(unitId)
		end
	elseif sName == self.L["Life Force"] then
		core:DropPixie(unit:GetId())
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == self.L["Visceralus"] and castName == self.L["Blinding Light"] then
		if dist2unit(unit, uPlayer) < 33 then
			core:AddMsg("BLIND", self.L["Blinding Light"], 5, mod:GetSetting("SoundBlindingLight", "Beware"))
		end
	elseif unitName == self.L["Mnemesis"] and castName == self.L["Defragment"] then
		core:StopBar("DEFRAG")
		core:AddBar("DEFRAG", self.L["~DEFRAG CD"], 40, mod:GetSetting("SoundDefrag")) -- Defrag is unreliable, but seems to take at least this long.
		core:AddBar("DEFRAG1", self.L["Defrag Explosion"], 9, mod:GetSetting("SoundDefrag"))
		core:AddMsg("DEFRAG", self.L["DEFRAG"], 5, mod:GetSetting("SoundDefrag", "Beware"))
	end
	--Print(eventTime .. " " .. unitName .. " Casting: " .. castName)
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Visceralus"] then
			core:AddUnit(unit)
			core:WatchUnit(unit)
			if mod:GetSetting("LineCleaveVisceralus") then
				core:AddLine("Visc1", 2, unit, nil, 3, 25, 0, 10)
				core:AddLine("Visc2", 2, unit, nil, 1, 25, 72)
				core:AddLine("Visc3", 2, unit, nil, 1, 25, 144)
				core:AddLine("Visc4", 2, unit, nil, 1, 25, 216)
				core:AddLine("Visc5", 2, unit, nil, 1, 25, 288)
			end
		elseif sName == self.L["Mnemesis"] then
			self:Start()
			core:WatchUnit(unit)
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			midphase = false
			core:AddUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("DEFRAG", self.L["~DEFRAG CD"], 21, mod:GetSetting("SoundDefrag"))
			core:AddBar("ENRAGE", self.L["ENRAGE"], 480, mod:GetSetting("SoundEnrage"))
		end
	end
end
