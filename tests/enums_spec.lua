-- Kennel's names for the game's bare values that no Enum of the game covers: the pet's happiness
-- (GetPetHappiness), a unit's sex (UnitSex), the factions (UnitFactionGroup) and the raid target
-- marks (SetRaidTarget, /tm).

describe("Kennel's enums", function()
    local Kennel

    before_each(function()
        Kennel = NewClient():login().Kennel
    end)

    it("names the pet's happiness as GetPetHappiness gives it", function()
        assert.are.same({ unhappy = 1, content = 2, happy = 3 }, Kennel.happiness)
    end)

    it("names the sexes as UnitSex gives them", function()
        assert.are.same({ unknown = 1, male = 2, female = 3 }, Kennel.sex)
    end)

    it("names the pet specializations and diets each family's info uses", function()
        assert.are.same({ ferocity = "ferocity", cunning = "cunning", tenacity = "tenacity" }, Kennel.petSpecs)
        assert.are.equal(Kennel.petSpecs.ferocity, Kennel.familyInfo[Kennel.families.cat].spec)
        assert.are.same({ Kennel.diets.meat, Kennel.diets.fish }, Kennel.familyInfo[Kennel.families.cat].diet)
        for key, value in pairs(Kennel.diets) do
            assert.are.equal(key, value)
        end
    end)

    it("names the factions as UnitFactionGroup gives them", function()
        assert.are.same({ alliance = "Alliance", horde = "Horde" }, Kennel.factions)
    end)

    it("names the raid target marks as SetRaidTarget and /tm take them", function()
        assert.are.same({
            star = 1,
            circle = 2,
            diamond = 3,
            triangle = 4,
            moon = 5,
            square = 6,
            cross = 7,
            skull = 8,
        }, Kennel.raidMarks)
    end)
end)
