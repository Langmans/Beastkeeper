-- Classic Era (1.15): the same Kennel on a client without WoW: Forever's pet APIs. The pet's
-- values come from the old globals, its spellbook from GetSpellBookItemName, unit tooltips from
-- GameTooltip's OnTooltipSetUnit.

describe("Classic Era", function()
    it("logs in a hunter with every module on, without errors", function()
        local client = NewClient({ era = true }):login():advance(10)
        assert.are.same({}, client.errors or {})
        assert.is_truthy(client.Kennel:GetModule("Feeding"):IsEnabled())
    end)

    it("reads the pet's happiness from the global", function()
        local client = NewClient({ era = true }):login()
        client:setHappiness(2)
        assert.are.equal(2, client.Kennel.PetHappiness())
    end)

    it("reads autocast from the spellbook through GetSpellAutocast", function()
        local client = NewClient({ era = true, noPetBarAPI = true }):login()
        local states = client.Kennel:GetModule("AutocastCheck"):PetAutocasts()
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
        local journal = client.Kennel:GetModule("PetJournal")
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
            for _, food in ipairs(client.Kennel:GetModule("Feeding"):Scan()) do
                ids[#ids + 1] = food.itemID
            end
            return ids
        end
        assert.are.same({ JERKY }, fed(), "a cat eats meat and fish")
        client.familyID = client.Kennel.families.bear
        local ids = fed()
        table.sort(ids)
        assert.are.same({ JERKY, BREAD }, ids, "a bear eats bread too")
    end)

    it("reads the pet's spellbook through GetSpellBookItemName", function()
        local client = NewClient({ era = true }):login()
        local spells = client.Kennel.PetSpells()
        assert.is_truthy(next(spells), "the pet's spells")
        for name, spell in pairs(spells) do
            assert.are.equal("string", type(name))
            assert.are.equal("number", type(spell.id))
        end
    end)
end)
