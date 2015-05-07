--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("Prototypes", 67, 147, 149)
if not mod then return end

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
    ["[2] TP + CROIX + BOTS"] = "[2] TP + CROIX + BOTS",
    ["[3] SINGULARITY + VAGUE"] = "[3] SINGULARITY + VAGUE",
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
    --["Phagetech Commander is now active!"] = "Phagetech Commander is now active!", -- TODO: French translation missing !!!!
    --["Phagetech Augmentor is now active!"] = "Phagetech Augmentor is now active!", -- TODO: French translation missing !!!!
    --["Phagetech Protector is now active!"] = "Phagetech Protector is now active!", -- TODO: French translation missing !!!!
    --["Phagetech Fabricator is now active!"] = "Phagetech Fabricator is now active!", -- TODO: French translation missing !!!!
    -- Cast.
    ["Summon Repairbot"] = "Déployer Bricobot",
    ["Summon Destructobot"] = "Déployer Destructobot",
    -- Bar and messages.
    ["[1] LINK + KICK"] = "[1] LIEN + KICK",
    ["[2] TP + CROIX + BOTS"] = "[2] TP + CROIX + BOTS",
    ["[3] SINGULARITY + VAGUE"] = "[3] SINGULARITÉ + VAGUE",
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
    ["[2] TP + CROIX + BOTS"] = "[2] FARBEN + KREUZ + REPARATURBOTS",
    ["[3] SINGULARITY + VAGUE"] = "[3] SINGULARITÄT + WELLEN",
    ["[4] SOAK + BOTS"] = "[4] KREISE + DESTRUKTOBOTS",
    ["BOTS !!"] = "BOTS !!",
    ["BERSERK"] = "BERSERK",
    ["Singularity"] = "SINGULARITÄT",
})

--------------------------------------------------------------------------------
-- Locals
--

local protoFirst = true

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Phagetech Augmentor"] and castName == self.L["Summon Repairbot"] then
        core:AddMsg("BOTS", self.L["BOTS !!"], 5, "Alert")
    elseif unitName == self.L["Phagetech Fabricator"] and castName == self.L["Summon Destructobot"] then
        core:AddMsg("BOTS", self.L["BOTS !!"], 5, "Alert")
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["Phagetech Commander is now active!"]) then
        core:AddBar("PROTO", self.L["[2] TP + CROIX + BOTS"], protoFirst and 20 or 60)
        if protoFirst then 
            protoFirst = nil
            core:AddBar("BERSERK", self.L["BERSERK"], 585)
        end
    elseif message:find(self.L["Phagetech Augmentor is now active!"]) then
        core:AddBar("PROTO", self.L["[3] SINGULARITY + VAGUE"], 60)
    elseif message:find(self.L["Phagetech Protector is now active!"]) then
        core:AddBar("SINGU", self.L["Singularity"], 5)
        core:AddBar("PROTO", self.L["[4] SOAK + BOTS"], 60)
    elseif message:find(self.L["Phagetech Fabricator is now active!"]) then
        core:AddBar("PROTO", self.L["[1] LINK + KICK"], 60)
    end
end

function mod:OnReset()
    protoFirst = true
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Phagetech Commander"] then
        elseif sName == self.L["Phagetech Augmentor"] or sName == self.L["Phagetech Fabricator"] then
            core:WatchUnit(unit)
        end
    end
end
