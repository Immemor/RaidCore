--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("DSFireWing", 52)
if not mod then return end

mod:RegisterEnableMob("Warmonger Agratha", "Warmonger Talarii", "Grand Warmonger Tar'gresh")

--------------------------------------------------------------------------------
-- Locals
--

local prev, first = 0, true
local boss

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
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
	if unitName == "Warmonger Agratha" and (health == 67 or health == 34) then
		core:AddMsg("ELEMENTALS", "ELEMENTALS SOON", 5, "Info")
	elseif unitName == "Warmonger Talarii" and (health == 67 or health == 34) then
		core:AddMsg("ELEMENTALS", "ELEMENTALS SOON", 5, "Info")
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Warmonger Talarii" and castName == "Incineration" then
		core:AddMsg("KNOCK", "INTERRUPT !", 5, "Alert")
		core:AddBar("KNOCK", "KNOCKBACK", 29)
	elseif unitName == "Warmonger Agratha" and castName == "Conjure Fire Elementals" then
		core:AddMsg("ELEMENTALS", "ELEMENTALS", 5, "Alert")
		core:AddBar("1STAB", "FIRST ABILITY", 15)
		core:AddBar("2DNAB", "SECOND ABILITY", 24)
	elseif unitName == "Warmonger Talarii" and castName == "Conjure Fire Elementals" then
		core:AddMsg("ELEMENTALS", "ELEMENTALS", 5, "Alert")
		core:AddBar("1STAB", "FIRST ABILITY", 15)
		core:AddBar("2DNAB", "SECOND ABILITY", 24)
	elseif unitName == "Grand Warmonger Tar'gresh" and castName == "Meteor Storm" then
		core:AddMsg("STORM", "STORM !!", 5, "RunAway")
		core:AddBar("STORM", "METEOR STORM", 43, 1)
	end
end


function mod:OnDebuffApplied(unitName, splId, unit)
	if splId == 49485 then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 10 then
			first = false
			core:AddBar("AIDS", "AIDS", (boss == "Warmonger Agratha") and 20 or 18, 1)
		end
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Warmonger Agratha" then
			self:Start()
			prev, first = 0, true
			boss = sName
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("BOMB", "BOMB", 23)
		elseif sName == "Warmonger Talarii" then
			self:Start()
			prev = 0
			boss = sName
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("KNOCK", "KNOCKBACK", 23)
		elseif sName == "Grand Warmonger Tar'gresh" then
			self:Start()
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			core:AddBar("STORM", "METEOR STORM", 26, 1)
		end
	end
end
