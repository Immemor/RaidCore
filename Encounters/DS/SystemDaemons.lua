--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("SystemDaemons", 52, 98, 105)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Binary System Daemon", "Null System Daemon" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Binary System Daemon"] = "Binary System Daemon",
    ["Null System Daemon"] = "Null System Daemon",
    ["Brute Force Algorithm"] = "Brute Force Algorithm",
    ["Encryption Program"] = "Encryption Program",
    ["Radiation Dispersion Unit"] = "Radiation Dispersion Unit",
    ["Defragmentation Unit"] = "Defragmentation Unit",
    ["Extermination Sequence"] = "Extermination Sequence",
    ["Data Compiler"] = "Data Compiler",
    ["Viral Diffusion Inhibitor"] = "Viral Diffusion Inhibitor",
    ["Enhancement Module"] = "Enhancement Module",
    ["Conduction Unit Mk. I"]  = "Conduction Unit Mk. I",
    ["Conduction Unit Mk. II"]  = "Conduction Unit Mk. II",
    ["Conduction Unit Mk. III"]  = "Conduction Unit Mk. III",
    ["Infinite Generator Core"] = "Infinite Generator Core",
    ["Recovery Protocol"] = "Recovery Protocol",
    -- Datachron messages.
    ["INVALID SIGNAL. DISCONNECTING"] = "INVALID SIGNAL. DISCONNECTING",
    ["COMMENCING ENHANCEMENT SEQUENCE"] = "COMMENCING ENHANCEMENT SEQUENCE",
    -- Cast.
    ["Repair Sequence"] = "Repair Sequence",
    ["Power Surge"] = "Power Surge",
    ["Black IC"] = "Black IC",
    -- Bar and messages.
    ["[%u] Probe"] = "[%u] Probe",
    ["[%u] WAVE"] = "[%u] WAVE",
    ["[%u] MINIBOSS"] = "[%u] MINIBOSS",
    ["MARKER north"] = "N",
    ["MARKER south"] = "S",
    ["P2 SOON !"] = "P2 SOON !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["INTERRUPT NORTH"] = "INTERRUPT NORTH",
    ["INTERRUPT SOUTH"] = "INTERRUPT SOUTH",
    ["AIDDDDDDDS !"] = "AIDDDDDDDS !",
    ["PURGE - %s"] = "PURGE - %s",
    ["INTERRUPT !"] = "INTERRUPT !",
    ["INTERRUPT HEAL!"] = "INTERRUPT HEAL!",
    ["BLACK IC"] = "BLACK IC",
    ["HEAL"] = "HEAL",
    ["PURGE ON YOU"] = "PURGE ON YOU",
    ["Probe Spawn"] = "Probe Spawn",
    ["DISCONNECT (%u)"] = "DISCONNECT (%u)",
    ["YOU ARE NEXT ON NORTH !"] = "YOU ARE NEXT ON NORTH !",
    ["YOU ARE NEXT ON SOUTH !"] = "YOU ARE NEXT ON SOUTH !",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Binary System Daemon"] = "Daemon 2.0",
    ["Null System Daemon"] = "Daemon 1.0",
    ["Brute Force Algorithm"] = "Algorithme de force brute",
    ["Encryption Program"] = "Programme de cryptage",
    ["Radiation Dispersion Unit"] = "Unité de dispersion de radiations",
    ["Defragmentation Unit"] = "Unité de défragmentation",
    ["Extermination Sequence"] = "Séquence d'extermination",
    ["Data Compiler"] = "Compilateur de données",
    ["Viral Diffusion Inhibitor"] = "Inhibiteur de diffusion virale",
    ["Enhancement Module"] = "Module d'amélioration",
    ["Conduction Unit Mk. I"]  = "Unité de conductivité v1",
    ["Conduction Unit Mk. II"]  = "Unité de conductivité v2",
    ["Conduction Unit Mk. III"]  = "Unité de conductivité v3",
    ["Infinite Generator Core"] = "Noyau du générateur d'infinité",
    ["Recovery Protocol"] = "Protocole de récupération",
    -- Datachron messages.
    ["INVALID SIGNAL. DISCONNECTING"] = "SIGNAL INCORRECT.",
    ["COMMENCING ENHANCEMENT SEQUENCE"] = "DÉBUT DE LA SEQUENCE D'AMÉLIORATION",
    -- Cast.
    ["Repair Sequence"] = "Séquence de réparation",
    ["Power Surge"] = "Afflux d'énergie",
    ["Black IC"] = "CI noir",
    -- Bar and messages.
    --["[%u] Probe"] = "[%u] Probe", -- TODO: French translation missing !!!!
    ["[%u] WAVE"] = "[%u] WAVE",
    --["[%u] MINIBOSS"] = "[%u] MINIBOSS", -- TODO: French translation missing !!!!
    ["MARKER north"] = "N",
    ["MARKER south"] = "S",
    ["P2 SOON !"] = "P2 SOON !",
    ["PHASE 2 !"] = "PHASE 2 !",
    --["INTERRUPT NORTH"] = "INTERRUPT NORTH", -- TODO: French translation missing !!!!
    --["INTERRUPT SOUTH"] = "INTERRUPT SOUTH", -- TODO: French translation missing !!!!
    --["AIDDDDDDDS !"] = "AIDDDDDDDS !", -- TODO: French translation missing !!!!
    --["PURGE - %s"] = "PURGE - %s", -- TODO: French translation missing !!!!
    --["INTERRUPT !"] = "INTERRUPT !", -- TODO: French translation missing !!!!
    --["INTERRUPT HEAL!"] = "INTERRUPT HEAL!", -- TODO: French translation missing !!!!
    --["BLACK IC"] = "BLACK IC", -- TODO: French translation missing !!!!
    --["HEAL"] = "HEAL", -- TODO: French translation missing !!!!
    --["PURGE ON YOU"] = "PURGE ON YOU", -- TODO: French translation missing !!!!
    --["Probe Spawn"] = "Probe Spawn", -- TODO: French translation missing !!!!
    --["DISCONNECT (%u)"] = "DISCONNECT (%u)", -- TODO: French translation missing !!!!
    --["YOU ARE NEXT ON NORTH !"] = "YOU ARE NEXT ON NORTH !", -- TODO: French translation missing !!!!
    --["YOU ARE NEXT ON SOUTH !"] = "YOU ARE NEXT ON SOUTH !", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Binary System Daemon"] = "Binärsystem-Dämon",
    ["Null System Daemon"] = "Nullsystem-Dämon",
    ["Brute Force Algorithm"] = "Brachialgewalt-Algorithmus",
    ["Encryption Program"] = "Verschlüsselungsprogramm",
    ["Radiation Dispersion Unit"] = "Strahlungsverteilungseinheit",
    ["Defragmentation Unit"] = "Defragmentierungseinheit",
    ["Extermination Sequence"] = "Vernichtungssequenz",
    ["Data Compiler"] = "Datenkompilierer",
    ["Viral Diffusion Inhibitor"] = "Virushemmstoff",
    ["Enhancement Module"] = "Verbesserungsmodul",
    ["Conduction Unit Mk. I"]  = "Leistungseinheit V1",
    ["Conduction Unit Mk. II"]  = "Leistungseinheit V2",
    ["Conduction Unit Mk. III"]  = "Leistungseinheit V3",
    ["Infinite Generator Core"] = "Infiniter Generatorkern",
    ["Recovery Protocol"] = "Wiederherstellungsprotokoll",
    -- Datachron messages.
    ["INVALID SIGNAL. DISCONNECTING"] = "UNGÜLTIGES SIGNAL. VERBINDUNG ZU",
    ["COMMENCING ENHANCEMENT SEQUENCE"] = "BEGINNE VERBESSERUNGSSEQUENZ",
    -- Cast.
    ["Repair Sequence"] = "Reparatursequenz",
    ["Power Surge"] = "Energieschweller",
    ["Black IC"] = "Glatteis",
    -- Bar and messages.
    ["[%u] Probe"] = "[%u] Sonde",
    ["[%u] WAVE"] = "[%u] WELLE",
    ["[%u] MINIBOSS"] = "[%u] MINIBOSS",
    ["MARKER north"] = "N",
    ["MARKER south"] = "S",
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    ["PHASE 2 !"] = "PHASE 2 !",
    ["INTERRUPT NORTH"] = "UNTERBRECHE NORDEN",
    ["INTERRUPT SOUTH"] = "UNTERBRECHE SÜDEN",
    ["AIDDDDDDDS !"] = "AIDDDDDDDS !",
    ["PURGE - %s"] = "SÄUBERN - %s",
    ["INTERRUPT !"] = "UNTERBRECHEN !",
    ["INTERRUPT HEAL!"] = "HEILUNG UNTERBRECHEN !",
    ["BLACK IC"] = "GLATTEIS",
    ["HEAL"] = "HEILUNG",
    ["PURGE ON YOU"] = "STEHEN BLEIBEN !!!",
    ["Probe Spawn"] = "Sonde Spawn",
    ["DISCONNECT (%u)"] = "TRENNUNG (%u)",
    ["YOU ARE NEXT ON NORTH !"] = "DU BIST DER NÄCHSTE IM NORDEN !",
    ["YOU ARE NEXT ON SOUTH !"] = "DU BIST DER NÄCHSTE IM SÜDEN !",
})

