--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("PhageCouncil", 67)
if not mod then return end

mod:RegisterEnableMob("Golgox the Lifecrusher", "Terax Blightweaver", "Ersoth Curseform", "Noxmind the Insidious", "Fleshmonger Vratorg")
mod:RegisterRestrictZone("PhageCouncil", "Augmentation Core")
mod:RegisterEnableZone("PhageCouncil", "Augmentation Core")

--------------------------------------------------------------------------------
-- Locals
--

local p2Count = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Golgox the Lifecrusher" and castName == "Teleport" then
		core:AddMsg("CONVP2", "P2 : 20 IA", 5, "Alert")
		core:AddBar("CONVP2", "P2 : 20 IA", 29.5)
	elseif unitName == "Terax Blightweaver" and castName == "Teleport" then
		core:AddMsg("CONVP2", "P2 : MINI ADDS", 5, "Alert")
		core:AddBar("CONVP2", "P2 : MINI ADDS", 29.5)
	elseif unitName == "Ersoth Curseform" and castName == "Teleport" then
		core:AddMsg("CONVP2", "P2 : SUBDUE", 5, "Alert")
		core:AddBar("CONVP2", "P2 : SUBDUE", 29.5)
	elseif unitName == "Noxmind the Insidious" and castName == "Teleport" then
		core:AddMsg("CONVP2", "P2 : PILLARS", 5, "Alert")
		core:AddBar("CONVP2", "P2 : PILLARS", 29.5)
	elseif unitName == "Fleshmonger Vratorg" and castName == "Teleport" then
		core:AddMsg("CONVP2", "P2 : SHIELD", 5, "Alert")
		core:AddBar("CONVP2", "P2 : SHIELD", 29.5)
	end
end

function mod:OnSpellCastEnd(unitName, castName)
	if castName == "Channeling Energy" then
		core:StopScan()
		core:StopBar("CONVP2")
		core:AddBar("CONVP1", ("[%s] NEXT P2"):format(p2Count + 1), 60, 1)
	end
end

function mod:OnChatDC(message)
	if message:find("The Phageborn Convergence begins gathering its power") then
		p2Count = p2Count + 1
		core:StartScan()
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Golgox the Lifecrusher" or sName == "Terax Blightweaver"  or sName == "Ersoth Curseform" or sName == "Noxmind the Insidious" or sName == "Fleshmonger Vratorg" then
			self:Start()
			p2Count = 0
			core:AddBar("CONVP1", ("[%s] NEXT P2"):format(p2Count + 1), 90, 1)
			core:AddUnit(unit)
			core:WatchUnit(unit)
		end
	end
end
