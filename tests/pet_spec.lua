-- The pet helpers every module can use.

describe("the pet helpers", function()
    it("name a spell through C_Spell, GetSpellInfo, or not at all", function()
        assert.are.same({ "Growl", 132270 }, { NewClient().Addon.SpellInfo(GROWL) })
        assert.are.same({ "Growl", 132270 }, { NewClient({ oldSpellAPI = true }).Addon.SpellInfo(GROWL) })
        assert.are.same({ "Growl" }, { NewClient({ noTextureAPI = true }).Addon.SpellInfo(GROWL) })
        assert.are.same({}, { NewClient({ noSpellAPI = true }).Addon.SpellInfo(GROWL) })
    end)

    it("give a spell's rank as the client words it, nil for a spell without ranks", function()
        assert.are.same({ "Claw", 132140, "Rank 2" }, { NewClient().Addon.SpellInfo(CLAW_2) })
        assert.are.same({ "Klaue", 132140, "Rang 2" }, { NewClient({ locale = "deDE" }).Addon.SpellInfo(CLAW_2) })
        assert.are.same({ "Claw", 132140, "Rank 2" }, { NewClient({ oldSpellAPI = true }).Addon.SpellInfo(CLAW_2) })
        assert.are.same({ "Growl", 132270 }, { NewClient().Addon.SpellInfo(GROWL) })
    end)

    it("list the pet's spells by name, with ID, rank and icon; commands and odd entries left out", function()
        local client = NewClient()
        -- 99999: a spell the client cannot name.
        client.petBook = { { token = "Attack" }, { CLAW_2 }, { GROWL }, { CLAW_3, noInfo = true }, { 99999 } }
        assert.are.same({
            Claw = { id = CLAW_2, rank = "Rank 2", icon = 132140 },
            Growl = { id = GROWL, icon = 132270 },
        }, client.Addon.PetSpells())
        client.pet = nil
        assert.are.same({}, client.Addon.PetSpells())
        assert.are.same({}, NewClient({ noPetSpellCount = true }).Addon.PetSpells())
        assert.are.same({}, NewClient({ noSpellBookAPI = true }).Addon.PetSpells())
    end)

    it("give the pet's free training points and its total through either API, nil without", function()
        assert.are.same({ 43, 50 }, { NewClient().Addon.PetTrainingPoints() })
        assert.are.same({ 43, 50 }, { NewClient({ oldTrainingAPI = true }).Addon.PetTrainingPoints() })
        assert.is_nil(NewClient({ noTrainingAPI = true }).Addon.PetTrainingPoints())
        local client = NewClient()
        client.trainingPoints = { 5, 9 } -- more used than there are: none free, not a negative
        assert.are.equal(0, client.Addon.PetTrainingPoints())
        client.trainingPoints = { SECRET, 0 }
        assert.is_nil(client.Addon.PetTrainingPoints())
        client.pet = nil
        assert.is_nil(client.Addon.PetTrainingPoints())
    end)

    it("know the pet's family", function()
        local client = NewClient()
        assert.are.equal(2, client.Addon.PetFamilyID())
        client.pet = nil
        assert.is_nil(client.Addon.PetFamilyID())
    end)

    it("give the pet family's attack call, death sound and wound cry", function()
        local client = NewClient()
        assert.are.same({ file = 562387 }, client.Addon.PetSound("AGGRO"))
        assert.are.same({ file = 562391 }, client.Addon.PetSound("DEATH"))
        assert.are.same({ file = 562395 }, client.Addon.PetSound("WOUND"))
        client.familyID = 25 -- a hyena: a wound cry and a call, no death sound
        assert.are.same({ file = 552336 }, client.Addon.PetSound("WOUND"))
        assert.is_nil(client.Addon.PetSound("DEATH"))
        client.familyID = 40 -- a fox, new in WoW: Forever
        assert.are.same({ file = 3593144 }, client.Addon.PetSound("AGGRO"))
        assert.are.same({ file = 3593200 }, client.Addon.PetSound("DEATH"))
        assert.are.same({ file = 3593220 }, client.Addon.PetSound("WOUND"))
        client.familyID = 6 -- a crocolisk: none of them
        assert.is_nil(client.Addon.PetSound("AGGRO"))
        client.pet = nil
        assert.is_nil(client.Addon.PetSound("AGGRO"))
    end)

    it("take the pet's number and the beast it was tamed as from the stable's entry of the pet out", function()
        local client = NewClient()
        client.petGUID = "Pet-0-4615-1-1-165189-3AA8C65C43"
        client.stable.active = {
            { petNumber = 5, name = "Shadow", creatureID = 1131 },
            { petNumber = 3069428, name = "Fluffy", creatureID = 1984 },
        }
        assert.are.equal(3069428, client.Addon.PetNumber())
        assert.are.equal(1984, client.Addon.PetNPC(), "not the GUID's 165189, every pet's")
        client.stable.active = { { petNumber = 7, name = "Someone else", creatureID = 1 } }
        assert.are.equal(0xA8C65C43, client.Addon.PetNumber(), "no entry by its name: the GUID")
        client.stable.active = {
            { petNumber = 7, name = "Fluffy", creatureID = 1 },
            { petNumber = 8, name = "Fluffy", creatureID = 2 },
        }
        assert.are.equal(0xA8C65C43, client.Addon.PetNumber(), "two by its name: which one is unsure")
    end)

    it("give the pet's number from its GUID without a stable entry for it", function()
        local client = NewClient()
        client.petGUID = "Pet-0-5251-0-12345-6219-0201A3F27C"
        assert.are.equal(0x01A3F27C, client.Addon.PetNumber())
        client.petGUID = SECRET
        assert.is_nil(client.Addon.PetNumber())
        client.petGUID = "Creature-0-5251-0-12345-6219-0201A3F27C"
        assert.is_nil(client.Addon.PetNumber(), "not a pet GUID")
        client.pet = nil
        assert.is_nil(client.Addon.PetNumber())
    end)

    it("name a creature as the client does, once the client has it, nil before", function()
        local client = NewClient()
        assert.is_nil(client.Addon.CreatureName(1188), "not cached yet")
        client.creatureNames[1188] = "Grizzlybär"
        assert.are.equal("Grizzlybär", client.Addon.CreatureName(1188))
        client.creatureNames[1188] = nil
        assert.are.equal("Grizzlybär", client.Addon.CreatureName(1188), "kept once known")
        client.creatureNames[30] = SECRET
        assert.is_nil(client.Addon.CreatureName(30), "a hidden value is no name")
        C_TooltipInfo = nil
        assert.is_nil(client.Addon.CreatureName(31))
    end)

    it("give the NPC ID the pet was tamed as: its GUID's sixth field", function()
        local client = NewClient()
        client.petGUID = "Pet-0-5251-0-12345-1188-0201A3F27C"
        assert.are.equal(1188, client.Addon.PetNPC())
        client.petGUID = SECRET
        assert.is_nil(client.Addon.PetNPC())
        client.petGUID = "Creature-0-5251-0-12345-1188-0201A3F27C"
        assert.are.equal(1188, client.Addon.PetNPC(), "a pet tamed this session, until relog")
        client.petGUID = "Player-5251-0ABCDEF0"
        assert.is_nil(client.Addon.PetNPC())
        client.pet = nil
        assert.is_nil(client.Addon.PetNPC())
    end)

    it("tell a value the client hides from one it shows", function()
        local Addon = NewClient().Addon
        assert.is_true(Addon.Readable(40))
        assert.is_true(Addon.Readable(nil))
        assert.is_false(Addon.Readable(SECRET))
    end)
end)
