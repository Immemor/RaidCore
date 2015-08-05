----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--   TODO
----------------------------------------------------------------------------------------------------
require "ChatSystemLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("EpFireEarth", 52, 98, 117)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Pyrobane", "Megalith" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Pyrobane"] = "Pyrobane",
    ["Megalith"] = "Megalith",
    ["Lava Mine"] = "Lava Mine",
    ["Obsidian Outcropping"] = "Obsidian Outcropping",
    ["Flame Wave"] = "Flame Wave",
    ["Lava Floor (invis unit)"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
    -- Datachron.
    ["The lava begins to rise through the floor!"] = "The lava begins to rise through the floor!",
    ["Time to die, sapients!"] = "Time to die, sapients!",
    -- Bar and messages.
    ["Enrage"] = "Enrage",
    ["RAID WIPE"] = "RAID WIPE",
    ["Lava Floor Phase"] = "Lava Floor Phase",
    ["End of Lava Floor"] = "End of Lava Floor",
    ["Next Obsidian"] = "Next Obsidian %d/%d",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Pyrobane"] = "Pyromagnus",
    ["Megalith"] = "Mégalithe",
    ["Lava Mine"] = "Mine de lave",
    ["Obsidian Outcropping"] = "Affleurement d'obsidienne",
    ["Flame Wave"] = "Vague de feu",
    ["Lava Floor (invis unit)"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
    -- Datachron.
    ["The lava begins to rise through the floor!"] = "La lave apparaît par les fissures du sol !",
    ["Time to die, sapients!"] = "Maintenant c'est l'heure de mourir, misérables !",
    -- Bar and messages.
    ["Enrage"] = "Enrage",
    ["RAID WIPE"] = "MORT DU RAID",
    ["Lava Floor Phase"] = "Phase Lave",
    ["End of Lava Floor"] = "Fin de la lave",
    ["Next Obsidian"] = "Prochaine Obsidienne %d/%d",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Pyrobane"] = "Pyroman",
    ["Megalith"] = "Megalith",
    ["Flame Wave"] = "Flammenwelle",
})
-- Default settings.
mod:RegisterDefaultSetting("LineFlameWaves")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["ENRAGE"] = { sColor = "xkcdAmethyst" },
    ["LAVA_FLOOR"] = { sColor = "xkcdBloodRed" },
    ["RAID_WIPE"] = { sColor = "xkcdBloodRed" },
    ["OBSIDIAN"] = { sColor = "xkcdMediumBrown" },
})
----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local OBSIDIAN_POP_INTERVAL = 14
local LAVA_MINE_POP_INTERVAL = 11.2

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local nObsidianPopMax, nObsidianPopCount
local nLavaFloorCount

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("BUFF_ADD", "OnBuffAdded", self)
    Apollo.RegisterEventHandler("BUFF_UPDATE", "OnBuffUpdate", self)
    Apollo.RegisterEventHandler("BUFF_DEL", "OnBuffRemoved", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    nObsidianPopMax = 6
    nObsidianPopCount = 1
    nLavaFloorCount = 0
    local text = self.L["Next Obsidian"]:format(nObsidianPopCount, nObsidianPopMax)
    mod:AddTimerBar("OBSIDIAN", text, OBSIDIAN_POP_INTERVAL)
    mod:AddTimerBar("LAVA_FLOOR", self.L["Lava Floor Phase"], 94)
    mod:AddTimerBar("ENRAGE", self.L["Enrage"], 425)
end

function mod:OnBuffAdded(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnBuffUpdate(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnBuffRemoved(nId, nSpellId)
end

function mod:OnChatDC(message)
    if message == self.L["The lava begins to rise through the floor!"] then
        mod:AddTimerBar("LAVA_FLOOR", self.L["End of Lava Floor"], 28)
        nLavaFloorCount = nLavaFloorCount + 1
    elseif self.L["Time to die, sapients!"] == message then
        mod:AddTimerBar("RAID_WIPE", self.L["RAID WIPE"], 34)
    end
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Pyrobane"] or sName == self.L["Megalith"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
    elseif sName == self.L["Flame Wave"] then
        if mod:GetSetting("LineFlameWaves") then
            core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 20, 0)
        end
    elseif sName == self.L["Obsidian Outcropping"] then
        nObsidianPopCount = nObsidianPopCount + 1
        if nObsidianPopCount <= nObsidianPopMax then
            local text = self.L["Next Obsidian"]:format(nObsidianPopCount, nObsidianPopMax)
            mod:AddTimerBar("OBSIDIAN", text, OBSIDIAN_POP_INTERVAL)
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Flame Wave"] then
        core:DropPixie(unit:GetId())
    elseif sName == self.L["Lava Floor (invis unit)"] then
        if nLavaFloorCount < 3 then
            mod:AddTimerBar("LAVA_FLOOR", self.L["Lava Floor Phase"], 89)
        end
        nObsidianPopCount = 1
        if nObsidianPopMax > 2 then
            nObsidianPopMax = nObsidianPopMax - 2
        else
            nObsidianPopMax = 2
        end
        local text = self.L["Next Obsidian"]:format(nObsidianPopCount, nObsidianPopMax)
        local nTimeOffset = (6 - nObsidianPopMax) * OBSIDIAN_POP_INTERVAL + 8
        mod:AddTimerBar("OBSIDIAN", text, nTimeOffset)
    elseif self.L["Pyrobane"] == sName then
        mod:RemoveTimerBar("LAVA_FLOOR")
    end
end
