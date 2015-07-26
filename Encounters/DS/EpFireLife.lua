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
local mod = core:NewEncounter("EpFireLife", 52, 98, 119)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Visceralus", "Pyrobane" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Visceralus"] = "Visceralus",
    ["Pyrobane"] = "Pyrobane",
    ["Life Force"] = "Life Force",
    ["Essence of Life"] = "Essence of Life",
    ["Flame Wave"] = "Flame Wave",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blinding Light",
    -- Bar and messages.
    ["You are rooted"] = "You are rooted",
    ["MIDPHASE"] = "MIDPHASE",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Visceralus"] = "Visceralus",
    ["Pyrobane"] = "Pyromagnus",
    ["Life Force"] = "Force vitale",
    ["Essence of Life"] = "Essence de vie",
    ["Flame Wave"] = "Vague de feu",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Lumière aveuglante",
    -- Bar and messages.
    --["You are rooted"] = "You are rooted", -- TODO: French translation missing !!!!
    --["MIDPHASE"] = "MIDPHASE", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Visceralus"] = "Viszeralus",
    ["Pyrobane"] = "Pyroman",
    ["Life Force"] = "Lebenskraft",
    ["Essence of Life"] = "Lebensessenz",
    ["Flame Wave"] = "Flammenwelle",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blendendes Licht",
    -- Bar and messages.
    --["You are rooted"] = "You are rooted", -- TODO: German translation missing !!!!
    --["MIDPHASE"] = "MIDPHASE", -- TODO: German translation missing !!!!
})
-- Default settings.
mod:RegisterDefaultSetting("SoundRooted")
mod:RegisterDefaultSetting("SoundNoHealDebuff")
mod:RegisterDefaultSetting("SoundBlindingLight")
mod:RegisterDefaultSetting("OtherRootedPlayersMarkers")
mod:RegisterDefaultSetting("LineLifeOrbs")
mod:RegisterDefaultSetting("LineFlameWaves")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["MID"] = { sColor = "xkcdLightOrange" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_PRIMAL_ENTANGLEMENT1 = 73179 -- A root ability.
local DEBUFFID_PRIMAL_ENTANGLEMENT2 = 73177 -- A root ability.

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffAdd", self)
    Apollo.RegisterEventHandler("DEBUFF_DEL", "OnDebuffDel", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
end

function mod:OnUnitCreated(tUnit, sName)
    local nId = tUnit:GetId()
    if sName == self.L["Visceralus"] or sName == self.L["Pyrobane"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    elseif sName == self.L["Life Force"] then
        if mod:GetSetting("LineLifeOrbs") and nId then
            core:AddPixie(nId, 2, tUnit, nil, "Blue", 10, -40, 0)
        end
    elseif sName == self.L["Flame Wave"] then
        if mod:GetSetting("LineFlameWaves") and nId then
            core:AddPixie(nId, 2, tUnit, nil, "Green", 10, 20, 0)
        end
    end
end

function mod:OnUnitDestroyed(tUnit, sName)
    local nId = tUnit:GetId()
    if sName == self.L["Life Force"] then
        core:DropPixie(nId)
    elseif sName == self.L["Flame Wave"] then
        core:DropPixie(nId)
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    local tSpell = GameLib.GetSpell(splId)
    local strSpellName = tSpell:GetName()

    if nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT1 or nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT2 then
        if GetPlayerUnit():GetId() == nId then
            core:AddMsg("ROOT", self.L["You are rooted"], 5, mod:GetSetting("SoundRooted") and "Info")
        end
        if mod:GetSetting("OtherRootedPlayersMarkers") then
            core:MarkUnit(tUnit, nil, "ROOT")
            core:AddUnit(tUnit)
        end
    elseif strSpellName == "Life Force Shackle" then
        if GetPlayerUnit():GetId() == nId then
            core:AddMsg("NOHEAL", "No-Healing Debuff!", 5, mod:GetSetting("SoundNoHealDebuff") and "Alarm")
        end
    end
end

function mod:OnDebuffDel(nId, nSpellId)
    if nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT1 or nSpellId == DEBUFFID_PRIMAL_ENTANGLEMENT2 then
        core:DropMark(nId)
        core:RemoveUnit(nId)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Visceralus"] then
        if castName == self.L["Blinding Light"]
            and self:GetDistanceBetweenUnits(unit, GetPlayerUnit()) < 33 then
            core:AddMsg("BLIND", self.L["Blinding Light"], 5, mod:GetSetting("SoundBlindingLight") and "Beware")
        end
    end
end
