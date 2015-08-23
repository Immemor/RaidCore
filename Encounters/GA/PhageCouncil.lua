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
local mod = core:NewEncounter("PhageCouncil", 67, 147, 149)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", {
    "Golgox the Lifecrusher", "Terax Blightweaver", "Ersoth Curseform", "Noxmind the Insidious",
    "Fleshmonger Vratorg",
})
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Terax Blightweaver"] = "Terax Blightweaver",
    ["Golgox the Lifecrusher"] = "Golgox the Lifecrusher",
    ["Fleshmonger Vratorg"] = "Fleshmonger Vratorg",
    ["Noxmind the Insidious"] = "Noxmind the Insidious",
    ["Ersoth Curseform"] = "Ersoth Curseform",
    -- Datachron messages.
    ["The Phageborn Convergence begins gathering its power"] = "The Phageborn Convergence begins gathering its power",
    -- Cast.
    ["Teleport"] = "Teleport",
    ["Channeling Energy"] = "Channeling Energy",
    ["Stitching Strain"] = "Stitching Strain",
    -- Bar and messages.
    ["[%u] NEXT P2"] = "[%u] NEXT P2",
    ["P2 : 20 IA"] = "P2 : 20 IA",
    ["P2 : MINI ADDS"] = "P2 : MINI ADDS",
    ["P2 : SUBDUE"] = "P2 : SUBDUE",
    ["P2 : PILLARS"] = "P2 : PILLARS",
    ["Interrupt Terax!"] = "Interrupt Terax!",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Terax Blightweaver"] = "Terax Tisserouille",
    ["Golgox the Lifecrusher"] = "Golgox le Fossoyeur",
    ["Fleshmonger Vratorg"] = "Vratorg le Cannibale",
    ["Noxmind the Insidious"] = "Toxultime l'Insidieux",
    ["Ersoth Curseform"] = "Ersoth le Maudisseur",
    -- Datachron messages.
    ["The Phageborn Convergence begins gathering its power"] = "La Convergence néophage commence à rassembler son énergie !",
    -- Cast.
    ["Teleport"] = "Se téléporter",
    ["Channeling Energy"] = "Canalisation d'énergie",
    -- Bar and messages.
    ["[%u] NEXT P2"] = "[%u] PROCHAINE P2",
    ["P2 : 20 IA"] = "P2 : 20 IA",
    ["P2 : MINI ADDS"] = "P2 : MINI ADDS",
    ["P2 : SUBDUE"] = "P2 : DESARMEMENT",
    ["P2 : PILLARS"] = "P2 : PILLIERS",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Terax Blightweaver"] = "Terax Brandweber",
    ["Golgox the Lifecrusher"] = "Golgox der Lebenszermalmer",
    ["Fleshmonger Vratorg"] = "Fleischhändler Vratorg",
    ["Noxmind the Insidious"] = "Noxgeist der Hinterlistige",
    ["Ersoth Curseform"] = "Ersoth Fluchform",
    -- Datachron messages.
    ["The Phageborn Convergence begins gathering its power"] = "Die Konvergenz der Phagengeborenen sammelt ihre Macht",
    -- Cast.
    ["Teleport"] = "Teleportieren",
    ["Channeling Energy"] = "Energie kanalisieren",
    -- Bar and messages.
    ["[%u] NEXT P2"] = "[%u] NÄCHSTE P2",
    ["P2 : 20 IA"] = "P2 : 20x UNTERBRECHEN",
    ["P2 : MINI ADDS"] = "P2 : MINI ADDS",
    ["P2 : SUBDUE"] = "P2 : ENTWAFFNEN",
    ["P2 : PILLARS"] = "P2 : GENERATOREN",
})
-- Default settings.
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local p2Count = 0

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)

    p2Count = 0
    mod:AddTimerBar("CONVP1", self.L["[%u] NEXT P2"]:format(p2Count + 1), 90)
end

function mod:OnUnitCreated(tUnit, sName)
    if sName == self.L["Golgox the Lifecrusher"]
        or sName == self.L["Terax Blightweaver"]
        or sName == self.L["Ersoth Curseform"]
        or sName == self.L["Noxmind the Insidious"]
        or sName == self.L["Fleshmonger Vratorg"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Golgox the Lifecrusher"] then
        if castName == self.L["Teleport"] then
            mod:AddMsg("CONVP2", "P2 : 20 IA", 5, "Alert")
            mod:AddTimerBar("CONVP2", "P2 : 20 IA", 29.5)
        end
    elseif unitName == self.L["Terax Blightweaver"] then
        if castName == self.L["Teleport"] then
            mod:AddMsg("CONVP2", "P2 : MINI ADDS", 5, "Alert")
            mod:AddTimerBar("CONVP2", "P2 : MINI ADDS", 29.5)
        elseif castName == self.L["Stitching Strain"] then
            if self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), unit) < 30 then
                mod:AddMsg("INTSTRAIN", "Interrupt Terax!", 5, "Inferno")
            end
        end
    elseif unitName == self.L["Ersoth Curseform"] then
        if castName == self.L["Teleport"] then
            mod:AddMsg("CONVP2", "P2 : SUBDUE", 5, "Alert")
            mod:AddTimerBar("CONVP2", "P2 : SUBDUE", 29.5)
        end
    elseif unitName == self.L["Noxmind the Insidious"] then
        if castName == self.L["Teleport"] then
            mod:AddMsg("CONVP2", "P2 : PILLARS", 5, "Alert")
            mod:AddTimerBar("CONVP2", "P2 : PILLARS", 29.5)
        end
    elseif unitName == self.L["Fleshmonger Vratorg"] then
        if castName == self.L["Teleport"] then
            mod:AddMsg("CONVP2", "P2 : SHIELD", 5, "Alert")
            mod:AddTimerBar("CONVP2", "P2 : SHIELD", 29.5)
        end
    end
end

function mod:OnSpellCastEnd(unitName, castName)
    if castName == self.L["Channeling Energy"] then
        core:RemoveTimerBar("CONVP2")
        mod:AddTimerBar("CONVP1", self.L["[%u] NEXT P2"]:format(p2Count + 1), 60)
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The Phageborn Convergence begins gathering its power"]) then
        p2Count = p2Count + 1
    end
end
