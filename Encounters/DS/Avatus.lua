----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--
-- Avatus fight is split in 3 major phases, they start on threshold healh pourcent of Avatus:
--  * From 100% to 75%: Avatus itself, with all players.
--  * At 75%, there is the small labyrinth and green and blue teleporter.
--  * From 75% to 50: Avatus itself, with all players.
--  * At 50%, again the labyrinth with red and yellow teleporter.
--  * From 50% to 25%: Avatus itself, with all players.
--  * From 25% to death: Enrage phase.
--
-- In "Green" phase, there are 24 pillars. An number will be add between two pillars.
-- So 12 numbers will be displayed like this:
--
--        9
--     A     8
--   B         7
--  .     +     6
--   1         5
--     2     4
--        3
--
-- The center is { x = 618.21, z =-174.2 }, and the unit called "Unstoppable Object Simulation"
-- start on West, on the dot so. The dot Pillars are unusable.
--
-- With n from 1 to 12, coordonates are:
-- {{{
--   Angle(n) = PI + (n - 1) * PI / 6
--   Position(n) = {
--       x = 618.21 + 70 * cos(Angle(n)),
--       z = -174.2 + 70 * sin(Angle(n))
--   }
-- }}}
-- Results are stored in GREEN_ROOM_MARKERS constant.
--
-- Extra Informations. Few pillars positions collected:
-- {
--     { x = 671.276489, z = -174.475327 },
--     { x = 565.161865, z = -174.289658 },
--     { x = 618.183533, z = -227.125458 },
--     { x = 661.742126, z = -249.719589 },
--     { x = 574.576834, z = -98.386374 },
--     { x = 530.910645, z = -174.166290 },
--     { x = 645.375183, z = -128.802170 },
--     { x = 663.878540, z = -201.568573 },
--     { x = 591.531921, z = -128.216736 },
--     { x = 693.861572, z = -218.121765 },
--     { x = 705.460144, z = -174.510483 },
--     { x = 618.322693, z = -86.674301 },
--     { x = 618.349182, z = -121.058273 },
--     { x = 644.759949, z = -220.22229 },
--     { x = 542.987549, z = -129.588684 },
-- }
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Avatus", 52, 98, 104)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Avatus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holo Hand",
    ["Mobius Physics Constructor"] = "Mobius Physics Constructor",
    ["Unstoppable Object Simulation"] = "Unstoppable Object Simulation",
    ["Holo Cannon"] = "Holo Cannon",
    ["Shock Sphere"] = "Shock Sphere",
    ["Support Cannon"] = "Support Cannon",
    ["Infinite Logic Loop"] = "Infinite Logic Loop",
    ["Tower Platform"] = "Tower Platform",
    ["Augmented Rowsdower"] = "Augmented Rowsdower",
    ["Excessive Force Protocol"] = "Excessive Force Protocol",
    ["Augmented Triage Specialist"] = "Augmented Triage Specialist",
    ["Augmented Juggernaut"] = "Augmented Juggernaut",
    ["Augmented Predator"] = "Augmented Predator",
    -- Datachron messages.
    ["Portals have opened!"] = "Avatus' power begins to surge! Portals have opened!",
    ["Gun Grid Activated"] = "SECURITY PROTOCOL: Gun Grid Activated.",
    -- Cast.
    ["Crushing Blow"] = "Crushing Blow",
    ["Data Flare"] = "Data Flare",
    ["Obliteration Beam"] = "Obliteration Beam",
    -- BuffName with many ID.
    ["Red Empowerment Matrix"] = "Red Empowerment Matrix",
    ["Blue Disruption Matrix"] = "Blue Disruption Matrix",
    ["Green Reconstitution Matrix"] = "Green Reconstitution Matrix",
    -- Bar and messages.
    ["Holo Hand Spawned"] = "Holo Hand Spawned",
    ["PURGE BLUE BOSS"] = "PURGE BLUE BOSS",
    ["P2 SOON !"] = "P2 SOON !",
    ["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!",
    ["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS",
    ["Blind"] = "Blind",
    ["Gun Grid NOW!"] = "Gun Grid NOW!",
    ["~Gun Grid"] = "~Gun Grid",
    ["Hand %u"] = "Hand %u",
    ["MARKER North"] = "North",
    ["MARKER South"] = "South",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holo-main",
    ["Mobius Physics Constructor"] = "Constructeur de physique de Möbius",
    ["Unstoppable Object Simulation"] = "Simulacre invincible",
    ["Holo Cannon"] = "Holocanon",
    ["Shock Sphere"] = "Sphère de choc",
    ["Support Cannon"] = "Canon d'appui",
    ["Infinite Logic Loop"] = "Boucle de logique infinie",
    ["Tower Platform"] = "Plateforme de la tour",
    ["Augmented Rowsdower"] = "Tamarou augmenté",
    -- Datachron messages.
    ["Portals have opened!"] = "L'énergie d'Avatus commence à déferler ! Des portails se sont ouverts !",
    ["Gun Grid Activated"] = "PROTOCOLE DE SÉCURITÉ : pétoires activées.",
    -- Cast.
    ["Crushing Blow"] = "Coup écrasant",
    ["Data Flare"] = "Signal de données",
    ["Obliteration Beam"] = "Rayon de suppression",
    -- BuffName with many ID.
    ["Red Empowerment Matrix"] = "Matrice de renforcement rouge",
    ["Blue Disruption Matrix"] = "Matrice disruptive bleue",
    ["Green Reconstitution Matrix"] = "Matrice de reconstitution verte",
    -- Bar and messages.
    ["Holo Hand Spawned"] = "Holo-main Apparition",
    ["PURGE BLUE BOSS"] = "PURGE BOSS BLEUE",
    ["P2 SOON !"] = "P2 BIENTÔT !",
    ["INTERRUPT CRUSHING BLOW!"] = "INTERROMPRE COUP ÉCRASANT!",
    ["BLIND! TURN AWAY FROM BOSS"] = "AVEUGLER! DOS AU BOSS",
    ["Blind"] = "Aveugler",
    ["Gun Grid NOW!"] = "pétoires MAINTENANT!",
    ["~Gun Grid"] = "~Pétoires Grille",
    ["Hand %u"] = "Main %u",
    ["MARKER North"] = "Nord",
    ["MARKER South"] = "Sud",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Avatus"] = "Avatus",
    ["Holo Hand"] = "Holohand",
    ["Mobius Physics Constructor"] = "Mobius Physikkonstrukteur",
    ["Unstoppable Object Simulation"] = "Unaufhaltbare Objektsimulation",
    ["Holo Cannon"] = "Holokanone",
    ["Shock Sphere"] = "Schocksphäre",
    ["Support Cannon"] = "Hilfskanone",
    ["Infinite Logic Loop"] = "Unendliche Logikschleife",
    --["Tower Platform"] = "Tower Platform", -- TODO: German translation missing !!!!
    --["Augmented Rowsdower"] = "Augmented Rowsdower", -- TODO: German translation missing !!!!
    -- Datachron messages.
    --["Portals have opened!"] = "Portals have opened!", -- TODO: German translation missing !!!!
    --["Gun Grid Activated"] = "Gun Grid Activated", -- TODO: German translation missing !!!!
    -- Cast.
    ["Crushing Blow"] = "Vernichtender Schlag",
    ["Data Flare"] = "Daten-Leuchtsignal",
    ["Obliteration Beam"] = "Vernichtungsstrahl",
    -- Bar and messages.
    --["Holo Hand Spawned"] = "Holo Hand Spawned", -- TODO: German translation missing !!!!
    --["PURGE BLUE BOSS"] = "PURGE BLUE BOSS", -- TODO: German translation missing !!!!
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    --["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!", -- TODO: German translation missing !!!!
    --["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS", -- TODO: German translation missing !!!!
    ["Blind"] = "Geblendet",
    --["Gun Grid NOW!"] = "Gun Grid NOW!", -- TODO: German translation missing !!!!
    --["~Gun Grid"] = "~Gun Grid", -- TODO: German translation missing !!!!
    --["Hand %u"] = "Hand %u", -- TODO: German translation missing !!!!
    ["MARKER North"] = "N",
    ["MARKER South"] = "S",
})
-- Default settings.
mod:RegisterDefaultSetting("LineCleaveBoss")
mod:RegisterDefaultSetting("LineCleaveHands")
mod:RegisterDefaultSetting("LineCleaveYellowRoomBoss")
mod:RegisterDefaultSetting("LineCannons")
mod:RegisterDefaultSetting("LineOrbsYellowRoom")
mod:RegisterDefaultSetting("SoundObliterationBeam")
mod:RegisterDefaultSetting("SoundBlueInterrupt")
mod:RegisterDefaultSetting("SoundPortalPhase")
mod:RegisterDefaultSetting("SoundHandInterrupt")
mod:RegisterDefaultSetting("SoundBlindYellowRoom")
mod:RegisterDefaultSetting("SoundGunGrid")
mod:RegisterDefaultSetting("OtherHandSpawnMarkers")
mod:RegisterDefaultSetting("OtherDirectionMarkers")
mod:RegisterDefaultSetting("OtherGreenRoomMarkers")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["OBBEAM"] = { sColor = "xkcdBloodRed" },
    ["BLIND"] = { sColor = "xkcdBurntYellow" },
    ["GGRID"] = { sColor = "xkcdBlue" },
    ["HHAND"] = { sColor = "xkcdOrangeyRed" },
})

