local _, ns = ...

-- Pet sounds by CreatureFamily ID (the second return of UnitCreatureFamily, the same on every
-- client language), as FileDataIDs for PlaySoundFile. One table per kind of sound, named
-- <KIND>_PER_FAMILY; Pet.lua picks the active pet's. FileDataIDs from the wago.tools community
-- listfile, with the file names so they can be looked up again.

---@type Kennel
local Kennel = ns

Kennel.sounds = {}

-- The call a pet gives when it is sent to attack. None was found for Crocolisk (6), Scorpid (20)
-- and Bat (24).
---@type table<number, number>
Kennel.sounds.AGGRO_PER_FAMILY = {
    [1] = 564215, -- Wolf: sound/creature/wolf/mwolfaggro1.ogg
    [2] = 562387, -- Cat: sound/creature/tiger/mtigeraggroa.ogg
    [3] = 561415, -- Spider: sound/creature/tarantula/mtarantulaaggroa.ogg
    [4] = 544959, -- Bear: sound/creature/bear/mbearaggroa.ogg
    [5] = 545134, -- Boar: sound/creature/boar/mwildboaraggro1.ogg
    [7] = 545937, -- Carrion Bird: sound/creature/carrion/mcarrionaggroa.ogg
    [8] = 546423, -- Crab: sound/creature/crab/crabaggro.ogg
    [9] = 550967, -- Gorilla: sound/creature/gorilla/gorillaaggroa.ogg
    [11] = 558877, -- Raptor: sound/creature/raptor/mraptoraggroa.ogg
    [12] = 561390, -- Tallstrider: sound/creature/tallstrider/tallstrideraggroa.ogg
    [21] = 559878, -- Turtle: sound/creature/seaturtle/seaturtleaggroa.ogg
    [25] = 552339, -- Hyena: sound/creature/hyena/hyenaaggroa.ogg
    [26] = 557977, -- Bird of Prey: sound/creature/owl/owlaggro.ogg
    [27] = 559967, -- Wind Serpent: sound/creature/serpent/serpentaggro.ogg
}

-- The sound a pet makes when it dies. Hyena (25) has only later files, and Crocolisk, Scorpid and
-- Bat have none of their own.
---@type table<number, number>
Kennel.sounds.DEATH_PER_FAMILY = {
    [1] = 564219, -- Wolf: sound/creature/wolf/mwolfdeath1.ogg
    [2] = 562391, -- Cat: sound/creature/tiger/mtigerdeatha.ogg
    [3] = 561420, -- Spider: sound/creature/tarantula/mtarantuladeath1a.ogg
    [4] = 544952, -- Bear: sound/creature/bear/mbeardeatha.ogg
    [5] = 545132, -- Boar: sound/creature/boar/mwildboardeath1.ogg
    [7] = 545944, -- Carrion Bird: sound/creature/carrion/mcarriondeatha.ogg
    [8] = 546431, -- Crab: sound/creature/crab/crabdeatha.ogg
    [9] = 550959, -- Gorilla: sound/creature/gorilla/gorilladeatha.ogg
    [11] = 558876, -- Raptor: sound/creature/raptor/mraptordeatha.ogg
    [12] = 561391, -- Tallstrider: sound/creature/tallstrider/tallstriderdeatha.ogg
    [21] = 559874, -- Turtle: sound/creature/seaturtle/seaturtledeatha.ogg
    [26] = 557976, -- Bird of Prey: sound/creature/owl/owldeath.ogg
    [27] = 559971, -- Wind Serpent: sound/creature/serpent/serpentdeath.ogg
}

-- The cry of a pet critically wounded. Crocolisk, Scorpid and Bat have none of their own.
---@type table<number, number>
Kennel.sounds.WOUND_PER_FAMILY = {
    [1] = 564231, -- Wolf: sound/creature/wolf/mwolfwoundcritical1.ogg
    [2] = 562395, -- Cat: sound/creature/tiger/mtigerwoundcriticala.ogg
    [3] = 561419, -- Spider: sound/creature/tarantula/mtarantulawoundcritical1a.ogg
    [4] = 544958, -- Bear: sound/creature/bear/mbearwoundcriticala.ogg
    [5] = 545130, -- Boar: sound/creature/boar/mwildboarwoundcritical1.ogg
    [7] = 545936, -- Carrion Bird: sound/creature/carrion/mcarrionwoundcriticala.ogg
    [8] = 546422, -- Crab: sound/creature/crab/crabwoundcrit.ogg
    [9] = 550964, -- Gorilla: sound/creature/gorilla/gorillawoundcrit.ogg
    [11] = 558875, -- Raptor: sound/creature/raptor/mraptorwoundcriticala.ogg
    [12] = 561389, -- Tallstrider: sound/creature/tallstrider/tallstriderwoundcrit.ogg
    [21] = 559875, -- Turtle: sound/creature/seaturtle/seaturtlewoundcrita.ogg
    [25] = 552336, -- Hyena: sound/creature/hyena/hyenawoundcrit.ogg
    [26] = 557975, -- Bird of Prey: sound/creature/owl/owlwoundcrit.ogg
    [27] = 559974, -- Wind Serpent: sound/creature/serpent/serpentwoundcrit.ogg
}
