--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpEarthAir", 52)
if not mod then return end

--mod:RegisterEnableMob("Megalith")
mod:RegisterEnableBossPair("Megalith", "Aileron")
mod:RegisterRestrictZone("EpEarthAir", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local midphase = false
local startTime


--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
	--Apollo.RegisterEventHandler("DEBUFF_APPLIED", 	"OnDebuffApplied", 			self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self)	
end


--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()
	--Print(sName)
	if sName == "Air Column" then
		core:AddLine(unit:GetId(), 2, unit, nil, 3, 30, 0, 10)
		if eventTime > startTime + 10 then
			core:StopBar("TORNADO")
			core:AddBar("TORNADO", "~Tornado Spawn", 17, true)
		end
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Air Column" then
		core:DropLine(unit:GetId())
	end	
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Megalith" and castName == "Raw Power" then	
			midphase = true
			core:AddMsg("RAW", "RAW POWER", 5, "Alert")
	elseif unitName == "Aileron" and castName == "Supercell" then
		local timeOfEvent = GameLib.GetGameTime()
		if timeOfEvent - prev > 30 then
			prev = timeOfEvent
			core:AddMsg("CELL", "SUPERCELL", 5, "Alarm")
			core:AddBar("CELL", "SUPERCELL", 80)
		end
	end
end


function mod:OnChatDC(message)
	if message:find("The ground shudders beneath Megalith") then
		core:AddMsg("QUAKE", "JUMP !", 3, "Beware")
	elseif message:find("fractured crust leaves it exposed") and midphase then
		midphase = false
		core:AddMsg("MOO", "MOO !", 5, "Info", "Blue")
		core:AddBar("RAW", "RAW POWER", 60, 1)
	end
end



function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		local eventTime = GameLib.GetGameTime()
		startTime = eventTime

		if sName == "Megalith" then
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:MarkUnit(unit, nil, "EARTH")
		elseif sName == "Aileron" then
			self:Start()
			prev = 0
			midphase = false
			core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 15, 0)
			core:AddBar("SCELL", "Supercell", 65, 1)
			core:AddBar("TORNADO", "~Tornado Spawn", 16, true)
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			--Print(eventTime .. "FIGHT STARTED")
		end
	end
end
