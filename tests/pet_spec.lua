-- The pet helpers every module can use.

describe("the pet helpers", function()
    it("name a spell through C_Spell, GetSpellInfo, or not at all", function()
        assert.are.same({ "Growl", 132270 }, { NewClient().Kennel.SpellInfo(GROWL) })
        assert.are.same({ "Growl", 132270 }, { NewClient({ oldSpellAPI = true }).Kennel.SpellInfo(GROWL) })
        assert.are.same({ "Growl" }, { NewClient({ noTextureAPI = true }).Kennel.SpellInfo(GROWL) })
        assert.are.same({}, { NewClient({ noSpellAPI = true }).Kennel.SpellInfo(GROWL) })
    end)

    it("know the pet's family and its call", function()
        local client = NewClient()
        assert.are.equal(2, client.Kennel.PetFamilyID())
        assert.are.same({ file = 562387 }, client.Kennel.PetAggroSound())
        client.familyID = 6 -- a crocolisk: no call known
        assert.is_nil(client.Kennel.PetAggroSound())
        client.petBar = nil
        assert.is_nil(client.Kennel.PetFamilyID())
        assert.is_nil(client.Kennel.PetAggroSound())
    end)
end)
