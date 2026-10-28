-- FeedEmotes: the whole feeding path, from the food picked to the /emote sent on the next input.
-- The sentence in front is the plain "feeds Fluffy ..." unless a test asks for variety.

local MYSTERY_MEAT, APPLE, JERKY, BREAD = 12037, 4536, 117, 4540

---The module.
local function module(client)
    return client.Addon:GetModule("FeedEmotes")
end

---A hunter logged in with FeedEmotes switched on (it starts off). Without `variety`, the
---openings and whole sentences are taken out, so every emote starts with the feed sentence.
---@param opts table?
local function feeder(opts)
    opts = opts or {}
    local client = NewClient(opts):login()
    client.Addon:SetModuleOn("FeedEmotes", true)
    if not opts.variety then
        local emotes = module(client):LinesInUse().emotes
        emotes.openings, emotes.whole, emotes.wholeFamily = nil, nil, nil
    end
    return client
end

---Asserts that `text` starts with `prefix`; gives the rest.
local function startsWith(text, prefix)
    assert.are.equal(prefix, text and text:sub(1, #prefix), text)
    return text:sub(#prefix + 1)
end

describe("FeedEmotes", function()
    it("is off until switched on: its emotes go out in public chat", function()
        local client = NewClient():login()
        assert.is_false(client.Addon:IsModuleOn("FeedEmotes"))
        client:feed(MYSTERY_MEAT):settle()
        assert.are.same({}, client.chatSent)
    end)

    describe("feeding", function()
        it("sends one emote naming the pet and the food, with a fitting line", function()
            local client = feeder():feed(MYSTERY_MEAT):pressKey()
            assert.are.equal(1, #client.chatSent)
            assert.are.equal("EMOTE", client.chatSent[1][2])
            local line = startsWith(client.chatSent[1][1], "feeds Fluffy some " .. ItemLink(MYSTERY_MEAT) .. ". ")
            ---@type string[]
            local filled = {}
            for i, pooled in ipairs(module(client):EmotePool(MYSTERY_MEAT, "Mystery Meat")) do
                filled[i] = module(client):FillPlaceholders(pooled, "Fluffy", "Mystery Meat")
            end
            assert.is_true(table.concat(filled, "\n"):find(line, 1, true) ~= nil, line)
        end)

        it("names food dragged onto the pet, for one cast only", function()
            local client = feeder():dragFeed(APPLE):pressKey()
            startsWith(client.chatSent[1][1], "feeds Fluffy a " .. ItemLink(APPLE) .. ". ")
            client:castSucceeded()
            startsWith(client:lastSent(), "feeds Fluffy. ")
        end)

        it("does not name food let go of long before the cast", function()
            startsWith(feeder():dragFeed(APPLE, 5):lastSent(), "feeds Fluffy. ")
        end)

        it("takes the food picked as Feed Pet's target over an earlier dragged item", function()
            local client = feeder():pickUp(APPLE):release():feed(JERKY)
            startsWith(client:lastSent(), "feeds Fluffy some " .. ItemLink(JERKY) .. ". ")
        end)

        it("ignores a hidden item ID on the cursor, in a bag click and in the bags", function()
            local client = feeder()
            client.secret = APPLE
            startsWith(client:dragFeed(APPLE):lastSent(), "feeds Fluffy. ")
            client.secret = MYSTERY_MEAT
            startsWith(client:feed(MYSTERY_MEAT):lastSent(), "feeds Fluffy. ")
            client.secret = BREAD
            startsWith(client:spellbookFeed(BREAD):lastSent(), "feeds Fluffy. ")
        end)

        it("names food eaten from the bags just after or just before the cast", function()
            local client = feeder():spellbookFeed(BREAD):pressKey()
            assert.are.equal(1, #client.chatSent, "ready as soon as the bags showed the food gone")
            startsWith(client.chatSent[1][1], "feeds Fluffy a " .. ItemLink(BREAD) .. ". ")
            client = feeder():spellbookFeed(BREAD, true):pressKey()
            startsWith(client.chatSent[1][1], "feeds Fluffy a " .. ItemLink(BREAD) .. ". ")
        end)

        it("without food leaving the bags, sends after a second without the food, once", function()
            local client = feeder():castSucceeded():pressKey()
            assert.are.same({}, client.chatSent, "still waiting")
            client:advance(0.5):pressKey()
            assert.are.same({}, client.chatSent, "still waiting at half a second")
            client:advance(0.6):pressKey()
            startsWith(client.chatSent[1][1], "feeds Fluffy. ")
            client:settle()
            assert.are.equal(1, #client.chatSent)
        end)

        it("does not take food eaten long before, or items gained, as eaten", function()
            local client = feeder():stock(BREAD, 3):eat(BREAD):advance(5):castSucceeded()
            startsWith(client:lastSent(), "feeds Fluffy. ")
            client = feeder():stock(BREAD, 3):stock(BREAD, 5):castSucceeded()
            startsWith(client:lastSent(), "feeds Fluffy. ")
        end)

        it("counts the bags into the same two tables, turn about", function()
            local client = feeder()
            local tracker = module(client).Tracker
            client:stock(BREAD, 3)
            local first = tracker.bagCounts
            client:stock(BREAD, 2)
            local second = tracker.bagCounts
            client:stock(BREAD, 1)
            assert.are_not.equal(first, second)
            assert.are.equal(first, tracker.bagCounts)
        end)

        it("does not name food picked too long before the cast, or used while nothing targets", function()
            startsWith(feeder():feed(MYSTERY_MEAT, 5):lastSent(), "feeds Fluffy. ")
            local client = feeder():pickItem(MYSTERY_MEAT, false):castSucceeded()
            startsWith(client:lastSent(), "feeds Fluffy. ")
        end)

        it("sends without the food's name while the client has not cached it", function()
            startsWith(feeder():feed(99999):lastSent(), "feeds Fluffy. ")
        end)

        it("sends nothing for other spells, another unit's cast, a hidden spell ID or a hidden pet name", function()
            local client = feeder():pickItem(MYSTERY_MEAT):castSucceeded(133)
            client:castSucceeded(nil, "pet"):settle()
            client.secret = FEED_PET
            client:feed(MYSTERY_MEAT):settle()
            client.secret = "Fluffy"
            client:feed(MYSTERY_MEAT):settle()
            assert.are.same({}, client.chatSent)
        end)

        it("drops the emote while the client locks addon chat", function()
            local client = feeder()
            client.chatLocked = true
            client:feed(MYSTERY_MEAT):settle()
            assert.are.same({}, client.chatSent)
            client.chatLocked = false
            client:feed(MYSTERY_MEAT):pressKey()
            assert.are.equal(1, #client.chatSent)
        end)

        it("is in the client's language", function()
            local client = feeder({ locale = "deDE" }):feed(JERKY)
            -- The simulated client has English item names only.
            startsWith(client:lastSent(), "füttert Fluffy mit " .. ItemLink(JERKY) .. ". ")
        end)

        it("replaces {pet} in a line with the pet's name", function()
            local client = feeder()
            client.familyID, client.petSex = 999, 1
            module(client):LinesInUse().emotes.any = { "Just how {pet} likes it, {pet}!" }
            assert.are.equal("feeds Fluffy. Just how Fluffy likes it, Fluffy!", client:castSucceeded():lastSent())
        end)

        it("sends nothing for a cast still waiting for the bags when switched off", function()
            local client = feeder():castSucceeded()
            client.Addon:SetModuleOn("FeedEmotes", false)
            client:settle()
            assert.are.same({}, client.chatSent)
        end)

        it("watches nothing on other classes, and stops when switched off", function()
            local mage = NewClient({ class = "MAGE" }):login()
            mage.Addon:SetModuleOn("FeedEmotes", true)
            mage:feed(MYSTERY_MEAT):settle()
            assert.are.same({}, mage.chatSent)
            local client = feeder()
            client.Addon:SetModuleOn("FeedEmotes", false)
            client:feed(MYSTERY_MEAT):settle()
            assert.are.same({}, client.chatSent)
        end)
    end)

    describe("the example", function()
        it("prints an emote about Mystery Meat in the player's own chat only", function()
            local client = feeder()
            module(client):GetOptions().args.test.func()
            assert.are.same({}, client.chatSent)
            assert.is_true(client:printedContains("Langmans feeds Fluffy some " .. ItemLink(MYSTERY_MEAT) .. ". "))
            client.pet = nil
            module(client):GetOptions().args.test.func()
            assert.is_true(client:printedContains("Summon your pet first."))
        end)
    end)
end)
