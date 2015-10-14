---------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Description:
--   Elemental Pair after the Logic wings.
---------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("EpLogicLife", 52, 98, 119)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Mnemesis", "Visceralus" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Essence of Life"] = "Essence of Life",
    ["Essence of Logic"] = "Essence of Logic",
    ["Alphanumeric Hash"] = "Alphanumeric Hash",
    ["Life Force"] = "Life Force",
    ["Mnemesis"] = "Mnemesis",
    ["Visceralus"] = "Visceralus",
    -- Datachron messages.
    ["Time to die, sapients!"] = "Time to die, sapients!",
    -- Cast.
    ["Blinding Light"] = "Blinding Light",
    ["Defragment"] = "Defragment",
    -- Timer bars.
    ["Next defragment"] = "Next defragment",
    ["Avatus incoming"] = "Avatus incoming",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["SPREAD"] = "SPREAD",
    ["No-Healing Debuff!"] = "No-Healing Debuff!",
    ["NO HEAL DEBUFF"] = "NO HEAL\nDEBUFF",
    ["SNAKE ON YOU!"] = "SNAKE ON YOU!",
    ["SNAKE ON %s!"] = "SNAKE ON %s!",
    ["SNAKE"] = "SNAKE",
    ["THORNS DEBUFF"] = "THORNS\nDEBUFF",
    ["MARKER North"] = "North",
    ["MARKER South"] = "South",
    ["MARKER East"] = "East",
    ["MARKER West"] = "West",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Essence of Life"] = "Essence de vie",
    ["Essence of Logic"] = "Essence de logique",
    ["Alphanumeric Hash"] = "Alphanumeric Hash",
    ["Life Force"] = "Force vitale",
    ["Mnemesis"] = "Mnémésis",
    ["Visceralus"] = "Visceralus",
    -- Datachron messages.
    ["Time to die, sapients!"] = "Maintenant c'est l'heure de mourir, misérables !",
    -- Cast.
    ["Blinding Light"] = "Lumière aveuglante",
    ["Defragment"] = "Défragmentation",
    -- Timer bars.
    ["Next defragment"] = "Prochaine defragmentation",
    ["Avatus incoming"] = "Avatus arrivé",
    ["Enrage"] = "Enrage",
    -- Message bars.
    ["SPREAD"] = "SEPAREZ-VOUS",
    ["No-Healing Debuff!"] = "No-Healing Debuff!",
    ["NO HEAL DEBUFF"] = "NO HEAL\nDEBUFF",
    ["SNAKE ON YOU!"] = "SERPENT SUR VOUS!",
    ["SNAKE ON %s!"] = "SERPENT SUR %s!",
    ["SNAKE"] = "SERPENT",
    ["THORNS DEBUFF"] = "ÉPINE",
    ["MARKER North"] = "Nord",
    ["MARKER South"] = "Sud",
    ["MARKER East"] = "Est",
    ["MARKER West"] = "Ouest",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Essence of Life"] = "Lebensessenz",
    ["Essence of Logic"] = "Logikessenz",
    ["Alphanumeric Hash"] = "Alphanumerische Raute",
    ["Life Force"] = "Lebenskraft",
    ["Mnemesis"] = "Mnemesis",
    ["Visceralus"] = "Viszeralus",
    -- Datachron messages.
    -- Cast.
    ["Blinding Light"] = "Blendendes Licht",
    ["Defragment"] = "Defragmentieren",
    -- Timer bars.
    -- Message bars.
    ["MARKER North"] = "N",
    ["MARKER South"] = "S",
    ["MARKER East"] = "O",
    ["MARKER West"] = "W",
})
-- Default settings.
mod:RegisterDefaultSetting("SoundSnakeOnYou")
mod:RegisterDefaultSetting("SoundSnakeOnOther")
mod:RegisterDefaultSetting("SoundNoHealDebuff")
mod:RegisterDefaultSetting("SoundBlindingLight")
mod:RegisterDefaultSetting("SoundDefrag")
mod:RegisterDefaultSetting("SoundEnrageCountDown")
mod:RegisterDefaultSetting("OtherSnakePlayerMarkers")
mod:RegisterDefaultSetting("OtherNoHealDebuffPlayerMarkers")
mod:RegisterDefaultSetting("OtherRootedPlayersMarkers")
mod:RegisterDefaultSetting("OtherDirectionMarkers")
mod:RegisterDefaultSetting("LineTetrisBlocks")
mod:RegisterDefaultSetting("LineLifeOrbs")
mod:RegisterDefaultSetting("LineCleaveVisceralus")
mod:RegisterDefaultSetting("PolygonDefrag")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["DEFRAG"] = { sColor = "xkcdAlgaeGreen" },
    ["AVATUS_INCOMING"] = { sColor = "xkcdAmethyst" },
    ["ENRAGE"] = { sColor = "xkcdBloodRed" },
})