--------------------------------------------------------------------------------
-- Locals
--

local PILLARS_POSITIONS = {
    ["mid1"] = {
        ["N1"] = { x = 133.217, y = -225.94, z = -207.71 },
        ["N2"] = { x = 109.22, y = -225.94, z = -150.85 },
        ["N3"] = { x = 109.23, y = -225.94, z = -198.13 },
        ["S1"] = { x = 133.17, y = -225.94, z = -140.96 },
        ["S2"] = { x = 156.79, y = -225.94, z = -198.126 },
        ["S3"] = { x = 156.80, y = -225.94, z = -150.82 },
    },
    ["mid2"] = {
        ["N1"] = { x = 109.23, y = -225.94, z = -198.12 },
        ["N2"] = { x = 156.79, y = -225.94, z = -198.12 },
        ["N3"] = { x = 99.91, y = -225.99, z = -174.35 },
        ["N4"] = { x = 133.21, y = -225.94, z = -207.71 },
        ["S1"] = { x = 109.22, y = -225.94, z = -150.85 },
        ["S2"] = { x = 156.80, y = -225.94, z = -150.82 },
        ["S3"] = { x = 133.17, y = -225.94, z = -140.93 },
        ["S4"] = { x = 166.56, y = -225.94, z = -174.30 },
    },
}

