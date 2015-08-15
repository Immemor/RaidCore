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

local GeminiAddon = Apollo.GetPackage("Gemini:Addon-1.1").tPackage
local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
local RaidCore = GeminiAddon:NewAddon("RaidCore", false, {}, "Gemini:Timer-1.0")

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
-- Should be @project-version@ when replacement tokens will works (see #88 issue).
local RAIDCORE_CURRENT_VERSION = "3.12-alpha"
-- Should be deleted.
local ADDON_DATE_VERSION = 15081002
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with French language. This problem is not present in English.
local NO_BREAK_SPACE = string.char(194, 160)

local MYCOLORS = {
    ["Blue"] = "FF0066FF",
    ["Green"] = "FF00CC00",
}

----------------------------------------------------------------------------------------------------
-- Privates variables.
----------------------------------------------------------------------------------------------------
local _wndrclog = nil
local _tWipeTimer
local _tTrigPerZone = {}
local _tEncountersPerZone = {}
local _tDelayedUnits = {}
local _bIsEncounterInProgress = false
local _tCurrentEncounter = nil
local trackMaster = Apollo.GetAddon("TrackMaster")
local markCount = 0
local VCReply, VCtimer = {}, nil
local empCD, empTimer = 5, nil

----------------------------------------------------------------------------------------------------
-- Privates functions
----------------------------------------------------------------------------------------------------
local function Split(str, sep)
    assert(str)
    sep = sep or "%s"
    local r = {}
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(r, str)
    end
    return r
end

local function ManageDelayedUnit(nId, sName, bInCombat)
    local tMap = GetCurrentZoneMap()
    local id1 = tMap.continentId
    local id2 = tMap.parentZoneId
    local id3 = tMap.id
    local tTrig = _tTrigPerZone[id1] and _tTrigPerZone[id1][id2] and _tTrigPerZone[id1][id2][id3]
    if tTrig and tTrig[sName] then
        if bInCombat then
            if not _tDelayedUnits[sName] then
                _tDelayedUnits[sName] = {}
            end
            _tDelayedUnits[sName][nId] = true
        else
            if _tDelayedUnits[sName] then
                if _tDelayedUnits[sName][nId] then
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
                Event_FireGenericEvent("RC_UnitCreated", tUnit, nDelayedName)
                if bInCombat then
                    Event_FireGenericEvent("RC_UnitStateChanged", tUnit, bInCombat, nDelayedName)
                end
            end
        end
    end
    _tDelayedUnits = {}
end

local function OnMenuLeft_CheckUncheck(wndButton, bIsChecked)
    local sButtonName = wndButton:GetName()
    if not bIsChecked then
        local wnd = RaidCore.wndTargetFrame:GetData()
        if wnd then
            wnd:Show(false)
            RaidCore.wndTargetFrame:SetData(nil)
        end
    else
        if sButtonName ~= "Datascape" and sButtonName ~= "Genetic_Archives" then
            local wnd = RaidCore.wndSettings[sButtonName]
            wnd:Show(true)
            RaidCore.wndTargetFrame:SetData(wnd)
        end
    end

    if sButtonName == "Datascape" then
        RaidCore.wndModuleList["DS"]:Show(bIsChecked)
    elseif sButtonName == "Genetic_Archives" then
        RaidCore.wndModuleList["GA"]:Show(bIsChecked)
    end
end

----------------------------------------------------------------------------------------------------
-- RaidCore Initialization
----------------------------------------------------------------------------------------------------
function RaidCore:Print(sMessage)
    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug, tostring(sMessage), "RaidCore")
end

