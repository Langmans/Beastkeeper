local _, ns = ...

-- Names for the game's bare values that no Enum of the game covers, so code says
-- Kennel.happiness.content instead of 2. Each holds what the API it is named after gives or takes.

---@type Kennel
local Kennel = ns

-- GetPetHappiness.
Kennel.happiness = { unhappy = 1, content = 2, happy = 3 }

-- UnitSex.
Kennel.sex = { unknown = 1, male = 2, female = 3 }

-- UnitFactionGroup's first return, the same on every client language.
Kennel.factions = { alliance = "Alliance", horde = "Horde" }

-- The kinds of ammo by their Projectile item subclass, as GetItemInfoInstant gives it.
Kennel.ammoKinds = { arrow = 2, bullet = 3 }

-- SetRaidTarget and /tm.
Kennel.raidMarks = { star = 1, circle = 2, diamond = 3, triangle = 4, moon = 5, square = 6, cross = 7, skull = 8 }
