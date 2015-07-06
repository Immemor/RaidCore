----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Description:
--   Unique encounter in Core-Y83 raid.
--
--   - There are 3 boss called "Prime Evolutionary Operant". At any moment, one of them is
--     compromised, and his name is "Prime Phage Distributor".
--   - Bosses don't move, their positions are constants so.
--   - The boss call "Prime Phage Distributor" have a debuff called "Compromised Circuitry".
--   - And switch boss occur at 60% and 20% of health.
--   - The player which will be irradied is the last connected in the game (probability: 95%).
--
--   So be careful, with code based on name, as bosses are renamed many times during the combat.
--
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("PrimeEvolutionaryOperant", 91, 0, 475)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Prime Evolutionary Operant", "Prime Phage Distributor" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Prime Evolutionary Operant"] = "Prime Evolutionary Operant",
    ["Prime Phage Distributor"] = "Prime Phage Distributor",
    ["Sternum Buster"] = "Sternum Buster",
    ["Organic Incinerator"] = "Organic Incinerator",
    -- Datachron messages.
    ["(.*) is being irradiated"] = "(.*) is being irradiated",
    ["ENGAGING TECHNOPHAGE TRASMISSION"] = "ENGAGING TECHNOPHAGE TRASMISSION",
    ["A Prime Purifier has been corrupted!"] = "A Prime Purifier has been corrupted!",
    -- Cast
    ["Digitize"] = "Digitize",
    ["Strain Injection"] = "Strain Injection",
    ["Corruption Spike"] = "Corruption Spike",
    ["Radiation Bath on %s"] = "Radiation Bath on %s",
    -- Bars messages.
    ["~Next irradiate"] = "~Next irradiate",
    ["SWITCH SOON"] = "SWITCH SOON",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Prime Evolutionary Operant"] = "Premier purificateur",
    ["Prime Phage Distributor"] = "Distributeur de Primo Phage",
    ["Organic Incinerator"] = "Incinérateur organique",
    -- Datachron messages.
    ["(.*) is being irradiated"] = "(.*) est irradiée.",
    ["ENGAGING TECHNOPHAGE TRASMISSION"] = "ENCLENCHEMENT DE LA TRANSMISSION DU TECHNOPHAGE",
    ["Radiation Bath on %s"] = "Douche Radioactive sur %s",  
    -- Bars messages.
    ["~Next irradiate"] = "~Prochaine irradiation",
    ["SWITCH SOON"] = "SWITCH SOON",
})
mod:RegisterGermanLocale({
})
-- Default settings.
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NEXT_IRRADIATE"] = { sColor = "xkcdLightRed" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Center of the room, where is the Organic Incinerator button.
local ORGANIC_INCINERATOR = { x = 1268, y = -800, z = 876 }
-- It's when the player enter in "nuclear" green zone. If this last have some STRAIN INCUBATION,
-- he will lost it, and an small mob will pop.
local DEBUFF_RADIATION_BATH = 71188
-- DOT taken by one or more players, which is dispel with RADIATION_BATH or ENGAGING datachron
-- event.
local DEBUFF_STRAIN_INCUBATION = 49303
-- DoT taken by everyone when the laser is interrupted. Hardmode only
local DEBUFF_DEGENERATION = 81783
-- Compas position
local EAST = "EAST"
local NORTH = "NORTH"
local WEST = "WEST"
-- Coordinates of the three safe zone
local SAFE_ZONE_WEST = { x = 1238.644, y = -800.505, z = 894.101 }
local SAFE_ZONE_EAST = { x = 1300.937, y = -800.505, z = 895.701 }
local SAFE_ZONE_NORTH = { x = 1267.703, y = -800.505, z = 842.803 }
-- Constant Y position
local yCoord = -800.60

-- Constant to draw digitize lines
local Coords = {}
local CoordsTank = {}
Coords[EAST] = {
    [1] = { name = "1", x = 1285.45, z = 927.58 },
    [2] = { name = "2", x = 1296.25, z = 934.77 },
    [3] = { name = "3", x = 1320.93, z = 935.26 },
    [4] = { name = "4", x = 1332.09, z = 928.45 },
    [5] = { name = "5",x = 1344.32,z = 907.19 },
    [6] = { name = "6",x = 1344.04,z = 891.89 },
    [7] = { name = "7", x = 1331.96,z = 873.30 },
    [8] = { name = "8", x = 1321.60, z = 866.36 },
    [9] = { name = "9", x = 1308.58, z = 913.53 },
    [10] = { name = "10", x = 1319.61, z = 907.28 },
    [11] = { name = "11", x = 1319.62, z = 894.53 },
}

