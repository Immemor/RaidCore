--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("PhageMaw", 67)
if not mod then return end

mod:RegisterEnableMob("Phage Maw", "Phagenschlund")
mod:RegisterRestrictZone("PhageMaw", "Experimentation Lab CX-33", "Experimentierlabor CX-33")
mod:RegisterEnableZone("PhageMaw", "Experimentation Lab CX-33", "Experimentierlabor CX-33")

--------------------------------------------------------------------------------
-- Locals
--

local locale = core:GetLocale()
local msgStrings = {
	["enUS"] = {
		moduleName = "Module %s loaded",
		unitName = "Phage Maw",
		bombName = "Detonation Bomb",
		shieldMsg = "The augmented shield has been destroyed",
		mawBar1 = "Bomb 1",
		mawBar2 = "Bomb 2",
		mawBar3 = "Bomb 3",
		boomBar = "BOOOM !",
		orbitalStrikeMsg = "Phage Maw begins charging an orbital strike",		
	},
	["deDE"] = {
		moduleName = "Modul %s geladen",
		unitName = "Phagenschlund",
		bombName = "Sprengbombe",
		shieldMsg = "Der augmentierte Schild wurde zerstört",
		mawBar1 = "Bombe 1",
		mawBar2 = "Bombe 2",
		mawBar3 = "Bombe 3",
		boomBar = "BOOOM !",
		orbitalStrikeMsg = "Phagenschlund beginnt einen Orbitalschlag aufzuladen",
	},
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print((msgStrings[locale]["moduleName"]):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 				self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--


function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == msgStrings[locale]["bombName"] then
		core:MarkUnit(unit, 1)
		core:AddUnit(unit)
	end
end


function mod:OnChatDC(message)
	if message:find(msgStrings[locale]["shieldMsg"]) then
		core:AddBar("MAW1", msgStrings[locale]["mawBar1"], 20)
		core:AddBar("MAW2", msgStrings[locale]["mawBar2"], 49)
		core:AddBar("MAW3", msgStrings[locale]["mawBar3"], 78)
		core:AddBar("PHAGEMAW", msgStrings[locale]["boomBar"], 104, 1)
	elseif message:find(msgStrings[locale]["orbitalStrikeMsg"]) then
		core:ResetMarks()
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == msgStrings[locale]["unitName"] then
			self:Start()
			core:AddUnit(unit)				
		end
	end
end
