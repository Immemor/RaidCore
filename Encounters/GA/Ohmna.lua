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
local mod = core:NewEncounter("Ohmna", 67, 147, 149)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Dreadphage Ohmna" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Dreadphage Ohmna"] = "Dreadphage Ohmna",
    ["Tentacle of Ohmna"] = "Tentacle of Ohmna",
    ["Ravenous Maw of the Dreadphage"] = "Ravenous Maw of the Dreadphage",
    -- Datachron messages.
    ["A plasma leech begins draining"] = "A plasma leech begins draining",
    ["Dreadphage Ohmna submerges"] = "Dreadphage Ohmna submerges",
    ["Dreadphage Ohmna is bored"] = "Dreadphage Ohmna is bored with (.*)!",
    ["The Archives tremble as Dreadphage Ohmna"] = "The Archives tremble as Dreadphage Ohmna",
    ["The Archives quake with the furious might"] = "The Archives quake with the furious might",
    -- Objectifs.
    ["North Power Core Energy"] = "North Power Core Energy",
    ["South Power Core Energy"] = "South Power Core Energy",
    ["East Power Core Energy"] = "East Power Core Energy",
    ["West Power Core Energy"] = "West Power Core Energy",
    -- Cast.
    ["Erupt"] = "Erupt",
    ["Genetic Torrent"] = "Genetic Torrent",
    -- Bar and messages.
    ["Next Tentacles"] = "Next Tentacles",
    ["Tentacles"] = "Tentacles",
    ["P2 SOON !"] = "P2 SOON !",
    ["P2: TENTACLES"] = "P2: TENTACLES",
    ["PHASE 2"] = "PHASE 2",
    ["P3 SOON !"] = "P3 SOON !",
    ["P3: RAVENOUS"] = "P3: RAVENOUS",
    ["P3 REALLY SOON !"] = "P3 REALLY SOON !",
    ["PILLAR %u : %s"] = "PILLAR %u : %s",
    ["PILLAR %u"] = "PILLAR %u",
    ["SWITCH TANK"] = "SWITCH TANK",
    ["BIG SPEW"] = "BIG SPEW",
    ["NEXT BIG SPEW"] = "NEXT BIG SPEW",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Dreadphage Ohmna"] = "Ohmna la Terriphage",
    ["Tentacle of Ohmna"] = "Tentacule d'Ohmna",
    ["Ravenous Maw of the Dreadphage"] = "Gueule vorace de la Terriphage",
    -- Datachron messages.
    ["A plasma leech begins draining"] = "Une Sangsue à plasma commence à vider la cellule énergétique (.*) !",
    ["Dreadphage Ohmna submerges"] = "Ohmna la Terriphage s'immerge dans les bassins de Biophage.",
    ["Dreadphage Ohmna is bored"] = "(.*) n'amuse plus Ohmna la Terriphage !",
    ["The Archives tremble as Dreadphage Ohmna"] = "Les Archives tremblent alors que les tentacules d'Ohmna la Terriphage font surface autour de vous !",
    ["The Archives quake with the furious might"] = "Les Archives tremblent sous la puissance terrible de la Terriphage.",
    -- Objectifs.
    ["North Power Core Energy"] = "Puissance de la cellule énergétique nord",
    ["South Power Core Energy"] = "Puissance de la cellule énergétique sud",
    ["East Power Core Energy"] = "Puissance de la cellule énergétique est",
    ["West Power Core Energy"] = "Puissance de la cellule énergétique ouest",
    -- Cast.
    ["Erupt"] = "Erupt",
    ["Genetic Torrent"] = "Torrent génétique",
    -- Bar and messages.
    ["Next Tentacles"] = "Prochaine Tentacules",
    ["Tentacles"] = "Tentacules",
    ["P2 SOON !"] = "P2 SOON !",
    ["P2: TENTACLES"] = "P2: TENTACULES",
    ["PHASE 2"] = "PHASE 2",
    ["P3 SOON !"] = "P3 BIENTÔT !",
    ["P3: RAVENOUS"] = "P3: AFFAMÉ",
    ["P3 REALLY SOON !"] = "P3 RÉELLEMENT BIENTÔT !",
    ["PILLAR %u : %s"] = "PILLIER %u : %s",
    ["PILLAR %u"] = "PILLIER %u",
    ["SWITCH TANK"] = "CHANGEMENT TANK",
    ["BIG SPEW"] = "TORRENT",
    ["NEXT BIG SPEW"] = "PROCHAIN TORRENT",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Dreadphage Ohmna"] = "Schreckensphage Ohmna",
    ["Tentacle of Ohmna"] = "Tentakel von Ohmna",
    ["Ravenous Maw of the Dreadphage"] = "Unersättliches Maul der Schreckensphage",
    -- Datachron messages.
    ["A plasma leech begins draining"] = "Ein Plasmaegel beginnt, den",
    ["Dreadphage Ohmna submerges"] = "Die Schreckensphage Ohmna taucht in den",
    ["Dreadphage Ohmna is bored"] = "Die Schreckensphage Ohmna langweilt sich",
    ["The Archives tremble as Dreadphage Ohmna"] = "Die Archive beben, als die Tentakeln der Schreckensphage Ohmna um dich herum auftauchen",
    ["The Archives quake with the furious might"] = "Die Archive beben unter der wütenden Macht der Schreckensphage",
    -- Objectifs.
    ["North Power Core Energy"] = "Nördliche Kraftkernenergie",
    ["South Power Core Energy"] = "Südliche Kraftkernenergie",
    ["East Power Core Energy"] = "Östliche Kraftkernenergie",
    ["West Power Core Energy"] = "Westliche Kraftkernenergie",
    -- Cast.
    ["Erupt"] = "Ausbrechen",
    ["Genetic Torrent"] = "Genetische Strömung",
    -- Bar and messages.
    ["Next Tentacles"] = "NÄCHSTE TENTAKEL",
    ["Tentacles"] = "TENTAKEL",
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    ["P2: TENTACLES"] = "P2: TENTAKEL",
    ["PHASE 2"] = "PHASE 2",
    ["P3 SOON !"] = "GLEICH PHASE 3 !",
    ["P3: RAVENOUS"] = "P3: GROßE WÜRMER",
    ["P3 REALLY SOON !"] = "17 % | VORSICHT MIT DAMAGE",
    ["PILLAR %u : %s"] = "SÄULE %u : %s",
    ["PILLAR %u"] = "SÄULE %u",
    ["SWITCH TANK"] = "AGGRO ZIEHEN !!!",
    ["BIG SPEW"] = "GROßES BRECHEN",
    ["NEXT BIG SPEW"] = "NÄCHSTES GROßES BRECHEN",
})
-- Default settings.
mod:RegisterDefaultSetting("LineSafeZoneOhmna")
mod:RegisterDefaultSetting("LineRavenousMaw")
mod:RegisterDefaultSetting("SoundBigSpew")
mod:RegisterDefaultSetting("OtherRavenousMawMarker")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local pilarCount, boreCount, submergeCount = 0, 0, 0
local firstPull, OhmnaP3, OhmnaP4 = true, false, false

