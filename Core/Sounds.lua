local _, ns = ...

-- Pet sounds by family (Beastkeeper.families, Families.lua), as FileDataIDs for PlaySoundFile. One
-- table per kind of sound, named <KIND>_PER_FAMILY; Pet.lua picks the active pet's. FileDataIDs
-- from the wago.tools community listfile, with the file names so they can be looked up again.

---@type Addon
local Addon = ns
local F = Addon.families

Addon.sounds = {}

-- The call a pet gives when it is sent to attack. None was found for the Crocolisk, Scorpid and
-- Bat.
---@type table<number, number>
Addon.sounds.AGGRO_PER_FAMILY = {
    [F.wolf] = 564215, -- sound/creature/wolf/mwolfaggro1.ogg
    [F.cat] = 562387, -- sound/creature/tiger/mtigeraggroa.ogg
    [F.spider] = 561415, -- sound/creature/tarantula/mtarantulaaggroa.ogg
    [F.bear] = 544959, -- sound/creature/bear/mbearaggroa.ogg
    [F.boar] = 545134, -- sound/creature/boar/mwildboaraggro1.ogg
    [F.carrionBird] = 545937, -- sound/creature/carrion/mcarrionaggroa.ogg
    [F.crab] = 546423, -- sound/creature/crab/crabaggro.ogg
    [F.gorilla] = 550967, -- sound/creature/gorilla/gorillaaggroa.ogg
    [F.raptor] = 558877, -- sound/creature/raptor/mraptoraggroa.ogg
    [F.tallstrider] = 561390, -- sound/creature/tallstrider/tallstrideraggroa.ogg
    [F.turtle] = 559878, -- sound/creature/seaturtle/seaturtleaggroa.ogg
    [F.hyena] = 552339, -- sound/creature/hyena/hyenaaggroa.ogg
    [F.birdOfPrey] = 557977, -- sound/creature/owl/owlaggro.ogg
    [F.windSerpent] = 559967, -- sound/creature/serpent/serpentaggro.ogg
    [F.fox] = 3593144, -- sound/creature/fox2/mon_fox2_aggro_00_157872.ogg
}

-- The sound a pet makes when it dies. The Hyena has only later files, and the Crocolisk, Scorpid
-- and Bat have none of their own.
---@type table<number, number>
Addon.sounds.DEATH_PER_FAMILY = {
    [F.wolf] = 564219, -- sound/creature/wolf/mwolfdeath1.ogg
    [F.cat] = 562391, -- sound/creature/tiger/mtigerdeatha.ogg
    [F.spider] = 561420, -- sound/creature/tarantula/mtarantuladeath1a.ogg
    [F.bear] = 544952, -- sound/creature/bear/mbeardeatha.ogg
    [F.boar] = 545132, -- sound/creature/boar/mwildboardeath1.ogg
    [F.carrionBird] = 545944, -- sound/creature/carrion/mcarriondeatha.ogg
    [F.crab] = 546431, -- sound/creature/crab/crabdeatha.ogg
    [F.gorilla] = 550959, -- sound/creature/gorilla/gorilladeatha.ogg
    [F.raptor] = 558876, -- sound/creature/raptor/mraptordeatha.ogg
    [F.tallstrider] = 561391, -- sound/creature/tallstrider/tallstriderdeatha.ogg
    [F.turtle] = 559874, -- sound/creature/seaturtle/seaturtledeatha.ogg
    [F.birdOfPrey] = 557976, -- sound/creature/owl/owldeath.ogg
    [F.windSerpent] = 559971, -- sound/creature/serpent/serpentdeath.ogg
    [F.fox] = 3593200, -- sound/creature/fox2/mon_fox2_death_00_157876.ogg
}

-- The cry of a pet critically wounded. The Crocolisk, Scorpid and Bat have none of their own.
---@type table<number, number>
Addon.sounds.WOUND_PER_FAMILY = {
    [F.wolf] = 564231, -- sound/creature/wolf/mwolfwoundcritical1.ogg
    [F.cat] = 562395, -- sound/creature/tiger/mtigerwoundcriticala.ogg
    [F.spider] = 561419, -- sound/creature/tarantula/mtarantulawoundcritical1a.ogg
    [F.bear] = 544958, -- sound/creature/bear/mbearwoundcriticala.ogg
    [F.boar] = 545130, -- sound/creature/boar/mwildboarwoundcritical1.ogg
    [F.carrionBird] = 545936, -- sound/creature/carrion/mcarrionwoundcriticala.ogg
    [F.crab] = 546422, -- sound/creature/crab/crabwoundcrit.ogg
    [F.gorilla] = 550964, -- sound/creature/gorilla/gorillawoundcrit.ogg
    [F.raptor] = 558875, -- sound/creature/raptor/mraptorwoundcriticala.ogg
    [F.tallstrider] = 561389, -- sound/creature/tallstrider/tallstriderwoundcrit.ogg
    [F.turtle] = 559875, -- sound/creature/seaturtle/seaturtlewoundcrita.ogg
    [F.hyena] = 552336, -- sound/creature/hyena/hyenawoundcrit.ogg
    [F.birdOfPrey] = 557975, -- sound/creature/owl/owlwoundcrit.ogg
    [F.windSerpent] = 559974, -- sound/creature/serpent/serpentwoundcrit.ogg
    [F.fox] = 3593220, -- sound/creature/fox2/mon_fox2_woundcritical_00_157879.ogg
}
