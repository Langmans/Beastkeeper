-- FeedEmotes: the text of an emote. Pronouns follow the pet's sex (the player's choice per pet
-- first), openings and whole sentences add variety, and which lists a feeding draws from.

local MYSTERY_MEAT, WATERMELON, BREAD, JERKY = 12037, 4538, 4540, 117

local function module(client)
    return client.Kennel:GetModule("FeedEmotes")
end

---A hunter with FeedEmotes on; without `variety`, no openings or whole sentences.
local function feeder(opts)
    opts = opts or {}
    local client = NewClient(opts):login()
    client.Kennel:SetModuleOn("FeedEmotes", true)
    if not opts.variety then
        local emotes = module(client):LinesInUse().emotes
        emotes.openings, emotes.whole, emotes.wholeFamily = nil, nil, nil
    end
    return client
end

---Leaves `line` as the only line a feeding can get.
local function onlyLine(client, line)
    client.familyID = 999
    local emotes = module(client):LinesInUse().emotes
    emotes.any, emotes.male, emotes.female = { line }, {}, {}
end

---The emote for a feeding without a known food.
local function sent(client)
    return client:castSucceeded():lastSent()
end

---Runs fn with math.random(n) giving pick(n).
local function withRandom(pick, fn)
    local original = math.random
    math.random = pick
    local ok, err = pcall(fn)
    math.random = original
    if not ok then error(err, 0) end
end

local function first()
    return 1
end

local function last(n)
    return n
end

---Whether `list` holds `value`.
local function has(list, value)
    for _, item in ipairs(list) do
        if item == value then return true end
    end
    return false
end

