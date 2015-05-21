----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--  Description: TODO
----------------------------------------------------------------------------------------------------
require "Apollo"
require "Window"
require "GameLib"
require "ChatSystemLib"
require "ICCommLib"
require "ICComm"

local GeminiAddon = Apollo.GetPackage("Gemini:Addon-1.1").tPackage
local LogPackage = Apollo.GetPackage("Log-1.0").tPackage
local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
local RaidCore = GeminiAddon:NewAddon("RaidCore", false, {}, "Gemini:Timer-1.0")
local Log = LogPackage:CreateNamespace("CombatManager")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local GetCurrentZoneMap = GameLib.GetCurrentZoneMap

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with French language. This problem is not present in English.
local NO_BREAK_SPACE = string.char(194, 160)

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _wndrclog = nil
local _tWipeTimer
local _tHUDtimer
local _tTrigPerZone = {}
local _tEncountersPerZone = {}
local _tDelayedUnits = {}
local _bIsEncounterInProgress = false
local _tCurrentEncounter = nil


local trackMaster = Apollo.GetAddon("TrackMaster")
local markCount = 0
local AddonVersion = 15051101
local VCReply, VCtimer = {}, nil
local CommChannelTimer = nil
local empCD, empTimer = 5, nil

local DefaultSettings = {
    General = {
        raidbars = {
            isEnabled = true,
            barSize = {
                Width = 300,
                Height = 25,
            },
            anchorFromTop = true,
            barColor = "ff00007f",
        },
        message = {
            isEnabled = true,
            barSize = {
                Width = 300,
                Height = 25,
            },
            anchorFromTop = true,
        },
        unitmoni = {
            isEnabled = true,
            barSize = {
                Width = 300,
                Height = 25,
            },
            anchorFromTop = true,
            barColor = "ff00007f",
        },
        bSoundEnabled = true,
        bAcceptSummons = true,
    },
    -- Datascape Settings

    -- System Daemons
    SystemDaemons_LineOnModulesMidphase = true,
    SystemDaemons_SoundPhase2 = true,
    SystemDaemons_SoundPurge = true,
    SystemDaemons_SoundWave = true,
    SystemDaemons_SoundRepairSequence = true,
    SystemDaemons_SoundPowerSurge = true,
    SystemDaemons_OtherPillarMarkers = true,
    SystemDaemons_OtherPurgePlayerMarkers = true,
    SystemDaemons_OtherOverloadMarkers = true,
    SystemDaemons_OtherDisconnectTimer = true,

    -- Gloomclaw
    Gloomclaw_SoundRuptureInterrupt = true,
    Gloomclaw_SoundRuptureCountdown = true,
    Gloomclaw_SoundCorruptingRays = true,
    Gloomclaw_SoundSectionSwitch = true,
    Gloomclaw_SoundCorruptionCountdown = true,
    Gloomclaw_SoundMoOWarning = true,
    Gloomclaw_SoundWaveWarning = true,
    Gloomclaw_OtherLeftRightMarkers = true,
    Gloomclaw_OtherMaulerMarkers = true,

    -- Maelstrom
    Maelstrom_LineWeatherStations = true,
    Maelstrom_LineCleaveBoss = true,
    Maelstrom_LineWindWalls = true,
    Maelstrom_SoundIcyBreath = true,
    Maelstrom_SoundTyphoon = true,
    Maelstrom_SoundCrystallize = true,
    Maelstrom_SoundWeatherStationSwitch = true,

    -- Avatus
    Avatus_LineCleaveBoss = true,
    Avatus_LineCleaveHands = true,
    Avatus_LineCannons = true,
    Avatus_LineCleaveYellowRoomBoss = true,
    Avatus_LineOrbsYellowRoom = true,
    Avatus_SoundHandInterrupt = true,
    Avatus_SoundObliterationBeam = true,
    Avatus_SoundBlindYellowRoom = true,
    Avatus_SoundPortalPhase = true,
    Avatus_SoundBlueInterrupt = true,
    Avatus_SoundGunGrid = true,
    Avatus_OtherDirectionMarkers = true,
    Avatus_OtherHandSpawnMarkers = true,

    -- Limbo

    -- Lattice
    Lattice_LineDataDevourers = true,
    Lattice_SoundBeam = true,
    Lattice_SoundBigCast = true,
    Lattice_SoundShieldPhase = true,
    Lattice_SoundJumpPhase = true,
    Lattice_SoundNewWave = true,
    Lattice_SoundLaser = true,
    Lattice_SoundExplosion = true,
    Lattice_OtherPlayerBeamMarkers = true,
    Lattice_OtherLogicWallMarkers = true,

    -- Air/Earth
    EpAirEarth_LineTornado = true,
    EpAirEarth_LineCleaveAileron = true,
    EpAirEarth_SoundMidphase = true,
    EpAirEarth_SoundQuakeJump = true,
    EpAirEarth_SoundSupercell = true,
    EpAirEarth_SoundTornadoCountdown = true,
    EpAirEarth_SoundMoO = true,

    -- Air/Water
    EpAirWater_SoundTwirl = true,
    EpAirWater_SoundMoO = true,
    EpAirWater_SoundIcestorm = true,
    EpAirWater_SoundMidphase = true,
    EpAirWater_SoundFrostTombs = true,
    EpAirWater_OtherTwirlWarning = true,
    EpAirWater_OtherTwirlPlayerMarkers = true,

    -- Air/Life
    EpAirLife_LineLifeOrbs = true,
    EpAirLife_LineHealingTrees = true,
    EpAirLife_LineCleaveAileron = true,
    EpAirLife_SoundTwirl = true,
    EpAirLife_SoundNoHealDebuff = true,
    EpAirLife_SoundBlindingLight = true,
    EpAirLife_SoundHealingTree = true,
    EpAirLife_SoundMidphase = true,
    EpAirLife_SoundLightning = true,
    EpAirLife_OtherTwirlWarning = true,
    EpAirLife_OtherNoHealDebuff = true,
    EpAirLife_OtherBlindingLight = true,
    EpAirLife_OtherTwirlPlayerMarkers = true,
    EpAirLife_OtherNoHealDebuffPlayerMarkers = true,
    EpAirLife_OtherLightningMarkers = true,

    -- Fire/Water
    EpFireWater_LineFlameWaves = true,
    EpFireWater_LineCleaveHydroflux = true,
    EpFireWater_LineBombPlayers = true,
    EpFireWater_LineIceTomb = true,
    EpFireWater_SoundBomb = true,
    EpFireWater_SoundHighDebuffStacks = true,
    EpFireWater_SoundIceTomb = true,
    EpFireWater_OtherBombPlayerMarkers = true,

    -- Fire/Life
    EpFireLife_LineLifeOrbs = true,
    EpFireLife_LineFlameWaves = true,
    EpFireLife_SoundRooted = true,
    EpFireLife_SoundBlindingLight = true,
    EpFireLife_SoundNoHealDebuff = true,
    EpFireLife_OtherRootedPlayersMarkers = true,

    -- Fire/Earth

    -- Logic/Earth
    EpLogicEarth_LineObsidianOutcropping = true,
    EpLogicEarth_SoundDefrag = true,
    EpLogicEarth_SoundStars = true,
    EpLogicEarth_SoundQuakeJump = true,
    EpLogicEarth_SoundSnake = true,

    -- Logic/Water
    EpLogicWater_LineTetrisBlocks = true,
    EpLogicWater_LineOrbs = true,
    EpLogicWater_SoundDefrag = true,
    EpLogicWater_SoundDataDisruptorDebuff = true,
    EpLogicWater_SoundMidphase = true,
    EpLogicWater_OtherWateryGraveTimer = true,
    EpLogicWater_OtherOrbMarkers = true,

    -- Logic/Life
    EpLogicLife_LineTetrisBlocks = true,
    EpLogicLife_LineLifeOrbs = true,
    EpLogicLife_LineCleaveVisceralus = true,
    EpLogicLife_SoundSnake = true,
    EpLogicLife_SoundNoHealDebuff = true,
    EpLogicLife_SoundBlindingLight = true,
    EpLogicLife_SoundDefrag = true,
    EpLogicLife_SoundEnrage = true,
    EpLogicLife_OtherSnakePlayerMarkers = true,
    EpLogicLife_OtherNoHealDebuffPlayerMarkers = true,
    EpLogicLife_OtherRootedPlayersMarkers = true,
    EpLogicLife_OtherDirectionMarkers = true,
}

