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
local mod = core:NewEncounter("Prototypes", 67, 147, 149)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", {
    "Phagetech Commander", "Phagetech Augmentor", "Phagetech Protector", "Phagetech Fabricator",
})
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Phagetech Commander"] = "Phagetech Commander",
    ["Phagetech Augmentor"] = "Phagetech Augmentor",
    ["Phagetech Protector"] = "Phagetech Protector",
    ["Phagetech Fabricator"] = "Phagetech Fabricator",
    -- Datachron messages.
    ["Phagetech Commander is now active!"] = "Phagetech Commander is now active!",
    ["Phagetech Augmentor is now active!"] = "Phagetech Augmentor is now active!",
    ["Phagetech Protector is now active!"] = "Phagetech Protector is now active!",
    ["Phagetech Fabricator is now active!"] = "Phagetech Fabricator is now active!",
    -- Cast.
    ["Summon Repairbot"] = "Summon Repairbot",
    ["Summon Destructobot"] = "Summon Destructobot",
    -- Bar and messages.
    ["[1] LINK + KICK"] = "[1] LINK + KICK",
    ["[2] TP + CROSS + BOTS"] = "[2] TP + CROSS + BOTS",
    ["[3] SINGULARITY + WAVES"] = "[3] SINGULARITY + WAVES",
    ["[4] SOAK + BOTS"] = "[4] SOAK + BOTS",
    ["BOTS !!"] = "BOTS !!",
    ["BERSERK"] = "BERSERK",
    ["Singularity"] = "Singularity",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Phagetech Commander"] = "Commandant technophage",
    ["Phagetech Augmentor"] = "Augmenteur technophage",
    ["Phagetech Protector"] = "Protecteur technophage",
    ["Phagetech Fabricator"] = "Fabricant technophage",
    -- Datachron messages.
    ["Phagetech Commander is now active!"] = "Commandant technophage est désormais en activité !",
    ["Phagetech Augmentor is now active!"] = "Augmenteur technophage est désormais en activité !",
    ["Phagetech Protector is now active!"] = "Protecteur technophage est désormais en activité !",
    ["Phagetech Fabricator is now active!"] = "Fabricant technophage est désormais en activité !",
    -- Cast.
    ["Summon Repairbot"] = "Déployer Bricobot",
    ["Summon Destructobot"] = "Déployer Destructobot",
    -- Bar and messages.
    ["[1] LINK + KICK"] = "[1] LIEN + KICK",
    ["[2] TP + CROSS + BOTS"] = "[2] TP + CROIX + BOTS",
    ["[3] SINGULARITY + WAVES"] = "[3] SINGULARITÉ + VAGUE",
    ["[4] SOAK + BOTS"] = "[4] SOAK + BOTS",
    ["BOTS !!"] = "BOTS !!",
    ["BERSERK"] = "BERSERK",
    ["Singularity"] = "Singularité",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Phagetech Commander"] = "Phagentech-Kommandant",
    ["Phagetech Augmentor"] = "Phagentech-Augmentor",
    ["Phagetech Protector"] = "Phagentech-Protektor",
    ["Phagetech Fabricator"] = "Phagentech-Fabrikant",
    -- Datachron messages.
    ["Phagetech Commander is now active!"] = "Phagentech-Kommandant ist jetzt aktiv",
    ["Phagetech Augmentor is now active!"] = "Phagentech-Augmentor ist jetzt aktiv",
    ["Phagetech Protector is now active!"] = "Phagentech-Protektor ist jetzt aktiv",
    ["Phagetech Fabricator is now active!"] = "Phagentech-Fabrikant ist jetzt aktiv",
    -- Cast.
    ["Summon Repairbot"] = "Reparaturbot herbeirufen",
    ["Summon Destructobot"] = "Destruktobot herbeirufen",
    -- Bar and messages.
    ["[1] LINK + KICK"] = "[1] VERBINDUNG + KICK",
    ["[2] TP + CROSS + BOTS"] = "[2] FARBEN + KREUZ + REPARATURBOTS",
    ["[3] SINGULARITY + WAVES"] = "[3] SINGULARITÄT + WELLEN",
    ["[4] SOAK + BOTS"] = "[4] KREISE + DESTRUKTOBOTS",
    ["BOTS !!"] = "BOTS !!",
    ["BERSERK"] = "BERSERK",
    ["Singularity"] = "SINGULARITÄT",
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
local protoFirst = true

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    protoFirst = true
end

function mod:OnUnitCreated(nId, tUnit, sName)
    if sName == self.L["Phagetech Commander"] or sName == self.L["Phagetech Augmentor"]
        or sName == self.L["Phagetech Protector"] or sName == self.L["Phagetech Fabricator"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sName == self.L["Phagetech Augmentor"] then
        if sCastName == self.L["Summon Repairbot"] then
            mod:AddMsg("BOTS", "BOTS !!", 5, "Alert")
        end
    elseif sName == self.L["Phagetech Fabricator"] then
        if sCastName == self.L["Summon Destructobot"] then
            mod:AddMsg("BOTS", "BOTS !!", 5, "Alert")
        end
    end
end

function mod:OnDatachron(sMessage)
    if sMessage:find(self.L["Phagetech Commander is now active!"]) then
        mod:AddTimerBar("PROTO", "[2] TP + CROSS + BOTS", protoFirst and 20 or 60)
        if protoFirst then
            protoFirst = nil
            mod:AddTimerBar("BERSERK", "BERSERK", 585)
        end
    elseif sMessage:find(self.L["Phagetech Augmentor is now active!"]) then
        mod:AddTimerBar("PROTO", "[3] SINGULARITY + WAVES", 60)
    elseif sMessage:find(self.L["Phagetech Protector is now active!"]) then
        mod:AddTimerBar("SINGU", "Singularity", 5)
        mod:AddTimerBar("PROTO", "[4] SOAK + BOTS", 60)
    elseif sMessage:find(self.L["Phagetech Fabricator is now active!"]) then
        mod:AddTimerBar("PROTO", "[1] LINK + KICK", 60)
    end
end
