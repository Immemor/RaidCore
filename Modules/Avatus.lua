local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Avatus", 52)
if not mod then return end

mod:RegisterEnableMob("Avatus")
mod:RegisterRestrictZone("Avatus", "The Oculus")

local phase2warn, phase2 = false, false
local phase_blueroom = false
local phase2_blueroom_rotation = {}
local encounter_started = false
local redBuffCount, greenBuffCount, blueBuffCount = 1
local buffCountTimer = false
local gungrid_time = nil
-- 40man: first after 46sec - 20m: first after 20sec, after that every 112 sec
local gungrid_timer = 20
-- 40man: first after 93sec, after that every 37 sec. - 20m: first after 69sec, after that every 37 sec
local obliteration_beam_timer = 69
local holo_hands = {}
local strMyName

local handpos = {
	["hand1"] = {x = 608.70, y = -198.75, z = -191.62},
	["hand2"] = {x = 607.67, y = -198.75, z = -157.00},
}

local referencePos = {
	["north"] = { x = 618, y = -198, z = -235 },
	["south"] = { x = 618, y = -198, z = -114 }
}

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
	Apollo.RegisterEventHandler("CHAT_NPCSAY", 			"OnChatNPCSay", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
	Apollo.RegisterEventHandler("BUFF_APPLIED", 		"OnBuffApplied", self) -- temp disabled. Not finished.
	Apollo.RegisterEventHandler("ChatMessage",			"OnChatMessage", self) -- temp dissabled. Not finished
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

local function lowestKeyValue(tbl)
	local lowestValue = false
	local tmp_table = {}
	for key, value in pairs(tbl) do
		if not lowestValue or (value < lowestValue) then
			lowestValue = value
			tmp_table = {}
			tmp_table[key] = value
		elseif value == lowestValue then
		    tmp_table[key] = value
		end
    end
    -- Now that we only have the keys with the lowest values left, order alphabetically
    local lowest_key = nil
    for key, value in pairs(tmp_table) do
        if not lowest_key or (key < lowest_key) then
            lowest_key = key
        end
    end
    return lowest_key
end

local function isAlive(strPlayerName)
	local unit = GameLib.GetPlayerUnitByName(strPlayerName)
	if not unit or unit:IsDead() then
		return false
	else
		return true
	end
end

local function getPlayerAssignment(tbl)
	local playerAssigned = lowestKeyValue(tbl)
	if not playerAssigned then return "<unknown>" end
	while not isAlive(playerAssigned) do
		tbl[playerAssigned] = nil
		playerAssigned = lowestKeyValue(tbl)
	end
	return playerAssigned
end

local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

local function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

function mod:OnReset()
	phase2warn, phase2 = false, false
	phase_blueroom = false
	phase2_blueroom_rotation = {}
	redBuffCount = 1
	greenBuffCount = 1
	blueBuffCount = 1
	buffCountTimer = false
	encounter_started = false
	gungrid_time = nil
	gungrid_timer = 20
	obliteration_beam_timer = 69
	holo_hands = {}
	core:ResetMarks()
	core:ResetWorldMarkers()
end

function mod:OnUnitCreated(unit)
	local eventTime = GameLib.GetGameTime()

	local sName = unit:GetName()
	--Print(eventTime .. " " .. sName .. " spawned")
	if sName == "Avatus" then
		core:AddUnit(unit)
		core:WatchUnit(unit)
		core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 22, 0)
	elseif sName == "Holo Hand" then
		--Print(eventTime .. " Holo hand Spawned")
		local unitId = unit:GetId()
		core:AddUnit(unit)
		core:WatchUnit(unit)
		table.insert(holo_hands, unitId, {["unit"] = unit})
		core:AddMsg("HHAND", "Holo Hand Spawned", 5, "Info")
		if unitId then
			core:AddPixie(unitId .. "_1", 2, unit, nil, "Blue", 7, 20, 0)
			--core:AddPixie(unitId .. "_2", 2, unit, nil, "Blue", 7, 20, 270)
		end
	elseif sName == "Mobius Physics Constructor" then
		core:AddUnit(unit)
		core:WatchUnit(unit)
		local unitId = unit:GetId()
		if unitId then
			if unit:GetHealth() then -- Portals have same name, actual boss has HP, portals have nilvalue
				core:AddPixie(unitId, 2, unit, nil, "Red", 5, 35, 0)
			end
		end
	elseif sName == "Unstoppable Object Simulation" then
		core:AddUnit(unit)
	elseif sName == "Holo Cannon" then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, 100, 0)
	elseif sName == "Shock Sphere" then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, -7, 0)
	elseif sName == "Support Cannon" then
		core:AddUnit(unit)
	end

	-- TESTING BLUE ROOM:
	if sName == "Infinite Logic Loop" then
		core:AddUnit(unit)
		core:UnitBuff(unit)
		phase2_blueroom = true
	end

