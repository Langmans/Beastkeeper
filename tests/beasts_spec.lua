-- The generated beast data: pet ability ranks and the beasts that teach them, loaded here on its
-- own (the module specs use a small data set instead).

---@return table<number, KennelPetAbilityRank>, table<number, KennelBeast>
local function Load()
    local ns = {}
    assert(loadfile("Data/Beasts.lua"))("Kennel", ns)
    return ns.data.petAbilityRanks, ns.data.beasts
end

---@param list number[]
---@param value number
---@return boolean
local function tContains(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local BITE, CLAW_2, SWIPE = 17253, 16828, 1264494
local FOREST_SPIDER, GRIZZLED_BLACK_BEAR, NIGHT_WEB_SPIDER = 30, 1188, 1505
local ELWYNN, TIRISFAL, SPIDER, CAT, BEAR = 1429, 1420, 3, 2, 4

describe("the beast data", function()
    local ranks, beasts = Load()

    it("knows a rank's ability, number, pet level and the families that learn it", function()
        local claw = ranks[CLAW_2]
        assert.are.equal(16827, claw.ability)
        assert.are.equal(2, claw.rank)
        assert.is_true(claw.level > 0)
        assert.is_true(tContains(claw.families, CAT))
    end)

    it("ties every rank to its ability's rank 1", function()
        for id, rank in pairs(ranks) do
            local first = ranks[rank.ability]
            assert.is_not_nil(first, id)
            assert.are.equal(1, first.rank, id)
        end
    end)

    it("names only beasts it has, and only beasts that teach", function()
        local teaches = {}
        for id, rank in pairs(ranks) do
            for _, npc in ipairs(rank.teachers) do
                assert.is_not_nil(beasts[npc], ("rank %d: beast %d"):format(id, npc))
                teaches[npc] = true
                if #rank.families > 0 then
                    assert.is_true(tContains(rank.families, beasts[npc].family), ("rank %d: beast %d"):format(id, npc))
                end
            end
        end
        for npc in pairs(beasts) do
            assert.is_true(teaches[npc], npc)
        end
    end)

    it("places a beast by pins on a map, or by zone when Wowhead has no map", function()
        for npc, beast in pairs(beasts) do
            assert.is_true(beast.minLevel <= beast.maxLevel, npc)
            assert.are_not.equal(beast.pins == nil, beast.zones == nil, npc)
            for map, flat in pairs(beast.pins or {}) do
                assert.is_true(#flat > 0 and #flat % 2 == 0, ("%d on map %d"):format(npc, map))
                for _, v in ipairs(flat) do
                    assert.is_true(v >= 0 and v <= 100, ("%d on map %d"):format(npc, map))
                end
            end
        end
        local spider = beasts[FOREST_SPIDER]
        assert.are.equal(SPIDER, spider.family)
        assert.is_not_nil(spider.pins[ELWYNN])
        assert.is_true(tContains(ranks[BITE].teachers, FOREST_SPIDER))
    end)

    it("has the pet trainers and stable masters, each with a faction it serves and its spots", function()
        local ns = {}
        assert(loadfile("Data/Trainers.lua"))("Kennel", ns)
        local count = { trainer = 0, stable = 0 }
        for npc, trainer in pairs(ns.data.trainers) do
            count[trainer.kind] = count[trainer.kind] + 1
            assert.is_string(trainer.name, npc)
            assert.is_true(trainer.side == nil or trainer.side == "Alliance" or trainer.side == "Horde", npc)
            assert.is_nil(beasts[npc], "no trainer is a beast too")
            for map, flat in pairs(trainer.pins) do
                assert.is_true(#flat > 0 and #flat % 2 == 0, ("%d on map %d"):format(npc, map))
                for _, v in ipairs(flat) do
                    assert.is_true(v >= 0 and v <= 100, ("%d on map %d"):format(npc, map))
                end
            end
        end
        assert.is_true(count.trainer >= 10, "pet trainers")
        assert.is_true(count.stable >= 30, "stable masters")
    end)

    it("has the teachers Wowhead's data leaves out, from its comments and from Tamed", function()
        assert.is_true(tContains(ranks[SWIPE].teachers, GRIZZLED_BLACK_BEAR))
        assert.are.equal(BEAR, beasts[GRIZZLED_BLACK_BEAR].family)
        assert.is_true(tContains(ranks[BITE].teachers, NIGHT_WEB_SPIDER))
        assert.is_not_nil(beasts[NIGHT_WEB_SPIDER].pins[TIRISFAL])
    end)
end)
