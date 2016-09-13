----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
-- Using the Large Training Grounds fabkit it is possible to spawn enemies.
-- There are 4 different modes: easy, normal, hard, elite. In each mode you get
-- a random enemy out of 3 possibilities.
-- These enemies have atleast one cast each and some of them have buffs and debuffs
-- Easy:
-- Chompacabra: Applies bleed debuff on the player
-- Chompacabra: Applies melt debuff on the player
-- Moodie: Applies melt debuff on the player
-- Hard:
-- Krogg: Applies a crit buff on himself
--
-- It's not possible to control what enemy you want to get so it's recommended
-- to use the easy mode since there are 2 mobs there that will apply debuffs
-- on the player.
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
--@alpha@
local mod = core:NewEncounter("HousingTest", 36, 0, 60)
--@end-alpha@
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
local ALL_MOBS = {
  -- Easy.
  "unit.chompacabra",
  "unit.moodie",
  "unit.aggressorbot",
  -- Normal.
  "unit.bandit",
  "unit.girrok",
  "unit.shootbot",
  -- Hard.
  "unit.pumera",
  "unit.osun",
  "unit.krogg",
  -- Elite.
  "unit.ravenok",
  "unit.pell",
  "unit.titan",
}

mod:RegisterTrigMob("ANY", ALL_MOBS)
mod:RegisterEnglishLocale({
    -- Unit names.
    -- Easy.
    ["unit.chompacabra"] = "Holographic Chompacabra",
    ["unit.moodie"] = "Holographic Moodie",
    ["unit.aggressorbot"] = "Holographic Aggressorbot",
    -- Normal.
    ["unit.bandit"] = "Holographic Bandit",
    ["unit.girrok"] = "Holographic Girrok",
    ["unit.shootbot"] = "Holographic Shootbot",
    -- Hard.
    ["unit.pumera"] = "Holographic Pumera",
    ["unit.osun"] = "Holographic Osun",
    ["unit.krogg"] = "Holographic Krogg",
    -- Elite.
    ["unit.ravenok"] = "Holographic Ravenok",
    ["unit.pell"] = "Holographic Pell",
    ["unit.titan"] = "Holographic Titan",
    ["unit.buffer"] = "Invisible Unit s71975 - Aquatic Buffer", -- titan cast,

    ["unit.invis.0"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    -- Cast names.
    ["cast.chompacabra.frenzy"] = "Feeding Frenzy",
    ["cast.chompacabra.trap"] = "Snap Trap",
    ["cast.moodie.firestorm"] = "Firestorm",
    ["cast.moodie.fissure"] = "Erupting Fissure",
    ["cast.shootbot.dash"] = "Slasher Dash",
    ["cast.shootbot.jump"] = "Jump Shot",

    ["unit.bandit.blast"] = "Blast Shot",
    ["unit.girrok.roar"] = "Roar",
    ["unit.aggressorbot.spin"] = "Mauling Spin",

    ["unit.pumera.pounce"] = "Pride Pounce",
    ["unit.pumera.frenzy"] = "Frenzy of the Feline",
    ["unit.osun.firestorm"] = "Firestorm",
    ["unit.osun.fisure"] = "Erupting Fissure",
    ["unit.krogg.rush"] = "Crushing Rush",
    ["unit.krogg.flurry"] = "Crushing Flurry",
    ["unit.krogg.assault"] = "Focused Assault",

    ["unit.ravenok.head_shoulders"] = "Head and Shoulders",
    ["unit.ravenok.tooth_nail"] = "Tooth and Nail",
    ["unit.ravenok.winds"] = "Tail Winds",
    ["unit.ravenok.rush"] = "Ravenok Rush",
    ["unit.titan.slash"] = "Shellark Slash",
    ["unit.titan.strike"] = "Trident Strike",
    ["unit.titan.buffer"] = "Aquatic Buffer",
    ["unit.pell.vortex"] = "Swirling Vortex",
  })

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local BUFF_KROGG_FOCUSED_ASSAULT = 72202
--moodie and chompacabra debuff
local DEBUFF_MELT = 50233
local DEBUFF_CHOMPACABRA_BLEED = 43759
----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()

end

mod:RegisterUnitEvents(ALL_MOBS,{
    ["OnUnitCreated"] = function (_, _, unit)
      core:WatchUnit(unit)
      core:AddUnit(unit)
    end,
  }
)
