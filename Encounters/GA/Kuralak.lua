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
local mod = core:NewEncounter("Kuralak", 67, 147, 148)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Kuralak the Defiler" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Kuralak the Defiler"] = "Kuralak the Defiler",
    -- Datachron messages.
    ["Kuralak the Defiler returns to the Archive Core"] = "Kuralak the Defiler returns to the Archive Core",
    ["Kuralak the Defiler causes a violent outbreak of corruption"] = "Kuralak the Defiler causes a violent outbreak of corruption",
    ["The corruption begins to fester"] = "The corruption begins to fester",
    ["has been anesthetized"] = "has been anesthetized",
    -- NPCSay messages.
    ["Through the Strain you will be transformed"] = "Through the Strain you will be transformed",
    ["Your form is flawed, but I will make you beautiful"] = "Your form is flawed, but I will make you beautiful",
    ["Let the Strain perfect you"] = "Let the Strain perfect you",
    ["The Experiment has failed"] = "The Experiment has failed",
    ["Join us... become one with the Strain"] = "Join us... become one with the Strain",
    ["One of us... you will become one of us"] = "One of us... you will become one of us",
    -- Cast.
    ["Vanish into Darkness"] = "Vanish into Darkness",
    -- Bar and messages.
    ["P2 SOON !"] = "P2 SOON !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["VANISH"] = "VANISH",
    ["Vanish"] = "Vanish",
    ["OUTBREAK"] = "OUTBREAK",
    ["Outbreak (%s)"] = "Outbreak (%s)",
    ["EGGS (%s)"] = "EGGS (%s)",
    ["Eggs (%s)"] = "Eggs (%s)",
    ["BERSERK !!"] = "BERSERK !!",
    ["SWITCH TANK"] = "SWITCH TANK",
    ["Switch Tank (%s)"] = "Switch Tank (%s)",
    ["MARKER north"] = "N",
    ["MARKER south"] = "S",
    ["MARKER east"] = "E",
    ["MARKER west"] = "W",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Kuralak the Defiler"] = "Kuralak la Profanatrice",
    -- Datachron messages.
    ["Kuralak the Defiler returns to the Archive Core"] = "Kuralak la Profanatrice retourne au Noyau d'accès aux archives pour reprendre des forces",
    ["Kuralak the Defiler causes a violent outbreak of corruption"] = "Kuralak la Profanatrice provoque une violente éruption de Corruption",
    ["The corruption begins to fester"] = "La Corruption commence à se répandre",
    ["has been anesthetized"] = "est sous anesthésie",
    -- NPCSay messages.
    --["Through the Strain you will be transformed"] = "Through the Strain you will be transformed", -- TODO: French translation missing !!!!
    --["Your form is flawed, but I will make you beautiful"] = "Your form is flawed, but I will make you beautiful", -- TODO: French translation missing !!!!
    ["Let the Strain perfect you"] = "Embrasse la perfection de la Souillure...",
    ["The Experiment has failed"] = "L'expérience a échoué",
    ["Join us... become one with the Strain"] = "Livrez-vous corps et âme à la Souillure...",
    ["One of us... you will become one of us"] = "Des nôtres... Tu seras bientôt des nôtres...",
    -- Cast.
    ["Vanish into Darkness"] = "Disparaître dans les ténèbres",
    -- Bar and messages.
    ["P2 SOON !"] = "P2 SOON !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["VANISH"] = "DISPARITION",
    ["Vanish"] = "Disparition",
    ["OUTBREAK"] = "INVASION",
    ["Outbreak (%s)"] = "Invasion (%s)",
    ["EGGS (%s)"] = "Oeufs (%s)",
    ["Eggs (%s)"] = "Oeufs (%s)",
    ["BERSERK !!"] = "BERSERK !!",
    ["SWITCH TANK"] = "CHANGEMENT TANK",
    ["Switch Tank (%s)"] = "Changement de Tank (%s)",
    ["MARKER north"] = "N",
    ["MARKER south"] = "S",
    ["MARKER east"] = "E",
    ["MARKER west"] = "O",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Kuralak the Defiler"] = "Kuralak die Schänderin",
    -- Datachron messages.
    ["Kuralak the Defiler returns to the Archive Core"] = "Kuralak die Schänderin kehrt zum Archivkern zurück",
    ["Kuralak the Defiler causes a violent outbreak of corruption"] = "Kuralak die Schänderin verursacht einen heftigen Ausbruch der Korrumpierung",
    ["The corruption begins to fester"] = "Die Korrumpierung beginnt zu eitern",
    ["has been anesthetized"] = "wurde narkotisiert",
    -- NPCSay messages.
    ["Through the Strain you will be transformed"] = "Durch die Transformation wirst du",
    ["Your form is flawed, but I will make you beautiful"] = "aber ich werde dich schön machen",
    ["Let the Strain perfect you"] = "Dies ist mein Reich! Daraus gibt es kein Entrinnen ...",
    ["The Experiment has failed"] = "Lass dich von der Transmutation perfektionieren",
    ["Join us... become one with the Strain"] = "Die Transmutation ... Lass dich von ihr verschlingen ...",
    ["One of us... you will become one of us"] = "Einer von uns ...",
    -- Cast.
    ["Vanish into Darkness"] = "In der Dunkelheit verschwinden",
    -- Bar and messages.
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["VANISH"] = "VERSCHWINDEN",
    ["Vanish"] = "Verschwinden",
    ["OUTBREAK"] = "AUSBRUCH",
    ["Outbreak (%s)"] = "Ausbruch (%s)",
    ["EGGS (%s)"] = "Eier (%s)",
    ["Eggs (%s)"] = "Eier (%s)",
    ["BERSERK !!"] = "DAS WARS !!",
    ["SWITCH TANK"] = "AGGRO ZIEHEN !!!",
    ["Switch Tank (%s)"] = "Tankwechsel (%s)",
    ["MARKER north"] = "N",
    ["MARKER south"] = "S",
    ["MARKER east"] = "O",
    ["MARKER west"] = "W",
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
local GetUnitById = GameLib.GetUnitById
local eggsCount, siphonCount, outbreakCount = 0, 0, 0

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("CHAT_NPCSAY", "OnChatNPCSay", self)
    Apollo.RegisterEventHandler("DEBUFF_ADD", "OnDebuffAdd", self)

    eggsCount, siphonCount, outbreakCount = 2, 1, 0
