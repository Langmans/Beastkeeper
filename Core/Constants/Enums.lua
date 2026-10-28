local _, ns = ...

-- Names for the game's bare values that no Enum of the game covers, so code says
-- Beastkeeper.happiness.content instead of 2. Each holds what the API it is named after gives or takes.

---@type Addon
local Addon = ns

-- GetPetHappiness.
Addon.happiness = { unhappy = 1, content = 2, happy = 3 }

-- UnitSex.
Addon.sex = { unknown = 1, male = 2, female = 3 }

-- UnitFactionGroup's first return, the same on every client language.
Addon.factions = { alliance = "Alliance", horde = "Horde" }

-- The kinds of ammo by their Projectile item subclass, as GetItemInfoInstant gives it.
Addon.ammoKinds = { arrow = 2, bullet = 3 }

-- SetRaidTarget and /tm.
Addon.raidMarks = { star = 1, circle = 2, diamond = 3, triangle = 4, moon = 5, square = 6, cross = 7, skull = 8 }
