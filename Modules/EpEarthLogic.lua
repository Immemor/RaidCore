--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpEarthLogic", 52)
if not mod then return end

mod:RegisterEnableMob("Megalith")

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
	--Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 			"OnDebuffApplied", 			self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self)	
end


--------------------------------------------------------------------------------
-- Event Handlers
--


function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Obsidian Outcropping" then
		--core:AddLine(unit:GetId(), 1, GameLib.GetPlayerUnit(), unit, 3)
		core:AddPixie(unit:GetId().."_1", 1, GameLib.GetPlayerUnit(), unit, "Blue", 10)
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Obsidian Outcropping" then
		core:DropPixie(unit:GetId())
	end	
end


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Mnemesis" and castName == "Defragment" then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 10 then
			prev = timeOfEvent
			core:AddMsg("DEFRAG", "SPREAD", 5, "Alarm")
			core:AddBar("BOOM", "BOOM", 9)
			core:AddBar("DEFRAG", "DEFRAG", 40)
		end
	end
end


function mod:OnChatDC(message)
	if message:find("The ground shudders beneath Megalith") then
		core:AddMsg("QUAKE", "JUMP !", 3, "Beware")
	elseif message:find("Logic creates powerful data caches") then
		core:AddMsg("STAR", "STARS !", 5, "Alert")
		core:AddBar("STAR", "STARS", 60)
	end
end


function mod:OnDebuffApplied(unitName, splId, unit)
	if splId == 74570 then
		--local timeOfEvent = GameLib.GetGameTime()
		--if timeOfEvent - prev > 10 then
		--	first = false
		if unitName == GameLib.GetPlayerUnit():GetName() then
			core:AddMsg("SNAKE", ("SNAKE ON %s"):format(unitName), 5, "RunAway", "Blue")
		end
		core:AddBar("SNAKE", ("SNAKE ON %s"):format(unitName), 20)
		--end
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Megalith" then
			core:AddUnit(unit)
		elseif sName == "Mnemesis" then
			self:Start()
			prev = 0
			pilarCount = 0
			core:AddBar("DEFRAG", "DEFRAG", 10)
			core:AddBar("STAR", "STARS", 60)
			core:AddUnit(unit)
			core:WatchUnit(unit)
			--core:UnitDebuff(GameLib.GetPlayerUnit())
			core:RaidDebuff()
			Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
			core:StartScan()
		elseif sName == "Crystalline Matrix" then
			pilarCount = pilarCount + 1
			--core:MarkUnit(unit)
			--core:AddUnit(unit)
			--core:AddMsg("PILAR", ("[%s] PILAR"):format(pilarCount), 5, "Info", "Blue")				
		end
	elseif unit:GetType() == "NonPlayer" and not bInCombat then
		local sName = unit:GetName()
		if sName == "Mnemesis" then
			Apollo.RemoveEventHandler("UnitCreated", self)
			core:ResetLines()
		end
	end
end


function mod:PlaceSpawnPos()
	for k,v in pairs(spreadPos) do
		core:SetWorldMarker(v, k)
	end
end