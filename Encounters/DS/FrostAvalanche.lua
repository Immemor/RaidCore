--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("FrostAvalanche", 52, 98, 109)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Frost-Boulder Avalanche" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Frost-Boulder Avalanche",
    -- Cast.
    ["Icicle Storm"] = "Icicle Storm",
    ["Shatter"] = "Shatter",
    ["Cyclone"] = "Cyclone",
    -- Bar and messages.
    ["CYCLONE SOON"] = "CYCLONE SOON",
    ["ICICLE"] = "ICICLE%s"
    ["SHATTER"] = "SHATTER%s"
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Avalanche cryoroc",
    -- Cast.
    ["Icicle Storm"] = "Tempête de stalactites",
    ["Shatter"] = "Fracasser",
    ["Cyclone"] = "Cyclone",
    -- Bar and messages.
    --["CYCLONE SOON"] = "CYCLONE SOON", -- TODO: French translation missing !!!!
    --["ICICLE"] = "ICICLE%s" -- TODO: French translation missing !!!!
    --["SHATTER"] = "SHATTER%s" -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Frost-Boulder Avalanche"] = "Frostfelsen-Lawine",
    -- Cast.
    ["Icicle Storm"] = "Eiszapfensturm",
    ["Shatter"] = "Zerschmettern",
    ["Cyclone"] = "Wirbelsturm",
    -- Bar and messages.
    --["CYCLONE SOON"] = "CYCLONE SOON", -- TODO: German translation missing !!!!
    --["ICICLE"] = "ICICLE%s" -- TODO: German translation missing !!!!
    --["SHATTER"] = "SHATTER%s" -- TODO: German translation missing !!!!
})

--------------------------------------------------------------------------------
-- Locals
--

local icicleSpell = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OnHealthChanged(unitName, health)
    if unitName == self.L["Frost-Boulder Avalanche"] then
        if (health == 85 or health == 55 or health ==31) then
            core:AddMsg("CYCLONE", self.L["CYCLONE SOON"], 5, "Info", "Blue")
        end
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Frost-Boulder Avalanche"] then
        if castName == self.L["Icicle Storm"] then
            core:AddMsg("ICICLE", self.L["ICICLE"]:format(" !!"), 5, "Alert")
            core:AddBar("ICICLE", self.L["ICICLE"]:format(""), 22)
            icicleSpell = true
        elseif castName == self.L["Shatter"] then
            core:AddMsg("ICICLE", self.L["SHATTER"]:format(" !!"), 5, "Alert")
            core:AddBar("ICICLE", self.L["SHATTER"]:format(""), 22)
        elseif castName == self.L["Cyclone"] then
            core:AddMsg("CYCLONE", self.L["Cyclone"]:upper(), 5, "RunAway")
            core:AddBar("RUN", self.L["Cyclone"]:upper(), 23)
            local txt = icicleSpell and self.L["ICICLE"]:format("") or self.L["SHATTER"]:format("")
            core:AddBar("ICICLE", txt, 48)
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Frost-Boulder Avalanche"] then
            icicleSpell = false
            core:AddUnit(unit)
            core:WatchUnit(unit)
        end
    end
end
