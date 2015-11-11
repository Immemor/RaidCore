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
local mod = core:NewEncounter("ExperimentX89", 67, 147, 148)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Experiment X-89" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Experiment X-89"] = "Experiment X-89",
    -- Datachron messages.
    ---- This entry is used with string.match, so the dash in X-89 needs to be escaped.
    ["Experiment X-89 has placed a bomb"] = "Experiment X%-89 has placed a bomb on (.*)!",
    -- Cast.
    ["Shattering Shockwave"] = "Shattering Shockwave",
    ["Repugnant Spew"] = "Repugnant Spew",
    ["Resounding Shout"] = "Resounding Shout",
    -- Timer bars.
    ["Big bomb on %s"] = "Big bomb on %s",
    ["Little bomb on %s"] = "Little bomb on %s",
    -- Message bars.
    ["KNOCKBACK"] = "KNOCKBACK",
    ["SPEW"] = "SPEW",
    ["SHOCKWAVE"] = "SHOCKWAVE",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Experiment X-89"] = "Expérience X-89",
    -- Datachron messages.
    ---- This entry is used with string.match, so the dash in X-89 needs to be escaped.
    ["Experiment X-89 has placed a bomb"] = "L'expérience X%-89 a posé une bombe sur (.*) !",
    -- Cast.
    ["Shattering Shockwave"] = "Onde de choc dévastatrice",
    ["Repugnant Spew"] = "Crachat répugnant",
    ["Resounding Shout"] = "Hurlement retentissant",
    -- Timer bars.
    ["Big bomb on %s"] = "Grosse bombe sur %s",
    ["Little bomb on %s"] = "Petite bombe sur %s",
    -- Message bars.
    ["KNOCKBACK"] = "KNOCKBACK",
    ["SPEW"] = "CRACHAT",
    ["SHOCKWAVE"] = "ONDE DE CHOC",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Experiment X-89"] = "Experiment X-89",
    -- Datachron messages.
    ---- This entry is used with string.match, so the dash in X-89 needs to be escaped.
    ["Experiment X-89 has placed a bomb"] = "Experiment X%-89 hat eine Bombe auf (.*)!",
    -- Cast.
    ["Shattering Shockwave"] = "Zerschmetternde Schockwelle",
    ["Repugnant Spew"] = "Widerliches Erbrochenes",
    ["Resounding Shout"] = "Widerhallender Schrei",
    -- Timer bars.
    -- Message bars.
    ["KNOCKBACK"] = "RÜCKSTOß",
    ["SPEW"] = "ERBROCHENES",
    ["SHOCKWAVE"] = "SCHOCKWELLE",
})
-- Default settings.
mod:RegisterDefaultSetting("LineExperimentX89")
mod:RegisterDefaultSetting("LineBigBomb")
mod:RegisterDefaultSetting("LineLittleBomb")
mod:RegisterDefaultSetting("PictureBigBomb")
mod:RegisterDefaultSetting("PictureLittleBomb")
mod:RegisterDefaultSetting("SoundLittleBomb")
mod:RegisterDefaultSetting("SoundBigBomb")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["LittleBomb"] = { sColor = "xkcdBottleGreen" },
    ["BigBomb"] = { sColor = "xkcdAubergine" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_LITTLE_BOMB = 47316
local DEBUFFID_BIG_BOMB = 47285

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local nExperimentX89Id

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    nExperimentX89Id = nil
end

function mod:OnUnitCreated(nId, tUnit, sName)
    if sName == self.L["Experiment X-89"] then
        nExperimentX89Id = nId
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        if mod:GetSetting("LineExperimentX89") then
            core:AddSimpleLine("Cleave", nExperimentX89Id, 0, 5, 0, 8, "green")
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sName == self.L["Experiment X-89"] then
        if sCastName == self.L["Resounding Shout"] then
            mod:AddMsg("KNOCKBACK", "KNOCKBACK", 3, "Alert")
        elseif sCastName == self.L["Repugnant Spew"] then
            mod:AddMsg("SPEW", "SPEW", 3, "Info")
        end
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local bIsItself = nId == GetPlayerUnit():GetId()

    if DEBUFFID_LITTLE_BOMB == nSpellId then
        local tUnit = GetUnitById(nId)
        local sText = self.L["Little bomb on %s"]:format(tUnit:GetName())
        if mod:GetSetting("LineLittleBomb") then
            local o = core:AddLineBetweenUnits("LittleBomb", nExperimentX89Id, nId, nil, "blue")
            o:SetMaxLengthVisible(40)
        end
        if mod:GetSetting("PictureLittleBomb") then
            core:AddPicture("LittleBomb", nId, "Crosshair", 20, 0, 0, nil, "blue")
        end
        mod:AddMsg("LittleBomb", sText:upper(), 3, nil, "blue")
        local bCountDownLittleBomb = mod:GetSetting("SoundLittleBomb") and bIsItself
        mod:AddTimerBar("LittleBomb", sText, fTimeRemaining - 1, bCountDownLittleBomb)
        if bIsItself then
            if mod:GetSetting("SoundLittleBomb") then
                core:PlaySound("RunAway")
            end
        end
    elseif DEBUFFID_BIG_BOMB == nSpellId then
        local tUnit = GetUnitById(nId)
        local sText = self.L["Big bomb on %s"]:format(tUnit:GetName())
        if mod:GetSetting("LineBigBomb") then
            local o = core:AddLineBetweenUnits("BigBomb", nExperimentX89Id, nId, nil, "red")
            o:SetMaxLengthVisible(40)
        end
        if mod:GetSetting("PictureBigBomb") then
            core:AddPicture("BigBomb", nId, "Crosshair", 40, 0, 0, nil, "red")
        end
        mod:AddMsg("BigBomb", sText:upper(), 3, nil, "red")
        local bCountDownBigBomb = mod:GetSetting("SoundBigBomb") and bIsItself
        mod:AddTimerBar("BigBomb", sText, fTimeRemaining - 2, bCountDownBigBomb)
        if bIsItself then
            if mod:GetSetting("SoundBigBomb") then
                core:PlaySound("RunAway")
            end
        end
    end
end

function mod:OnDebuffRemove(nId, nSpellId)
    if DEBUFFID_LITTLE_BOMB == nSpellId then
        core:RemovePicture("LittleBomb")
        core:RemoveLineBetweenUnits("LittleBomb")
    elseif DEBUFFID_BIG_BOMB == nSpellId then
        core:RemovePicture("BigBomb")
        core:RemoveLineBetweenUnits("BigBomb")
    end
end
