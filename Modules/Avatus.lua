local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("Avatus", 52)
if not mod then return end

mod:RegisterEnableMob("Avatus")
mod:RegisterRestrictZone("Avatus", "The Oculus")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Avatus"] = "Avatus",
	["Holo Hand"] = "Holo Hand",
	["Holo Hand Spawned"] = "Holo Hand Spawned",
	["Mobius Physics Constructor"] = "Mobius Physics Constructor",
	["Unstoppable Object Simulation"] = "Unstoppable Object Simulation",
	["Holo Cannon"] = "Holo Cannon",
	["Shock Sphere"] = "Shock Sphere",
	["Support Cannon"] = "Support Cannon",
	["Infinite Logic Loop"] = "Infinite Logic Loop",
	-- Datachron messages.
	["Portals have opened!"] = "Portals have opened!",
	["Gun Grid Activated"] = "Gun Grid Activated",
	-- Cast.
	["Crushing Blow"] = "Crushing Blow",
	["Data Flare"] = "Data Flare",
	["Obliteration Beam"] = "Obliteration Beam",
	-- Bar and messages.
	["PURGE BLUE BOSS"] = "PURGE BLUE BOSS",
	["P2 SOON !"] = "P2 SOON !",
	["GO TO SIDES !"] = "GO TO SIDES !",
	["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!",
	["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS",
	["Blind"] = "Blind",
	["Gun Grid NOW!"] = "Gun Grid NOW!",
	["~Gun Grid"] = "~Gun Grid",
	["Holo Hands spawn"] = "Holo Hands spawn",
	["Hand %u"] = "Hand %u",
	["MARKER North"] = "North",
	["MARKER South"] = "South",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})
mod:RegisterGermanLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})

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
local NO_BREAK_SPACE = string.char(194, 160)

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
	Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	--Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
	--Apollo.RegisterEventHandler("RAID_SYNC", "OnSyncRcv", self)
	--Apollo.RegisterEventHandler("SubZoneChanged", "OnZoneChanged", self)
	Apollo.RegisterEventHandler("CHAT_NPCSAY", "OnChatNPCSay", self)
	Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
	Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self) -- temp disabled. Not finished.
	Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self) -- temp dissabled. Not finished
end

local function GetSetting(key)
	return core:GetSettings()["DS"]["Avatus"][key]
end

local function GetSoundSetting(sound, key)
	if core:GetSettings()["DS"]["Avatus"][key] then return sound else return nil end
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

function mod:OnUnitCreated(unit, sName)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " " .. sName .. " spawned")
	if sName == self.L["Avatus"] then
		core:AddUnit(unit)
		core:WatchUnit(unit)
		if GetSetting("LineCleaveBoss") then
			core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 22, 0)
		end
	elseif sName == self.L["Holo Hand"] then
		--Print(eventTime .. " Holo hand Spawned")
		local unitId = unit:GetId()
		core:AddUnit(unit)
		core:WatchUnit(unit)
		table.insert(holo_hands, unitId, {["unit"] = unit})
		core:AddMsg("HHAND", self.L["Holo Hand Spawned"], 5, "Info")
		if unitId and GetSetting("LineCleaveHands") then
			core:AddPixie(unitId .. "_1", 2, unit, nil, "Blue", 7, 20, 0)
			--core:AddPixie(unitId .. "_2", 2, unit, nil, "Blue", 7, 20, 270)
		end
	elseif sName == self.L["Mobius Physics Constructor"] then -- yellow room
		core:AddUnit(unit)
		core:WatchUnit(unit)
		local unitId = unit:GetId()
		if unitId then
			if unit:GetHealth() and GetSetting("LineCleaveYellowRoomBoss") then -- Portals have same name, actual boss has HP, portals have nilvalue
				core:AddPixie(unitId, 2, unit, nil, "Red", 5, 35, 0)
			end
		end
	elseif sName == self.L["Unstoppable Object Simulation"] then --green
		core:AddUnit(unit)
	elseif sName == self.L["Holo Cannon"] and GetSetting("LineCannons") then
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, 100, 0)
	elseif sName == self.L["Shock Sphere"] and GetSetting("LineOrbsYellowRoom") then -- yellow room orbs
		core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, -7, 0)
	elseif sName == self.L["Support Cannon"] then
		core:AddUnit(unit)
	elseif sName == self.L["Infinite Logic Loop"] then -- blue
		-- TESTING BLUE ROOM:
		core:AddUnit(unit)
		core:UnitBuff(unit)
		phase2_blueroom = true
	end
end

