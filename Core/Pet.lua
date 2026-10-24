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

-- Creature names the client gave, by NPC ID: they do not change within a session.
---@type table<number, string>
local creatureNames = {}

---A creature's name as the client words it, through the tooltip of a creature link; nil while the
---client does not have it (asking makes the client fetch it, so a later call usually has it).
---@param npcID number
---@return string?
function Kennel.CreatureName(npcID)
    if creatureNames[npcID] then return creatureNames[npcID] end
    if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, ("unit:Creature-0-0-0-0-%d-0000000000"):format(npcID))
    local line = ok and type(data) == "table" and data.lines and data.lines[1]
    local name = line and line.leftText
    if type(name) ~= "string" or not Kennel.Readable(name) or name == "" then return nil end
    creatureNames[npcID] = name
    return name
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

-- What PetSpells found last, and each spell's entry, kept and refilled rather than built anew on
-- every summon, learn and hint.
---@type table<string, KennelPetSpell>, table<string, KennelPetSpell>
local petSpells, spellEntries = {}, {}

---A pet spellbook entry's name, rank text and spell ID: C_SpellBook's on newer clients,
---GetSpellBookItemName's by book type on Classic Era; nil for a command or an unreadable entry.
---@param index number
---@return string? name
---@return string? subName
---@return number? spellID
function Kennel.PetBookEntry(index)
    local book = C_SpellBook
    if book and book.GetSpellBookItemInfo then
        local ok, info = pcall(book.GetSpellBookItemInfo, index, Enum.SpellBookSpellBank.Pet)
        if ok and info then return info.name, info.subName, info.spellID end
    elseif GetSpellBookItemName then
        local ok, name, subName, id = pcall(GetSpellBookItemName, index, BOOKTYPE_PET or "pet")
        if ok then return name, subName, id end
    end
end

---Whether a pet spellbook entry can autocast and whether it does: C_SpellBook's on newer
---clients, GetSpellAutocast's on Classic Era; nil for an entry that cannot be read.
---@param index number
---@return GameValue allowed
---@return GameValue enabled
function Kennel.PetBookAutocast(index)
    local book = C_SpellBook
    local get = book and book.GetSpellBookItemAutoCast
    if get then
        local ok, allowed, enabled = pcall(get, index, Enum.SpellBookSpellBank.Pet)
        if ok then return allowed, enabled end
    elseif GetSpellAutocast then
        local ok, allowed, enabled = pcall(GetSpellAutocast, index, BOOKTYPE_PET or "pet")
        if ok then return allowed, enabled end
    end
end

---How many entries the pet's spellbook has: C_SpellBook's count, or the old global's; 0 without a
---pet or either.
---@return number
function Kennel.PetBookSize()
    local count = (C_SpellBook and C_SpellBook.HasPetSpells) or HasPetSpells
    return count and tonumber((count())) or 0
end

---The spells in the active pet's spellbook by name, each with its ID, rank and icon; empty
---without a pet or a spellbook API. Pet commands (Attack, Follow) have no spell and are left
---out, as is an entry that cannot be read. The same table each time, refilled: read what is
---needed from it before the next call, and keep no entry.
---@return table<string, KennelPetSpell>
function Kennel.PetSpells()
    wipe(petSpells)
    for index = 1, Kennel.PetBookSize() do
        local name, subName, id = Kennel.PetBookEntry(index)
        if name and id then
            local _, icon, rank = Kennel.SpellInfo(id)
            local entry = spellEntries[name] or {}
            spellEntries[name] = entry
            entry.id, entry.rank, entry.icon = id, subName ~= "" and subName or rank, icon
            petSpells[name] = entry
        end
    end
    return petSpells
end

---The active pet's free training points (total minus used) and its total, from C_PetInfo on
---WoW: Forever or the global on older clients; nil without a pet, without the API or when the
---client hides them.
---@return number? free
---@return number? total
function Kennel.PetTrainingPoints()
    ---@type (fun(): GameValue, GameValue)?
    local get = (C_PetInfo and C_PetInfo.GetPetTrainingPoints) or GetPetTrainingPoints
    if not get or not UnitExists("pet") then return nil end
    local total, used = get()
    if type(total) ~= "number" or not Kennel.Readable(total) then return nil end
    return math.max(0, total - (tonumber(used) or 0)), total
end

---The active pet's CreatureFamily ID (1 wolf, 2 cat, ...), the same on every client language;
---nil without a pet.
---@return number?
function Kennel.PetFamilyID()
    if not UnitExists("pet") then return nil end
    local _, familyID = UnitCreatureFamily("pet")
    return tonumber(familyID)
end

---The stable's entry of the pet out (C_StableInfo's active pets, which WoW: Forever gives away from
---the stable master too): the one with the pet's name. Nil without a pet, the API, or exactly one
---entry of that name.
---@return table?
function Kennel.PetStableInfo()
    local getActive = C_StableInfo and C_StableInfo.GetActivePetList
    if not UnitExists("pet") or not getActive then return nil end
    local name = UnitName("pet")
    ---@type table?
    local found
    for _, info in ipairs(getActive()) do
        if info.name == name then
            if found then return nil end
            found = info
        end
    end
    return found
end

