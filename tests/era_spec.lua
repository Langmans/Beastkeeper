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
