local _, ns = ...

-- Kennel:Listen, and the core's sources: messages about the pet out that the core works out from
-- game events (KENNEL_PET_HAPPINESS, KENNEL_PET_DIED, KENNEL_PET_TAMED). One source serves every
-- listener, Kennel's own modules and other addons alike, and watches the game only while at least
-- one listens through Listen. A message a module sends itself needs no source; Listen hands it on
-- just the same (docs\04-hooking.md).

---@type Kennel
local Kennel = ns

local TAME_BEAST = 1515

-- Per message, who listens through Listen.
---@type table<string, table<table, true>>
local listeners = {}

-- Per message, the source that sends it: a table with the game events it watches, a method of the
-- same name for each, and Start, which takes stock when it begins to watch.
---@type table<string, KennelSource>
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
        for _, event in ipairs(source.events) do
            -- Not every client has every event; a missing one is skipped.
            pcall(Kennel.RegisterEvent, source, event)
        end
        source:Start()
    else
        Kennel.UnregisterAllEvents(source)
    end
end

---Listens to a Kennel message: `handler` gets the message's name and its table. The owner is any
---table, the key StopListening takes; asking again for the same message replaces the handler.
---@param owner table
---@param message string
---@param handler string|function a method of the owner, or a function
function Kennel:Listen(owner, message, handler)
    Kennel.RegisterMessage(owner, message, handler)
    listeners[message] = listeners[message] or {}
    listeners[message][owner] = true
    Follow(message)
end

---Stops listening to one message, or to every message the owner listens to.
---@param owner table
---@param message string?
function Kennel:StopListening(owner, message)
    for name, owners in pairs(listeners) do
        if owners[owner] and (message == nil or message == name) then
            Kennel.UnregisterMessage(owner, name)
            owners[owner] = nil
            Follow(name)
        end
    end
end

-- KENNEL_PET_HAPPINESS: the pet out's happiness changed; before is nil for a pet just out.
---@type KennelSource
local happiness = { events = { "UNIT_HAPPINESS", "PET_UI_UPDATE", "UNIT_PET" } }
sources.KENNEL_PET_HAPPINESS = happiness

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
    local now = Kennel.PetHappiness()
    if not now then return end
    local guid = UnitGUID("pet")
    local before = guid == self.guid and self.last or nil
    self.guid, self.last = guid, now
    if now ~= before and not quiet then
        Kennel:SendMessage("KENNEL_PET_HAPPINESS", { happiness = now, before = before })
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

-- KENNEL_PET_DIED: the pet out died, seen going from alive to dead.
---@type KennelSource
local death = { events = { "UNIT_HEALTH", "UNIT_PET" } }
sources.KENNEL_PET_DIED = death

function death:Start()
    self.dead = PetDead()
end

---@param _ string the event
---@param unit string
function death:UNIT_HEALTH(_, unit)
    if unit ~= "pet" then return end
    local dead = PetDead()
    if dead and not self.dead then Kennel:SendMessage("KENNEL_PET_DIED", { pet = UnitName("pet") }) end
    self.dead = dead
end

-- Another pet out (or none): a pet summoned dead was not seen dying.
---@param _ string the event
---@param unit string
function death:UNIT_PET(_, unit)
    if unit == "player" then self.dead = PetDead() end
end

-- KENNEL_PET_TAMED: the pet that came out after a Tame Beast cast. It has no pet number until the
-- next relog (its GUID is still the beast's), so petNumber is nil then.
---@type KennelSource
local tame = { events = { "UNIT_SPELLCAST_SUCCEEDED", "UNIT_PET" } }
sources.KENNEL_PET_TAMED = tame

function tame:Start()
    self.taming = false
end

---@param _ string the event
---@param unit string
---@param _castGUID GameValue
---@param spellID GameValue
function tame:UNIT_SPELLCAST_SUCCEEDED(_, unit, _castGUID, spellID)
    if unit == "player" and Kennel.Readable(spellID) and spellID == TAME_BEAST then self.taming = true end
end

---@param _ string the event
---@param unit string
function tame:UNIT_PET(_, unit)
    if unit ~= "player" or not self.taming or not UnitExists("pet") then return end
    self.taming = false
    Kennel:SendMessage(
        "KENNEL_PET_TAMED",
        { pet = UnitName("pet"), npc = Kennel.PetNPC(), petNumber = Kennel.PetNumber() }
    )
end
