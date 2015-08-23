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
local mod = core:NewEncounter("EpFireWater", 52, 98, 118)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Hydroflux", "Pyrobane" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Pyrobane"] = "Pyrobane",
    ["Ice Tomb"] = "Ice Tomb",
    -- Cast.
    ["Flame Wave"] = "Flame Wave",
    -- Bar and messages.
    ["Fire Bomb"] = "Fire",
    ["Frost Bomb"] = "Frost",
    ["BOMBS"] = "BOMBS",
    ["BOMBS UP !"] = "BOMBS UP !",
    ["Bomb Explosion"] = "Bomb Explosion",
    ["ICE TOMB"] = "ICE TOMB",
    ["%d STACKS!"] = "%d STACKS!",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Pyrobane"] = "Pyromagnus",
    ["Ice Tomb"] = "Tombeau de glace",
    -- Cast.
    ["Flame Wave"] = "Vague de feu",
    -- Bar and messages.
    ["Fire Bomb"] = "Feu",
    ["Frost Bomb"] = "Givre",
    ["BOMBS"] = "BOMBES",
    --["BOMBS UP !"] = "BOMBS UP !", -- TODO: French translation missing !!!!
    ["Bomb Explosion"] = "Bombe Explosion",
    ["ICE TOMB"] = "TOMBEAU DE GLACE",
    ["%d STACKS!"] = "%d STACKS!",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Pyrobane"] = "Pyroman",
    ["Ice Tomb"] = "Eisgrab",
    -- Cast.
    ["Flame Wave"] = "Flammenwelle",
    -- Bar and messages.
    --["Fire Bomb"] = "Fire", -- TODO: German translation missing !!!!
    --["Frost Bomb"] = "Frost", -- TODO: German translation missing !!!!
    --["BOMBS"] = "BOMBS", -- TODO: German translation missing !!!!
    --["BOMBS UP !"] = "BOMBS UP !", -- TODO: German translation missing !!!!
    ["Bomb Explosion"] = "Bomb Explosion",
    ["ICE TOMB"] = "EISGRAB",
    ["%d STACKS!"] = "%d STACKS!",
})
-- Default settings.
mod:RegisterDefaultSetting("SoundBomb")
mod:RegisterDefaultSetting("SoundIceTomb")
mod:RegisterDefaultSetting("SoundHighDebuffStacks")
mod:RegisterDefaultSetting("OtherBombPlayerMarkers")
mod:RegisterDefaultSetting("LineBombPlayers")
mod:RegisterDefaultSetting("LineIceTomb")
mod:RegisterDefaultSetting("LineFlameWaves")
mod:RegisterDefaultSetting("LineCleaveHydroflux")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["TOMB"] = { sColor = "xkcdBrightLightBlue" },
    ["BOMBS"] = { sColor = "xkcdRed" },
    ["BEXPLODE"] = { sColor = "xkcdOrangered" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_ICE_TOMB = 74326
local DEBUFFID_FROSTBOMB = 75058
local DEBUFFID_FIREBOMB = 75059
local DEBUFFID_DRENCHED = 52874
local DEBUFFID_ENGULFED = 52876

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local nLastIceTombTime
local nLastBombTime
local tFireBombPlayersList
local tFrostBombPlayersList

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffAdd", self)
    Apollo.RegisterEventHandler("DEBUFF_UPDATE", "OnDebuffUpdate", self)
    Apollo.RegisterEventHandler("DEBUFF_DEL", "OnDebuffDel", self)

    nLastIceTombTime = 0
    nLastBombTime = 0
    tFireBombPlayersList = {}
    tFrostBombPlayersList = {}
    mod:AddTimerBar("BOMBS", "BOMBS", 30)
    mod:AddTimerBar("TOMB", "ICE TOMB", 26)
end

function mod:RemoveBombMarker(bomb_type, unit)
    if unit and unit:IsValid() then
        local sName = unit:GetName()
        local nId = unit:GetId()
        core:DropMark(nId)
        core:RemoveUnit(nId)
        if bomb_type == "fire" then
            tFireBombPlayersList[sName] = nil
            core:DropPixie(nId .. "_BOMB")
        elseif bomb_type == "frost" then
            tFrostBombPlayersList[sName] = nil
            core:DropPixie(nId .. "_BOMB")
        end
    end
end

function mod:ApplyBombLines(bomb_type)
    local tPlayerUnit = GetPlayerUnit()
    if bomb_type == "fire" then
        for key, value in pairs(tFrostBombPlayersList) do
            local unitId = value:GetId()
            if unitId then
                core:AddPixie(unitId .. "_BOMB", 1, tPlayerUnit, value, "Blue", 5, 10, 10)
            end
        end
    elseif bomb_type == "frost" then
        for key, value in pairs(tFireBombPlayersList) do
            local unitId = value:GetId()
            if unitId then
                core:AddPixie(unitId .. "_BOMB", 1, tPlayerUnit, value, "Red", 5, 10, 10)
            end
        end
    end
end

function mod:OnUnitCreated(unit, sName)
    local nId = unit:GetId()
    if sName == self.L["Hydroflux"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        if mod:GetSetting("LineCleaveHydroflux") then
            core:AddPixie(nId .. "_1", 2, unit, nil, "Yellow", 3, 7, 0)
            core:AddPixie(nId .. "_2", 2, unit, nil, "Yellow", 3, 7, 180)
        end
    elseif sName == self.L["Pyrobane"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif sName == self.L["Ice Tomb"] then
        local nCurrentTime = GetGameTime()
        if nCurrentTime - nLastIceTombTime > 13 then
            nLastIceTombTime = nCurrentTime
            mod:AddMsg("TOMB", "ICE TOMB", 5, mod:GetSetting("SoundIceTomb") and "Alert", "Blue")
            mod:AddTimerBar("TOMB", "ICE TOMB", 15)
        end
        core:AddUnit(unit)
    elseif sName == self.L["Flame Wave"] and mod:GetSetting("LineFlameWaves") then
        core:AddPixie(nId, 2, unit, nil, "Green", 10, 20, 0)
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Flame Wave"] then
        local unitId = unit:GetId()
        if unitId then
            core:DropPixie(unitId)
        end
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    local sUnitName = tUnit:GetName()

    if nSpellId == DEBUFFID_FIREBOMB then
        if mod:GetSetting("OtherBombPlayerMarkers") then
            core:MarkUnit(tUnit, nil, self.L["Fire Bomb"])
        end
        core:AddUnit(tUnit)
        tFireBombPlayersList[sUnitName] = tUnit
        if tUnit == GetPlayerUnit() then
            mod:AddMsg("BOMB", "BOMBS UP !", 5, mod:GetSetting("SoundBomb") and "RunAway")
            if mod:GetSetting("LineBombPlayers") then
                self:ScheduleTimer("ApplyBombLines", 1, "fire")
            end
        end
        self:ScheduleTimer("RemoveBombMarker", 10, "fire", tUnit)
    elseif nSpellId == DEBUFFID_FROSTBOMB then
        if mod:GetSetting("OtherBombPlayerMarkers") then
            core:MarkUnit(tUnit, nil, self.L["Frost Bomb"])
        end
        core:AddUnit(tUnit)
        tFrostBombPlayersList[sUnitName] = tUnit
        if tUnit == GetPlayerUnit() then
            mod:AddMsg("BOMB", "BOMBS UP !", 5, mod:GetSetting("SoundBomb") and "RunAway")
            if mod:GetSetting("LineBombPlayers") then
                self:ScheduleTimer("ApplyBombLines", 1, "frost")
            end
        end
        self:ScheduleTimer("RemoveBombMarker", 10, "frost", tUnit)
    elseif nSpellId == DEBUFFID_ICE_TOMB then
        if mod:GetSetting("LineIceTomb") and self:GetDistanceBetweenUnits(GetPlayerUnit(), tUnit) < 45 then
            core:AddPixie(nId .. "_TOMB", 1, GetPlayerUnit(), tUnit, "Blue", 5, 10, 10)
        end
    end

    if nSpellId == DEBUFFID_FIREBOMB or nSpellId == DEBUFFID_FROSTBOMB then
        local nCurrentTime = GetGameTime()
        if nCurrentTime - nLastBombTime > 10 then
            nLastBombTime = nCurrentTime
            mod:AddTimerBar("BOMBS", "BOMBS", 30)
            mod:AddTimerBar("BEXPLODE", "Bomb Explosion", 10, mod:GetSetting("SoundBomb"))
        end
    end
end

function mod:OnDebuffUpdate(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)

    if nSpellId == DEBUFFID_DRENCHED or nSpellId == DEBUFFID_ENGULFED then
        if (self:Tank() and nStack == 13) or (not self:Tank() and nStack == 10) then
            if tUnit == GetPlayerUnit() then
                local sMessage = self.L["%d STACKS!"]:format(nStack)
                mod:AddMsg("STACK", sMessage, 5, mod:GetSetting("SoundHighDebuffStacks") and "Beware")
            end
        end
    end
end

function mod:OnDebuffDel(nId, nSpellId)
    local tUnit = GetUnitById(nId)

    if nSpellId == DEBUFFID_FIREBOMB then
        mod:RemoveBombMarker("fire", tUnit)
    elseif nSpellId == DEBUFFID_FROSTBOMB then
        mod:RemoveBombMarker("frost", tUnit)
    elseif nSpellId == DEBUFFID_ICE_TOMB then
        core:DropPixie(nId .. "_TOMB")
    end
end
