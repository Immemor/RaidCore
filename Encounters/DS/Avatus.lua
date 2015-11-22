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
    ["Fragmented Data Chunk"] = "Fragmented Data Chunk",
    -- Datachron messages.
    ["Portals have opened!"] = "Avatus' power begins to surge! Portals have opened!",
    ["Gun Grid Activated"] = "SECURITY PROTOCOL: Gun Grid Activated.",
    ["The Excessive Force Protocol's protective barrier has fallen."] = "The Excessive Force Protocol's protective barrier has fallen.",
    ["The Excessive Force Protocol has been terminated."] = "The Excessive Force Protocol has been terminated.",
    ["Escalating defense matrix system"] = "Escalating defense matrix system to level (.*) protocols",
    -- Cast.
    ["Crushing Blow"] = "Crushing Blow",
    ["Data Flare"] = "Data Flare",
    ["Obliteration Beam"] = "Obliteration Beam",
    -- BuffName with many ID.
    ["Red Empowerment Matrix"] = "Red Empowerment Matrix",
    ["Blue Disruption Matrix"] = "Blue Disruption Matrix",
    ["Green Reconstitution Matrix"] = "Green Reconstitution Matrix",
    -- Timer bars.
    ["Next gun grid"] = "Next gun grid",
    ["Next obliteration beam"] = "Next obliteration beam",
    ["Next increase of number of purge"] = "Next increase of number of purge",
    ["Next purge cycle"] = "Next purge cycle",
    ["Next support cannon"] = "Next support cannon",
    ["Next holo: Hands"] = "Next holo: Hands",
    ["Next holo: Cannons"] = "Next holo: Cannons",
    ["Next blind"] = "Next blind",
    -- Message bars.
    ["HOLO HAND SPAWNED"] = "HOLO HAND SPAWNED",
    ["P2 SOON !"] = "P2 SOON !",
    ["P3 SOON !"] = "P3 SOON !",
    ["KILL AVATUS !!!"] = "KILL AVATUS !!!",
    ["INTERRUPT CRUSHING BLOW!"] = "INTERRUPT CRUSHING BLOW!",
    ["BLIND! TURN AWAY FROM BOSS"] = "BLIND! TURN AWAY FROM BOSS",
    ["GUN GRID NOW!"] = "GUN GRID NOW!",
    ["MARKER North"] = "North",
    ["MARKER South"] = "South",
    ["MARKER Est"] = "Est",
    ["MARKER West"] = "West",
    ["%s. PURGE BLUE (%s)"] = "%s. PURGE BLUE (%s)",
    ["%s. PURGE RED (%s)"] = "%s. PURGE RED (%s)",
    ["%s. PURGE GREEN (%s)"] = "%s. PURGE GREEN (%s)",
    ["Yellow Room: Combat started"] = "Yellow Room: Combat started",
    ["Mobius health: %d%%"] = "Mobius health: %d%%",
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
    ["Excessive Force Protocol"] = "Protocole de force excessive",
    ["Fragmented Data Chunk"] = "Données fragmentées",
    -- Datachron messages.
    ["Portals have opened!"] = "L'énergie d'Avatus commence à déferler ! Des portails se sont ouverts !",
    ["Gun Grid Activated"] = "PROTOCOLE DE SÉCURITÉ : pétoires activées.",
    --TODO ["The Excessive Force Protocol's protective barrier has fallen."] = "",
    ["The Excessive Force Protocol has been terminated."] = "Le Protocole de force excessive a été abandonné.",
    ["Escalating defense matrix system"] = "Passage de la matrice de défense aux protocoles de niveau (.*)",
    -- Cast.
    ["Crushing Blow"] = "Coup écrasant",
    ["Data Flare"] = "Signal de données",
    ["Obliteration Beam"] = "Rayon de suppression",
    -- BuffName with many ID.
    ["Red Empowerment Matrix"] = "Matrice de renforcement rouge",
    ["Blue Disruption Matrix"] = "Matrice disruptive bleue",
    ["Green Reconstitution Matrix"] = "Matrice de reconstitution verte",
    -- Timer bars.
    ["Next gun grid"] = "Prochaine pétoires grille",
    ["Next obliteration beam"] = "Prochain rayon de suppression",
    ["Next increase of number of purge"] = "Prochaine augmentation du nombre de purge",
    ["Next purge cycle"] = "Prochain cycle de purge",
    ["Next support cannon"] = "Prochain canon d'appui",
    ["Next holo: Hands"] = "Prochain holo: Mains",
    ["Next holo: Cannons"] = "Prochain holo: Cannons",
    ["Next blind"] = "Prochain aveuglement",
    -- Message bars.
    ["HOLO HAND SPAWNED"] = "HOLO-MAIN APPARITION",
    ["P2 SOON !"] = "P2 BIENTÔT !",
    ["P3 SOON !"] = "P3 BIENTÔT !",
    ["KILL AVATUS !!!"] = "TUEZ AVATUS !!!",
    ["INTERRUPT CRUSHING BLOW!"] = "INTERROMPRE COUP ÉCRASANT!",
    ["BLIND! TURN AWAY FROM BOSS"] = "AVEUGLER! DOS AU BOSS",
    ["GUN GRID NOW!"] = "PÉTOIRES MAINTENANT!",
    ["MARKER North"] = "Nord",
    ["MARKER South"] = "Sud",
    ["MARKER Est"] = "Est",
    ["MARKER West"] = "Ouest",
    ["%s. PURGE BLUE (%s)"] = "%s. PURGE BLEUE (%s)",
    ["%s. PURGE RED (%s)"] = "%s. PURGE ROUGE (%s)",
    ["%s. PURGE GREEN (%s)"] = "%s. PURGE VERT (%s)",
    ["Yellow Room: Combat started"] = "Salle Jaune: Combat démarré",
    ["Mobius health: %d%%"] = "Mobius santé: %d%%",
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
    -- Datachron messages.
    -- Cast.
    ["Crushing Blow"] = "Vernichtender Schlag",
    ["Data Flare"] = "Daten-Leuchtsignal",
    ["Obliteration Beam"] = "Vernichtungsstrahl",
    -- Bar and messages.
    ["P2 SOON !"] = "GLEICH PHASE 2 !",
    ["MARKER North"] = "Nord",
    ["MARKER South"] = "Süd",
    ["MARKER Est"] = "Ost",
    ["MARKER West"] = "West",
})
-- Default settings.
mod:RegisterDefaultSetting("LineCleaveBoss")
mod:RegisterDefaultSetting("LineCleaveHands")
mod:RegisterDefaultSetting("LineCleaveFragments")
mod:RegisterDefaultSetting("LineCleaveYellowRoomBoss")
mod:RegisterDefaultSetting("LineCannons")
mod:RegisterDefaultSetting("LineOrbsYellowRoom")
mod:RegisterDefaultSetting("LinePortals")
mod:RegisterDefaultSetting("SoundObliterationBeam")
mod:RegisterDefaultSetting("SoundPortalPhase")
mod:RegisterDefaultSetting("SoundHandInterrupt")
mod:RegisterDefaultSetting("SoundBlindYellowRoom")
mod:RegisterDefaultSetting("SoundGunGrid")
mod:RegisterDefaultSetting("OtherHandSpawnMarkers")
mod:RegisterDefaultSetting("OtherDirectionMarkers")
mod:RegisterDefaultSetting("OtherGreenRoomMarkers")
mod:RegisterDefaultSetting("OtherPurgeList")
mod:RegisterDefaultSetting("OtherPurgeMessages")
mod:RegisterDefaultSetting("OtherPurgeNames")
mod:RegisterDefaultSetting("OtherMobiusHealthMessages")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["OBBEAM"] = { sColor = "xkcdBloodRed" },
    ["BLIND"] = { sColor = "xkcdBurntYellow" },
    ["GGRID"] = { sColor = "xkcdBlue" },
    ["HHAND"] = { sColor = "xkcdOrangeyRed" },
    ["PURGE_CYCLE"] = { sColor = "xkcdBluishGreen" },
    ["PURGE_INCREASE"] = { sColor = "xkcdDeepOrange" },
    ["SUPPORT_CANNON"] = { sColor = "xkcdBrightLilac" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)