end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	local unitId = unit:GetId()

	if sName == "Holo Hand" then
		if unitId then
			core:DropPixie(unitId .. "_1")
			--core:DropPixie(unitId .. "_2")
		end
	end
	
	if sName == "Holo Hand" and holo_hands[unitId] then
		holo_hands[unitId] = nil
	elseif sName == "Holo Cannon" then
		core:DropPixie(unit:GetId())
	elseif sName == "Avatus" then
		core:DropPixie(unit:GetId())
	elseif sName == "Shock Sphere" then
		core:DropPixie(unit:GetId())
	elseif sName == "Infinite Logic Loop" then
		phase2_blueroom = false
	elseif sName == "Mobius Physics Constructor" then
		core:DropPixie(unit:GetId())
	end
	--[[
	elseif sName == "" then
		core:DropPixie(unit:GetId())
	end
	]]
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
		if strSpellName == "Green Reconstitution Matrix" then
			local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["green"])
			if playerAssigned == strMyName then
				core:AddMsg("BLUEPURGE", "PURGE BLUE BOSS", 5, "Inferno")
			end
			--ChatSystemLib.Command('/p [#' .. tostring(greenBuffCount) .. '] ' .. unitName .. " has GREEN buff - assigned to: " .. playerAssigned)
			Print('[#' .. tostring(greenBuffCount) .. '] ' .. unitName .. " has GREEN buff - assigned to: " .. playerAssigned)
			greenBuffCount = greenBuffCount + 1
			phase2_blueroom_rotation["green"][playerAssigned] = phase2_blueroom_rotation["green"][playerAssigned] + 1
			if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
		elseif strSpellName == "Blue Disruption Matrix" then
			local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["blue"])
			if playerAssigned == strMyName then
				core:AddMsg("BLUEPURGE", "PURGE BLUE BOSS", 5, "Inferno")
			end
			--ChatSystemLib.Command('/p [#' .. tostring(blueBuffCount) .. '] ' .. unitName .. " has BLUE buff - assigned to: " .. playerAssigned)
			Print('[#' .. tostring(blueBuffCount) .. '] ' .. unitName .. " has BLUE buff - assigned to: " .. playerAssigned)
			phase2_blueroom_rotation["blue"][playerAssigned] = phase2_blueroom_rotation["blue"][playerAssigned] + 1
			blueBuffCount = blueBuffCount + 1
			if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
		elseif strSpellName == "Red Empowerment Matrix" then
			local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["red"])
			if playerAssigned == strMyName then
				core:AddMsg("BLUEPURGE", "PURGE BLUE BOSS", 5, "Inferno")
			end
			--ChatSystemLib.Command('/p [#' .. tostring(redBuffCount) .. '] ' .. unitName .. " has RED buff - assigned to: " .. playerAssigned)
			Print('[#' .. tostring(redBuffCount) .. '] ' .. unitName .. " has RED buff - assigned to: " .. playerAssigned)
			phase2_blueroom_rotation["red"][playerAssigned] = phase2_blueroom_rotation["red"][playerAssigned] + 1
			redBuffCount = redBuffCount + 1
			if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
		end		
	end
end

function mod:OnHealthChanged(unitName, health)
	if unitName == "Avatus" and health >= 75 and health <= 77 and not phase2warn then
		phase2warn = true
		core:AddMsg("AVAP2", "P2 SOON !", 5, "Info")
	elseif unitName == "Avatus" and health >= 50 and health <= 52 and not phase2warn then
		phase2warn = true
		core:AddMsg("AVAP2", "P2 SOON!", 5, "Info")
	end
	if unitName == "Avatus" and health >= 70 and health <= 72 and phase2warn then
		phase2warn = false
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
	elseif unitName == "Mobius Physics Constructor" and castName == "Data Flare" then
		core:AddBar("BLIND", "Blind", 29, true)
		core:AddMsg("BLIND", "BLIND! TURN AWAY FROM BOSS", 5, "Inferno")
	end

	--Print(eventTime .. " " .. unitName .. " is casting " .. castName)
