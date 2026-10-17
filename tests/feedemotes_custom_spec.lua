-- FeedEmotes: the player's own lines, their conditions, sharing them across characters, the
-- chance of an own line and the fallback, and editing them on the module's page.

local MYSTERY_MEAT, APPLE, MACKEREL = 12037, 4536, 787

local function module(client)
    return client.Kennel:GetModule("FeedEmotes")
end

---A hunter with FeedEmotes on and no variety, so emotes start with the plain feed sentence.
local function feeder(opts)
    local client = NewClient(opts):login()
    client.Kennel:SetModuleOn("FeedEmotes", true)
    local emotes = module(client):LinesInUse().emotes
    emotes.openings, emotes.whole, emotes.wholeFamily = nil, nil, nil
    return client
end

---The page's options.
local function page(client)
    return module(client):GetOptions().args
end

---Adds lines and sets the chance to 100, so the emote takes one of them.
local function onlyOwn(client, ...)
    for _, line in ipairs({ ... }) do
        module(client):AddCustomLine(line)
    end
    module(client):Settings().customChance = 100
end

---Whether the pool for feeding `itemID` (a food named "Food" when given) has `text`.
local function poolHas(client, itemID, text)
    for _, line in ipairs(module(client):EmotePool(itemID, itemID and "Food")) do
        if line == text then return true end
    end
    return false
end

---Runs fn with math.random(100) giving `roll` and math.random(n) for a pool giving 1.
local function withRoll(roll, fn)
    local original = math.random
    math.random = function(n)
        return n == 100 and roll or 1
    end
    local ok, err = pcall(fn)
    math.random = original
    if not ok then error(err, 0) end
end