----------------------------------------------------------------------------------------------------
-- Privates functions
----------------------------------------------------------------------------------------------------
local function ManageDelayedUnit(nId, sName, bInCombat)
    local tMap = GetCurrentZoneMap()
    local id1 = tMap.continentId
    local id2 = tMap.parentZoneId
    local id3 = tMap.id
    local tTrig = _tTrigPerZone[id1] and _tTrigPerZone[id1][id2] and _tTrigPerZone[id1][id2][id3]
    if tTrig and tTrig[sName] then
        if bInCombat then
            Log:Add("Add2DelayedUnit", nId, sName)
            if not _tDelayedUnits[sName] then
                _tDelayedUnits[sName] = {}
            end
            _tDelayedUnits[sName][nId] = true
        else
            if _tDelayedUnits[sName] then
                if _tDelayedUnits[sName][nId] then
                    Log:Add("Remove2DelayedUnit", nId, sName)
                    _tDelayedUnits[sName][nId] = nil
                end
                if next(_tDelayedUnits[sName]) == nil then
                    _tDelayedUnits[sName] = nil
                end
            end
        end
    end
end

local function SearchEncounter()
    local tMap = GetCurrentZoneMap()
    local id1 = tMap.continentId
    local id2 = tMap.parentZoneId
    local id3 = tMap.id
    local tEncounters = _tEncountersPerZone[id1] and _tEncountersPerZone[id1][id2] and _tEncountersPerZone[id1][id2][id3]
    if tEncounters then
        for _, tEncounter in next, tEncounters do
            if tEncounter:OnTrig(_tDelayedUnits) then
                _tCurrentEncounter = tEncounter
                Log:Add("Encounter Found", _tCurrentEncounter:GetName())
                break
            end
        end
    end
end

local function ProcessDelayedUnit()
    for nDelayedName, tDelayedList in next, _tDelayedUnits do
        for nDelayedId, _ in next, tDelayedList do
            local tUnit = GetUnitById(nDelayedId)
            if tUnit then
                local bInCombat = tUnit:IsInCombat()
                Event_FireGenericEvent("RC_UnitStateChanged", tUnit, bInCombat, nDelayedName)
            else
                Log:Add("Error Invalid tUnit not found", nDelayedName, nDelayedId)
            end
        end
    end
    _tDelayedUnits = {}
end