function RaidCore:OnInitialize()
    self.xmlDoc = XmlDoc.CreateFromFile("RaidCore.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
    Apollo.LoadSprites("Textures_GUI.xml")
    Apollo.LoadSprites("Textures_Bars.xml")

    local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
    self.L = GeminiLocale:GetLocale("RaidCore")
    local GeminiDB = Apollo.GetPackage("Gemini:DB-1.0").tPackage
    self.db = GeminiDB:New(self, nil, true)
end

----------------------------------------------------------------------------------------------------
-- RaidCore OnDocLoaded
----------------------------------------------------------------------------------------------------
function RaidCore:OnDocLoaded()
    -- Send version information to OneVersion Addon.
    local fNumber = RAIDCORE_CURRENT_VERSION:gmatch("%d+")
    local sSuffix = RAIDCORE_CURRENT_VERSION:gmatch("%a+")()
    local nMajor, nMinor = fNumber(), fNumber()
    local nSuffix = sSuffix == "alpha" and -2 or sSuffix == "beta" and -1 or 0
    Event_FireGenericEvent("OneVersion_ReportAddonInfo", "RaidCore", nMajor, nMinor, 0, nSuffix)

    -- Create default settings to provide to GeminiDB.
    local tDefaultSettings = {
        profile = {
            version = RAIDCORE_CURRENT_VERSION,
            Encounters = {},
            BarsManagers = self:GetBarsDefaultSettings(),
            -- Simple and general settings.
            bSoundEnabled = true,
            bAcceptSummons = true,
        }
    }
    -- Final parsing about encounters.
    for name, module in self:IterateModules() do
        local r, e = pcall(module.PrepareEncounter, module)
        if not r then
            self:Print(e)
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

        -- Fill Default setting with encounters definitions.
        tDefaultSettings.profile.Encounters[name] = module.tDefaultSettings or {}
    end
    -- Initialize GeminiDB with the default table.
    self.db:RegisterDefaults(tDefaultSettings)

    -- Load every software block.
    self:CombatInterface_Init(self)
    self:BarManagersInit(self.db.profile.BarsManagers)
    self:LogGUI_init()
    -- Do additional initialization.
    self.mark = {}
    self.worldmarker = {}
    self.berserk = false
    self.syncRegister = {}
    self.syncTimer = {}
    _tWipeTimer = ApolloTimer.Create(0.5, true, "WipeCheck", self)
    _tWipeTimer:Stop()
    self.lines = {}

    -- Initialize the Zone Detection.
    self:OnCheckMapZone()

    -- Load Forms.
    self.wndConfig = Apollo.LoadForm(self.xmlDoc, "ConfigForm", nil, self)
    self.wndConfig:FindChild("Tag"):SetText(RAIDCORE_CURRENT_VERSION)
    self.wndConfig:SetSizingMinimum(950, 500)
    self.wndTargetFrame = self.wndConfig:FindChild("BodyTarget")
    self.wndConfigOptionsTargetFrame = self.wndConfig:FindChild("SubMenuLeft")
    self.wndModuleList = {
        GA = Apollo.LoadForm(self.xmlDoc, "ModuleList_GA", self.wndConfigOptionsTargetFrame, self),
        DS = Apollo.LoadForm(self.xmlDoc, "ModuleList_DS", self.wndConfigOptionsTargetFrame, self),
    }
    self.wndSettings = {
        General = Apollo.LoadForm(self.xmlDoc, "ConfigForm_General", self.wndTargetFrame, self),
        Datascape = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Datascape", self.wndTargetFrame, self),
        CoreY83 = Apollo.LoadForm(self.xmlDoc, "ConfigForm_CoreY83", self.wndTargetFrame, self),
        Genetic_Archives = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Genetic_Archives", self.wndTargetFrame, self),
        About_Us = Apollo.LoadForm(self.xmlDoc, "ConfigForm_About_Us", self.wndTargetFrame, self),
        GA = {
            ExperimentX89 = Apollo.LoadForm(self.xmlDoc, "ConfigForm_ExperimentX89", self.wndTargetFrame, self),
            Kuralak = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Kuralak", self.wndTargetFrame, self),
            Prototypes = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Prototypes", self.wndTargetFrame, self),
            Phagemaw = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Phagemaw", self.wndTargetFrame, self),
            PhageCouncil = Apollo.LoadForm(self.xmlDoc, "ConfigForm_PhageCouncil", self.wndTargetFrame, self),
            Ohmna = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Ohmna", self.wndTargetFrame, self),
        },
        DS = {
            Minibosses = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Minibosses", self.wndTargetFrame, self),
            SystemDaemons = Apollo.LoadForm(self.xmlDoc, "ConfigForm_SystemDaemons", self.wndTargetFrame, self),
            Gloomclaw = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Gloomclaw", self.wndTargetFrame, self),
            Maelstrom = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Maelstrom", self.wndTargetFrame, self),
            Lattice = Apollo.LoadForm(self.xmlDoc, "ConfigForm_Lattice", self.wndTargetFrame, self),
            LimboInfomatrix = Apollo.LoadForm(self.xmlDoc, "ConfigForm_LimboInfomatrix", self.wndTargetFrame, self),
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
    self.drawline = RaidCoreLibs.DisplayLine.new(self.xmlDoc)
    self.GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
    Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)

    -- Initialize Left Menu in Main RaidCore window.
    local wndGeneralButton = self.wndConfig:FindChild("Static"):FindChild("General")
    wndGeneralButton:SetCheck(true)
    OnMenuLeft_CheckUncheck(wndGeneralButton, true)

    -- Register handlers for events, slash commands and timer, etc.
    Apollo.RegisterSlashCommand("raidc", "OnRaidCoreOn", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnCheckMapZone", self)
    Apollo.RegisterEventHandler("SubZoneChanged", "OnCheckMapZone", self)
end

----------------------------------------------------------------------------------------------------
-- RaidCore Channel Communication functions.
----------------------------------------------------------------------------------------------------
function RaidCore:SendMessage(tMessage, tDPlayerId)
    assert(type(tMessage) == "table")
    tMessage.sender = GetPlayerUnit():GetName()
    self:CombatInterface_SendMessage(JSON.encode(tMessage), tDPlayerId)
end

function RaidCore:OnReceivedMessage(sMessage, sSender)
    local tMessage = JSON.decode(sMessage)
    self:ProcessMessage(tMessage, sSender)
end

function RaidCore:ProcessMessage(tMessage, sSender)
    if type(tMessage) ~= "table" or type(tMessage.action) ~= "string" then
        -- Silent error.
        return
    end

    if tMessage.action == "VersionCheckRequest" then
        local msg = {
            action = "VersionCheckReply",
            version = ADDON_DATE_VERSION,
            tag = RAIDCORE_CURRENT_VERSION,
        }
        self:SendMessage(msg)
    elseif tMessage.action == "VersionCheckReply" then
        if tMessage.sender and tMessage.version and VCtimer then
            VCReply[tMessage.sender] = tMessage.version
        end
    elseif tMessage.action == "NewestVersion" then
        if tMessage.version and ADDON_DATE_VERSION < tMessage.version then
            self:Print("Your RaidCore version is outdated. Please get " .. tMessage.version)
        end
    elseif tMessage.action == "LaunchPull" then
        if tMessage.cooldown then
            self:AddTimerBar("PULL", "PULL", tMessage.cooldown)
            self:AddMsg("PULL", ("PULL in %s"):format(tMessage.cooldown), 5, MYCOLORS["Green"])
        end
    elseif tMessage.action == "LaunchBreak" then
        if tMessage.cooldown then
            self:AddTimerBar("BREAK", "BREAK", tMessage.cooldown)
            self:AddMsg("BREAK", ("BREAK for %s sec"):format(tMessage.cooldown), 5, MYCOLORS["Green"])
            self:PlaySound("Long")
        end
    elseif tMessage.action == "Sync" then
        if tMessage.sync and self.syncRegister[tMessage.sync] then
            local timeOfEvent = GameLib.GetGameTime()
            if timeOfEvent - self.syncTimer[tMessage.sync] >= self.syncRegister[tMessage.sync] then
                self.syncTimer[tMessage.sync] = timeOfEvent
                Event_FireGenericEvent("RAID_SYNC", tMessage.sync, tMessage.parameter)
            end
        end
    elseif tMessage.action == "SyncSummon" then
        if not self.db.profile.bAcceptSummons or not self:isRaidManagement(strSender) then
            return false
        end
        self:Print(tMessage.sender .. " requested that you accept a summon. Attempting to accept now.")
        local CSImsg = CSIsLib.GetActiveCSI()
        if not CSImsg or not CSImsg["strContext"] then return end

        if CSImsg["strContext"] == "Teleport to your group member?" then
            if CSIsLib.IsCSIRunning() then
                CSIsLib.CSIProcessInteraction(true)
            end
        end
    elseif tMessage.action == "Encounter_IND" then
        if _tCurrentEncounter and _tCurrentEncounter.ReceiveIndMessage then
            _tCurrentEncounter:ReceiveIndMessage(tMessage.sender, tMessage.reason, tMessage.data)
        end
    end
end

---------------------------------------------------------------------------------------------------
---- ConfigForm_General Functions
-----------------------------------------------------------------------------------------------------
function RaidCore:OnWindowManagementReady()
    local param = {wnd = self.wndConfig, strName = "RaidCore"}
    Event_FireGenericEvent('WindowManagementAdd', param)
end

function RaidCore:OnWindowLoad(wndHandler, wndControl)
    local a, b, c = unpack(Split(wndControl:GetName(), '_'))
    local val = nil
    if c then
        val = self.db.profile[a][b][c]
    elseif b then
        val = self.db.profile[a][b]
    elseif a then
        val = self.db.profile[a]
    end
    assert(val ~= nil)
    if wndControl.SetCheck then
        wndControl:SetCheck(val)
    end
    if type(val) == "boolean"  or a == "Encounters" then
        wndControl:SetCheck(val)
    elseif type(val) == "number" or type(val) == "string" then
        wndControl:SetText(val)
        if wndControl.SetValue and type(val) == "number" then
            wndControl:SetValue(val)
        end
    end
end

function RaidCore:OnButtonCheckBoxSwitched(wndHandler, wndControl, eMouseButton)
    local a, b, c = unpack(Split(wndControl:GetName(), '_'))
    if c then
        self.db.profile[a][b][c] = wndControl:IsChecked()
    elseif b then
        self.db.profile[a][b] = wndControl:IsChecked()
    else
        self.db.profile[a] = wndControl:IsChecked()
    end
end

function RaidCore:OnGeneralSliderBarChanged(wndHandler, wndControl, nNewValue, fOldValue)
    local sName = wndControl:GetName()
    local a, b, c = unpack(Split(sName, '_'))
    nNewValue = math.floor(nNewValue)
    wndControl:GetChildren()[1]:SetText(nNewValue)
    if c then
        self.db.profile[a][b][c] = nNewValue
    elseif b then
        self.db.profile[a][b] = nNewValue
    else
        self.db.profile[a] = nNewValue
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
            self:AddTimerBar(tAllParams[2], tAllParams[2], tonumber(tAllParams[3]))
        else
            self:AddTimerBar("truc", "OVERDRIVE", 10)
            self:AddMsg("mtruc2", "OVERDRIVE", 5, "Alarm", MYCOLORS["Blue"])
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
        self:Print("Version : " .. ADDON_DATE_VERSION)
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
    elseif (tAllParams[1] == "testline") then
        local uPlayer = GetPlayerUnit()
        local unit = GameLib.GetTargetUnit()
        self.drawline:AddLine("Ohmna1", 2, unit, nil, 3, 25, 0, 10)
        self.drawline:AddLine("Ohmna2", 2, unit, nil, 1, 25, 120)
        self.drawline:AddLine("Ohmna3", 2, unit, nil, 1, 25, -120)
        self.drawline:AddLine("Ohmna4", 1, uPlayer, unit, 2)
    elseif (tAllParams[1] == "testpixie") then
        local uPlayer = GetPlayerUnit()
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
                self:Print("Module SystemDaemons not loaded")
            end
        end
    elseif (tAllParams[1] == "sysdm") then
        if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
            local mod = self:GetModule("SystemDaemons", 1)
            if mod then
                mod:SetInterrupter(tAllParams[2], tonumber(tAllParams[3]))
            else
                self:Print("Module SystemDaemons not loaded")
            end
        end
    elseif (tAllParams[1] == "testdm") then
        local mod = self:GetModule("SystemDaemons", 1)
        if mod then
            mod:NextWave()
            mod:OnChatDC("COMMENCING ENHANCEMENT SEQUENCE")
        else
            self:Print("Module SystemDaemons not loaded")
        end
    elseif (tAllParams[1] == "testel") then
        local mod = self:GetModule("EpLogicEarth", 1)
        if mod then
            mod:PlaceSpawnPos()
        else
            self:Print("Module EpLogicEarth not loaded")
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
            else
                self:CombatInterface_Activate("Disable")
            end
        else
            self:ScheduleTimer("OnCheckMapZone", 5)
        end
    end
end

function RaidCore:PlaySound(sFilename)
    assert(type(sFilename) == "string")
    if self.db.profile.bSoundEnabled then
        Sound.PlayFile("Sounds\\".. sFilename .. ".wav")
    end
end

-- Track buff and cast of this unit.
-- @param unit  userdata object related to an unit in game.
function RaidCore:WatchUnit(unit)
    local id = unit:GetId()
    self:CombatInterface_Track(id)
end

function RaidCore:MarkUnit(unit, location, mark)
    if unit and not unit:IsDead() then
        local nId = unit:GetId()
        if not self.mark[nId] then
            self.mark[nId] = {}
            self.mark[nId]["unit"] = unit
            if not mark then
                markCount = markCount + 1
                self.mark[nId].number = tostring(markCount)
            else
                self.mark[nId].number = tostring(mark)
            end

            local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
            markFrame:SetUnit(unit, location)
            markFrame:FindChild("Name"):SetText(self.mark[nId].number)
            self:MarkerVisibilityHandler(markFrame)

            self.mark[nId].frame = markFrame
        elseif mark then
            self.mark[nId].number = tostring(mark)
            self.mark[nId].frame:FindChild("Name"):SetText(self.mark[nId].number)
        end
        self:SetMark2UnitBar(nId, self.mark[nId].number)
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

function RaidCore:OnUnitDestroyed(nId, unit, unitName)
    Event_FireGenericEvent("RC_UnitDestroyed", unit, unitName)
    self:RemoveUnit(nId)
    if self.mark[nId] then
        local markFrame = self.mark[nId].frame
        markFrame:SetUnit(nil)
        markFrame:Destroy()
        self.mark[nId] = nil
    end
end

function RaidCore:SetTarget(position)
    if trackMaster ~= nil then
        trackMaster:SetTarget(position)
    end
end

function RaidCore:OnCastStart(nId, sCastName)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("SPELL_CAST_START", unitName, sCastName, tUnit)
    end
end

function RaidCore:OnCastEnd(nId, sCastName, bInterrupted)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        Event_FireGenericEvent("SPELL_CAST_END", unitName, sCastName, tUnit)
    end
end

function RaidCore:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        -- Keep Old event for compatibility.
        Event_FireGenericEvent("BUFF_APPLIED", unitName, nSpellId, tUnit)
    end
    -- New event not based on the name.
    Event_FireGenericEvent("BUFF_ADD", nId, nSpellId, nStack, fTimeRemaining)
end

function RaidCore:OnBuffRemove(nId, nSpellId)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        -- Keep Old event for compatibility.
        Event_FireGenericEvent("BUFF_REMOVED", unitName, nSpellId, GetUnitById(nId))
    end
    -- New event not based on the name.
    Event_FireGenericEvent("BUFF_DEL", nId, nSpellId)
end

function RaidCore:OnBuffUpdate(nId, nSpellId, nOldStack, nNewStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        -- Keep Old event for compatibility.
        Event_FireGenericEvent("BUFF_APPLIED_DOSE", unitName, nSpellId, nNewStack)
    end
    -- New event not based on the name.
    Event_FireGenericEvent("BUFF_UPDATE", nId, nSpellId, nNewStack, fTimeRemaining)
end

function RaidCore:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        -- Keep Old event for compatibility.
        Event_FireGenericEvent("DEBUFF_APPLIED", unitName, nSpellId, tUnit)
    end
    -- New event not based on the name.
    Event_FireGenericEvent("DEBUFF_ADD", nId, nSpellId, nStack, fTimeRemaining)
end

function RaidCore:OnDebuffRemove(nId, nSpellId)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        -- Keep Old event for compatibility.
        Event_FireGenericEvent("DEBUFF_REMOVED", unitName, nSpellId, tUnit)
    end
    -- New event not based on the name.
    Event_FireGenericEvent("DEBUFF_DEL", nId, nSpellId)
end

function RaidCore:OnDebuffUpdate(nId, nSpellId, nOldStack, nNewStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    if tUnit then
        local unitName = tUnit:GetName():gsub(NO_BREAK_SPACE, " ")
        -- Keep Old event for compatibility.
        Event_FireGenericEvent("DEBUFF_APPLIED_DOSE", unitName, nSpellId, nNewStack)
    end
    -- New event not based on the name.
    Event_FireGenericEvent("DEBUFF_UPDATE", nId, nSpellId, nNewStack, fTimeRemaining)
end

function RaidCore:OnShowShortcutBar(tIconFloatingSpellBar)
    Event_FireGenericEvent("SHORTCUT_BAR", tIconFloatingSpellBar)
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

function RaidCore:ResetSync()
    self.syncTimer = {}
    self.syncRegister = {}
end

function RaidCore:ResetLines()
    self.drawline:ResetLines()
end

function RaidCore:TestPE()
    local tActiveEvents = PublicEvent.GetActiveEvents()
    local i = RaidCore:isPublicEventObjectiveActive("Talk to Captain Tero")
    self:Print("result ".. tostring(i))
    i = RaidCore:isPublicEventObjectiveActive("Talk to Captain Teroxx")
    self:Print("result ".. tostring(i))
    for idx, peEvent in pairs(tActiveEvents) do
        local test = peEvent:GetName()
        local truc
        self:Print(test)
        for idObjective, peObjective in pairs(peEvent:GetObjectives()) do
            test = peObjective:GetShortDescription()
            if test == "North Power Core Energy" then
                truc = peObjective:GetCount()
                self:Print(test)
                self:Print(truc)
            end
        end
    end
end

function RaidCore:OnSay(sMessage, sSender)
    Event_FireGenericEvent('CHAT_SAY', sMessage, sSender)
end

function RaidCore:OnNPCSay(sMessage, sSender)
    Event_FireGenericEvent('CHAT_NPCSAY', sMessage, sSender)
end

function RaidCore:OnNPCYell(sMessage, sSender)
    Event_FireGenericEvent('CHAT_NPCYELL', sMessage, sSender)
end

function RaidCore:OnNPCWisper(sMessage, sSender)
    Event_FireGenericEvent('CHAT_NPCWHISPER', sMessage, sSender)
end

function RaidCore:OnDatachron(sMessage, sSender)
    Event_FireGenericEvent('CHAT_DATACHRON', sMessage, sSender)
end

function RaidCore:OnParty(sMessage, sSender)
    Event_FireGenericEvent('CHAT_PARTY', sMessage, sSender)
end

function RaidCore:PrintBerserk()
    self:AddMsg("BERSERK", "BERSERK IN 1MIN", 5, false, MYCOLORS["Green"])
    self:AddTimerBar("BERSERK", "BERSERK", 60)
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
    self:BarsRemoveAll()
    self:ResetMarks()
    self:ResetWorldMarkers()
    self:ResetSync()
    self:ResetLines()
end

function RaidCore:WipeCheck()
    for i = 1, GroupLib.GetMemberCount() do
        local tUnit = GroupLib.GetUnitForGroupMember(i)
        if tUnit and tUnit:IsInCombat() then
            return
        end
    end
    _bIsEncounterInProgress = false
    if _tCurrentEncounter then
        Event_FireGenericEvent("RAID_WIPE")
        _tCurrentEncounter:Disable()
        _tCurrentEncounter = nil
    end
    self:CombatInterface_Activate("DetectCombat")
    self:ResetAll()
end

function RaidCore:OnUnitCreated(nId, tUnit, sName)
    Event_FireGenericEvent("RC_UnitCreated", tUnit, sName)
end

function RaidCore:OnEnteredCombat(nId, tUnit, sName, bInCombat)
    -- Manage the lower layer.
    if tUnit == GetPlayerUnit() then
        if bInCombat then
            -- Player entering in combat.
            _bIsEncounterInProgress = true
            self:CombatInterface_Activate("FullEnable")
            SearchEncounter()
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

function RaidCore:VersionCheckResults()
    local nMaxVersion = ADDON_DATE_VERSION
    for _, v in next, VCReply do
        if v > nMaxVersion then
            nMaxVersion = v
        end
    end

    local tNotInstalled = {}
    local tOutdated = {}
    local nMemberWithLasted = 0
    for i = 1, GroupLib.GetMemberCount() do
        local tMember = GroupLib.GetGroupMember(i)
        if tMember then
            local sPlayerName = tMember.strCharacterName
            local sPlayerVersion = VCReply[sPlayerName]
            if not sPlayerVersion then
                table.insert(tNotInstalled, sPlayerName)
            elseif sPlayerVersion < nMaxVersion then
                if tOutdated[sPlayerVersion] == nil then
                    tOutdated[sPlayerVersion] = {}
                end
                table.insert(tOutdated[sPlayerVersion], sPlayerName)
            else
                nMemberWithLasted = nMemberWithLasted + 1
            end
        end
    end

    if next(tNotInstalled) then
        self:Print(self.L["Not installed: %s"]:format(table.concat(tNotInstalled, ", ")))
    end
    if next(tOutdated) then
        self:Print("Outdated RaidCore Version:")
        for sPlayerVersion, tList in next, tOutdated do
            self:Print((" - '%s': %s"):format(sPlayerVersion, table.concat(tList, ", ")))
        end
    end
    self:Print(self.L["%d members are up to date."]:format(nMemberWithLasted))
    -- Send Msg to oudated players.
    local msg = {action = "NewestVersion", version = maxver}
    self:SendMessage(msg)
    self:ProcessMessage(msg)
    VCtimer = nil
end

function RaidCore:VersionCheck()
    if VCtimer then
        self:Print(self.L["VersionCheck already running ..."])
    elseif GroupLib.GetMemberCount() == 0 then
        self:Print(self.L["Command available only in group."])
    else
        self:Print(self.L["Checking version on group member."])
        VCReply[GetPlayerUnit():GetName()] = ADDON_DATE_VERSION
        local msg = {
            action = "VersionCheckRequest",
        }
        VCtimer = ApolloTimer.Create(5, false, "VersionCheckResults", self)
        self:SendMessage(msg)
    end
end

function RaidCore:LaunchPull(time)
    if time and time > 2 then
        local msg = {
            action = "LaunchPull",
            cooldown = time,
        }
        self:SendMessage(msg)
        self:ProcessMessage(msg)
    end
end

function RaidCore:LaunchBreak(time)
    local sPlayerName = GetPlayerUnit():GetName()
    if not self:isRaidManagement(sPlayerName) then
        self:Print("You must be a raid leader or assistant to use this command!")
    else
        if time and time > 5 then
            local msg = {
                action = "LaunchBreak",
                cooldown = time
            }
            self:SendMessage(msg)
            self:ProcessMessage(msg)
        end
    end
end

function RaidCore:SyncSummon()
    local myName = GetPlayerUnit():GetName()
    if not self:isRaidManagement(myName) then
        self:Print("You must be a raid leader or assistant to use this command!")
        return false
    end
    local msg = {
        action = "SyncSummon",
    }
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
    local msg = {
        action = "Sync",
        sync = syncName,
        parameter = param,
    }
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
-- When the Reset button is clicked
function RaidCore:OnResetBarPositions(wndHandler, wndControl, eMouseButton)
    self:BarsResetAnchors()
end

-- When the Move button is clicked
function RaidCore:OnMoveBars(wndHandler, wndControl, eMouseButton)
    if wndHandler:GetText() == "Move Bars" then
        wndHandler:SetText("Lock Bars")
        self:BarsAnchorUnlock(true)
    else
        wndHandler:SetText("Move Bars")
        self:BarsAnchorUnlock(false)
    end
end

function RaidCore:OnConfigOn()
    self.wndConfig:Invoke()
end

function RaidCore:OnConfigCloseButton()
    self.wndConfig:Close()
end

function RaidCore:OnMenuLeft_Check(wndHandler, wndControl, eMouseButton)
    OnMenuLeft_CheckUncheck(wndControl, true)
end

function RaidCore:OnMenuLeft_Uncheck(wndHandler, wndControl, eMouseButton)
    OnMenuLeft_CheckUncheck(wndControl, false)
end

function RaidCore:OnModuleSettingsCheck(wndHandler, wndControl, eMouseButton)
    local raidInstance = Split(wndControl:GetParent():GetName(), "_")
    local identifier = Split(wndControl:GetName(), "_")
    local wnd = self.wndSettings[raidInstance[2]][identifier[3]]
    wnd:Show(true)
    self.wndTargetFrame:SetData(wnd)
end

function RaidCore:OnModuleSettingsUncheck(wndHandler, wndControl, eMouseButton)
    OnMenuLeft_CheckUncheck(wndControl, false)
end
