-- FeedEmotes' data: the lines of every language, the food types and groups, the families, and the
-- English article for every food a pet can eat on WoW: Forever (tests/data: Wowhead's food and
-- meat lists, and what a DevProbes PetFoodScan run found beyond those).

local LANGUAGES = { "enUS", "deDE", "esES", "esMX", "frFR", "koKR", "ruRU" }
local FOOD_TYPES = { "bread", "meat", "fish", "cheese", "fruit", "fungus" }
local FOREVER_FAMILIES = {
    "WOLF",
    "CAT",
    "SPIDER",
    "BEAR",
    "BOAR",
    "CROCOLISK",
    "CARRION_BIRD",
    "CRAB",
    "GORILLA",
    "RAPTOR",
    "TALLSTRIDER",
    "SCORPID",
    "TURTLE",
    "BAT",
    "HYENA",
    "BIRD_OF_PREY",
    "WIND_SERPENT",
    "FOX",
}

-- Families a language has no lines for yet (its pets get the lines for every pet): Fox came with
-- WoW: Forever, after the Feed-O-Matic and FeedPetEmotes translations.
local FAMILY_GAPS = {
    esES = { FOX = true },
    esMX = { FOX = true },
    frFR = { FOX = true },
    koKR = { FOX = true },
    ruRU = { FOX = true },
}

-- Food sold by vendors on Forever, classified by name.
local VENDOR_FOOD = {
    bread = { 4540, 4541, 4542, 4544, 4601, 8950, 252026, 278119 },
    meat = { 117, 2287, 3770, 3771, 4599, 8952, 11444, 17119, 252029, 278121 },
    fish = { 787, 4592, 4593, 4594, 8957, 21552 },
    cheese = { 414, 422, 1707, 2070, 3927, 8932, 252030 },
    fruit = { 4536, 4537, 4538, 4539, 4602, 8953, 13810, 252032 },
    fungus = { 4604, 4605, 4606, 4607, 4608, 8948 },
}

local FOOD_LISTS = {
    ["forever-food.lua"] = assert(loadfile("tests/data/forever-food.lua"))(),
    ["forever-scan.lua"] = assert(loadfile("tests/data/forever-scan.lua"))(),
}

local M = NewClient().Kennel:GetModule("FeedEmotes")

---How many %s a format has.
local function formats(text)
    local _, n = text:gsub("%%s", "")
    return n
end

