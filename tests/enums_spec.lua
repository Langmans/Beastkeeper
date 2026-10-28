-- Beastkeeper's names for the game's bare values that no Enum of the game covers: the pet's happiness
-- (GetPetHappiness), a unit's sex (UnitSex), the factions (UnitFactionGroup) and the raid target
-- marks (SetRaidTarget, /tm).

describe("Beastkeeper's enums", function()
    local Addon

    before_each(function()
        Addon = NewClient():login().Addon
    end)

    it("names the pet's happiness as GetPetHappiness gives it", function()
        assert.are.same({ unhappy = 1, content = 2, happy = 3 }, Addon.happiness)
    end)

    it("names the sexes as UnitSex gives them", function()
        assert.are.same({ unknown = 1, male = 2, female = 3 }, Addon.sex)
    end)

    it("makes a string enum from a list whose keys are its values", function()
        assert.are.same({ a = "a", bCd = "bCd" }, Addon.SelfKeyedEnum({ "a", "bCd" }))
    end)

    it("names the pet specializations and diets each family's info uses", function()
        assert.are.same({ ferocity = "ferocity", cunning = "cunning", tenacity = "tenacity" }, Addon.petSpecs)
        assert.are.equal(Addon.petSpecs.ferocity, Addon.familyInfo[Addon.families.cat].spec)
        assert.are.same({ Addon.diets.meat, Addon.diets.fish }, Addon.familyInfo[Addon.families.cat].diet)
        for key, value in pairs(Addon.diets) do
            assert.are.equal(key, value)
        end
    end)

    it("names the factions as UnitFactionGroup gives them", function()
        assert.are.same({ alliance = "Alliance", horde = "Horde" }, Addon.factions)
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
        }, Addon.raidMarks)
    end)
end)