end

function mod:OnUnitCreated(tUnit, sName)
    if sName == self.L["Kuralak the Defiler"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    end
end

function mod:OnHealthChanged(unitName, health)
    if health == 74 and unitName == self.L["Kuralak the Defiler"] then
        core:AddMsg("P2", self.L["P2 SOON !"], 5, "Info")
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["Kuralak the Defiler returns to the Archive Core"]) then
        core:AddMsg("VANISH", self.L["VANISH"], 5, "Alert")
        core:AddTimerBar("VANISH", self.L["Vanish"], 47)
    elseif message:find(self.L["Kuralak the Defiler causes a violent outbreak of corruption"]) then
        core:AddMsg("OUTBREAK", self.L["OUTBREAK"], 5, "RunAway")
        outbreakCount = outbreakCount + 1
        if outbreakCount <= 5 then
            core:AddTimerBar("OUTBREAK", self.L["Outbreak (%s)"]:format(outbreakCount + 1), 45)
        end
    elseif message:find(self.L["The corruption begins to fester"]) then
        if eggsCount < 2 then eggsCount = 2 end
        core:AddMsg("EGGS", (self.L["EGGS (%s)"]):format(math.pow(2, eggsCount-1)), 5, "Alert")
        eggsCount = eggsCount + 1
        if eggsCount == 5 then
            core:AddTimerBar("EGGS", self.L["BERSERK !!"], 66)
            eggsCount = 2
        else
            core:AddTimerBar("EGGS", self.L["Eggs (%s)"]:format(math.pow(2, eggsCount-1)), 66)
        end
    elseif message:find(self.L["has been anesthetized"]) then
        if siphonCount == 0 then siphonCount = 1 end
        siphonCount = siphonCount + 1
        if self:Tank() then
            core:AddMsg("SIPHON", self.L["SWITCH TANK"], 5, "Alarm")
            if siphonCount < 4 then
                core:AddTimerBar("SIPHON", self.L["Switch Tank (%s)"]:format(siphonCount), 88)
            end
        end
    end
end

function mod:OnChatNPCSay(message)
    if message:find(self.L["Through the Strain you will be transformed"])
        or message:find(self.L["Your form is flawed, but I will make you beautiful"])
        or message:find(self.L["Let the Strain perfect you"])
        or message:find(self.L["The Experiment has failed"])
        or message:find(self.L["Join us... become one with the Strain"])
        or message:find(self.L["One of us... you will become one of us"]) then
        eggsCount, siphonCount, outbreakCount = 2, 1, 0
        core:RemoveTimerBar("VANISH")
        core:AddMsg("KP2", self.L["PHASE 2 !"], 5, "Alert")
        core:AddTimerBar("OUTBREAK", self.L["Outbreak (%s)"]:format(outbreakCount + 1), 15)
        core:AddTimerBar("EGGS", self.L["Eggs (%s)"]:format(eggsCount), 73)
        if self:Tank() then
            core:AddTimerBar("SIPHON", self.L["Switch Tank (%s)"]:format(siphonCount), 37)
        end
        local estpos = { x = 194.44, y = -110.80034637451, z = -483.20 }
        core:SetWorldMarker("EAST", self.L["MARKER east"], estpos)
        local sudpos = { x = 165.79222106934, y = -110.80034637451, z = -464.8489074707 }
        core:SetWorldMarker("SOUTH", self.L["MARKER south"], sudpos)
        local ouestpos = { x = 144.20, y = -110.80034637451, z = -494.38 }
        core:SetWorldMarker("WEST", self.L["MARKER west"], ouestpos)
        local nordpos = { x = 175.00, y = -110.80034637451, z = -513.31 }
        core:SetWorldMarker("NORTH", self.L["MARKER north"], nordpos)
    end
end

function mod:OnDebuffApplied(nId, nSpellId, nStack, fTimeRemaining)
    if nSpellId == 56652 then
        local tUnit = GetUnitById(nId)
        if tUnit then
            core:MarkUnit(tUnit)
            core:AddUnit(tUnit)
        end
    end
end
