----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--
--   The elemental Pair Megalith and Mnemesis juste after Maelstrom fight.
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("EpLogicEarth", 52, 98, 117)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ALL", { "Megalith", "Mnemesis" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Mnemesis"] = "Mnemesis",
    ["Obsidian Outcropping"] = "Obsidian Outcropping",
    ["Crystalline Matrix"] = "Crystalline Matrix",
    ["Snake Piece"] = "e395- [Datascape] Logic Elemental - Snake Piece (invis unit)",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "The ground shudders beneath Megalith",
    ["Logic creates powerful data caches"] = "Logic creates powerful data caches",
    -- Cast.
    ["Defragment"] = "Defragment",
    -- Timer bars.
    ["Next defragment"] = "Next defragment",
    ["Next phase: Stars"] = "Next phase: Stars",
    -- Message bars.
    ["SNAKE on %s"] = "SNAKE on %s",
    ["SPREAD"] = "SPREAD",
    ["JUMP !"] = "JUMP !",
    ["STARS !"] = "STARS !",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Megalith"] = "Mégalithe",
    ["Mnemesis"] = "Mnémésis",
    ["Obsidian Outcropping"] = "Affleurement d'obsidienne",
    ["Crystalline Matrix"] = "Matrice cristalline",
    ["Snake Piece"] = "e395- [Datascape] Logic Elemental - Snake Piece (invis unit)",
    -- Datachron messages.
    ["The ground shudders beneath Megalith"] = "Le sol tremble sous les pieds de Mégalithe !",
    ["Logic creates powerful data caches"] = "La logique crée de puissantes caches de données !",
    -- Cast.
    ["Defragment"] = "Défragmentation",
    -- Timer bars.
    ["Next defragment"] = "Prochaine defragmentation",
    ["Next phase: Stars"] = "Prochaine phase: Étoile",
    -- Message bars.
    ["SNAKE on %s"] = "SERPENT sur %s",
    ["SPREAD"] = "SEPAREZ-VOUS",
    ["JUMP !"] = "SAUTEZ !",
    ["STARS !"] = "ÉTOILE !",
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Megalith"] = "Megalith",
    ["Mnemesis"] = "Mnemesis",
    ["Crystalline Matrix"] = "Kristallmatrix",
    -- Datachron messages.
    -- Cast.
    ["Defragment"] = "Defragmentieren",
    -- Timer bars.
    -- Message bars.
})
-- Default settings.
mod:RegisterDefaultSetting("LineSnakeVsPlayer")
mod:RegisterDefaultSetting("LineSnakeVsCloseObsidian")
mod:RegisterDefaultSetting("LineSnakeVsOtherObsidian")
mod:RegisterDefaultSetting("PolygonDefrag")
mod:RegisterDefaultSetting("SoundDefrag")
mod:RegisterDefaultSetting("SoundQuakeJump")
mod:RegisterDefaultSetting("SoundStars")
mod:RegisterDefaultSetting("SoundSnake")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["DEFRAG"] = { sColor = "xkcdAlgaeGreen" },
    ["STARS"] = { sColor = "xkcdBlue" },
    ["SNAKE"] = { sColor = "xkcdBrickOrange" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local BUFF_MNEMESIS_INFORMATIC_CLOUD = 52571
local DEBUFF_SNAKE = 74570
local COLOR_SNAKE_FOCUS = "xkcdBarneyPurple"
local COLOR_SNAKE_UNFOCUS_OBSIDIAN = "xkcdBarbiePink"
local COLOR_SNAKE_UNFOCUS_PLAYER = "xkcdBabyPink"

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local ipairs = ipairs
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local nLastSnakePieceId
local nMemberIdTargetedBySnake
local tObsidianList

local function DrawSnakePieceLines()
    if mod:GetSetting("LineSnakeVsPlayer") then
        if nLastSnakePieceId and nMemberIdTargetedBySnake then
            local bTrig = #tObsidianList == 0
            local c = bTrig and COLOR_SNAKE_FOCUS or COLOR_SNAKE_UNFOCUS_PLAYER
            local w = bTrig and 8 or 3
            core:AddLineBetweenUnits("Player VS Snake", nLastSnakePieceId, nMemberIdTargetedBySnake, w, c)
        else
            core:RemoveLineBetweenUnits("Player VS Snake")
        end
    end
    if nLastSnakePieceId and #tObsidianList > 0 then
        local nObisidianMostClosedId = nil
        local nObisidianMostClosedDistance = nil

        for i, nId in ipairs(tObsidianList) do
            local nDistance = mod:GetDistanceBetweenUnits(GetUnitById(nId), GetUnitById(nLastSnakePieceId))
            if not nObisidianMostClosedDistance or nObisidianMostClosedDistance > nDistance then
                nObisidianMostClosedDistance = nDistance
                nObisidianMostClosedId = nId
            end
        end
        for i, nId in ipairs(tObsidianList) do
            local bIsMostClose = nId == nObisidianMostClosedId
            local c = bIsMostClose and COLOR_SNAKE_FOCUS or COLOR_SNAKE_UNFOCUS_OBSIDIAN
            local w = bIsMostClose and 8 or 3
            if mod:GetSetting("LineSnakeVsCloseObsidian") and bIsMostClose or
                mod:GetSetting("LineSnakeVsOtherObsidian") and not bIsMostClose then
                core:AddLineBetweenUnits("OBSIDIAN" .. nId, nLastSnakePieceId, nId, w, c)
            end
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    nLastSnakePieceId = nil
    tObsidianList = {}
    nMemberIdTargetedBySnake = nil
    mod:AddTimerBar("DEFRAG", "Next defragment", 10)
    mod:AddTimerBar("STARS", "Next phase: Stars", 60)
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()

    if self.L["Megalith"] == sName or self.L["Mnemesis"] == sName then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
        end
    elseif sName == self.L["Obsidian Outcropping"] then
        table.insert(tObsidianList, nId)
    elseif self.L["Snake Piece"] == sName then
        nLastSnakePieceId = nId
        DrawSnakePieceLines()
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Obsidian Outcropping"] then
        core:RemoveLineBetweenUnits("OBSIDIAN" .. nId)
        for i, nIdSaved in ipairs(tObsidianList) do
            if nIdSaved == nId then
                table.remove(tObsidianList, i)
                break
            end
        end
        DrawSnakePieceLines()
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Mnemesis"] == sName then
        if self.L["Defragment"] == sCastName then
            mod:AddMsg("DEFRAG", "SPREAD", 3, mod:GetSetting("SoundDefrag") and "Alarm")
            mod:AddTimerBar("DEFRAG", "Next defragment", 40)
            if mod:GetSetting("PolygonDefrag") then
                core:AddPolygon("DEFRAG_SQUARE", GetPlayerUnit():GetId(), 13, 0, 4, "xkcdBloodOrange", 4)
                self:ScheduleTimer(function()
                    core:RemovePolygon("DEFRAG_SQUARE")
                end, 10)
            end
        end
    end
end

function mod:OnDatachron(sMessage)
    if sMessage:find(self.L["The ground shudders beneath Megalith"]) then
        mod:AddMsg("QUAKE", "JUMP !", 3, mod:GetSetting("SoundQuakeJump") and "Beware")
    elseif sMessage:find(self.L["Logic creates powerful data caches"]) then
        mod:AddMsg("STARS", "STARS !", 5, mod:GetSetting("SoundStars") and "Alert")
        mod:AddTimerBar("STARS", "Next phase: Stars", 60)
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GetUnitById(nId)
    local sUnitName = tUnit:GetName()

    if nSpellId == DEBUFF_SNAKE then
        local sSnakeOnX = self.L["SNAKE on %s"]:format(sUnitName)
        local sSound = tUnit == GetPlayerUnit() and mod:GetSetting("SoundSnake") and "RunAway"
        mod:AddMsg("SNAKE", sSnakeOnX, 5, sSound, "Blue")
        mod:AddTimerBar("SNAKE", sSnakeOnX, 20)
        nMemberIdTargetedBySnake = nId
        DrawSnakePieceLines()
    end
end