local PURGE_BLUE = 1
local PURGE_RED = 2
local PURGE_GREEN = 3
local PURGE_LIST_IN_BLUE_ROOM = {
    ["Icon_SkillEnergy_UI_srcr_shckcntrp"] = PURGE_BLUE,
    ["Icon_SkillEnergy_UI_srcr_XXXX"] = PURGE_RED,
    ["Icon_SkillEnergy_UI_srcr_surgeengine"] = PURGE_GREEN,
}
local PURGE_COOLDOWNS = 16

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local next = next
local NO_BREAK_SPACE = string.char(194, 160)
local MAIN_PHASE = 1
local LABYRINTH_PHASE = 2
local GREEN_PHASE = 3
local YELLOW_PHASE = 4
local RED_PHASE = 5
local BLUE_PHASE = 6
local HAND_MAKERS = {
    ["hand1"] = {x = 608.70, y = -198.75, z = -191.62},
    ["hand2"] = {x = 607.67, y = -198.75, z = -157.00},
}

local CARDINAL_MARKERS = {
    ["north"] = { x = 618, y = -198, z = -235 },
    ["south"] = { x = 618, y = -198, z = -114 }
}
local GREEN_ROOM_MARKERS = {
   ["1"] = { y = -198, x = 557.58, z = -139.2 },
   ["2"] = { y = -198, x = 583.21, z = -113.5 },
   ["3"] = { y = -198, x = 618.21, z = -104.2 },
   ["4"] = { y = -198, x = 653.21, z = -113.5 },
   ["5"] = { y = -198, x = 678.83, z = -139.2 },
   ["6"] = { y = -198, x = 688.21, z = -174.2 },
   ["7"] = { y = -198, x = 678.83, z = -209.2 },
   ["8"] = { y = -198, x = 653.21, z = -234.8 },
   ["9"] = { y = -198, x = 618.21, z = -244.2 },
   ["10"] = { y = -198, x = 583.21, z = -234.8 },
   ["11"] = { y = -198, x = 557.58, z = -209.2 },
}

