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
