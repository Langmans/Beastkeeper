local _, ns = ...

-- A journal per pet, per character, kept under the pet's number (Kennel.PetNumber: the same
-- through renames, resummons and stable swaps). It notes when and where a pet was tamed (a Tame
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
    "PLAYER_LOGOUT",
}

---This character's pets, by number (as a string).
---@return table<string, KennelJournalEntry>
function M:Pets()
    return self.db.char.pets --[[@as table<string, KennelJournalEntry>]]
end

---The pet out's key, or nil.
---@return string?
local function Key()
    local number = Kennel.PetNumber()
    return number and tostring(number)
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

---A pet's entry, made the first time it is seen (the pet out).
---@param key string
---@return KennelJournalEntry
function M:Entry(key)
    local pets = self:Pets()
    local entry = pets[key]
    if not entry then
        entry = {
            first = { t = GetServerTime(), zone = GetZoneText(), npc = Kennel.PetNPC() },
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
    if event.petNumber then self:Entry(tostring(event.petNumber)).first.tamed = true end
end

function M:PLAYER_LOGOUT()
    self:Close()
end

function M:OnEnable()
    self.current, self.outSince = nil, nil
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return end
    for _, event in ipairs(EVENTS) do
        pcall(self.RegisterEvent, self, event)
    end
    Kennel:Listen(self, "KENNEL_PET_DIED", "OnDied")
    Kennel:Listen(self, "KENNEL_PET_TAMED", "OnTamed")
    self:UNIT_PET("UNIT_PET", "player")
end

function M:OnDisable()
    Kennel:StopListening(self)
    self:Close()
end