local discoCount, sdwaveCount, probeCount, sdSurgeCount, PurgeLast = 0, 0, 0, {}, {}
local phase2warn, phase2 = false, false
local phase2count = 0
local intNorth, intSouth = nil, nil
local prev = 0
local nbKick = 2
local playerName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("RAID_SYNC", "OnSyncRcv", self)
    Apollo.RegisterEventHandler("SubZoneChanged", "OnZoneChanged", self)
    Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnReset()
    core:ResetWorldMarkers()
    phase2count = 0
end

function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Brute Force Algorithm"]
        or sName == self.L["Encryption Program"]
        or sName == self.L["Radiation Dispersion Unit"]
        or sName == self.L["Defragmentation Unit"]
        or sName == self.L["Extermination Sequence"]
        or sName == self.L["Data Compiler"]
        or sName == self.L["Viral Diffusion Inhibitor"] then

        if phase2 then return end
        local timeOfEvent = GameLib.GetGameTime()
        if timeOfEvent - prev > 48 then
            prev = timeOfEvent
            sdwaveCount = sdwaveCount + 1
            probeCount = 0
            if sdwaveCount == 1 then
                core:AddMsg("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount), 5, mod:GetSetting("SoundWave", "Info"), "Blue")
                core:AddBar("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount + 1), 50, mod:GetSetting("SoundWave"))
            elseif sdwaveCount % 2 == 0 then
                core:AddMsg("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount), 5, mod:GetSetting("SoundWave", "Info"), "Blue")
                core:AddBar("SDWAVE", self.L["[%u] MINIBOSS"]:format(sdwaveCount + 1), 50, mod:GetSetting("SoundWave"))
            else
                core:AddMsg("SDWAVE", self.L["[%u] MINIBOSS"]:format(sdwaveCount), 5, mod:GetSetting("SoundWave", "Info"), "Blue")
                core:AddBar("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount + 1), 50, mod:GetSetting("SoundWave"))
            end
            core:AddBar("PROBES", self.L["[%u] Probe"]:format(1), 10)
        end
    elseif sName == self.L["Conduction Unit Mk. I"] then
        if probeCount == 0 then probeCount = 1 end
        if GetCurrentSubZoneName():find(self.L["Infinite Generator Core"]) then core:MarkUnit(unit, 1, 1) end
        core:AddBar("PROBES", self.L["[%u] Probe"]:format(2), 10)
    elseif sName == self.L["Conduction Unit Mk. II"] then
        if probeCount == 1 then probeCount = 2 end
        if GetCurrentSubZoneName():find(self.L["Infinite Generator Core"]) then core:MarkUnit(unit, 1, 2) end
        core:AddBar("PROBES", self.L["[%u] Probe"]:format(3), 10)
    elseif sName == self.L["Conduction Unit Mk. III"] then
        if probeCount == 2 then probeCount = 3 end
        if GetCurrentSubZoneName():find(self.L["Infinite Generator Core"]) then core:MarkUnit(unit, 1, 3) end
    elseif sName == self.L["Enhancement Module"] then
        core:AddUnit(unit)
        if mod:GetSetting("LineOnModulesMidphase") then
            core:AddLine(unit:GetId().."_1", 2, unit, nil, 1, 25, 90)
            core:AddLine(unit:GetId().."_2", 2, unit, nil, 2, 25, -90)
        end
    elseif sName == self.L["Recovery Protocol"] then
        core:WatchUnit(unit)
    end
end

function mod:OnUnitDestroyed(unit, sName)
    if sName == self.L["Enhancement Module"] then
        core:DropLine(unit:GetId().."_1")
        core:DropLine(unit:GetId().."_2")
    end
end

function mod:OnHealthChanged(unitName, health)
    if health >= 70 and health <= 72 and not phase2warn and not phase2 then
        phase2warn = true
        core:AddMsg("SDP2", self.L["P2 SOON !"], 5, mod:GetSetting("SoundPhase2", "Algalon"))
    elseif health >= 30 and health <= 32 and not phase2warn and not phase2 then
        phase2warn = true
        core:AddMsg("SDP2", self.L["P2 SOON !"], 5, mod:GetSetting("SoundPhase2", "Algalon"))
    end
end

function mod:OnSpellCastEnd(unitName, castName, unit)
    if unitName == self.L["Recovery Protocol"] and castName == self.L["Repair Sequence"] then
        core:DropMark(unit:GetId())
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Binary System Daemon"] and castName == self.L["Power Surge"] then
        core:SendSync("NORTH_SURGE", unit:GetId())
        if phase2 and self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), unit) < 40 then
            core:AddMsg("SURGE", self.L["INTERRUPT NORTH"], 5, mod:GetSetting("SoundPowerSurge", "Alert"))
        end
    elseif unitName == self.L["Null System Daemon"] and castName == self.L["Power Surge"] then
        core:SendSync("SOUTH_SURGE", unit:GetId())
        if phase2 and self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), unit) < 40 then
            core:AddMsg("SURGE", self.L["INTERRUPT SOUTH"], 5, mod:GetSetting("SoundPowerSurge", "Alert"))
        end
    elseif castName == "Purge" then
        PurgeLast[unit:GetId()] = GameLib.GetGameTime()
        if self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), unit) < 40 then
            core:AddMsg("PURGE", self.L["AIDDDDDDDS !"], 5, mod:GetSetting("SoundPurge", "Beware"))
            if unitName == self.L["Null System Daemon"] then
                core:AddBar("PURGE_"..unit:GetId(), self.L["PURGE - %s"]:format("NULL"), 27)
            elseif unitName == self.L["Binary System Daemon"] then
                core:AddBar("PURGE_"..unit:GetId(), self.L["PURGE - %s"]:format("BINARY"), 27)
            end
        elseif phase2 then
            if unitName == self.L["Null System Daemon"] then
                core:AddBar("PURGE_"..unit:GetId(), self.L["PURGE - %s"]:format("NULL"), 27)
            elseif unitName == self.L["Binary System Daemon"] then
                core:AddBar("PURGE_"..unit:GetId(), self.L["PURGE - %s"]:format("BINARY"), 27)
            end
        end
    elseif unitName == self.L["Defragmentation Unit"] and castName == self.L["Black IC"] then
        core:AddMsg("BLACKIC", self.L["INTERRUPT !"], 5, "Alert")
        core:AddBar("BLACKIC", self.L["BLACK IC"], 30)
    elseif unitName == self.L["Recovery Protocol"] and castName == self.L["Repair Sequence"] then
        if self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), unit) < 50 then
            core:AddMsg("HEAL", self.L["INTERRUPT HEAL!"], 5, mod:GetSetting("SoundRepairSequence", "Inferno"))
            core:MarkUnit(unit, nil, self.L["HEAL"])
            self:ScheduleTimer("RemoveHealMarker", 5, unit)
        end
    end
