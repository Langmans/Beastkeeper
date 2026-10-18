-- Kennel:Listen and the core's sources: messages about the pet out (happiness, a death, a tame)
-- that the core works out from game events, for its own modules and for other addons alike. A
-- source watches the game only while something listens to its message through Kennel:Listen.

local TAME_BEAST = 1515

---Whether any frame has `event` registered.
---@param client table
---@param event string
---@return boolean
local function watched(client, event)
    for _, frame in ipairs(client.frames) do
        if frame.events[event] then return true end
    end
    return false
end

---A client with every module off: only what a spec listens to runs.
---@return table
local function bare()
    local client = NewClient():login()
    for name in pairs(client.Kennel.modules) do
        client.Kennel:SetModuleOn(name, false)
    end
    return client
end

---Listens to `message` as another addon would, keeping what it hears.
---@param client table
---@param message string
---@return table owner, table[] heard
local function listen(client, message)
    local owner, heard = {}, {}
    client.Kennel:Listen(owner, message, function(_, event)
        heard[#heard + 1] = event
    end)
    return owner, heard
end

describe("Kennel:Listen", function()
    it("watches the game for a core message only while something listens", function()
        local client = bare()
        assert.is_false(watched(client, "UNIT_HAPPINESS"))
        local owner = listen(client, "KENNEL_PET_HAPPINESS")
        assert.is_true(watched(client, "UNIT_HAPPINESS"))
        local other = listen(client, "KENNEL_PET_HAPPINESS")
        client.Kennel:StopListening(owner)
        assert.is_true(watched(client, "UNIT_HAPPINESS"), "one still listens")
        client.Kennel:StopListening(other, "KENNEL_PET_HAPPINESS")
        assert.is_false(watched(client, "UNIT_HAPPINESS"))
    end)

    it("hands a module's own message on as well, with no source to start", function()
        local client = bare()
        local owner, heard = listen(client, "KENNEL_PRINT")
        client.Kennel:Print("hello")
        assert.are.same({ { line = "hello" } }, heard)
        client.Kennel:StopListening(owner)
        client.Kennel:Print("again")
        assert.are.equal(1, #heard)
    end)

    it("counts a listener once, however often it asks", function()
        local client = bare()
        local owner, heard = listen(client, "KENNEL_PET_HAPPINESS")
        client.Kennel:Listen(owner, "KENNEL_PET_HAPPINESS", function(_, event)
            heard[#heard + 1] = event
        end)
        client:setHappiness(2)
        assert.are.equal(1, #heard, "the second handler replaced the first")
        client.Kennel:StopListening(owner)
        assert.is_false(watched(client, "UNIT_HAPPINESS"))
    end)

    it("is stopped for a module when it is switched off", function()
        local client = NewClient():login()
        assert.is_true(watched(client, "UNIT_HAPPINESS"), "Feeding and the broker listen")
        client.Kennel:SetModuleOn("Feeding", false)
        client.Kennel:SetModuleOn("Broker", false)
        assert.is_false(watched(client, "UNIT_HAPPINESS"))
    end)
end)

describe("KENNEL_PET_HAPPINESS", function()
    it("says when the pet's happiness changes, with what it was", function()
        local client = bare()
        local _, heard = listen(client, "KENNEL_PET_HAPPINESS")
        client:setHappiness(3)
        assert.are.same({}, heard, "no change from the reading at the start")
        client:setHappiness(2):setHappiness(2):setHappiness(1)
        assert.are.same({ { happiness = 2, before = 3 }, { happiness = 1, before = 2 } }, heard)
    end)

    it("has no before for a pet just summoned, and says nothing without a pet", function()
        local client = bare()
        local _, heard = listen(client, "KENNEL_PET_HAPPINESS")
        client:petGone()
        client:fire("UNIT_PET", "player")
        client.happiness = nil
        client:fire("PET_UI_UPDATE")
        assert.are.same({}, heard)
        client.happiness = 2
        client:summon("Shadow", {})
        assert.are.same({ { happiness = 2 } }, heard)
    end)
end)

describe("KENNEL_PET_DIED", function()
    it("says once when the pet out dies", function()
        local client = bare()
        local _, heard = listen(client, "KENNEL_PET_DIED")
        client:petDies():fire("UNIT_HEALTH", "pet")
        assert.are.same({ { pet = "Fluffy" } }, heard)
        client:petBack():petDies()
        assert.are.equal(2, #heard)
        client:fire("UNIT_HEALTH", "target")
        assert.are.equal(2, #heard)
    end)

    it("does not take a pet summoned dead for a death", function()
        local client = bare()
        client:petGone()
        local _, heard = listen(client, "KENNEL_PET_DIED")
        client:summon("Shadow", {})
        client.pet.dead = true
        client:fire("UNIT_PET", "player"):fire("UNIT_HEALTH", "pet")
        assert.are.same({}, heard)
    end)
end)

describe("KENNEL_PET_TAMED", function()
    it("names the pet a Tame Beast cast brought, and the beast it was", function()
        local client = NewClient({ noPet = true }):login()
        local _, heard = listen(client, "KENNEL_PET_TAMED")
        client:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", TAME_BEAST)
        client.petGUID = "Pet-0-5250-0-1-3825-0100ABCDEF"
        client:summon("Whiskers", {})
        assert.are.same({ { pet = "Whiskers", npc = 3825, petNumber = 0xABCDEF } }, heard)
        client:petGone():summon("Shadow", {})
        assert.are.equal(1, #heard, "an ordinary summon")
    end)

    it("leaves other spells, other units and hidden spell IDs alone", function()
        local client = NewClient({ noPet = true }):login()
        local _, heard = listen(client, "KENNEL_PET_TAMED")
        client:fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-1", TAME_BEAST)
        client:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 883)
        client:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", SECRET)
        client:summon("Shadow", {})
        assert.are.same({}, heard)
    end)
end)