local MAIN_PHASE = 1
local LABYRINTH_PHASE = 2
local GREEN_PHASE = 3
local YELLOW_PHASE = 4
local RED_PHASE = 5
local BLUE_PHASE = 6

local CARDINAL_MARKERS = {
    ["north"] = { x = 618, y = -198, z = -235 },
    ["south"] = { x = 618, y = -198, z = -114 },
    ["est"] = { x = 678, y = -198, z = -174 },
    ["west"] = { x = 557, y = -198, z = -174 },
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
local PURGE_BLUE = 1
local PURGE_RED = 2
local PURGE_GREEN = 3
local PURGE_LIST_IN_BLUE_ROOM = {
    ["Icon_SkillEnergy_UI_srcr_shckcntrp"] = PURGE_BLUE,
    ["Icon_SkillFire_UI_ss_srngblst"] = PURGE_RED,
    ["Icon_SkillEnergy_UI_srcr_surgeengine"] = PURGE_GREEN,
}
local PURGE_COOLDOWNS = 15
-- Protective Barrier win by Avatus on each end of main phase.
local BUFFID_PROTECTIVE_BARRIER = 45304
-- Buff win by Avatus, which will enable obliteration beam.
local BUFFID_HOLO_CANNONS_ACTIVE = 44756
-- Holo cannons duration per main phase.
local HOLO_CANNONS_DURATION = {
    [1] = 93,
    [2] = 93,
    [3] = 64,
}
-- Timer of the next gun per main phase.
local GUN_INTERVAL = {
    [1] = 112,
    [2] = 112,
    [3] = 81,
}

----------------------------------------------------------------------------------------------------
-- locals.
----------------------------------------------------------------------------------------------------
local next = next
local GetGameTime = GameLib.GetGameTime
local GetSpell = GameLib.GetSpell
local GetPlayerUnit = GameLib.GetPlayerUnit
local SetTargetUnit = GameLib.SetTargetUnit
local GetPlayerUnitByName = GameLib.GetPlayerUnitByName
local nCurrentPhase
local tBlueRoomPurgeList
local tBlueRoomPurgeOrderedList
local tHoloHandsList
local bIsHoloHand
local nPurgeCount
local nPurgeCycleCount
local nPurgeCycleCountPerColor
local bWarningSwitchPhaseDone
local nMobiusId
local nMobiusHealthPourcent
local bDisplayHandsPictures
local nAvatusId
local nInfiniteLogicLoopId
local nMainPhaseCount
local nHoloCannonActivationTime
local nLastSupportCannonPopTime
local nLastBuffPurgeTime
local bIsPurgeSync
local bIsProtectionBarrierEnable

local function SetMarkersByPhase(nNewPhase)
    -- Remove previous markers
    core:DropWorldMarker("NORTH")
    core:DropWorldMarker("SOUTH")
    core:DropWorldMarker("EST")
    core:DropWorldMarker("WEST")

    -- Set markers
    if MAIN_PHASE == nNewPhase or YELLOW_PHASE == nNewPhase or LABYRINTH_PHASE == nNewPhase then
        if mod:GetSetting("OtherDirectionMarkers") then
            core:SetWorldMarker("NORTH", mod.L["MARKER North"], CARDINAL_MARKERS["north"])
            core:SetWorldMarker("SOUTH", mod.L["MARKER South"], CARDINAL_MARKERS["south"])
            if YELLOW_PHASE == nNewPhase then
                core:SetWorldMarker("EST", mod.L["MARKER Est"], CARDINAL_MARKERS["est"])
                core:SetWorldMarker("WEST", mod.L["MARKER West"], CARDINAL_MARKERS["west"])
            end
        end
    end
    nCurrentPhase = nNewPhase
end

local function RefreshHoloHandPictures()
    if mod:GetSetting("OtherHandSpawnMarkers") and bDisplayHandsPictures then
        core:AddPicture("HAND1", nAvatusId, "RaidCore_Draw:AvatusLeftHand", 30, -60, 17)
        core:AddPicture("HAND2", nAvatusId, "RaidCore_Draw:AvatusRightHand", 30, 60, 17)
    else
        core:RemovePicture("HAND1")
        core:RemovePicture("HAND2")
    end
end

local function BuildBlueRoomPurgeOrderedList()
    for ePurgeType = PURGE_BLUE, PURGE_GREEN do
        if next(tBlueRoomPurgeList[ePurgeType]) then
            local tCopy = {}
            for k, v in next, tBlueRoomPurgeList[ePurgeType] do
                tCopy[k] = v
            end

            local tOrdered = {}
            while next(tCopy) do
                local f = nil
                for key, val in next, tCopy do
                    if f == nil or tCopy[f] > val then
                        f = key
                    end
                end
                table.insert(tOrdered, f:gmatch("%a+")())
                tCopy[f] = nil
            end
            tBlueRoomPurgeOrderedList[ePurgeType] = tOrdered
        end
    end
end

local function DisplayPurgeList()
    if mod:GetSetting("OtherPurgeList") then
        core:Print("====== PURGE LIST ======")
        for ePurgeType = PURGE_BLUE, PURGE_GREEN do
            if next(tBlueRoomPurgeOrderedList[ePurgeType]) then
                local sPlayers = table.concat(tBlueRoomPurgeOrderedList[ePurgeType], ", ")
                if ePurgeType == PURGE_BLUE then
                    core:Print(mod.L["%s. PURGE BLUE (%s)"]:format("a", sPlayers))
                elseif ePurgeType == PURGE_RED then
                    core:Print(mod.L["%s. PURGE RED (%s)"]:format("b", sPlayers))
                elseif ePurgeType == PURGE_GREEN then
                    core:Print(mod.L["%s. PURGE GREEN (%s)"]:format("c", sPlayers))
                end
            end
        end
    end
end

local function Spell2PurgeType(nSpellId)
    local sSpellName = GetSpell(nSpellId):GetName()

    if sSpellName == mod.L["Green Reconstitution Matrix"] then
        return PURGE_GREEN
    elseif sSpellName == mod.L["Blue Disruption Matrix"] then
        return PURGE_BLUE
    elseif sSpellName == mod.L["Red Empowerment Matrix"] then
        return PURGE_RED
    end
    return nil
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    SetMarkersByPhase(MAIN_PHASE)
    bWarningSwitchPhaseDone = false
    tBlueRoomPurgeList = {
        [PURGE_BLUE] = {},
        [PURGE_RED] = {},
        [PURGE_GREEN] = {},
    }
    tBlueRoomPurgeOrderedList = {
        [PURGE_BLUE] = {},
        [PURGE_RED] = {},
        [PURGE_GREEN] = {},
    }
    tHoloHandsList = {}
    bGreenRoomMarkerDisplayed = false
    bIsHoloHand = true
    nPurgeCount = 0
    nPurgeCycleCount = 0
    nPurgeCycleCountPerColor = {
        [PURGE_BLUE] = 0,
        [PURGE_RED] = 0,
        [PURGE_GREEN] = 0,
    }
    nMobiusId = nil
    nMobiusHealthPourcent = 100
    nAvatusId = nil
    nMainPhaseCount = 1
    nHoloCannonActivationTime = nil
    bIsProtectionBarrierEnable = false
    bDisplayHandsPictures = false
    nLastSupportCannonPopTime = 0
    nLastBuffPurgeTime = 0

    mod:AddTimerBar("GGRID", "Next gun grid", 21, mod:GetSetting("SoundGunGrid"))
end

function mod:OnUnitCreated(nId, unit, sName)
    local nHealth = unit:GetHealth()

    if self.L["Avatus"] == sName then
        SetMarkersByPhase(MAIN_PHASE)
        core:AddUnit(unit)
        core:WatchUnit(unit)
        if mod:GetSetting("LineCleaveBoss") then
            core:AddPixie(unit:GetId(), 2, unit, nil, "Green", 10, 22, 0)
        end
        nAvatusId = nId
        RefreshHoloHandPictures()
    elseif self.L["Augmented Rowsdower"] == sName then
        SetMarkersByPhase(LABYRINTH_PHASE)
        mod:AddMsg("Rowsdower", "Augmented Rowsdower", 3)
        SetTargetUnit(unit)
    elseif sName == self.L["Mobius Physics Constructor"] then
        -- Portals have same name, actual boss has HP, portals have nil value.
        if nHealth then
            SetMarkersByPhase(YELLOW_PHASE)
            core:AddUnit(unit)
            core:WatchUnit(unit)
            if mod:GetSetting("LineCleaveYellowRoomBoss") then
                core:AddPixie(nId, 2, unit, nil, "Red", 5, 35, 0)
            end
        else
            -- Draw a line to the yellow portal.
            if mod:GetSetting("LinePortals") then
                core:AddPixie(nId, 1, unit, GetPlayerUnit(), "xkcdBananaYellow")
            end
        end
    elseif sName == self.L["Unstoppable Object Simulation"] then
        -- Portals have same name, actual boss has HP, portals have nil value.
        if nHealth then
            SetMarkersByPhase(GREEN_PHASE)
            core:AddUnit(unit)
            core:WatchUnit(unit)
        else
            -- Draw a line to the green portal.
            if mod:GetSetting("LinePortals") then
                core:AddPixie(nId, 1, unit, GetPlayerUnit(), "green")
            end
        end
    elseif sName == self.L["Infinite Logic Loop"] then
        if nHealth then
            -- Blue room.
            local bDisplayPurgeList = RED_PHASE == nCurrentPhase
            SetMarkersByPhase(BLUE_PHASE)
            nInfiniteLogicLoopId = nId
            core:AddUnit(unit)
            core:WatchUnit(unit)
            -- Cheat on the last purge date, to avoid some troubles with:
            --  * players who come from red phase.
            --  * spellslinger who use their void slip spell.
            nLastBuffPurgeTime = GetGameTime()
            -- When player from red room come to blue room, the event EnteringInCombat is not
            -- received.
            if bDisplayPurgeList then
                DisplayPurgeList()
            end
        else
            -- Draw a line to the blue portal.
            if mod:GetSetting("LinePortals") then
                core:AddPixie(nId, 1, unit, GetPlayerUnit(), "blue")
            end
        end
    elseif sName == self.L["Holo Hand"] then
        bDisplayHandsPictures = false
        RefreshHoloHandPictures()
        core:AddUnit(unit)
        core:WatchUnit(unit)
        table.insert(tHoloHandsList, nId, { ["unit"] = unit} )
        mod:AddMsg("HHAND", "HOLO HAND SPAWNED", 5, "Info")
        if mod:GetSetting("LineCleaveHands") then
            core:AddPixie(nId .. "_1", 2, unit, nil, "Blue", 7, 25, 0)
            core:AddPixie(nId .. "_2", 2, unit, nil, "xkcdBluegrey", 3, 7, 60)
            core:AddPixie(nId .. "_3", 2, unit, nil, "xkcdBluegrey", 3, 7, 300)
        end
    elseif self.L["Excessive Force Protocol"] == sName then
        if nHealth then
            -- Red room.
            SetMarkersByPhase(RED_PHASE)
            core:AddUnit(unit)
            core:WatchUnit(unit)
        else
            -- Draw a line to the red portal.
            core:AddPixie(nId, 1, unit, GetPlayerUnit(), "red")
        end
    elseif sName == self.L["Holo Cannon"] then
        if nHealth then
            core:AddUnit(unit)
        end
        if mod:GetSetting("LineCannons") then
            core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, 100, 0)
        end
    elseif sName == self.L["Shock Sphere"] then
        if mod:GetSetting("LineOrbsYellowRoom") then
            -- Yellow room orbs.
            core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 5, -7, 0)
        end
    elseif sName == self.L["Support Cannon"] then
        core:AddUnit(unit)
        local nCurrentTime = GetGameTime()
        if nLastSupportCannonPopTime + 20 < nCurrentTime then
            nLastSupportCannonPopTime = nCurrentTime
            mod:AddTimerBar("SUPPORT_CANNON", "Next support cannon", 23)
        end
    elseif sName == self.L["Tower Platform"] then
        if not bGreenRoomMarkerDisplayed and mod:GetSetting("OtherGreenRoomMarkers") then
            bGreenRoomMarkerDisplayed = true
            for k, tPosition in next, GREEN_ROOM_MARKERS do
                core:SetWorldMarker("GREEN_ROOM_MARKERS_" .. k, k, tPosition)
            end
        end
    elseif self.L["Fragmented Data Chunk"] == sName then
        if mod:GetSetting("LineCleaveFragments") then
            core:AddSimpleLine(nId .. "_1", nId, 0, 25, 0, 5, "Blue")
            core:AddSimpleLine(nId .. "_2", nId, 0, 7, 60, 3, "xkcdBluegrey")
            core:AddSimpleLine(nId .. "_3", nId, 0, 7, -60, 3,  "xkcdBluegrey")
        end
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Holo Hand"] then
        core:DropPixie(nId .. "_1")
        core:DropPixie(nId .. "_2")
        core:DropPixie(nId .. "_3")
        if tHoloHandsList[nId] then
            tHoloHandsList[nId] = nil
        end
    elseif sName == self.L["Holo Cannon"] then
        core:DropPixie(nId)
    elseif sName == self.L["Avatus"] then
        core:DropPixie(nId)
        core:RemovePicture("HAND1")
        core:RemovePicture("HAND2")
    elseif sName == self.L["Shock Sphere"] then
        core:DropPixie(nId)
    elseif sName == self.L["Infinite Logic Loop"] then
        core:DropPixie(nId)
        mod:RemoveTimerBar("PURGE_CYCLE")
        mod:RemoveTimerBar("PURGE_INCREASE")
        -- With the spellslinger's void slip spell, the purge sync is lost.
        bIsPurgeSync = false
    elseif sName == self.L["Mobius Physics Constructor"] then
        core:DropPixie(nId)
        if tUnit:GetHealth() == 0 then
            -- Send information about the miniboss, not the portal.
            mod:SendIndMessage("MOBIUS_DEATH")
        end
    elseif self.L["Unstoppable Object Simulation"] == sName then
        core:DropPixie(nId)
    elseif self.L["Excessive Force Protocol"] == sName then
        core:DropPixie(nId)
    elseif sName == self.L["Tower Platform"] then
        if bGreenRoomMarkerDisplayed then
            bGreenRoomMarkerDisplayed = false
            for k, tPosition in next, GREEN_ROOM_MARKERS do
                core:DropWorldMarker("GREEN_ROOM_MARKERS_" .. k)
            end
        end
    elseif self.L["Fragmented Data Chunk"] == sName then
        core:RemoveSimpleLine(nId .. "_1")
        core:RemoveSimpleLine(nId .. "_2")
        core:RemoveSimpleLine(nId .. "_3")
    end