end

function mod:RemoveHealMarker(unit)
    if not unit then return end
    core:DropMark(unit:GetId())
end

function mod:OnDebuffApplied(unitName, splId, unit)
    local eventTime = GameLib.GetGameTime()
    local tSpell = GameLib.GetSpell(splId)
    local strSpellName = tSpell:GetName()
    if strSpellName == "Overload" then
        if mod:GetSetting("OtherOverloadMarkers") then
            core:MarkUnit(unit, nil, "DOT DMG")
        end
    elseif strSpellName == "Purge" then
        if mod:GetSetting("OtherPurgePlayerMarkers") then
            core:MarkUnit(unit, nil, "PURGE")
        end
        if unitName == playerName then
            core:AddMsg("PURGEDEBUFF", self.L["PURGE ON YOU"], 5, mod:GetSetting("SoundPurge", "Beware"))
        end
    end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
    local eventTime = GameLib.GetGameTime()
    local tSpell = GameLib.GetSpell(splId)
    local strSpellName = tSpell:GetName()
    if strSpellName == "Overload" then
        core:DropMark(unit:GetId())
    elseif strSpellName == "Purge" then
        core:DropMark(unit:GetId())
    end
end

function mod:OnZoneChanged(zoneId, zoneName)
    if zoneName == "Datascape" then
        return
    elseif zoneName == "Halls of the Infinite Mind" then
        local timeOfEvent = GameLib.GetGameTime()
        for id, timer in pairs(PurgeLast) do
            local unit = GameLib.GetUnitById(id)
            if unit and (self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), unit) < 40 or phase2) then
                if timeOfEvent - timer < 27 then
                    local NO_BREAK_SPACE = string.char(194, 160)
                    local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
                    if unitName == self.L["Null System Daemon"] then
                        core:AddBar("PURGE_".. id, self.L["PURGE - %s"]:format("NULL"), timer + 27 - timeOfEvent)
                    elseif unitName == self.L["Binary System Daemon"] then
                        core:AddBar("PURGE_".. id, self.L["PURGE - %s"]:format("BINARY"), timer + 27 - timeOfEvent)
                    end
                end
            end
        end
    elseif zoneName:find("Infinite Generator Core") then
        for id, timer in pairs(PurgeLast) do
            core:StopBar("PURGE_" .. id)
        end
        local probesouth = { x = 95.89, y = -337.19, z = 211.26 }
        core:SetWorldMarker("PROBE_SOUTH", self.L["Probe Spawn"], probesouth)
    end
