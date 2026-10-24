-- What the client's game has (Kennel.features), and modules that need what it lacks: never on,
-- not on the settings page. Burning Crusade has it all; Wrath and later lack loyalty and training
-- points, Cataclysm and later pet happiness and ammo.

---The module switches on the settings page.
local function switches(client)
    return client.Kennel:GetOptionsTable().args.modules.args
end

describe("Features", function()
    it("are all there on WoW: Forever and Classic Era", function()
        for _, opts in ipairs({ {}, { era = true } }) do
            local features = NewClient(opts):login().Kennel.features
            assert.are.same({ happiness = true, ammo = true, beastTraining = true, beastData = true }, features)
        end
    end)

    it("keep Beast Map off on a client without beast data of its own", function()
        local client = NewClient({
            modules = function(Kennel)
                Kennel.data.beasts = {}
            end,
        }):login()
        assert.is_false(client.Kennel.features.beastData)
        assert.is_false(client.Kennel:GetModule("BeastMap"):IsEnabled())
        assert.is_true(client.Kennel:GetModule("AbilityLearned"):IsEnabled())
    end)

    it("keep a module whose game part is missing off and off the settings page", function()
        local client = NewClient({ noHappinessAPI = true, noAmmoSlot = true, noTrainingAPI = true }):login()
        local Kennel = client.Kennel
        assert.are.same({ happiness = false, ammo = false, beastTraining = false, beastData = true }, Kennel.features)
        for _, name in ipairs({ "Feeding", "FeedEmotes", "Ammo", "AbilityLearned", "BeastMap" }) do
            assert.is_false(Kennel:GetModule(name):IsEnabled(), name)
            assert.is_false(Kennel:IsModuleOn(name), name)
            assert.is_nil(switches(client)[name], name .. "'s switch")
            assert.is_nil(Kennel:GetOptionsTable().args[name], name .. "'s page")
            Kennel:SetModuleOn(name, true)
            assert.is_false(Kennel:GetModule(name):IsEnabled(), name .. " stays off")
        end
        for _, name in ipairs({ "CareButton", "AutocastCheck", "PetJournal" }) do
            assert.is_true(Kennel:GetModule(name):IsEnabled(), name)
        end
    end)
end)