----------------------------------------------------------------------------------------------------
-- locals.
----------------------------------------------------------------------------------------------------
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local SetTargetUnit = GameLib.SetTargetUnit
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local nCurrentPhase
local tBlueRoomPurgeList
local nGunGridLastPopTime
local tHoloHandsList
local phase2warn, phase2

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    Apollo.RegisterEventHandler("CHAT_NPCSAY", "OnChatNPCSay", self)
    Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
    Apollo.RegisterEventHandler("SHORTCUT_BAR", "OnShowShortcutBar", self)

    nCurrentPhase = MAIN_PHASE
    phase2warn, phase2 = false, false
    tBlueRoomPurgeList = {
        [PURGE_BLUE] = {},
        [PURGE_RED] = {},
        [PURGE_GREEN] = {},
    }
    tHoloHandsList = {}
    bGreenRoomMarkerDisplayed = false

    nGunGridLastPopTime = GetGameTime() + 20

    mod:AddTimerBar("OBBEAM", "Obliteration Beam", 69, mod:GetSetting("SoundObliterationBeam"))
    mod:AddTimerBar("GGRID", "~Gun Grid", 20, mod:GetSetting("SoundGunGrid"))
    if mod:GetSetting("OtherHandSpawnMarkers") then
        core:SetWorldMarker("HAND1", self.L["Hand %u"]:format(1), HAND_MAKERS["hand1"])
        core:SetWorldMarker("HAND2", self.L["Hand %u"]:format(2), HAND_MAKERS["hand2"])
    end
    if mod:GetSetting("OtherDirectionMarkers") then
        core:SetWorldMarker("NORTH", self.L["MARKER North"], CARDINAL_MARKERS["north"])
        core:SetWorldMarker("SOUTH", self.L["MARKER South"], CARDINAL_MARKERS["south"])
    end
