local _, ns = ...

-- What several modules ask about the pet and its spells: names and icons across client
-- generations, the pet's family, and the sound a pet of that family makes (the tables are in
-- Sounds.lua).

---@type Addon
local Addon = ns

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
function Addon.CreatureName(npcID)
    if creatureNames[npcID] then return creatureNames[npcID] end
    local ok, data = pcall(Addon.C.TooltipInfo.GetHyperlink, ("unit:Creature-0-0-0-0-%d-0000000000"):format(npcID))
    if not ok or type(data) ~= "table" then return nil end
    local line = (data --[[@as BeastkeeperTooltipData]]).lines and data.lines[1]
    local name = line and line.leftText
    if type(name) ~= "string" or not Addon.Readable(name) or name == "" then return nil end
    creatureNames[npcID] = name
    return name
end

---Runs `fn` once the client has an item's data (its name, level, link): now when it has, else
---when it has loaded it (Item:ContinueOnItemLoad, which also asks the server). On a client
---without the Item object, now.
---@param itemID number
---@param fn fun()
function Addon.WhenItemLoaded(itemID, fn)
    if not Item or (C_Item.IsItemDataCachedByID and C_Item.IsItemDataCachedByID(itemID)) then
        fn()
        return
    end
    Item:CreateFromItemID(itemID):ContinueOnItemLoad(fn)
end

-- Call Pet: a hunter has a pet to care for only once it knows this (level 10 on the classic clients).
-- Tame Beast: learned at the same level. Beast Training and Feed Pet: from the quest that ends the
-- hunter's taming quests at 10 (Training the Beast), with Revive Pet.
Addon.CALL_PET, Addon.TAME_BEAST, Addon.BEAST_TRAINING, Addon.FEED_PET = 883, 1515, 5149, 6991

---Whether the player is taming a beast now: Tame Beast cast or channelled (the spell ID is the 9th
---return of UnitCastingInfo, the 8th of UnitChannelInfo). The beast fights back meanwhile.
---@return boolean
function Addon.IsTaming()
    local cast = select(9, UnitCastingInfo("player"))
    local channel = select(8, UnitChannelInfo("player"))
    return (Addon.Readable(cast) and cast == Addon.TAME_BEAST)
        or (Addon.Readable(channel) and channel == Addon.TAME_BEAST)
end

---Whether the player knows a spell (Beastkeeper.C.SpellBook.IsSpellKnown); true on a client that cannot
---tell.
---@param spellID number
---@return boolean
function Addon.KnowsSpell(spellID)
    return Addon.C.SpellBook.IsSpellKnown(spellID) ~= false
end

---Spell name, icon and rank across client generations: C_Spell on newer clients, GetSpellInfo on
---older ones. All nil when the client knows neither.
---@param id number
---@return string? name
---@return (number|string)? icon
---@return string? rank the rank text ("Rank 2"), nil when the spell has none
function Addon.SpellInfo(id)
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
---@type table<string, BeastkeeperPetSpell>, table<string, BeastkeeperPetSpell>
local petSpells, spellEntries = {}, {}

---A pet spellbook entry's name, rank text and spell ID (Beastkeeper.C.SpellBook); nil for a command
---or an entry that cannot be read.
---@param index number
---@return string? name
---@return string? subName
---@return number? spellID
function Addon.PetBookEntry(index)
    local ok, info = pcall(Addon.C.SpellBook.GetSpellBookItemInfo, index, Enum.SpellBookSpellBank.Pet)
    if not ok or type(info) ~= "table" then return nil end
    local name, subName, spellID = info.name, info.subName, info.spellID
    if type(name) ~= "string" or not Addon.Readable(name) then return nil end
    return name, type(subName) == "string" and subName or nil, type(spellID) == "number" and spellID or nil
end

---Whether a pet spellbook entry can autocast and whether it does (Beastkeeper.C.SpellBook); nil for an
---entry that cannot be read.
---@param index number
---@return GameValue allowed
---@return GameValue enabled
function Addon.PetBookAutocast(index)
    local ok, allowed, enabled = pcall(Addon.C.SpellBook.GetSpellBookItemAutoCast, index, Enum.SpellBookSpellBank.Pet)
    if ok then return allowed, enabled end
end

---How many entries the pet's spellbook has; 0 without a pet or a spellbook API.
---@return number
function Addon.PetBookSize()
    return tonumber((Addon.C.SpellBook.HasPetSpells())) or 0
end

---The spells in the active pet's spellbook by name, each with its ID, rank and icon; empty
---without a pet or a spellbook API. Pet commands (Attack, Follow) have no spell and are left
---out, as is an entry that cannot be read. The same table each time, refilled: read what is
---needed from it before the next call, and keep no entry.
---@return table<string, BeastkeeperPetSpell>
function Addon.PetSpells()
    wipe(petSpells)
    for index = 1, Addon.PetBookSize() do
        local name, subName, id = Addon.PetBookEntry(index)
        if name and id then
            local _, icon, rank = Addon.SpellInfo(id)
            local entry = spellEntries[name] or {}
            spellEntries[name] = entry
            entry.id, entry.rank, entry.icon = id, subName ~= "" and subName or rank, icon
            petSpells[name] = entry
        end
    end
    return petSpells
end

---The active pet's free training points (total minus used) and its total (Beastkeeper.C.PetInfo); nil
---without a pet, without the API or when the client hides them.
---@return number? free
---@return number? total
function Addon.PetTrainingPoints()
    if not UnitExists("pet") then return nil end
    local total, used = Addon.C.PetInfo.GetPetTrainingPoints()
    if type(total) ~= "number" or not Addon.Readable(total) then return nil end
    return math.max(0, total - (tonumber(used) or 0)), total
end

