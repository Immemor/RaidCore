--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("DSLogicWing", 52)
if not mod then return end

mod:RegisterEnableMob("Hyper-Accelerated Skeledroid", "Augmented Herald of Avatus", "Abstract Augmentation Algorithm")

--------------------------------------------------------------------------------
-- Locals
--

local prevInt = ""
local castCount = 0
local nbKick = 28


--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", 	self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 			"OnDebuffApplied", 			self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", 			"OnDebuffApplied", 			self)	
	Apollo.RegisterEventHandler("UNIT_HEALTH", 			"OnHealthChanged", 		self)
	--Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--
function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Conjured Fire Bomb" then
		core:AddMsg("BOMB", "BOMB", 5, "Long", "Blue")
		core:AddBar("BOMB", "BOMB", first and 20 or 23)
	end
end


function mod:OnHealthChanged(unitName, health)
	if unitName == "Augmented Herald of Avatus" and health == 25 then
		core:AddMsg("SIPHON", "HEAL SOON", 5, "Info")
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Augmented Herald of Avatus" and castName == "Cube Smash" then
		core:AddBar("CUBE", "CUBE SMASH", 17)	
	elseif unitName == "Abstract Augmentation Algorithm" and castName == "Data Deconstruction" then
		castCount = castCount + 1
		core:AddMsg("DATA", ("[%s] INTERRUPT"):format(castCount), 3, "Long", "Blue")
		core:AddBar("DATA", ("[%s] INTERRUPT"):format(castCount), 7)
	end
end

function mod:OnChatDC(message)
	if message:find("The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit") then
		core:AddMsg("EMPOWER", "EMPOWER !!", 5, "Alert")
		core:AddBar("EMPOWER", "EMPOWER", 30, 1)		
	end
end



function mod:OnDebuffApplied(unitName, splId)
	if splId == 72559 and prevInt ~= unitName then
		--local timeOfEvent = GameLib.GetGameTime()
		--if timeOfEvent - prev > 10 then
			--first = false
		Print(("[%s] %s"):format(castCount, unitName))
		prevInt = unitName
		castCount = castCount + 1
		if castCount > nbKick then castCount = 1 end
		--core:AddMsg("DATA", ("[%s] INTERRUPT"):format(castCount), 3, "Long", "Blue")
		core:AddBar("DATA", ("[%s] INTERRUPT"):format(castCount), 7)
		--end
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Abstract Augmentation Algorithm" then
			self:Start()
			prevInt = ""
			castCount = 1
			core:AddUnit(unit)
			--core:WatchUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("DATA", ("[%s] INTERRUPT"):format(castCount), 7)
			core:AddBar("EMPOWER", "EMPOWER", 30, 1)
		elseif sName == "Quantum Processing Unit" then
			self:Start()
			core:AddUnit(unit)
			core:MarkUnit(unit)
		elseif sName == "Hyper-Accelerated Skeledroid" then
			self:Start()
			core:AddUnit(unit)
			core:AddBar("BERSERK", "BERSERK", 180, 1)
		elseif sName == "Augmented Herald of Avatus" then
			self:Start()
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			core:AddBar("CUBE", "CUBE SMASH", 8)							
		end
	end
end
