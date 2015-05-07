--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("PhageMaw", 67, 147, 149)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Phage Maw" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Phage Maw"] = "Phage Maw",
    ["Detonation Bomb"] = "Detonation Bomb",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "The augmented shield has been destroyed",
    ["Phage Maw begins charging an orbital strike"] = "Phage Maw begins charging an orbital strike",
    -- Bar and messages.
    ["Bomb %u"] = "Bomb %u",
    ["BOOOM !"] = "BOOOM !",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Phage Maw"] = "Phagegueule",
    ["Detonation Bomb"] = "Bombe à détonateur",
    -- Datachron messages.
    --["The augmented shield has been destroyed"] = "The augmented shield has been destroyed", -- TODO: French translation missing !!!!
    --["Phage Maw begins charging an orbital strike"] = "Phage Maw begins charging an orbital strike", -- TODO: French translation missing !!!!
    -- Bar and messages.
    ["Bomb %u"] = "Bombe %u",
    ["BOOOM !"] = "BOOOM !",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Phage Maw"] = "Phagenschlund",
    ["Detonation Bomb"] = "Sprengbombe",
    -- Datachron messages.
    ["The augmented shield has been destroyed"] = "Der augmentierte Schild wurde zerstört",
    ["Phage Maw begins charging an orbital strike"] = "Phagenschlund beginnt einen Orbitalschlag aufzuladen",
    -- Bar and messages.
    ["Bomb %u"] = "Bombe %u",
    ["BOOOM !"] = "BOOOM !",
})

--------------------------------------------------------------------------------
-- Locals
--

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Detonation Bomb"] then
        core:MarkUnit(unit, 1)
        core:AddUnit(unit)
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The augmented shield has been destroyed"]) then
        core:AddBar("MAW1", self.L["Bomb %u"]:format(1), 20)
        core:AddBar("MAW2", self.L["Bomb %u"]:format(2), 49)
        core:AddBar("MAW3", self.L["Bomb %u"]:format(3), 78)
        core:AddBar("PHAGEMAW", self.L["BOOOM !"], 104, 1)
    elseif message:find(self.L["Phage Maw begins charging an orbital strike"]) then
        core:ResetMarks()
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Phage Maw"] then
            core:AddUnit(unit)
        end
    end
end
