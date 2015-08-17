----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--
--   The elemental Pair Megalith and Mnemesis juste after Maelstrom fight.
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("EpLogicEarth", 52, 98, 117)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Megalith", "Mnemesis" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Mnemesis"] = "Mnemesis",
    ["Obsidian Outcropping"] = "Obsidian Outcropping",
    ["Crystalline Matrix"] = "Crystalline Matrix",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith",
    ["Logic creates powerful data caches"] = "Logic creates powerful data caches",
    -- Cast.
    ["Defragment"] = "Defragment",
    -- Bar and messages.
    ["SNAKE ON %s"] = "SNAKE ON %s",
    ["DEFRAG"] = "DEFRAG",
    ["SPREAD"] = "SPREAD",
    ["BOOM"] = "BOOM",
    ["JUMP !"] = "JUMP !",
    ["STARS"] = "STARS%s"
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Megalith"] = "Mégalithe",
    ["Mnemesis"] = "Mnémésis",
    ["Obsidian Outcropping"] = "Affleurement d'obsidienne",
    ["Crystalline Matrix"] = "Matrice cristalline",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "Le sol tremble sous les pieds de Mégalithe !",
    ["Logic creates powerful data caches"] = "La logique crée de puissantes caches de données !",
    -- Cast.
    ["Defragment"] = "Défragmentation",
    -- Bar and messages.
    ["SNAKE ON %s"] = "SERPENT sur %s",
    ["DEFRAG"] = "DEFRAG",
    ["SPREAD"] = "ECARTER",
    ["BOOM"] = "BOOM",
    ["JUMP !"] = "SAUTEZ !",
    ["STARS"] = "Etoile%s"
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Mnemesis"] = "Mnemesis",
    --["Obsidian Outcropping"] = "Obsidian Outcropping", -- TODO: German translation missing !!!!
    ["Crystalline Matrix"] = "Kristallmatrix",
    -- Datachron messages.
    --["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith", -- TODO: German translation missing !!!!
    --["Logic creates powerful data caches"] = "Logic creates powerful data caches", -- TODO: German translation missing !!!!
    -- Cast.
    ["Defragment"] = "Defragmentieren",
    -- Bar and messages.
    --["SNAKE ON %s"] = "SNAKE ON %s", -- TODO: German translation missing !!!!
    --["DEFRAG"] = "DEFRAG", -- TODO: German translation missing !!!!
    --["SPREAD"] = "SPREAD", -- TODO: German translation missing !!!!
    --["BOOM"] = "BOOM", -- TODO: German translation missing !!!!
    --["JUMP !"] = "JUMP !", -- TODO: German translation missing !!!!
    --["STARS"] = "STARS%s" -- TODO: German translation missing !!!!
})
-- Default settings.
mod:RegisterDefaultSetting("LineObsidianOutcropping")
mod:RegisterDefaultSetting("SoundDefrag")
mod:RegisterDefaultSetting("SoundQuakeJump")
mod:RegisterDefaultSetting("SoundStars")
mod:RegisterDefaultSetting("SoundSnake")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BOOM"] = { sColor = "xkcdBloodRed" },
    ["DEFRAG"] = { sColor = "xkcdAlgaeGreen" },
    ["STAR"] = { sColor = "xkcdBlue" },
    ["SNAKE"] = { sColor = "xkcdBrickOrange" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local BUFF_MNEMESIS_INFORMATIC_CLOUD = 52571
local DEBUFF_SNAKE = 74570

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local nPreviousDefragmentTime

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffAdd", self)

    nPreviousDefragmentTime = 0
    mod:AddTimerBar("DEFRAG", "DEFRAG", 10)
    mod:AddTimerBar("STAR", self.L["STARS"]:format(""), 60)
end

function mod:OnUnitCreated(unit, sName)
    if self.L["Megalith"] == sName or self.L["Mnemesis"] == sName then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif sName == self.L["Obsidian Outcropping"] and mod:GetSetting("LineObsidianOutcropping") then
        core:AddPixie(unit:GetId().."_1", 1, GetPlayerUnit(), unit, "Blue", 10)
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Obsidian Outcropping"] then
        core:DropPixie(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Mnemesis"] then
        if castName == self.L["Defragment"] then
            local timeOfEvent = GetGameTime()
            if timeOfEvent - nPreviousDefragmentTime > 10 then
                nPreviousDefragmentTime = timeOfEvent
                mod:AddMsg("DEFRAG", "SPREAD", 5, mod:GetSetting("SoundDefrag") and "Alarm")
                mod:AddTimerBar("BOOM", "BOOM", 9)
                mod:AddTimerBar("DEFRAG", "DEFRAG", 40)
            end
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The ground shudders beneath Megalith"]) then
        mod:AddMsg("QUAKE", "JUMP !", 3, mod:GetSetting("SoundQuakeJump") and "Beware")
    elseif message:find(self.L["Logic creates powerful data caches"]) then
        mod:AddMsg("STAR", self.L["STARS"]:format(" !"), 5, mod:GetSetting("SoundStars") and "Alert")
        mod:AddTimerBar("STAR", self.L["STARS"]:format(""), 60)
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    local sUnitName = tUnit:GetName()

    if nSpellId == DEBUFF_SNAKE then
        local sSnakeOnX = self.L["SNAKE ON %s"]:format(sUnitName)
        local sSound = tUnit == GetPlayerUnit() and mod:GetSetting("SoundSnake") and "RunAway"
        mod:AddMsg("SNAKE", sSnakeOnX, 5, sSound, "Blue")
        mod:AddTimerBar("SNAKE", sSnakeOnX, 20)
    end
end
