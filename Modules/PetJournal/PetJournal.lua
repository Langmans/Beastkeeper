local _, ns = ...

-- A journal per pet, per character, kept under the pet's number (Kennel.PetNumber: the same
-- through renames, resummons and stable swaps); a pet tamed this session has no number until the
-- next relog and is kept under its Creature GUID, then moved to its number. It notes when and where a pet was tamed (a Tame
-- Beast cast before a new pet comes out) or first seen, its level, family and loyalty, the time
-- it was out, how often it died, the time out at which each loyalty rise came (for the forecast),
-- and the abilities in its spellbook. Options.lua shows it. Only a hunter has pets.

---@type Kennel
local Kennel = ns
local L = Kennel.L

---@type KennelPetJournal
local M = Kennel:NewModule("PetJournal")
M.title = L.PETJOURNAL_TITLE
M.description = L.PETJOURNAL_DESC
M.defaults = { profile = { tooltip = true }, char = { pets = {} } }

---The settings of the profile in use.
---@return KennelPetJournalSettings
function M:Settings()
    return self.db.profile --[[@as KennelPetJournalSettings]]
end

local BOOK_WAIT = 1 -- seconds for a new pet's spellbook to fill in
-- Deaths and tames come from the core's KENNEL_PET_DIED and KENNEL_PET_TAMED.
local EVENTS = {
    "UNIT_PET",
    "UNIT_LEVEL",
    "UNIT_PET_TRAINING_POINTS",
    "PET_UI_UPDATE",
    "PET_STABLE_UPDATE",
    "PLAYER_LOGOUT",
}

---This character's pets, by number (as a string).
---@return table<string, KennelJournalEntry>
function M:Pets()
    return self.db.char.pets --[[@as table<string, KennelJournalEntry>]]
end

---The pet out's key, or nil: its number; for a pet tamed this session, which keeps the beast's
---Creature GUID until the next relog, that GUID.
---@return string?
local function Key()
    local number = Kennel.PetNumber()
    if number then return tostring(number) end
    local guid = UnitGUID("pet")
    if Kennel.NPCFromGUID(guid, "Creature") then
        return guid --[[@as string]]
    end
end

---Moves the entry of a pet tamed in an earlier session, kept under its Creature GUID, to its
---number `key` now that it has one: the newest such entry tamed as the same beast.
---@param pets table<string, KennelJournalEntry>
---@param key string
local function Adopt(pets, key)
    local npc = Kennel.PetNPC()
    ---@type string?
    local found
    for other, entry in pairs(pets) do
        local fresh = other:find("^Creature%-") ~= nil and entry.first.npc == npc
        if fresh and (not found or entry.first.t > pets[found].first.t) then found = other end
    end
    if found then
        pets[key], pets[found] = pets[found], nil
    end
end

---The seconds a pet has been out, counting the current stretch.
---@param key string
---@return number
function M:Out(key)
    local entry = self:Pets()[key]
    local now = self.current == key and self.outSince and GetTime() - self.outSince or 0
    return entry.out + now
end

---Notes the pet out's name, family, level and loyalty; a loyalty rise with the time out it took.
function M:Record()
    local entry = self.current and self:Pets()[self.current]
    if not entry or not UnitExists("pet") then return end
    entry.name = UnitName("pet") or entry.name
    entry.family = UnitCreatureFamily("pet") or entry.family
    local level = UnitLevel("pet")
    if type(level) == "number" and Kennel.Readable(level) then entry.level = level end
    local _, total = Kennel.PetTrainingPoints()
    local loyalty, name = Kennel.PetLoyalty(total or 0, total and level or nil)
    if not loyalty then return end
    if entry.loyalty and loyalty > entry.loyalty then entry.rises[loyalty] = self:Out(self.current) end
    entry.loyalty, entry.loyaltyName = loyalty, name or entry.loyaltyName
end