---The active pet's number, C_StableInfo's petNumber. It stays the same through resummons, relogs,
---stable swaps and renames, so per-pet settings are kept under it. On WoW: Forever the pet's GUID
---does not hold it, so the stable's entry of the pet gives it; the GUID's last field (its low 32
---bits) only without one. Nil without a pet or when the client hides the GUID.
---@return number?
function Kennel.PetNumber()
    local info = Kennel.PetStableInfo()
    if info and type(info.petNumber) == "number" then
        return info.petNumber --[[@as number]]
    end
    return Kennel.PetNumberFromGUID(UnitGUID("pet"))
end

---A pet's number from its GUID, as PetNumber; nil for another kind of GUID or a hidden one.
---@param guid GameValue
---@return number?
function Kennel.PetNumberFromGUID(guid)
    if type(guid) ~= "string" or not Kennel.Readable(guid) then return nil end
    local spawnUID = guid:match("^Pet%-.-%-(%x+)$")
    return spawnUID and tonumber(spawnUID:sub(-8), 16) or nil
end

---The pet's loyalty level and its name, as far as the client tells them. WoW: Forever gives the
---name alone ("Faithful", C_PetInfo.GetPetLoyalty), classic clients "Loyalty Level 5 (Faithful)"
---(the global), some a number. Without a number the level comes from the training points, which
---are level × (loyalty − 1), when they divide evenly; else it stays unknown.
---@param total number the training points total
---@param petLevel GameValue
---@return number? loyalty
---@return string? name
function Kennel.PetLoyalty(total, petLevel)
    local get = (C_PetInfo and C_PetInfo.GetPetLoyalty) or GetPetLoyalty
    ---@type GameValue
    local value = get and get()
    ---@type number?, string?
    local loyalty, name
    if not Kennel.Readable(value) then
        value = nil
    elseif type(value) == "number" then
        loyalty = value
    elseif type(value) == "string" and value ~= "" then
        loyalty = tonumber(value:match("%d+"))
        name = value:match("%((.-)%)") or (not loyalty and value or nil)
    end
    if not loyalty and type(petLevel) == "number" and Kennel.Readable(petLevel) and petLevel > 0 then
        local derived = total / petLevel + 1
        if derived == math.floor(derived) then loyalty = derived end
    end
    return loyalty, name
end

---The pet's happiness, a Kennel.happiness value; nil without a pet, the API, or a readable answer.
---@return number?
function Kennel.PetHappiness()
    ---@type (fun(): GameValue)?
    local get = (C_PetInfo and C_PetInfo.GetPetHappiness) or GetPetHappiness
    ---@type GameValue
    local happiness = get and get()
    if type(happiness) == "number" and Kennel.Readable(happiness) then
        return happiness --[[@as number]]
    end
end

-- The loyalty name's colour runs from the friendly to the exalted reputation colour.
local FRIENDLY, EXALTED = { 0, 0.8, 0 }, { 0, 0.8, 0.8 }

---One colour channel, 0-255, a share `t` of the way from friendly to exalted.
---@param i number 1, 2 or 3: red, green, blue
---@param t number
---@return number
local function Channel(i, t)
    return math.floor((FRIENDLY[i] + (EXALTED[i] - FRIENDLY[i]) * t) * 255 + 0.5)
end

---The colour code of a loyalty level, along the reputation colours: friendly green at loyalty
---level 1 to exalted teal at 6.
---@param level number
---@return string
local function LoyaltyColor(level)
    local t = (math.min(math.max(level, 1), 6) - 1) / 5
    return ("|cff%02x%02x%02x"):format(Channel(1, t), Channel(2, t), Channel(3, t))
end

---A loyalty level as Kennel shows it: "5 (Faithful)" with the name in its colour, or "5" when the
---client gave no name.
---@param loyalty number
---@param name string?
---@return string
function Kennel.LoyaltyLabel(loyalty, name)
    if not name then return tostring(loyalty) end
    return ("%d (%s%s|r)"):format(loyalty, LoyaltyColor(loyalty), name)
end

---The frame that shows the pet: EllesmereUI's when it draws its own unit frames, else the game's.
---@return Frame
function Kennel.PetFrame()
    return _G.EllesmereUIUnitFrames_Pet or PetFrame
end

---The NPC ID in a GUID of `kind` ("Creature" or "Pet"): its sixth field
---(Creature-0-server-instance-zone-npcID-spawnUID). Nil for another kind, or a hidden GUID.
---@param guid GameValue
---@param kind "Creature"|"Pet"
---@return number?
function Kennel.NPCFromGUID(guid, kind)
    if type(guid) ~= "string" or not Kennel.Readable(guid) then return nil end
    return tonumber(guid:match("^" .. kind .. "%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end

---The NPC ID the active pet was tamed as: the stable entry's creatureID. Without one, the GUID's:
---a pet tamed this session keeps the beast's own Creature GUID until the next relog (/reload keeps
---it too); a Pet GUID's sixth field is the tamed NPC on some clients, on WoW: Forever every pet's
---"Hunter Pet" (165189). Nil without a pet or when the client hides the GUID.
---@return number?
function Kennel.PetNPC()
    local info = Kennel.PetStableInfo()
    if info and type(info.creatureID) == "number" then
        return info.creatureID --[[@as number]]
    end
    local guid = UnitGUID("pet")
    return Kennel.NPCFromGUID(guid, "Pet") or Kennel.NPCFromGUID(guid, "Creature")
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
