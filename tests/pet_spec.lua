-- The pet helpers every module can use.

describe("the pet helpers", function()
    it("name a spell through C_Spell, GetSpellInfo, or not at all", function()
        assert.are.same({ "Growl", 132270 }, { NewClient().Kennel.SpellInfo(GROWL) })
        assert.are.same({ "Growl", 132270 }, { NewClient({ oldSpellAPI = true }).Kennel.SpellInfo(GROWL) })
        assert.are.same({ "Growl" }, { NewClient({ noTextureAPI = true }).Kennel.SpellInfo(GROWL) })
        assert.are.same({}, { NewClient({ noSpellAPI = true }).Kennel.SpellInfo(GROWL) })
    end)

    it("give a spell's rank as the client words it, nil for a spell without ranks", function()
        assert.are.same({ "Claw", 132140, "Rank 2" }, { NewClient().Kennel.SpellInfo(CLAW_2) })
        assert.are.same({ "Klaue", 132140, "Rang 2" }, { NewClient({ locale = "deDE" }).Kennel.SpellInfo(CLAW_2) })
        assert.are.same({ "Claw", 132140, "Rank 2" }, { NewClient({ oldSpellAPI = true }).Kennel.SpellInfo(CLAW_2) })
        assert.are.same({ "Growl", 132270 }, { NewClient().Kennel.SpellInfo(GROWL) })
    end)

    it("list the pet's spells by name, with ID, rank and icon; commands and odd entries left out", function()
        local client = NewClient()
        -- 99999: a spell the client cannot name.
        client.petBook = { { token = "Attack" }, { CLAW_2 }, { GROWL }, { CLAW_3, noInfo = true }, { 99999 } }
        assert.are.same({
            Claw = { id = CLAW_2, rank = "Rank 2", icon = 132140 },
            Growl = { id = GROWL, icon = 132270 },
        }, client.Kennel.PetSpells())
        client.pet = nil
        assert.are.same({}, client.Kennel.PetSpells())
        assert.are.same({}, NewClient({ noPetSpellCount = true }).Kennel.PetSpells())
        assert.are.same({}, NewClient({ noSpellBookAPI = true }).Kennel.PetSpells())
    end)

    it("give the pet's free training points and its total through either API, nil without", function()
        assert.are.same({ 43, 50 }, { NewClient().Kennel.PetTrainingPoints() })
        assert.are.same({ 43, 50 }, { NewClient({ oldTrainingAPI = true }).Kennel.PetTrainingPoints() })
        assert.is_nil(NewClient({ noTrainingAPI = true }).Kennel.PetTrainingPoints())
        local client = NewClient()
        client.trainingPoints = { 5, 9 } -- more used than there are: none free, not a negative
        assert.are.equal(0, client.Kennel.PetTrainingPoints())
        client.trainingPoints = { SECRET, 0 }
        assert.is_nil(client.Kennel.PetTrainingPoints())
        client.pet = nil
        assert.is_nil(client.Kennel.PetTrainingPoints())
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
        client.familyID = 40 -- a fox, new in WoW: Forever
        assert.are.same({ file = 3593144 }, client.Kennel.PetSound("AGGRO"))
        assert.are.same({ file = 3593200 }, client.Kennel.PetSound("DEATH"))
        assert.are.same({ file = 3593220 }, client.Kennel.PetSound("WOUND"))
        client.familyID = 6 -- a crocolisk: none of them
        assert.is_nil(client.Kennel.PetSound("AGGRO"))
        client.pet = nil
        assert.is_nil(client.Kennel.PetSound("AGGRO"))
    end)

    it("give the pet's number: the low 32 bits of its GUID's last field, the stable's petNumber", function()
        local client = NewClient()
        client.petGUID = "Pet-0-5251-0-12345-6219-0201A3F27C"
        assert.are.equal(0x01A3F27C, client.Kennel.PetNumber())
        client.petGUID = SECRET
        assert.is_nil(client.Kennel.PetNumber())
        client.petGUID = "Creature-0-5251-0-12345-6219-0201A3F27C"
        assert.is_nil(client.Kennel.PetNumber(), "not a pet GUID")
        client.pet = nil
        assert.is_nil(client.Kennel.PetNumber())
    end)

    it("name a creature as the client does, once the client has it, nil before", function()
        local client = NewClient()
        assert.is_nil(client.Kennel.CreatureName(1188), "not cached yet")
        client.creatureNames[1188] = "Grizzlybär"
        assert.are.equal("Grizzlybär", client.Kennel.CreatureName(1188))
        client.creatureNames[1188] = nil
        assert.are.equal("Grizzlybär", client.Kennel.CreatureName(1188), "kept once known")
        client.creatureNames[30] = SECRET
        assert.is_nil(client.Kennel.CreatureName(30), "a hidden value is no name")
        C_TooltipInfo = nil
        assert.is_nil(client.Kennel.CreatureName(31))
    end)

    it("tell a value the client hides from one it shows", function()
        local Kennel = NewClient().Kennel
        assert.is_true(Kennel.Readable(40))
        assert.is_true(Kennel.Readable(nil))
        assert.is_false(Kennel.Readable(SECRET))
    end)
end)