end

function mod:OnEnteredCombat(nId, tUnit, sName, bInCombat)
    if sName == self.L["Infinite Logic Loop"] then
        if bInCombat then
            DisplayPurgeList()
        end
    elseif sName == self.L["Mobius Physics Constructor"] then
        mod:SendIndMessage("MOBIUS_IN_COMBAT", tUnit:GetId())
    end
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    if nInfiniteLogicLoopId == nId then
        local ePurgeType = Spell2PurgeType(nSpellId)

        if ePurgeType then
            nPurgeCount = nPurgeCount + 1
            -- 1 second without debuff is requested to sync with new cycle.
            if nLastBuffPurgeTime + 1 <= GetGameTime() then
                bIsPurgeSync = true
                nPurgeCycleCount = 0
                nPurgeCycleCountPerColor[PURGE_BLUE] = 0
                nPurgeCycleCountPerColor[PURGE_RED] = 0
                nPurgeCycleCountPerColor[PURGE_GREEN] = 0
            end
            if bIsPurgeSync then
                nPurgeCycleCount = nPurgeCycleCount + 1
                nPurgeCycleCountPerColor[ePurgeType] = nPurgeCycleCountPerColor[ePurgeType] + 1
                if nPurgeCycleCount == 1 then
                    mod:AddTimerBar("PURGE_CYCLE", "Next purge cycle", 20)
                    DisplayPurgeList()
                end
            end
            if nCurrentPhase == BLUE_PHASE and mod:GetSetting("OtherPurgeMessages") then
                local a = bIsPurgeSync and nPurgeCycleCount or nPurgeCount
                local b = nil
                if bIsPurgeSync then
                    if mod:GetSetting("OtherPurgeNames") then
                        local index = nPurgeCycleCountPerColor[ePurgeType]
                        b = tBlueRoomPurgeOrderedList[ePurgeType][index]
                    end
                    if not b then
                        b = nPurgeCycleCountPerColor[ePurgeType]
                    end
                end
                if not b then
                    b = "NA"
                end
                a = tostring(a)
                b = tostring(b)
                if ePurgeType == PURGE_GREEN then
                    mod:AddMsg("PURGE", self.L["%s. PURGE GREEN (%s)"]:format(a, b), 3, nil, "green")
                elseif ePurgeType == PURGE_BLUE then
                    mod:AddMsg("PURGE", self.L["%s. PURGE BLUE (%s)"]:format(a, b), 3, nil, "blue")
                elseif ePurgeType == PURGE_RED then
                    mod:AddMsg("PURGE", self.L["%s. PURGE RED (%s)"]:format(a, b), 3, nil, "red")
                end
            end
        end
    elseif nAvatusId == nId then
        if BUFFID_HOLO_CANNONS_ACTIVE == nSpellId then
            if not nHoloCannonActivationTime and not bIsProtectionBarrierEnable then
                nHoloCannonActivationTime = GetGameTime()
                mod:AddTimerBar("OBBEAM", "Next obliteration beam", 26, mod:GetSetting("SoundObliterationBeam"))
            end
        elseif BUFFID_PROTECTIVE_BARRIER == nSpellId then
            bIsProtectionBarrierEnable = true
            -- End of one main phase.
            nHoloCannonActivationTime = nil
            bWarningSwitchPhaseDone = false
            bDisplayHandsPictures = false
            mod:RemoveTimerBar("GGRID")
            mod:RemoveTimerBar("OBBEAM")
            mod:RemoveTimerBar("HOLO")
            RefreshHoloHandPictures()
        end
    end