end

function mod:NextWave()
    if probeCount == 3 then
        if sdwaveCount % 2 == 0 then
            core:AddBar("SDWAVE", self.L["[%u] MINIBOSS"]:format(sdwaveCount + 1), 90, mod:GetSetting("SoundWave"))
        else
            core:AddBar("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount + 1), 90, mod:GetSetting("SoundWave"))
        end
    else
        if sdwaveCount % 2 == 0 then
            core:AddBar("SDWAVE", self.L["[%u] MINIBOSS"]:format(sdwaveCount + 1), 110 + (2 - probeCount) * 10, mod:GetSetting("SoundWave"))
        else
            core:AddBar("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount + 1), 110 + (2 - probeCount) * 10, mod:GetSetting("SoundWave"))
        end
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["INVALID SIGNAL. DISCONNECTING"]) then
        if phase2 then
            core:ResetWorldMarkers()
            phase2 = false
            phase2warn = false
        end
        discoCount = discoCount + 1
        if mod:GetSetting("OtherDisconnectTimer") then
            core:AddBar("DISC", self.L["DISCONNECT (%u)"]:format(discoCount + 1), 60)
        end
    elseif message:find(self.L["COMMENCING ENHANCEMENT SEQUENCE"]) then
        phase2, phase2warn = true, false
        phase2count = phase2count + 1
        core:StopBar("DISC")
        core:StopBar("SDWAVE")
        core:AddMsg("SDP2", self.L["PHASE 2 !"], 5, mod:GetSetting("SoundPhase2", "Alarm"))
        if mod:GetSetting("OtherDisconnectTimer") then
            core:AddBar("DISC", self.L["DISCONNECT (%u)"]:format(discoCount + 1), 85)
        end
        if mod:GetSetting("OtherPillarMarkers") and phase2count == 1 then
            for key, value in pairs(PILLARS_POSITIONS["mid1"]) do
                core:SetWorldMarker(key, key, value)
            end
        elseif mod:GetSetting("OtherPillarMarkers") and phase2count == 2 then
            for key, value in pairs(PILLARS_POSITIONS["mid2"]) do
                core:SetWorldMarker(key, key, value)
            end
        end
        self:ScheduleTimer("NextWave", 5)
    end
end

function mod:OnSyncRcv(sync, parameter)
    if sync == "NORTH_SURGE" then
        if intNorth and intNorth == sdSurgeCount[parameter] and not phase2 then
            core:AddMsg("SURGE", self.L["INTERRUPT NORTH"], 5, "Alert")
        end

        sdSurgeCount[parameter] = sdSurgeCount[parameter] + 1
        if sdSurgeCount[parameter] > nbKick then sdSurgeCount[parameter] = 1 end

        if intNorth and intNorth == sdSurgeCount[parameter] then
            core:AddMsg("SURGE", self.L["YOU ARE NEXT ON NORTH !"], 5, "Long", "Blue")
        end
    elseif sync == "SOUTH_SURGE" then
        if intSouth and intSouth == sdSurgeCount[parameter] and not phase2 then
            core:AddMsg("SURGE", self.L["INTERRUPT SOUTH"], 5, "Alert")
        end

        sdSurgeCount[parameter] = sdSurgeCount[parameter] + 1
        if sdSurgeCount[parameter] > nbKick then sdSurgeCount[parameter] = 1 end

        if intSouth and intSouth == sdSurgeCount[parameter] then
            core:AddMsg("SURGE", self.L["YOU ARE NEXT ON SOUTH !"], 5, "Long", "Blue")
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Null System Daemon"] or sName == self.L["Binary System Daemon"] then
            if sName == self.L["Null System Daemon"] then
                core:MarkUnit(unit, 0, self.L["MARKER south"])
            else
                core:MarkUnit(unit, 0, self.L["MARKER north"])
            end
            discoCount, sdwaveCount, probeCount = 0, 0, 0
            phase2warn, phase2 = false, false
            phase2count = 0
            sdSurgeCount[unit:GetId()] = 1
            PurgeLast[unit:GetId()] = 0
            playerName = GameLib.GetPlayerUnit():GetName()
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:RaidDebuff()
            core:AddSync("NORTH_SURGE", 5)
            core:AddSync("SOUTH_SURGE", 5)
            if mod:GetSetting("OtherDisconnectTimer") then
                core:AddBar("DISC", self.L["DISCONNECT (%u)"]:format(discoCount + 1), 41)
            end
            core:AddBar("SDWAVE", self.L["[%u] WAVE"]:format(sdwaveCount + 1), 15, mod:GetSetting("SoundWave"))
        elseif sName == self.L["Defragmentation Unit"] then
            if GetCurrentSubZoneName():find("Infinite Generator Core") then
                core:WatchUnit(unit)
            end
        end
    end
end

function mod:SetInterrupter(position, num)
    if num > nbKick then
        Print("MORON ! Set a good number")
        return
    end
    if position:lower() == "north" then
        intNorth = num
        Print(("Position %s set for North Boss"):format(num))
    elseif position:lower() == "south" then
        intSouth = num
        Print(("Position %s set for South Boss"):format(num))
    else 
        Print(("Bad Position : %s"):format(position))
    end
end