----------------------------------------------------------------------------------------------------
-- RaidCore Initialization
----------------------------------------------------------------------------------------------------
function RaidCore:OnInitialize()
    self.xmlDoc = XmlDoc.CreateFromFile("RaidCore.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
    Apollo.LoadSprites("BarTextures.xml")
    Apollo.LoadSprites("Textures_GUI.xml")

    local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
    self.L = GeminiLocale:GetLocale("RaidCore")
end

----------------------------------------------------------------------------------------------------
-- RaidCore OnDocLoaded
----------------------------------------------------------------------------------------------------
function RaidCore:OnDocLoaded()
    self:CombatInterface_Init(self)

    self.settings = self.settings or self:recursiveCopyTable(DefaultSettings)

    self.wndConfig = Apollo.LoadForm(self.xmlDoc, "ConfigForm", nil, self)
    self.wndConfig:Show(false)

    self.wndTargetFrame = self.wndConfig:FindChild("TargetFrame")
    self.wndConfigOptionsTargetFrame = self.wndConfig:FindChild("ConfigOptionsTargetFrame")
    self.wndModuleList = {
        DS = Apollo.LoadForm(self.xmlDoc, "ModuleList_DS", self.wndConfigOptionsTargetFrame, self),
    }

    self.wndSettings = {
        General = Apollo.LoadForm(self.xmlDoc, "ConfigForm_General", self.wndTargetFrame, self),
        DS = {
            SystemDaemons = Apollo.LoadForm(self.xmlDoc, "ConfigForm_SystemDaemons", self.wndTargetFrame, self),
            Gloomclaw = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Gloomclaw", self.wndTargetFrame, self),
            Maelstrom = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Maelstrom", self.wndTargetFrame, self),
            Lattice = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Lattice", self.wndTargetFrame, self),
            Limbo = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Limbo", self.wndTargetFrame, self),
            AirEarth = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpAirEarth", self.wndTargetFrame, self),
            AirLife = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpAirLife", self.wndTargetFrame, self),
            AirWater = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpAirWater", self.wndTargetFrame, self),
            FireEarth = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpFireEarth", self.wndTargetFrame, self),
            FireLife = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpFireLife", self.wndTargetFrame, self),
            FireWater = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpFireWater", self.wndTargetFrame, self),
            LogicEarth = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpLogicEarth", self.wndTargetFrame, self),
            LogicLife = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpLogicLife", self.wndTargetFrame, self),
            LogicWater = Apollo.LoadForm(self.xmlDoc, "ConfigForm_EpLogicWater", self.wndTargetFrame, self),
            Avatus = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Avatus", self.wndTargetFrame, self),
        },
    }

    self.raidbars = RaidCoreLibs.DisplayBlock.new(self.xmlDoc)
    self.raidbars:SetName("Raid Bars")
    self.raidbars:SetPosition(0.3, 0.5)
    self.raidbars:AnchorFromTop(true)

    self.unitmoni = RaidCoreLibs.DisplayBlock.new(self.xmlDoc)
    self.unitmoni:SetName("Unit Monitor")
    self.unitmoni:SetPosition(0.7, 0.5)
    self.unitmoni:AnchorFromTop(true)

    self.message = RaidCoreLibs.DisplayBlock.new(self.xmlDoc)
    self.message:SetName("Messages")
    self.message:SetPosition(0.5, 0.5)
    self.message:AnchorFromTop(true)

    self.drawline = RaidCoreLibs.DisplayLine.new(self.xmlDoc)

    self.GeminiColor = Apollo.GetPackage("GeminiColor").tPackage

    if self.settings ~= nil then
        self:LoadSaveData()
    end

    -- Register handlers for events, slash commands and timer, etc.
    Apollo.RegisterSlashCommand("raidc", "OnRaidCoreOn", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnCheckMapZone", self)
    Apollo.RegisterEventHandler("SubZoneChanged", "OnCheckMapZone", self)

    -- Do additional Addon initialization here

    self.watch = {}
    self.mark = {}
    self.worldmarker = {}
    self.buffs = {}
    self.debuffs = {}
    self.emphasize = {}
    self.delayedmsg = {}
    self.berserk = false

    self.syncRegister = {}
    self.syncTimer = {}

    _tWipeTimer = ApolloTimer.Create(0.5, true, "WipeCheck", self)
    _tWipeTimer:Stop()
    _tHUDtimer = ApolloTimer.Create(0.1, true, "OnTimer", self)
    _tHUDtimer:Stop()

    self.lines = {}

    self.chanCom = nil
    CommChannelTimer = ApolloTimer.Create(5, false, "UpdateCommChannel", self) -- make sure everything is loaded, so after 5sec

    -- Final parsing about encounters.
    for name, module in self:IterateModules() do
        local r, e = pcall(module.PrepareEncounter, module)
        if not r then
            Print(e)
        else
            for _, id1 in next, module.continentIdList do
                if _tTrigPerZone[id1] == nil then
                    _tTrigPerZone[id1] = {}
                    _tEncountersPerZone[id1] = {}
                end
                for _, id2 in next, module.parentMapIdList do
                    if _tTrigPerZone[id1][id2] == nil then
                        _tTrigPerZone[id1][id2] = {}
                        _tEncountersPerZone[id1][id2] = {}
                    end
                    for _, id3 in next, module.mapIdList do
                        if _tTrigPerZone[id1][id2][id3] == nil then
                            _tTrigPerZone[id1][id2][id3] = {}
                            _tEncountersPerZone[id1][id2][id3] = {}
                        end
                        table.insert(_tEncountersPerZone[id1][id2][id3], module)
                        if module.EnableMob then
                            for _, Mob in next, module.EnableMob do
                                _tTrigPerZone[id1][id2][id3][Mob] = true
                            end
                        end
                    end
                end
            end
        end
    end
    self:LogGUI_init()
    self:OnCheckMapZone()
end

----------------------------------------------------------------------------------------------------
-- RaidCore Functions
----------------------------------------------------------------------------------------------------
function RaidCore:UpdateCommChannel()
    if not self.chanCom then
        self.chanCom = ICCommLib.JoinChannel("RaidCore", ICCommLib.CodeEnumICCommChannelType.Group)
    end

    if self.chanCom:IsReady() then
        -- Set handler for messages only if ready
        self.chanCom:SetReceivedMessageFunction("OnComMessage", self)
    else
        -- Channel not ready yet, repeat in a few seconds
        self:ScheduleTimer("UpdateCommChannel", 1)
    end
end

function RaidCore:SendMessage(msg)
    if not self.chanCom then
        Print("[RaidCore] Error sending Sync Message. Attempting to fix this now. If this issue persists, contact the developers")
        self:UpdateCommChannel()
        return false
    else
        local msg_encoded = JSON.encode(msg)
        self.chanCom:SendMessage(msg_encoded)
    end
end

function RaidCore:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
    self.settings["General"]["raidbars"] = self.raidbars:GetSaveData()
    self.settings["General"]["unitmoni"] = self.unitmoni:GetSaveData()
    self.settings["General"]["message"] = self.message:GetSaveData()
    local saveData = {}

    self:recursiveCopyTable(self.settings, saveData)

    return saveData
end

function RaidCore:OnRestore(eLevel, tData)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end

    self.settings = self:recursiveCopyTable(DefaultSettings, self.settings)
    self.settings = self:recursiveCopyTable(tData, self.settings)
end

function RaidCore:LoadSaveData()
    self.raidbars:Load(self.settings["General"]["raidbars"])
    self.unitmoni:Load(self.settings["General"]["unitmoni"])
    self.message:Load(self.settings["General"]["message"])
end

function RaidCore:OnGeneralCheckBoxChecked(wndHandler, wndControl, eMouseButton )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local settingKey = self:SplitString(wndControl:GetName(), "_")[2]

    self.settings[settingType][settingKey] = true
end

function RaidCore:OnGeneralCheckBoxUnchecked(wndHandler, wndControl, eMouseButton )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local settingKey = self:SplitString(wndControl:GetName(), "_")[2]

    self.settings[settingType][settingKey] = false
end

function RaidCore:OnBarSettingChecked(wndHandler, wndControl, eMouseButton )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local identifier = self:SplitString(wndControl:GetName(), "_")
    self.settings[settingType][identifier[2]][identifier[3]] = true

    self[identifier[2]]:Load(self.settings[settingType][identifier[2]])
end

function RaidCore:OnBarSettingUnchecked(wndHandler, wndControl, eMouseButton )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local identifier = self:SplitString(wndControl:GetName(), "_")
    self.settings[settingType][identifier[2]][identifier[3]] = false

    self[identifier[2]]:Load(self.settings[settingType][identifier[2]])
end

function RaidCore:OnSliderBarChanged( wndHandler, wndControl, fNewValue, fOldValue )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetParent():GetName(), "_")[2]
    local identifier = self:SplitString(wndControl:GetName(), "_")
    self.settings[settingType][identifier[2]][identifier[3]][identifier[4]] = fNewValue
    wndHandler:GetParent():GetParent():FindChild("Label_".. identifier[2] .. "_" .. identifier[3] .. "_" .. identifier[4]):SetText(string.format("%.fpx", fNewValue))
    self[identifier[2]]:Load(self.settings[settingType][identifier[2]])
end

function RaidCore:EditBarColor( wndHandler, wndControl, eMouseButton )
    if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local identifier = self:SplitString(wndControl:GetName(), "_")
    self.GeminiColor:ShowColorPicker(self, {callback = "OnGeminiColor", bCustomColor = true, strInitialColor = self.settings[settingType][identifier[2]][identifier[3]]}, identifier, settingType)
end

function RaidCore:OnGeminiColor(strColor, identifier, settingType)
    self.settings[settingType][identifier[2]][identifier[3]] = strColor
    self[identifier[2]]:Load(self.settings[settingType][identifier[2]])
end

function RaidCore:OnBossSettingChecked(wndHandler, wndControl, eMouseButton )
    local bossModule = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local setting = self:SplitString(wndControl:GetName(), "_")[2]
    local settingString = bossModule .. "_" .. setting
    self.settings[settingString] = true
end

function RaidCore:OnBossSettingUnchecked(wndHandler, wndControl, eMouseButton )
    local bossModule = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local setting = self:SplitString(wndControl:GetName(), "_")[2]
    local settingString = bossModule .. "_" .. setting
    self.settings[settingString] = false
end

function RaidCore:OnWindowLoad(wndHandler, wndControl )
    local bossModule = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local setting = self:SplitString(wndControl:GetName(), "_")[2]
    local settingString = bossModule .. "_" .. setting
    local val = self.settings[settingString]

    if val ~= nil then
        if type(val) == "boolean" then
            wndControl:SetCheck(val)
        elseif type(val) == "number" then
            wndControl:SetText(val)
        elseif type(val) == "string" then
            wndControl:SetText(val)
        end
    end
end

-- Custom handler for general settings, since they are not specific to a bossinstance it'll be saved
-- differently in the settings table
function RaidCore:OnWindowLoadGeneral(wndHandler, wndControl )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local settingKey = self:SplitString(wndControl:GetName(), "_")[2]
    local val = self.settings[settingType][settingKey]

    if val ~= nil then
        if type(val) == "boolean" then
            wndControl:SetCheck(val)
        elseif type(val) == "number" then
            wndControl:SetText(val)
        elseif type(val) == "string" then
            wndControl:SetText(val)
        end
    end
end

-- Custom handler for the bar settings, they are in separate tables so we can call
-- DisplayBlock with these specific settings
function RaidCore:OnWindowLoadGeneralBars(wndhandler, wndControl )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local setting = self:SplitString(wndControl:GetName(), "_")
    local barType = setting[2]
    local settingKey = setting[3]
    local val = self.settings[settingType][barType][settingKey]

    if val ~= nil then
        if type(val) == "boolean" then
            wndControl:SetCheck(val)
        elseif type(val) == "number" then
            wndControl:SetText(val)
        elseif type(val) == "string" then
            wndControl:SetText(val)
        end
    end
end

-- (Hopefully!) last custom handler for setting save & restore stuff
-- This one for the sliders in general, since we use them in DisplayBlock
-- and have some extra tables for width/height!
function RaidCore:LoadGeneralSliders(wndHandler, wndControl )
    local settingType = self:SplitString(wndControl:GetParent():GetParent():GetName(), "_")[2]
    local setting = self:SplitString(wndControl:GetName(), "_")
    local val = self.settings[settingType][setting[2]][setting[3]][setting[4]]

    if val ~= nil then
        if type(val) == "boolean" then
            wndControl:SetCheck(val)
        elseif type(val) == "number" then
            wndControl:SetText(string.format("%.fpx", val))
            if wndControl.SetValue then
                wndControl:SetValue(val)
            end
        elseif type(val) == "string" then
            wndControl:SetText(val)
        end
    end
end

local function wipe(t)
    for k,v in pairs(t) do
        t[k] = nil
    end
end

-- on SlashCommand "/raidcore"
function RaidCore:OnRaidCoreOn(cmd, args)
    local tAllParams = {}
    for sOneParam in string.gmatch(args, "[^%s]+") do
        table.insert(tAllParams, sOneParam)
    end

    if (tAllParams[1] == "config") then
        self:OnConfigOn()
    elseif (tAllParams[1] == "bar") then
        if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
            self:AddBar(tAllParams[2], tAllParams[2], tAllParams[3])
        else
            self:AddBar("truc", "OVERDRIVE", 10, true)
            self:AddMsg("mtruc2", "OVERDRIVE", 5, "Alarm", "Blue")
        end
    elseif (tAllParams[1] == "unit") then
        local unit = GameLib.GetTargetUnit()
        if unit ~= nil then
            self:MarkUnit(unit, 1, "N1")
            self:AddUnit(unit)
        end
    elseif (tAllParams[1] == "reset") then
        self:ResetAll()
    elseif (tAllParams[1] == "testpe") then
        self:TestPE()
    elseif (tAllParams[1] == "msg") then
        if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
            self:AddMsg(tAllParams[2], tAllParams[3], 5)
        end
    elseif (tAllParams[1] == "version") then
        Print("RaidCore version : " .. AddonVersion)
    elseif (tAllParams[1] == "versioncheck") then
        self:VersionCheck()
    elseif (tAllParams[1] == "pull") then
        if tAllParams[2] ~= nil then
            self:LaunchPull(tonumber(tAllParams[2]))
        else
            self:LaunchPull(10)
        end
    elseif (tAllParams[1] == "break") then
        if tAllParams[2] ~= nil then
            self:LaunchBreak(tonumber(tAllParams[2]))
        else
            self:LaunchBreak(600)
        end
    elseif (tAllParams[1] == "summon") then
        self:SyncSummon()
    elseif (tAllParams[1] == "buff") then
        local unit = GameLib.GetTargetUnit()
        if unit ~= nil then
            local id = unit:GetId()
            self:CombatInterface_Track(id)
            self.buffs[id] = {
                ["unit"] = unit,
                ["aura"] = {},
            }
        end
    elseif (tAllParams[1] == "debuff") then
        local unit = GameLib.GetTargetUnit()
        if unit ~= nil then
            local id = unit:GetId()
            self:CombatInterface_Track(id)
            self.debuffs[id] = {
                ["unit"] = unit,
                ["aura"] = {},
            }
        end
    elseif (tAllParams[1] == "testline") then
        local uPlayer = GameLib.GetPlayerUnit()
        local unit = GameLib.GetTargetUnit()
        self.drawline:AddLine("Ohmna1", 2, unit, nil, 3, 25, 0, 10)
        self.drawline:AddLine("Ohmna2", 2, unit, nil, 1, 25, 120)
        self.drawline:AddLine("Ohmna3", 2, unit, nil, 1, 25, -120)
        self.drawline:AddLine("Ohmna4", 1, uPlayer, unit, 2)
    elseif (tAllParams[1] == "testpixie") then
        local uPlayer = GameLib.GetPlayerUnit()
        local unit = GameLib.GetTargetUnit()
        self.drawline:AddPixie("Ohmna1", 2, unit, nil, "Blue", 10, 25, 0)
        self.drawline:AddPixie("Ohmna2", 2, unit, nil, "Green", 10, 25, 120)
        self.drawline:AddPixie("Ohmna3", 2, unit, nil, "Green", 10, 25, -120)
        self.drawline:AddPixie("Ohmna4", 1, uPlayer, unit, "Yellow", 5)
    elseif (tAllParams[1] == "stopline") then
        self.drawline:ResetLines()
    elseif (tAllParams[1] == "sysdm") then
        if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
            local mod = self:GetModule("SystemDaemons", 1)
            if mod then
                mod:SetInterrupter(tAllParams[2], tonumber(tAllParams[3]))
            else
                Print("Module SystemDaemons not loaded")
            end
        end
    elseif (tAllParams[1] == "sysdm") then
        if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
            local mod = self:GetModule("SystemDaemons", 1)
            if mod then
                mod:SetInterrupter(tAllParams[2], tonumber(tAllParams[3]))
            else
                Print("Module SystemDaemons not loaded")
            end
        end
    elseif (tAllParams[1] == "testdm") then
        local mod = self:GetModule("SystemDaemons", 1)
        if mod then
            mod:NextWave()
            mod:OnChatDC("COMMENCING ENHANCEMENT SEQUENCE")
        else
            Print("Module SystemDaemons not loaded")
        end
    elseif (tAllParams[1] == "testel") then
        local mod = self:GetModule("EpLogicEarth", 1)
        if mod then
            mod:PlaceSpawnPos()
        else
            Print("Module EpLogicEarth not loaded")
        end
    elseif (tAllParams[1] == "wm") then
        local estpos = {
            x = 194.44,
            y = -110.80034637451,
            z = -483.20
        }
        self:SetWorldMarker("EST", "EST", estpos)
        local sudpos = {
            x = 165.79222106934,
            y = -110.80034637451,
            z = -464.8489074707
        }
        self:SetWorldMarker("SUD", "SUD", sudpos)
        local ouestpos = {
            x = 144.20,
            y = -110.80034637451,
            z = -494.38
        }
        self:SetWorldMarker("WEST", "WEST", ouestpos)
        local nordpos = {
            x = 175.00,
            y = -110.80034637451,
            z = -513.31
        }
        self:SetWorldMarker("NORD", "NORD", nordpos)
    else
        self:OnConfigOn()
    end
end

-- on timer
function RaidCore:OnTimer()
    self.raidbars:RefreshBars()
    self.unitmoni:RefreshUnits()
    self.message:RefreshMsg()
end

function RaidCore:isPublicEventObjectiveActive(objectiveString)
    local activeEvents = PublicEvent:GetActiveEvents()
    if activeEvents == nil then
        return false
    end

    for eventId, event in pairs(activeEvents) do
        local objectives = event:GetObjectives()
        if objectives ~= nil then
            for id, objective in pairs(objectives) do
                if objective:GetShortDescription() == objectiveString then
                    return objective:GetStatus() == 1
                end
            end
        end
    end
    return false
end

function RaidCore:hasActiveEvent(tblEvents)
    for key, value in pairs(tblEvents) do
        if self:isPublicEventObjectiveActive(key) then
            return true
        end
    end
    return false
end

function RaidCore:OnCheckMapZone()
    if not _bIsEncounterInProgress then
        local tMap = GetCurrentZoneMap()
        if tMap then
            local tTrigInZone = _tTrigPerZone[tMap.continentId]
            local bSearching = false
            if tTrigInZone then
                tTrigInZone = tTrigInZone[tMap.parentZoneId]
                if tTrigInZone then
                    tTrigInZone = tTrigInZone[tMap.id]
                    if tTrigInZone then
                        bSearching = true
                    end
                end
            end
            if bSearching then
                self:CombatInterface_Activate("DetectCombat")
                _tHUDtimer:Start()
            else
                _tHUDtimer:Stop()
                self:CombatInterface_Activate("Disable")
                self:ResetAll()
            end
        else
            self:ScheduleTimer("OnCheckMapZone", 5)
        end
    end
end

function RaidCore:AddBar(key, message, duration, emphasize)
    self.raidbars:AddBar(key, message, duration)
    if emphasize then
        self:AddEmphasize(key, duration)
    end
end

function RaidCore:StopBar(key)
    self.raidbars:ClearBar(key)
    self:StopEmphasize(key)
end

function RaidCore:AddMsg(key, message, duration, sound, color)
    self.message:AddMsg(key, message, duration, sound, color)
end

function RaidCore:StopDelayedMsg(key)
    if self.delayedmsg[key] then
        self:CancelTimer(self.delayedmsg[key])
        self.delayedmsg[key] = nil
    end
end

function RaidCore:AddDelayedMsg(key, delay, message, duration, sound, color)
    self:StopDelayedMsg(key)
    self.delayedmsg[key] = self:ScheduleTimer("AddMsg", delay, key, message, duration, sound, color)
end

function RaidCore:PrintEmphasize(key, num)
    self:AddMsg("EMP"..key..num, num, 0.9, num, "Green")
    self.emphasize[key][num] = nil
    if num == 1 then
        self.emphasize[key] = nil
    end
end

function RaidCore:StopEmphasize(key)
    if self.emphasize[key] then
        for k, v in pairs(self.emphasize[key]) do
            self:CancelTimer(v)
        end
        self.emphasize[key] = nil
    end
end

function RaidCore:AddEmphasize(key, delay)
    self:StopEmphasize(key)
    if not self.emphasize[key] then self.emphasize[key] = {} end
    if delay >= 1 then
        self.emphasize[key][1] = self:ScheduleTimer("PrintEmphasize", delay - 1, key, 1)
        if delay >= 2 then
            self.emphasize[key][2] = self:ScheduleTimer("PrintEmphasize", delay - 2, key, 2)
            if delay >= 3 then
                self.emphasize[key][3] = self:ScheduleTimer("PrintEmphasize", delay - 3, key, 3)
                if delay >= 4 then
                    self.emphasize[key][4] = self:ScheduleTimer("PrintEmphasize", delay - 4, key, 4)
                    if delay >= 5 then
                        self.emphasize[key][5] = self:ScheduleTimer("PrintEmphasize", delay - 5, key, 5)
                    end
                end
            end
        end
    end
end

function RaidCore:AddUnit(unit)
    local marked = nil
    if self.mark[unit:GetId()] then
        marked = self.mark[unit:GetId()].number
    end
    self.unitmoni:AddUnit(unit, marked)
end

function RaidCore:RemoveUnit(unitId)
    self.unitmoni:RemoveUnit(unitId)
end

function RaidCore:SetMarkToUnit(unit, marked)
    if not marked then
        marked = self.mark[unit:GetId()].number
    end
    self.unitmoni:SetMarkUnit(unit, marked)
end

function RaidCore:StartScan()
    -- Deprecated function
end

function RaidCore:StopScan()
    -- Deprecated function
end

function RaidCore:WatchUnit(unit)
    if unit then
        local id = unit:GetId()
        if id and not unit:IsDead() and not self.watch[id] then
            self:CombatInterface_Track(id)
            self.watch[id] = {
                ["unit"] = unit,
            }
        end
    end
end

function RaidCore:UnitBuff(unit)
    if unit then
        local id = unit:GetId()
        if id and not unit:IsDead() and not self.buffs[id] then
            self:CombatInterface_Track(id)
            self.buffs[id] = {
                ["unit"] = unit,
                ["aura"] = {},
            }
        end
    end
end

function RaidCore:UnitDebuff(unit)
    if unit then
        local id = unit:GetId()
        if id and not unit:IsDead() and not self.debuffs[id] then
            self.debuffs[id] = {
                ["unit"] = unit,
                ["aura"] = {},
            }
        end
    end
end

function RaidCore:RaidDebuff()
    for i = 1, GroupLib.GetMemberCount() do
        local unit = GroupLib.GetUnitForGroupMember(i)
        if unit then
            self:UnitDebuff(unit)
        end
    end
end

function RaidCore:MarkUnit(unit, location, mark)
    if unit and not unit:IsDead() then
        local key = unit:GetId()
        if not self.mark[key] then
            self.mark[key] = {}
            self.mark[key]["unit"] = unit
            if not mark then
                markCount = markCount + 1
                self.mark[key].number = markCount
            else
                self.mark[key].number = mark
            end

            local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
            markFrame:SetUnit(unit, location)
            markFrame:FindChild("Name"):SetText(self.mark[key].number)
            self:MarkerVisibilityHandler(markFrame)

            self.mark[key].frame = markFrame
        elseif mark then
            self.mark[key].number = mark
            self.mark[key].frame:FindChild("Name"):SetText(self.mark[key].number)
        end
        self:SetMarkToUnit(unit, mark)
    end
end

function RaidCore:MarkerVisibilityHandler(markFrame)
    -- If marker was never on screen it might already have been destroyed again
    -- so we'll check if it still exists
    if not markFrame or not markFrame:IsValid() then return end
    if markFrame:IsOnScreen() then
        markFrame:Show(true)
    else
        -- run check again later
        self:ScheduleTimer("MarkerVisibilityHandler", 1, markFrame)
    end
end

-- Removes all the world markers
function RaidCore:ResetWorldMarkers()
    for k, over in pairs(self.worldmarker) do
        over:Destroy()
        self.worldmarker[k] = nil
    end
end

function RaidCore:CreateWorldMarker(key, sText, tPosition)
    local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
    markFrame:SetWorldLocation(tPosition)
    markFrame:FindChild("Name"):SetText(sText)
    self.worldmarker[key] = markFrame
    self:MarkerVisibilityHandler(markFrame)
end

function RaidCore:UpdateWorldMarker(key, sText, tPosition)
    if sText then
        local wndText = self.worldmarker[key]:FindChild("Name")
        if wndText:GetText() ~= sText then
            wndText:SetText(sText)
        end
    end

    if tPosition then 
        self.worldmarker[key]:SetWorldLocation(tPosition)
    end
end

function RaidCore:DropWorldMarker(key)
    if self.worldmarker[key] then
        self.worldmarker[key]:Destroy()
        self.worldmarker[key] = nil
        return true
    end
end

function RaidCore:SetWorldMarker(key, sText, tPosition)
    assert(key)
    local tWorldMarker = self.worldmarker[key]
    if not tWorldMarker and sText and tPosition then
        self:CreateWorldMarker(key, sText, tPosition)
    elseif tWorldMarker and (sText or tPosition) then
        self:UpdateWorldMarker(key, sText, tPosition)
    elseif tWorldMarker and not sText and not tPosition then
        self:DropWorldMarker(key)
    end
end

function RaidCore:AddLine(... )
    self.drawline:AddLine(...)
end

function RaidCore:AddPixie(... )
    self.drawline:AddPixie(...)
end

function RaidCore:DropPixie(key)
    self.drawline:DropPixie(key)
end

function RaidCore:DropLine(key)
    self.drawline:DropLine(key)
end

function RaidCore:OnUnitDestroyed(key, unit, unitName)
    Event_FireGenericEvent("RC_UnitDestroyed", unit, unitName)
    if self.watch[key] then
        self.watch[key] = nil
    end
    if self.mark[key] then
        local markFrame = self.mark[key].frame
        markFrame:SetUnit(nil)
        markFrame:Destroy()
        self.mark[key] = nil
    end
    if self.debuffs[key] and unit:IsDead() then
        self.debuffs[key] = nil
    end
    if self.buffs[key] then
        self.buffs[key] = nil
    end
end

function RaidCore:SetTarget(position)
    if trackMaster ~= nil then
        trackMaster:SetTarget(position)
    end
end

function RaidCore:OnCastStart(nId, sCastName)
    local v = self.watch[nId]
    if v then
        local unitName = v.unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("SPELL_CAST_START", unitName, sCastName, v.unit)
    end
end

function RaidCore:OnCastEnd(nId, sCastName, bInterrupted)
    local v = self.watch[nId]
    if v then
        local unitName = v.unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("SPELL_CAST_END", unitName, sCastName, v.unit)
    end
end

function RaidCore:OnBuffAdd(nId, nSpellId, nStack)
    local buffs = self.buffs[nId]
    if buffs then
        unit = buffs.unit
        local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("BUFF_APPLIED", unitName, nSpellId, unit)
    end
end

function RaidCore:OnBuffRemove(nId, nSpellId, nStack)
    local buffs = self.buffs[nId]
    if buffs then
        unit = buffs.unit
        local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("BUFF_REMOVED", unitName, nSpellId, unit)
    end
end

function RaidCore:OnBuffUpdate(nId, nSpellId, nOldStack, nNewStack)
    local buffs = self.buffs[nId]
    if buffs then
        unit = buffs.unit
        local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("BUFF_APPLIED_DOSE", unitName, nSpellId, nStack)
    end
end

function RaidCore:OnDebuffAdd(nId, nSpellId, nStack)
    local debuffs = self.debuffs[nId]
    if debuffs then
        unit = debuffs.unit
        local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("DEBUFF_APPLIED", unitName, nSpellId, unit)
    end
end

function RaidCore:OnDebuffRemove(nId, nSpellId)
    local debuffs = self.debuffs[nId]
    if debuffs then
        unit = debuffs.unit
        local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("DEBUFF_REMOVED", unitName, nSpellId, unit)
    end
end

function RaidCore:OnDebuffUpdate(nId, nSpellId, nOldStack, nNewStack)
    local debuffs = self.debuffs[nId]
    if debuffs then
        unit = debuffs.unit
        local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("DEBUFF_APPLIED_DOSE", unitName, nSpellId, nStack)
    end
end

function RaidCore:OnMarkUpdate()
    for k, v in pairs(self.mark) do
        if v.unit:GetPosition() then
            v.frame:SetWorldLocation(v.unit:GetPosition())
        end
    end
end

function RaidCore:DropMark(key)
    if self.mark[key] then
        local markFrame = self.mark[key].frame
        markFrame:SetUnit(nil)
        markFrame:Destroy()
        self.mark[key] = nil
    end
end

function RaidCore:ResetMarks()
    for k, over in pairs(self.mark) do
        over.frame:SetUnit(nil)
        over.frame:Destroy()
        self.mark[k] = nil
    end
    markCount = 0
end

function RaidCore:ResetWatch()
    wipe(self.watch)
end

function RaidCore:ResetBuff()
    wipe(self.buffs)
end

function RaidCore:ResetDebuff()
    wipe(self.debuffs)
end

function RaidCore:ResetEmphasize()
    for key, emp in pairs(self.emphasize) do
        self:StopEmphasize(key)
    end
end

function RaidCore:ResetDelayedMsg()
    for key, timer in pairs(self.delayedmsg) do
        self:StopDelayedMsg(key)
    end
end

function RaidCore:ResetSync()
    wipe(self.syncTimer)
    wipe(self.syncRegister)
end

function RaidCore:ResetLines()
    self.drawline:ResetLines()
end

function RaidCore:TestPE()
    local tActiveEvents = PublicEvent.GetActiveEvents()
    local i = RaidCore:isPublicEventObjectiveActive("Talk to Captain Tero")
    Print("result ".. tostring(i))
    i = RaidCore:isPublicEventObjectiveActive("Talk to Captain Teroxx")
    Print("result ".. tostring(i))
    for idx, peEvent in pairs(tActiveEvents) do
        local test = peEvent:GetName()
        local truc
        Print(test)
        for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
            test = peObjective:GetShortDescription()
            if test == "North Power Core Energy" then
                truc = peObjective:GetCount()
                Print(test)
                Print(truc)
            end
        end
    end
end

function RaidCore:OnSay(sMessage)
    Event_FireGenericEvent('CHAT_SAY', sMessage)
end

function RaidCore:OnNPCSay(sMessage)
    Event_FireGenericEvent('CHAT_NPCSAY', sMessage)
end

function RaidCore:OnNPCYell(sMessage)
    Event_FireGenericEvent('CHAT_NPCYELL', sMessage)
end

function RaidCore:OnNPCWisper(sMessage)
    Event_FireGenericEvent('CHAT_NPCWHISPER', sMessage)
end

function RaidCore:OnDatachron(sMessage)
    Event_FireGenericEvent('CHAT_DATACHRON', sMessage)
end

function RaidCore:PrintBerserk()
    self:AddMsg("BERSERK", "BERSERK IN 1MIN", 5, nil, "Green")
    self:AddBar("BERSERK", "BERSERK", 60)
    self.berserk = false
end

function RaidCore:Berserk(timer)
    if timer > 60 then
        self.berserk = self:ScheduleTimer("PrintBerserk", timer - 60)
    end
end

function RaidCore:ResetAll()
    _tWipeTimer:Stop()
    if self.berserk then
        self:CancelTimer(self.berserk)
        self.berserk = nil
    end
    self.raidbars:ClearAll()
    self.unitmoni:ClearAll()
    self.message:ClearAll()
    self:ResetWatch()
    self:ResetDebuff()
    self:ResetBuff()
    self:ResetMarks()
    self:ResetWorldMarkers()
    self:ResetEmphasize()
    self:ResetDelayedMsg()
    self:ResetSync()
    self:ResetLines()
end

function RaidCore:WipeCheck()
    for i = 1, GroupLib.GetMemberCount() do
        local unit = GroupLib.GetUnitForGroupMember(i)
        if unit then
            if unit:IsInCombat() then
                return
            end
        end
    end
    _tWipeTimer:Stop()
    if self.berserk then
        self:CancelTimer(self.berserk)
        self.berserk = nil
    end
    Log:Add("Encounter no more in progress")
    _bIsEncounterInProgress = false
    if _tCurrentEncounter then
        Event_FireGenericEvent("RAID_WIPE")
        _tCurrentEncounter:Disable()
        _tCurrentEncounter = nil
    end
    self.raidbars:ClearAll()
    self.unitmoni:ClearAll()
    self.message:ClearAll()
    self:ResetWatch()
    self:ResetDebuff()
    self:ResetBuff()
    self:ResetMarks()
    self:ResetWorldMarkers()
    self:ResetEmphasize()
    self:ResetDelayedMsg()
    self:ResetSync()
    self:ResetLines()

    self:CombatInterface_Activate("DetectCombat")
end

function RaidCore:OnUnitCreated(nId, tUnit, sName)
    Event_FireGenericEvent("RC_UnitCreated", tUnit, sName)
end

function RaidCore:OnEnteredCombat(nId, tUnit, sName, bInCombat)
    -- Manage the lower layer.
    if tUnit == GetPlayerUnit() then
        if bInCombat then
            -- Player entering in combat.
            Log:Add("Player In Combat")
            _bIsEncounterInProgress = true
            self:CombatInterface_Activate("FullEnable")
            if _tCurrentEncounter and not _tCurrentEncounter:IsEnabled() then
                _tCurrentEncounter:Enable()
                ProcessDelayedUnit()
            end
        else
            -- Player is dead or left the combat.
            _tWipeTimer:Start()
        end
    elseif not tUnit:IsInYourGroup() then
        if not _tCurrentEncounter then
            ManageDelayedUnit(nId, sName, bInCombat)
            if _bIsEncounterInProgress then
                SearchEncounter()
                if _tCurrentEncounter and not _tCurrentEncounter:IsEnabled() then
                    _tCurrentEncounter:Enable()
                    ProcessDelayedUnit()
                end
            end
        else
            -- Dispatch this Event to the Encounter
            Event_FireGenericEvent("RC_UnitStateChanged", tUnit, bInCombat, sName)
        end
    end
end

local function IsPartyMemberByName(sName)
    for i=1, GroupLib.GetMemberCount() do
        local unit = GroupLib.GetGroupMember(i)
        if unit then
            if unit.strCharacterName == sName then
                return true
            end
        end
    end
    return false
end

function RaidCore:OnComMessage(channel, strMessage, strSender)
    local tMessage = JSON.decode(strMessage)
    if type(tMessage.action) ~= "string" then return end
    local msg = {}

    if tMessage.action == "VersionCheckRequest" and IsPartyMemberByName(tMessage.sender) then
        msg = {action = "VersionCheckReply", sender = GameLib.GetPlayerUnit():GetName(), version = AddonVersion}
        self:SendMessage(msg)
    elseif tMessage.action == "VersionCheckReply" and tMessage.sender and tMessage.version and VCtimer then
        VCReply[tMessage.sender] = tMessage.version
    elseif tMessage.action == "NewestVersion" and tMessage.version then
        if AddonVersion < tMessage.version then
            Print("Your RaidCore version is outdated. Please get " .. tMessage.version)
        end
    elseif tMessage.action == "LaunchPull" and IsPartyMemberByName(tMessage.sender) and tMessage.cooldown then
        self:AddBar("PULL", "PULL", tMessage.cooldown, true)
        self:AddMsg("PULL", ("PULL in %s"):format(tMessage.cooldown), 5, nil, "Green")
    elseif tMessage.action == "LaunchBreak" and IsPartyMemberByName(tMessage.sender) and tMessage.cooldown then
        self:AddBar("BREAK", "BREAK", tMessage.cooldown)
        self:AddMsg("BREAK", ("BREAK for %s sec"):format(tMessage.cooldown), 5, "Long", "Green")
    elseif tMessage.action == "Sync" and tMessage.sync and self.syncRegister[tMessage.sync] then
        local timeOfEvent = GameLib.GetGameTime()
        if timeOfEvent - self.syncTimer[tMessage.sync] >= self.syncRegister[tMessage.sync] then
            self.syncTimer[tMessage.sync] = timeOfEvent
            Event_FireGenericEvent("RAID_SYNC", tMessage.sync, tMessage.parameter)
        end
    elseif tMessage.action == "SyncSummon" then
        if not self.settings["General"]["bAcceptSummons"] or not self:isRaidManagement(strSender) then
            return false
        end
        Print(tMessage.sender .. " requested that you accept a summon. Attempting to accept now.")
        local CSImsg = CSIsLib.GetActiveCSI()
        if not CSImsg or not CSImsg["strContext"] then return end

        if CSImsg["strContext"] == "Teleport to your group member?" then
            if CSIsLib.IsCSIRunning() then
                CSIsLib.CSIProcessInteraction(true)
            end
        end
    end
end

function RaidCore:VersionCheckResults()
    local maxver = 0
    local outdatedList = ""
    VCtimer = nil

    for k,v in pairs(VCReply) do
        if v > maxver then
            maxver = v
        end
    end

    local count = 0
    for i=1, GroupLib.GetMemberCount() do
        local unit = GroupLib.GetGroupMember(i)
        if unit then
            local playerName = unit.strCharacterName
            if not VCReply[playerName] or VCReply[playerName] < maxver then
                count = count + 1
                if count == 1 then
                    outdatedList = playerName
                else
                    outdatedList = playerName .. ", " .. outdatedList
                end
            end
        end
    end

    if string.len(outdatedList) > 0 then
        Print(("Outdated (%s) : %s"):format(count,outdatedList))
    else
        Print("Outdated : None ! Congrats")
    end
    local msg = {action = "NewestVersion", version = maxver}
    self:SendMessage(msg)
    self:OnComMessage(nil, JSON.encode(msg))
end

function RaidCore:VersionCheck()
    if VCtimer then
        Print("VersionCheck already running ...")
        return
    end
    Print("Running VersionCheck")
    wipe(VCReply)
    VCReply[GameLib.GetPlayerUnit():GetName()] = AddonVersion
    local msg = {action = "VersionCheckRequest", sender = GameLib.GetPlayerUnit():GetName()}
    VCtimer = ApolloTimer.Create(5, false, "VersionCheckResults", self)
    self:SendMessage(msg)
end

function RaidCore:LaunchPull(time)
    if time and time > 2 then
        local msg = {action = "LaunchPull", sender = GameLib.GetPlayerUnit():GetName(), cooldown = time}
        self:SendMessage(msg)
        self:OnComMessage(nil, JSON.encode(msg))
    end
end

function RaidCore:LaunchBreak(time)
    local sPlayerName = GetPlayerUnit():GetName()
    if not self:isRaidManagement(sPlayerName) then
        Print("You must be a raid leader or assistant to use this command!")
    else
        if time and time > 5 then
            local msg = {action = "LaunchBreak", sender = sPlayerName, cooldown = time}
            self:SendMessage(msg)
            self:OnComMessage(nil, JSON.encode(msg))
        end
    end
end

function RaidCore:SyncSummon()
    local myName = GameLib.GetPlayerUnit():GetName()
    if not self:isRaidManagement(myName) then
        Print("You must be a raid leader or assistant to use this command!")
        return false
    end
    local msg = {action = "SyncSummon", sender = myName}
    self:SendMessage(msg)
end

function RaidCore:AddSync(sync, throttle)
    self.syncRegister[sync] = throttle or 5
    if not self.syncTimer[sync] then self.syncTimer[sync] = 0 end
end

function RaidCore:SendSync(syncName, param)
    if syncName and self.syncRegister[syncName] then
        local timeOfEvent = GameLib.GetGameTime()
        if timeOfEvent - self.syncTimer[syncName] >= self.syncRegister[syncName] then
            self.syncTimer[syncName] = timeOfEvent
            Event_FireGenericEvent("RAID_SYNC", syncName, param)
        end
    end
    local msg = {action = "Sync", sender = GameLib.GetPlayerUnit():GetName(), sync = syncName, parameter = param}
    self:SendMessage(msg)
end

function RaidCore:isRaidManagement(strName)
    if not GroupLib.InGroup() then return false end
    for nIdx=0, GroupLib.GetMemberCount() do
        local tGroupMember = GroupLib.GetGroupMember(nIdx)
        if tGroupMember and tGroupMember["strCharacterName"] == strName then
            if tGroupMember["bIsLeader"] or tGroupMember["bRaidAssistant"] then
                return true
            else
                return false
            end
        end
    end
    return false -- just in case
end

----------------------------------------------------------------------------------------------------
-- RaidCoreForm Functions
----------------------------------------------------------------------------------------------------
function RaidCore:recursiveCopyTable(from, to)
    to = to or {}
    for k,v in pairs(from) do
        if type(v) == "table" then
            to[k] = self:recursiveCopyTable(v, to[k])
        else
            to[k] = v
        end
    end
    return to
end

function RaidCore:SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function RaidCore:GetSettings()
    return self.settings
end

function RaidCore:HideChildWindows(wndParent)
    for key, value in pairs(wndParent:GetChildren()) do
        value:Show(false)
    end
end

-- when the Reset button is clicked
function RaidCore:OnResetBarPositions( wndHandler, wndControl, eMouseButton )
    self.raidbars:ResetPosition()
    self.unitmoni:ResetPosition()
    self.message:ResetPosition()
end

-- when the Move button is clicked
function RaidCore:OnMoveBars( wndHandler, wndControl, eMouseButton )
    if wndHandler:GetText() == "Move Bars" then
        wndHandler:SetText("Lock Bars")
        self.raidbars:SetMovable(true)
        self.unitmoni:SetMovable(true)
        self.message:SetMovable(true)
    else
        wndHandler:SetText("Move Bars")
        self.raidbars:SetMovable(false)
        self.unitmoni:SetMovable(false)
        self.message:SetMovable(false)
    end
end

function RaidCore:OnConfigOn()
    self.wndConfig:Invoke()
end

function RaidCore:OnConfigCloseButton()
    self.wndConfig:Close()
end

function RaidCore:Button_DSSettingsCheck(wndHandler, wndControl, eMouseButton)
    self.wndModuleList["DS"]:Show(true)
end

function RaidCore:Button_DSSettingsUncheck(wndHandler, wndControl, eMouseButton)
    self.wndModuleList["DS"]:Show(false)
end

function RaidCore:Button_SettingsGeneralCheck( wndHandler, wndControl, eMouseButton )
    self:HideChildWindows(self.wndTargetFrame)
    self.wndSettings["General"]:Show(true)
end

function RaidCore:Button_SettingsGeneralUncheck( wndHandler, wndControl, eMouseButton )
    self.wndSettings["General"]:Show(false)
end

function RaidCore:OnModuleSettingsCheck(wndHandler, wndControl, eMouseButton )
    local raidInstance = self:SplitString(wndControl:GetParent():GetName(), "_")
    local identifier = self:SplitString(wndControl:GetName(), "_")
    self.wndSettings[raidInstance[2]][identifier[3]]:Show(true)
end

function RaidCore:OnModuleSettingsUncheck(wndHandler, wndControl, eMouseButton )
    local raidInstance = self:SplitString(wndControl:GetParent():GetName(), "_")
    local identifier = self:SplitString(wndControl:GetName(), "_")
    self.wndSettings[raidInstance[2]][identifier[3]]:Show(false)
end