local function getMax(t)
    local max_val, key = -1000, ""
    for k, v in pairs(t) do
        if max_val < v then
            max_val, key = v, k
        elseif max_val == v then
            key = key .. " / " .. k
        end
    end
    return max_val, key
end

local function getMin(t)
    local min_val, key = 1000, ""
    for k, v in pairs(t) do
        -- Ignore pillars that are on 0%
        if min_val > v and v > 0 then
            min_val, key = v, k
        elseif min_val == v then
            key = key .. " / " .. k
        end
    end
    return min_val, key
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    pilarCount, boreCount, submergeCount = 1, 0, 0
    firstPull, OhmnaP3, OhmnaP4 = true, false, false
    mod:AddTimerBar("OPILAR", self.L["PILLAR %u"]:format(pilarCount), 25)
    if self:Tank() then
        mod:AddTimerBar("OBORE", "SWITCH TANK", 45)
    end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    if sName == self.L["Dreadphage Ohmna"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        if mod:GetSetting("LineSafeZoneOhmna") then
            core:AddSimpleLine("Ohmna1", nId, nil, 25, 0, nil, "xkcdGreen", 20)
            core:AddSimpleLine("Ohmna2", nId, nil, 25, 120, nil, "xkcdBlue", 20)
            core:AddSimpleLine("Ohmna3", nId, nil, 25, -120, nil, "xkcdBlue", 20)
        end
    elseif sName == self.L["Tentacle of Ohmna"] then
        if not OhmnaP4 then
            mod:AddMsg("OTENT", "Tentacles", 5, "Info", "Blue")
            mod:AddTimerBar("OTENT", "Next Tentacles", 20)
        end
    elseif sName == self.L["Ravenous Maw of the Dreadphage"] then
        -- Phase 3: 3 units will pop.
        if mod:GetSetting("OtherRavenousMawMarker") then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
            core:MarkUnit(tUnit, 0)
        end
        if mod:GetSetting("LineRavenousMaw") then
            core:AddSimpleLine(nId, nId, nil, 25, 0, nil, "xkcdBrightYellow", 20)
        end
    end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
    if sName == self.L["Dreadphage Ohmna"] then
        if nPourcent == 52 then
            mod:AddMsg("OP2", "P2 SOON !", 5, "Alert")
        elseif nPourcent == 20 then
            mod:AddMsg("OP3", "P3 SOON !", 5, "Alert")
        elseif nPourcent == 17 then
            mod:AddMsg("OP3", "P3 REALLY SOON !", 5, "Alert")
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sName == self.L["Dreadphage Ohmna"] then
        if sCastName == self.L["Erupt"] then
            if OhmnaP3 then return end
            local pilarActivated = self:OhmnaPE(pilarCount % 2)
            mod:AddTimerBar("OPILAR", self.L["PILLAR %u : %s"]:format(pilarCount, pilarActivated), 32)
            if self:Tank() then
                mod:AddTimerBar("OBORE", "SWITCH TANK", 45)
            end
        elseif sCastName == self.L["Genetic Torrent"] then
            mod:AddMsg("SPEW", "BIG SPEW", 5, mod:GetSetting("SoundBigSpew") and "RunAway")
            mod:AddTimerBar("OSPEW", "NEXT BIG SPEW", OhmnaP4 and 40 or 60)
        end
    end
end

function mod:OhmnaPE(lowest)
    local tStatus = {}
    local strResult = ""
    local max_val
    local tActiveEvents = PublicEvent.GetActiveEvents()
    for idx, peEvent in pairs(tActiveEvents) do
        for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
            if peObjective:GetShortDescription() == self.L["North Power Core Energy"] then
                tStatus["NORTH"] = peObjective:GetCount()
            elseif peObjective:GetShortDescription() == self.L["South Power Core Energy"] then
                tStatus["SOUTH"] = peObjective:GetCount()
            elseif peObjective:GetShortDescription() == self.L["East Power Core Energy"] then
                tStatus["EAST"] = peObjective:GetCount()
            elseif peObjective:GetShortDescription() == self.L["West Power Core Energy"] then
                tStatus["WEST"] = peObjective:GetCount()
            end
        end
    end

    if lowest == 1 then
        max_val, strResult = getMin(tStatus)
    else
        max_val, strResult = getMax(tStatus)
    end

    return strResult
end

function mod:OnDatachron(sMessage)
    if sMessage:find(self.L["A plasma leech begins draining"]) then
        if OhmnaP3 then return end
        pilarCount = pilarCount + 1
        if submergeCount < 2 and pilarCount > 4 then
            mod:AddTimerBar("OPILAR", "PHASE 2", firstPull and 27 or 22)
            firstPull = false
        else
            local pilarActivated = self:OhmnaPE(pilarCount % 2)
            mod:AddTimerBar("OPILAR", self.L["PILLAR %u : %s"]:format(pilarCount, pilarActivated), 25)
        end
    elseif sMessage:find(self.L["Dreadphage Ohmna submerges"]) then
        pilarCount, boreCount = 1, 0
        submergeCount = submergeCount + 1
        core:RemoveTimerBar("OTENT")
    elseif sMessage:find(self.L["Dreadphage Ohmna is bored"]) then
        boreCount = boreCount + 1
        if boreCount < 2 and self:Tank() then
            mod:AddTimerBar("OBORE", "SWITCH TANK", 42)
        end
    elseif sMessage:find(self.L["The Archives tremble as Dreadphage Ohmna"]) then
        mod:AddMsg("OP2", "P2: TENTACLES", 5, "Alert")
    elseif sMessage:find(self.L["The Archives quake with the furious might"]) then
        mod:AddMsg("OP3", "P3: RAVENOUS", 5, "Alert")
        OhmnaP3 = true
        core:RemoveTimerBar("OPILAR")
        core:RemoveTimerBar("OBORE")
        mod:AddTimerBar("OSPEW", "NEXT BIG SPEW", 45)
    end
end
