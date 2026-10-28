local _, ns = ...

-- Beastkeeper:Listen, and the core's sources: messages about the pet out that the core works out from
-- game events (BEASTKEEPER_PET_HAPPINESS, _DIED, _TAMED, _GROWTH). One source serves every
-- listener, Beastkeeper's own modules and other addons alike, and watches the game only while at least
-- one listens through Listen. A message a module sends itself needs no source; Listen hands it on
-- just the same (docs\04-hooking.md).

---@type Addon
local Addon = ns

local TAME_BEAST = Addon.TAME_BEAST

-- Per message, who listens through Listen.
---@type table<string, table<table, true>>
local listeners = {}

-- Per message, the source that sends it: a table with the game events it watches, a method of the
-- same name for each, and Start, which takes stock when it begins to watch.
---@type table<string, AddonSource>
local sources = {}

---Starts the message's source when it has a listener and is not running, stops it when it has none.
---@param message string
local function Follow(message)
    local source = sources[message]
    if not source then return end
    local owners = listeners[message]
    local wanted = owners ~= nil and next(owners) ~= nil
    if wanted == source.running then return end
    source.running = wanted
    if wanted then
        -- Not every client has every event; a missing one is skipped.
        Addon.RegisterEvents(source, source.events)
        source:Start()
    else
        Addon.UnregisterAllEvents(source)
    end
end

---Listens to a Beastkeeper message: `handler` gets the message's name and its table. The owner is any
---table, the key StopListening takes; asking again for the same message replaces the handler.
---@param owner table
---@param message string
---@param handler string|function a method of the owner, or a function
function Addon:Listen(owner, message, handler)
    Addon.RegisterMessage(owner, message, handler)
    listeners[message] = listeners[message] or {}
    listeners[message][owner] = true
    Follow(message)
end

---Stops listening to one message, or to every message the owner listens to.
---@param owner table
---@param message string?
function Addon:StopListening(owner, message)
    for name, owners in pairs(listeners) do
        if owners[owner] and (message == nil or message == name) then
            Addon.UnregisterMessage(owner, name)
            owners[owner] = nil
            Follow(name)
        end
    end
end

-- BEASTKEEPER_PET_HAPPINESS: the pet out's happiness changed; before is nil for a pet just out.
---@type AddonSource
local happiness = { events = { "UNIT_HAPPINESS", "PET_UI_UPDATE", "UNIT_PET" } }
sources.BEASTKEEPER_PET_HAPPINESS = happiness

function happiness:Start()
    self.guid, self.last = nil, nil
    self:Read(true)
end

---Reads the happiness and says when it changed; at the start (`quiet`) it only takes note.
---@param quiet boolean?
function happiness:Read(quiet)
    if not UnitExists("pet") then
        self.guid, self.last = nil, nil
        return
    end
    local now = Addon.PetHappiness()
    if not now then return end
    local guid = UnitGUID("pet")
    local before = guid == self.guid and self.last or nil
    self.guid, self.last = guid, now
    if now ~= before and not quiet then
        Addon:SendMessage(Addon.messages.petHappiness, { happiness = now, before = before })
    end
end

---@param _ string the event
---@param unit string
function happiness:UNIT_HAPPINESS(_, unit)
    if unit == "pet" then self:Read() end
end

function happiness:PET_UI_UPDATE()
    self:Read()
end

---@param _ string the event
---@param unit string
function happiness:UNIT_PET(_, unit)
    if unit == "player" then self:Read() end
end

---Whether the pet out is dead; false without a pet.
---@return boolean
local function PetDead()
    return UnitExists("pet") and UnitIsDead("pet") == true
end

-- BEASTKEEPER_PET_DIED: the pet out died, seen going from alive to dead.
---@type AddonSource
local death = { events = { "UNIT_HEALTH", "UNIT_PET" } }
sources.BEASTKEEPER_PET_DIED = death

function death:Start()
    self.dead = PetDead()
end

---@param _ string the event
---@param unit string
function death:UNIT_HEALTH(_, unit)
    if unit ~= "pet" then return end
    local dead = PetDead()
    if dead and not self.dead then Addon:SendMessage(Addon.messages.petDied, { pet = UnitName("pet") }) end
    self.dead = dead
end

-- Another pet out (or none): a pet summoned dead was not seen dying.
---@param _ string the event
---@param unit string
function death:UNIT_PET(_, unit)
    if unit == "player" then self.dead = PetDead() end
