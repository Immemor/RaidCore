--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("DSLogicWing", 52, 98, 111)
if not mod then return end

mod:RegisterTrigMob("ANY", {
    "Hyper-Accelerated Skeledroid", "Augmented Herald of Avatus", "Abstract Augmentation Algorithm",
})
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Conjured Fire Bomb"] = "Conjured Fire Bomb",
    ["Abstract Augmentation Algorithm"] = "Abstract Augmentation Algorithm",
    ["Augmented Herald of Avatus"] = "Augmented Herald of Avatus",
    ["Quantum Processing Unit"] = "Quantum Processing Unit",
    ["Hyper-Accelerated Skeledroid"] = "Hyper-Accelerated Skeledroid",
    -- Datachron messages.
    ["The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit"] = "The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit",
    -- Cast.
    ["Data Deconstruction"] = "Data Deconstruction",
    -- Bar and messages.
    ["[%u] INTERRUPT"] = "[%u] INTERRUPT",
    ["HEAL SOON"] = "HEAL SOON",
    ["CUBE SMASH"] = "CUBE SMASH",
    ["EMPOWER"] = "EMPOWER%s",
    ["BOMB"] = "BOMB",
    ["BERSERK"] = "BERSERK",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Conjured Fire Bomb"] = "Bombe incendiaire invoquée",
    ["Abstract Augmentation Algorithm"] = "Algorithme d'augmentation abstrait",
    ["Augmented Herald of Avatus"] = "Messager d'Avatus augmenté",
    ["Quantum Processing Unit"] = "Processeur quantique",
    ["Hyper-Accelerated Skeledroid"] = "Crânedroïde hyper-accéléré",
    -- Datachron messages.
    --["The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit"] = "The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit", -- TODO: French translation missing !!!!
    -- Cast.
    ["Data Deconstruction"] = "Déconstruction de données",
    -- Bar and messages.
    --["[%u] INTERRUPT"] = "[%u] INTERRUPT", -- TODO: French translation missing !!!!
    --["HEAL SOON"] = "HEAL SOON", -- TODO: French translation missing !!!!
    --["CUBE SMASH"] = "CUBE SMASH", -- TODO: French translation missing !!!!
    --["EMPOWER"] = "EMPOWER%s", -- TODO: French translation missing !!!!
    --["BOMB"] = "BOMB", -- TODO: French translation missing !!!!
    ["BERSERK"] = "BERSERK",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Conjured Fire Bomb"] = "Beschworene Feuerbombe",
    ["Abstract Augmentation Algorithm"] = "Abstrakter Augmentations-Algorithmus",
    ["Augmented Herald of Avatus"] = "Avatus’ augmentierter Herold",
    ["Quantum Processing Unit"] = "Quantum-Aufbereitungseinheit",
    ["Hyper-Accelerated Skeledroid"] = "Hyper-beschleunigter Skeledroid",
    -- Datachron messages.
    --["The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit"] = "The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit", -- TODO: German translation missing !!!!
    -- Cast.
    ["Data Deconstruction"] = "Datendekonstruktion",
    -- Bar and messages.
    --["[%u] INTERRUPT"] = "[%u] INTERRUPT", -- TODO: German translation missing !!!!
    --["HEAL SOON"] = "HEAL SOON", -- TODO: German translation missing !!!!
    --["CUBE SMASH"] = "CUBE SMASH", -- TODO: German translation missing !!!!
    --["EMPOWER"] = "EMPOWER%s", -- TODO: German translation missing !!!!
    --["BOMB"] = "BOMB", -- TODO: German translation missing !!!!
    ["BERSERK"] = "BERSERK",
})

--------------------------------------------------------------------------------
-- Locals
--

local prevInt = ""
local castCount = 0
local nbKick = 28

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitEnteredCombat", "OnUnitEnteredCombat", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED_DOSE", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--
function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Conjured Fire Bomb"] then
        core:AddMsg("BOMB", self.L["BOMB"], 5, "Long", "Blue")
        core:AddBar("BOMB", self.L["BOMB"], first and 20 or 23)
    end
end


function mod:OnHealthChanged(unitName, health)
    if unitName == self.L["Augmented Herald of Avatus"] and health == 25 then
        core:AddMsg("SIPHON", self.L["HEAL SOON"], 5, "Info")
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Augmented Herald of Avatus"] and castName == "Cube Smash" then
        core:AddBar("CUBE", self.L["CUBE SMASH"], 17)
    elseif unitName == self.L["Abstract Augmentation Algorithm"] and castName == self.L["Data Deconstruction"] then
        castCount = castCount + 1
        core:AddMsg("DATA", self.L["[%u] INTERRUPT"]:format(castCount), 3, "Long", "Blue")
        core:AddBar("DATA", self.L["[%u] INTERRUPT"]:format(castCount), 7)
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["The Abstract Augmentation Algorithm has amplified a Quantum Processing Unit"]) then
        core:AddMsg("EMPOWER", self.L["EMPOWER"]:format(" !!"), 5, "Alert")
        core:AddBar("EMPOWER", self.L["EMPOWER"]:format(""), 30, 1)
    end
end

function mod:OnDebuffApplied(unitName, splId)
    if splId == 72559 and prevInt ~= unitName then
        Print(("[%s] %s"):format(castCount, unitName))
        prevInt = unitName
        castCount = castCount + 1
        if castCount > nbKick then castCount = 1 end
        core:AddBar("DATA", self.L["[%u] INTERRUPT"]:format(castCount), 7)
    end
end

function mod:OnUnitEnteredCombat(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Abstract Augmentation Algorithm"] then
            prevInt = ""
            castCount = 1
            core:AddUnit(unit)
            core:RaidDebuff()
            core:AddBar("DATA", self.L["[%u] INTERRUPT"]:format(castCount), 7)
            core:AddBar("EMPOWER", self.L["EMPOWER"]:format(""), 30, 1)
        elseif sName == self.L["Quantum Processing Unit"] then
            core:AddUnit(unit)
            core:MarkUnit(unit)
        elseif sName == self.L["Hyper-Accelerated Skeledroid"] then
            core:AddUnit(unit)
            core:AddBar("BERSERK", self.L["BERSERK"], 180, 1)
        elseif sName == self.L["Augmented Herald of Avatus"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:AddBar("CUBE", self.L["CUBE SMASH"], 8)
        end
    end
end
