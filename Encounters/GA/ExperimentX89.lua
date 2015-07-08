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
    -- Bar and messages.
    ["KNOCKBACK !!"] = "KNOCKBACK !!",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["BEAM !!"] = "BEAM !!",
    ["BEAM"] = "BEAM",
    ["SHOCKWAVE"] = "SHOCKWAVE",
    ["BIG BOMB on %s"] = "BIG BOMB on %s",
    ["LITTLE BOMB on %s "] = "LITTLE BOMB on %s",
    ["LITTLE BOMB"] = "LITTLE BOMB",
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
    -- Bar and messages.
    ["KNOCKBACK !!"] = "KNOCKBACK !!",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["BEAM !!"] = "LASER !!",
    ["BEAM"] = "LASER",
    ["SHOCKWAVE"] = "ONDE DE CHOC",
    ["BIG BOMB on %s"] = "GROSSE BOMBE sur %s",
    ["LITTLE BOMB on %s "] = "PETITE BOMBE sur %s",
    ["LITTLE BOMB"] = "PETITE BOMBE",
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
    -- Bar and messages.
    ["KNOCKBACK !!"] = "RÜCKSTOß !!!",
    ["KNOCKBACK"] = "RÜCKSTOß",
    ["BEAM !!"] = "LASER !!",
    ["BEAM"] = "LASER",
    ["SHOCKWAVE"] = "SCHOCKWELLE",
    ["BIG BOMB on %s"] = "GROßE BOMBE auf %s",
    ["LITTLE BOMB on %s"] = "KLEINE BOMBE auf %s",
    ["LITTLE BOMB"] = "KLEINE BOMBE",
})
-- Default settings.
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF_LITTLE_BOMB = 47316

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffApplied", self)
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Experiment X-89"] then
        if castName == self.L["Resounding Shout"] then
            core:AddMsg("KNOCKBACK", self.L["KNOCKBACK !!"], 5, "Alert")
            core:AddBar("KNOCKBACK", self.L["KNOCKBACK"], 23)
        elseif castName == self.L["Repugnant Spew"] then
            core:AddMsg("BEAM", self.L["BEAM !!"], 5, "Alarm")
            core:AddBar("BEAM", self.L["BEAM"], 40)
        elseif castName == self.L["Shattering Shockwave"] then
            core:AddBar("SHOCKWAVE", self.L["SHOCKWAVE"], 19)
        end
    end
end

-- I think this could be done by using OnDebuffApplied with the 
-- spellId of the debuff. Would be better for performance.
function mod:OnChatDC(message)
    -- The dash in X-89 needs to be escaped, by adding a % in front of it.
    -- The value returned is the player name targeted by the boss.
    local sPlayerName = message:match(self.L["Experiment X-89 has placed a bomb"])
    if sPlayerName then
        core:AddMsg("BIGB", self.L["BIG BOMB on %s"]:format(sPlayerName), 5, "Destruction", "Blue")
    end
end

function mod:OnDebuffApplied(nId, nSpellId, nStack, fTimeRemaining)
    if nSpellId == DEBUFF_LITTLE_BOMB then
        local unit = GetUnitById(nId)
        core:AddMsg("LITTLEB", self.L["LITTLE BOMB on %s"]:format(unit:GetName()), fTimeRemaining, "RunAway", "Blue")
        core:AddBar("LITTLEB", self.L["LITTLE BOMB"], 5, 1)
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Experiment X-89"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:AddBar("KNOCKBACK", self.L["KNOCKBACK"], 6)
            core:AddBar("SHOCKWAVE", self.L["SHOCKWAVE"], 17)
            core:AddBar("BEAM", self.L["BEAM"], 36)
        end
    end
end
