local _, ns = ...

-- What several modules ask about the pet and its spells: names and icons across client
-- generations, the pet's family, and the sound a pet of that family makes (the tables are in
-- Sounds.lua).

---@type Kennel
local Kennel = ns

---The rank text of a spell ("Rank 2", "Rang 2"); nil for a spell without ranks.
---@param id number
---@return string?
local function SpellRank(id)
    ---@type (fun(id: number): string?)?
    local subtext = (C_Spell and C_Spell.GetSpellSubtext) or GetSpellSubtext
    local rank = subtext and subtext(id)
    return rank ~= "" and rank or nil
end

---Spell name, icon and rank across client generations: C_Spell on newer clients, GetSpellInfo on
---older ones. All nil when the client knows neither.
---@param id number
---@return string? name
---@return (number|string)? icon
---@return string? rank the rank text ("Rank 2"), nil when the spell has none
function Kennel.SpellInfo(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id), C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id), SpellRank(id)
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(id)
        return name, icon, SpellRank(id)
    end
    return nil, nil, nil
end

---The spells in the active pet's spellbook by name, each with its ID, rank and icon; empty
---without a pet or without C_SpellBook. Pet commands (Attack, Follow) have no spell and are left
---out, as is an entry that cannot be read.
---@return table<string, KennelPetSpell>
function Kennel.PetSpells()
    ---@type table<string, KennelPetSpell>
    local spells = {}
    local book = C_SpellBook
    if not (book and book.GetSpellBookItemInfo and book.HasPetSpells) then return spells end
    for index = 1, tonumber((book.HasPetSpells())) or 0 do
        local ok, info = pcall(book.GetSpellBookItemInfo, index, Enum.SpellBookSpellBank.Pet)
        local id = ok and info and info.spellID
        if id then
            local _, icon, rank = Kennel.SpellInfo(id)
            local subName = info.subName ~= "" and info.subName or nil
            spells[info.name] = { id = id, rank = subName or rank, icon = icon }
        end
    end
    return spells
end

---The active pet's free training points (total minus used), from C_PetInfo on WoW: Forever or
---the global on older clients; nil without a pet, without the API or when the client hides them.
---@return number?
function Kennel.PetTrainingPoints()
    ---@type (fun(): GameValue, GameValue)?
    local get = (C_PetInfo and C_PetInfo.GetPetTrainingPoints) or GetPetTrainingPoints
    if not get or not UnitExists("pet") then return nil end
    local total, used = get()
    if type(total) ~= "number" or not Kennel.Readable(total) then return nil end
    return math.max(0, total - (tonumber(used) or 0))
end

---The active pet's CreatureFamily ID (1 wolf, 2 cat, ...), the same on every client language;
---nil without a pet.
---@return number?
function Kennel.PetFamilyID()
    if not UnitExists("pet") then return nil end
    local _, familyID = UnitCreatureFamily("pet")
    return tonumber(familyID)
end

---A sound of the active pet's family, as a toast sound; nil without a pet or for a family without
---that sound.
---@param kind "AGGRO"|"DEATH"|"WOUND" its attack call, death sound or wound cry
---@return KennelSound?
function Kennel.PetSound(kind)
    local familyID = Kennel.PetFamilyID()
    local sounds = Kennel.sounds[kind .. "_PER_FAMILY"] --[[@as table<number, number>]]
    local file = familyID and sounds[familyID]
    return file and { file = file } or nil
end

---Whether the addon may read a value: WoW: Forever hides some (health, autocast) in combat. A
---client without canaccessvalue hides nothing.
---@param value GameValue
---@return boolean
function Kennel.Readable(value)
    return not canaccessvalue or canaccessvalue(value)
end
