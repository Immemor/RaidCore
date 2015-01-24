local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Avatus", 52)
if not mod then return end

mod:RegisterRestrictZone("Avatus", "The Oculus")
mod:RegisterEnableMob("Avatus")

local phase2warn, phase2 = false, false
local phase_blueroom = false
local encounter_started = false
local gungrid_time = nil
-- 40man: first after 46sec - 20m: first after 20sec, after that every 112 sec
local gungrid_timer = 46
-- 40man: first after 93sec, after that every 37 sec. - 20m: first after 69sec, after that every 37 sec
local obliteration_beam_timer = 93
local holo_hands = {}

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
	encounter_started = false
	holo_hands = {}
end

function mod:OnUnitCreated(unit)
	local eventTime = GameLib.GetGameTime()

	local sName = unit:GetName()
	--Print(eventTime .. " " .. sName .. " spawned")
	if sName == "Avatus" then
		core:AddUnit(unit)
	elseif sName == "Holo Hand" then
		--Print(eventTime .. " Holo hand Spawned")
		local unitId = unit:GetId()
		core:AddUnit(unit)
		core:WatchUnit(unit)
		table.insert(holo_hands, unitId, {["unit"] = unit})
		core:AddMsg("HHAND", "Holo Hand Spawned", 5, "Info")
	elseif sName == "Mobius Physics Constructor" then
		core:AddUnit(unit)
	end
	--[[if sName == "Infinite Logic Loop" then
		core:AddUnit(unit)
		core:UnitBuff(unit)
		phase2_blueroom = true
	end--]]

end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	local unitId = unit:GetId()

	if sName == "Holo Hand" and holo_hands[unitId] then
		holo_hands[unitId] = nil
		--Print("Removed destroyed holo hand from holo_hands list")
	end
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

		--Print(eventTime .. " " .. unitName .. " has a buff: " .. strSpellName .. " with SplId: " .. splId)
	end
end

function mod:OnHealthChanged(unitName, health)
	if unitName == "Avatus" and health >= 75 and health <= 80 and not phase2warn then
		phase2warn = true
		core:AddMsg("AVAP2", "P2 SOON !", 5, "Info")
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == "Avatus" and castName == "Obliteration Beam" then
		core:AddMsg("BEAMS", "GO TO SIDES !", 5, "RunAway")
		core:StopBar("OBBEAM")
		-- check if next ob beam in {obliteration_beam_timer} sec doesn't happen during a gungrid which takes 20 sec
		if gungrid_time + gungrid_timer + 20 < eventTime + obliteration_beam_timer then
			core:AddBar("OBBEAM", "Obliteration Beam", obliteration_beam_timer, true)
		end
	elseif unitName == "Holo Hand" and castName == "Crushing Blow" then
		local playerUnit = GameLib.GetPlayerUnit()
		for _, hand in pairs(holo_hands) do
			local distance_to_hand = dist2unit(playerUnit, hand["unit"])
			hand["distance"] = distance_to_hand
		end

		local closest_holo_hand = holo_hands[next(holo_hands)]
		for _, hand in pairs(holo_hands) do
			if hand["distance"] < closest_holo_hand["distance"] then
				closest_holo_hand = hand
			end
		end
		if closest_holo_hand["unit"]:GetCastName() == "Crushing Blow" then
			core:AddMsg("CRBLOW", "INTERRUPT CRUSHING BLOW!", 5, "Inferno")
		end
	end

	--Print(eventTime .. " " .. unitName .. " is casting " .. castName)
end

function mod:OnChatDC(message)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " ChatDC Message: " .. message)
	if message:find("Gun Grid Activated") then
		gungrid_time = eventTime
		core:AddMsg("GGRIDMSG", "Gun Grid NOW!", 5, "Beware")
		core:StopBar("GGRID")
		core:AddBar("GGRID", "Gun Grid", gungrid_timer, true)
	end
	if message:find("Portals have opened!") then
		phase2 = true
		core:StopBar("GGRID")
		core:StopBar("OBBEAM")
		core:StopBar("HHAND")
	end
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()

		if sName == "Avatus" and not encounter_started then
			local eventTime = GameLib.GetGameTime()
			self:Start()
			encounter_started = true
			phase2warn, phase2 = false, false
			phase2_blueroom = false
			gungrid_time = eventTime + gungrid_timer
			holo_hands = {}
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()
			--Print(eventTime .. " " .. sName .. " FIGHT STARTED ")
			core:AddBar("OBBEAM", "Obliteration Beam", obliteration_beam_timer, true)
			core:AddBar("GGRID", "Gun Grid", gungrid_timer, true)
			core:AddBar("HHAND", "Holo Hands spawn", 43)
			gungrid_timer = 112
			obliteration_beam_timer = 37
		end
	end
end