---------------------------------------------------------------------------------------------------
-- Constants.
---------------------------------------------------------------------------------------------------
local DEBUFF__SNAKE_SNACK = 74570
local DEBUFF__THORNS = 75031
local DEBUFF__LIFE_FORCE_SHACKLE = 74366
local MID_POSITIONS = {
    ["north"] = { x = 9741.53, y = -518, z = 17823.81 },
    ["west"] = { x = 9691.53, y = -518, z = 17873.81 },
    ["south"] = { x = 9741.53, y = -518, z = 17923.81 },
    ["east"] = { x = 9791.53, y = -518, z = 17873.81 },
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local bIsMidPhase = false

---------------------------------------------------------------------------------------------------
-- Encounter description.
---------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("RC_UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("DEBUFF_REMOVED", "OnDebuffRemoved", self)
    Apollo.RegisterEventHandler("CHAT_DATACHRON", "OnChatDC", self)
    bIsMidPhase = false

    mod:AddTimerBar("DEFRAG", "Next defragment", 21, mod:GetSetting("SoundDefrag"))
    mod:AddTimerBar("AVATUS_INCOMING", "Avatus incoming", 480, mod:GetSetting("SoundEnrageCountDown"))
end

function mod:OnChatDC(message)
    if self.L["Time to die, sapients!"] == message then
        mod:RemoveTimerBar("AVATUS_INCOMING")
        mod:AddTimerBar("ENRAGE", "Enrage", 34)
    end
end

function mod:OnDebuffApplied(unitName, splId, unit)
    if DEBUFF__SNAKE_SNACK == splId then
        if unit == GetPlayerUnit() then
            mod:AddMsg("SNAKE", "SNAKE ON YOU!", 5, mod:GetSetting("SoundSnakeOnYou") and "RunAway")
        else
            mod:AddMsg("SNAKE", self.L["SNAKE ON %s!"]:format(unitName), 5, mod:GetSetting("SoundSnakeOnOther") and "Info")
        end
        if mod:GetSetting("OtherSnakePlayerMarkers") then
            core:MarkUnit(unit, nil, self.L["SNAKE"]) 
        end
    elseif DEBUFF__LIFE_FORCE_SHACKLE == splId then
        if mod:GetSetting("OtherNoHealDebuffPlayerMarkers") then
            core:MarkUnit(unit, nil, self.L["NO HEAL DEBUFF"])
        end
        if unit == GetPlayerUnit() then
            mod:AddMsg("NOHEAL", "No-Healing Debuff!", 5, mod:GetSetting("SoundNoHealDebuff") and "Alarm")
        end
    elseif DEBUFF__THORNS == splId then
        if mod:GetSetting("OtherRootedPlayersMarkers") then
            core:MarkUnit(unit, nil, self.L["THORNS DEBUFF"])
        end
    end
end

function mod:OnDebuffRemoved(unitName, splId, unit)
    if DEBUFF__SNAKE_SNACK == splId then
        core:DropMark(unit:GetId())
    elseif DEBUFF__LIFE_FORCE_SHACKLE == splId then
        core:DropMark(unit:GetId())
    elseif DEBUFF__THORNS == splId then
        core:DropMark(unit:GetId())
    end
end

function mod:OnUnitCreated(nId, unit, sName)
    local nHealth = tUnit:GetHealth()

    if sName == self.L["Visceralus"] then
        if nHealth then 
            core:AddUnit(unit)
            core:WatchUnit(unit)
            if mod:GetSetting("LineCleaveVisceralus") then
                core:AddSimpleLine("Visc1", nId, 0, 25, 0, 4, "blue", 10)
                core:AddSimpleLine("Visc2", nId, 0, 25, 72, 4, "green", 20)
                core:AddSimpleLine("Visc3", nId, 0, 25, 144, 4, "green", 20)
                core:AddSimpleLine("Visc4", nId, 0, 25, 216, 4, "green", 20)
                core:AddSimpleLine("Visc5", nId, 0, 25, 288, 4, "green", 20)
            end
        end
    elseif sName == self.L["Mnemesis"] then
        if nHealth then 
            core:WatchUnit(unit)
            core:AddUnit(unit)
        end
    elseif sName == self.L["Essence of Life"] then
        core:AddUnit(unit)
        if not bIsMidPhase then
            bIsMidPhase = true
            if mod:GetSetting("OtherDirectionMarkers") then
                core:SetWorldMarker("NORTH", self.L["MARKER North"], MID_POSITIONS["north"])
                core:SetWorldMarker("EAST", self.L["MARKER East"], MID_POSITIONS["east"])
                core:SetWorldMarker("SOUTH", self.L["MARKER South"], MID_POSITIONS["south"])
                core:SetWorldMarker("WEST", self.L["MARKER West"], MID_POSITIONS["west"])
            end
            core:RemoveTimerBar("DEFRAG")
        end
    elseif sName == self.L["Essence of Logic"] then
        core:AddUnit(unit)
    elseif sName == self.L["Alphanumeric Hash"] then
        local unitId = unit:GetId()
        if unitId then
            if mod:GetSetting("LineTetrisBlocks") then
                core:AddSimpleLine(unitId, unitId, 0, 20, 0, 10, "red")
            end
        end
    elseif sName == self.L["Life Force"] and mod:GetSetting("LineLifeOrbs") then
        core:AddPixie(unit:GetId(), 2, unit, nil, "Blue", 3, 15, 0)
    end
end

function mod:OnUnitDestroyed(unit, sName)
    local nId = unit:GetId()

    if sName == self.L["Essence of Logic"] then
        bIsMidPhase = false
        core:ResetWorldMarkers()
    elseif sName == self.L["Alphanumeric Hash"] then
        core:RemoveSimpleLine(nId)
    elseif sName == self.L["Life Force"] then
        core:DropPixie(nId)
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    local eventTime = GameLib.GetGameTime()
    if unitName == self.L["Visceralus"] then
        if castName == self.L["Blinding Light"] then
            if self:GetDistanceBetweenUnits(unit, GetPlayerUnit()) < 33 then
                mod:AddMsg("BLIND", "Blinding Light", 5, mod:GetSetting("SoundBlindingLight") and "Beware")
            end
        end
    elseif unitName == self.L["Mnemesis"] then
        if castName == self.L["Defragment"] then
            mod:AddMsg("DEFRAG", "SPREAD", 3, mod:GetSetting("SoundDefrag") and "Alarm")
            mod:AddTimerBar("DEFRAG", "Next defragment", 40, mod:GetSetting("SoundDefrag"))
            if mod:GetSetting("PolygonDefrag") then
                core:AddPolygon("DEFRAG_SQUARE", GetPlayerUnit():GetId(), 13, 0, 4, "xkcdBloodOrange", 4)
                self:ScheduleTimer(function()
                    core:RemovePolygon("DEFRAG_SQUARE")
                end, 10)
            end
        end
    end
end