end

-- BEASTKEEPER_PET_GROWTH: the pet out's training points total, level or loyalty level changed since it
-- was last seen, kept per pet name in BeastkeeperDB (char.growth), so a pet summoned again, or the pet
-- after a relog, tells what changed while away. A pet seen the first time is only noted. Not in the
-- first seconds after login, while the client replays its values; then once. Spending points
-- changes only what is free, not the total: no growth.
local LOGIN_WAIT = 5 -- seconds
local SUMMON_WAIT = 1 -- seconds for a new pet's values to fill in
---@type AddonSource
local growth = { events = { "UNIT_PET_TRAINING_POINTS", "PET_UI_UPDATE", "UNIT_LEVEL", "UNIT_PET" } }
sources.BEASTKEEPER_PET_GROWTH = growth

local function CheckGrowthLater()
    growth.pending = false
    if growth.running then growth:Check() end
end

---Checks after `delay` seconds, once however often asked meanwhile.
---@param delay number
function growth:CheckAfter(delay)
    if self.pending then return end
    self.pending = true
    C_Timer.After(delay, CheckGrowthLater)
end

function growth:Start()
    self.pending = false
    local waited = GetTime() - (Addon.loginTime or 0)
    if waited < LOGIN_WAIT then
        self:CheckAfter(LOGIN_WAIT - waited)
    else
        self:Check()
    end
end

---Compares the pet out with how it stood last time and sends what changed.
function growth:Check()
    if self.pending then return end
    local free, total = Addon.PetTrainingPoints()
    if not total then return end
    -- Right after a /reload a classic client may give no loyalty yet and the points as 0, which
    -- would read as loyalty 1: a fall now and a rise once the values come in. Where the client has
    -- loyalty, nothing counts until it gives one; a later event checks again.
    local given = Addon.C.PetInfo.GetPetLoyalty()
    local none = given == nil or (Addon.Readable(given) and given == "")
    if none and Addon.C.Has("PetInfo", "GetPetLoyalty") then return end
    local pet, level = UnitName("pet"), UnitLevel("pet")
    local loyalty, loyaltyName = Addon.PetLoyalty(total, level)
    local pets = Addon.db.char.growth --[[@as table<string, AddonGrowthSeen>]]
    local seen = pets[pet]
    if not seen then
        pets[pet] = { total = total, level = level, loyalty = loyalty }
        return
    end
    if total == seen.total and level == seen.level and loyalty == seen.loyalty then return end
    local before = { level = seen.level, loyalty = seen.loyalty, points = seen.total }
    seen.total, seen.level, seen.loyalty = total, level, loyalty
    Addon:SendMessage(Addon.messages.petGrowth, {
        pet = pet,
        level = level,
        loyalty = loyalty,
        loyaltyName = loyaltyName,
        points = total,
        free = free,
        before = before,
    })
end

---@param _ string the event
---@param unit string
function growth:UNIT_PET_TRAINING_POINTS(_, unit)
    if unit == "pet" then self:Check() end
end
growth.UNIT_LEVEL = growth.UNIT_PET_TRAINING_POINTS

function growth:PET_UI_UPDATE()
    self:Check()
end

---@param _ string the event
---@param unit string
function growth:UNIT_PET(_, unit)
    if unit == "player" then self:CheckAfter(SUMMON_WAIT) end
end

-- BEASTKEEPER_PET_TAMED: the pet that came out after a Tame Beast cast. It has no pet number until the
-- next relog (its GUID is still the beast's), so petNumber is nil then.
---@type AddonSource
local tame = { events = { "UNIT_SPELLCAST_SUCCEEDED", "UNIT_PET" } }
sources.BEASTKEEPER_PET_TAMED = tame

function tame:Start()
    self.taming = false
end

---@param _ string the event
---@param unit string
---@param _castGUID GameValue
---@param spellID GameValue
function tame:UNIT_SPELLCAST_SUCCEEDED(_, unit, _castGUID, spellID)
    if unit == "player" and Addon.Readable(spellID) and spellID == TAME_BEAST then self.taming = true end
end

---@param _ string the event
---@param unit string
function tame:UNIT_PET(_, unit)
    if unit ~= "player" or not self.taming or not UnitExists("pet") then return end
    self.taming = false
    Addon:SendMessage(
        Addon.messages.petTamed,
        { pet = UnitName("pet"), npc = Addon.PetNPC(), petNumber = Addon.PetNumber() }
    )
end
