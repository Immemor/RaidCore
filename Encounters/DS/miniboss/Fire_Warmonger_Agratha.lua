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
local mod = core:NewEncounter("WarmongerAgratha", 52, 98, 110)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Warmonger Agratha" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Warmonger Agratha"] = "Warmonger Agratha",
    ["Conjured Fire Bomb"] = "Conjured Fire Bomb",
    -- Cast.
    ["Conjure Fire Elementals"] = "Conjure Fire Elementals",
    ["Fire Room"] = "[DS] Fire Room - Osun (F) - Bubble Block (Target Selection)",
    -- Bar and messages.
    ["Safe Bubble"] = "Safe Bubble",
    ["Bombs"] = "Bombs",
    ["ELEMENTALS SOON"] = "ELEMENTALS SOON",
    ["FIRE ELEMENTALS"] = "FIRE ELEMENTALS",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Warmonger Agratha"] = "Guerroyeuse Agratha",
    ["Conjured Fire Bomb"] = "Bombe incendiaire invoquée",
    -- Cast.
    ["Conjure Fire Elementals"] = "Invocation d'Élémentaires de feu",
    ["Fire Room"] = "[DS] Fire Room - Osun (F) - Bubble Block (Target Selection)",
    -- Bar and messages.
    ["Safe Bubble"] = "Bulle Sûre",
    ["Bombs"] = "Bombes",
    ["ELEMENTALS SOON"] = "ÉLÉMENTAIRES BIENTÔT",
    ["FIRE ELEMENTALS"] = "ÉLÉMENTAIRES DE FEU",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Warmonger Agratha"] = "Kriegstreiberin Agratha",
    ["Conjured Fire Bomb"] = "Beschworene Feuerbombe",
    -- Cast.
    ["Conjure Fire Elementals"] = "Feuerelementare beschwören",
    -- Bar and messages.
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BOMBS"] = { sColor = "xkcdLightRed" },
    ["BUBBLE"] = { sColor = "xkcdBabyBlue" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID__DISORIENT = 49485

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local nPreviousBombPopDate, bIsFirstBomb
local bIsFirstFireRoom

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    nPreviousBombPopDate = 0
    bIsFirstBomb = true
    bIsFirstFireRoom = true
    mod:AddTimerBar("BOMBS", "Bombs", 8)
end

function mod:OnUnitCreated(nId, tUnit, sUnitName)
    if self.L["Warmonger Agratha"] == sUnitName then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    elseif self.L["Conjured Fire Bomb"] == sUnitName then
        if nPreviousBombPopDate + 8 < GetGameTime() then
            -- Second bomb have huge chance to be delayed by elemental cast.
            mod:AddTimerBar("BOMBS", "Bombs", bIsFirstBomb and 44 or 23)
            mod:AddMsg("BOMBS", "Bombs", 5, nil, "Blue")
            nPreviousBombPopDate = GetGameTime()
            bIsFirstBomb = false
        end
    end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
    if self.L["Warmonger Agratha"] == sName then
        if nPourcent == 67 or nPourcent == 34 then
            mod:AddMsg("ELEMENTALS", "ELEMENTALS SOON", 5)
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Warmonger Agratha"] == sName then
        if self.L["Conjure Fire Elementals"] == sCastName then
            mod:AddMsg("ELEMENTALS", "FIRE ELEMENTALS", 5)
        elseif self.L["Fire Room"] == sCastName then
            if bIsFirstFireRoom == false then
                core:PlaySound("Long")
            end
            bIsFirstFireRoom = false
        end
    end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
    if self.L["Warmonger Agratha"] == sName then
        if self.L["Fire Room"] == sCastName then
            mod:AddTimerBar("BUBBLE", "Safe Bubble", 50, true)
        end
    end
end
