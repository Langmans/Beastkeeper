local _, ns = ...

-- A pet family's ID, name and specialization, from Kennel.familyInfo (Constants\Families.lua) and
-- the client.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local S = Kennel.petSpecs
local SPEC_NAMES =
    { [S.ferocity] = L.FAMILY_FEROCITY, [S.cunning] = L.FAMILY_CUNNING, [S.tenacity] = L.FAMILY_TENACITY }

---A family's ID from its name as Kennel.FamilyName gives it (a pet's UnitCreatureFamily, a stable
---list's familyName); nil for a name Kennel does not know.
---@param name string?
---@return number?
function Kennel.FamilyID(name)
    if not name then return nil end
    for familyID in pairs(Kennel.familyInfo) do
        if Kennel.FamilyName(familyID) == name then return familyID end
    end
end

---A family's specialization, named: Ferocity, Cunning or Tenacity, as Wowhead sorts the families
---(the client says "Default" for every pet); nil without one.
---@param familyID number?
---@return string?
function Kennel.SpecName(familyID)
    local info = familyID and Kennel.familyInfo[familyID]
    return info and info.spec and SPEC_NAMES[info.spec]
end

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