describe("FeedEmotes' own lines", function()
    it("start empty, unshared, at an even chance with the fallback on", function()
        local client = feeder()
        assert.are.same({}, module(client):CustomLines())
        assert.is_false(module(client):Char().sharedLines)
        assert.are.equal(0, module(client):Settings().customChance)
        assert.is_true(module(client):Settings().customFallback)
    end)

    it("are saved trimmed, conditions lower case, in a fixed order, without duplicates", function()
        local M = module(feeder())
        assert.are.same({ true, "{pet} Wolfs It Down!" }, { M:AddCustomLine("   {pet} Wolfs It Down!  ") })
        assert.are.same({ true, "[fish,cat] Nice kitty." }, { M:AddCustomLine("[ CAT , Fish,cat ]  Nice kitty.") })
        assert.are.same({ true, "Chomp." }, { M:AddCustomLine("[] Chomp.") })
    end)

    it("join the built-in lines, with {pet}, {food} and pronouns filled in", function()
        local client = feeder()
        local before = #module(client):EmotePool(MYSTERY_MEAT, "Mystery Meat")
        module(client):AddCustomLine("Chomp.")
        local pool = module(client):EmotePool(MYSTERY_MEAT, "Mystery Meat")
        assert.are.equal(before + 1, #pool)
        assert.is_true(poolHas(client, MYSTERY_MEAT, "Chomp."))
        client = feeder()
        onlyOwn(client, "{pet} wolfs down the {food}, as {he} does.")
        local sent = client:feed(MYSTERY_MEAT):lastSent()
        assert.are.equal(
            "feeds Fluffy some " .. ItemLink(MYSTERY_MEAT) .. ". Fluffy wolfs down the Mystery Meat, as he does.",
            sent
        )
    end)

    it("with {food} are left out while the food is unknown", function()
        local client = feeder()
        onlyOwn(client, "Mmm, {food}.")
        assert.is_false(poolHas(client, nil, "Mmm, {food}."))
        assert.is_true(poolHas(client, nil, "Nice kitty!"), "the built-in lines stand in")
        module(client):AddCustomLine("Chomp.")
        assert.are.equal("feeds Fluffy. Chomp.", client:castSucceeded():lastSent())
    end)

    it("are refused when they would break the emote, saying why", function()
        local M = module(feeder())
        assert.are.same({ false, "Type a line first, such as: {pet} wolfs it down." }, { M:AddCustomLine("") })
        assert.are.same({ false, "Type a line first, such as: {pet} wolfs it down." }, { M:AddCustomLine("[cat]") })
        local ok, reason = M:AddCustomLine(("x"):rep(M.CUSTOM_LINE_MAX + 1))
        assert.is_false(ok)
        assert.truthy(reason:find("at most 150 bytes", 1, true))
        assert.are.same({ false, "A line cannot contain the | character." }, { M:AddCustomLine("|cffff0000red|r") })
        assert.is_true((M:AddCustomLine("[male,fish,bird_of_prey] " .. ("x"):rep(M.CUSTOM_LINE_MAX))))
        M:AddCustomLine("[cat,fish] Yum.")
        assert.are.same({ false, "You already have that line." }, { M:AddCustomLine("[FISH, CAT]  Yum. ") })
        assert.is_true((M:AddCustomLine("[cat] Yum.")), "other conditions make another line")
        ok, reason = M:AddCustomLine("[cat,dragon] Rawr.")
        assert.is_false(ok)
        assert.truthy(reason:find("Unknown condition [dragon]. Conditions: male, female, bread,", 1, true))
        assert.truthy(reason:find("bird_of_prey", 1, true))
        assert.are.equal(3, #M:CustomLines())
    end)

    it("are replaced after the same checks, except against themselves, and removed", function()
        local M = module(feeder())
        M:AddCustomLine("Chomp.")
        M:AddCustomLine("Crunch.")
        assert.are.same({ true, "[cat] Chomp." }, { M:ReplaceCustomLine(1, "[cat] Chomp.") })
        assert.are.same({ true, "[cat] Chomp." }, { M:ReplaceCustomLine(1, "[cat] Chomp.") }, "unchanged is fine")
        assert.are.same({ false, "You already have that line." }, { M:ReplaceCustomLine(1, "Crunch.") })
        assert.are.same({ false, "There is no line 9." }, { M:ReplaceCustomLine(9, "Munch.") })
        assert.are.equal("[cat] Chomp.", M:RemoveCustomLine(1))
        assert.is_nil(M:RemoveCustomLine(5))
        assert.are.same({ "Crunch." }, M:CustomLines())
    end)

    it("survive a reload", function()
        local client = feeder()
        onlyOwn(client, "Chomp.")
        client:logout()
        local reloaded = NewClient({ saved = Saved() }):login()
        local emotes = module(reloaded):LinesInUse().emotes
        emotes.openings, emotes.whole = nil, nil
        assert.are.equal("feeds Fluffy. Chomp.", reloaded:castSucceeded():lastSent())
    end)
end)

describe("FeedEmotes' conditions", function()
    it("offer a family line only to that family; one of a group is enough", function()
        local client = feeder() -- a male cat
        local M = module(client)
        M:AddCustomLine("[cat] Kitty line.")
        M:AddCustomLine("[wolf] Wolf line.")
        M:AddCustomLine("[cat,wolf] Either line.")
        assert.is_true(poolHas(client, nil, "Kitty line."))
        assert.is_false(poolHas(client, nil, "Wolf line."))
        assert.is_true(poolHas(client, nil, "Either line."))
        client.familyID = M.Family.WOLF
        assert.is_false(poolHas(client, nil, "Kitty line."))
        assert.is_true(poolHas(client, nil, "Wolf line."))
        client.secret = M.Family.WOLF
        assert.is_false(poolHas(client, nil, "Wolf line."), "a hidden family matches none")
    end)

    it("must all hold across groups", function()
        local client = feeder()
        module(client):AddCustomLine("[cat,fish] Cat eats fish.")
        assert.is_false(poolHas(client, APPLE, "Cat eats fish."), "an apple is no fish")
        assert.is_false(poolHas(client, nil, "Cat eats fish."), "an unknown food is no fish")
        assert.is_true(poolHas(client, MACKEREL, "Cat eats fish."))
        client.familyID = module(client).Family.BEAR
        assert.is_false(poolHas(client, MACKEREL, "Cat eats fish."), "a bear is no cat")
    end)

    it("on sex need that sex; an unknown or hidden sex matches neither", function()
        local client = feeder()
        module(client):AddCustomLine("[male] He line.")
        module(client):AddCustomLine("[female] She line.")
        assert.is_true(poolHas(client, nil, "He line."))
        assert.is_false(poolHas(client, nil, "She line."))
        client.petSex = 3
        assert.is_true(poolHas(client, nil, "She line."))
        client.petSex = 1
        assert.is_false(poolHas(client, nil, "He line.") or poolHas(client, nil, "She line."))
        client.petSex, client.secret = 2, 2
        assert.is_false(poolHas(client, nil, "He line."))
    end)

    it("are not sent with the line", function()
        local client = feeder()
        onlyOwn(client, "[cat] Nice kitty, {pet}!")
        assert.are.equal("feeds Fluffy. Nice kitty, Fluffy!", client:castSucceeded():lastSent())
    end)

    it("make a saved line with a tag this version does not know skipped", function()
        local client = feeder()
        local lines = module(client):CustomLines()
        lines[1], lines[2] = "[dragon] Rawr.", "Chomp."
        assert.is_false(poolHas(client, nil, "Rawr."))
        assert.is_false(poolHas(client, nil, "[dragon] Rawr."))
        assert.is_true(poolHas(client, nil, "Chomp."))
    end)
end)

describe("FeedEmotes' shared lines", function()
    it("are the account's list while shared, the character's own otherwise", function()
        local client = feeder()
        local M = module(client)
        M:AddCustomLine("Mine.")
        page(client).shared.set({}, true)
        assert.is_true(page(client).shared.get())
        M:AddCustomLine("Ours.")
        M:AddCustomLine("Also ours.")
        M:RemoveCustomLine(1)
        assert.are.same({ "Also ours." }, M.db.global.customLines)
        assert.are.same({ "Mine." }, M:Char().customLines)
        M:Settings().customChance = 100
        page(client).shared.set({}, false)
        assert.are.equal("feeds Fluffy. Mine.", client:castSucceeded():lastSent())
    end)

    it("are kept for the whole account", function()
        local client = feeder()
        page(client).shared.set({}, true)
        module(client):AddCustomLine("Ours.")
        client:logout()
        -- Only the account-wide part of the saved file: as a character that never ran FeedEmotes.
        local account = { namespaces = { FeedEmotes = { global = Saved().namespaces.FeedEmotes.global } } }
        local other = NewClient({ saved = account })
        other:login()
        other.Kennel:SetModuleOn("FeedEmotes", true)
        local M = module(other)
        assert.are.same({}, M:CustomLines(), "a character that does not share")
        M:Char().sharedLines = true
        assert.are.same({ "Ours." }, M:CustomLines())
    end)
end)

describe("FeedEmotes' chance of an own line", function()
    it("takes an own line at or under the roll, a built-in one above it", function()
        local client = feeder()
        local M = module(client)
        M:AddCustomLine("Mine.")
        M:Settings().customChance = 30
        withRoll(30, function()
            assert.are.equal("Mine.", M:PickLine(nil))
        end)
        withRoll(31, function()
            assert.are.equal(M:LinesInUse().emotes.any[1], M:PickLine(nil))
        end)
    end)

    it("at 0 lets the own lines simply join the pool, at 100 uses only them", function()
        local client = feeder()
        local M = module(client)
        M:AddCustomLine("Mine.")
        withRoll(1, function()
            assert.are.equal("Mine.", M:PickLine(nil), "the joined pool starts with the own line")
        end)
        M:Settings().customChance = 100
        withRoll(100, function()
            assert.are.equal("Mine.", M:PickLine(nil))
        end)
    end)

    it("falls back on a built-in line when no own line fits, or on none without the fallback", function()
        local client = feeder()
        local M = module(client)
        M:AddCustomLine("[wolf] Wolf line.")
        M:Settings().customChance = 100
        withRoll(1, function()
            assert.are.equal(M:LinesInUse().emotes.any[1], M:PickLine(nil))
        end)
        page(client).fallback.set({}, false)
        assert.is_false(page(client).fallback.get())
        withRoll(1, function()
            assert.is_nil(M:PickLine(nil))
            assert.are.equal("feeds Fluffy a " .. ItemLink(APPLE) .. ".", client:feed(APPLE):lastSent())
            assert.are.equal("feeds Fluffy.", client:castSucceeded():lastSent(), "no food either")
        end)
    end)

    it("makes the fallback matter only when an own line is wanted", function()
        local client = feeder()
        local M = module(client)
        M:AddCustomLine("[wolf] Wolf line.")
        M:Settings().customFallback = false
        withRoll(1, function()
            assert.is_not_nil(M:PickLine(nil), "even: the built-in lines count as usual")
            M:Settings().customChance = 50
            assert.is_nil(M:PickLine(nil), "a roll of 1 wants an own line")
        end)
        withRoll(51, function()
            assert.are.equal(M:LinesInUse().emotes.any[1], M:PickLine(nil))
        end)
    end)

    it("lets own lines stand in for a language without built-in lines", function()
        local client = feeder()
        local M = module(client)
        M.Lines.enUS.emotes = { any = {}, food = {}, family = {} }
        M:AddCustomLine("Mine.")
        M:Settings().customChance = 50
        withRoll(99, function()
            assert.are.equal("Mine.", M:PickLine(nil))
        end)
    end)

    it("is set on the page with a slider from 0 to 100", function()
        local client = feeder()
        local chance = page(client).chance
        assert.are.equal(0, chance.get())
        chance.set({}, 40)
        assert.are.equal(40, module(client):Settings().customChance)
        assert.are.same({ 0, 100, 1 }, { chance.min, chance.max, chance.step })
    end)
end)

describe("FeedEmotes' page for own lines", function()
    it("adds a typed line with the ticked conditions, says so, and clears the ticks", function()
        local client = feeder()
        local args = page(client)
        args.condFamily.set({}, "wolf", true)
        args.condSex.set({}, "female", true)
        assert.is_true(args.condFamily.get({}, "wolf"))
        args.new.set({}, "[fish] Good hunter!")
        assert.are.same({ "[female,fish,wolf] Good hunter!" }, module(client):CustomLines())
        assert.is_true(client:printedContains("Line 1 added: [female,fish,wolf] Good hunter!"))
        assert.is_false(page(client).condFamily.get({}, "wolf"))
        args.condFamily.set({}, "wolf", false)
        assert.are.equal("", args.new.get())
    end)

    it("says why a line is refused, and keeps the ticks", function()
        local client = feeder()
        local args = page(client)
        args.condFamily.set({}, "cat", true)
        args.new.set({}, "[dragon] Rawr.")
        assert.is_true(client:printedContains("Unknown condition [dragon]."))
        assert.is_true(args.condFamily.get({}, "cat"))
    end)

    it("offers a box per condition, families by name, no exotics", function()
        local args = page(feeder())
        assert.are.same({ male = "Male", female = "Female" }, args.condSex.values)
        assert.are.equal("Mushrooms", args.condFood.values.fungus)
        assert.are.equal("Bird of Prey", args.condFamily.values.bird_of_prey)
        assert.is_nil(args.condFamily.values.chimaera)
    end)

    it("lists the lines, each edited in place and removable, under a title with the count", function()
        local client = feeder()
        local args = page(client)
        assert.are.equal("Lines for this character (0)", args.list.name)
        assert.is_false(args.none.hidden)
        module(client):AddCustomLine("Chomp.")
        module(client):AddCustomLine("Crunch.")
        args = page(client)
        assert.are.equal("Lines for this character (2)", args.list.name)
        assert.is_true(args.none.hidden)
        assert.are.equal("Line 1", args.line1.name)
        assert.are.equal("Chomp.", args.line1.get())
        args.line1.set({}, "[cat] Chomp!")
        assert.are.equal("[cat] Chomp!", module(client):CustomLines()[1])
        args.line2.set({}, "[cat] Chomp!")
        assert.is_true(client:printedContains("You already have that line."))
        args.remove1.func()
        assert.are.same({ "Crunch." }, module(client):CustomLines())
        page(client).shared.set({}, true)
        assert.are.equal("Lines shared by all characters (0)", page(client).list.name)
    end)

    it("names the placeholders of the client's language", function()
        assert.truthy(page(feeder()).ownDesc.name:find("{pet}, {food}, {boy}, {he}, {his}", 1, true))
        local german = page(feeder({ locale = "deDE" })).ownDesc.name
        assert.truthy(german:find("{pet}, {food}, {Junge}, {er}, {sein}", 1, true))
    end)

    it("sets 'always the pet's name'", function()
        local client = feeder()
        local args = page(client)
        assert.is_false(args.petName.get())
        args.petName.set({}, true)
        assert.is_true(module(client):Settings().petName)
    end)
end)
