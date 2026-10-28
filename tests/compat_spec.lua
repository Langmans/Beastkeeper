-- Beastkeeper.C (Core\Compat.lua): the modern pet, spellbook and tooltip API under Beastkeeper's own name,
-- the same on every client: the client's own function where it has one (WoW: Forever), else the
-- classic way (Classic Era's globals, a tooltip scan, the family's diet). Never written into the
-- game's shared C_ tables.

local JERKY, BREAD, WOLF = 117, 4540, 2680
local GROWL, COWER = 2649, 1742

---Each kind of client in turn, logged in, with a pet: an iterator of (kind, client). One at a
---time, since a new client resets the game's globals.
local function clients()
    local kinds = { { "forever", {} }, { "era", { era = true } } }
    local i = 0
    return function()
        i = i + 1
        local kind = kinds[i]
        if kind then return kind[1], NewClient(kind[2]):login() end
    end
end

describe("Beastkeeper.C", function()
    it("gives the pet's happiness, training points and loyalty on both clients", function()
        for kind, client in clients() do
            local C = client.Addon.C
            client.happiness = 2
            assert.are.equal(2, (C.PetInfo.GetPetHappiness()), kind)
            assert.are.same({ 50, 7 }, { C.PetInfo.GetPetTrainingPoints() }, kind)
            assert.are.equal("Loyalty Level 4 (Dependable)", C.PetInfo.GetPetLoyalty(), kind)
            assert.are.same({ "Meat", "Fish" }, C.PetInfo.GetPetFoodTypes(), kind .. ": a list on both")
        end
    end)

    it("reads the loyalty level and its name from Classic Era's words", function()
        for kind, client in clients() do
            -- As Classic Era says it (seen 2026-10-25 on Season of Discovery).
            client.loyalty = "(Loyalty Level 1) Rebellious"
            assert.are.same({ 1, "Rebellious" }, { client.Addon.PetLoyalty(0, 5) }, kind)
            client.loyalty = "Loyalty Level 4 (Dependable)"
            assert.are.same({ 4, "Dependable" }, { client.Addon.PetLoyalty(0, 5) }, kind)
        end
    end)

    it("tells whether the pet eats an item: the client's answer, else its family's diet", function()
        for kind, client in clients() do
            local C = client.Addon.C
            assert.is_true(C.PetInfo.CanPetEatItem(JERKY), kind)
            assert.is_false(C.PetInfo.CanPetEatItem(BREAD), kind .. ": a cat eats no bread")
        end
    end)

    it("reads the pet's spellbook and autocast the modern way on both clients", function()
        for kind, client in clients() do
            local C = client.Addon.C
            local bank = Enum.SpellBookSpellBank.Pet
            local count = C.SpellBook.HasPetSpells()
            assert.is_true(count > 0, kind)
            local seen = {}
            for index = 1, count do
                local info = C.SpellBook.GetSpellBookItemInfo(index, bank)
                if info and info.spellID then
                    seen[info.spellID] = { info.name, (C.SpellBook.GetSpellBookItemAutoCast(index, bank)) }
                end
            end
            assert.are.same({ "Growl", true }, seen[GROWL], kind)
            assert.are.same({ "Cower", true }, seen[COWER], kind)
            assert.is_true(C.SpellBook.IsSpellKnown(883), kind)
            client.unknownSpells[883] = true
            assert.is_false(C.SpellBook.IsSpellKnown(883), kind)
        end
    end)

    it("gives an item's tooltip lines, read off a hidden tooltip on Classic Era", function()
        for kind, client in clients() do
            local C = client.Addon.C
            local info = C.TooltipInfo.GetItemByID(WOLF)
            assert.are.equal("Spiced Wolf Meat", info.lines[1].leftText, kind)
            assert.is_truthy(info.lines[2].leftText:find("well fed", 1, true), kind)
            client.unloadedItems[JERKY] = true
            assert.are.same({}, C.TooltipInfo.GetItemByID(JERKY).lines, kind .. ": not loaded yet")
        end
    end)

    it("says which parts the client has, and answers nothing without them", function()
        local C = NewClient({ noHappinessAPI = true, noTrainingAPI = true }):login().Addon.C
        assert.is_false(C.Has("PetInfo", "GetPetHappiness"))
        assert.is_false(C.Has("PetInfo", "GetPetTrainingPoints"))
        assert.is_nil(C.PetInfo.GetPetHappiness())
        assert.is_nil(C.PetInfo.GetPetTrainingPoints())
        assert.is_true(C.Has("PetInfo", "GetPetLoyalty"))
        local book = NewClient({ noSpellBookAPI = true }):login().Addon.C.SpellBook
        assert.is_nil(book.GetSpellBookItemAutoCast(1, Enum.SpellBookSpellBank.Pet))
        assert.is_nil(book.GetSpellBookItemInfo(1, Enum.SpellBookSpellBank.Pet))
        local era = NewClient({ era = true }):login().Addon.C
        assert.is_true(era.Has("PetInfo", "GetPetHappiness"), "through the global")
        assert.is_true(era.Has("PetInfo", "CanPetEatItem"), "through the diet")
    end)

    it("leaves the game's own C_ tables alone", function()
        local client = NewClient({ era = true }):login()
        assert.is_nil(C_PetInfo.GetPetHappiness)
        assert.is_nil(C_TooltipInfo)
        assert.is_nil(C_SpellBook.GetSpellBookItemInfo)
        assert.is_truthy(client.Addon.C.PetInfo.GetPetHappiness)
    end)
end)
