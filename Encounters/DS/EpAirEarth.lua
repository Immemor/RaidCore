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
local mod = core:NewEncounter("EpAirEarth", 52, 98, 117)
if not mod then return end

local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
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
    ["Fierce Swipe"] = "Fierce Swipe",
    -- Bar and messages.
    ["EARTH"] = "EARTH",
    ["~Tornado Spawn"] = "~Tornado Spawn",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Megalith"] = "Mégalithe",
    ["Aileron"] = "Ventemort",
    ["Air Column"] = "Colonne d'air",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "Le sol tremble sous les pieds de Mégalithe !",
    ["fractured crust leaves it exposed"] = "La croûte fracturée de Mégalithe le rend vulnérable !",
    -- Cast.
    ["Supercell"] = "Super-cellule",
    ["Raw Power"] = "Énergie brute",
    ["Fierce Swipe"] = "Baffe féroce",
    -- Bar and messages.
    ["EARTH"] = "TERRE",
    ["~Tornado Spawn"] = "~Tornade Apparition",
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
    --["EARTH"] = "EARTH", -- TODO: German translation missing !!!!
    --["~Tornado Spawn"] = "~Tornado Spawn", -- TODO: German translation missing !!!!
})
-- Default settings.
mod:RegisterDefaultSetting("LineTornado")
mod:RegisterDefaultSetting("LineCleaveAileron")
mod:RegisterDefaultSetting("SoundTornadoCountDown")
mod:RegisterDefaultSetting("SoundMidphase")
mod:RegisterDefaultSetting("SoundSupercell")
mod:RegisterDefaultSetting("SoundQuakeJump")
mod:RegisterDefaultSetting("SoundMoO")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["SUPERCELL"] = { sColor = "xkcdBlueBlue" },
    ["TORNADO"] = { sColor = "xkcdBrightSkyBlue" },
    ["RAWPOWER"] = { sColor = "xkcdBrownishRed" },
    ["FIERCE_SWIPE"] = { sColor = "xkcdBurntYellow" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local nStartTime, nRefTime = 0, 0
local bMidPhase = false

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    local nTime = GetGameTime()
    nStartTime = nTime
    nRefTime = nTime
    bMidPhase = false

    mod:AddTimerBar("SUPERCELL", "Supercell", 65, mod:GetSetting("SoundSupercell"))
    mod:AddTimerBar("TORNADO", "~Tornado Spawn", 16, mod:GetSetting("SoundTornadoCountDown"))
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Megalith"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        core:MarkUnit(unit, nil, self.L["EARTH"])
    elseif sName == self.L["Aileron"] then
        if mod:GetSetting("LineCleaveAileron") then
            core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 15, 0)
        end
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif sName == self.L["Air Column"] then
        if mod:GetSetting("LineTornado") then
            core:AddLine(unit:GetId(), 2, unit, nil, 3, 30, 0, 10)
        end
        if GetGameTime() > nStartTime + 10 then
            mod:AddTimerBar("TORNADO", "~Tornado Spawn", 17, mod:GetSetting("SoundTornadoCountDown"))
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Air Column"] then
        core:DropLine(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Megalith"] then
        if castName == self.L["Raw Power"] then
            bMidPhase = true
            core:AddMsg("RAW", self.L["Raw Power"]:upper(), 5, mod:GetSetting("SoundMidphase") and "Alert")
        elseif castName == self.L["Fierce Swipe"] then
            mod:AddTimerBar("FIERCE_SWIPE", "Fierce Swipe", 16.5)
        end
    elseif unitName == self.L["Aileron"] then
        if castName == self.L["Supercell"] then
            local timeOfEvent = GetGameTime()
            if timeOfEvent - nRefTime > 30 then
                nRefTime = timeOfEvent
                core:AddMsg("SUPERCELL", self.L["Supercell"]:upper(), 5, mod:GetSetting("SoundSupercell") and "Alarm")
                mod:AddTimerBar("SUPERCELL", "Supercell", 80)
            end
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The ground shudders beneath Megalith"]) then
        core:AddMsg("QUAKE", "JUMP !", 3, mod:GetSetting("SoundQuakeJump") and "Beware")
    elseif message:find(self.L["fractured crust leaves it exposed"]) and bMidPhase then
        bMidPhase = false
        mod:AddTimerBar("RAWPOWER", "Raw Power", 60, mod:GetSetting("SoundMidphase"))
    end
end