end

function mod:OnBuffRemove(nId, nSpellId)
    if nAvatusId == nId then
        if BUFFID_PROTECTIVE_BARRIER == nSpellId then
            bIsProtectionBarrierEnable = false
            -- New main phase.
            if nMainPhaseCount < 3 then
                nMainPhaseCount = nMainPhaseCount + 1
            else
                mod:RemoveTimerBar("SUPPORT_CANNON")
                mod:AddMsg("KILL", "KILL AVATUS !!!", 4, "Info")
            end
        end
    elseif nInfiniteLogicLoopId == nId then
        local ePurgeType = Spell2PurgeType(nSpellId)
        if ePurgeType then
            nLastBuffPurgeTime = GetGameTime()
        end
    end
end

function mod:OnHealthChanged(nId, nPourcent, sName)
    if sName == self.L["Avatus"] then
        if not bWarningSwitchPhaseDone then
            if nPourcent >= 75 and nPourcent <= 76 then
                bWarningSwitchPhaseDone = true
                mod:AddMsg("AVAP2", "P2 SOON !", 5, mod:GetSetting("SoundPortalPhase") and "Info")
            elseif nPourcent >= 50 and nPourcent <= 52 then
                bWarningSwitchPhaseDone = true
                mod:AddMsg("AVAP2", "P2 SOON!", 5, mod:GetSetting("SoundPortalPhase") and "Info")
            elseif nPourcent >= 25 and nPourcent <= 27 then
                bWarningSwitchPhaseDone = true
                mod:AddMsg("AVAP2", "P3 SOON!", 5, mod:GetSetting("SoundPortalPhase") and "Info")
            end
        end
    elseif self.L["Mobius Physics Constructor"] == sName then
        if nPourcent % 10 == 0 and nPourcent < 100 then
            mod:SendIndMessage("MOBIUS_HEALTH_UPDATE", nPourcent)
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Avatus"] == sName then
        if self.L["Obliteration Beam"] == sCastName then
            local EndOfCannon = nHoloCannonActivationTime + HOLO_CANNONS_DURATION[nMainPhaseCount]
            local NextBeam = GetGameTime() + 37
            if EndOfCannon > NextBeam and nMainPhaseCount < 3 then
                mod:AddTimerBar("OBBEAM", "Next obliteration beam", 37, mod:GetSetting("SoundObliterationBeam"))
            else
                mod:RemoveTimerBar("OBBEAM")
            end
        end
    elseif self.L["Holo Hand"] == sName then
        if self.L["Crushing Blow"] == sCastName then
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
                mod:AddMsg("CRBLOW", "INTERRUPT CRUSHING BLOW!", 5, mod:GetSetting("SoundHandInterrupt") and "Inferno")
            end
        end
    elseif self.L["Mobius Physics Constructor"] == sName then
        if self.L["Data Flare"] == sCastName then
            mod:AddTimerBar("BLIND", "Next blind", 29, mod:GetSetting("SoundBlindYellowRoom"))
            mod:AddMsg("BLIND", "BLIND! TURN AWAY FROM BOSS", 5, mod:GetSetting("SoundBlindYellowRoom") and "Inferno")
        end
    end