end

function mod:OnChatDC(message)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " ChatDC Message: " .. message)
	if message:find("Gun Grid Activated") then
		--Print(eventTime .. " ChatDC Message: " .. message)
		gungrid_time = eventTime
		core:AddMsg("GGRIDMSG", "Gun Grid NOW!", 5, "Beware")
		core:StopBar("GGRID")
		core:StopBar("HHAND")
		core:AddBar("GGRID", "~Gun Grid", gungrid_timer, true)
		core:AddBar("HHAND", "Holo Hands spawn", 22)
	end
	if message:find("Portals have opened!") then
		phase2 = true
		core:StopBar("GGRID")
		core:StopBar("OBBEAM")
		core:StopBar("HHAND")
	end
end

function mod:OnChatMessage(channelCurrent, tMessage)
	local strChannelName = channelCurrent:GetName()
	if strChannelName == "Party" and phase2 then
		local msg = string.lower(tMessage["arMessageSegments"][1]["strText"])
		local strSender = tMessage["strSender"]
		
		if msg == "red" then
			if not phase2_blueroom_rotation["red"] then phase2_blueroom_rotation["red"] = {} end
			phase2_blueroom_rotation["red"][strSender] = 1
		elseif msg == "green" then
			if not phase2_blueroom_rotation["green"] then phase2_blueroom_rotation["green"] = {} end
			phase2_blueroom_rotation["green"][strSender] = 1
		elseif msg == "blue" then
			if not phase2_blueroom_rotation["blue"] then phase2_blueroom_rotation["blue"] = {} end
			phase2_blueroom_rotation["blue"][strSender] = 1
		end
	end
end

function mod:ResetBuffCount()
	redBuffCount = 1
	greenBuffCount = 1
	blueBuffCount = 1
	buffCountTimer = false
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
			phase2_blueroom_rotation = {}
			redBuffCount = 1
			greenBuffCount = 1
			blueBuffCount = 1
			buffCountTimer = false
			gungrid_time = eventTime + gungrid_timer
			holo_hands = {}
			strMyName = GameLib.GetPlayerUnit():GetName()
			core:AddUnit(unit)
			core:WatchUnit(unit)
			core:StartScan()

			--Print(eventTime .. " " .. sName .. " FIGHT STARTED ")

			core:AddBar("OBBEAM", "Obliteration Beam", obliteration_beam_timer, true)
			core:AddBar("GGRID", "~Gun Grid", gungrid_timer, true)
			core:SetWorldMarker(handpos["hand1"], "Hand Spawn")
			core:SetWorldMarker(handpos["hand2"], "Hand Spawn")
			core:SetWorldMarker(referencePos["north"], "North")
			core:SetWorldMarker(referencePos["south"], "South")
			gungrid_timer = 112
			obliteration_beam_timer = 37
		elseif sName == "Infinite Logic Loop" then
			local strRedBuffs = "Red Buffs:"
			local strGreenBuffs = "Green Buffs:"
			local strBlueBuffs = "Blue Buffs:"
		
			local redPlayerCount = 1
			local greenPlayerCount = 1
			local bluePlayerCount = 1

			for key, value in orderedPairs(phase2_blueroom_rotation["red"]) do
				strRedBuffs = strRedBuffs .. " - " .. tostring(redPlayerCount) .. ". " .. key
				redPlayerCount = redPlayerCount + 1
			end
			for key, value in orderedPairs(phase2_blueroom_rotation["green"]) do
				strGreenBuffs = strGreenBuffs .. " - " .. tostring(greenPlayerCount) .. ". " .. key
				greenPlayerCount = greenPlayerCount + 1
			end
			for key, value in orderedPairs(phase2_blueroom_rotation["blue"]) do
				strBlueBuffs = strBlueBuffs .. " - " .. tostring(bluePlayerCount) .. ". " .. key
				bluePlayerCount = bluePlayerCount + 1
			end
			--[[
			ChatSystemLib.Command('/p ' .. strRedBuffs)
			ChatSystemLib.Command('/p ' .. strGreenBuffs)
			ChatSystemLib.Command('/p ' .. strBlueBuffs)
			--]]
			Print(strRedBuffs)
			Print(strGreenBuffs)
			Print(strBlueBuffs)
		end
	end
end
