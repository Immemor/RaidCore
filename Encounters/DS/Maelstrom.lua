--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("Maelstrom", 52, 98, 120)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Maelstrom Authority" })

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local stationCount = 0
local bossPos = {}
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Wind Wall"] = "Wind Wall",
    ["Avatus Hologram"] = "Avatus Hologram",
    ["Weather Station"] = "Weather Station",
    ["Maelstrom Authority"] = "Maelstrom Authority",
    -- Datachron messages.
    ["The platform trembles"] = "The platform trembles",
    -- Cast.
    ["Activate Weather Cycle"] = "Activate Weather Cycle",
    ["Ice Breath"] = "Ice Breath",
    ["Crystallize"] = "Crystallize",
    ["Typhoon"] = "Typhoon",
    -- Bar and messages.
    ["[%u] STATION: %s %s"] = "[%u] STATION: %s %s",
    ["[%u] STATION"] = "[%u] STATION",
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
    ["Avatus Hologram"] = "Hologramme d'Avatus",
    ["Weather Station"] = "Station météorologique",
    ["Maelstrom Authority"] = "Contrôleur du Maelstrom",
    -- Datachron messages.
    ["The platform trembles"] = "La plateforme tremble !",
    -- Cast.
    ["Activate Weather Cycle"] = "Activer cycle climatique",
    ["Ice Breath"] = "Souffle de glace",
    ["Crystallize"] = "Cristalliser",
    ["Typhoon"] = "Typhon",
    -- Bar and messages.
    ["[%u] STATION: %s %s"] = "[%u] STATION: %s %s",
    ["[%u] STATION"] = "[%u] STATION",
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
    --["Avatus Hologram"] = "Avatus Hologram", -- TODO: German translation missing !!!!
    ["Weather Station"] = "Wetterstation",
    ["Maelstrom Authority"] = "Mahlstromgewalt",
    -- Datachron messages.
    --["The platform trembles"] = "The platform trembles", -- TODO: German translation missing !!!!
    -- Cast.
    ["Activate Weather Cycle"] = "Wetterzyklus aktivieren",
    ["Ice Breath"] = "Eisatem",
    ["Crystallize"] = "Kristallisieren",
    ["Typhoon"] = "Taifun",
    -- Bar and messages.
    --["[%u] STATION: %s %s"] = "[%u] STATION: %s %s", -- TODO: German translation missing !!!!
    --["[%u] STATION"] = "[%u] STATION", -- TODO: German translation missing !!!!
    --["ICE BREATH"] = "ICE BREATH", -- TODO: German translation missing !!!!
    --["TYPHOON"] = "TYPHOON", -- TODO: German translation missing !!!!
    --["JUMP"] = "JUMP", -- TODO: German translation missing !!!!
    --["Encounter Start"] = "Encounter Start", -- TODO: German translation missing !!!!
    ["NORTH"] = "N",
    ["SOUTH"] = "S",
    ["EAST"] = "E",
    ["WEST"] = "W",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Wind Wall"] and mod:GetSetting("LineWindWalls") then
        core:AddPixie(unit:GetId().."_1", 2, unit, nil, "Green", 10, 20, 0)
        core:AddPixie(unit:GetId().."_2", 2, unit, nil, "Green", 10, 20, 180)
    elseif sName == self.L["Weather Station"] then
        local stationPos = unit:GetPosition()
        core:AddUnit(unit)
        if mod:GetSetting("LineWeatherStations") then
            local playerUnit = GameLib.GetPlayerUnit()
            core:AddPixie(unit:GetId(), 1, playerUnit, unit, "Blue", 5, 10, 10)
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    --Print(sName)
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
            stationCount = 0
            core:AddBar("STATION", self.L["[%u] STATION"]:format(stationCount + 1), 13)
        elseif castName == self.L["Ice Breath"] then
            core:AddMsg("BREATH", self.L["ICE BREATH"], 5, mod:GetSetting("SoundIcyBreath", "RunAway"))
        elseif castName == self.L["Crystallize"] then
            core:AddMsg("BREATH", self.L["ICE BREATH"], 5, mod:GetSetting("SoundCrystallize", "Beware"))
        elseif castName == self.L["Typhoon"] then
            core:AddMsg("BREATH", self.L["TYPHOON"], 5, mod:GetSetting("SoundTyphoon", "Beware"))
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The platform trembles"]) then
        core:AddBar("JUMP", self.L["JUMP"], 7, 14)
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Maelstrom Authority"] then
            bossPos = {}
            stationCount = 0
            core:AddUnit(unit)
            core:WatchUnit(unit)
            if mod:GetSetting("LineCleaveBoss") then
                core:AddPixie(unit:GetId(), 2, unit, nil, "Red", 10, 15, 0)
            end
        elseif sName == self.L["Weather Station"] then
            stationCount = stationCount + 1
            local station_name = "STATION" .. tostring(stationCount)

            local posStr = ""
            local stationPos = unit:GetPosition()
            if stationPos and bossPos then
                local text = self.L["[%u] STATION: %s %s"]:format(
                stationCount,
                (stationPos.z > bossPos.z) and self.L["SOUTH"] or self.L["NORTH"],
                (stationPos.x > bossPos.x) and self.L["EAST"] or self.L["WEST"])
                core:AddMsg(station_name, text, 5, mod:GetSetting("SoundWeatherStationSwitch", "Info"), "Blue")
            else
                local text = self.L["[%u] STATION"]:format(stationCount)
                core:AddMsg(station_name, text, 5, mod:GetSetting("SoundWeatherStationSwitch", "Info"), "Blue")
            end
            local text = self.L["[%u] STATION"]:format(stationCount + 1)
            core:AddBar(station_name, text, 10)
        end
    end
end
