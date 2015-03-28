--------------------------------------------------------------------------------
-- Module Declaration
-- German translation by https://github.com/Eikju
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("ExperimentX89", 67)
if not mod then return end

mod:RegisterEnableMob("Experiment X-89")
mod:RegisterRestrictZone("ExperimentX89", "Isolation Chamber", "Isolationskammer")
mod:RegisterEnableZone("ExperimentX89", "Isolation Chamber", "Isolationskammer")

--------------------------------------------------------------------------------
-- Locals
--

local playerName
local locale = core:GetLocale()
local msgStrings = {
	["enUS"] = {
		knockback = "KNOCKBACK",
		knockback_msg = "KNOCKBACK !!!",
		shockwave = "SHOCKWAVE",
		beam = "BEAM",
		small_bomb = "LITTLE BOMB",
		small_bomb_you = "LITTLE BOMB on YOU !!!",
		big_bomb = "BIG BOMB on YOU !!!",
		chatdc_big_bomb = "Experiment X-89 has placed a bomb",
		cast_shout = "Resounding Shout",
		cast_spew = "Repugnant Spew",
		cast_shockwave = "Shattering Shockwave",
	},
	["deDE"] = {
		knockback = "RÜCKSTOß",
		knockback_msg = "RÜCKSTOß !!!",
		shockwave = "SCHOCKWELLE",
		beam = "LASER",
		small_bomb = "KLEINE BOMBE",
		small_bomb_you = "KLEINE BOMBE auf DIR !!!",
		big_bomb = "GROßE BOMBE auf DIR !!!",
		chatdc_big_bomb = "Experiment X-89 hat eine Bombe auf",
		cast_shout = "Widerhallender Schrei",
		cast_spew = "Widerliches Erbrochenes",
		cast_shockwave = "Zerschmetternde Schockwelle",
	},
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", 			self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", 	self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", 		self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Experiment X-89" and castName == msgStrings[locale]["cast_shout"] then
		core:AddMsg("KNOCKBACK", msgStrings[locale]["knockback_msg"], 5, "Alert")
		core:AddBar("KNOCKBACK", msgStrings[locale]["knockback"], 23)
	elseif unitName == "Experiment X-89" and castName == msgStrings[locale]["cast_spew"] then
		core:AddMsg("BEAM", msgStrings[locale]["beam"], 5, "Alarm")
		core:AddBar("BEAM", msgStrings[locale]["beam"], 40)
	elseif unitName == "Experiment X-89" and castName == msgStrings[locale]["cast_shockwave"] then
		core:AddBar("SHOCKWAVE", msgStrings[locale]["shockwave"], 19)
	end
end

function mod:OnChatDC(message)
	if message:find(msgstrings[locale]["chatdc_big_bomb"]) then
		local pName
		if locale == "enUS" then
			pName = string.gsub(string.sub(message, 38), "!", "")
		elseif locale == "deDE" then
			pName = string.gsub(string.sub(message, 36), "platziert!", "")
		end
		if pName == playerName then
			core:AddMsg("BIGB", msgStrings[locale]["big_bomb"], 5, "Destruction", "Blue")
		end
	end
end

function mod:OnDebuffApplied(unitName, splId, unit)
	if splId == 47316 then
		core:AddMsg("LITTLEB", msgStrings[locale]["small_bomb_you"], 5, "RunAway", "Blue")
		core:AddBar("LITTLEB", msgStrings[locale]["small_bomb"], 5, 1)
	end
end


function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		if sName == "Experiment X-89" then
			self:Start()
			playerName = GameLib.GetPlayerUnit():GetName()
			core:AddUnit(unit)
			core:UnitDebuff(GameLib.GetPlayerUnit())
			core:WatchUnit(unit)
			core:StartScan()
			locale = core:GetLocale()
			core:AddBar("KNOCKBACK", msgStrings[locale]["knockback"], 6)
			core:AddBar("SHOCKWAVE", msgStrings[locale]["shockwave"], 17)
			core:AddBar("BEAM", msgStrings[locale]["beam"], 36)
		end
	end
end
