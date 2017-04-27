----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- TODO
----------------------------------------------------------------------------------------------------
local Apollo = require "Apollo"
local GameLib = require "GameLib"

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("LimboInfomatrix", 52, 98, 114)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob(core.E.TRIGGER_ANY, { "Invisible Hate Unit" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Invisible Hate Unit"] = "Invisible Hate Unit",
    ["Keeper of Sands"] = "Keeper of Sands",
    ["Infomatrix Antlion"] = "Infomatrix Antlion",
    ["BEAX"] = "16623 Hostile Invisible Unit for Fields (0 hit radius) (Very Fast Move Updates) - BEAX",
    -- Cast.
    ["Exhaust"] = "Exhaust",
    ["Desiccate"] = "Desiccate",
    -- Bar and messages.
    ["WARNING: KNOCK-BACK"] = "WARNING: KNOCK-BACK",
  })
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Invisible Hate Unit"] = "Unité haineuse invisible",
    ["Keeper of Sands"] = "Gardien des sables",
    ["Infomatrix Antlion"] = "Fourmilion de l'Infomatrice",
    ["BEAX"] = "16623 Hostile Invisible Unit for Fields (0 hit radius) (Very Fast Move Updates) - BEAX",
    -- Cast.
    ["Exhaust"] = "Épuiser",
    ["Desiccate"] = "Dessécher",
    -- Bar and messages.
    ["WARNING: KNOCK-BACK"] = "ATTENTION: KNOCK-BACK",
  })
mod:RegisterGermanLocale({
  })
-- Default settings.
mod:RegisterDefaultSetting("PathOfSandsKeeper")
mod:RegisterDefaultSetting("LinePathOfInvisibleUnit")
mod:RegisterDefaultSetting("SoundDessicateInterrupt")
mod:RegisterDefaultSetting("OtherMarkerAntlion")

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local tKoS_Position
local bKoS_bInCombat

-- Is the player is far from the Keeper Of Sands.
-- @param tKeeperUnit unit object which represent the Keeper of Sands.
-- @return true player is under the 40 meters, false otherwise.
local function IsInRangeOfKeeper(tKeeperUnit)
  return mod:GetDistanceBetweenUnits(GetPlayerUnit(), tKeeperUnit) < 40
end

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
local function ManagerKeeperOfSandsLine()
  if mod:GetSetting("PathOfSandsKeeper") then
    if not bKoS_bInCombat and tKoS_Position then
      local nPlayerId = GetPlayerUnit():GetId()
      local line = core:AddLineBetweenUnits("Path2KoS", nPlayerId, tKoS_Position, 6, "red")
      line:SetMinLengthVisible(60)
    else
      core:RemoveLineBetweenUnits("Path2KoS")
    end
  end
end

function mod:OnBossEnable()
  tKoS_Position = nil
  bKoS_bInCombat = false
end

function mod:OnUnitCreated(nId, tUnit, sName)
  if sName == self.L["Keeper of Sands"] then
    core:AddUnit(tUnit)
    core:WatchUnit(tUnit, core.E.TRACK_CASTS)
    tKoS_Position = tUnit:GetPosition()
    mod:SendIndMessage("KeeperOfSands_Position", tKoS_Position)
    ManagerKeeperOfSandsLine()
  elseif sName == self.L["Infomatrix Antlion"] then
    core:AddUnit(tUnit)
    if mod:GetSetting("OtherMarkerAntlion") then
      core:MarkUnit(tUnit)
    end
  elseif sName == self.L["BEAX"] then
    if mod:GetSetting("LinePathOfInvisibleUnit") then
      if IsInRangeOfKeeper(tUnit) then
        local tPosition = tUnit:GetPosition()
        local sKey1 = ("BEAX %d-%d"):format(nId, 1)
        local sKey2 = ("BEAX %d-%d"):format(nId, 2)
        -- Avoid the rotation of the circles through the Position instead the nId.
        core:AddPolygon(sKey1, tPosition, 6, 0, 3, "xkcdBrightPurple", 16)
        core:AddPolygon(sKey2, tPosition, 15, 0, 3, "xkcdBluishPurple", 16)
      end
    end
  end
end

function mod:OnEnteredCombat(nId, tUnit, sName, bInCombat)
  if sName == self.L["Keeper of Sands"] then
    bKoS_bInCombat = bInCombat
    mod:SendIndMessage("KeeperOfSands_bInCombat", bKoS_bInCombat)
    ManagerKeeperOfSandsLine()
  end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
  if sName == self.L["BEAX"] then
    for i=1, 2 do
      core:RemovePolygon(("BEAX %d-%d"):format(nId, i))
    end
  end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
  if sName == self.L["Keeper of Sands"] then
    local tUnit = GetUnitById(nId)
    local bInRange = IsInRangeOfKeeper(tUnit)
    if bInRange then
      if sCastName == self.L["Desiccate"] then
        if mod:GetSetting("SoundDessicateInterrupt") then
          core:PlaySound("Alert")
        end
      elseif sCastName == self.L["Exhaust"] then
        mod:AddMsg("EXHAUST", "WARNING: KNOCK-BACK", 3, "Info")
      end
    end
  end
end

function mod:ReceiveIndMessage(sFrom, sReason, data)
  if "KeeperOfSands_Position" == sReason then
    tKoS_Position = data
    ManagerKeeperOfSandsLine()
  end
  if "KeeperOfSands_bInCombat" == sReason then
    bKoS_bInCombat = data
    ManagerKeeperOfSandsLine()
  end
end