end

function mod:OnDatachron(sMessage)
    local nEscalatingFound = sMessage:match(self.L["Escalating defense matrix system"])
    if sMessage:find(self.L["Gun Grid Activated"]) then
        mod:AddMsg("GGRIDMSG", "GUN GRID NOW!", 5, mod:GetSetting("SoundGunGrid") and "Beware")
        mod:AddTimerBar("GGRID", "Next gun grid", GUN_INTERVAL[nMainPhaseCount], mod:GetSetting("SoundGunGrid"))
        if bIsHoloHand then
            mod:AddTimerBar("HOLO", "Next holo: Hands", 22)
            bDisplayHandsPictures = true
            RefreshHoloHandPictures()
        else
            mod:AddTimerBar("HOLO", "Next holo: Cannons", 22)
        end
        bIsHoloHand = not bIsHoloHand
    elseif sMessage:find(self.L["Portals have opened!"]) then
        mod:RemoveTimerBar("GGRID")
        mod:RemoveTimerBar("OBBEAM")
        mod:RemoveTimerBar("HOLO")
    elseif nEscalatingFound then
        mod:AddTimerBar("PURGE_INCREASE", "Next increase of number of purge", 30)
    end
end

function mod:OnShowShortcutBar(tIconFloatingSpellBar)
    if #tIconFloatingSpellBar > 0 then
        local sIcon1 = tIconFloatingSpellBar[1]
        local ePurgeType = PURGE_LIST_IN_BLUE_ROOM[sIcon1]
        if ePurgeType then
            tBlueRoomPurgeList[ePurgeType][GetPlayerUnit():GetName()] = GetGameTime()
            BuildBlueRoomPurgeOrderedList()
            mod:SendIndMessage("PURGE_TYPE", ePurgeType)
        end
    end