Coords[NORTH] = {
    [1] = { name = "1", x = 1302.87, z = 837.23 },
    [2] = { name = "2", x = 1303.22, z = 823.23 },
    [3] = { name = "3", x = 1291.21, z = 803.33 },
    [4] = { name = "4", x = 1280.26, z = 796.33 },
    [5] = { name = "5", x = 1256.22, z = 796.51 },
    [6] = { name = "6", x = 1244.71, z = 802.90 },
    [7] = { name = "7", x = 1232.53, z = 823.87 },
    [8] = { name = "8", x = 1232.62, z = 836.80 },
    [9] = { name = "9", x = 1278.79, z = 823.45 },
    [10] = { name = "10", x = 1268.00, z = 817.31 },
    [11] = { name = "11", x = 1256.95, z = 823.64 },
}

Coords[WEST] = {
    [1] = { name = "1", x = 1215.35, z = 866.08 },
    [2] = { name = "2", x = 1204.24, z = 872.99 },
    [3] = { name = "3", x = 1191.91, z = 893.94 },
    [4] = { name = "4", x = 1191.86, z = 906.97 },
    [5] = { name = "5", x = 1204.29, z = 927.76 },
    [6] = { name = "6", x = 1215.66, z = 934.04 },
    [7] = { name = "7", x = 1239.53, z = 933.93 },
    [8] = { name = "8", x = 1250.87, z = 927.76 },
    [9] = { name = "9", x = 1216.43, z = 894.04 },
    [10] = { name = "10", x = 1216.33, z = 906.61 },
    [11] = { name = "11", x = 1227.33, z = 912.87 },
}
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit

-- Tables that contains the 3 bosses. Will be iterated each push (60% and 20%) to find which one is
-- the highest one to draw a line for the DPS.
local tPrimeUnits = {}
local tPrimeUnitIndex = 0

-- Tables that contains all lines drew. Used to be sure to clear all line when we push. Otherwise 
-- expect FPS issues
local tLinesDrewIndex = 0
local tLinesDrew = {}

-- Unit Laser (hardmode only)
local uLaser = nil
-- Unit north boss
local uNorthBoss = nil
-- Unit west boss
local uWestBoss = nil
-- Unit east boss
local uEastBoss = nil
-- Unit next corrupted boss 
local uNextBoss = nil

-- Boolean to know if we are in the first phase (first phase = 100 => 60% for each bosses) because
-- the next corrupted boss is always N => W => E for the first phase then it's the one with the 
-- highest HP
local bIsInFirstPhase = true

local function AddPrimeUnit(unit)
    local bAdd = true
    for _, tPrimeUnit in next, tPrimeUnits do
        if tPrimeUnit:GetId() == unit:GetId() then
            bAdd = false
        end
    end
    if bAdd == true then
        table.insert(tPrimeUnits, unit)
    end
end

local function GetHighestPrimeUnit()
    local uHighest = nil
    for _, tPrimeUnit in next, tPrimeUnits do
        if uHighest == nil or tPrimeUnit :GetHealth() > uHighest:GetHealth() then
            if uNextBoss ~= tPrimeUnit then
                uHighest = tPrimeUnit
            end
        end
    end
    return uHighest
end

local function GetNextBoss()
    if bIsInFirstPhase == true then
        if uNextBoss == nil then --first push ==> W always
            uNextBoss = uWestBoss
        elseif uNextBoss == uWestBoss then -- second push ==> E
            uNextBoss = uEastBoss
            bIsInFirstPhase = false
        end
    else  -- highest HP
        uNextBoss = GetHighestPrimeUnit()
    end

    return uNextBoss
end

local function DrawDigitizeLines(position) 
    DrawLine(position, Coords[position][1], Coords[position][8], "Red")
    DrawLine(position, Coords[position][2], Coords[position][9], "Blue")
    DrawLine(position, Coords[position][3], Coords[position][9], "Blue")
    DrawLine(position, Coords[position][4], Coords[position][10], "Yellow")
    DrawLine(position, Coords[position][5], Coords[position][10], "Yellow")
    DrawLine(position, Coords[position][6], Coords[position][11], "White")
    DrawLine(position, Coords[position][7], Coords[position][11], "White")
end

local function DrawLine(position, vFrom, vTo, color)
    core:AddWorldLine(position .. vFrom.name .. position .. vTo.name, Vector3.New(vFrom.x, yCoord, vFrom.z), Vector3.New(vTo.x, yCoord, vTo.z), color, 2)
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_DEL", "OnDebuffRemoved", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    -- reset and draw a marker for the safe zone
    core:SetWorldMarker("SAFE_ZONE_WEST", "SafeZone", SAFE_ZONE_WEST) 
    core:SetWorldMarker("SAFE_ZONE_EAST", "SafeZone", SAFE_ZONE_EAST)
    core:SetWorldMarker("SAFE_ZONE_NORTH", "SafeZone", SAFE_ZONE_NORTH)

    -- Watch debuff on everyone
    core:RaidDebuff()

    tPrimeUnits = {}
    tLinesDrew = {}

    uLaser = nil
    uNorthBoss = nil
    uWestBoss = nil
    uEastBoss = nil
    uNextBoss = nil

    bIsInFirstPhase = true

    -- Draw lines for the three bosses
    DrawDigitizeLines(NORTH)
    DrawDigitizeLines(EAST)
    DrawDigitizeLines(WEST)
