--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewBoss("EpLifeLogic", 52)
if not mod then return end

mod:RegisterEnableBossPair("Mnemesis", "Visceralus")
mod:RegisterRestrictZone("EpLifeLogic", "Elemental Vortex Alpha", "Elemental Vortex Beta", "Elemental Vortex Delta")

--------------------------------------------------------------------------------
-- Locals
--

local uPlayer = nil
local strMyName = ""

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	Print(("Module %s loaded"):format(mod.ModuleName))
	Apollo.RegisterEventHandler("UnitEnteredCombat", 	"OnCombatStateChanged", self)
	Apollo.RegisterEventHandler("SPELL_CAST_START", 	"OnSpellCastStart", self)
	--Apollo.RegisterEventHandler("UnitCreated", 		"OnUnitCreated", self)
	--Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("DEBUFF_APPLIED", 		"OnDebuffApplied", self)
	Apollo.RegisterEventHandler("DEBUFF_REMOVED", 		"OnDebuffRemoved", self)
	Apollo.RegisterEventHandler("RAID_WIPE", 			"OnReset", self)
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

function mod:OnReset()
	core:ResetMarks()
end

function mod:OnDebuffApplied(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName = tSpell:GetName()

	if strSpellName == "Snake Snack" then
		if unitName == strMyName then
			core:AddMsg("SNAKE", "SNAKE ON YOU!", 5, "RunAway")
		else
			local msgString = "SNAKE ON " .. unitName
			core:AddMsg("SNAKE", msgString, 5, "Info")
		end
		core:MarkUnit(unit, nil, "SNAKE")
	elseif strSpellName == "Life Force Shackle" then
		core:MarkUnit(unit, nil, "NO HEAL\nDEBUFF")
		if unitName == strMyName then
			core:AddMsg("NOHEAL", "No-Healing Debuff!", 5, "Alarm")
		end
	end
	--Print(eventTime .. " " .. unitName .. "has debuff: " .. strSpellName .. " with splId: " .. splId)
end

function mod:OnDebuffRemoved(unitName, splId, unit)
	local eventTime = GameLib.GetGameTime()
	local tSpell = GameLib.GetSpell(splId)
	local strSpellName = tSpell:GetName()

	if strSpellName == "Snake Snack" then
		core:DropMark(unit:GetId())
	elseif strSpellName == "Life Force Shackle" then
		core:DropMark(unit:GetId())
	end
end

function mod:OnUnitCreated(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()
	--Print(eventTime .. " - " .. sName)
end

function mod:OnUnitDestroyed(unit)
	local sName = unit:GetName()
	local eventTime = GameLib.GetGameTime()
end

function mod:OnSpellCastStart(unitName, castName, unit)
	local eventTime = GameLib.GetGameTime()
	if unitName == "Visceralus" and castName == "Blinding Light" then
		if dist2unit(unit, uPlayer) < 33 then
			core:AddMsg("BLIND", "Blinding Light", 5, "Beware")
		end
	elseif unitName == "Mnemesis" and castName == "Defragment" then
		core:StopBar("DEFRAG")
		--core:AddBar("DEFRAG", "~DEFRAG", 48, true) -- Maybe, test if correct, doesnt'seem to be after p2 at least.
		core:AddMsg("DEFRAG", "DEFRAG", 5, "Beware")
	end
	--Print(eventTime .. " " .. unitName .. " Casting: " .. castName)
end

function mod:OnCombatStateChanged(unit, bInCombat)
	if unit:GetType() == "NonPlayer" and bInCombat then
		local sName = unit:GetName()
		local eventTime = GameLib.GetGameTime()

		if sName == "Visceralus" then
			core:AddUnit(unit)
			core:WatchUnit(unit)
		elseif sName == "Mnemesis" then
			self:Start()
			core:WatchUnit(unit)
			uPlayer = GameLib.GetPlayerUnit()
			strMyName = uPlayer:GetName()
			core:AddUnit(unit)
			core:RaidDebuff()
			core:StartScan()
			core:AddBar("DEFRAG", "~DEFRAG", 21, true)

			--Print(eventTime .. " FIGHT STARTED")
		end
	end
end