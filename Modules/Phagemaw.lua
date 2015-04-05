--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("PhageMaw", 67)
if not mod then return end

mod:RegisterEnableMob("Phage Maw")
mod:RegisterRestrictZone("PhageMaw", "Experimentation Lab CX-33")
mod:RegisterEnableZone("PhageMaw", "Experimentation Lab CX-33")

--------------------------------------------------------------------------------
-- Locals
--

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStateChanged", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Detonation Bomb" then
		core:MarkUnit(unit, 1)
		core:AddUnit(unit)
	end
end

function mod:OnChatDC(message)
	if message:find("The augmented shield has been destroyed") then
		core:AddBar("MAW1", "Bomb 1", 20)
		core:AddBar("MAW2", "Bomb 2", 49)
		core:AddBar("MAW3", "Bomb 3", 78)
		core:AddBar("PHAGEMAW", "BOOOM !", 104, 1)
	elseif message:find("Phage Maw begins charging an orbital strike") then
		core:ResetMarks()
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Phage Maw" then
			self:Start()
			core:AddUnit(unit)
		end
	end
end
