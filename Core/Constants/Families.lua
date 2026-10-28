local _, ns = ...

-- Hunter pet families by CreatureFamily ID (UnitCreatureFamily's second return, the same on every
-- client language), both ways: Beastkeeper.families.cat is 2, so code says families.cat instead of a
-- bare number; Beastkeeper.familyInfo[2] is what Beastkeeper knows of the Cat. Its specialization and diet
-- are as Wowhead's Forever hunter pet pages give them; the Fox, new in Forever, is on none of
-- them yet. Burning Crusade's families eat what that client's CreatureFamily.PetFoodMask says
-- (raw meat counting as meat). The name shown is the client's (Beastkeeper.FamilyName in
-- Core\Families.lua), English as fallback.
--
-- Before Wrath a family has no specialization but a category and fixed modifiers to the pet's
-- health, armor and damage, in percent (Beastkeeper.familyMods, the classic clients): as Icy Veins'
-- Classic and TBC Classic pet tables give them, which Wowhead's Classic pet guide bears out
-- (a Cat 1.10 damage and 2% less health, an Owl 1.07 damage).

---@type Addon
local Addon = ns

Addon.families = {
    wolf = 1,
    cat = 2,
    spider = 3,
    bear = 4,
    boar = 5,
    crocolisk = 6,
    carrionBird = 7,
    crab = 8,
    gorilla = 9,
    raptor = 11,
    tallstrider = 12,
    scorpid = 20,
    turtle = 21,
    bat = 24,
    hyena = 25,
    birdOfPrey = 26,
    windSerpent = 27,
    dragonhawk = 30,
    ravager = 31,
    warpStalker = 32,
    sporebat = 33,
    netherRay = 34,
    serpent = 35,
    fox = 40,
}

-- The specializations, as Wowhead sorts the families.
Addon.petSpecs = Addon.SelfKeyedEnum({ "ferocity", "cunning", "tenacity" }) --[[@as AddonPetSpecs]]

-- The kinds of food a family eats; upper-cased, each names a BEASTMAP_FOOD_* string, and the emote
-- lines' food types use them as keys.
Addon.diets = Addon.SelfKeyedEnum({ "meat", "fish", "cheese", "bread", "fungus", "fruit", "rawFish" }) --[[@as AddonDiets]]

local F, S, D = Addon.families, Addon.petSpecs, Addon.diets
local ALL = { D.meat, D.fish, D.cheese, D.bread, D.fungus, D.fruit }

---@type table<number, AddonFamilyInfo>
Addon.familyInfo = {
    [F.wolf] = { name = "Wolf", spec = S.ferocity, diet = { D.meat } },
    [F.cat] = { name = "Cat", spec = S.ferocity, diet = { D.meat, D.fish } },
    [F.spider] = { name = "Spider", spec = S.ferocity, diet = { D.meat } },
    [F.bear] = { name = "Bear", spec = S.tenacity, diet = ALL },
    [F.boar] = { name = "Boar", spec = S.cunning, diet = ALL },
    [F.crocolisk] = { name = "Crocolisk", spec = S.ferocity, diet = { D.meat, D.fish } },
    [F.carrionBird] = { name = "Carrion Bird", spec = S.ferocity, diet = { D.meat, D.fish } },
    [F.crab] = { name = "Crab", spec = S.tenacity, diet = { D.fish, D.bread, D.fungus, D.fruit } },
    [F.gorilla] = { name = "Gorilla", spec = S.ferocity, diet = { D.fungus, D.fruit } },
    [F.raptor] = { name = "Raptor", spec = S.cunning, diet = { D.meat } },
    [F.tallstrider] = { name = "Tallstrider", spec = S.ferocity, diet = { D.cheese, D.fungus, D.fruit } },
    [F.scorpid] = { name = "Scorpid", spec = S.ferocity, diet = { D.meat } },
    [F.turtle] = { name = "Turtle", spec = S.tenacity, diet = { D.fish, D.fungus, D.fruit, D.rawFish } },
    [F.bat] = { name = "Bat", spec = S.ferocity, diet = { D.fungus, D.fruit } },
    [F.hyena] = { name = "Hyena", spec = S.cunning, diet = { D.meat, D.fruit } },
    [F.birdOfPrey] = { name = "Bird of Prey", spec = S.cunning, diet = { D.meat } },
    [F.windSerpent] = { name = "Wind Serpent", spec = S.ferocity, diet = { D.fish, D.cheese, D.bread } },
    -- Burning Crusade's families, without a specialization (pet talents came with Wrath).
    [F.dragonhawk] = { name = "Dragonhawk", diet = { D.meat, D.fish, D.fruit, D.rawFish }, client = "tbc" },
    [F.ravager] = { name = "Ravager", diet = { D.meat }, client = "tbc" },
    [F.warpStalker] = { name = "Warp Stalker", diet = { D.fish, D.fruit, D.rawFish }, client = "tbc" },
    [F.sporebat] = { name = "Sporebat", diet = { D.cheese, D.bread, D.fungus, D.fruit }, client = "tbc" },
    [F.netherRay] = { name = "Nether Ray", diet = { D.meat }, client = "tbc" },
    [F.serpent] = { name = "Serpent", diet = { D.meat, D.fish, D.rawFish }, client = "tbc" },
    [F.fox] = { name = "Fox", client = "forever" },
}

