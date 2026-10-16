local _, ns = ...

-- What several modules ask about the pet and its spells: names and icons across client
-- generations, the pet's family, and the sound a pet of that family makes (the tables are in
-- Sounds.lua).

---@type Kennel
local Kennel = ns

---Spell name and icon across client generations: C_Spell on newer clients, GetSpellInfo on older
---ones. Both nil when the client knows neither.
---@param id number
---@return string? name
---@return (number|string)? icon
function Kennel.SpellInfo(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id), C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(id)
        return name, icon
    end
    return nil, nil
end

---The active pet's CreatureFamily ID (1 wolf, 2 cat, ...), the same on every client language;
---nil without a pet.
---@return number?
function Kennel.PetFamilyID()
    if not UnitExists("pet") then return nil end
    local _, familyID = UnitCreatureFamily("pet")
    return tonumber(familyID)
end

---The attack call of the active pet's family, as a toast sound; nil without a pet or for a family
---whose call is not known.
---@return KennelSound?
function Kennel.PetAggroSound()
    local familyID = Kennel.PetFamilyID()
    local file = familyID and Kennel.sounds.AGGRO_PER_FAMILY[familyID]
    return file and { file = file } or nil
end
