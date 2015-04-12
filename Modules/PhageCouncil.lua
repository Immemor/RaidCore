--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("PhageCouncil", 67)
if not mod then return end

mod:RegisterEnableMob("Golgox the Lifecrusher", "Terax Blightweaver", "Ersoth Curseform", "Noxmind the Insidious", "Fleshmonger Vratorg")
mod:RegisterRestrictZone("PhageCouncil", "Augmentation Core")
mod:RegisterEnableZone("PhageCouncil", "Augmentation Core")
mod:RegisterEnglishLocale({
	-- Unit names.
	["Terax Blightweaver"] = "Terax Blightweaver",
	["Golgox the Lifecrusher"] = "Golgox the Lifecrusher",
	["Fleshmonger Vratorg"] = "Fleshmonger Vratorg",
	["Noxmind the Insidious"] = "Noxmind the Insidious",
	["Ersoth Curseform"] = "Ersoth Curseform",
	-- Datachron messages.
	["The Phageborn Convergence begins gathering its power"] = "The Phageborn Convergence begins gathering its power",
	-- Cast.
	["Teleport"] = "Teleport",
	["Channeling Energy"] = "Channeling Energy",
	["Stitching Strain"] = "Stitching Strain",
	-- Bar and messages.
	["[%u] NEXT P2"] = "[%u] NEXT P2",
	["P2 : 20 IA"] = "P2 : 20 IA",
	["P2 : MINI ADDS"] = "P2 : MINI ADDS",
	["P2 : SUBDUE"] = "P2 : SUBDUE",
	["P2 : PILLARS"] = "P2 : PILLARS",
	["Interrupt Terax!"] = "Interrupt Terax!",
})
mod:RegisterFrenchLocale({
	-- Unit names.
	["Terax Blightweaver"] = "Terax Tisserouille",
	["Golgox the Lifecrusher"] = "Golgox le Fossoyeur",
	["Fleshmonger Vratorg"] = "Vratorg le Cannibale",
	["Noxmind the Insidious"] = "Toxultime l'Insidieux",
	["Ersoth Curseform"] = "Ersoth le Maudisseur",
	-- Datachron messages.
	-- Cast.
	["Teleport"] = "Se téléporter",
	-- Bar and messages.
	["[%u] NEXT P2"] = "[%u] PROCHAINE P2",
	["P2 : 20 IA"] = "P2 : 20 IA",
	["P2 : MINI ADDS"] = "P2 : MINI ADDS",
	["P2 : SUBDUE"] = "P2 : DESARMEMENT",
	["P2 : PILLARS"] = "P2 : PILLIERS",
})
mod:RegisterGermanLocale({
	-- Unit names.
	-- Datachron messages.
	-- Cast.
	-- Bar and messages.
})


--------------------------------------------------------------------------------
-- Locals
--

local p2Count = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
	Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
	Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function dist2unit(unitSource, unitTarget)
	if not unitSource or not unitTarget then return 999 end
	local sPos = unitSource:GetPosition()
	local tPos = unitTarget:GetPosition()

	local sVec = Vector3.New(sPos.x, sPos.y, sPos.z)
	local tVec = Vector3.New(tPos.x, tPos.y, tPos.z)

	local dist = (tVec - sVec):Length()

	return tonumber(dist)
end

function mod:OnSpellCastStart(unitName, castName, unit)
	if unitName == self.L["Golgox the Lifecrusher"] and castName == self.L["Teleport"] then
		core:AddMsg("CONVP2", self.L["P2 : 20 IA"], 5, "Alert")
		core:AddBar("CONVP2", self.L["P2 : 20 IA"], 29.5)
	elseif unitName == self.L["Terax Blightweaver"] then
		if castName == self.L["Teleport"] then
			core:AddMsg("CONVP2", self.L["P2 : MINI ADDS"], 5, "Alert")
			core:AddBar("CONVP2", self.L["P2 : MINI ADDS"], 29.5)
		elseif castName == self.L["Stitching Strain"] and dist2unit(GameLib.GetPlayerUnit(), unit) < 30 then
			core:AddMsg("INTSTRAIN", self.L["Interrupt Terax!"], 5, "Inferno")
		end
	elseif unitName == self.L["Ersoth Curseform"] and castName == self.L["Teleport"] then
		core:AddMsg("CONVP2", self.L["P2 : SUBDUE"], 5, "Alert")
		core:AddBar("CONVP2", self.L["P2 : SUBDUE"], 29.5)
	elseif unitName == self.L["Noxmind the Insidious"] and castName == self.L["Teleport"] then
		core:AddMsg("CONVP2", self.L["P2 : PILLARS"], 5, "Alert")
		core:AddBar("CONVP2", self.L["P2 : PILLARS"], 29.5)
	elseif unitName == self.L["Fleshmonger Vratorg"] and castName == self.L["Teleport"] then
		core:AddMsg("CONVP2", self.L["P2 : SHIELD"], 5, "Alert")
		core:AddBar("CONVP2", self.L["P2 : SHIELD"], 29.5)
	end
end

function mod:OnSpellCastEnd(unitName, castName)
	if castName == self.L["Channeling Energy"] then
		core:StopBar("CONVP2")
		core:AddBar("CONVP1", self.L["[%u] NEXT P2"]:format(p2Count + 1), 60, 1)
	end
end

function mod:OnChatDC(message)
	if message:find(self.L["The Phageborn Convergence begins gathering its power"]) then
		p2Count = p2Count + 1
	end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
	if unit:GetType() == "NonPlayer" and bInCombat then
		if sName == self.L["Golgox the Lifecrusher"]
			or sName == self.L["Terax Blightweaver"]
			or sName == self.L["Ersoth Curseform"]
			or sName == self.L["Noxmind the Insidious"]
			or sName == self.L["Fleshmonger Vratorg"] then
			self:Start()
			self:StartScan()
			p2Count = 0
			core:AddBar("CONVP1", self.L["[%u] NEXT P2"]:format(p2Count + 1), 90, 1)
			core:AddUnit(unit)
			core:WatchUnit(unit)
		end
	end
end