function mod:OnUnitDestroyed(unit, sName)
	local unitId = unit:GetId()

	if sName == self.L["Holo Hand"] then
		if unitId then
			core:DropPixie(unitId .. "_1")
			--core:DropPixie(unitId .. "_2")
		end
		if holo_hands[unitId] then
			holo_hands[unitId] = nil
		end
	elseif sName == self.L["Holo Cannon"] then
		core:DropPixie(unit:GetId())
	elseif sName == self.L["Avatus"] then
		core:DropPixie(unit:GetId())
	elseif sName == self.L["Shock Sphere"] then
		core:DropPixie(unit:GetId())
	elseif sName == self.L["Infinite Logic Loop"] then
		phase2_blueroom = false
	elseif sName == self.L["Mobius Physics Constructor"] then
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
	if phase2_blueroom and unitName == self.L["Infinite Logic Loop"] then
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
				core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, GetSoundSetting("Inferno", "SoundBlueInterrupt"))
			end
			--ChatSystemLib.Command('/p [#' .. tostring(greenBuffCount) .. '] ' .. unitName .. " has GREEN buff - assigned to: " .. playerAssigned)
			Print('[#' .. tostring(greenBuffCount) .. '] ' .. unitName .. " has GREEN buff - assigned to: " .. playerAssigned)
			greenBuffCount = greenBuffCount + 1
			phase2_blueroom_rotation["green"][playerAssigned] = phase2_blueroom_rotation["green"][playerAssigned] + 1
			if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
		elseif strSpellName == "Blue Disruption Matrix" then
			local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["blue"])
			if playerAssigned == strMyName then
				core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, GetSoundSetting("Inferno", "SoundBlueInterrupt"))
			end
			--ChatSystemLib.Command('/p [#' .. tostring(blueBuffCount) .. '] ' .. unitName .. " has BLUE buff - assigned to: " .. playerAssigned)
			Print('[#' .. tostring(blueBuffCount) .. '] ' .. unitName .. " has BLUE buff - assigned to: " .. playerAssigned)
			phase2_blueroom_rotation["blue"][playerAssigned] = phase2_blueroom_rotation["blue"][playerAssigned] + 1
			blueBuffCount = blueBuffCount + 1
			if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
		elseif strSpellName == "Red Empowerment Matrix" then
			local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["red"])
			if playerAssigned == strMyName then
				core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, GetSoundSetting("Inferno", "SoundBlueInterrupt"))
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
	if unitName == self.L["Avatus"] then
		if health >= 75 and health <= 77 and not phase2warn then
			phase2warn = true
			core:AddMsg("AVAP2", self.L["P2 SOON !"], 5, GetSoundSetting("Info", "SoundPortalPhase"))
		elseif health >= 50 and health <= 52 and not phase2warn then
			phase2warn = true
			core:AddMsg("AVAP2", self.L["P2 SOON!"], 5, GetSoundSetting("Info", "SoundPortalPhase"))
		elseif health >= 70 and health <= 72 and phase2warn then
			phase2warn = false
		end
	end
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == self.L["Avatus"] and castName == self.L["Obliteration Beam"] then
		core:AddMsg("BEAMS", self.L["GO TO SIDES !"], 5, GetSoundSetting("RunAway", "SoundObliterationBeam"))
		core:StopBar("OBBEAM")
		-- check if next ob beam in {obliteration_beam_timer} sec doesn't happen during a gungrid which takes 20 sec
		if gungrid_time + gungrid_timer + 20 < eventTime + obliteration_beam_timer then
			core:AddBar("OBBEAM", self.L["Obliteration Beam"], obliteration_beam_timer, GetSoundSetting(true, "SoundObliterationBeam"))
		end
	elseif unitName == self.L["Holo Hand"] and castName == self.L["Crushing Blow"] then
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
		local sSpellName = closest_holo_hand["unit"]:GetCastName():gsub(NO_BREAK_SPACE, " ")
		if sSpellName == self.L["Crushing Blow"] then
			core:AddMsg("CRBLOW", self.L["INTERRUPT CRUSHING BLOW!"], 5, GetSoundSetting("Inferno", "SoundHandInterrupt"))
		end
	elseif unitName == self.L["Mobius Physics Constructor"] and castName == self.L["Data Flare"] then
		core:AddBar("BLIND", self.L["Blind"], 29, GetSoundSetting(true, "SoundBlindYellowRoom"))
		core:AddMsg("BLIND", self.L["BLIND! TURN AWAY FROM BOSS"], 5, GetSoundSetting("Inferno", "SoundBlindYellowRoom"))
	end
end

function mod:OnChatDC(message)
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " ChatDC Message: " .. message)
	if message:find(self.L["Gun Grid Activated"]) then
		--Print(eventTime .. " ChatDC Message: " .. message)
		gungrid_time = eventTime
		core:AddMsg("GGRIDMSG", self.L["Gun Grid NOW!"], 5, GetSoundSetting("Beware", "SoundGunGrid"))
		core:StopBar("GGRID")
		core:StopBar("HHAND")
		core:AddBar("GGRID", self.L["~Gun Grid"], gungrid_timer, GetSoundSetting(true, "SoundGunGrid"))
		core:AddBar("HHAND", self.L["Holo Hands spawn"], 22)
	end
	if message:find(self.L["Portals have opened!"]) then
		phase2 = true
		core:StopBar("GGRID")
		core:StopBar("OBBEAM")
		core:StopBar("HHAND")
	end
end

function mod:OnChatMessage(channelCurrent, tMessage)
	local strChannelName = channelCurrent:GetName()
	if strChannelName == "Party" and phase2 then
		local msg = tMessage.arMessageSegments[1].strText:lower()
		local strSender = tMessage["strSender"]:gsub(NO_BREAK_SPACE, " ")

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

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Avatus"] and not encounter_started then
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

			core:AddBar("OBBEAM", self.L["Obliteration Beam"], obliteration_beam_timer, GetSoundSetting(true, "SoundObliterationBeam"))
			core:AddBar("GGRID", self.L["~Gun Grid"], gungrid_timer, GetSoundSetting(true, "SoundGunGrid"))
			if GetSetting("OtherHandSpawnMarkers") then
				core:SetWorldMarker(handpos["hand1"], self.L["Hand %u"])
				core:SetWorldMarker(handpos["hand2"], self.L["Hand %u"])
			end
			if GetSetting("OtherDirectionMarkers") then
				core:SetWorldMarker(referencePos["north"], self.L["MARKER North"])
				core:SetWorldMarker(referencePos["south"], self.L["MARKER South"])
			end
			gungrid_timer = 112
			obliteration_beam_timer = 37
		elseif sName == self.L["Infinite Logic Loop"] then
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