describe("FeedEmotes' pronouns", function()
    it("follow the pet's sex: he/she, boy/girl, his/her", function()
        local client = feeder()
        onlyLine(client, "Good {boy}, {he} ate {his} dinner.")
        assert.are.equal("feeds Fluffy. Good boy, he ate his dinner.", sent(client))
        client.petSex = 3
        assert.are.equal("feeds Fluffy. Good girl, she ate her dinner.", sent(client))
    end)

    it("name the pet when the sex is unknown or hidden, or when asked to", function()
        local client = feeder()
        onlyLine(client, "Good {boy}, not {his} dessert.")
        client.petSex = 1
        assert.are.equal("feeds Fluffy. Good Fluffy, not Fluffy's dessert.", sent(client))
        client.petSex, client.secret = 2, 2
        assert.are.equal("feeds Fluffy. Good Fluffy, not Fluffy's dessert.", sent(client))
        client.secret = nil
        module(client):Settings().petName = true
        assert.are.equal("feeds Fluffy. Good Fluffy, not Fluffy's dessert.", sent(client))
    end)

    it("keep a % in the pet's name in the possessive", function()
        local client = feeder()
        onlyLine(client, "Not {his} dessert!")
        client.petSex, client.pet.name = 1, "100%"
        assert.are.equal("feeds 100%. Not 100%'s dessert!", sent(client))
    end)

    it("use the language's own words, never borrowing English ones", function()
        local client = feeder({ locale = "deDE" })
        onlyLine(client, "Frisst {er} auch seitwärts, {Junge}? Wie {he} es mag.")
        client.petSex = 3
        assert.are.equal("füttert Fluffy. Frisst sie auch seitwärts, Mädchen? Wie Fluffy es mag.", sent(client))
    end)

    it("give German {sein} as Fluffys, but Boris' and Strauß' with the sex unknown", function()
        local client = feeder({ locale = "deDE" })
        onlyLine(client, "Nicht {sein} Nachtisch!")
        client.petSex = 3
        assert.are.equal("füttert Fluffy. Nicht ihr Nachtisch!", sent(client))
        client.petSex = 1
        assert.are.equal("füttert Fluffy. Nicht Fluffys Nachtisch!", sent(client))
        for name, possessive in pairs({ Boris = "Boris'", ["Strauß"] = "Strauß'", Max = "Max'" }) do
            client.pet.name = name
            assert.are.equal("füttert " .. name .. ". Nicht " .. possessive .. " Nachtisch!", sent(client))
        end
    end)

    it("are each language's own, and every line uses only {pet} and those", function()
        local M = module(feeder())
        ---@type string[]
        local bad = {}
        local function scan(value, allowed, where)
            if type(value) == "table" then
                for key, inner in pairs(value) do
                    scan(inner, allowed, where .. "." .. tostring(key))
                end
            elseif type(value) == "string" then
                for token in value:gmatch("{([^}]*)}") do
                    local general = token == "pet" or token == "food" or token == "a"
                    if not general and not allowed[token] then bad[#bad + 1] = where .. ": {" .. token .. "}" end
                end
            end
        end
        for code, lines in pairs(M.Lines) do
            scan(lines.emotes, lines.pronouns or {}, code)
            for token, words in pairs(lines.pronouns or {}) do
                assert.is_true(type(words.male) == "string" and type(words.female) == "string", code .. " " .. token)
            end
        end
        table.sort(bad)
        assert.are.same({}, bad)
    end)
end)

describe("FeedEmotes' pet sex", function()
    it("is the player's choice for this pet first, kept under its stable number", function()
        local client = feeder()
        local M = module(client)
        client.petSex = 1
        assert.is_nil(M:PetSex())
        assert.is_true(M:ChoosePetSex(3))
        assert.are.equal(3, M:Char().petSex[3069428])
        assert.are.equal(3, M:PetSex())
        client.pet.name = "Renamed"
        assert.are.equal(3, M:PetSex(), "a rename keeps it")
        client.petGUID = "Pet-0-5250-0-1-165189-0300ABCDEF"
        assert.is_nil(M:PetSex(), "another pet")
        client.petGUID = "Pet-0-5250-0-1-165189-01002ED5F4"
        M:ChoosePetSex(nil)
        assert.is_nil(M:PetSex(), "back to the game's value")
        client.pet = nil
        assert.is_false(M:ChoosePetSex(2), "no pet to keep it for")
    end)

    it("picks the gendered lists, the own-line conditions and the pronouns", function()
        local client = feeder()
        local M = module(client)
        client.petSex = 1
        M:ChoosePetSex(3)
        local pool = M:EmotePool(nil)
        assert.is_true(has(pool, "Good girl!"))
        assert.is_false(has(pool, "Good boy!"))
        M:AddCustomLine("[female] She line.")
        assert.is_true(has(M:EmotePool(nil), "She line."))
    end)

    it("is chosen on the page for the pet out, or not without one", function()
        local client = feeder()
        local sex = module(client):GetOptions().args.sex
        assert.are.equal("Sex of Fluffy", sex.name())
        assert.is_false(sex.disabled())
        assert.are.equal("game", sex.get())
        sex.set({}, "female")
        assert.are.equal("female", sex.get())
        assert.are.equal(3, module(client):PetSex())
        sex.set({}, "game")
        assert.are.equal("game", sex.get())
        client.pet = nil
        assert.are.equal("Summon your pet to choose its sex.", sex.name())
        assert.is_true(sex.disabled())
    end)

    it("is dropped at login for pets in neither stable list", function()
        local client = feeder()
        local petSex = module(client):Char().petSex
        petSex[3069428], petSex[999] = 3, 2
        client.stable.stabled = { 555 }
        client:fire("PLAYER_ENTERING_WORLD")
        assert.are.same({ [3069428] = 3 }, petSex)
    end)

    it("is kept with empty stable lists, a hidden pet number, or no C_StableInfo", function()
        local client = feeder()
        local petSex = module(client):Char().petSex
        petSex[999] = 2
        client.stable.active = {}
        client:fire("PLAYER_ENTERING_WORLD")
        client.stable.active = { SECRET }
        client:fire("PLAYER_ENTERING_WORLD")
        assert.are.same({ [999] = 2 }, petSex)
        client = feeder({ noStableInfo = true })
        module(client):Char().petSex[999] = 2
        client:fire("PLAYER_ENTERING_WORLD")
        assert.are.same({ [999] = 2 }, module(client):Char().petSex)
    end)
end)

describe("FeedEmotes' lists", function()
    it("for a male cat eating Mystery Meat are any, male, mystery and cat", function()
        local client = feeder()
        local M = module(client)
        local emotes = M:LinesInUse().emotes
        local pool = M:EmotePool(MYSTERY_MEAT, "Mystery Meat")
        -- Mystery Meat is no vendor food, so it has a group but no type.
        assert.is_nil(M.FoodTypes[MYSTERY_MEAT])
        local expected = #emotes.any + #emotes.male + #emotes.food.mystery + #emotes.family[M.Family.CAT]
        assert.are.equal(expected, #pool)
    end)

    it("leave out the gendered lists for an unknown sex, and family lines for a hidden family", function()
        local client = feeder()
        local M = module(client)
        local emotes = M:LinesInUse().emotes
        client.petSex = 1
        assert.are.equal(#emotes.any + #emotes.family[M.Family.CAT], #M:EmotePool(nil))
        client.secret = M.Family.CAT
        assert.are.equal(#emotes.any, #M:EmotePool(nil))
        client.secret, client.familyID = nil, 999
        assert.are.equal(#emotes.any, #M:EmotePool(nil), "a family without lines")
    end)

    it("give a food with its own lines its type's lines too", function()
        local client = feeder()
        local emotes = module(client):LinesInUse().emotes
        local pool = module(client):EmotePool(WATERMELON)
        assert.is_true(has(pool, "What a big mouth!"))
        assert.is_true(has(pool, emotes.foodType.fruit[1]))
        assert.is_true(has(module(client):EmotePool(BREAD), emotes.foodType.bread[1]))
    end)

    it("are the client's language, matched on the same family ID", function()
        local client = feeder({ locale = "deDE" })
        local M = module(client)
        local deDE = M.Lines.deDE.emotes
        local pool = M:EmotePool(JERKY)
        assert.is_true(has(pool, deDE.foodType.meat[1]))
        assert.is_true(has(pool, deDE.family[M.Family.CAT][1]))
        assert.is_false(has(pool, M.Lines.enUS.emotes.any[1]))
    end)

    it("are English for a language without lines of its own", function()
        local client = feeder({ locale = "itIT" })
        assert.are.equal(module(client).Lines.enUS, module(client):LinesInUse())
    end)
end)

describe("FeedEmotes' variety", function()
    ---A client left with one line and the given openings and whole sentences.
    local function varied(openings, whole, line)
        local client = feeder({ variety = true })
        onlyLine(client, line)
        local emotes = module(client):LinesInUse().emotes
        emotes.food, emotes.foodType = {}, {}
        emotes.openings, emotes.whole, emotes.wholeFamily = openings, whole, {}
        return client
    end

    it("puts an opening in the feed sentence's place, with the article and the item link", function()
        local client = varied({ "tosses {pet} {a} {food}." }, {}, "Yum!")
        withRandom(first, function()
            local text = client:feed(MYSTERY_MEAT):lastSent()
            assert.are.equal("tosses Fluffy some " .. ItemLink(MYSTERY_MEAT) .. ". Yum!", text)
        end)
        withRandom(last, function()
            -- The feed sentence counts as one of the openings.
            local text = client:feed(MYSTERY_MEAT):lastSent()
            assert.are.equal("feeds Fluffy some " .. ItemLink(MYSTERY_MEAT) .. ". Yum!", text)
        end)
    end)

    it("fills an opening's pronouns, and lets it stand alone without a line", function()
        local client = varied({ "rewards {pet} with {a} {food}, {his} favourite." }, {}, "Mine.")
        local M = module(client)
        M:LinesInUse().emotes.any = {}
        M:Settings().customFallback, M:Settings().customChance = false, 100
        withRandom(first, function()
            local text = client:feed(MYSTERY_MEAT):lastSent()
            assert.are.equal("rewards Fluffy with some " .. ItemLink(MYSTERY_MEAT) .. ", his favourite.", text)
        end)
    end)

    it("uses the plain sentence without a known food", function()
        local client = varied({ "tosses {pet} {a} {food}." }, { "and {pet} share {a} {food}." }, "Yum!")
        withRandom(first, function()
            assert.are.equal("feeds Fluffy. Yum!", sent(client))
        end)
    end)

    it("lets a whole sentence stand alone, for a known food only, never as an own line", function()
        local whole = "and {pet} have a staring contest over {a} {food}. {pet} wins."
        local client = varied({ "tosses {pet} {a} {food}." }, { whole })
        local M = module(client)
        M:LinesInUse().emotes.any = {}
        withRandom(first, function()
            local text = client:feed(MYSTERY_MEAT):lastSent()
            local food = ItemLink(MYSTERY_MEAT)
            assert.are.equal("and Fluffy have a staring contest over some " .. food .. ". Fluffy wins.", text)
        end)
        assert.is_false(has(M:EmotePool(nil), whole))
        M:AddCustomLine("Mine.")
        M:Settings().customChance = 100
        withRandom(last, function()
            local text = client:feed(MYSTERY_MEAT):lastSent()
            assert.are.equal("feeds Fluffy some " .. ItemLink(MYSTERY_MEAT) .. ". Mine.", text)
        end)
    end)

    it("gives a family's whole sentences to that family only", function()
        local client = varied({}, {}, "Yum!")
        local M = module(client)
        local emotes = M:LinesInUse().emotes
        local line = "puts {a} {food} on the table. {pet} knocks it off."
        emotes.wholeFamily = { [M.Family.CAT] = { line } }
        assert.is_false(has(M:EmotePool(MYSTERY_MEAT, "Mystery Meat"), line), "not for another family")
        client.familyID = M.Family.CAT
        assert.is_true(has(M:EmotePool(MYSTERY_MEAT, "Mystery Meat"), line))
        emotes.any, emotes.family = {}, {}
        withRandom(first, function()
            local text = client:feed(MYSTERY_MEAT):lastSent()
            assert.are.equal("puts some " .. ItemLink(MYSTERY_MEAT) .. " on the table. Fluffy knocks it off.", text)
        end)
    end)

    it("always uses the feed sentence in a language without openings", function()
        local client = feeder({ locale = "frFR", variety = true })
        assert.is_nil(module(client):LinesInUse().emotes.openings)
        withRandom(last, function()
            local text = client:feed(MYSTERY_MEAT):lastSent()
            assert.are.equal("donne à Fluffy à manger un(e) ", text:sub(1, #"donne à Fluffy à manger un(e) "))
        end)
    end)

    it("fills every placeholder of the English and German openings and whole sentences", function()
        for _, code in ipairs({ "enUS", "deDE" }) do
            for _, sex in ipairs({ 1, 2, 3 }) do
                local client = feeder({ locale = code, variety = true })
                client.petSex = sex
                local M = module(client)
                local emotes = M:LinesInUse().emotes
                assert.is_true(#emotes.openings >= 10 and #emotes.whole >= 10, code)
                local lists = { emotes.openings, emotes.whole }
                for name, id in pairs(M.Family) do
                    if not M.ExoticFamily[id] then
                        assert.is_true(#emotes.wholeFamily[id] >= 2, code .. " whole lines for " .. name)
                        lists[#lists + 1] = emotes.wholeFamily[id]
                    end
                end
                for _, list in ipairs(lists) do
                    for _, line in ipairs(list) do
                        assert.truthy(line:find("{food}", 1, true), line)
                        local filled = M:FillPlaceholders(line, "Fluffy", ItemLink(MYSTERY_MEAT), "a")
                        assert.is_nil(filled:find("[{}]"), filled)
                        assert.truthy(filled:find("[.!?]$"), filled)
                    end
                end
            end
        end
    end)
end)