describe("FeedEmotes' lines", function()
    it("have feed sentences with the right number of arguments in every language", function()
        for _, code in ipairs(LANGUAGES) do
            local lines = M.Lines[code]
            if type(lines.feed) == "string" then assert.are.equal(2, formats(lines.feed), code) end
            assert.are.equal(1, formats(lines.feedNoFood), code)
        end
        assert.are.equal(M.Lines.esES, M.Lines.esMX, "esMX uses the esES lines")
    end)

    it("hold non-empty lines under known food groups and families", function()
        ---@type table<string, true>, table<number, true>
        local groups, families = {}, {}
        for _, group in pairs(M.FoodGroups) do
            groups[group] = true
        end
        for _, id in pairs(M.Family) do
            families[id] = true
        end
        local function check(list, where)
            assert.is_true(type(list) == "table" and #list > 0, where)
            for i, line in ipairs(list) do
                assert.is_true(type(line) == "string" and line ~= "", where .. "[" .. i .. "]")
            end
        end
        for _, code in ipairs(LANGUAGES) do
            local emotes = M.Lines[code].emotes
            check(emotes.any, code .. ".any")
            check(emotes.male, code .. ".male")
            check(emotes.female, code .. ".female")
            for group, list in pairs(emotes.food) do
                assert.is_true(groups[group], code .. ": food group " .. group)
                check(list, code .. ".food." .. group)
            end
            for id, list in pairs(emotes.family) do
                assert.is_true(families[id], code .. ": family " .. id)
                check(list, code .. ".family." .. id)
            end
        end
    end)

    it("have at least three lines per family and two per food type in every language, but its gaps", function()
        ---@type string[]
        local short = {}
        for _, code in ipairs(LANGUAGES) do
            local emotes = M.Lines[code].emotes
            local gaps = FAMILY_GAPS[code] or {}
            for name, id in pairs(M.Family) do
                local count = #(emotes.family[id] or {})
                if gaps[name] then
                    if count > 0 then short[#short + 1] = code .. " " .. name .. " is no gap any more" end
                elseif count < 3 then
                    short[#short + 1] = code .. " " .. name
                end
            end
            for _, foodType in ipairs(FOOD_TYPES) do
                if #((emotes.foodType or {})[foodType] or {}) < 2 then short[#short + 1] = code .. " " .. foodType end
            end
        end
        table.sort(short)
        assert.are.same({}, short)
    end)

    it("have 20 lines for every pet and 10 per family in English and German", function()
        for _, code in ipairs({ "enUS", "deDE" }) do
            local emotes = M.Lines[code].emotes
            assert.are.equal(20, #emotes.any, code)
            for name, id in pairs(M.Family) do
                assert.are.equal(10, #emotes.family[id], code .. " " .. name)
            end
        end
    end)

    it("never hold the same line twice in a list", function()
        ---@type string[]
        local twice = {}
        local function check(list, where)
            ---@type table<string, true>
            local seen = {}
            for _, line in ipairs(list) do
                if seen[line] then twice[#twice + 1] = where .. ": " .. line end
                seen[line] = true
            end
        end
        for _, code in ipairs(LANGUAGES) do
            local emotes = M.Lines[code].emotes
            check(emotes.any, code .. " any")
            for name, id in pairs(M.Family) do
                check(emotes.family[id] or {}, code .. " " .. name)
            end
        end
        table.sort(twice)
        assert.are.same({}, twice)
    end)
end)

describe("FeedEmotes' food and families", function()
    it("know the 17 families tameable on WoW: Forever", function()
        for _, name in ipairs(FOREVER_FAMILIES) do
            assert.is_number(M.Family[name], name)
            assert.is_nil(M.ExoticFamily[M.Family[name]], name)
        end
    end)

    it("give every vendor food its type, and only the six types", function()
        for foodType, items in pairs(VENDOR_FOOD) do
            for _, itemID in ipairs(items) do
                assert.are.equal(foodType, M.FoodTypes[itemID], "item " .. itemID)
            end
        end
        ---@type table<string, true>
        local known = {}
        for _, foodType in ipairs(FOOD_TYPES) do
            known[foodType] = true
        end
        for itemID, foodType in pairs(M.FoodTypes) do
            assert.is_true(known[foodType], "item " .. itemID)
        end
    end)
end)

describe("FeedEmotes' English article", function()
    local article = M.Lines.enUS.article
    local feed = M.Lines.enUS.feed

    it("is a or an by the first letter, some for uncounted food and plurals, by the head noun", function()
        local cases = {
            ["Rockscale Cod"] = "a",
            ["Apple"] = "an",
            ["egg"] = "an",
            ["Mystery Meat"] = "some",
            ["Tough Jerky"] = "some",
            ["Alterac Swiss"] = "some",
            ["Delicious Cave Mold"] = "some",
            ["Deep Fried Plantains"] = "some",
            ["Bread with Butter"] = "some",
            ["Haunch of Meat"] = "a",
            ["Tough Hunk of Bread"] = "a",
            ["Spongy Morel"] = "a",
            ["Tel'Abim Banana"] = "a",
            ["Glass"] = "a",
            ["Octopus"] = "an",
        }
        for name, expected in pairs(cases) do
            assert.are.equal(expected, article(name), name)
        end
    end)

    it("is taken from the name inside an item link", function()
        local apple = "|cffffffff|Hitem:4536::::::::60:::::|h[Apple]|h|r"
        local jerky = "|cffffffff|Hitem:117::::::::60:::::|h[Tough Jerky]|h|r"
        assert.are.equal("feeds Fluffy an " .. apple .. ". ", feed("Fluffy", apple))
        assert.are.equal("feeds Fluffy some " .. jerky .. ". ", feed("Fluffy", jerky))
    end)

    it("is right for every food a pet can eat on WoW: Forever", function()
        assert.is_true(#FOOD_LISTS["forever-food.lua"] > 300)
        assert.is_true(#FOOD_LISTS["forever-scan.lua"] > 100)
        ---@type table<number, true>
        local wowhead = {}
        for _, row in ipairs(FOOD_LISTS["forever-food.lua"]) do
            wowhead[row[1]] = true
        end
        ---@type string[]
        local wrong = {}
        for file, rows in pairs(FOOD_LISTS) do
            for _, row in ipairs(rows) do
                local id, name, expected = row[1], row[2], row[4]
                if file == "forever-scan.lua" and wowhead[id] then wrong[#wrong + 1] = name .. " is in both" end
                if article(name) ~= expected then
                    wrong[#wrong + 1] = ("%s: %s %s (%d), expected %s"):format(file, article(name), name, id, expected)
                end
            end
        end
        table.sort(wrong)
        assert.are.same({}, wrong)
    end)
end)
