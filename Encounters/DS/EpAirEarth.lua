--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("EpAirEarth", 52, 98, 117)
if not mod then return end

mod:RegisterTrigMob("ALL", { "Megalith", "Aileron" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Aileron"] = "Aileron",
    ["Air Column"] = "Air Column",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith",
    ["fractured crust leaves it exposed"] = "fractured crust leaves it exposed",
    -- Cast.
    ["Supercell"] = "Supercell",
    ["Raw Power"] = "Raw Power",
    -- Bar and messages.
    ["MOO !"] = "MOO !",
    ["EARTH"] = "EARTH",
    ["~Tornado Spawn"] = "~Tornado Spawn",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Megalith"] = "Mégalithe",
    ["Aileron"] = "Ventemort",
    ["Air Column"] = "Colonne d'air",
    -- Datachron messages.
    --["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith", -- TODO: French translation missing !!!!
    --["fractured crust leaves it exposed"] = "fractured crust leaves it exposed", -- TODO: French translation missing !!!!
    -- Cast.
    ["Supercell"] = "Super-cellule",
    ["Raw Power"] = "Puissance brute",
    -- Bar and messages.
    --["MOO !"] = "MOO !", -- TODO: French translation missing !!!!
    --["EARTH"] = "EARTH", -- TODO: French translation missing !!!!
    --["~Tornado Spawn"] = "~Tornado Spawn", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Aileron"] = "Aileron",
    ["Air Column"] = "Luftsäule",
    -- Datachron messages.
    --["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith", -- TODO: German translation missing !!!!
    --["fractured crust leaves it exposed"] = "fractured crust leaves it exposed", -- TODO: German translation missing !!!!
    -- Cast.
    ["Supercell"] = "Superzelle",
    ["Raw Power"] = "Rohe Kraft",
    -- Bar and messages.
    --["MOO !"] = "MOO !", -- TODO: German translation missing !!!!
    --["EARTH"] = "EARTH", -- TODO: German translation missing !!!!
    --["~Tornado Spawn"] = "~Tornado Spawn", -- TODO: German translation missing !!!!
})

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local midphase = false
local startTime

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
    local eventTime = GameLib.GetGameTime()
    if sName == self.L["Air Column"] then
        if mod:GetSetting("LineTornado") then
            core:AddLine(unit:GetId(), 2, unit, nil, 3, 30, 0, 10)
        end
        if eventTime > startTime + 10 then
            core:StopBar("TORNADO")
            core:AddBar("TORNADO", self.L["~Tornado Spawn"], 17, mod:GetSetting("SoundTornadoCountdown"))
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    local sName = unit:GetName()
    if sName == self.L["Air Column"] then
        core:DropLine(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Megalith"] and castName == self.L["Raw Power"] then
        midphase = true
        core:AddMsg("RAW", self.L["Raw Power"]:upper(), 5, mod:GetSetting("SoundMidphase", "Alert"))
    elseif unitName == self.L["Aileron"] and castName == self.L["Supercell"] then
        local timeOfEvent = GameLib.GetGameTime()
        if timeOfEvent - prev > 30 then
            prev = timeOfEvent
            core:AddMsg("CELL", self.L["Supercell"]:upper(), 5, mod:GetSetting("SoundSupercell", "Alarm"))
            core:AddBar("CELL", self.L["Supercell"]:upper(), 80)
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The ground shudders beneath Megalith"]) then
        core:AddMsg("QUAKE", "JUMP !", 3, mod:GetSetting("SoundQuakeJump", "Beware"))
    elseif message:find(self.L["fractured crust leaves it exposed"]) and midphase then
        midphase = false
        core:AddMsg("MOO", self.L["MOO !"], 5, "Info", mod:GetSetting("SoundMoO", "Blue"))
        core:AddBar("RAW", self.L["Raw Power"]:upper(), 60, mod:GetSetting("SoundMidphase"))
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        local eventTime = GameLib.GetGameTime()
        startTime = eventTime

        if sName == self.L["Megalith"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:MarkUnit(unit, nil, self.L["EARTH"])
        elseif sName == self.L["Aileron"] then
            prev = 0
            midphase = false
            if mod:GetSetting("LineCleaveAileron") then
                core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 15, 0)
            end
            core:AddBar("SCELL", self.L["Supercell"], 65, mod:GetSetting("SoundSupercell"))
            core:AddBar("TORNADO", self.L["~Tornado Spawn"], 16, mod:GetSetting("SoundTornadoCountdown"))
            core:AddUnit(unit)
            core:WatchUnit(unit)
        end
    end
end
