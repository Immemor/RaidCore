--------------------------------------------------------------------------------
-- Module Declaration
--

local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")

local mod = core:NewEncounter("DSFireWing", 52, 98, 110)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Warmonger Agratha", "Warmonger Talarii", "Grand Warmonger Tar'gresh" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Warmonger Agratha"] = "Warmonger Agratha",
    ["Warmonger Talarii"] = "Warmonger Talarii",
    ["Warmonger Chuna"] = "Warmonger Chuna",
    ["Grand Warmonger Tar'gresh"] = "Grand Warmonger Tar'gresh",
    ["Conjured Fire Bomb"] = "Conjured Fire Bomb",
    -- Datachron messages.
    -- NPCSay messages.
    -- Cast.
    ["Incineration"] = "Incineration",
    ["Conjure Fire Elementals"] = "Conjure Fire Elementals",
    ["Meteor Storm"] = "Meteor Storm",
    -- Bar and messages.
    ["INTERRUPT !"] = "INTERRUPT !",
    ["ELEMENTALS SOON"] = "ELEMENTALS SOON",
    ["ELEMENTALS"] = "ELEMENTALS",
    ["FIRST ABILITY"] = "FIRST ABILITY",
    ["SECOND ABILITY"] = "SECOND ABILITY",
    ["STORM !!"] = "STORM !!",
    ["METEOR STORM"] = "METEOR STORM",
    ["KNOCKBACK"] = "KNOCKBACK",
    ["BOMB"] = "BOMB",
})
mod:RegisterFrenchLocale({
    -- Unit names.
    ["Warmonger Agratha"] = "Guerroyeuse Agratha",
    ["Warmonger Talarii"] = "Guerroyeuse Talarii",
    ["Warmonger Chuna"] = "Guerroyeuse Chuna",
    ["Grand Warmonger Tar'gresh"] = "Grand guerroyeur Tar'gresh",
    ["Conjured Fire Bomb"] = "Bombe incendiaire invoquée",
    ["Totem's Fire"] = "Totem de feu invoqué",
    -- Datachron messages.
    -- NPCSay messages.
    -- Cast.
    ["Incineration"] = "Incinération",
    ["Conjure Fire Elementals"] = "Invocation d'Élémentaires de feu",
    ["Meteor Storm"] = "Pluie de météores",
    -- Bar and messages.
    --["INTERRUPT !"] = "INTERRUPT !", -- TODO: French translation missing !!!!
    --["ELEMENTALS SOON"] = "ELEMENTALS SOON", -- TODO: French translation missing !!!!
    --["ELEMENTALS"] = "ELEMENTALS", -- TODO: French translation missing !!!!
    --["FIRST ABILITY"] = "FIRST ABILITY", -- TODO: French translation missing !!!!
    --["SECOND ABILITY"] = "SECOND ABILITY", -- TODO: French translation missing !!!!
    --["STORM !!"] = "STORM !!", -- TODO: French translation missing !!!!
    --["METEOR STORM"] = "METEOR STORM", -- TODO: French translation missing !!!!
    ["KNOCKBACK"] = "KNOCKBACK",
    --["BOMB"] = "BOMB", -- TODO: French translation missing !!!!
})
mod:RegisterGermanLocale({
    -- Unit names.
    ["Warmonger Agratha"] = "Kriegstreiberin Agratha",
    ["Warmonger Talarii"] = "Kriegstreiberin Talarii",
    ["Warmonger Chuna"] = "Kriegstreiberin Chuna",
    ["Grand Warmonger Tar'gresh"] = "Großer Kriegstreiber Tar’gresh",
    ["Conjured Fire Bomb"] = "Beschworene Feuerbombe",
    -- Datachron messages.
    -- NPCSay messages.
    -- Cast.
    ["Incineration"] = "Lodernde Flammen",
    ["Conjure Fire Elementals"] = "Feuerelementare beschwören",
    ["Meteor Storm"] = "Meteorsturm",
    -- Bar and messages.
    --["INTERRUPT !"] = "INTERRUPT !", -- TODO: German translation missing !!!!
    --["ELEMENTALS SOON"] = "ELEMENTALS SOON", -- TODO: German translation missing !!!!
    --["ELEMENTALS"] = "ELEMENTALS", -- TODO: German translation missing !!!!
    --["FIRST ABILITY"] = "FIRST ABILITY", -- TODO: German translation missing !!!!
    --["SECOND ABILITY"] = "SECOND ABILITY", -- TODO: German translation missing !!!!
    --["STORM !!"] = "STORM !!", -- TODO: German translation missing !!!!
    --["METEOR STORM"] = "METEOR STORM", -- TODO: German translation missing !!!!
    ["KNOCKBACK"] = "RÜCKSTOß",
    --["BOMB"] = "BOMB", -- TODO: German translation missing !!!!
})