end

function mod:OnUnitCreated(unit, sName)
    local nUnitId = unit:GetId()
    local nHealth = unit:GetHealth()

    if self.L["Avatus"] == sName then
        nCurrentPhase = MAIN_PHASE
        core:AddUnit(unit)
        core:WatchUnit(unit)
        if mod:GetSetting("LineCleaveBoss") then
            core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 22, 0)
        end
    elseif self.L["Augmented Rowsdower"] == sName then
        nCurrentPhase = LABYRINTH_PHASE
        core:AddMsg("Rowsdower", self.L["Augmented Rowsdower"], 3)
        SetTargetUnit(unit)
    elseif sName == self.L["Mobius Physics Constructor"] then
        -- Portals have same name, actual boss has HP, portals have nil value.
        if nHealth then
            nCurrentPhase = YELLOW_PHASE
            core:AddUnit(unit)
            core:WatchUnit(unit)
            if mod:GetSetting("LineCleaveYellowRoomBoss") then
                core:AddPixie(nUnitId, 2, unit, nil, "Red", 5, 35, 0)
            end
        else
            -- Draw a line to the yellow portal.
            core:AddPixie(nUnitId, 1, unit, GetPlayerUnit(), "xkcdBananaYellow")
        end
    elseif sName == self.L["Unstoppable Object Simulation"] then
        -- Portals have same name, actual boss has HP, portals have nil value.
        if nHealth then
            nCurrentPhase = GREEN_PHASE
            core:AddUnit(unit)
            core:WatchUnit(unit)
        else
            -- Draw a line to the green portal.
            core:AddPixie(nUnitId, 1, unit, GetPlayerUnit(), "green")
        end
    elseif sName == self.L["Infinite Logic Loop"] then
        if nHealth then
            -- Blue room.
            nCurrentPhase = BLUE_PHASE
            core:AddUnit(unit)
            core:WatchUnit(unit)
        else
            -- Draw a line to the blue portal.
            core:AddPixie(nUnitId, 1, unit, GetPlayerUnit(), "blue")
        end
    elseif sName == self.L["Holo Hand"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        table.insert(tHoloHandsList, nUnitId, { ["unit"] = unit} )
        core:AddMsg("HHAND", self.L["Holo Hand Spawned"], 5, "Info")
        if mod:GetSetting("LineCleaveHands") then
            core:AddPixie(nUnitId .. "_1", 2, unit, nil, "Blue", 7, 20, 0)
        end
    elseif self.L["Excessive Force Protocol"] == sName then
        if nHealth == nil then
            -- Draw a line to the red portal.
            core:AddPixie(nUnitId, 1, unit, GetPlayerUnit(), "red")
        end
    elseif sName == self.L["Holo Cannon"] and mod:GetSetting("LineCannons") then
        core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, 100, 0)
    elseif sName == self.L["Shock Sphere"] and mod:GetSetting("LineOrbsYellowRoom") then
        -- Yellow room orbs.
        core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, -7, 0)
    elseif sName == self.L["Support Cannon"] then
        core:AddUnit(unit)
    elseif sName == self.L["Tower Platform"] then
        if not bGreenRoomMarkerDisplayed and mod:GetSetting("OtherGreenRoomMarkers") then
            bGreenRoomMarkerDisplayed = true
            for k, tPosition in next, GREEN_ROOM_MARKERS do
                core:SetWorldMarker("GREEN_ROOM_MARKERS_" .. k, k, tPosition)
            end
        end
    end
