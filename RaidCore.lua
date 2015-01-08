-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ChatSystemLib"

-----------------------------------------------------------------------------------------------
-- RaidCore Module Definition
-----------------------------------------------------------------------------------------------
--local RaidCore = {} 
local RaidCore = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("RaidCore", false, {}, "Gemini:Timer-1.0")
local addon = RaidCore

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local enablezones, enablemobs, restrictzone = {}, {}, {}
local monitoring = nil


local trackMaster = Apollo.GetAddon("TrackMaster")
local markCount = 0
local AddonVersion = 15010801
local VCReply, VCtimer = {}, nil
local empCD, empTimer = 5, nil

local chatEvent = {
		[ChatSystemLib.ChatChannel_Datachron] 	= 'CHAT_DATACHRON',
		[ChatSystemLib.ChatChannel_Say] 		= 'CHAT_SAY',
		[ChatSystemLib.ChatChannel_NPCSay] 		= 'CHAT_NPCSAY',
		[ChatSystemLib.ChatChannel_NPCYell] 	= 'CHAT_NPCYELL',
		[ChatSystemLib.ChatChannel_NPCWhisper] 	= 'CHAT_NPCWHISPER',
}
 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function RaidCore:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function RaidCore:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- RaidCore OnLoad
-----------------------------------------------------------------------------------------------
--function RaidCore:OnLoad()
function RaidCore:OnInitialize()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("RaidCore.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- RaidCore OnDocLoaded
-----------------------------------------------------------------------------------------------
--function RaidCore:OnDocLoaded()
function RaidCore:OnEnable()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "RaidCoreForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
	    Apollo.LoadSprites("BarTextures.xml")

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

	    if self.saveData ~= nil then
	    	self:LoadSaveData(self.saveData)
	    end

	    self.colorPicker = RaidCoreLibs.ColorPicker.new(self.xmlDoc)
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("raidc", "OnRaidCoreOn", self)

		--self.timer = ApolloTimer.Create(0.100, true, "OnTimer", self)
		--self.timer:Stop()

		Apollo.RegisterEventHandler("ChangeWorld", 		"OnWorldChangedTimer", self)

		-- Do additional Addon initialization here

		self:InitializeConfigForm()

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

		--self.uMyGuild = GameLib.GetPlayerUnit():GetGuildName()
		self.chanCom = ICCommLib.JoinChannel("WL_RaidCore", "OnComMessage", self)

		self:ScheduleTimer("OnWorldChanged", 5)

		self.Loaded = true
	end
end

-----------------------------------------------------------------------------------------------
-- RaidCore Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function RaidCore:InitializeConfigForm()
	local groupOptionsList = self.wndMain:FindChild("GroupOptionsList")
	groupOptionsList:DestroyChildren()

	local raidbarsOpt = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	raidbarsOpt:SetData(self.raidbars)
	raidbarsOpt:FindChild("OptionsLabel"):SetText("Raid Bars")
	self:InitializeGroup(raidbarsOpt, self.raidbars)

	local unitmoniOpt = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	unitmoniOpt:SetData(self.unitmoni)
	unitmoniOpt:FindChild("OptionsLabel"):SetText("Unit Bars")
	self:InitializeGroup(unitmoniOpt, self.unitmoni)

	local unitmoniOpt = Apollo.LoadForm(self.xmlDoc, "SubForms.GroupOptions", groupOptionsList, self)
	unitmoniOpt:SetData(self.message)
	unitmoniOpt:FindChild("OptionsLabel"):SetText("Message Bars")
	self:InitializeGroup(unitmoniOpt, self.message)

	groupOptionsList:ArrangeChildrenVert()
end

function RaidCore:InitializeGroup(groupFrame, group)
	groupFrame:FindChild("Enabled"):SetCheck(group:IsEnabled())
	groupFrame:FindChild("BackgroundColor"):FindChild("Text"):SetTextColor(group.bgColor)
	groupFrame:FindChild("BarColor"):FindChild("Text"):SetTextColor(group.barColor)
	groupFrame:FindChild("StartFromTop"):SetCheck(group.anchorFromTop)
	groupFrame:FindChild("BarWidth"):SetValue(group.barSize.Width)
	groupFrame:FindChild("BarWidthValue"):SetText(string.format("%.f", group.barSize.Width))
	groupFrame:FindChild("BarHeight"):SetValue(group.barSize.Height)
	groupFrame:FindChild("BarHeightValue"):SetText(string.format("%.f", group.barSize.Height))
end

function RaidCore:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
	local saveData = { 
		raidbars = self.raidbars:GetSaveData(),
		unitmoni = self.unitmoni:GetSaveData(),
		message = self.message:GetSaveData()
	}
	
	return saveData
end

function RaidCore:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end

	if self.Loaded then
		self:LoadSaveData(tData)
		self:InitializeConfigForm()	
	else
		self.saveData = tData
	end
end

function RaidCore:LoadSaveData(tData)
	if tData.raidbars then
		self.raidbars:Load(tData.raidbars)
	end

	if tData.unitmoni then
		self.unitmoni:Load(tData.unitmoni)
	end

	if tData.message then
		self.message:Load(tData.message)
	end
end

function RaidCore:OnBarEnabledChanged( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	group:SetEnabled(wndHandler:IsChecked())
end

function RaidCore:OnBarStartFromTopChanged( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	group:AnchorFromTop(wndHandler:IsChecked())
end

function RaidCore:OnBarWidthChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local group = wndHandler:GetParent():GetData()
	group:SetBarWidth(fNewValue)
	wndHandler:GetParent():FindChild("BarWidthValue"):SetText(string.format("%.f", fNewValue))
end

function RaidCore:OnBarWidthValueChanged( wndHandler, wndControl, strText )
	local group = wndHandler:GetParent():GetData()
	local value = tonumber(strText)
	wndHandler:SetText(tostring(value))
	wndHandler:GetParent():FindChild("BarWidth"):SetValue(value)
	group:SetBarWidth(value)
end

function RaidCore:OnBarHeightChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local group = wndHandler:GetParent():GetData()
	group:SetBarHeight(fNewValue)
	wndHandler:GetParent():FindChild("BarHeightValue"):SetText(string.format("%.f", fNewValue))
end

function RaidCore:OnBarHeightValueChanged( wndHandler, wndControl, strText )
	local group = wndHandler:GetParent():GetData()
	local value = tonumber(strText)
	wndHandler:SetText(tostring(value))
	wndHandler:GetParent():FindChild("BarHeight"):SetValue(value)
	group:SetBarHeight(value)
end

function RaidCore:EditBarBGColor( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	local color = group.bgColor
	self.colorPicker:OpenColorPicker(color, function()
		wndHandler:FindChild("Text"):SetTextColor(color)
		group:SetBGColor(color)
	end)
end

function RaidCore:EditBarColor( wndHandler, wndControl, eMouseButton )
	local group = wndHandler:GetParent():GetData()
	local color = group.barColor
	self.colorPicker:OpenColorPicker(color, function()
		wndHandler:FindChild("Text"):SetTextColor(color)
		group:SetBarColor(color)
	end)
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

	if (tAllParams[1] == "bar") then
		if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
			self:AddBar(tAllParams[2], tAllParams[2], tAllParams[3])
		else
			self:AddBar("truc", "OVERDRIVE", 10, true)
			self:AddMsg("mtruc2", "OVERDRIVE", 5, "Alarm", "Blue")
			--self:AddDelayedMsg("mtruc2",10, "OVERDRIVE", 5, "Alarm", "Blue")
		end
	elseif (tAllParams[1] == "unit") then
		local unit = GameLib.GetTargetUnit()
		if unit ~= nil then
			--self.unitmoni:AddUnit(unit)
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
	elseif (tAllParams[1] == "buff") then
		local unit = GameLib.GetTargetUnit()
		if unit ~= nil then
			--self.unitmoni:AddUnit(unit)
			self.buffs[unit:GetId()] = {}
			self.buffs[unit:GetId()].unit = unit
			self.buffs[unit:GetId()].aura = {}
			self:StartScan()
		end
	elseif (tAllParams[1] == "debuff") then
		local unit = GameLib.GetTargetUnit()
		if unit ~= nil then
			--self.unitmoni:AddUnit(unit)
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
			local mod = self:GetBossModule("SystemDeamons", 1)
			if mod then
				mod:SetInterrupter(tAllParams[2], tonumber(tAllParams[3]))
			else
				Print("Module SystemDeamons not loaded")
			end
		end
	elseif (tAllParams[1] == "sysdm") then
		if tAllParams[2] ~= nil and tAllParams[3] ~= nil then
			local mod = self:GetBossModule("SystemDeamons", 1)
			if mod then
				mod:SetInterrupter(tAllParams[2], tonumber(tAllParams[3]))
			else
				Print("Module SystemDeamons not loaded")
			end
		end
	elseif (tAllParams[1] == "testdm") then
		local mod = self:GetBossModule("SystemDeamons", 1)
		if mod then
			mod:NextWave()
		else
			Print("Module SystemDeamons not loaded")
		end
	elseif (tAllParams[1] == "testel") then
		local mod = self:GetBossModule("EpEarthLogic", 1)
		if mod then
			mod:PlaceSpawnPos()
		else
			Print("Module EpEarthLogic not loaded")
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
		self:InitializeConfigForm()
		self.wndMain:Invoke() -- show the window
	end
end

-- on timer
function RaidCore:OnTimer()
	self.raidbars:RefreshBars()
	self.unitmoni:RefreshUnits()
	self.message:RefreshMsg()
end

function RaidCore:unitCheck(unit)
	if unit and not unit:IsDead() then
		local sName = unit:GetName()
		--Print("Checking " .. sName)
		if sName and enablemobs[sName] then
			if type(enablemobs[sName]) == "string" then
				local modName = enablemobs[sName]
				local module = self.bossCore:GetModule(modName)
				if not module or module:IsEnabled() then return end
				if restrictzone[modName] and not restrictzone[modName][GetCurrentSubZoneName()] then return end
				Print("Enabling Boss Module : " .. enablemobs[sName])
				for name, mod in self:IterateBossModules() do
					if mod:IsEnabled() then mod:Disable() end
				end
				module:Enable()
			else
				for i, modName in next, enablemobs[sName] do
					local module = self.bossCore:GetModule(modName)
					if not module or module:IsEnabled() then return end
				end
				for name, mod in self:IterateBossModules() do
					if mod:IsEnabled() then mod:Disable() end
				end
				for i, modName in next, enablemobs[sName] do
					local module = self.bossCore:GetModule(modName)
					if restrictzone[modName] and not restrictzone[modName][GetCurrentSubZoneName()] then return end
					Print("Enabling Boss Module : " .. modName)
					module:Enable()
				end
			end
		end
	end
end


function RaidCore:StartCombat(modName)
	Print("Starting Core Combat")
	for name, mod in self:IterateBossModules() do
		if mod:IsEnabled() and mod.ModuleName ~= modName then 
			mod:Disable() 
		end
	end
	Apollo.RemoveEventHandler("UnitCreated",	 	self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 		"CombatStateChanged", self)
	Apollo.RegisterEventHandler("ChatMessage", 			"OnChatMessage", self)
end

function RaidCore:OnWorldChangedTimer()
	self:ScheduleTimer("OnWorldChanged", 5)
end


function RaidCore:OnWorldChanged()
	--if not IsInInstance() then
	--	for _, module in addon:IterateBossModules() do
	--		if module.isEngaged then module:Reboot(true) end
	--	end
	--end
	--Print("TESTING ZONES")
	local zoneMap = GameLib.GetCurrentZoneMap()
	if zoneMap and zoneMap.continentId then
		if enablezones[zoneMap.continentId] then
			if not monitoring then
				monitoring = true
				--Print("MONITORING ON")
				Apollo.RegisterEventHandler("UnitCreated", 			"unitCheck", self)
				--Apollo.RegisterEventHandler("ChatMessage", 			"OnChatMessage", self)
				--Apollo.RegisterEventHandler("UnitEnteredCombat", 		"CombatStateChanged", self)
				if not self.timer then 
					self.timer = ApolloTimer.Create(0.100, true, "OnTimer", self)
				else
					self.timer:Start()
				end
			end
		elseif monitoring then
			monitoring = nil
			--Print("MONITORING OFF")
			Apollo.RemoveEventHandler("UnitCreated",	 	self)
			Apollo.RemoveEventHandler("ChatMessage",	 	self)
			Apollo.RemoveEventHandler("UnitEnteredCombat",	self)
			self:ResetAll()
			self.timer:Stop()
		end
	end
end


do
	local function add(moduleName, tbl, ...)
		for i = 1, select("#", ...) do
			local entry = select(i, ...)
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
	function RaidCore:RegisterEnableMob(module, ...) add(module.ModuleName, enablemobs, ...) end
	function RaidCore:GetEnableMobs() return enablemobs end
	function RaidCore:RegisterRestrictZone(module, zone) add(zone, restrictzone, module.ModuleName) end
end


do
	local function add2(moduleName, tbl, ...)
		if not tbl[moduleName] then tbl[moduleName] = {} end
		for i = 1, select("#", ...) do
			local entry = select(i, ...)
			if not tbl[moduleName][entry] then tbl[moduleName][entry] = true end
		end
	end

	function RaidCore:RegisterRestrictZone(module, ...) add2(module.ModuleName, restrictzone, ...) end
end
	

do
	local function new(core, module, zoneId, ...)
		if core:GetModule(module, true) then
			Print(("ERR : %s already loaded"):format(module))
		else
			local m = core:NewModule(module, ...)

			m.zoneId = zoneId
			return m
		end
	end

	-- A wrapper for :NewModule to present users with more information in the
	-- case where a module with the same name has already been registered.
	function RaidCore:NewBoss(module, zoneId, ...)
		return new(self.bossCore, module, zoneId, ...)
	end

	function RaidCore:IterateBossModules() return self.bossCore:IterateModules() end
	function RaidCore:GetBossModule(...) return self.bossCore:GetModule(...) end


	function RaidCore:RegisterBossModule(module)
		if not module.displayName then module.displayName = module.ModuleName end

		--module.SetupOptions = moduleOptions

		if not enablezones[module.zoneId] then
			enablezones[module.zoneId] = true
			self:OnWorldChanged()
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
	self:AddMsg("EMP"..key, num, 0.9, num, "Green")
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
	if delay > 1 then
		self.emphasize[key][1] = self:ScheduleTimer("PrintEmphasize", delay - 1, key, 1)
		if delay > 2 then
			self.emphasize[key][2] = self:ScheduleTimer("PrintEmphasize", delay - 2, key, 2)
			if delay > 3 then
				self.emphasize[key][3] = self:ScheduleTimer("PrintEmphasize", delay - 3, key, 3)
				if delay > 4 then
					self.emphasize[key][4] = self:ScheduleTimer("PrintEmphasize", delay - 4, key, 4)
					if delay > 5 then
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
	Apollo.RegisterEventHandler("VarChange_FrameCount",	 					"OnUpdate", self)
end

function RaidCore:StopScan()
	Apollo.RemoveEventHandler("VarChange_FrameCount", self)
end

function RaidCore:WatchUnit(unit)
	if unit and not unit:IsDead() and not self.watch[unit:GetId()] then
		self.watch[unit:GetId()] = {}
		self.watch[unit:GetId()]["unit"] = unit

		Apollo.RegisterEventHandler("UnitDestroyed", 					"OnUnitDestroyed", self)
	end
end

function RaidCore:UnitBuff(unit)
	if unit and not unit:IsDead() and not self.buffs[unit:GetId()] then
		self.buffs[unit:GetId()] = {}
		self.buffs[unit:GetId()].unit = unit
		self.buffs[unit:GetId()].aura = {}

		Apollo.RegisterEventHandler("UnitDestroyed", 					"OnUnitDestroyed", self)
	end
end

function RaidCore:UnitDebuff(unit)
	if unit and not unit:IsDead() and not self.debuffs[unit:GetId()] then
		self.debuffs[unit:GetId()] = {}
		self.debuffs[unit:GetId()].unit = unit
		self.debuffs[unit:GetId()].aura = {}

		Apollo.RegisterEventHandler("UnitDestroyed", 					"OnUnitDestroyed", self)
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
		if  not self.mark[key] then
			self.mark[key] = {}
			self.mark[key]["unit"] = unit
			if not mark then 
				markCount = markCount + 1
				self.mark[key].number = markCount
			else
				self.mark[key].number = mark
			end

			local markFrame = Apollo.LoadForm(self.xmlDoc, "MarkFrame", "InWorldHudStratum", self)
			--markFrame:SetWorldLocation(unit:GetPosition())
			markFrame:SetUnit(unit, location)
			markFrame:FindChild("Name"):SetText(self.mark[key].number)
			markFrame:Show(true)

			self.mark[key].frame = markFrame


			Apollo.RegisterEventHandler("UnitDestroyed", 					"OnUnitDestroyed", self)
			--Apollo.RegisterEventHandler("NextFrame",	 					"OnMarkUpdate", self)
			--Apollo.RegisterEventHandler("VarChange_FrameCount",	 					"OnUpdate", self) 
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
--self.drawline:AddLine("Ohmna1", 2, unit, 3, 25, 0)

function RaidCore:AddPixie(... )
	self.drawline:AddPixie(...)
end

function RaidCore:DropPixie(key)
	self.drawline:DropPixie(key)
end

function RaidCore:DropLine(key)
	self.drawline:DropLine(key)
end

function RaidCore:OnUnitDestroyed(unit)
	--Print("Removing 1".. unit:GetName())
	local key = unit:GetId()
	if self.watch[key] then
		self.watch[key] = nil
		--[[
		if #self.watch == 0 and #self.mark == 0 then
			Apollo.RemoveEventHandler("UnitDestroyed", self)
		end
		]]--
	end
	if self.mark[key] then
		local markFrame = self.mark[key].frame
		markFrame:SetUnit(nil)
		markFrame:Destroy()
		self.mark[key] = nil
		--[[
		Print("Removing ".. unit:GetName())
		if #self.watch == 0 and #self.mark == 0 then
			Apollo.RemoveEventHandler("UnitDestroyed", self)
		end
		]]--
	end
	if self.debuffs[key] and unit:IsDead() then
		self.debuffs[key] = nil
		--Print("Removing " .. unit:GetName() .. " from debuff")
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

function RaidCore:OnUpdate()
	local unit
	for k, v in pairs(self.watch) do
		unit = v.unit
		if not unit:IsDead() then
			if unit:GetType() and unit:GetType() == "NonPlayer" then -- XXX only track non player casts
				if unit:ShouldShowCastBar() then
					if not self.watch[k].tracked then
						self.watch[k].tracked = unit:GetCastName()
						Event_FireGenericEvent("SPELL_CAST_START", unit:GetName(), self.watch[k].tracked, unit)
						--Print("SPELL_CAST_START : " .. unit:GetName() .. " " .. self.watch[k].tracked)
					end
				elseif self.watch[k].tracked then
					Event_FireGenericEvent("SPELL_CAST_END", unit:GetName(), self.watch[k].tracked, unit)
					--Print("SPELL_CAST_END : " .. unit:GetName() .. " " .. self.watch[k].tracked)
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
			for _, s in pairs(unitBuffs) do
				tempbuff[s.idBuff] = true
				if v.aura[s.idBuff] then -- refresh
					if s.nCount ~= v.aura[s.idBuff].nCount then -- this for when an aura has no duration but has stacks
						Event_FireGenericEvent("BUFF_APPLIED_DOSE", unit:GetName(), s.splEffect:GetId(), s.nCount)
					elseif s.fTimeRemaining > v.aura[s.idBuff].fTimeRemaining then
						Event_FireGenericEvent("BUFF_APPLIED_RENEW", unit:GetName(), s.splEffect:GetId(), s.nCount)
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
						Event_FireGenericEvent("BUFF_APPLIED", unit:GetName(), s.splEffect:GetId(), unit)
						--Print("BUFF_APPLIED : " .. unit:GetName() .. " " .. s.splEffect:GetId())
				end
			end
			for buffId, buffData in pairs(v.aura) do
				if not tempbuff[buffId] then
					Event_FireGenericEvent("BUFF_REMOVED", unit:GetName(), buffData.splEffect:GetId(), unit)
					--Print("BUFF_REMOVED : " .. unit:GetName() .. " " .. buffData.splEffect:GetId())
					v.aura[buffId] = nil
				end
			end
		end
	end	

	for k, v in pairs(self.debuffs) do
		unit = v.unit
		if not unit:IsDead() then
			local truc
			if (unit:GetBuffs()) then
				local unitDebuffs = unit:GetBuffs().arHarmful
				local tempdebuff = {}
				for _, s in pairs(unitDebuffs) do
					tempdebuff[s.idBuff] = true
					if v.aura[s.idBuff] then -- refresh
						if s.nCount ~= v.aura[s.idBuff].nCount then -- this for when an aura has no duration but has stacks
							Event_FireGenericEvent("DEBUFF_APPLIED_DOSE", unit:GetName(), s.splEffect:GetId(), s.nCount)
						elseif s.fTimeRemaining > v.aura[s.idBuff].fTimeRemaining then
							Event_FireGenericEvent("DEBUFF_APPLIED_RENEW", unit:GetName(), s.splEffect:GetId(), s.nCount)
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
							Event_FireGenericEvent("DEBUFF_APPLIED", unit:GetName(), s.splEffect:GetId(), unit)
							--Print("DEBUFF_APPLIED : " .. unit:GetName() .. " " .. s.splEffect:GetId())
					end
				end
				for buffId, buffData in pairs(v.aura) do
					if not tempdebuff[buffId] then
						Event_FireGenericEvent("DEBUFF_REMOVED", unit:GetName(), buffData.splEffect:GetId(), unit)
							--Print("DEBUFF_REMOVED : " .. unit:GetName() .. " " .. buffData.splEffect:GetId())
						v.aura[buffId] = nil
					end
				end
			end
		--else
		--	self.debuffs[k] = nil
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



do
	local chatFilter = {
		ChatSystemLib.ChatChannel_Datachron,  --23
		--ChatSystemLib.ChatChannel_Say,
		ChatSystemLib.ChatChannel_NPCSay,     --20
		ChatSystemLib.ChatChannel_NPCYell,    --21
		ChatSystemLib.ChatChannel_NPCWhisper, --22
		--ChatSystemLib.ChatChannel_Datachron,  --23
	}
	local function checkChatFilter(channelType)
		for _, v in next, chatFilter do
			if v == channelType then
				return true
			end
		end
		return false
	end
	function RaidCore:OnChatMessage(channelCurrent, tMessage)
		local channelType = channelCurrent:GetType()
		if checkChatFilter(channelType) then
			local strMessage = ""
			for _, tSegment in next, tMessage.arMessageSegments do
				strMessage = strMessage .. tSegment.strText
			end

			Event_FireGenericEvent(chatEvent[channelType], strMessage)
		end
	end
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
	Apollo.RemoveEventHandler("UnitDestroyed", self)
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
	Print("WIPE")
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
	Apollo.RemoveEventHandler("UnitDestroyed", self)
	Apollo.RemoveEventHandler("ChatMessage",	 	self)
	Apollo.RemoveEventHandler("UnitEnteredCombat",	self)
	Apollo.RegisterEventHandler("UnitCreated", 			"unitCheck", self)
	Event_FireGenericEvent("RAID_WIPE")
end

function RaidCore:CombatStateChanged(unit, bInCombat)
	if unit == GameLib.GetPlayerUnit() and not bInCombat and not self.wipeTimer then
		--and GroupLib.InRaid() then
		self.wipeTimer = ApolloTimer.Create(0.5, true, "WipeCheck", self)
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

function RaidCore:OnComMessage(channel, tMessage)
	if type(tMessage.action) ~= "string" then return end
	local msg = {}

	if tMessage.action == "VersionCheckRequest" and IsPartyMemberByName(tMessage.sender) then
		msg = {action = "VersionCheckReply", sender = GameLib.GetPlayerUnit():GetName(), version = AddonVersion}
		self.chanCom:SendMessage(msg)
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
			--Print(("%s : Received %s msg from %s"):format(os.clock(), tMessage.sync, tMessage.sender))
			self.syncTimer[tMessage.sync] = timeOfEvent
			Event_FireGenericEvent("RAID_SYNC", tMessage.sync, tMessage.parameter)
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
	self.chanCom:SendMessage(msg)
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
	self.chanCom:SendMessage(msg)
end

function RaidCore:LaunchPull(time)
	if time and time > 5 then
		local msg = {action = "LaunchPull", sender = GameLib.GetPlayerUnit():GetName(), cooldown = time}
		self.chanCom:SendMessage(msg)
		self:OnComMessage(nil, msg)
	end	
end

function RaidCore:LaunchBreak(time)
	if time and time > 5 then
		local msg = {action = "LaunchBreak", sender = GameLib.GetPlayerUnit():GetName(), cooldown = time}
		self.chanCom:SendMessage(msg)
		self:OnComMessage(nil, msg)
	end	
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
	self.chanCom:SendMessage(msg)	
end

-----------------------------------------------------------------------------------------------
-- RaidCoreForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function RaidCore:OnOK()
	self.wndMain:Close() -- hide the window
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


-----------------------------------------------------------------------------------------------
-- RaidCore Instance
-----------------------------------------------------------------------------------------------
--local RaidCoreInst = RaidCore:new()
--RaidCoreInst:Init()
