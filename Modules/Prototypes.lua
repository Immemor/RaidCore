--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Prototypes", 67)
if not mod then return end

mod:RegisterEnableMob("Phagetech Commander", "Phagetech Augmentor", "Phagetech Protector", "Phagetech Fabricator", "Phagentech-Kommandant", "Phagentech-Augmentor", "Phagentech-Protektor", "Phagentech-Fabrikant")
mod:RegisterRestrictZone("Prototypes", "Phagetech Uplink Hub", "Phagentech-Uplink-Zentrale")
mod:RegisterEnableZone("Prototypes", "Phagetech Uplink Hub", "Phagentech-Uplink-Zentrale")

--------------------------------------------------------------------------------
-- Locals
--
 
local protoFirst = true
local locale = core:GetLocale()
local msgStrings = {
	["enUS"] = {
		moduleName = "Module %s loaded",
		unitNameAugmentor = "Phagetech Augmentor",
		unitNameFabricator = "Phagetech Fabricator",
		unitNameCommander = "Phagetech Commander",
		repairbotCast = "Summon Repairbot",
		reparibotWarn = "Repairbot!",
		destructobotCast = "Summon Destructobot",
		destructobotWarn = "Destructobot!",
		commanderMsg = "Phagetech Commander is now active!",
		commanderBar = "[2] TP + CROIX + BOTS",
		berserkBar = "BERSERK",
		augmentorMsg = "Phagetech Augmentor is now active!",
		augmentorBar = "[3] SINGULARITY + VAGUE",
		protectorMsg = "Phagetech Protector is now active!",
		protectorBar1 = "Singularity",
		protectorBar2 = "[4] SOAK + BOTS",
		fabricatorMsg = "Phagetech Fabricator is now active!",
		fabricatorBar = "[1] LINK + KICK",
	},
	["deDE"] = {
		moduleName = "Modul %s geladen",
		unitNameAugmentor = "Phagentech-Augmentor",
		unitNameFabricator = "Phagentech-Fabrikant",
		unitNameCommander = "Phagentech-Kommandant",
		repairbotCast = "Reparaturbot herbeirufen",
		reparibotWarn = "REPERATURBOTS !!!",
		destructobotCast = "Destruktobot herbeirufen",
		destructobotWarn = "DESTRUKTUBOTS !!!",
		commanderMsg = "Phagentech-Kommandant ist jetzt aktiv",
		commanderBar = "[2] FARBEN + KREUZ + REPARATURBOTS",
		berserkBar = "BERSERK",
		augmentorMsg = "Phagentech-Augmentor ist jetzt aktiv",
		augmentorBar = "[3] SINGULARITÄT + WELLEN",
		protectorMsg = "Phagentech-Protektor ist jetzt aktiv",
		protectorBar1 = "SINGULARITÄT",
		protectorBar2 = "[4] KREISE + DESTRUKTOBOTS",
		fabricatorMsg = "Phagentech-Fabrikant ist jetzt aktiv",
		fabricatorBar = "[1] VERBINDUNG + KICK",
	},
}
 
--------------------------------------------------------------------------------
-- Initialization
--
 
function mod:OnBossEnable()
	Print((msgStrings[locale]["moduleName"]):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", 	self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 				self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 				"OnReset", self)
end
 
 
--------------------------------------------------------------------------------
-- Event Handlers
--
 
 
function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == msgStrings[locale]["unitNameAugmentor"] and castName == msgStrings[locale]["repairbotCast"] then
		core:AddMsg("BOTS", msgStrings[locale]["reparibotWarn"], 5, "Alert")
	elseif unitName == msgStrings[locale]["unitNameFabricator"] and castName == msgStrings[locale]["destructobotCast"] then
		core:AddMsg("BOTS", msgStrings[locale]["destructobotWarn"], 5, "Alert")
	end
end
 
function mod:OnChatDC(message)
	if message:find(msgStrings[locale]["commanderMsg"]) then
		core:AddBar("PROTO", msgStrings[locale]["commanderBar"], protoFirst and 20 or 60)
		if protoFirst then 
			protoFirst = nil
			core:AddBar("BERSERK", msgStrings[locale]["berserkBar"], 585)
		end
	elseif message:find(msgStrings[locale]["augmentorMsg"]) then
		core:AddBar("PROTO", msgStrings[locale]["augmentorBar"], 60)
	elseif message:find(msgStrings[locale]["protectorMsg"]) then
		core:AddBar("SINGU", msgStrings[locale]["protectorBar1"], 5)
		core:AddBar("PROTO", msgStrings[locale]["protectorBar2"], 60)
	elseif message:find(msgStrings[locale]["fabricatorMsg"]) then
		core:AddBar("PROTO", msgStrings[locale]["fabricatorBar"], 60)
	end
end
 
function mod:OnReset()
	protoFirst = true
end
 
function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == msgStrings[locale]["unitNameCommander"] then
			self:Start()
		elseif sName == msgStrings[locale]["unitNameAugmentor"] or sName == msgStrings[locale]["unitNameFabricator"] then
			core:WatchUnit(unit)
			core:StartScan()
		end
	end
end