end

function mod:OnUnitDestroyed(unit, sName)
    local nUnitId = unit:GetId()

    if sName == self.L["Holo Hand"] then
        core:DropPixie(nUnitId .. "_1")
        if tHoloHandsList[nUnitId] then
            tHoloHandsList[nUnitId] = nil
        end
    elseif sName == self.L["Holo Cannon"] then
        core:DropPixie(nUnitId)
    elseif sName == self.L["Avatus"] then
        core:DropPixie(nUnitId)
    elseif sName == self.L["Shock Sphere"] then
        core:DropPixie(nUnitId)
    elseif sName == self.L["Infinite Logic Loop"] then
        core:DropPixie(nUnitId)
    elseif sName == self.L["Mobius Physics Constructor"] then
        core:DropPixie(nUnitId)
    elseif self.L["Unstoppable Object Simulation"] == sName then
        core:DropPixie(nUnitId)
    elseif self.L["Excessive Force Protocol"] == sName then
        core:DropPixie(nUnitId)
    elseif sName == self.L["Tower Platform"] then
        if bGreenRoomMarkerDisplayed then
            bGreenRoomMarkerDisplayed = false
            for k, tPosition in next, GREEN_ROOM_MARKERS do
                core:DropWorldMarker("GREEN_ROOM_MARKERS_" .. k)
            end
        end
    end
end

function mod:OnBuffApplied(unitName, splId, unit)
    if unitName == self.L["Infinite Logic Loop"] then
        local sSpellName = GameLib.GetSpell(splId):GetName()

        local ePurgeType = nil
        if sSpellName == self.L["Green Reconstitution Matrix"] then
            ePurgeType = PURGE_GREEN
        elseif sSpellName == self.L["Blue Disruption Matrix"] then
            ePurgeType = PURGE_BLUE
        elseif sSpellName == self.L["Red Empowerment Matrix"] then
            ePurgeType = PURGE_RED
        end

        if ePurgeType then
            local nCurrentTime = GetGameTime()
            local sCandidate = nil
            local tList = tBlueRoomPurgeList[DispelType]
            for sPlayerName, nTimeout in pairs(tList) do
                local tPlayerUnit = GetPlayerUnitByName(sPlayerName)
                if tPlayerUnit == nil or tPlayerUnit:IsDead() or tPlayerUnit:GetHealth() == 0 then
                    -- Player is dead.
                    tList[sPlayerName] = nil
                elseif sCandidate == nil and nTimeout < nCurrentTime then
                    sCandidate = sPlayerName
                end
            end

            if sCandidate then
                tList[sCandidate] = nCurrentTime + PURGE_COOLDOWNS
            else
                sCandidate = "..."
            end
            if nCurrentPhase == BLUE_PHASE then 
                if ePurgeType == PURGE_GREEN then
                    core:AddMsg("PURGE", self.L["PURGE GREEN BY '%s'"]:format(sCandidate), 6, "green")
                elseif ePurgeType == PURGE_BLUE then
                    core:AddMsg("PURGE", self.L["PURGE BLUE BY '%s'"]:format(sCandidate), 6, "blue")
                elseif ePurgeType == PURGE_RED then
                    core:AddMsg("PURGE", self.L["PURGE RED BY '%s'"]:format(sCandidate), 6, "red")
                end
            end
        end
    end
end