---Keeps the pet out's abilities as "Claw (Rank 2)", sorted, and each one's rank by name (what it
---could still teach is worked out when shown: the hunter learns meanwhile).
function M:Snapshot()
    local entry = self.current and self:Pets()[self.current]
    if not entry or not UnitExists("pet") then return end
    wipe(entry.abilities)
    entry.ranks = entry.ranks and wipe(entry.ranks) or {}
    for name, spell in pairs(Kennel.PetSpells()) do
        local rank = spell.rank or ""
        entry.abilities[#entry.abilities + 1] = rank ~= "" and ("%s (%s)"):format(name, rank) or name
        entry.ranks[name] = rank
    end
    table.sort(entry.abilities)
end

local function SnapshotLater()
    if M:IsEnabled() then M:Snapshot() end
end

---Adds the stretch out so far to the pet that was out.
function M:Close()
    if self.current and self.outSince then
        local entry = self:Pets()[self.current]
        entry.out = entry.out + GetTime() - self.outSince
    end
    self.current, self.outSince = nil, nil
end

---A pet's entry, made the first time it is seen: out, or in the stable's lists.
---@param key string
---@param npc number? the NPC ID it was tamed as; the pet out's when nil
---@return KennelJournalEntry
function M:Entry(key, npc)
    local pets = self:Pets()
    local entry = pets[key]
    if not entry then
        entry = {
            first = { t = GetServerTime(), zone = GetZoneText(), npc = npc or Kennel.PetNPC() },
            out = 0,
            deaths = 0,
            rises = {},
            abilities = {},
        }
        pets[key] = entry
    end
    return entry
end

---A pet came out.
---@param key string
function M:Open(key)
    local pets = self:Pets()
    if not pets[key] and not key:find("^Creature%-") then Adopt(pets, key) end
    self:Entry(key)
    self.current, self.outSince = key, GetTime()
    self:Record()
    C_Timer.After(BOOK_WAIT, SnapshotLater)
end

-- A pet summoned, tamed, dismissed or swapped.
---@param _ string the event
---@param unit string
function M:UNIT_PET(_, unit)
    if unit ~= "player" then return end
    local key = Key()
    if key == self.current then
        self:Record()
        return
    end
    self:Close()
    if key then self:Open(key) end
    Kennel:RefreshWindow("pets")
end

---Takes what the stable's lists say of each pet: its name, level, family, specialization and
---loyalty, and the
---model it shows (displayID) and the beast it was tamed as, for the window's card. A pet not in
---the journal yet gets an entry. Forever's C_StableInfo; other clients have none.
---@param list fun(): table[]
function M:ReadStableList(list)
    for _, info in ipairs(list()) do
        local number = info.petNumber --[[@as GameValue]]
        if type(number) == "number" and Kennel.Readable(number) and info.name then
            local entry = self:Entry(tostring(number), info.creatureID)
            entry.name, entry.level, entry.family = info.name, info.level, info.familyName
            entry.displayID = info.displayID
            -- Ferocity, Cunning or Tenacity, by family; the client may give an empty one.
            if info.specialization ~= "" then entry.specialization = info.specialization end
            entry.loyalty, entry.loyaltyName = info.loyaltyLevel or entry.loyalty, info.loyaltyName or entry.loyaltyName
        end
    end
end

-- The stable's lists changed (at the stable master): what they say goes into the journal.
function M:PET_STABLE_UPDATE()
    local stable = C_StableInfo
    if not stable then return end
    self:ReadStableList(stable.GetActivePetList)
    self:ReadStableList(stable.GetStabledPetList)
    Kennel:RefreshWindow("pets")
end

---@param _ string the event
---@param unit string
function M:UNIT_LEVEL(_, unit)
    if unit == "pet" then self:Record() end
end
M.UNIT_PET_TRAINING_POINTS = M.UNIT_LEVEL

function M:PET_UI_UPDATE()
    self:Record()
end

-- The core's KENNEL_PET_DIED: the pet out died.
function M:OnDied()
    if not self.current then return end
    local entry = self:Pets()[self.current]
    entry.deaths = entry.deaths + 1
end

---The core's KENNEL_PET_TAMED. It may come before or after this module sees the pet come out,
---so it makes the entry if need be.
---@param _ string the message
---@param event KennelPetTamedEvent
function M:OnTamed(_, event)
    -- Freshly tamed, the pet has no number yet: it goes under its Creature GUID (Key).
    local key = event.petNumber and tostring(event.petNumber) or Key()
    if key then self:Entry(key).first.tamed = true end
end

function M:PLAYER_LOGOUT()
    self:Close()
end

function M:OnEnable()
    self.current, self.outSince = nil, nil
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    Kennel.RegisterEvents(self, EVENTS)
    Kennel:Listen(self, "KENNEL_PET_DIED", "OnDied")
    Kennel:Listen(self, "KENNEL_PET_TAMED", "OnTamed")
    self:UNIT_PET("UNIT_PET", "player")
end

function M:OnDisable()
    Kennel:StopListening(self)
    self:Close()
end
