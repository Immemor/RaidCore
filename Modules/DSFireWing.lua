--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("DSFireWing", 52)
if not mod then return end

mod:RegisterEnableMob("Warmonger Agratha", "Warmonger Talarii", "Grand Warmonger Tar'gresh")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Warmonger Agratha"] = "Warmonger Agratha",
	["Warmonger Talarii"] = "Warmonger Talarii",
	["Warmonger Chuna"] = "Warmonger Chuna",
	["Grand Warmonger Tar'gresh"] = "Grand Warmonger Tar'gresh",
	["Conjured Fire Bomb"] = "Conjured Fire Bomb",
	-- Datachron messages.
	-- NPCSay messages.
	-- Cast.
	["Incineration"] = "Incineration",
	["Conjure Fire Elementals"] = "Conjure Fire Elementals",
	["Meteor Storm"] = "Meteor Storm",
	-- Bar and messages.
	["INTERRUPT !"] = "INTERRUPT !",
	["ELEMENTALS SOON"] = "ELEMENTALS SOON",
	["ELEMENTALS"] = "ELEMENTALS",
	["FIRST ABILITY"] = "FIRST ABILITY",
	["SECOND ABILITY"] = "SECOND ABILITY",
	["STORM !!"] = "STORM !!",
	["METEOR STORM"] = "METEOR STORM",
	["KNOCKBACK"] = "KNOCKBACK",
	["BOMB"] = "BOMB",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	["Warmonger Agratha"] = "Guerroyeuse Agratha",
	["Warmonger Talarii"] = "Guerroyeuse Talarii",
	["Warmonger Chuna"] = "Guerroyeuse Chuna",
	["Conjured Fire Bomb"] = "Bombe incendiaire invoquée",
	["Totem's Fire"] = "Totem de feu invoqué",
	-- Datachron messages.
	-- NPCSay messages.
	-- Cast.
	-- Bar and messages.
})
mod:RegisterGermanLocale({
	-- Unit names.
	-- Datachron messages.
	-- NPCSay messages.
	-- Cast.
	-- Bar and messages.
})

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
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--
function mod:OnUnitCreated(unit, sName)
	--Print(sName)
	if sName == self.L["Conjured Fire Bomb"] then
		core:AddMsg("BOMB", self.L["BOMB"], 5, "Long", "Blue")
		core:AddBar("BOMB", self.L["BOMB"], first and 20 or 23)
	end
end


function mod:OnHealthChanged(unitName, health)
	if unitName == self.L["Warmonger Agratha"] and (health == 67 or health == 34) then
		core:AddMsg("ELEMENTALS", self.L["ELEMENTALS SOON"], 5, "Info")
	elseif unitName == self.L["Warmonger Talarii"] and (health == 67 or health == 34) then
		core:AddMsg("ELEMENTALS", self.L["ELEMENTALS SOON"], 5, "Info")
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Warmonger Talarii"] then
		if castName == self.L["Incineration"] then
			core:AddMsg("KNOCK", self.L["INTERRUPT !"], 5, "Alert")
			core:AddBar("KNOCK", self.L["KNOCKBACK"], 29)
		elseif castName == self.L["Conjure Fire Elementals"] then
			core:AddMsg("ELEMENTALS", self.L["ELEMENTALS"], 5, "Alert")
			core:AddBar("1STAB", self.L["FIRST ABILITY"], 15)
			core:AddBar("2DNAB", self.L["SECOND ABILITY"], 24)
		end
	elseif unitName == self.L["Warmonger Agratha"] and castName == self.L["Conjure Fire Elementals"] then
		core:AddMsg("ELEMENTALS", self.L["ELEMENTALS"], 5, "Alert")
		core:AddBar("1STAB", self.L["FIRST ABILITY"], 15)
		core:AddBar("2DNAB", self.L["SECOND ABILITY"], 24)
	elseif unitName == self.L["Grand Warmonger Tar'gresh"] and castName == self.L["Meteor Storm"] then
		core:AddMsg("STORM", self.L["STORM !!"], 5, "RunAway")
		core:AddBar("STORM", self.L["METEOR STORM"], 43, 1)
	end
end


function mod:OnDebuffApplied(unitName, splId, unit)
	if splId == 49485 then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 10 then
			first = false
			core:AddBar("AIDS", "AIDS", (boss == self.L["Warmonger Agratha"]) and 20 or 18, 1)
		end
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Warmonger Agratha"] then
			self:Start()
			prev, first = 0, true
			boss = sName
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("BOMB", self.L["BOMB"], 23)
		elseif sName == self.L["Warmonger Talarii"] then
			self:Start()
			prev = 0
			boss = sName
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("KNOCK", self.L["KNOCKBACK"], 23)
		elseif sName == self.L["Grand Warmonger Tar'gresh"] then
			self:Start()
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			core:AddBar("STORM", self.L["METEOR STORM"], 26, 1)
		end
	end
end
