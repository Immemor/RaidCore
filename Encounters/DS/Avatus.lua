----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--   TODO
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Avatus", 52, 98, 104)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Avatus" })
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
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holo-main",
    --["Holo Hand Spawned"] = "Holo Hand Spawned", -- TODO: French translation missing !!!!
    ["Mobius Physics Constructor"] = "Constructeur de physique de Möbius",
    ["Unstoppable Object Simulation"] = "Simulacre invincible",
    ["Holo Cannon"] = "Holocanon",
    ["Shock Sphere"] = "Sphère de choc",
    ["Support Cannon"] = "Canon d'appui",
    ["Infinite Logic Loop"] = "Boucle de logique infinie",
    -- Datachron messages.
    --["Portals have opened!"] = "Portals have opened!", -- TODO: French translation missing !!!!
    --["Gun Grid Activated"] = "Gun Grid Activated", -- TODO: French translation missing !!!!
    -- Cast.
    ["Crushing Blow"] = "Coup écrasant",
    ["Data Flare"] = "Signal de données",
    ["Obliteration Beam"] = "Rayon de suppression",
    -- Bar and messages.
    --["PURGE BLUE BOSS"] = "PURGE BLUE BOSS", -- TODO: French translation missing !!!!
    ["P2 SOON !"] = "P2 SOON !",
    --["GO TO SIDES !"] = "GO TO SIDES !", -- TODO: French translation missing !!!!
    --["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!", -- TODO: French translation missing !!!!
    --["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS", -- TODO: French translation missing !!!!
    ["Blind"] = "Aveugler",
    --["Gun Grid NOW!"] = "Gun Grid NOW!", -- TODO: French translation missing !!!!
    --["~Gun Grid"] = "~Gun Grid", -- TODO: French translation missing !!!!
    --["Holo Hands spawn"] = "Holo Hands spawn", -- TODO: French translation missing !!!!
    --["Hand %u"] = "Hand %u", -- TODO: French translation missing !!!!
    ["MARKER North"] = "N",
    ["MARKER South"] = "S",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holohand",
    --["Holo Hand Spawned"] = "Holo Hand Spawned", -- TODO: German translation missing !!!!
    ["Mobius Physics Constructor"] = "Mobius Physikkonstrukteur",
    ["Unstoppable Object Simulation"] = "Unaufhaltbare Objektsimulation",
    ["Holo Cannon"] = "Holokanone",
    ["Shock Sphere"] = "Schocksphäre",
    ["Support Cannon"] = "Hilfskanone",
    ["Infinite Logic Loop"] = "Unendliche Logikschleife",
    -- Datachron messages.
    --["Portals have opened!"] = "Portals have opened!", -- TODO: German translation missing !!!!
    --["Gun Grid Activated"] = "Gun Grid Activated", -- TODO: German translation missing !!!!
    -- Cast.
    ["Crushing Blow"] = "Vernichtender Schlag",
    ["Data Flare"] = "Daten-Leuchtsignal",
    ["Obliteration Beam"] = "Vernichtungsstrahl",
    -- Bar and messages.
    --["PURGE BLUE BOSS"] = "PURGE BLUE BOSS", -- TODO: German translation missing !!!!
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    --["GO TO SIDES !"] = "GO TO SIDES !", -- TODO: German translation missing !!!!
    --["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!", -- TODO: German translation missing !!!!
    --["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS", -- TODO: German translation missing !!!!
    ["Blind"] = "Geblendet",
    --["Gun Grid NOW!"] = "Gun Grid NOW!", -- TODO: German translation missing !!!!
    --["~Gun Grid"] = "~Gun Grid", -- TODO: German translation missing !!!!
    --["Holo Hands spawn"] = "Holo Hands spawn", -- TODO: German translation missing !!!!
    --["Hand %u"] = "Hand %u", -- TODO: German translation missing !!!!
    ["MARKER North"] = "N",
    ["MARKER South"] = "S",
})
mod:RegisterDefaultTimerBarConfigs({
    ["OBBEAM"] = { sColor = "xkcdBloodRed" },
    ["BLIND"] = { sColor = "xkcdBurntYellow" },
    ["GGRID"] = { sColor = "xkcdBlue" },
    ["HHAND"] = { sColor = "xkcdOrangeyRed" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)
local handpos = {
    ["hand1"] = {x = 608.70, y = -198.75, z = -191.62},
    ["hand2"] = {x = 607.67, y = -198.75, z = -157.00},
}

local referencePos = {
    ["north"] = { x = 618, y = -198, z = -235 },
    ["south"] = { x = 618, y = -198, z = -114 }
}

----------------------------------------------------------------------------------------------------
-- locals.
----------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("CHAT_NPCSAY", "OnChatNPCSay", self)
    Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
    Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self) -- temp disabled. Not finished.
    Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self) -- temp dissabled. Not finished
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
    if sName == self.L["Holo Hand"] then
        local unitId = unit:GetId()
        core:AddUnit(unit)
        core:WatchUnit(unit)
        table.insert(holo_hands, unitId, {["unit"] = unit})
        core:AddMsg("HHAND", self.L["Holo Hand Spawned"], 5, "Info")
        if unitId and mod:GetSetting("LineCleaveHands") then
            core:AddPixie(unitId .. "_1", 2, unit, nil, "Blue", 7, 20, 0)
        end
    elseif sName == self.L["Mobius Physics Constructor"] then -- yellow room
        core:AddUnit(unit)
        core:WatchUnit(unit)
        local unitId = unit:GetId()
        if unitId then
            if unit:GetHealth() and mod:GetSetting("LineCleaveYellowRoomBoss") then -- Portals have same name, actual boss has HP, portals have nilvalue
                core:AddPixie(unitId, 2, unit, nil, "Red", 5, 35, 0)
            end
        end
    elseif sName == self.L["Unstoppable Object Simulation"] then --green
        core:AddUnit(unit)
    elseif sName == self.L["Holo Cannon"] and mod:GetSetting("LineCannons") then
        core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, 100, 0)
    elseif sName == self.L["Shock Sphere"] and mod:GetSetting("LineOrbsYellowRoom") then -- yellow room orbs
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
                core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, mod:GetSetting("SoundBlueInterrupt", "Inferno"))
            end
            Print('[#' .. tostring(greenBuffCount) .. '] ' .. unitName .. " has GREEN buff - assigned to: " .. playerAssigned)
            greenBuffCount = greenBuffCount + 1
            phase2_blueroom_rotation["green"][playerAssigned] = phase2_blueroom_rotation["green"][playerAssigned] + 1
            if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
        elseif strSpellName == "Blue Disruption Matrix" then
            local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["blue"])
            if playerAssigned == strMyName then
                core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, mod:GetSetting("SoundBlueInterrupt", "Inferno"))
            end
            Print('[#' .. tostring(blueBuffCount) .. '] ' .. unitName .. " has BLUE buff - assigned to: " .. playerAssigned)
            phase2_blueroom_rotation["blue"][playerAssigned] = phase2_blueroom_rotation["blue"][playerAssigned] + 1
            blueBuffCount = blueBuffCount + 1
            if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
        elseif strSpellName == "Red Empowerment Matrix" then
            local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["red"])
            if playerAssigned == strMyName then
                core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, mod:GetSetting("SoundBlueInterrupt", "Inferno"))
            end
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
            core:AddMsg("AVAP2", self.L["P2 SOON !"], 5, mod:GetSetting("SoundPortalPhase", "Info"))
        elseif health >= 50 and health <= 52 and not phase2warn then
            phase2warn = true
            core:AddMsg("AVAP2", self.L["P2 SOON!"], 5, mod:GetSetting("SoundPortalPhase", "Info"))
        elseif health >= 70 and health <= 72 and phase2warn then
            phase2warn = false
        end
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    local eventTime = GameLib.GetGameTime()
    if unitName == self.L["Avatus"] and castName == self.L["Obliteration Beam"] then
        core:AddMsg("BEAMS", self.L["GO TO SIDES !"], 5, mod:GetSetting("SoundObliterationBeam", "RunAway"))
        mod:RemoveTimerBar("OBBEAM")
        -- check if next ob beam in {obliteration_beam_timer} sec doesn't happen during a gungrid which takes 20 sec
        if gungrid_time + gungrid_timer + 20 < eventTime + obliteration_beam_timer then
            mod:AddTimerBar("OBBEAM", "Obliteration Beam", obliteration_beam_timer, mod:GetSetting("SoundObliterationBeam"))
        end
    elseif unitName == self.L["Holo Hand"] and castName == self.L["Crushing Blow"] then
        local playerUnit = GameLib.GetPlayerUnit()
        for _, hand in pairs(holo_hands) do
            local distance_to_hand = self:GetDistanceBetweenUnits(playerUnit, hand["unit"])
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
            core:AddMsg("CRBLOW", self.L["INTERRUPT CRUSHING BLOW!"], 5, mod:GetSetting("SoundHandInterrupt", "Inferno"))
        end
    elseif unitName == self.L["Mobius Physics Constructor"] and castName == self.L["Data Flare"] then
        mod:AddTimerBar("BLIND", "Blind", 29, mod:GetSetting("SoundBlindYellowRoom"))
        core:AddMsg("BLIND", self.L["BLIND! TURN AWAY FROM BOSS"], 5, mod:GetSetting("SoundBlindYellowRoom", "Inferno"))
    end
