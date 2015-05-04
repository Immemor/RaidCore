------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Description:
--   Fake boss, to test few basic feature in RaidCore.
--
--   This last should be declared only in alpha version or with git database.
------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

--@alpha@
local mod = core:NewEncounter("GalerasTest", 6, 0, 16)
--@end-alpha@
if not mod then return end

mod:RegisterTrigMob("ANY", { "Crimson Spiderbot", "Crimson Clanker" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Crimson Clanker"] = "Crimson Clanker",
    ["Crimson Spiderbot"] = "Crimson Spiderbot",
    ["Phaser Combo"] = "Phaser Combo",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Crimson Clanker"] = "Cybernéticien écarlate",
    ["Crimson Spiderbot"] = "Arachnobot écarlate",
    ["Phaser Combo"] = "Combo de phaser",
})

function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Crimson Spiderbot"] then
        core:MarkUnit(unit, 1, "A")
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if bInCombat then
        if sName == self.L["Crimson Spiderbot"] then
            core:WatchUnit(unit)
            core:AddUnit(unit)
            core:MarkUnit(unit, 1, "X")
        end
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if castName == self.L["Phaser Combo"] then
        Print("Cast Start")
    end
end

function mod:OnSpellCastEnd(unitName, castName, unit)
    if castName == self.L["Phaser Combo"] then
        Print("Cast End")
    end
end
