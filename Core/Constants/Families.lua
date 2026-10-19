local _, ns = ...

-- Hunter pet families by CreatureFamily ID (UnitCreatureFamily's second return, the same on every
-- client language), both ways: Kennel.families.cat is 2, so code says families.cat instead of a
-- bare number; Kennel.familyInfo[2] is what Kennel knows of the Cat. Its specialization and diet
-- are as Wowhead's Forever hunter pet pages give them; the Fox, new in Forever, is on none of
-- them yet. The name shown is the client's (Kennel.FamilyName in Core\Families.lua), English as
-- fallback.

---@type Kennel
local Kennel = ns

Kennel.families = {
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
    fox = 40,
}

-- The specializations, as Wowhead sorts the families.
Kennel.petSpecs = { ferocity = "ferocity", cunning = "cunning", tenacity = "tenacity" }

-- The kinds of food a family eats; upper-cased, each names a BEASTMAP_FOOD_* string, and the emote
-- lines' food types use them as keys.
Kennel.diets = {
    meat = "meat",
    fish = "fish",
    cheese = "cheese",
    bread = "bread",
    fungus = "fungus",
    fruit = "fruit",
    rawFish = "rawFish",
}

local F, S, D = Kennel.families, Kennel.petSpecs, Kennel.diets
local ALL = { D.meat, D.fish, D.cheese, D.bread, D.fungus, D.fruit }

---@type table<number, KennelFamilyInfo>
Kennel.familyInfo = {
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
    [F.fox] = { name = "Fox" },
}
