--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpFrostAir", 52)
if not mod then return end

mod:RegisterEnableMob("Hydroflux")

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local mooCount = 0
local phase2 = false


--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	--Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
	Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self)	
end


--------------------------------------------------------------------------------
-- Event Handlers
--


function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Landing Volume" then
		core:MarkUnit(unit, 0, "LAND")
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Wind Wall" then
		core:DropLine(unit:GetId().."_1")
		core:DropLine(unit:GetId().."_2")
	end	
end


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Hydroflux" and castName == "Tsunami" then
		phase2 = true
		mooCount = mooCount + 1
		core:AddMsg("PHASE2", "TSUNAMI", 5, "Alert")
	elseif unitName == "Hydroflux" and castName == "Glacial Icestorm" then
		core:AddMsg("ICESTORM", "ICESTORM", 5, "RunAway")
	end
end


function mod:OnChatDC(message)
	if message:find("Hydroflux evaporates") then
		--core:AddMsg("PHASE1", "MOO !", 5, "Info", "Blue")
		core:AddBar("PHASE2", "EYE OF THE STORM", 45, 1)
	elseif message:find("Aileron dissipates with a flurry") then
		core:AddBar("PHASE2", "TSUNAMI", 45, 1)
	elseif message:find("The wind starts to blow faster and faster") then
		phase2 = true
		mooCount = mooCount + 1
		core:AddMsg("PHASE2", "EYE OF THE STORM", 5, "Alert")
	end
end

function mod:OnBuffApplied(unitName, splId, unit)
	if phase2 and (splId == 69959 or splId == 47075) then
		phase2 = false
		core:AddMsg("MOO", "MOO !", 5, "Info", "Blue")
		core:AddBar("MOO", "MOO PHASE", 10, 1)
		if mooCount == 2 then
			mooCount = 0
			core:AddBar("ICESTORM", "ICESTORM", 15)
		end
	end
end


function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Hydroflux" then
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:UnitBuff(unit)
		elseif sName == "Aileron" then
			self:Start()
			mooCount = 0
			phase2 = false
			core:AddUnit(unit)
			core:UnitBuff(unit)
			core:StartScan()
			self:Start()						
		end
	end
end
