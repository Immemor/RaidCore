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
local mod = core:NewEncounter("Maelstrom", 52, 98, 120)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Maelstrom Authority" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Wind Wall"] = "Wind Wall",
    ["Weather Station"] = "Weather Station",
    ["Maelstrom Authority"] = "Maelstrom Authority",
    -- Datachron messages.
    ["The platform trembles"] = "The platform trembles",
    -- Cast.
    ["Activate Weather Cycle"] = "Activate Weather Cycle",
    ["Ice Breath"] = "Ice Breath",
    ["Crystallize"] = "Crystallize",
    ["Typhoon"] = "Typhoon",
    -- Timer bars.
    ["Next stations"] = "Next stations",
    -- Message bars.
    ["STATION: %s %s"] = "STATION: %s %s",
    ["STATION"] = "STATION",
    ["ICE BREATH"] = "ICE BREATH",
    ["TYPHOON"] = "TYPHOON",
    ["JUMP"] = "JUMP",
    ["Encounter Start"] = "Encounter Start",
    ["NORTH"] = "NORTH",
    ["SOUTH"] = "SOUTH",
    ["EAST"] = "EAST",
    ["WEST"] = "WEST",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Wind Wall"] = "Mur de vent",
    ["Weather Station"] = "Station météorologique",
    ["Maelstrom Authority"] = "Contrôleur du Maelstrom",
    -- Datachron messages.
    ["The platform trembles"] = "La plateforme tremble !",
    -- Cast.
    ["Activate Weather Cycle"] = "Activer cycle climatique",
    ["Ice Breath"] = "Souffle de glace",
    ["Crystallize"] = "Cristalliser",
    ["Typhoon"] = "Typhon",
    -- Timer bars.
    ["Next stations"] = "Prochaine stations",
    -- Message bars.
    ["STATION: %s %s"] = "STATION: %s %s",
    ["STATION"] = "STATION",
    ["ICE BREATH"] = "SOUFFLE DE GLACE",
    ["TYPHOON"] = "TYPHON",
    ["JUMP"] = "SAUTER",
    ["Encounter Start"] = "Début de la Rencontre",
    ["NORTH"] = "NORD",
    ["SOUTH"] = "SUD",
    ["EAST"] = "EST",
    ["WEST"] = "OUEST",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Wind Wall"] = "Windwand",
    ["Weather Station"] = "Wetterstation",
    ["Maelstrom Authority"] = "Mahlstromgewalt",
    -- Datachron messages.
    -- Cast.
    ["Activate Weather Cycle"] = "Wetterzyklus aktivieren",
    ["Ice Breath"] = "Eisatem",
    ["Crystallize"] = "Kristallisieren",
    ["Typhoon"] = "Taifun",
    -- Timer bars.
    -- Message bars.
    ["NORTH"] = "N",
    ["SOUTH"] = "S",
    ["EAST"] = "E",
    ["WEST"] = "W",
})
-- Default settings.
mod:RegisterDefaultSetting("LineWindWalls")
mod:RegisterDefaultSetting("LineWeatherStations")
mod:RegisterDefaultSetting("LineCleaveBoss")
mod:RegisterDefaultSetting("SoundIceBreath")
mod:RegisterDefaultSetting("SoundCrystallize")
mod:RegisterDefaultSetting("SoundTyphoon")
mod:RegisterDefaultSetting("SoundWeatherStationSwitch")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["STATION"] = { sColor = "xkcdOrangeYellow" },
    ["JUMP"] = { sColor = "xkcdSunYellow" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local prev = 0
local nStationCount = 0
local bossPos

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnEnteredCombat", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    bossPos = {}
    nStationCount = 0
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Maelstrom Authority"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        if mod:GetSetting("LineCleaveBoss") then
            core:AddPixie(unit:GetId(), 2, unit, nil, "Red", 10, 15, 0)
        end
    elseif sName == self.L["Weather Station"] then
        core:AddUnit(unit)
        if mod:GetSetting("LineWeatherStations") then
            core:AddPixie(unit:GetId(), 1, GetPlayerUnit(), unit, "Blue", 5, 10, 10)
        end
    elseif sName == self.L["Wind Wall"] then
        if mod:GetSetting("LineWindWalls") then
            core:AddPixie(unit:GetId().."_1", 2, unit, nil, "Green", 10, 20, 0)
            core:AddPixie(unit:GetId().."_2", 2, unit, nil, "Green", 10, 20, 180)
        end
    end
end

function mod:OnEnteredCombat(tUnit, bInCombat, sName)
    if bInCombat then
        if sName == self.L["Weather Station"] then
            mod:AddTimerBar("STATION", "Next stations", 25)
            nStationCount = nStationCount + 1
            local tStationPos = tUnit:GetPosition()
            local sMessage = "STATION"
            if tStationPos and bossPos then
                local sAxeZ = tStationPos.z > bossPos.z and self.L["SOUTH"] or self.L["NORTH"]
                local sAxeX = tStationPos.x > bossPos.x and self.L["EAST"] or self.L["WEST"]
                sMessage = self.L["STATION: %s %s"]:format(sAxeZ, sAxeX)
            end
            local sKey = "STATION" .. tostring(nStationCount)
            local sSoundFile = mod:GetSetting("SoundWeatherStationSwitch") and "Info"
            mod:AddMsg(sKey, sMessage, 5, sSoundFile, "Blue")
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Wind Wall"] then
        core:DropPixie(unit:GetId().."_1")
        core:DropPixie(unit:GetId().."_2")
    elseif sName == self.L["Weather Station"] then
        core:DropPixie(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Maelstrom Authority"] then
        if castName == self.L["Activate Weather Cycle"] then
            bossPos = unit:GetPosition()
            nStationCount = 0
            mod:AddTimerBar("STATION", "Next stations", 13)
        elseif castName == self.L["Ice Breath"] then
            mod:AddMsg("BREATH", "ICE BREATH", 5, mod:GetSetting("SoundIceBreath") and "RunAway")
        elseif castName == self.L["Crystallize"] then
            mod:AddMsg("BREATH", "ICE BREATH", 5, mod:GetSetting("SoundCrystallize") and "Beware")
        elseif castName == self.L["Typhoon"] then
            mod:AddMsg("BREATH", "TYPHOON", 5, mod:GetSetting("SoundTyphoon") and "Beware")
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The platform trembles"]) then
        mod:RemoveTimerBar("STATION")
        mod:AddTimerBar("JUMP", "JUMP", 7, true)
    end
end
