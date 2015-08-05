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
local mod = core:NewEncounter("WarmongerTalarii", 52, 98, 110)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Warmonger Talarii" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Warmonger Talarii"] = "Warmonger Talarii",
    ["Conjured Fire Bomb"] = "Conjured Fire Bomb",
    -- Cast.
    ["Incineration"] = "Incineration",
    ["Conjure Fire Elementals"] = "Conjure Fire Elementals",
    ["Fire Room"] = "[DS] Fire Room - Osun (F) - Bubble Block (Target Selection)",
    -- Bar and messages.
    ["INTERRUPT !"] = "INTERRUPT !",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["Safe Bubble"] = "Safe Bubble",
    ["Bombs"] = "Bombs",
    ["ELEMENTALS SOON"] = "ELEMENTALS SOON",
    ["FIRE ELEMENTALS"] = "FIRE ELEMENTALS",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Warmonger Talarii"] = "Guerroyeuse Talarii",
    ["Conjured Fire Bomb"] = "Bombe incendiaire invoquée",
    -- Cast.
    ["Incineration"] = "Incinération",
    ["Conjure Fire Elementals"] = "Invocation d'Élémentaires de feu",
    ["Fire Room"] = "[DS] Fire Room - Osun (F) - Bubble Block (Target Selection)",
    -- Bar and messages.
    ["INTERRUPT !"] = "INTERROMPRE !",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["Safe Bubble"] = "Bulle Sûre",
    ["Bombs"] = "Bombes",
    ["ELEMENTALS SOON"] = "ÉLÉMENTAIRES BIENTÔT",
    ["FIRE ELEMENTALS"] = "ÉLÉMENTAIRES DE FEU",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Warmonger Talarii"] = "Kriegstreiberin Talarii",
    ["Conjured Fire Bomb"] = "Beschworene Feuerbombe",
    -- Cast.
    ["Incineration"] = "Lodernde Flammen",
    ["Conjure Fire Elementals"] = "Feuerelementare beschwören",
    -- Bar and messages.
    ["KNOCKBACK"] = "RÜCKSTOß",
})
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BOMBS"] = { sColor = "xkcdLightRed" },
    ["BUBBLE"] = { sColor = "xkcdBabyBlue" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local nPreviousBombPopTime
local bIsFirstFireRoom

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)

    nPreviousBombPopTime = 0
    bIsFirstFireRoom = true
    mod:AddTimerBar("KNOCK", self.L["KNOCKBACK"], 23)
end

function mod:OnUnitCreated(tUnit, sUnitName)
    if self.L["Warmonger Talarii"] == sUnitName then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    elseif self.L["Conjured Fire Bomb"] == sUnitName then
        local nCurrentTime = GetGameTime()
        if nPreviousBombPopTime + 8 < nCurrentTime then
            core:AddMsg("BOMB", self.L["BOMB"], 5, nil, "Blue")
            mod:AddTimerBar("BOMB", self.L["BOMB"], 23)
            nPreviousBombPopTime = nCurrentTime
        end
    end
end

function mod:OnHealthChanged(sUnitName, nHealth)
    if self.L["Warmonger Talarii"] == sUnitName then
        if nHealth == 67 or nHealth == 34 then
            core:AddMsg("ELEMENTALS", self.L["ELEMENTALS SOON"], 5, "Info")
        end
    end
end

function mod:OnSpellCastStart(sUnitName, sCastName, tUnit)
    if self.L["Warmonger Talarii"] == sUnitName then
        if self.L["Incineration"] == sCastName then
            core:AddMsg("KNOCK", self.L["INTERRUPT !"], 5, "Alert")
            mod:AddTimerBar("KNOCK", self.L["KNOCKBACK"], 29)
        elseif self.L["Conjure Fire Elementals"] == sCastName then
            core:AddMsg("ELEMENTALS", self.L["ELEMENTALS"], 5)
        elseif self.L["Fire Room"] == sCastName then
            if bIsFirstFireRoom == false then
                core:PlaySound("Long")
            end
            bIsFirstFireRoom = false
        end
    end
end

function mod:OnSpellCastEnd(sUnitName, sCastName, tUnit)
    if self.L["Warmonger Talarii"] == sUnitName then
        if self.L["Fire Room"] == sCastName then
            mod:AddTimerBar("BUBBLE", self.L["Safe Bubble"], 50, true)
        end
    end
end