end

function mod:ReceiveIndMessage(sFrom, sReason, data)
    if "MOBIUS_IN_COMBAT" == sReason then
        -- Drop this message for player in Yellow phase.
        if (nCurrentPhase == LABYRINTH_PHASE or nCurrentPhase == GREEN_PHASE) and nMobiusId == nil then
            nMobiusId = data
            nMobiusHealthPourcent = 100
            if mod:GetSetting("OtherMobiusHealthMessages") then
                mod:AddMsg("MOBIUS_INFO", "Yellow Room: Combat started", 3, nil, "blue")
            end
        end
    elseif "MOBIUS_HEALTH_UPDATE" == sReason then
        if nCurrentPhase == GREEN_PHASE and nMobiusHealthPourcent > data then
            nMobiusHealthPourcent = data
            if mod:GetSetting("OtherMobiusHealthMessages") then
                mod:AddMsg("MOBIUS_INFO", self.L["Mobius health: %d%%"]:format(nMobiusHealthPourcent), 2, nil, "blue")
            end
        end
    elseif "MOBIUS_DEATH" == sReason then
        if nCurrentPhase == GREEN_PHASE and nMobiusHealthPourcent ~= 0 then
            nMobiusHealthPourcent = 0
            if mod:GetSetting("OtherMobiusHealthMessages") then
                mod:AddMsg("MOBIUS_INFO", self.L["Mobius health: %d%%"]:format(0), 2, nil, "blue")
            end
        end
    elseif "PURGE_TYPE" == sReason then
        tBlueRoomPurgeList[data][sFrom] = GetGameTime()
        BuildBlueRoomPurgeOrderedList()
    end
end
