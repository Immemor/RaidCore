--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpEarthLogic", 52)
if not mod then return end

--mod:RegisterEnableMob("Megalith")
mod:RegisterEnableBossPair("Megalith", "Mnemesis")
mod:RegisterRestrictZone("EpEarthLogic", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Megalith"] = "Megalith",
	["Mnemesis"] = "Mnemesis",
	["Obsidian Outcropping"] = "Obsidian Outcropping",
	["Crystalline Matrix"] = "Crystalline Matrix",
	-- Datachron messages.
	["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith",
	["Logic creates powerful data caches"] = "Logic creates powerful data caches",
	-- Cast.
	["Defragment"] = "Defragment",
	-- Bar and messages.
	["SNAKE ON %s"] = "SNAKE ON %s",
	["DEFRAG"] = "DEFRAG",
	["SPREAD"] = "SPREAD",
	["BOOM"] = "BOOM",
	["JUMP !"] = "JUMP !",
	["STARS"] = "STARS%s"
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
local pilarCount = 0

local spreadPos = {
	{x = -14349, y = -551.18, z = 17916 },
	{x = -14339, y = -551.18, z = 17916 },
	{x = -14329, y = -551.18, z = 17916 },
	{x = -14319, y = -551.18, z = 17916 },
	{x = -14309, y = -551.18, z = 17916 },
	{x = -14299, y = -551.18, z = 17916 },
	{x = -14289, y = -551.18, z = 17916 },
	{x = -14279, y = -551.18, z = 17916 },
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	--Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit, sName)
	local sName = unit:GetName()
	--Print(sName)
	if sName == self.L["Obsidian Outcropping"] then
		--core:AddLine(unit:GetId(), 1, GameLib.GetPlayerUnit(), unit, 3)
		core:AddPixie(unit:GetId().."_1", 1, GameLib.GetPlayerUnit(), unit, "Blue", 10)
	end
end

function mod:OnUnitDestroyed(unit, sName)
	if sName == self.L["Obsidian Outcropping"] then
		core:DropPixie(unit:GetId())
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Mnemesis"] and castName == self.L["Defragment"] then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 10 then
			prev = timeOfEvent
			core:AddMsg("DEFRAG", self.L["SPREAD"], 5, "Alarm")
			core:AddBar("BOOM", self.L["BOOM"], 9)
			core:AddBar("DEFRAG", self.L["DEFRAG"], 40)
		end
	end
end

function mod:OnChatDC(message)
	if message:find(self.L["The ground shudders beneath Megalith"]) then
		core:AddMsg("QUAKE", self.L["JUMP !"], 3, "Beware")
	elseif message:find(self.L["Logic creates powerful data caches"]) then
		core:AddMsg("STAR", self.L["STARS"]:format(" !"), 5, "Alert")
		core:AddBar("STAR", self.L["STARS"]:format(""), 60)
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	if splId == 74570 then
		--local timeOfEvent = GameLib.GetGameTime()
		--if timeOfEvent - prev > 10 then
		--	first = false
		if unitName == GameLib.GetPlayerUnit():GetName() then
			core:AddMsg("SNAKE", self.L["SNAKE ON %s"]:format(unitName), 5, "RunAway", "Blue")
		end
		core:AddBar("SNAKE", self.L["SNAKE ON %s"]:format(unitName), 20)
		--end
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Megalith"] then
			core:AddUnit(unit)
		elseif sName == self.L["Mnemesis"] then
			self:Start()
			prev = 0
			pilarCount = 0
			core:AddBar("DEFRAG", self.L["DEFRAG"], 10)
			core:AddBar("STAR", self.L["STARS"]:format(""), 60)
			core:AddUnit(unit)
			core:WatchUnit(unit)
			--core:UnitDebuff(GameLib.GetPlayerUnit())
			core:RaidDebuff()
			Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
			core:StartScan()
		elseif sName == self.L["Crystalline Matrix"] then
			pilarCount = pilarCount + 1
			--core:MarkUnit(unit)
			--core:AddUnit(unit)
			--core:AddMsg("PILAR", ("[%s] PILAR"):format(pilarCount), 5, "Info", "Blue")
		end
	elseif unit:GetType() == "NonPlayer" and not bInCombat then
		if sName == self.L["Mnemesis"] then
			Apollo.RemoveEventHandler("RC_UnitCreated", self)
			core:ResetLines()
		end
	end
end

function mod:PlaceSpawnPos()
	for k,v in pairs(spreadPos) do
		core:SetWorldMarker(v, k)
	end
end
