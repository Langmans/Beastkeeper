-- Classic Era (1.15): the same Beastkeeper on a client without WoW: Forever's pet APIs. The pet's
-- values come from the old globals, its spellbook from GetSpellBookItemName, unit tooltips from
-- GameTooltip's OnTooltipSetUnit.

describe("Classic Era", function()
    it("logs in a hunter with every module on, without errors", function()
        local client = NewClient({ era = true }):login():advance(10)
        assert.are.same({}, client.errors or {})
        assert.is_truthy(client.Addon:GetModule("Feeding"):IsEnabled())
    end)

    it("reads the pet's happiness from the global", function()
        local client = NewClient({ era = true }):login()
        client:setHappiness(2)
        assert.are.equal(2, client.Addon.PetHappiness())
    end)

    it("reads autocast from the spellbook through GetSpellAutocast", function()
        local client = NewClient({ era = true, noPetBarAPI = true }):login()
        local states = client.Addon:GetModule("AutocastCheck"):PetAutocasts()
        assert.is_true(states.Growl.on)
        assert.is_false(states.Cower.on)
    end)

    it("adds its lines to unit tooltips through OnTooltipSetUnit, once", function()
        local client = NewClient({ era = true }):login():advance(1)
        local lines = client:hoverUnit(client.petGUID)
        assert.is_true(#lines > 0, "the journal's lines")
        local first = #lines
        assert.are.equal(first, #client:hoverUnit(client.petGUID), "not twice")
    end)

    it("keeps the journal without a stable list", function()
        local client = NewClient({ era = true }):login():advance(1)
        local journal = client.Addon:GetModule("PetJournal")
        client:fire("PET_STABLE_UPDATE")
        assert.is_truthy(next(journal:Pets()), "the pet out")
    end)

    it("feeds what the family eats by the item's kind of food, without CanPetEatItem", function()
        local JERKY, BREAD, UNKNOWN = 117, 4540, 99999
        local client = NewClient({ era = true }):login()
        client.petLevel = 10
        client:stock(BREAD, 4):stock(JERKY, 6):stock(UNKNOWN, 1)
        local function fed()
            local ids = {}
            for _, food in ipairs(client.Addon:GetModule("Feeding"):Scan()) do
                ids[#ids + 1] = food.itemID
            end
            return ids
        end
        assert.are.same({ JERKY }, fed(), "a cat eats meat and fish")
        client.familyID = client.Addon.families.bear
        local ids = fed()
        table.sort(ids)
        assert.are.same({ JERKY, BREAD }, ids, "a bear eats bread too")
    end)

    it("feeds food that makes the hunter Well Fed last, read from a scanned tooltip", function()
        local JERKY, WOLF = 117, 2680 -- Spiced Wolf Meat makes you Well Fed
        local client = NewClient({ era = true }):login()
        client.petLevel = 10
        client.unloadedItems[WOLF] = true
        client:stock(WOLF, 2):stock(JERKY, 6)
        ---Per food in feeding order: its item ID and whether it makes the hunter Well Fed.
        local function order()
            local ids = {}
            for _, food in ipairs(client.Addon:GetModule("Feeding"):Scan()) do
                ids[#ids + 1] = { food.itemID, food.wellFed }
            end
            return ids
        end
        local before = order()
        for _, food in ipairs(before) do
            assert.is_false(food[2], "not loaded yet: not known to make you Well Fed")
        end
        client.unloadedItems[WOLF] = nil
        assert.are.same({ { JERKY, false }, { WOLF, true } }, order(), "once loaded, Well Fed and last")
    end)

    it("keeps the stabled pets the stable master shows, and one summoned later stays one pet", function()
        local client = NewClient({ era = true }):login():advance(1)
        local journal = client.Addon:GetModule("PetJournal")
        ---The journal's pets by name: their keys.
        local function keysByName()
            local out = {}
            for key, entry in pairs(journal:Pets()) do
                out[entry.name or "?"] = out[entry.name or "?"] or {}
                table.insert(out[entry.name or "?"], key)
            end
            return out
        end
        client.stableOpen = true
        client.eraStable.current = { "Fluffy", 15, "Cat", "Loyalty Level 4 (Dependable)" }
        client.eraStable.stabled = { { "Kaldor", 16, "Boar", "Loyalty Level 6 (Best Friend)" } }
        client:fire("PET_STABLE_SHOW")
        local pets = keysByName()
        assert.are.equal(1, #pets.Fluffy, "the pet out once")
        assert.are.equal(1, #pets.Kaldor, "the stabled pet, from the stable")
        local kaldor = journal:Pets()[pets.Kaldor[1]]
        assert.are.equal(16, kaldor.level)
        assert.are.equal("Boar", kaldor.family)
        kaldor.deaths = 2
        client.stableOpen = false
        client.petGUID, client.familyName, client.familyID = "Pet-0-5250-0-1-3099-0100AABBCC", "Boar", 5
        client:summon("Kaldor", {}):advance(1)
        pets = keysByName()
        assert.are.equal(1, #pets.Kaldor, "summoned: still one Kaldor")
        assert.are.equal(2, journal:Pets()[pets.Kaldor[1]].deaths, "what the stable's entry held")
        assert.are.equal(tostring(0xAABBCC), pets.Kaldor[1], "under its own number (the GUID's low 32 bits) now")
    end)

    it("reads the pet's spellbook through GetSpellBookItemName", function()
        local client = NewClient({ era = true }):login()
        local spells = client.Addon.PetSpells()
        assert.is_truthy(next(spells), "the pet's spells")
        for name, spell in pairs(spells) do
            assert.are.equal("string", type(name))
            assert.are.equal("number", type(spell.id))
        end
    end)
end)
