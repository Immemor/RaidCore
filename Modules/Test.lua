local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Gnash", 8)
if not mod then return end

mod:RegisterEnableMob("Gnash")

function mod:OnBossEnable()
	Print("YEAHHH")
		Apollo.RegisterEventHandler("UnitCreated", 				"OnUnitCreated", self)
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--if sName == "Crimson Augmentor" then
	if sName == "Gnash" then
		core:MarkUnit(unit, 1)
		core:AddUnit(unit)
	end
end