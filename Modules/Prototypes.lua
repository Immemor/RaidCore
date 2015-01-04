--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Prototypes", 67)
if not mod then return end

mod:RegisterEnableMob("Phagetech Commander", "Phagetech Augmentor", "Phagetech Protector", "Phagetech Fabricator")

--------------------------------------------------------------------------------
-- Locals
--

local protoFirst = true


--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", 	self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 				self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 				"OnReset", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Phagetech Augmentor" and castName == "Summon Repairbot" then
		core:AddMsg("BOTS", "BOTS !!", 5, "Alert")
	elseif unitName == "Phagetech Fabricator" and castName == "Summon Destructobot" then
		core:AddMsg("BOTS", "BOTS !!", 5, "Alert")
	end
end

function mod:OnChatDC(message)
	if message:find("Phagetech Commander is now active!") then
		core:AddBar("PROTO", "[2] TP + CROIX + BOTS", protoFirst and 20 or 60)
		if protoFirst then 
			protoFirst = nil
			core:AddBar("BERSERK", "BERSERK", 585)
		end
	elseif message:find("Phagetech Augmentor is now active!") then
		core:AddBar("PROTO", "[3] SINGULARITY + VAGUE", 60)
	elseif message:find("Phagetech Protector is now active!") then
		core:AddBar("SINGU", "Singularity", 5)
		core:AddBar("PROTO", "[4] SOAK + BOTS", 60)
	elseif message:find("Phagetech Fabricator is now active!") then
		core:AddBar("PROTO", "[1] LINK + KICK", 60)
	end
end

function mod:OnReset()
	protoFirst = true
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Phagetech Commander" then
			self:Start()
		elseif sName == "Phagetech Augmentor"  or  sName == "Phagetech Fabricator" then
			core:WatchUnit(unit)
			core:StartScan()
		end
	end
end
