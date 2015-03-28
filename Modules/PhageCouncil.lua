--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("PhageCouncil", 67)
if not mod then return end

mod:RegisterEnableMob("Golgox the Lifecrusher", "Terax Blightweaver", "Ersoth Curseform", "Noxmind the Insidious", "Fleshmonger Vratorg", "Golgox der Lebenszermalmer", "Terax Brandweber", "Ersoth Fluchform", "Noxgeist der Hinterlistige", "Fleischhändler Vratorg")
mod:RegisterRestrictZone("PhageCouncil", "Augmentation Core")
mod:RegisterEnableZone("PhageCouncil", "Augmentation Core")

--------------------------------------------------------------------------------
-- Locals
--
 
local p2Count = 0
local locale = core:GetLocale()
local msgStrings = {
	["enUS"] = {
		moduleName = "Module %s loaded",
		unitNameGolgox = "Golgox the Lifecrusher",
		unitNameTerax = "Terax Blightweaver",
		unitNameErsoth = "Ersoth Curseform",
		unitNameNoxmind = "Noxmind the Insidious",
		unitNameFleshmonger = "Fleshmonger Vratorg",
		teleportCast = "Teleport",
		iaWarn = "P2 : 20 IA",
		iaBar = "P2 : 20 IA",
		addsWarn = "P2 : MINI ADDS",
		addsBar = "P2 : MINI ADDS",
		subdueWarn = "P2 : SUBDUE",
		subdueBar = "P2 : SUBDUE",
		piliersWarn = "P2 : PILIERS",
		piliersBar = "P2 : PILIERS",
		shieldWarn = "P2 : SHIELD",
		shieldBar = "P2 : SHIELD",
		energyCast = "Channeling Energy",
		p2Bar = "[%s] NEXT P2",
		powerMsg = "The Phageborn Convergence begins gathering its power",		
	},
	["deDE"] = {
		moduleName = "Modul %s geladen",
		unitNameGolgox = "Golgox der Lebenszermalmer",
		unitNameTerax = "Terax Brandweber",
		unitNameErsoth = "Ersoth Fluchform",
		unitNameNoxmind = "Noxgeist der Hinterlistige",
		unitNameFleshmonger = "Fleischhändler Vratorg",
		teleportCast = "Teleportieren",
		iaWarn = "P2 : 20x UNTERBRECHEN",
		iaBar = "P2 : 20x UNTERBRECHEN",
		addsWarn = "P2 : MINI ADDS",
		addsBar = "P2 : MINI ADDS",
		subdueWarn = "P2 : ENTWAFFNEN",
		subdueBar = "P2 : ENTWAFFNEN",
		piliersWarn = "P2 : GENERATOREN",
		piliersBar = "P2 : GENERATOREN",
		shieldWarn = "P2 : SCHILD",
		shieldBar = "P2 : SCHILD",
		energyCast = "Energie kanalisieren",
		p2Bar = "[%s] Mittelphase",
		powerMsg = "Die Konvergenz der Phagengeborenen sammelt ihre Macht",		
	},
}
 
--------------------------------------------------------------------------------
-- Initialization
--
 
function mod:OnBossEnable()
	Print((msgStrings[locale]["moduleName"]):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", 	self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("SPELL_CAST_END", 			"OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 				self)
end
 
 
--------------------------------------------------------------------------------
-- Event Handlers
--
 
function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == msgStrings[locale]["unitNameGolgox"] and castName == msgStrings[locale]["teleportCast"] then
		core:AddMsg("CONVP2", msgStrings[locale]["iaWarn"], 5, "Alert")
		core:AddBar("CONVP2", msgStrings[locale]["iaBar"], 29.5)
	elseif unitName == msgStrings[locale]["unitNameTerax"] and castName == castName == msgStrings[locale]["teleportCast"] then
		core:AddMsg("CONVP2", msgStrings[locale]["addsWarn"], 5, "Alert")
		core:AddBar("CONVP2", msgStrings[locale]["addsBar"], 29.5)
	elseif unitName == msgStrings[locale]["unitNameErsoth"] and castName == castName == msgStrings[locale]["teleportCast"] then
		core:AddMsg("CONVP2", msgStrings[locale]["subdueWarn"], 5, "Alert")
		core:AddBar("CONVP2", msgStrings[locale]["subdueBar"], 29.5)
	elseif unitName == msgStrings[locale]["unitNameNoxmind"] and castName == castName == msgStrings[locale]["teleportCast"] then
		core:AddMsg("CONVP2", msgStrings[locale]["piliersWarn"], 5, "Alert")
		core:AddBar("CONVP2", msgStrings[locale]["piliersBar"], 29.5)
	elseif unitName == msgStrings[locale]["unitNameFleshmonger"] and castName == castName == msgStrings[locale]["teleportCast"] then
		core:AddMsg("CONVP2", msgStrings[locale]["shieldWarn"], 5, "Alert")
		core:AddBar("CONVP2", msgStrings[locale]["shieldBar"], 29.5)	
	end
end
 
function mod:OnSpellCastEnd(unitName, castName)
	if castName == msgStrings[locale]["energyCast"] then
		core:StopScan()
		core:StopBar("CONVP2")
		core:AddBar("CONVP1", (msgStrings[locale]["p2Bar"]):format(p2Count + 1), 60, 1)
	end
end
 
function mod:OnChatDC(message)
	if message:find(msgStrings[locale]["powerMsg"]) then
		p2Count = p2Count + 1
		core:StartScan()
	end
end
 
function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == msgStrings[locale]["unitNameGolgox"] or sName == msgStrings[locale]["unitNameTerax"]  or sName == msgStrings[locale]["unitNameErsoth"] or sName == msgStrings[locale]["unitNameNoxmind"] or sName == msgStrings[locale]["unitNameFleshmonger"] then
			self:Start()
			p2Count = 0
			core:AddBar("CONVP1", (msgStrings[locale]["p2Bar"]):format(p2Count + 1), 90, 1)
			core:AddUnit(unit)
			core:WatchUnit(unit)
		end
	end
end
