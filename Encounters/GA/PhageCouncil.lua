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
    ["Noxmind the Insidious prepares to equalize the Convergence!"] = "Noxmind the Insidious prepares to equalize the Convergence!",
    -- Cast.
    ["Teleport"] = "Teleport",
    ["Channeling Energy"] = "Channeling Energy",
    ["Gathering Energy"] = "Gathering Energy",
    ["Stitching Strain"] = "Stitching Strain",
    -- Timer bars.
    ["Next P2"] = "Next P2",
    ["Next equalization"] = "Next equalization",
    ["P2: Timeout 20 IA"] = "P2: Timeout 20 IA",
    ["P2: Timeout mini adds"] = "P2: Timeout mini adds",
    ["P2: Timeout subdue"] = "P2: Timeout subdue",
    ["P2: Timeout pillars"] = "P2: Timeout pillars",
    ["P2: Timeout shield"] = "P2: Timeout shield",
    -- Message bars.
    ["INTERRUPT TERAX!"] = "INTERRUPT TERAX!",
    ["Phase 2: GOLGOX! (20 IA)"] = "Phase 2: GOLGOX! (20 IA)",
    ["Phase 2: TERAX! (Mini adds)"] = "Phase 2: TERAX! (Mini adds)",
    ["Phase 2: ERSOTH! (Subdue)"] = "Phase 2: ERSOTH! (Subdue)",
    ["Phase 2: NOXMIND! (Pillars)"] = "Phase 2: NOXMIND! (Pillars)",
    ["Phase 2: VRATORG! (Shield)"] = "Phase 2: VRATORG! (Shield)",
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
    ["Noxmind the Insidious prepares to equalize the Convergence!"] = "Toxultime l'Insidieux se prépare à égaliser la Convergence !",
    -- Cast.
    ["Teleport"] = "Se téléporter",
    ["Channeling Energy"] = "Canalisation d'énergie",
    ["Gathering Energy"] = "Accumulation d'énergie",
    ["Stitching Strain"] = "Pression de suture",
    -- Timer bars.
    ["Next P2"] = "Prochaine P2",
    ["Next equalization"] = "Prochaine égalisation",
    ["P2: Timeout 20 IA"] = "P2: Timeout 20 IA",
    ["P2: Timeout mini adds"] = "P2: Timeout mini adds",
    ["P2: Timeout subdue"] = "P2: Timeout désarmement",
    ["P2: Timeout pillars"] = "P2: Timeout pilliers",
    ["P2: Timeout shield"] = "P2: Timeout bouclier",
    -- Message bars.
    ["INTERRUPT TERAX!"] = "INTÉRROMPRE TERAX !",
    ["Phase 2: GOLGOX! (20 IA)"] = "Phase 2: GOLGOX! (20 IA)",
    ["Phase 2: TERAX! (Mini adds)"] = "Phase 2: TERAX! (Mini adds)",
    ["Phase 2: ERSOTH! (Subdue)"] = "Phase 2: ERSOTH! (Désarmement)",
    ["Phase 2: NOXMIND! (Pillars)"] = "Phase 2: TOXULTIME! (Pilliers)",
    ["Phase 2: VRATORG! (Shield)"] = "Phase 2: VRATORG! (Bouclier)",
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
    -- Timer bars.
    ["Next P2"] = "Nächste P2",
})
-- Default settings.
mod:RegisterDefaultSetting("CircleErsothInterruptDist")
mod:RegisterDefaultSetting("LineToxWaves")
mod:RegisterDefaultSetting("SoundPhase2CountDown")
mod:RegisterDefaultSetting("SoundPhase2Alert")
mod:RegisterDefaultSetting("SoundInterruptTerax")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["NextP2"] = { sColor = "xkcdBluishPurple" },
    ["NextEqualize"] = { sColor = "xkcdEasterPurple" },
    ["P2Timeout"] = { sColor = "xkcdBloodOrange" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEFAULT_EQUALIZATION_DURATION = 37
local DEBUFFID_CHANNELING_ENERGY = 59721
local PHASE1_DURATION = 60
local PHASE2_DURATION = 29.5
local PHASE2_TYPE_GOLGOX = 1
local PHASE2_TYPE_TERAX = 2
local PHASE2_TYPE_ERSOTH = 3
local PHASE2_TYPE_NOXMIND = 4
local PHASE2_TYPE_VRATORG = 5

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local tBossesId
local nNextP2Time
local nNextEqualization

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    tBossesId = {}
    eBossPhase2 = nil
    nNextP2Time = GetGameTime() + 87
    mod:AddTimerBar("NextP2", "Next P2", 87, mod:GetSetting("SoundPhase2CountDown"))
    mod:AddTimerBar("NextEqualize", "Next equalization", 31.5)
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()
    if sName == self.L["Golgox the Lifecrusher"]
        or sName == self.L["Terax Blightweaver"]
        or sName == self.L["Ersoth Curseform"]
        or sName == self.L["Noxmind the Insidious"]
        or sName == self.L["Fleshmonger Vratorg"] then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
            tBossesId[sName] = nId
        elseif sName == self.L["Noxmind the Insidious"] then
            if mod:GetSetting("LineToxWaves") then
                -- It's the wave from Nox which target a player
                local line = core:AddSimpleLine("Wave" .. nId, nId, 5, 45, 0, 4, "green")
            end
        end
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Noxmind the Insidious"] then
        core:RemoveSimpleLine("Wave" .. nId)
    end
    tBossesId[sName] = nil
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sName == self.L["Golgox the Lifecrusher"]
        or sName == self.L["Terax Blightweaver"]
        or sName == self.L["Ersoth Curseform"]
        or sName == self.L["Noxmind the Insidious"]
        or sName == self.L["Fleshmonger Vratorg"] then
        -- Common behavior.
        if self.L["Teleport"] == sCastName then
            if mod:GetSetting("SoundPhase2Alert") then
                core:PlaySound("Alert")
            end
        end
        -- Specific behavior.
        if sName == self.L["Golgox the Lifecrusher"] then
            if self.L["Teleport"] == sCastName then
                mod:AddMsg("InfoPhase", "Phase 2: GOLGOX! (20 IA)", 5, nil, "blue")
                mod:AddTimerBar("P2Timeout", "P2: Timeout 20 IA", PHASE2_DURATION)
                eBossPhase2 = PHASE2_TYPE_GOLGOX
            end
        elseif sName == self.L["Terax Blightweaver"] then
            if self.L["Teleport"] == sCastName then
                mod:AddMsg("InfoPhase", "Phase 2: TERAX! (Mini adds)", 5, nil, "blue")
                mod:AddTimerBar("P2Timeout", "P2: Timeout mini adds", PHASE2_DURATION)
                eBossPhase2 = PHASE2_TYPE_TERAX
            elseif self.L["Stitching Strain"] == sCastName then
                local tUnit = GetUnitById(nId)
                if self:GetDistanceBetweenUnits(GetPlayerUnit(), tUnit) < 35 then
                    if mod:GetSetting("SoundInterruptTerax") then
                        core:PlaySound("Alarm")
                    end
                    mod:AddMsg("INTSTRAIN", "INTERRUPT TERAX!", 5, nil, "red")
                end
            end
        elseif sName == self.L["Ersoth Curseform"] then
            if self.L["Teleport"] == sCastName then
                mod:AddMsg("InfoPhase", "Phase 2: ERSOTH! (Subdue)", 5, nil, "blue")
                mod:AddTimerBar("P2Timeout", "P2: Timeout subdue", PHASE2_DURATION)
                eBossPhase2 = PHASE2_TYPE_ERSOTH
            elseif self.L["Gathering Energy"] == sCastName then
                if mod:GetSetting("CircleErsothInterruptDist") then
                    core:AddPolygon("ErsothCircle1", nId, 10, 0, 3, "red", 20)
                    core:AddPolygon("ErsothCircle2", nId, 20, 0, 3, "xkcdOrangeyRed", 20)
                    core:AddPolygon("ErsothCircle3", nId, 30, 0, 3, "xkcdOrange", 20)
                end
            end
        elseif sName == self.L["Noxmind the Insidious"] then
            if self.L["Teleport"] == sCastName then
                mod:AddMsg("InfoPhase", "Phase 2: NOXMIND! (Pillars)", 5, nil, "blue")
                mod:AddTimerBar("P2Timeout", "P2: Timeout pillars", PHASE2_DURATION)
                eBossPhase2 = PHASE2_TYPE_NOXMIND
            end
        elseif sName == self.L["Fleshmonger Vratorg"] then
            if self.L["Teleport"] == sCastName then
                mod:AddMsg("InfoPhase", "Phase 2: VRATORG! (Shield)", 5, nil, "blue")
                mod:AddTimerBar("P2Timeout", "P2: Timeout shield", PHASE2_DURATION)
                eBossPhase2 = PHASE2_TYPE_VRATORG
            end
        end
    end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
    if sName == self.L["Golgox the Lifecrusher"]
        or sName == self.L["Terax Blightweaver"]
        or sName == self.L["Ersoth Curseform"]
        or sName == self.L["Noxmind the Insidious"]
        or sName == self.L["Fleshmonger Vratorg"] then
        -- Common behavior.
        if self.L["Gathering Energy"] == sCastName then
            mod:RemoveTimerBar("P2Timeout")
            -- Specific behavior.
            if sName == self.L["Ersoth Curseform"] then
                core:RemovePolygon("ErsothCircle1")
                core:RemovePolygon("ErsothCircle2")
                core:RemovePolygon("ErsothCircle3")
            end
            if eBossPhase2 then
                -- Next Equalization is at:
                --  * Just after the MoO, when this last is interrupted interrupted.
                --    In other words, at the end of the "Channeling Energy", which
                --    is in same time as the end of "Gathering Energy".
                --  * Or 5 seconds after the end of the "Channeling Energy" when
                --    this last haven't been interrupted.
                --    Note: "Gathering Energy" cast end is reached before the "Channeling Energy".
                nNextEqualization = bInterrupted and 15 or 5
                eBossPhase2 = nil
            end
        elseif self.L["Channeling Energy"] == sCastName then
            if not nNextP2Time then
                nNextP2Time = GetGameTime() + PHASE1_DURATION
                mod:AddTimerBar("NextP2", "Next P2", PHASE1_DURATION, mod:GetSetting("SoundPhase2CountDown"))
                if tBossesId[self.L["Noxmind the Insidious"]] then
                    mod:AddTimerBar("NextEqualize", "Next equalization", nNextEqualization)
                end
            end
        end
    end
end

function mod:OnDatachron(sMessage)
    if sMessage:find(self.L["The Phageborn Convergence begins gathering its power"]) then
        nNextP2Time = nil
        -- 15 is the MoO duration.
        nNextEqualization = 15
        mod:RemoveTimerBar("NextP2")
        mod:RemoveTimerBar("NextEqualize")
    elseif sMessage:find(self.L["Noxmind the Insidious prepares to equalize the Convergence!"]) then
        local nRemainTimeBeforeP2 = nNextP2Time - GetGameTime()
        if DEFAULT_EQUALIZATION_DURATION < nRemainTimeBeforeP2 then
            mod:AddTimerBar("NextEqualize", "Next equalization", DEFAULT_EQUALIZATION_DURATION)
        end
    end
end