--------------------------------------------------------------------------------
-- Locals
--

local prev, first = 0, true
local boss

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
    Print(("Module %s loaded"):format(mod.ModuleName))
    Apollo.RegisterEventHandler("RC_UnitStateChanged", "OnUnitStateChanged", self)
    Apollo.RegisterEventHandler("SPELL_CAST_START", "OnSpellCastStart", self)
    Apollo.RegisterEventHandler("DEBUFF_APPLIED", "OnDebuffApplied", self)
    Apollo.RegisterEventHandler("UNIT_HEALTH", "OnHealthChanged", self)
    Apollo.RegisterEventHandler("RC_UnitCreated", "OnUnitCreated", self)
end


--------------------------------------------------------------------------------
-- Event Handlers
--
function mod:OnUnitCreated(unit, sName)
    if sName == self.L["Conjured Fire Bomb"] then
        core:AddMsg("BOMB", self.L["BOMB"], 5, "Long", "Blue")
        core:AddBar("BOMB", self.L["BOMB"], first and 20 or 23)
    end
end


function mod:OnHealthChanged(unitName, health)
    if unitName == self.L["Warmonger Agratha"] and (health == 67 or health == 34) then
        core:AddMsg("ELEMENTALS", self.L["ELEMENTALS SOON"], 5, "Info")
    elseif unitName == self.L["Warmonger Talarii"] and (health == 67 or health == 34) then
        core:AddMsg("ELEMENTALS", self.L["ELEMENTALS SOON"], 5, "Info")
    end
end

function mod:OnSpellCastStart(unitName, castName, unit)
    if unitName == self.L["Warmonger Talarii"] then
        if castName == self.L["Incineration"] then
            core:AddMsg("KNOCK", self.L["INTERRUPT !"], 5, "Alert")
            core:AddBar("KNOCK", self.L["KNOCKBACK"], 29)
        elseif castName == self.L["Conjure Fire Elementals"] then
            core:AddMsg("ELEMENTALS", self.L["ELEMENTALS"], 5, "Alert")
            core:AddBar("1STAB", self.L["FIRST ABILITY"], 15)
            core:AddBar("2DNAB", self.L["SECOND ABILITY"], 24)
        end
    elseif unitName == self.L["Warmonger Agratha"] and castName == self.L["Conjure Fire Elementals"] then
        core:AddMsg("ELEMENTALS", self.L["ELEMENTALS"], 5, "Alert")
        core:AddBar("1STAB", self.L["FIRST ABILITY"], 15)
        core:AddBar("2DNAB", self.L["SECOND ABILITY"], 24)
    elseif unitName == self.L["Grand Warmonger Tar'gresh"] and castName == self.L["Meteor Storm"] then
        core:AddMsg("STORM", self.L["STORM !!"], 5, "RunAway")
        core:AddBar("STORM", self.L["METEOR STORM"], 43, 1)
    end
end


function mod:OnDebuffApplied(unitName, splId, unit)
    if splId == 49485 then
        local timeOfEvent = GameLib.GetGameTime()
        if timeOfEvent - prev > 10 then
            first = false
            core:AddBar("AIDS", "AIDS", (boss == self.L["Warmonger Agratha"]) and 20 or 18, 1)
        end
    end
end

function mod:OnUnitStateChanged(unit, bInCombat, sName)
    if unit:GetType() == "NonPlayer" and bInCombat then
        if sName == self.L["Warmonger Agratha"] then
            prev, first = 0, true
            boss = sName
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:RaidDebuff()
            core:AddBar("BOMB", self.L["BOMB"], 23)
        elseif sName == self.L["Warmonger Talarii"] then
            prev = 0
            boss = sName
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:RaidDebuff()
            core:AddBar("KNOCK", self.L["KNOCKBACK"], 23)
        elseif sName == self.L["Grand Warmonger Tar'gresh"] then
            core:AddUnit(unit)
            core:WatchUnit(unit)
            core:AddBar("STORM", self.L["METEOR STORM"], 26, 1)
        end
    end
end