end

-- This is a stupid because there are 3 unit LASER in the room.
-- The 1st is one friendly (to click on it to activate hardmode but do nothing)
-- The 2nd is invisible and sticks around all the time, doesn't rotate
-- The 3rd is the real that spawns when you start the encounter
-- The Proper way to detect the true laser is to check if it cast "Incinerate (something like that)"
-- at the beginning of the fight (but I don't know if it possible to detect cast from units that 
-- are not in combat yet)
local uFakeLaser
function mod:OnUnitCreated(unit)
    if unit:GetName() == self.L["Organic Incinerator"] and not uLaser then
        if unit:GetDispositionTo(GetPlayerUnit) == Unit.CodeEnumDisposition.Hostile then -- remove 1st
            if not uFakeLaser then
                uFakeLaser = unit -- remove 2nd
            elseif uFakeLaser ~= unit then    
                uLaser = unit -- get 3rd the right one
                core:AddPixie("laserRed", 2, uLaser, nil, "Red", 10, 65, 0)
            end
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat)
    if bInCombat then
        sName = unit:GetName()
        if sName == self.L["Prime Evolutionary Operant"] then
            AddPrimeUnit(unit)
            core:AddUnit(unit)
            core:WatchUnit(unit)
            local tPosition = unit:GetPosition()
            if tPosition.x < ORGANIC_INCINERATOR.x then
                uWestBoss = unit
                core:MarkUnit(unit, 51, "W")
            else
                uEastBoss = unit
                core:MarkUnit(unit, 51, "E")
            end
        elseif sName == self.L["Prime Phage Distributor"] then
            AddPrimeUnit(unit)
            uNorthBoss = unit
            core:AddUnit(unit)
            core:MarkUnit(unit, 51, "N")
            core:WatchUnit(unit)
            mod:AddTimerBar("NEXT_IRRADIATE", "~Next irradiate", 27, true)
        elseif sName == self.L["Organic Incinerator"] and not uLaser then
            uLaser = unit
            core:AddPixie("laserRed", 2, uLaser, nil, "Red", 10, 65, 0)
        end
    end
end

function mod:OnHealthChanged(sName, nHealth)
    if sName == self.L["Prime Phage Distributor"] then
        if nHealth <= 64 and nHealth >= 60 then
            core:AddMsg("Push soon", self.L["PUSH SOON !"], 5,  mod:GetSetting("SoundPhase2", "Algalon"))
        elseif nHealth <= 24 and nHealth >= 20 then
            core:AddMsg("Push soon", self.L["PUSH SOON !"], 5,  mod:GetSetting("SoundPhase2", "Algalon"))
        end
    end
end

function mod:OnDebuffApplied(nId, nSpellId, nStack, fTimeRemaining)
    if nSpellId == DEBUFF_DEGENERATION then
        if GetPlayerUnit:GetId() == nId then
            core:DropPixie("laserRed")
            core:AddPixie("laserGreen", 2, uLaser, nil, "LightGreen", 10, 65, 0)
            self:ScheduleTimer("LaserInterruptTimer", 5)
        end
    elseif nSpellId == DEBUFF_STRAIN_INCUBATION then
        local uPlayerDebuff = GetUnitById(nId)
        core:MarkUnit(uPlayerDebuff, 51, "U")
    elseif nSpellId == DEBUFF_RADIATION_BATH then
        core:AddMsg("RADIATION_BATH", string.format(self.L["Radiation Bath on %s"], GetPlayerUnit:GetName()), 5, "RunAway", "Blue") 
    end
end

function mod:OnDebuffRemoved(nId, nSpellId, nStack, fTimeRemaining)
    if nSpellId == DEBUFF_STRAIN_INCUBATION then
        core:DropMark(nId)
    end
end

function mod:OnChatDC(message)
    local sPlayerNameIrradiate = message:match(self.L["(.*) is being irradiated"])
    if sPlayerNameIrradiate then
        mod:AddTimerBar("NEXT_IRRADIATE", "~Next irradiate", 26, true)
    elseif message == self.L["ENGAGING TECHNOPHAGE TRASMISSION"] then
        mod:AddTimerBar("NEXT_IRRADIATE", "~Next irradiate", 40, true)
        local uNext = GetNextBoss()
        core:AddPixie("nextBoss", 1, GetPlayerUnit, uNext, "Blue", 10)
        self:ScheduleTimer("NextBossLineTimer", 10)
    end
end

function mod:LaserInterruptTimer()
    core:DropPixie("laserGreen")
    core:AddPixie("laserRed", 2, uLaser, nil, "Red", 10, 65, 7)
end

function mod:NextBossLineTimer()
    core:DropPixie("nextBoss")
end