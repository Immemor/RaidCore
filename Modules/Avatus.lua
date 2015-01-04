local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Avatus", 52)
if not mod then return end

mod:RegisterRestrictZone("Avatus", "The Oculus")
mod:RegisterEnableMob("Avatus")

local phase2warn, phase2 = false, false
local phase_blueroom = false
local encounter_started = false

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", self)
	--Apollo.RegisterEventHandler("SPELL_CAST_END", 	"OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", 			"OnHealthChanged", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", 		"OnChatDC", self)
	--Apollo.RegisterEventHandler("RAID_SYNC", 			"OnSyncRcv", self)
	--Apollo.RegisterEventHandler("SubZoneChanged", 	"OnZoneChanged", self)
	--Apollo.RegisterEventHandler("CHAT_NPCSAY", 		"OnChatNPCSay", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
	--Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self) temp disabled since not finished, TODO re-enable when doing avatus.
end

function mod:OnReset()
	encounter_started = false
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	if sName == "Avatus" then
		core:AddUnit(unit)
	end
	if sName == "Holo Hand" then
		core:AddUnit(unit)
		core:AddMsg("HHAND", "Holo Hand Spawned", 5, "Info")
	end
	if sName == "Mobius Physics Constructor" then
		core:AddUnit(unit)
	end
	--[[if sName == "Infinite Logic Loop" then
		core:AddUnit(unit)
		core:UnitBuff(unit)
		phase2_blueroom = true
	end--]]
end

function mod:OnBuffApplied(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	if phase2_blueroom and unitName == "Infinite Logic Loop" then
		local tSpell = GameLib.GetSpell(splId)
		local strSpellName
		if tSpell then
			strSpellName = tostring(tSpell:GetName())
		else
			Print("Unknown tSpell")
		end

		-- Todo change to SplId instead of name to reduce API calls
		if strSpellName == "Green Reconstruction Matrix" then
			Print(eventTime .. " " .. unitName .. " has the GREEN buff")
		elseif strSpellName == "Blue Disruption Matrix" then
			Print(eventTime .. " " .. unitName .. " has the BLUE buff")
		elseif strSpellName == "Red Empowerment Matrix" then
			Print(eventTime .. " " .. unitName .. " has the RED buff")
		end		

		Print(eventTime .. " " .. unitName .. " has a buff: " .. strSpellName .. " with SplId: " .. splId)
	end
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
end

function mod:OnHealthChanged(unitName, health)
	if unitName == "Avatus" and health >= 75 and health <= 80 and not phase2warn then
		phase2warn = true
		core:AddMsg("AVAP2", "P2 SOON !", 5, "Info")
	end
end

local function dist2unit(unitSource, unitTarget)
	if not unitSource or not unitTarget then return 999 end
	local sPos = unitSource:GetPosition()
	local tPos = unitTarget:GetPosition()

	local sVec = Vector3.New(sPos.x, sPos.y, sPos.z)
	local tVec = Vector3.New(tPos.x, tPos.y, tPos.z)

	local dist = (tVec - sVec):Length()

	return tonumber(dist)
end

function mod:OnChatNPCSay(message)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. "Message is: " .. message)
 	-- Inconsistent messages for gungrid, no point warning for that.
end

function mod:OnSpellCastEnd(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " " .. unitName .. " ended cast " .. castName)
end


function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == "Avatus" and castName == "Obliteration Beam" then
		core:AddMsg("BEAMS", "GO TO SIDES !", 5, "RunAway")
		core:StopBar("OBBEAM")
		core:AddBar("OBBEAM", "Obliteration Beam", 37)
	end
	--Print(eventTime .. " " .. unitName .. " is casting " .. castName)
end


function mod:OnZoneChanged(zoneId, zoneName)
	if zoneName == "Datascape" then
		return
	end
end


function mod:OnChatDC(message)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " ChatDC Message: " .. message)
	if message:find("Gun Grid Activated") then
		core:StopBar("GGRID")
		core:AddMsg("GGRIDMSG", "Gun Grid NOW!", 5, "Beware")
	end
	if message:find("Portals have opened!") then
		phase2 = true
		core:StopBar("GGRID")
		core:StopBar("OBBEAM")
	end
end

function mod:OnSyncRcv(sync, parameter)
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Avatus" and not encounter_started then
			self:Start()
			encounter_started = true
			phase2warn, phase2 = false, false
			phase2_blueroom = false
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			local eventTime = GameLib.GetGameTime()
			--Print(eventTime .. " " .. sName .. " FIGHT STARTED ")
			core:AddBar("OBBEAM", "Obliteration Beam", 93)
			core:AddBar("GGRID", "Gun Grid", 46)
		end
	end
end