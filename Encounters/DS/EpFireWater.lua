--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("EpFireWater", 52, 98, 118)
if not mod then return end

--mod:RegisterEnableMob("Hydroflux")
mod:RegisterEnableBossPair("Hydroflux", "Pyrobane")
mod:RegisterRestrictZone("EpFireWater", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Hydroflux"] = "Hydroflux",
	["Pyrobane"] = "Pyrobane",
	["Ice Tomb"] = "Ice Tomb",
	-- Datachron messages.
	-- NPCSay messages.
	["Burning mortals... such sweet agony..."] = "Burning mortals... such sweet agony...",
	["Run! Soon my fires will destroy you..."] = "Run! Soon my fires will destroy you...",
	["Ah! The smell of seared flesh..."] = "Ah! The smell of seared flesh...",
	["Enshrouded in deadly flame!"] = "Enshrouded in deadly flame!",
	["Pyrobane ignites you!"] = "Pyrobane ignites you!",
	-- Cast.
	["Flame Wave"] = "Flame Wave",
	-- Bar and messages.
	["Fire Bomb"] = "Fire\nBomb",
	["Frost Bomb"] = "Frost\nBomb",
	["BOMBS"] = "BOMBS",
	["BOMBS UP !"] = "BOMBS UP !",
	["Bomb Explosion"] = "Bomb Explosion",
	["ICE TOMB"] = "ICE TOMB",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	["Hydroflux"] = "Hydroflux",
	["Pyrobane"] = "Pyromagnus",
	["Ice Tomb"] = "Tombeau de glace",
	-- Datachron messages.
	-- NPCSay messages.
	["Burning mortals... such sweet agony..."] = "Des mortels en flammes... quelle délicieuse agonie...",
	["Run! Soon my fires will destroy you..."] = "Fuyez ! Bientôt mes flammes vous détruiront...",
	["Ah! The smell of seared flesh..."] = "Ah ! La douce odeur de la chair carbonisée...",
	["Enshrouded in deadly flame!"] = "Drapés dans un voile de flammes meutrières !",
	["Pyrobane ignites you!"] = "Pyromagnus vous enflamme",
	-- Cast.
	["Flame Wave"] = "Vague de feu",
	-- Bar and messages.
	["Fire Bomb"] = "Feu",
	["Frost Bomb"] = "Givre",
	["BOMBS"] = "BOMBES",
--	["BOMBS UP !"] = "BOMBS UP !",	-- TODO: French translation missing !!!!
	["Bomb Explosion"] = "Bomb Explosion",
	["ICE TOMB"] = "Tombeau de Glace",
})
mod:RegisterGermanLocale({
	-- Unit names.
	["Hydroflux"] = "Hydroflux",
	["Pyrobane"] = "Pyroman",
	["Ice Tomb"] = "Eisgrab",
	-- Datachron messages.
	-- NPCSay messages.
--	["Burning mortals... such sweet agony..."] = "Burning mortals... such sweet agony...",	-- TODO: German translation missing !!!!
--	["Run! Soon my fires will destroy you..."] = "Run! Soon my fires will destroy you...",	-- TODO: German translation missing !!!!
--	["Ah! The smell of seared flesh..."] = "Ah! The smell of seared flesh...",	-- TODO: German translation missing !!!!
--	["Enshrouded in deadly flame!"] = "Enshrouded in deadly flame!",	-- TODO: German translation missing !!!!
--	["Pyrobane ignites you!"] = "Pyrobane ignites you!",	-- TODO: German translation missing !!!!
	-- Cast.
	["Flame Wave"] = "Flammenwelle",
	-- Bar and messages.
--	["Fire Bomb"] = "Fire\nBomb",	-- TODO: German translation missing !!!!
--	["Frost Bomb"] = "Frost\nBomb",	-- TODO: German translation missing !!!!
--	["BOMBS"] = "BOMBS",	-- TODO: German translation missing !!!!
--	["BOMBS UP !"] = "BOMBS UP !",	-- TODO: German translation missing !!!!
	["Bomb Explosion"] = "Bomb Explosion",
--	["ICE TOMB"] = "ICE TOMB",	-- TODO: German translation missing !!!!
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
	Apollo.RegisterEventHandler("CHAT_NPCSAY", "OnChatNPCSay", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", "OnDebuffAppliedDose", self)
	Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
	Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--
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
		if mod:GetSetting("OtherBombPlayerMarkers") then
			core:MarkUnit(unit, nil, self.L["Fire Bomb"])
		end
		--core:AddPixie(unit:GetId() .. "_BOMB", 2, unit, nil, "Red", 7, 10, 0, 50)
		core:AddUnit(unit)
		firebomb_players[unitName] = unit
		if unitName == strMyName then
			core:AddMsg("BOMB", self.L["BOMBS UP !"], 5, mod:GetSetting("SoundBomb", "RunAway"))
			if mod:GetSetting("LineBombPlayers") then
				self:ScheduleTimer("ApplyBombLines", 1, "fire")
			end
		end
		self:ScheduleTimer("RemoveBombMarker", 10, "fire", unit)
	elseif splId == DEBUFFID_FROSTBOMB then
		if mod:GetSetting("OtherBombPlayerMarkers") then
			core:MarkUnit(unit, nil, self.L["Frost Bomb"])
		end
		--core:AddPixie(unit:GetId() .. "_BOMB", 2, unit, nil, "Blue", 7, 10, 0, 50)
		core:AddUnit(unit)
		frostbomb_players[unitName] = unit
		if unitName == strMyName then
			core:AddMsg("BOMB", self.L["BOMBS UP !"], 5, mod:GetSetting("SoundBomb", "RunAway"))
			if mod:GetSetting("LineBombPlayers") then
				self:ScheduleTimer("ApplyBombLines", 1, "frost")
			end
		end
		self:ScheduleTimer("RemoveBombMarker", 10, "frost", unit)
	elseif splId == DEBUFFID_ICE_TOMB and self:GetDistanceBetweenUnits(uPlayer, unit) < 45 then -- Ice Tomb Debuff
		local unitId = unit:GetId()
		if unitId and mod:GetSetting("LineIceTomb") then
			core:AddPixie(unitId .. "_TOMB", 1, uPlayer, unit, "Blue", 5, 10, 10)
		end
	end
	if splId == DEBUFFID_FIREBOMB or splId == DEBUFFID_FROSTBOMB then
		if eventTime - prevBomb > 10 then
			prevBomb = eventTime
			core:AddBar("BEXPLODE", self.L["Bomb Explosion"], 10, mod:GetSetting("SoundBomb"))
		end
	end
end

function mod:OnUnitCreated(unit, sName)
	if sName == self.L["Ice Tomb"] then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 13 then
			prev = timeOfEvent
			core:AddMsg("TOMB", self.L["ICE TOMB"], 5, mod:GetSetting("SoundIceTomb", "Alert"), "Blue")
			core:AddBar("TOMB", self.L["ICE TOMB"], 15)
		end
		core:AddUnit(unit)
	elseif sName == self.L["Flame Wave"] and mod:GetSetting("LineFlameWaves") then
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
			core:AddMsg("STACK", msgString, 5, mod:GetSetting("SoundHighDebuffStacks", "Beware"))
		end
	end
end

function mod:OnChatNPCSay(message)
	if message:find(self.L["Burning mortals... such sweet agony..."])
	or message:find(self.L["Run! Soon my fires will destroy you..."])
	or message:find(self.L["Ah! The smell of seared flesh..."])
	or message:find(self.L["Enshrouded in deadly flame!"])
	or message:find(self.L["Pyrobane ignites you!"]) then
		core:AddBar("BOMBS", self.L["BOMBS"], 30)
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Hydroflux"] then
			core:AddUnit(unit)
			local unitId = unit:GetId()
			if unitId and mod:GetSetting("LineCleaveHydroflux") then
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