---The active pet's CreatureFamily ID (1 wolf, 2 cat, ...), the same on every client language;
---nil without a pet.
---@return number?
function Addon.PetFamilyID()
    if not UnitExists("pet") then return nil end
    local _, familyID = UnitCreatureFamily("pet")
    return tonumber(familyID)
end

---The stable's entry of the pet out (Beastkeeper.C.StableInfo's active pets, which WoW: Forever gives
---away from the stable master too): the one with the pet's name. Nil without a pet, or without
---exactly one entry of that name.
---@return BeastkeeperStablePet?
function Addon.PetStableInfo()
    if not UnitExists("pet") then return nil end
    local name = UnitName("pet")
    ---@type BeastkeeperStablePet?
    local found
    for _, info in ipairs(Addon.C.StableInfo.GetActivePetList()) do
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
function Addon.PetNumber()
    local info = Addon.PetStableInfo()
    if info and type(info.petNumber) == "number" then
        return info.petNumber --[[@as number]]
    end
    return Addon.PetNumberFromGUID(UnitGUID("pet"))
end

---A pet's number from its GUID, as PetNumber; nil for another kind of GUID or a hidden one.
---@param guid GameValue
---@return number?
function Addon.PetNumberFromGUID(guid)
    if type(guid) ~= "string" or not Addon.Readable(guid) then return nil end
    local spawnUID = guid:match("^Pet%-.-%-(%x+)$")
    return spawnUID and tonumber(spawnUID:sub(-8), 16) or nil
end

---The pet's loyalty level and its name, as far as the client tells them. WoW: Forever gives the
---name alone ("Faithful"), Classic Era "(Loyalty Level 5) Faithful", some a number
---(Beastkeeper.C.PetInfo.GetPetLoyalty). Without a number the level comes from the training points,
---which are level × (loyalty − 1), when they divide evenly; else it stays unknown.
---@param total number the training points total
---@param petLevel GameValue
---@return number? loyalty
---@return string? name
function Addon.PetLoyalty(total, petLevel)
    local value = Addon.C.PetInfo.GetPetLoyalty()
    ---@type number?, string?
    local loyalty, name
    if not Addon.Readable(value) then
        value = nil
    elseif type(value) == "number" then
        loyalty = value
    elseif type(value) == "string" and value ~= "" then
        loyalty = tonumber(value:match("%d+"))
        -- Classic Era: "(Loyalty Level 1) Rebellious", the name after the brackets; else the name in
        -- them, "Loyalty Level 4 (Dependable)"; Forever: the bare name.
        local level, after = value:match("^%((.-)%)%s*(.+)$")
        name = level and after or value:match("%((.-)%)") or (not loyalty and value or nil)
    end
    if not loyalty and type(petLevel) == "number" and Addon.Readable(petLevel) and petLevel > 0 then
        local derived = total / petLevel + 1
        if derived == math.floor(derived) then loyalty = derived end
    end
    return loyalty, name
end

---The pet's happiness, a Beastkeeper.happiness value; nil without a pet, the API, or a readable answer.
---@return number?
function Addon.PetHappiness()
    local happiness = Addon.C.PetInfo.GetPetHappiness()
    if type(happiness) == "number" and Addon.Readable(happiness) then
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

---A loyalty level as Beastkeeper shows it: "5 (Faithful)" with the name in its colour, or "5" when the
---client gave no name.
---@param loyalty number
---@param name string?
---@return string
function Addon.LoyaltyLabel(loyalty, name)
    if not name then return tostring(loyalty) end
    return ("%d (%s%s|r)"):format(loyalty, LoyaltyColor(loyalty), name)
end

---The frame that shows the pet: EllesmereUI's when it draws its own unit frames, else the game's.
---@return Frame
function Addon.PetFrame()
    return _G.EllesmereUIUnitFrames_Pet or PetFrame
end

---The NPC ID in a GUID of `kind` ("Creature" or "Pet"): its sixth field
---(Creature-0-server-instance-zone-npcID-spawnUID). Nil for another kind, or a hidden GUID.
---@param guid GameValue
---@param kind "Creature"|"Pet"
---@return number?
function Addon.NPCFromGUID(guid, kind)
    if type(guid) ~= "string" or not Addon.Readable(guid) then return nil end
    return tonumber(guid:match("^" .. kind .. "%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end

---The NPC ID the active pet was tamed as: the stable entry's creatureID. Without one, the GUID's:
---a pet tamed this session keeps the beast's own Creature GUID until the next relog (/reload keeps
---it too); a Pet GUID's sixth field is the tamed NPC on some clients, on WoW: Forever every pet's
---"Hunter Pet" (165189). Nil without a pet or when the client hides the GUID.
---@return number?
function Addon.PetNPC()
    local info = Addon.PetStableInfo()
    if info and type(info.creatureID) == "number" then
        return info.creatureID --[[@as number]]
    end
    local guid = UnitGUID("pet")
    return Addon.NPCFromGUID(guid, "Pet") or Addon.NPCFromGUID(guid, "Creature")
end

---A sound of the active pet's family, as a toast sound; nil without a pet or for a family without
---that sound.
---@param kind "AGGRO"|"DEATH"|"WOUND" its attack call, death sound or wound cry
---@return BeastkeeperSound?
function Addon.PetSound(kind)
    local familyID = Addon.PetFamilyID()
    local sounds = Addon.sounds[kind .. "_PER_FAMILY"] --[[@as table<number, number>]]
    local file = familyID and sounds[familyID]
    return file and { file = file } or nil
end

---Whether the addon may read a value: WoW: Forever hides some (health, autocast) in combat. A
---client without canaccessvalue hides nothing.
---@param value GameValue
---@return boolean
function Addon.Readable(value)
    return not canaccessvalue or canaccessvalue(value)
end
