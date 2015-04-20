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
local LogPackage = Apollo.GetPackage("Log-1.0").tPackage
local RaidCore = GeminiAddon:NewAddon("RaidCore", false, {}, "Gemini:Timer-1.0")

----------------------------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit

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
local enablezones, enablemobs, enablepairs, restrictzone, enablezone, restricteventobjective, enableeventobjective = {}, {}, {}, {}, {}, {}, {}
local monitoring = nil


local trackMaster = Apollo.GetAddon("TrackMaster")
local markCount = 0
local AddonVersion = 15031701
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
	Apollo.RegisterEventHandler("Group_MemberFlagsChanged", "OnGroup_MemberFlagsChanged", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnWorldChangedTimer", self)
	Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveUpdate", "OnPublicEventObjectiveUpdate", self)

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

	self.wipeTimer = false

	self.lines = {}

	self.chanCom = nil
	CommChannelTimer = ApolloTimer.Create(5, false, "UpdateCommChannel", self) -- make sure everything is loaded, so after 5sec

	-- Final parsing about encounters.
	for name, module in self:IterateModules() do
		local r, e = pcall(module.PrepareEncounter, module)
		if not r then
			Print(e)
		else
			for _, id in next, module.continentIdList do
				enablezones[id] = true
			end
		end
	end
	self:ScheduleTimer("OnWorldChanged", 5)
	self:LogGUI_init()
end

----------------------------------------------------------------------------------------------------
-- RaidCore Functions
----------------------------------------------------------------------------------------------------
function RaidCore:OnGroup_MemberFlagsChanged(nMemberIdx, bFromPromotion, tChangedFlags)
	if bFromPromotion then
		CommChannelTimer = ApolloTimer.Create(5, false, "UpdateCommChannel", self) -- after 5 sec for slow API leader update
	end
end

function RaidCore:UpdateCommChannel()
	if GroupLib.InGroup() then
		for i = 1, GroupLib.GetMemberCount() do
			local tPlayer = GroupLib.GetGroupMember(i)
			if tPlayer and tPlayer.bIsLeader then
				local channel = "RaidCore_" .. tPlayer.strCharacterName
				self.chanCom = ICCommLib.JoinChannel(channel, "OnComMessage", self)
				if self.chanCom then return true else return false end
			end
		end
	end
	return false
end

function RaidCore:SendMessage(msg)
	if not self.chanCom and not self:UpdateCommChannel() then
		Print("[RaidCore] Error sending Sync Message. Are you sure that you're in a party?")
		return false
	else
		self.chanCom:SendMessage(msg)
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
			self.buffs[unit:GetId()] = {}
			self.buffs[unit:GetId()].unit = unit
			self.buffs[unit:GetId()].aura = {}
			self:StartScan()
		end
	elseif (tAllParams[1] == "debuff") then
		local unit = GameLib.GetTargetUnit()
		if unit ~= nil then
			self.debuffs[unit:GetId()] = {}
			self.debuffs[unit:GetId()].unit = unit
			self.debuffs[unit:GetId()].aura = {}
			self:StartScan()
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
		self:SetWorldMarker(estpos, "EST")
		local sudpos = {
			x = 165.79222106934,
			y = -110.80034637451,
			z = -464.8489074707
		}
		self:SetWorldMarker(sudpos, "SUD")
		local ouestpos = {
			x = 144.20,
			y = -110.80034637451,
			z = -494.38
		}
		self:SetWorldMarker(ouestpos, "WEST")
		local nordpos = {
			x = 175.00,
			y = -110.80034637451,
			z = -513.31
		}
		self:SetWorldMarker(nordpos, "NORD")
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

function RaidCore:OnUnitCreated(nId, unit, sName)
	Event_FireGenericEvent("RC_UnitCreated", unit, sName)
	if unit and not unit:IsDead() then
		if sName and enablemobs[sName] then
			if type(enablemobs[sName]) == "string" then
				local modName = enablemobs[sName]
				local module = self:GetModule(modName)
				if not module or module:IsEnabled() then return end
				if restrictzone[modName] and not restrictzone[modName][GetCurrentSubZoneName()] then return end
				if restricteventobjective[modName] and not self:hasActiveEvent(restricteventobjective[modName]) then return end
				Print("Enabling Boss Module : " .. enablemobs[sName])
				for name, mod in self:IterateModules() do
					if mod:IsEnabled() then mod:Disable() end
				end
				module:Enable()
			else
				for i, modName in next, enablemobs[sName] do
					local module = self:GetModule(modName)
					if not module or module:IsEnabled() then return end
				end
				for name, mod in self:IterateModules() do
					if mod:IsEnabled() then mod:Disable() end
				end
				for i, modName in next, enablemobs[sName] do
					local module = self:GetModule(modName)
					if restrictzone[modName] and not restrictzone[modName][GetCurrentSubZoneName()] then return end
					if restricteventobjective[modName] and not self:hasActiveEvent(restricteventobjective[modName]) then return end
					Print("Enabling Boss Module : " .. modName)
					module:Enable()
				end
			end
		else
			-- Check if part of a boss combination pair
			for modName, bosses in pairs(enablepairs) do
				for bossName, activeState in pairs(bosses) do
					if sName == bossName then
						-- Set this boss to true if it is active
						enablepairs[modName][bossName] = true
					end
				end
			end
			-- Loop again to check if there's any boss pair that has
			-- all bosses that are required for it to activate active
			for modName, bosses in pairs(enablepairs) do
				local bModNameBossActive = true
				for bossName, activeState in pairs(bosses) do
					if bModNameBossActive and not activeState then
						bModNameBossActive = false
					end
				end

				-- At this point we know this boss pair should be enabled.
				if bModNameBossActive then
					-- Disable any other modules that are active
					for name, mod in self:IterateModules() do
						if name ~= modName and mod:IsEnabled() then
							mod:Disable()
						end
					end
					mod = self:GetModule(modName)
					if restrictzone[modName] and not restrictzone[modName][GetCurrentSubZoneName()] then return end
					if mod:IsEnabled() then return end
					Print("Enabling Boss Module : " .. modName)
					mod:Enable()
					return
				end
			end
		end
	end
end


function RaidCore:StartCombat(modName)
	Print("Starting Core Combat")
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() and mod.ModuleName ~= modName then
			mod:Disable()
		end
	end
end

function RaidCore:OnWorldChangedTimer()
	self:ScheduleTimer("OnWorldChanged", 5)
end


function RaidCore:OnWorldChanged()
	local zoneMap = GameLib.GetCurrentZoneMap()

	if zoneMap then
		if enablezones[zoneMap.continentId] then
			self:CombatInterface_Activate("DetectAll")
			monitoring = true
			if self.timer == nil then
				self.timer = ApolloTimer.Create(0.100, true, "OnTimer", self)
			else
				self.timer:Start()
			end
		else
			self:CombatInterface_Activate("Disable")
			if monitoring then
				monitoring = nil
				self:ResetAll()
				self.timer:Stop()
			end
		end
	else
		self:ScheduleTimer("OnWorldChanged", 5)
	end
end

function RaidCore:OnSubZoneChanged(idZone, strSubZone)
	for key, value in pairs(enablezone) do
		if value[strSubZone] then
			local modName = key
			local bossMod = self:GetModule(modName)
			if not bossMod or bossMod:IsEnabled() then return end
			if restricteventobjective[modName] and not self:hasActiveEvent(restricteventobjective[modName]) then return end
			Print("Enabling Boss Module : " .. modName)
			bossMod:Enable()
			return
		end
	end
	-- if we haven't returned at this point we left the subzone and should disable the mod
	-- if it is still enabled
	for name, mod in self:IterateModules() do
		for key, value in pairs(enablezone) do
			local modName = mod.ModuleName
			if key == modName and mod:IsEnabled() then
				mod:Disable()
			end
		end
	end
end

function RaidCore:OnPublicEventObjectiveUpdate(peoUpdated)
	for key, value in pairs(enableeventobjective) do
		if value[peoUpdated:GetShortDescription()] then
			if peoUpdated:GetStatus() == 1 then
				local modName = key
				local bossMod = self:GetModule(modName)
				if not bossMod or bossMod:IsEnabled() then return end
				if restrictzone[modName] and not restrictzone[modName][GetCurrentSubZoneName()] then return end
				Print("Enabling Boss Module : " .. modName)
				bossMod:Enable()
				return
			elseif peoUpdated:GetStatus() == 0 then
				local modName = key
				local bossMod = self:GetModule(modName)
				if not bossMod or not bossMod:IsEnabled() then return end
				bossMod:Disable()
			end
		end
	end
end

do
	local function add(moduleName, tbl, list)
		for i, entry in next, list do
			local t = type(tbl[entry])
			if t == "nil" then
				tbl[entry] = moduleName
			elseif t == "table" then
				tbl[entry][#tbl[entry] + 1] = moduleName
			elseif t == "string" then
				local tmp = tbl[entry]
				tbl[entry] = { tmp, moduleName }
			else
				Print(("Unknown type in a enable trigger table at index %d for %q."):format(i, tostring(moduleName)))
			end
		end
	end

	local function addPair(moduleName, tbl, list)
		-- ... is holding our actual bosses that we want to have in a pair
		-- we will store them in the tbl (enablepairs)
		local bosses = {}
		for key, value in next, list do
			-- Defaults to false meaning the unit is not active/in-range
			bosses[value] = false
		end
		tbl[moduleName] = bosses
	end

	function RaidCore:RegisterEnableMob(module, list) add(module.ModuleName, enablemobs, list) end
	function RaidCore:RegisterEnableBossPair(module, list) addPair(module.ModuleName, enablepairs, list) end
	function RaidCore:GetEnableMobs() return enablemobs end
	function RaidCore:GetEnablePairs() return enablepairs end
	function RaidCore:GetRestrictZone() return restrictzone end
	function RaidCore:GetRestrictEventObjective() return restricteventobjective end
	function RaidCore:GetEnableEventObjective() return enableeventobjective end
	function RaidCore:GetEnableZone() return enablezone end
end


do
	local function add2(moduleName, tbl, list)
		if not tbl[moduleName] then tbl[moduleName] = {} end
		for i, entry in next, list do
			if not tbl[moduleName][entry] then tbl[moduleName][entry] = true end
		end
	end

	function RaidCore:RegisterRestrictZone(module, list) add2(module.ModuleName, restrictzone, list) end
	function RaidCore:RegisterEnableZone(module, list) add2(module.ModuleName, enablezone, list) end
	function RaidCore:RegisterRestrictEventObjective(module, list) add2(module.ModuleName, restricteventobjective, list) end
	function RaidCore:RegisterEnableEventObjective(module, list) add2(module.ModuleName, enableeventobjective, list) end
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
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnUpdate", self)
end

function RaidCore:StopScan()
	Apollo.RemoveEventHandler("VarChange_FrameCount", self)
end

function RaidCore:WatchUnit(unit)
	if unit and not unit:IsDead() and not self.watch[unit:GetId()] then
		self.watch[unit:GetId()] = {}
		self.watch[unit:GetId()]["unit"] = unit
	end
end

function RaidCore:UnitBuff(unit)
	if unit and not unit:IsDead() and not self.buffs[unit:GetId()] then
		self.buffs[unit:GetId()] = {}
		self.buffs[unit:GetId()].unit = unit
		self.buffs[unit:GetId()].aura = {}
	end
end

function RaidCore:UnitDebuff(unit)
	if unit and not unit:IsDead() and not self.debuffs[unit:GetId()] then
		self.debuffs[unit:GetId()] = {}
		self.debuffs[unit:GetId()].unit = unit
		self.debuffs[unit:GetId()].aura = {}
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
			markFrame:Show(true)

			self.mark[key].frame = markFrame
		elseif mark then
			self.mark[key].number = mark
			self.mark[key].frame:FindChild("Name"):SetText(self.mark[key].number)
		end
		self:SetMarkToUnit(unit, mark)
	end
end

function RaidCore:SetWorldMarker(position, mark)
	if position then
		self.worldmarker[mark] = {}

		local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
		markFrame:SetWorldLocation(position)
		markFrame:FindChild("Name"):SetText(mark)
		markFrame:Show(true)

		self.worldmarker[mark] = markFrame
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

	-- Unload boss module if all units are destroyed within a module
	for modName, bosses in pairs(enablepairs) do
		for bossName, activeState in pairs(bosses) do
			if activeState and bossName == unitName then
				enablepairs[modName][bossName] = false
			end
		end
	end
	for modName, bosses in pairs(enablepairs) do
		local bModNameBossActive = false
		for bossName, activeState in pairs(bosses) do
			if not bModNameBossActive and activeState then
				bModNameBossActive = true
			end
		end
		if not bModNameBossActive then
			-- Disable any other modules that are active
			for name, mod in self:IterateModules() do
				if name == modName and mod:IsEnabled() then
					mod:Disable()
				end
			end
		end
	end
end

function RaidCore:SetTarget(position)
	if trackMaster ~= nil then
		trackMaster:SetTarget(position)
	end
end

function RaidCore:OnUpdate()
	local unit
	for k, v in pairs(self.watch) do
		unit = v.unit
		if not unit:IsDead() then
			if unit:GetType() and unit:GetType() == "NonPlayer" then -- XXX only track non player casts
				if unit:ShouldShowCastBar() then
					if not self.watch[k].tracked then
						self.watch[k].tracked = unit:GetCastName()
						local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
						Event_FireGenericEvent("SPELL_CAST_START", unitName, self.watch[k].tracked, unit)
					end
				elseif self.watch[k].tracked then
					local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
					Event_FireGenericEvent("SPELL_CAST_END", unitName, self.watch[k].tracked, unit)
					self.watch[k].tracked = nil
				end
			end
		end
	end

	for k, v in pairs(self.buffs) do
		unit = v.unit
		if not unit:IsDead() then
			local unitBuffs = unit:GetBuffs().arBeneficial
			local tempbuff = {}
			local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
			for _, s in pairs(unitBuffs) do
				tempbuff[s.idBuff] = true
				if v.aura[s.idBuff] then -- refresh
					if s.nCount ~= v.aura[s.idBuff].nCount then -- this for when an aura has no duration but has stacks
						Event_FireGenericEvent("BUFF_APPLIED_DOSE", unitName, s.splEffect:GetId(), s.nCount)
					elseif s.fTimeRemaining > v.aura[s.idBuff].fTimeRemaining then
						Event_FireGenericEvent("BUFF_APPLIED_RENEW", unitName, s.splEffect:GetId(), s.nCount)
					end
					v.aura[s.idBuff] = {
						["nCount"] = s.nCount,
						["fTimeRemaining"] = s.fTimeRemaining,
						["splEffect"] = s.splEffect,
					}
				else -- first application
					v.aura[s.idBuff] = {
						["nCount"] = s.nCount,
						["fTimeRemaining"] = s.fTimeRemaining,
						["splEffect"] = s.splEffect,
					}
					Event_FireGenericEvent("BUFF_APPLIED", unitName, s.splEffect:GetId(), unit)
				end
			end
			for buffId, buffData in pairs(v.aura) do
				if not tempbuff[buffId] then
					Event_FireGenericEvent("BUFF_REMOVED", unitName, buffData.splEffect:GetId(), unit)
					v.aura[buffId] = nil
				end
			end
		end
	end

	for k, v in pairs(self.debuffs) do
		unit = v.unit
		if not unit:IsDead() then
			local unitName = unit:GetName():gsub(NO_BREAK_SPACE, " ")
			local truc
			if (unit:GetBuffs()) then
				local unitDebuffs = unit:GetBuffs().arHarmful
				local tempdebuff = {}
				for _, s in pairs(unitDebuffs) do
					tempdebuff[s.idBuff] = true
					if v.aura[s.idBuff] then -- refresh
						if s.nCount ~= v.aura[s.idBuff].nCount then -- this for when an aura has no duration but has stacks
							Event_FireGenericEvent("DEBUFF_APPLIED_DOSE", unitName, s.splEffect:GetId(), s.nCount)
						elseif s.fTimeRemaining > v.aura[s.idBuff].fTimeRemaining then
							Event_FireGenericEvent("DEBUFF_APPLIED_RENEW", unitName, s.splEffect:GetId(), s.nCount)
						end
						v.aura[s.idBuff] = {
							["nCount"] = s.nCount,
							["fTimeRemaining"] = s.fTimeRemaining,
							["splEffect"] = s.splEffect,
						}
					else -- first application
						v.aura[s.idBuff] = {
							["nCount"] = s.nCount,
							["fTimeRemaining"] = s.fTimeRemaining,
							["splEffect"] = s.splEffect,
						}
						Event_FireGenericEvent("DEBUFF_APPLIED", unitName, s.splEffect:GetId(), unit)
					end
				end
				for buffId, buffData in pairs(v.aura) do
					if not tempdebuff[buffId] then
						Event_FireGenericEvent("DEBUFF_REMOVED", unitName, buffData.splEffect:GetId(), unit)
						v.aura[buffId] = nil
					end
				end
			end
		end
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

function RaidCore:ResetWorldMarkers()
	for k, over in pairs(self.worldmarker) do
		over:Destroy()
		self.worldmarker[k] = nil
	end
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
	if self.wipeTimer then
		self.wipeTimer:Stop()
		self.wipeTimer = nil
	end
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
	self:StopScan()
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
	self.wipeTimer:Stop()
	self.wipeTimer = nil
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
	self:StopScan()
	self:ResetMarks()
	self:ResetWorldMarkers()
	self:ResetEmphasize()
	self:ResetDelayedMsg()
	self:ResetSync()
	self:ResetLines()

	-- XXX Zone not Checked!
	self:CombatInterface_Activate("DetectAll")
	Event_FireGenericEvent("RAID_WIPE")
end

function RaidCore:OnEnteredCombat(id, unit, UnitName, bInCombat)
	Event_FireGenericEvent("RC_UnitStateChanged", unit, bInCombat, UnitName)

	if unit == GetPlayerUnit() then
		if bInCombat then
			-- Player entering in combat.
			self:CombatInterface_Activate("FullEnable")
		else
			-- Player is dead or left the combat.
			self.wipeTimer = ApolloTimer.Create(0.5, true, "WipeCheck", self)
		end
	elseif unit:IsInYourGroup() then
		-- It's a raid member or group member.
	else
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

function RaidCore:OnComMessage(channel, tMessage, strSender)
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
		if not self:isRaidManagement(strSender) then
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
	self:OnComMessage(nil, msg)
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
		self:OnComMessage(nil, msg)
	end
end

function RaidCore:LaunchBreak(time)
	if time and time > 5 then
		local msg = {action = "LaunchBreak", sender = GameLib.GetPlayerUnit():GetName(), cooldown = time}
		self:SendMessage(msg)
		self:OnComMessage(nil, msg)
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