end

function mod:OnChatDC(message)
    local eventTime = GameLib.GetGameTime()
    if message:find(self.L["Gun Grid Activated"]) then
        gungrid_time = eventTime
        core:AddMsg("GGRIDMSG", self.L["Gun Grid NOW!"], 5, mod:GetSetting("SoundGunGrid", "Beware"))
        mod:AddTimerBar("GGRID", "~Gun Grid", gungrid_timer, mod:GetSetting("SoundGunGrid"))
        mod:AddTimerBar("HHAND", "Holo Hands spawn", 22)
    end
    if message:find(self.L["Portals have opened!"]) then
        phase2 = true
        mod:RemoveTimerBar("GGRID")
        mod:RemoveTimerBar("OBBEAM")
        mod:RemoveTimerBar("HHAND")
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
            if mod:GetSetting("LineCleaveBoss") then
                core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 22, 0)
            end

            mod:AddTimerBar("OBBEAM", "Obliteration Beam", obliteration_beam_timer, mod:GetSetting("SoundObliterationBeam"))
            mod:AddTimerBar("GGRID", "~Gun Grid", gungrid_timer, mod:GetSetting("SoundGunGrid"))
            if mod:GetSetting("OtherHandSpawnMarkers") then
                core:SetWorldMarker("HAND1", self.L["Hand %u"]:format(1), handpos["hand1"])
                core:SetWorldMarker("HAND2", self.L["Hand %u"]:format(2), handpos["hand2"])
            end
            if mod:GetSetting("OtherDirectionMarkers") then
                core:SetWorldMarker("NORTH", self.L["MARKER North"], referencePos["north"])
                core:SetWorldMarker("SOUTH", self.L["MARKER South"], referencePos["south"])
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
            Print(strRedBuffs)
            Print(strGreenBuffs)
            Print(strBlueBuffs)
        end
    end
end
