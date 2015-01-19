--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpAirLife", 52)
if not mod then return end

mod:RegisterEnableMob("Aileron")
mod:RegisterRestrictZone("Elemental Vortex Delta")

-- Tracking Blinding Light and Aileron knockback seems too random to display on timers.

--------------------------------------------------------------------------------
-- Locals
--

local last_thorns = 0
local last_twirl = 0
local midphase = false
local myName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", self)
	--Apollo.RegisterEventHandler("SPELL_CAST_END", 	"OnSpellCastEnd", self)
	--Apollo.RegisterEventHandler("CHAT_DATACHRON", 	"OnChatDC", self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--

local function dist2unit(unitSource, unitTarget)
	if not unitSource or not unitTarget then return 999 end
	local sPos = unitSource:GetPosition()
	local tPos = unitTarget:GetPosition()

	local sVec = Vector3.New(sPos.x, sPos.y, sPos.z)
	local tVec = Vector3.New(tPos.x, tPos.y, tPos.z)

	local dist = (tVec - sVec):Length()

	return tonumber(dist)
end

function mod:OnReset()
	last_thorns = 0
	last_twirl = 0
	midphase = false
	core:StopBar("THORN")
	core:StopBar("MIDEND")
	core:StopBar("MIDPHASE")
	core:StopBar("TWIRL")
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()
	if sName == "Wild Brambles" and eventTime > last_thorns + 1 and eventTime + 16 < midphase_start then
		last_thorns = eventTime
		core:AddBar("THORN", "Thorns", 15)
		--Print(eventTime .. " - " .. sName)
	elseif not midphase and sName == "[DS] e395 - Air - Tornado" then
		midphase = true
		midphase_start = eventTime + 115
		core:AddBar("MIDEND", "Midphase ending", 35)
		core:AddBar("THORN", "Thorns", 35)
		core:AddBar("TWIRL", "Twirl", 37)

		--Print(eventTime .. " Midphase STARTED")
	elseif sName == "Life Force" then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 10, -40, 0)
	end
	--Print(eventTime .. " - " .. sName)
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()
	--Print(sName)
	if midphase and sName == "[DS] e395 - Air - Tornado" then
		midphase = false
		core:AddBar("MIDPHASE", "Middle Phase", 80, true)
		--Print(eventTime .. " Midphase ENDED")
	elseif sName == "Life Force" then
		core:DropPixie(unit:GetId())
	end	
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	local splName = GameLib.GetSpell(splId):GetName()
	--Print(eventTime .. " debuff applied on unit: " .. unitName .. " - " .. splId)
	if unitName == myName then
		if splId == 70440 then -- Twirl
			core:AddMsg("TWIRL", "TWIRL ON YOU!", 5, "Inferno")
		end
	end
	if splName == "Twirl" and eventTime > last_twirl + 1 and eventTime + 16 < midphase_start then
		--Print(eventTime .. " TWIRL ON " .. unitName .. " - splId: " .. splId)
		last_twirl = eventTime
		core:AddBar("TWIRL", "Twirl", 15)
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == "Visceralus" and castName == "Blinding Light" then
		local playerUnit = GameLib.GetPlayerUnit()
		if dist2unit(unit, playerUnit) < 33 then
			core:AddMsg("BLIND", "Blinding Light", 5, "Beware")
		end
	end
	--Print(eventTime .. " " .. unitName .. " is casting " .. castName)
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		local eventTime = GameLib.GetGameTime()
		local playerUnit = GameLib.GetPlayerUnit()
		myName = playerUnit:GetName()

		if sName == "Aileron" then
			core:AddUnit(unit)
		elseif sName == "Visceralus" then
			self:Start()
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:RaidDebuff()
			core:StartScan()

			last_thorns = 0
			last_twirl = 0
			midphase = false
			midphase_start = eventTime + 80

			core:AddBar("MIDPHASE", "Middle Phase", 80, true)
			core:AddBar("THORN", "Thorns", 20)
			core:AddBar("TWIRL", "Twirl", 22)

			--Print(eventTime .. " " .. sName .. " FIGHT STARTED ")
		end
	end
end
