--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("MaelstromAuthority", 52)
if not mod then return end

mod:RegisterEnableMob("Weather Control Station")

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local stationCount = 0
local bossPos = {}


--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 		"OnSpellCastStart", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--


function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Avatus Hologram" then
		self:Start()
		core:AddBar("JUMP", "JUMP", 8.5, 1)
		bossPos = {}
	elseif sName == "Wind Wall" then
		core:AddPixie(unit:GetId().."_1", 2, unit, nil, "Green", 10, 20, 0)
		core:AddPixie(unit:GetId().."_2", 2, unit, nil, "Green", 10, 20, 180)
		--core:AddLine(unit:GetId().."_1", 2, unit, nil, 1, 20, 0)
		--core:AddLine(unit:GetId().."_2", 2, unit, nil, 1, 20, 180)
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	--Print(sName)
	if sName == "Wind Wall" then
		--core:DropLine(unit:GetId().."_1")
		--core:DropLine(unit:GetId().."_2")
		core:DropPixie(unit:GetId().."_1")
		core:DropPixie(unit:GetId().."_2")
	end	
end


function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == "Maelstrom Authority" and castName == "Activate Weather Cycle" then
		bossPos = unit:GetPosition()
		stationCount = 0
		core:AddBar("STATION", ("[%s] STATION"):format(stationCount + 1), 13)
	elseif unitName == "Maelstrom Authority" and castName == "Ice Breath" then
		core:AddMsg("BREATH", "ICE BREATH", 5, "RunAway")
	elseif unitName == "Maelstrom Authority" and castName == "Crystallize" then
		core:AddMsg("BREATH", "ICE BREATH", 5, "Beware")
	elseif unitName == "Maelstrom Authority" and castName == "Typhoon" then
		core:AddMsg("BREATH", "TYPHOON", 5, "Beware")
	end
end


function mod:OnChatDC(message)
	if message:find("The platform trembles") then
		core:AddBar("JUMP", "JUMP", 7, 14)
	end
end


function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Maelstrom Authority" then
			stationCount = 0
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
		elseif sName == "Weather Station" then
			stationCount = stationCount + 1
			local posStr = ""
			local stationPos = unit:GetPosition()
			if stationPos and bossPos then
				core:AddMsg("STATION", ("[%s] STATION : %s %s"):format(stationCount, (stationPos.z > bossPos.z) and "SOUTH" or "NORTH", (stationPos.x > bossPos.x) and "EAST" or "WEST"), 5, "Info", "Blue")
			else
				core:AddMsg("STATION", ("[%s] STATION"):format(stationCount), 5, "Info", "Blue")
			end	
			core:AddBar("STATION", ("[%s] STATION"):format(stationCount + 1), 10)				
		end
	end
end