-- The categories a family has before Wrath.
Addon.petCategories = Addon.SelfKeyedEnum({ "offense", "defense", "general" }) --[[@as AddonPetCategories]]

local K = Addon.petCategories

-- Per family its category and modifiers in percent, on the classic clients (the comment above).
---@type table<number, AddonFamilyMods>
Addon.familyMods = {
    [F.bat] = { category = K.offense, health = 0, armor = 0, damage = 7 },
    [F.bear] = { category = K.defense, health = 8, armor = 5, damage = -9 },
    [F.boar] = { category = K.defense, health = 4, armor = 9, damage = -10 },
    [F.carrionBird] = { category = K.general, health = 0, armor = 5, damage = 0 },
    [F.cat] = { category = K.offense, health = -2, armor = 0, damage = 10 },
    [F.crab] = { category = K.defense, health = -4, armor = 13, damage = -5 },
    [F.crocolisk] = { category = K.defense, health = -5, armor = 10, damage = 0 },
    [F.dragonhawk] = { category = K.general, health = 0, armor = 0, damage = 0 },
    [F.gorilla] = { category = K.defense, health = 4, armor = 0, damage = 2 },
    [F.hyena] = { category = K.general, health = 0, armor = 5, damage = 0 },
    [F.netherRay] = { category = K.defense, health = 10, armor = -10, damage = 3 },
    [F.birdOfPrey] = { category = K.offense, health = 0, armor = 0, damage = 7 },
    [F.raptor] = { category = K.offense, health = -5, armor = 3, damage = 10 },
    [F.ravager] = { category = K.offense, health = -7, armor = 5, damage = 10 },
    [F.scorpid] = { category = K.defense, health = 0, armor = 10, damage = -6 },
    [F.serpent] = { category = K.general, health = 0, armor = 0, damage = 0 },
    [F.spider] = { category = K.offense, health = 0, armor = 0, damage = 7 },
    [F.sporebat] = { category = K.general, health = 0, armor = 0, damage = 0 },
    [F.tallstrider] = { category = K.defense, health = 5, armor = 0, damage = 0 },
    [F.turtle] = { category = K.defense, health = 0, armor = 13, damage = -10 },
    [F.warpStalker] = { category = K.defense, health = 0, armor = 5, damage = -6 },
    [F.windSerpent] = { category = K.offense, health = 0, armor = 0, damage = 7 },
    [F.wolf] = { category = K.general, health = 0, armor = 5, damage = 0 },
}
