----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--
-- Description:
--   Unique encounter in Core-Y83 raid.
--
--   - There are 3 boss called "Prime Evolutionary Operant". At any moment, one of them is
--     compromised, and his name is "Prime Phage Distributor".
--   - Bosses don't move, their positions are constants so.
--   - The boss call "Prime Phage Distributor" have a debuff called "Compromised Circuitry".
--   - And switch boss occur at 60% and 20% of health.
--   - The player which will be irradied is the last connected in the game (probability: 95%).
--
--   So be careful, with code based on name, as bosses are renamed many times during the combat.
--
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("PrimeEvolutionaryOperant", 91, 0, 475)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Prime Evolutionary Operant", "Prime Phage Distributor" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Prime Evolutionary Operant"] = "Prime Evolutionary Operant",
    ["Prime Phage Distributor"] = "Prime Phage Distributor",
    ["Sternum Buster"] = "Sternum Buster",
    -- Datachron messages.
    ["(.*) is being irradiated"] = "(.*) is being irradiated",
    ["ENGAGING TECHNOPHAGE TRASMISSION"] = "ENGAGING TECHNOPHAGE TRASMISSION",
    ["A Prime Purifier has been corrupted!"] = "A Prime Purifier has been corrupted!",
    -- Cast
    ["Digitize"] = "Digitize",
    ["Strain Injection"] = "Strain Injection",
    ["Corruption Spike"] = "Corruption Spike",
    -- Bars messages.
    ["~Next irradiate"] = "~Next irradiate",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Prime Evolutionary Operant"] = "Premier purificateur",
    ["Prime Phage Distributor"] = "Distributeur de Primo Phage",
    -- Datachron messages.
    ["(.*) is being irradiated"] = "(.*) est irradiée.",
    ["ENGAGING TECHNOPHAGE TRASMISSION"] = "ENCLENCHEMENT DE LA TRANSMISSION DU TECHNOPHAGE",
    -- Bars messages.
    ["~Next irradiate"] = "~Prochaine irradiation",
})
mod:RegisterGermanLocale({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Center of the room, where is the Organic Incinerator button.
local ORGANIC_INCINERATOR = { x = 1268, y = -800, z = 876 }
-- It's when the player enter in "nuclear" green zone. If this last have some STRAIN INCUBATION,
-- he will lost it, and an small mob will pop.
local DEBUFF_RADIATION_BATH = 71188
-- DOT taken by one or more players, which is dispel with RADIATION_BATH or ENGAGING datachron
-- event.
local DEBUFF_STRAIN_INCUBATION = 49303
-- Buff stackable on bosses. The beam from the wall buff the boss when they are not hit by the boss
-- itself. At 15 stacks, the datachron message "A Prime Purifier has been corrupted!" will trig.
-- Note: the datachron event is raised before the buff update event.
local BUFF_NANOSTRAIN_INFUSION = 50075
-- Buff on bosses. The boss called "Prime Phage Distributor" have this buff, others not.
local BUFF_COMPROMISED_CIRCUITRY = 48735

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if bInCombat then
        if sName == self.L["Prime Evolutionary Operant"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            local tPosition = unit:GetPosition()
            if tPosition.x < ORGANIC_INCINERATOR.x then
                core:MarkUnit(unit, 1, "L")
            else
                core:MarkUnit(unit, 1, "R")
            end
        elseif sName == self.L["Prime Phage Distributor"] then
            core:AddUnit(unit)
            core:MarkUnit(unit, 1, "M")
            core:WatchUnit(unit)
            core:AddBar("NEXT_IRRADIATE", self.L["~Next irradiate"], 27, true)
        end
    end
end

function mod:OnChatDC(message)
    local sPlayerNameIrradiate = message:match(self.L["(.*) is being irradiated"])
    if sPlayerNameIrradiate then
        -- Sometime it's 26s, sometime 27s or 28s.
        core:AddBar("NEXT_IRRADIATE", self.L["~Next irradiate"], 26, true)
    elseif message == self.L["ENGAGING TECHNOPHAGE TRASMISSION"] then
        core:AddBar("NEXT_IRRADIATE", self.L["~Next irradiate"], 40, true)
    end
end
