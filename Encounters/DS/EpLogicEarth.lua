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

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

----------------------------------------------------------------------------------------------------
-- constants
----------------------------------------------------------------------------------------------------
local BUFF_MNEMESIS_INFORMATIC_CLOUD = 52571
local DEBUFF_SNAKE = 74570

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _Previous_Defragment_time = 0
local pilarCount = 0

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
end

----------------------------------------------------------------------------------------------------
-- Event Handlers
----------------------------------------------------------------------------------------------------
function mod:OnUnitCreated(unit, sName)
    local sName = unit:GetName()
    if sName == self.L["Obsidian Outcropping"] and mod:GetSetting("LineObsidianOutcropping") then
        core:AddPixie(unit:GetId().."_1", 1, GameLib.GetPlayerUnit(), unit, "Blue", 10)
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Obsidian Outcropping"] then
        core:DropPixie(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Mnemesis"] and castName == self.L["Defragment"] then
        local timeOfEvent = GetGameTime()
        if timeOfEvent - _Previous_Defragment_time > 10 then
            _Previous_Defragment_time = timeOfEvent
            core:AddMsg("DEFRAG", self.L["SPREAD"], 5, mod:GetSetting("SoundDefrag", "Alarm"))
            core:AddBar("BOOM", self.L["BOOM"], 9)
            core:AddBar("DEFRAG", self.L["DEFRAG"], 40)
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The ground shudders beneath Megalith"]) then
        core:AddMsg("QUAKE", self.L["JUMP !"], 3, mod:GetSetting("SoundQuakeJump", "Beware"))
    elseif message:find(self.L["Logic creates powerful data caches"]) then
        core:AddMsg("STAR", self.L["STARS"]:format(" !"), 5, mod:GetSetting("SoundStars", "Alert"))
        core:AddBar("STAR", self.L["STARS"]:format(""), 60)
    end
end

function mod:OnDebuffApplied(unitName, splId, unit)
    if splId == DEBUFF_SNAKE then
        if unit == GetPlayerUnit() then
            core:AddMsg("SNAKE", self.L["SNAKE ON %s"]:format(unitName), 5, mod:GetSetting("SoundSnake", "RunAway"), "Blue")
        end
        core:AddBar("SNAKE", self.L["SNAKE ON %s"]:format(unitName), 20)
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Megalith"] then
            core:AddUnit(unit)
        elseif sName == self.L["Mnemesis"] then
            _Previous_Defragment_time = 0
            pilarCount = 0
            core:AddBar("DEFRAG", self.L["DEFRAG"], 10)
            core:AddBar("STAR", self.L["STARS"]:format(""), 60)
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:RaidDebuff()
        elseif sName == self.L["Crystalline Matrix"] then
            pilarCount = pilarCount + 1
        end
    elseif unit:GetType() == "NonPlayer" and not bInCombat then
        if sName == self.L["Mnemesis"] then
            Apollo.RemoveEventHandler("RC_UnitCreated", self)
            core:ResetLines()
        end
    end
end
