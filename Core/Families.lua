local _, ns = ...

-- A pet family's ID, name and specialization, from Kennel.familyInfo (Constants\Families.lua) and
-- the client.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local S = Kennel.petSpecs
local SPEC_NAMES =
    { [S.ferocity] = L.FAMILY_FEROCITY, [S.cunning] = L.FAMILY_CUNNING, [S.tenacity] = L.FAMILY_TENACITY }
local K = Kennel.petCategories
local CATEGORY_NAMES =
    { [K.offense] = L.FAMILY_OFFENSE, [K.defense] = L.FAMILY_DEFENSE, [K.general] = L.FAMILY_GENERAL }
-- A family's modifiers in words, refilled for each one.
---@type string[]
local parts = {}

---A family's category and modifiers before Wrath (Kennel.familyMods): "Offense: +10% damage, -2%
---health", damage first; the category alone for a family without modifiers; nil for one Kennel has
---none for.
---@param familyID number?
---@return string?
function Kennel.FamilyModsText(familyID)
    local mods = familyID and Kennel.familyMods[familyID]
    if not mods then return nil end
    wipe(parts)
    if mods.damage ~= 0 then parts[#parts + 1] = L.FAMILY_DAMAGE:format(mods.damage) end
    if mods.health ~= 0 then parts[#parts + 1] = L.FAMILY_HEALTH:format(mods.health) end
    if mods.armor ~= 0 then parts[#parts + 1] = L.FAMILY_ARMOR:format(mods.armor) end
    local category = CATEGORY_NAMES[mods.category]
    if #parts == 0 then return category end
    return L.FAMILY_MODS:format(category, table.concat(parts, ", "))
end

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

---A family's portrait as the client gives it; the question mark when it gives none.
---@param familyID number
---@return number|string
function Kennel.FamilyIcon(familyID)
    local info = C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo(familyID)
    return info and info.iconFile or 134400
end
