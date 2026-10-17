local _, ns = ...

-- What the emote lines are picked by, the same in every language: food groups and types by item,
-- pet families by ID. Each Lines\<locale>.lua adds its lines to M.Lines.

---@type Kennel
local Kennel = ns
local M = Kennel:GetModule("FeedEmotes") --[[@as KennelFeedEmotes]]

---Locale code ("enUS", "deDE", ...) -> that language's emote lines.
---@type table<string, KennelEmoteLines>
M.Lines = {}

-- Item ID -> food group used as key in each locale's `emotes.food` table:
-- jokes about one particular food. An item can also have a type (below).
---@type table<number, string>
M.FoodGroups = {
    [7974] = "zesty", -- Zesty Clam Meat
    [12037] = "mystery", -- Mystery Meat
    [44072] = "mystery", -- Roasted Mystery Beast
    [59232] = "mystery", -- Unidentifiable Meat Dish
    [12217] = "chili", -- Dragonbreath Chili
    [4538] = "watermelon", -- Snapvine Watermelon
    [8950] = "cherryPie", -- Homemade Cherry Pie
    [27659] = "warpBurger", -- Warp Burger
    [41808] = "crunchy", -- Bonescale Snapper
    [41814] = "minnow", -- Glassfin Minnow
    [43647] = "minnow", -- Shimmering Minnow
}

-- Item ID -> food type used as key in each locale's `emotes.foodType` table.
-- The client offers no way to ask an item's type (C_PetInfo.CanPetEatItem only
-- says yes or no), so this lists the food sold by vendors on Forever (Wowhead,
-- forever/items/consumables/food-and-drinks, "Sold by a vendor"), classified
-- by name. Holiday, faire and unclear items are left out.
---@type table<number, string>
M.FoodTypes = {
    -- Bread
    [4540] = "bread", -- Tough Hunk of Bread
    [4541] = "bread", -- Freshly Baked Bread
    [4542] = "bread", -- Moist Cornbread
    [4544] = "bread", -- Mulgore Spice Bread
    [4601] = "bread", -- Soft Banana Bread
    [8950] = "bread", -- Homemade Cherry Pie
    [252026] = "bread", -- Gustberry Pie
    [278119] = "bread", -- Bread with Butter
    -- Meat
    [117] = "meat", -- Tough Jerky
    [2287] = "meat", -- Haunch of Meat
    [3770] = "meat", -- Mutton Chop
    [3771] = "meat", -- Wild Hog Shank
    [4599] = "meat", -- Cured Ham Steak
    [8952] = "meat", -- Roasted Quail
    [11444] = "meat", -- Grim Guzzler Boar
    [17119] = "meat", -- Deeprun Rat Kabob
    [252029] = "meat", -- Hippogryph Flank
    [278121] = "meat", -- Smoked Sausage
    -- Fish
    [787] = "fish", -- Slitherskin Mackerel
    [4592] = "fish", -- Longjaw Mud Snapper
    [4593] = "fish", -- Bristle Whisker Catfish
    [4594] = "fish", -- Rockscale Cod
    [8957] = "fish", -- Spinefin Halibut
    [21552] = "fish", -- Striped Yellowtail
    -- Cheese
    [414] = "cheese", -- Dalaran Sharp
    [422] = "cheese", -- Dwarven Mild
    [1707] = "cheese", -- Stormwind Brie
    [2070] = "cheese", -- Darnassian Bleu
    [3927] = "cheese", -- Fine Aged Cheddar
    [8932] = "cheese", -- Alterac Swiss
    [252030] = "cheese", -- Pungent Skycheddar
    -- Fruit
    [4536] = "fruit", -- Shiny Red Apple
    [4537] = "fruit", -- Tel'Abim Banana
    [4538] = "fruit", -- Snapvine Watermelon
    [4539] = "fruit", -- Goldenbark Apple
    [4602] = "fruit", -- Moon Harvest Pumpkin
    [8953] = "fruit", -- Deep Fried Plantains
    [13810] = "fruit", -- Blessed Sunfruit
    [252032] = "fruit", -- Red Delicious Stormapple
    -- Fungus
    [4604] = "fungus", -- Forest Mushroom Cap
    [4605] = "fungus", -- Red-speckled Mushroom
    [4606] = "fungus", -- Spongy Morel
    [4607] = "fungus", -- Delicious Cave Mold
    [4608] = "fungus", -- Raw Black Truffle
    [8948] = "fungus", -- Dried King Bolete
}

-- CreatureFamily IDs, the second return of UnitCreatureFamily("pet"); the
-- same on every client language, unlike the family name.
-- Source: the CreatureFamily DB2 table (wago.tools/db2/CreatureFamily).
M.Family = {
    -- The 18 families tameable on Forever (Wowhead, forever/hunter-pets; Fox is new there).
    WOLF = 1,
    CAT = 2,
    SPIDER = 3,
    BEAR = 4,
    BOAR = 5,
    CROCOLISK = 6,
    CARRION_BIRD = 7,
    CRAB = 8,
    GORILLA = 9,
    RAPTOR = 11,
    TALLSTRIDER = 12,
    SCORPID = 20,
    TURTLE = 21,
    BAT = 24,
    HYENA = 25,
    BIRD_OF_PREY = 26, -- "Owl" before Forever renamed it
    WIND_SERPENT = 27,
    FOX = 40,
    -- Wrath exotics, kept from Feed-O-Matic for later Classic flavors.
    CHIMAERA = 38,
    DEVILSAUR = 39,
    CORE_HOUND = 45,
}

-- Families no hunter can tame on Forever: own lines can still name them
-- ([chimaera] etc.), but the options panel offers no checkbox for them.
M.ExoticFamily = {
    [M.Family.CHIMAERA] = true,
    [M.Family.DEVILSAUR] = true,
    [M.Family.CORE_HOUND] = true,
}
