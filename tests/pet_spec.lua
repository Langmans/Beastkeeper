-- The pet helpers every module can use.

describe("the pet helpers", function()
    it("name a spell through C_Spell, GetSpellInfo, or not at all", function()
        assert.are.same({ "Growl", 132270 }, { NewClient().Kennel.SpellInfo(GROWL) })
        assert.are.same({ "Growl", 132270 }, { NewClient({ oldSpellAPI = true }).Kennel.SpellInfo(GROWL) })
        assert.are.same({ "Growl" }, { NewClient({ noTextureAPI = true }).Kennel.SpellInfo(GROWL) })
        assert.are.same({}, { NewClient({ noSpellAPI = true }).Kennel.SpellInfo(GROWL) })
    end)

    it("know the pet's family", function()
        local client = NewClient()
        assert.are.equal(2, client.Kennel.PetFamilyID())
        client.pet = nil
        assert.is_nil(client.Kennel.PetFamilyID())
    end)

    it("give the pet family's attack call, death sound and wound cry", function()
        local client = NewClient()
        assert.are.same({ file = 562387 }, client.Kennel.PetSound("AGGRO"))
        assert.are.same({ file = 562391 }, client.Kennel.PetSound("DEATH"))
        assert.are.same({ file = 562395 }, client.Kennel.PetSound("WOUND"))
        client.familyID = 25 -- a hyena: a wound cry and a call, no death sound
        assert.are.same({ file = 552336 }, client.Kennel.PetSound("WOUND"))
        assert.is_nil(client.Kennel.PetSound("DEATH"))
        client.familyID = 6 -- a crocolisk: none of them
        assert.is_nil(client.Kennel.PetSound("AGGRO"))
        client.pet = nil
        assert.is_nil(client.Kennel.PetSound("AGGRO"))
    end)

    it("tell a value the client hides from one it shows", function()
        local Kennel = NewClient().Kennel
        assert.is_true(Kennel.Readable(40))
        assert.is_true(Kennel.Readable(nil))
        assert.is_false(Kennel.Readable(SECRET))
    end)
end)
