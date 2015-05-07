--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("EpAirWater", 52, 98, 118)
if not mod then return end

mod:RegisterTrigMob("ALL", { "Hydroflux", "Aileron" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Aileron",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Glacial Icestorm",
    -- Bar and messages.
    ["MOO !"] = "MOO !",
    ["MOO PHASE"] = "MOO PHASE",
    ["ICESTORM"] = "ICESTORM",
    ["~Middle Phase"] = "~Middle Phase",
    ["~Frost Tombs"] = "~Frost Tombs",
    ["TWIRL ON YOU!"] = "TWIRL ON YOU!",
    ["TWIRL"] = "TWIRL",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Ventemort",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Tempête de neige glaciale",
    -- Bar and messages.
    --["MOO !"] = "MOO !", -- TODO: French translation missing !!!!
    ["MOO PHASE"] = "MOO PHASE",
    --["ICESTORM"] = "ICESTORM", -- TODO: French translation missing !!!!
    --["~Middle Phase"] = "~Middle Phase", -- TODO: French translation missing !!!!
    --["~Frost Tombs"] = "~Frost Tombs", -- TODO: French translation missing !!!!
    --["TWIRL ON YOU!"] = "TWIRL ON YOU!", -- TODO: French translation missing !!!!
    --["TWIRL"] = "TWIRL", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Hydroflux"] = "Hydroflux",
    ["Aileron"] = "Aileron",
    -- Cast.
    ["Tsunami"] = "Tsunami",
    ["Glacial Icestorm"] = "Frostiger Eissturm",
    -- Bar and messages.
    --["MOO !"] = "MOO !", -- TODO: German translation missing !!!!
    --["MOO PHASE"] = "MOO PHASE", -- TODO: German translation missing !!!!
    --["ICESTORM"] = "ICESTORM", -- TODO: German translation missing !!!!
    --["~Middle Phase"] = "~Middle Phase", -- TODO: German translation missing !!!!
    --["~Frost Tombs"] = "~Frost Tombs", -- TODO: German translation missing !!!!
    --["TWIRL ON YOU!"] = "TWIRL ON YOU!", -- TODO: German translation missing !!!!
    --["TWIRL"] = "TWIRL", -- TODO: German translation missing !!!!
})

--------------------------------------------------------------------------------
-- Locals
--

local prev = 0
local mooCount = 0
local phase2 = false
local myName
local CheckTwirlTimer = nil

--------------------------------------------------------------------------------
-- Initialization
--
function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("SPELL_CAST_END", "OnSpellCastEnd", self)
    Apollo.RegisterEventHandler("BUFF_APPLIED", "OnBuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("RAID_WIPE", "OnReset", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnReset()
    if CheckTwirlTimer then
        self:CancelTimer(CheckTwirlTimer)
    end
    core:ResetMarks()
    twirl_units = {}
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Hydroflux"] then
        if castName == self.L["Tsunami"] then
            phase2 = true
            mooCount = mooCount + 1
            core:AddMsg("PHASE2", self.L["Tsunami"]:upper(), 5, mod:GetSetting("SoundMidphase", "Alert"))
        elseif castName == self.L["Glacial Icestorm"] then
            core:AddMsg("ICESTORM", self.L["ICESTORM"], 5, mod:GetSetting("SoundIcestorm", "RunAway"))
        end
    end
end

function mod:OnSpellCastEnd(unitName, castName)
    if unitName == self.L["Hydroflux"] and castName == self.L["Tsunami"] then
        core:AddBar("MIDPHASE", self.L["~Middle Phase"], 88, mod:GetSetting("SoundMidphase"))
        core:AddBar("TOMB", self.L["~Frost Tombs"], 30, mod:GetSetting("SoundFrostTombs"))
    end
end

function mod:OnBuffApplied(unitName, splId, unit)
    if phase2 and (splId == 69959 or splId == 47075) then
        phase2 = false
        core:AddMsg("MOO", self.L["MOO !"], 5, mod:GetSetting("SoundMoO", "Info"), "Blue")
        core:AddBar("MOO", self.L["MOO PHASE"], 10, mod:GetSetting("SoundMoO"))
        if mooCount == 2 then
            mooCount = 0
            core:AddBar("ICESTORM", self.L["ICESTORM"], 15)
        end
    end
end

function mod:OnDebuffApplied(unitName, splId, unit)
    local eventTime = GameLib.GetGameTime()
    if splId == 70440 then -- Twirl ability
        if unitName == myName and mod:GetSetting("OtherTwirlWarning") then
            core:AddMsg("TWIRL", self.L["TWIRL ON YOU!"], 5, mod:GetSetting("SoundTwirl", "Inferno"))
        end
        if mod:GetSetting("OtherTwirlPlayerMarkers") then
            core:MarkUnit(unit, nil, self.L["TWIRL"])
        end
        core:AddUnit(unit)
        twirl_units[unitName] = unit
        if not CheckTwirlTimer then
            CheckTwirlTimer = self:ScheduleRepeatingTimer("CheckTwirlTimer", 1)
        end
    end
end

function mod:CheckTwirlTimer()
    for unitName, unit in pairs(twirl_units) do
        if unit and unit:GetBuffs() then
            local bUnitHasTwirl = false
            local debuffs = unit:GetBuffs().arHarmful
            for _, debuff in pairs(debuffs) do
                if debuff.splEffect:GetId() == 70440 then -- the Twirl ability
                    bUnitHasTwirl = true
                end
            end
            if not bUnitHasTwirl then
                -- else, if the debuff is no longer present, no need to track anymore.
                core:DropMark(unit:GetId())
                core:RemoveUnit(unit:GetId())
                twirl_units[unitName] = nil
            end
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        local eventTime = GameLib.GetGameTime()
        local playerUnit = GameLib.GetPlayerUnit()
        myName = playerUnit:GetName()

        if sName == self.L["Hydroflux"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:UnitBuff(unit)
        elseif sName == self.L["Aileron"] then
            mooCount = 0
            phase2 = false
            twirl_units = {}
            CheckTwirlTimer = nil
            core:AddUnit(unit)
            core:UnitBuff(unit)
            core:UnitDebuff(playerUnit)
            core:RaidDebuff()
            core:AddBar("MIDPHASE", self.L["Middle Phase"], 60, mod:GetSetting("SoundMidphase"))
            core:AddBar("TOMB", self.L["~Frost Tombs"], 30, mod:GetSetting("SoundFrostTombs"))
        end
    end
end
