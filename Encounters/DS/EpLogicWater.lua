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
local mod = core:NewEncounter("EpLogicWater", 52, 98, 118)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Hydroflux", "Mnemesis" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Mnemesis"] = "Mnemesis",
    ["Hydroflux"] = "Hydroflux",
    ["Alphanumeric Hash"] = "Alphanumeric Hash",
    ["Hydro Disrupter - DNT"] = "Hydro Disrupter - DNT",
    -- Datachron messages.
    ["Time to die, sapients!"] = "Time to die, sapients!",
    -- Cast.
    ["Circuit Breaker"] = "Circuit Breaker",
    ["Imprison"] = "Imprison",
    ["Defragment"] = "Defragment",
    ["Watery Grave"] = "Watery Grave",
    ["Tsunami"] = "Tsunami",
    -- Timer bars.
    ["Next defragment"] = "Next defragment",
    ["Next imprison"] = "Next imprison",
    ["Next Watery Grave"] = "Next watery grave",
    ["Next middle phase"] = "Next middle phase",
    ["Avatus incoming"] = "Avatus incoming",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["SPREAD"] = "SPREAD",
    ["ORB"] = "ORB",
    ["IA REMAINING %u"] = "IA REMAINING %u",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Mnemesis"] = "Mnémésis",
    ["Hydroflux"] = "Hydroflux",
    ["Alphanumeric Hash"] = "Alphanumeric Hash",
    ["Hydro Disrupter - DNT"] = "Hydro-disrupteur - DNT",
    -- Datachron messages.
    ["Time to die, sapients!"] = "Maintenant c'est l'heure de mourir, misérables !",
    -- Cast.
    ["Circuit Breaker"] = "Coupe-circuit",
    ["Imprison"] = "Emprisonner",
    ["Defragment"] = "Défragmentation",
    ["Watery Grave"] = "Tombe aqueuse",
    ["Tsunami"] = "Tsunami",
    -- Timer bars.
    ["Next defragment"] = "Prochaine defragmentation",
    ["Next Imprison"] = "Prochain emprisonner",
    ["Next Watery Grave"] = "Prochaine tombe aqueuse",
    ["Next middle phase"] = "Prochaine phase milieu",
    ["Avatus incoming"] = "Avatus arrivé",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["SPREAD"] = "SEPAREZ-VOUS",
    ["ORB"] = "ORB",
    ["IA REMAINING %u"] = "IA RESTANTE %u",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Mnemesis"] = "Mnemesis",
    ["Hydroflux"] = "Hydroflux",
    ["Alphanumeric Hash"] = "Alphanumerische Raute",
    -- Cast.
    ["Circuit Breaker"] = "Schaltkreiszerstörer",
    ["Imprison"] = "Einsperren",
    ["Defragment"] = "Defragmentieren",
    ["Watery Grave"] = "Seemannsgrab",
    -- Timer bars.
    -- Message bars.
})
-- Default settings.
mod:RegisterDefaultSetting("SoundDefrag")
mod:RegisterDefaultSetting("SoundDataDisruptorDebuff")
mod:RegisterDefaultSetting("SoundMidphaseCountDown")
mod:RegisterDefaultSetting("OtherWateryGraveTimer")
mod:RegisterDefaultSetting("OtherOrbMarkers")
mod:RegisterDefaultSetting("LineTetrisBlocks")
mod:RegisterDefaultSetting("LineOrbs")
mod:RegisterDefaultSetting("LineCleaveHydroflux")
mod:RegisterDefaultSetting("PolygonDefrag")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["MIDPHASE"] = { sColor = "xkcdAlgaeGreen" },
    ["PRISON"] = { sColor = "xkcdBluegreen" },
    ["GRAVE"] = { sColor = "xkcdDeepOrange" },
    ["DEFRAG"] = { sColor = "xkcdBarneyPurple" },
    ["AVATUS_INCOMING"] = { sColor = "xkcdAmethyst" },
    ["ENRAGE"] = { sColor = "xkcdBloodRed" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_DATA_DISRUPTOR = 78407

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local midphase = false

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    midphase = false
    mod:AddTimerBar("MIDPHASE", "Next middle phase", 75, mod:GetSetting("SoundMidphaseCountDown"))
    mod:AddTimerBar("PRISON", "Next Imprison", 33)
    mod:AddTimerBar("AVATUS_INCOMING", "Avatus incoming", 421)
    mod:AddTimerBar("DEFRAG", "Next defragment", 16, mod:GetSetting("SoundDefrag"))
    if mod:GetSetting("OtherWateryGraveTimer") then
        mod:AddTimerBar("GRAVE", "Next Watery Grave", 10)
    end
end

function mod:OnChatDC(message)
    if self.L["Time to die, sapients!"] == message then
        mod:RemoveTimerBar("AVATUS_INCOMING")
        mod:AddTimerBar("ENRAGE", "Enrage", 34)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Mnemesis"] then
        if castName == self.L["Circuit Breaker"] then
            midphase = true
            mod:RemoveTimerBar("PRISON")
            mod:RemoveTimerBar("DEFRAG")
            mod:AddTimerBar("MIDPHASE", "Circuit Breaker", 25, mod:GetSetting("SoundMidphaseCountDown"))
            local nArmorValue = unit:GetInterruptArmorValue()
            mod:AddMsg("IA", self.L["IA REMAINING %u"]:format(nArmorValue), 5, nil, "blue")
        elseif castName == self.L["Imprison"] then
            mod:RemoveTimerBar("PRISON")
        elseif castName == self.L["Defragment"] then
            mod:AddMsg("DEFRAG", "SPREAD", 3, mod:GetSetting("SoundDefrag") and "Alarm")
            mod:AddTimerBar("DEFRAG", "Next defragment", 36, mod:GetSetting("SoundDefrag"))
            if mod:GetSetting("PolygonDefrag") then
                core:AddPolygon("DEFRAG_SQUARE", GetPlayerUnit():GetId(), 13, 0, 4, "xkcdBloodOrange", 4)
                self:ScheduleTimer(function()
                    core:RemovePolygon("DEFRAG_SQUARE")
                end, 10)
            end
        end
    elseif unitName == self.L["Hydroflux"] then
        if castName == self.L["Watery Grave"] then
            if mod:GetSetting("OtherWateryGraveTimer") then
                mod:AddTimerBar("GRAVE", "Next Watery Grave", 10)
            end
        elseif self.L["Tsunami"] == castName then
            mod:RemoveTimerBar("GRAVE")
        end
    end
end

function mod:OnSpellCastEnd(unitName, castName)
    if unitName == self.L["Mnemesis"] then
        if castName == self.L["Circuit Breaker"] then
            midphase = false
            mod:AddTimerBar("MIDPHASE", "Next middle phase", 85, mod:GetSetting("SoundMidphaseCountDown"))
            mod:AddTimerBar("PRISON", "Next Imprison", 25)
        end
    end
end

function mod:OnDebuffApplied(unitName, splId, unit)
    if splId == DEBUFFID_DATA_DISRUPTOR then
        if unit == GetPlayerUnit() then
            if mod:GetSetting("SoundDataDisruptorDebuff") then
               core:PlaySound("Beware")
           end
        end
        if mod:GetSetting("OtherOrbMarkers") then
            core:MarkUnit(unit, nil, self.L["ORB"])
        end
    end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
    if splId == DEBUFFID_DATA_DISRUPTOR then
        local unitId = unit:GetId()
        if unitId then
            core:DropMark(unit:GetId())
        end
    end
end

function mod:OnUnitCreated(nId, unit, sName)
    local nHealth = unit:GetHealth()

    if sName == self.L["Alphanumeric Hash"] then
        if nId and mod:GetSetting("LineTetrisBlocks") then
            core:AddSimpleLine(nId, nId, 0, 20, 0, 10, "red")
        end
    elseif sName == self.L["Hydro Disrupter - DNT"] then
        if nId and not midphase and mod:GetSetting("LineOrbs") then
            core:AddLineBetweenUnits("Disrupter" .. nId, GetPlayerUnit():GetId(), nId, nil, "blue")
        end
    elseif sName == self.L["Hydroflux"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        if mod:GetSetting("LineCleaveHydroflux") then
            core:AddSimpleLine("HydroCleave", unit:GetId(), -7, 14, 0, 3, "xkcdOrangeYellow")
        end
    elseif sName == self.L["Mnemesis"] then
        if nHealth and nHealth > 0 then
            core:AddUnit(unit)
            core:WatchUnit(unit)
        end
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Alphanumeric Hash"] then
        core:RemoveSimpleLine(nId)
    elseif sName == self.L["Hydroflux"] then
        core:RemoveSimpleLine("HydroCleave")
    elseif sName == self.L["Hydro Disrupter - DNT"] then
        core:RemoveLineBetweenUnits("Disrupter" .. nId)
    end
end
