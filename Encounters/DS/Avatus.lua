----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--
-- Avatus fight is split in 3 major phases, they start on threshold healh pourcent of Avatus:
--  * From 100% to 75%: Avatus itself, with all players.
--  * At 75%, there is the small labyrinth and green and blue teleporter.
--  * From 75% to 50: Avatus itself, with all players.
--  * At 50%, again the labyrinth with red and yellow teleporter.
--  * From 50% to 25%: Avatus itself, with all players.
--  * From 25% to death: Enrage phase.
--
-- In "Green" phase, there are 24 pillars. An number will be add between two pillars.
-- So 12 numbers will be displayed like this:
--
--        9
--     A     8
--   B         7
--  .     +     6
--   1         5
--     2     4
--        3
--
-- The center is { x = 618.21, z =-174.2 }, and the unit called "Unstoppable Object Simulation"
-- start on West, on the dot so. The dot Pillars are unusable.
--
-- With n from 1 to 12, coordonates are:
-- {{{
--   Angle(n) = PI + (n - 1) * PI / 6
--   Position(n) = {
--       x = 618.21 + 70 * cos(Angle(n)),
--       z = -174.2 + 70 * sin(Angle(n))
--   }
-- }}}
-- Results are stored in GREEN_ROOM_MARKERS constant.
--
-- Extra Informations. Few pillars positions collected:
-- {
--     { x = 671.276489, z = -174.475327 },
--     { x = 565.161865, z = -174.289658 },
--     { x = 618.183533, z = -227.125458 },
--     { x = 661.742126, z = -249.719589 },
--     { x = 574.576834, z = -98.386374 },
--     { x = 530.910645, z = -174.166290 },
--     { x = 645.375183, z = -128.802170 },
--     { x = 663.878540, z = -201.568573 },
--     { x = 591.531921, z = -128.216736 },
--     { x = 693.861572, z = -218.121765 },
--     { x = 705.460144, z = -174.510483 },
--     { x = 618.322693, z = -86.674301 },
--     { x = 618.349182, z = -121.058273 },
--     { x = 644.759949, z = -220.22229 },
--     { x = 542.987549, z = -129.588684 },
-- }
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
    ["Mobius Physics Constructor"] = "Mobius Physics Constructor",
    ["Unstoppable Object Simulation"] = "Unstoppable Object Simulation",
    ["Holo Cannon"] = "Holo Cannon",
    ["Shock Sphere"] = "Shock Sphere",
    ["Support Cannon"] = "Support Cannon",
    ["Infinite Logic Loop"] = "Infinite Logic Loop",
    ["Tower Platform"] = "Tower Platform",
    ["Augmented Rowsdower"] = "Augmented Rowsdower",
    -- Datachron messages.
    ["Portals have opened!"] = "Avatus' power begins to surge! Portals have opened!",
    ["Gun Grid Activated"] = "SECURITY PROTOCOL: Gun Grid Activated.",
    -- Cast.
    ["Crushing Blow"] = "Crushing Blow",
    ["Data Flare"] = "Data Flare",
    ["Obliteration Beam"] = "Obliteration Beam",
    -- BuffName with many ID.
    ["Red Empowerment Matrix"] = "Red Empowerment Matrix",
    ["Blue Disruption Matrix"] = "Blue Disruption Matrix",
    ["Green Reconstitution Matrix"] = "Green Reconstitution Matrix",
    -- Bar and messages.
    ["Holo Hand Spawned"] = "Holo Hand Spawned",
    ["PURGE BLUE BOSS"] = "PURGE BLUE BOSS",
    ["P2 SOON !"] = "P2 SOON !",
    ["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!",
    ["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS",
    ["Blind"] = "Blind",
    ["Gun Grid NOW!"] = "Gun Grid NOW!",
    ["~Gun Grid"] = "~Gun Grid",
    ["Hand %u"] = "Hand %u",
    ["MARKER North"] = "North",
    ["MARKER South"] = "South",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holo-main",
    ["Mobius Physics Constructor"] = "Constructeur de physique de Möbius",
    ["Unstoppable Object Simulation"] = "Simulacre invincible",
    ["Holo Cannon"] = "Holocanon",
    ["Shock Sphere"] = "Sphère de choc",
    ["Support Cannon"] = "Canon d'appui",
    ["Infinite Logic Loop"] = "Boucle de logique infinie",
    ["Tower Platform"] = "Plateforme de la tour",
    ["Augmented Rowsdower"] = "Tamarou augmenté",
    -- Datachron messages.
    ["Portals have opened!"] = "L'énergie d'Avatus commence à déferler ! Des portails se sont ouverts !",
    ["Gun Grid Activated"] = "PROTOCOLE DE SÉCURITÉ : pétoires activées.",
    -- Cast.
    ["Crushing Blow"] = "Coup écrasant",
    ["Data Flare"] = "Signal de données",
    ["Obliteration Beam"] = "Rayon de suppression",
    -- BuffName with many ID.
    ["Holo Hand Spawned"] = "Holo-main Apparition",
    ["Red Empowerment Matrix"] = "Matrice de renforcement rouge",
    ["Blue Disruption Matrix"] = "Matrice disruptive bleue",
    ["Green Reconstitution Matrix"] = "Matrice de reconstitution verte",
    -- Bar and messages.
    ["PURGE BLUE BOSS"] = "PURGE BOSS BLEUE",
    ["P2 SOON !"] = "P2 BIENTÔT !",
    ["INTERRUPT CRUSHING BLOW!"] = "INTERROMPRE COUP ÉCRASANT!",
    ["BLIND! TURN AWAY FROM BOSS"] = "AVEUGLER! DOS AU BOSS",
    ["Blind"] = "Aveugler",
    ["Gun Grid NOW!"] = "pétoires MAINTENANT!",
    ["~Gun Grid"] = "~Pétoires Grille",
    ["Hand %u"] = "Main %u",
    ["MARKER North"] = "Nord",
    ["MARKER South"] = "Sud",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holohand",
    ["Mobius Physics Constructor"] = "Mobius Physikkonstrukteur",
    ["Unstoppable Object Simulation"] = "Unaufhaltbare Objektsimulation",
    ["Holo Cannon"] = "Holokanone",
    ["Shock Sphere"] = "Schocksphäre",
    ["Support Cannon"] = "Hilfskanone",
    ["Infinite Logic Loop"] = "Unendliche Logikschleife",
    --["Tower Platform"] = "Tower Platform", -- TODO: German translation missing !!!!
    --["Augmented Rowsdower"] = "Augmented Rowsdower", -- TODO: German translation missing !!!!
    -- Datachron messages.
    --["Portals have opened!"] = "Portals have opened!", -- TODO: German translation missing !!!!
    --["Gun Grid Activated"] = "Gun Grid Activated", -- TODO: German translation missing !!!!
    -- Cast.
    ["Crushing Blow"] = "Vernichtender Schlag",
    ["Data Flare"] = "Daten-Leuchtsignal",
    ["Obliteration Beam"] = "Vernichtungsstrahl",
    -- Bar and messages.
    --["Holo Hand Spawned"] = "Holo Hand Spawned", -- TODO: German translation missing !!!!
    --["PURGE BLUE BOSS"] = "PURGE BLUE BOSS", -- TODO: German translation missing !!!!
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    --["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!", -- TODO: German translation missing !!!!
    --["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS", -- TODO: German translation missing !!!!
    ["Blind"] = "Geblendet",
    --["Gun Grid NOW!"] = "Gun Grid NOW!", -- TODO: German translation missing !!!!
    --["~Gun Grid"] = "~Gun Grid", -- TODO: German translation missing !!!!
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
local next = next
local NO_BREAK_SPACE = string.char(194, 160)
local HAND_MAKERS = {
    ["hand1"] = {x = 608.70, y = -198.75, z = -191.62},
    ["hand2"] = {x = 607.67, y = -198.75, z = -157.00},
}

local CARDINAL_MARKERS = {
    ["north"] = { x = 618, y = -198, z = -235 },
    ["south"] = { x = 618, y = -198, z = -114 }
}
local GREEN_ROOM_MARKERS = {
   ["1"] = { y = -198, x = 557.58, z = -139.2 },
   ["2"] = { y = -198, x = 583.21, z = -113.5 },
   ["3"] = { y = -198, x = 618.21, z = -104.2 },
   ["4"] = { y = -198, x = 653.21, z = -113.5 },
   ["5"] = { y = -198, x = 678.83, z = -139.2 },
   ["6"] = { y = -198, x = 688.21, z = -174.2 },
   ["7"] = { y = -198, x = 678.83, z = -209.2 },
   ["8"] = { y = -198, x = 653.21, z = -234.8 },
   ["9"] = { y = -198, x = 618.21, z = -244.2 },
   ["10"] = { y = -198, x = 583.21, z = -234.8 },
   ["11"] = { y = -198, x = 557.58, z = -209.2 },
}

----------------------------------------------------------------------------------------------------
-- locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local SetTargetUnit = GameLib.SetTargetUnit
local phase2warn, phase2 = false, false
local phase_blueroom = false
local phase2_blueroom_rotation = {}
local encounter_started = false
local redBuffCount, greenBuffCount, blueBuffCount = 1
local buffCountTimer = false
local gungrid_time = nil
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
    Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
    Apollo.RegisterEventHandler("CHAT_PARTY", "OnPartyMessage", self)

    phase2warn, phase2 = false, false
    phase_blueroom = false
    phase2_blueroom_rotation = {}
    redBuffCount = 1
    greenBuffCount = 1
    blueBuffCount = 1
    buffCountTimer = false
    encounter_started = false
    holo_hands = {}
    strMyName = GetPlayerUnit():GetName()
    bGreenRoomMarkerDisplayed = false
end

function mod:OnUnitCreated(unit, sName)
    local eventTime = GameLib.GetGameTime()
    if sName == self.L["Augmented Rowsdower"] then
        core:AddMsg("Rowsdower", self.L["Augmented Rowsdower"], 3)
        SetTargetUnit(unit)
    elseif sName == self.L["Holo Hand"] then
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
        core:WatchUnit(unit)
        phase2_blueroom = true
    elseif sName == self.L["Tower Platform"] then
        if not bGreenRoomMarkerDisplayed then
            bGreenRoomMarkerDisplayed = true
            for k, tPosition in next, GREEN_ROOM_MARKERS do
                core:SetWorldMarker("GREEN_ROOM_MARKERS_" .. k, k, tPosition)
            end
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Holo Hand"] then
        local unitId = unit:GetId()
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
    elseif sName == self.L["Tower Platform"] then
        if bGreenRoomMarkerDisplayed then
            bGreenRoomMarkerDisplayed = false
            for k, tPosition in next, GREEN_ROOM_MARKERS do
                core:DropWorldMarker("GREEN_ROOM_MARKERS_" .. k)
            end
        end
    end
end

function mod:OnBuffApplied(unitName, splId, unit)
    if phase2_blueroom and unitName == self.L["Infinite Logic Loop"] then
        local sSpellName = GameLib.GetSpell(splId):GetName()

        -- Todo change to SplId instead of name to reduce API calls
        if sSpellName == self.L["Green Reconstitution Matrix"] then
            local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["green"])
            if playerAssigned == strMyName then
                core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, mod:GetSetting("SoundBlueInterrupt", "Inferno"))
            end
            Print('[#' .. tostring(greenBuffCount) .. '] ' .. unitName .. " has GREEN buff - assigned to: " .. playerAssigned)
            greenBuffCount = greenBuffCount + 1
            phase2_blueroom_rotation["green"][playerAssigned] = phase2_blueroom_rotation["green"][playerAssigned] + 1
            if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
        elseif sSpellName == self.L["Blue Disruption Matrix"] then
            local playerAssigned = getPlayerAssignment(phase2_blueroom_rotation["blue"])
            if playerAssigned == strMyName then
                core:AddMsg("BLUEPURGE", self.L["PURGE BLUE BOSS"], 5, mod:GetSetting("SoundBlueInterrupt", "Inferno"))
            end
            Print('[#' .. tostring(blueBuffCount) .. '] ' .. unitName .. " has BLUE buff - assigned to: " .. playerAssigned)
            phase2_blueroom_rotation["blue"][playerAssigned] = phase2_blueroom_rotation["blue"][playerAssigned] + 1
            blueBuffCount = blueBuffCount + 1
            if not buffCountTimer then buffCountTimer = true self:ScheduleTimer("ResetBuffCount", 13) end
        elseif sSpellName == self.L["Red Empowerment Matrix"] then
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
    if unitName == self.L["Avatus"] and castName == self.L["Obliteration Beam"] then
        mod:RemoveTimerBar("OBBEAM")
        -- check if next ob beam in sec doesn't happen during a gungrid which takes 20 sec
        if gungrid_time + 132 < GetGameTime() + 37 then
            mod:AddTimerBar("OBBEAM", "Obliteration Beam", 37, mod:GetSetting("SoundObliterationBeam"))
        end
    elseif unitName == self.L["Holo Hand"] and castName == self.L["Crushing Blow"] then
        local playerUnit = GetPlayerUnit()
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
    if message:find(self.L["Gun Grid Activated"]) then
        gungrid_time = GetGameTime()
        core:AddMsg("GGRIDMSG", self.L["Gun Grid NOW!"], 5, mod:GetSetting("SoundGunGrid", "Beware"))
        mod:AddTimerBar("GGRID", "~Gun Grid", 112, mod:GetSetting("SoundGunGrid"))
        mod:AddTimerBar("HHAND", "Holo Hand", 22)
    end
    if message:find(self.L["Portals have opened!"]) then
        phase2 = true
        mod:RemoveTimerBar("GGRID")
        mod:RemoveTimerBar("OBBEAM")
        mod:RemoveTimerBar("HHAND")
    end
end

function mod:OnPartyMessage(sMessage, sSender)
    if phase2 then
        sMessage = sMessage:lower()
        if sMessage == "red" or sMessage == "green" or sMessage == "blue" then
            if not phase2_blueroom_rotation[sMessage] then
                phase2_blueroom_rotation[sMessage] = {}
            end
            phase2_blueroom_rotation[sMessage][sSender] = 1
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
        if sName == self.L["Avatus"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            if mod:GetSetting("LineCleaveBoss") then
                core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 22, 0)
            end

            if not encounter_started then
                encounter_started = true
                gungrid_time = GetGameTime() + 20

                mod:AddTimerBar("OBBEAM", "Obliteration Beam", 69, mod:GetSetting("SoundObliterationBeam"))
                mod:AddTimerBar("GGRID", "~Gun Grid", 20, mod:GetSetting("SoundGunGrid"))
                if mod:GetSetting("OtherHandSpawnMarkers") then
                    core:SetWorldMarker("HAND1", self.L["Hand %u"]:format(1), HAND_MAKERS["hand1"])
                    core:SetWorldMarker("HAND2", self.L["Hand %u"]:format(2), HAND_MAKERS["hand2"])
                end
                if mod:GetSetting("OtherDirectionMarkers") then
                    core:SetWorldMarker("NORTH", self.L["MARKER North"], CARDINAL_MARKERS["north"])
                    core:SetWorldMarker("SOUTH", self.L["MARKER South"], CARDINAL_MARKERS["south"])
                end
            end
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