function mod:OnHealthChanged(unitName, health)
    if unitName == self.L["Avatus"] then
        if health >= 75 and health <= 76 and not phase2warn then
            phase2warn = true
            core:AddMsg("AVAP2", self.L["P2 SOON !"], 5, mod:GetSetting("SoundPortalPhase") and "Info")
        elseif health >= 50 and health <= 52 and not phase2warn then
            phase2warn = true
            core:AddMsg("AVAP2", self.L["P2 SOON!"], 5, mod:GetSetting("SoundPortalPhase") and "Info")
        elseif health >= 70 and health <= 72 and phase2warn then
            phase2warn = false
        end
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Avatus"] and castName == self.L["Obliteration Beam"] then
        mod:RemoveTimerBar("OBBEAM")
        -- Check if next ob beam in sec doesn't happen during a gungrid which takes 20 sec.
        if nGunGridLastPopTime + 132 < GetGameTime() + 37 then
            mod:AddTimerBar("OBBEAM", "Obliteration Beam", 37, mod:GetSetting("SoundObliterationBeam"))
        end
    elseif unitName == self.L["Holo Hand"] and castName == self.L["Crushing Blow"] then
        local playerUnit = GetPlayerUnit()
        for _, hand in pairs(tHoloHandsList) do
            local distance_to_hand = self:GetDistanceBetweenUnits(playerUnit, hand["unit"])
            hand["distance"] = distance_to_hand
        end

        local closest_holo_hand = tHoloHandsList[next(tHoloHandsList)]
        for _, hand in pairs(tHoloHandsList) do
            if hand["distance"] < closest_holo_hand["distance"] then
                closest_holo_hand = hand
            end
        end
        local sSpellName = closest_holo_hand["unit"]:GetCastName():gsub(NO_BREAK_SPACE, " ")
        if sSpellName == self.L["Crushing Blow"] then
            core:AddMsg("CRBLOW", self.L["INTERRUPT CRUSHING BLOW!"], 5, mod:GetSetting("SoundHandInterrupt") and "Inferno")
        end
    elseif unitName == self.L["Mobius Physics Constructor"] and castName == self.L["Data Flare"] then
        mod:AddTimerBar("BLIND", "Blind", 29, mod:GetSetting("SoundBlindYellowRoom"))
        core:AddMsg("BLIND", self.L["BLIND! TURN AWAY FROM BOSS"], 5, mod:GetSetting("SoundBlindYellowRoom") and "Inferno")
    end
end

function mod:OnChatDC(message)
    if message:find(self.L["Gun Grid Activated"]) then
        nGunGridLastPopTime = GetGameTime()
        core:AddMsg("GGRIDMSG", self.L["Gun Grid NOW!"], 5, mod:GetSetting("SoundGunGrid") and "Beware")
        mod:AddTimerBar("GGRID", "~Gun Grid", 112, mod:GetSetting("SoundGunGrid"))
        mod:AddTimerBar("HHAND", "Holo Hand", 22)
    end
    if message:find(self.L["Portals have opened!"]) then
        phase2 = true
        mod:RemoveTimerBar("GGRID")
        mod:RemoveTimerBar("OBBEAM")
        mod:RemoveTimerBar("HHAND")
    end
end

function mod:OnShowShortcutBar(tIconFloatingSpellBar)
    if #tIconFloatingSpellBar > 0 then
        local sIcon1 = tIconFloatingSpellBar[1]
        Print(("Name of the spell bar icon = '%s'"):format(sIcon1))
        local ePurgeType = PURGE_LIST_IN_BLUE_ROOM[sIcon1]
        if ePurgeType then
            tBlueRoomPurgeList[ePurgeType][GetPlayerUnit():GetName()] = GetGameTime()
            mod:SendIndMessage("PURGE_TYPE", ePurgeType)
            Print(("PurgeType=%d detected on you"):format(ePurgeType))
        end
    end
end

function mod:ReceiveIndMessage(sFrom, sReason, data)
    if sReason == "PURGE_TYPE" then
        tBlueRoomPurgeList[data][sFrom] = GetGameTime()
        Print(("PurgeType=%s detected on %s"):format(tostring(data), sFrom))
    end
end
