local _, ns = ...

-- Hunter pet families by CreatureFamily ID (UnitCreatureFamily's second return, the same on every
-- client language), both ways: Kennel.families.cat is 2, so code says families.cat instead of a
-- bare number; Kennel.familyInfo[2] is what Kennel knows of the Cat. Its specialization and diet
-- are as Wowhead's Forever hunter pet pages give them; the Fox, new in Forever, is on none of
-- them yet. The name shown is the client's (Kennel.FamilyName), English as fallback.

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

local F = Kennel.families

---@type table<number, KennelFamilyInfo>
Kennel.familyInfo = {
    [F.wolf] = { name = "Wolf", spec = "ferocity", diet = { "meat" } },
    [F.cat] = { name = "Cat", spec = "ferocity", diet = { "meat", "fish" } },
    [F.spider] = { name = "Spider", spec = "ferocity", diet = { "meat" } },
    [F.bear] = { name = "Bear", spec = "tenacity", diet = { "meat", "fish", "cheese", "bread", "fungus", "fruit" } },
    [F.boar] = { name = "Boar", spec = "cunning", diet = { "meat", "fish", "cheese", "bread", "fungus", "fruit" } },
    [F.crocolisk] = { name = "Crocolisk", spec = "ferocity", diet = { "meat", "fish" } },
    [F.carrionBird] = { name = "Carrion Bird", spec = "ferocity", diet = { "meat", "fish" } },
    [F.crab] = { name = "Crab", spec = "tenacity", diet = { "fish", "bread", "fungus", "fruit" } },
    [F.gorilla] = { name = "Gorilla", spec = "ferocity", diet = { "fungus", "fruit" } },
    [F.raptor] = { name = "Raptor", spec = "cunning", diet = { "meat" } },
    [F.tallstrider] = { name = "Tallstrider", spec = "ferocity", diet = { "cheese", "fungus", "fruit" } },
    [F.scorpid] = { name = "Scorpid", spec = "ferocity", diet = { "meat" } },
    [F.turtle] = { name = "Turtle", spec = "tenacity", diet = { "fish", "fungus", "fruit", "rawFish" } },
    [F.bat] = { name = "Bat", spec = "ferocity", diet = { "fungus", "fruit" } },
    [F.hyena] = { name = "Hyena", spec = "cunning", diet = { "meat", "fruit" } },
    [F.birdOfPrey] = { name = "Bird of Prey", spec = "cunning", diet = { "meat" } },
    [F.windSerpent] = { name = "Wind Serpent", spec = "ferocity", diet = { "fish", "cheese", "bread" } },
    [F.fox] = { name = "Fox" },
}

---A family's name as the client words it, else the English one; nil for a family Kennel does not
---know.
---@param familyID number
---@return string?
function Kennel.FamilyName(familyID)
    local info = C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo(familyID)
    if info and info.name then return info.name end
    local known = Kennel.familyInfo[familyID]
    return known and known.name
end
