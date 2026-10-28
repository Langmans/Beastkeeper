-- What the client's game has (Beastkeeper.features), and modules that need what it lacks: never on,
-- not on the settings page. Burning Crusade has it all; Wrath and later lack loyalty and training
-- points, Cataclysm and later pet happiness and ammo.

---The module switches on the settings page.
local function switches(client)
    return client.Addon:GetOptionsTable().args.modules.args
end

describe("Features", function()
    it("are all there on WoW: Forever and Classic Era", function()
        for _, opts in ipairs({ {}, { era = true } }) do
            local features = NewClient(opts):login().Addon.features
            assert.are.same({ happiness = true, ammo = true, beastTraining = true, beastData = true }, features)
        end
    end)

    it("keep Beast Map off on a client without beast data of its own", function()
        local client = NewClient({
            modules = function(Addon)
                Addon.data.beasts = {}
            end,
        }):login()
        assert.is_false(client.Addon.features.beastData)
        assert.is_false(client.Addon:GetModule("BeastMap"):IsEnabled())
        assert.is_true(client.Addon:GetModule("AbilityLearned"):IsEnabled())
    end)

    it("keep a module whose game part is missing off and off the settings page", function()
        local client = NewClient({ noHappinessAPI = true, noAmmoSlot = true, noTrainingAPI = true }):login()
        local Addon = client.Addon
        assert.are.same({ happiness = false, ammo = false, beastTraining = false, beastData = true }, Addon.features)
        for _, name in ipairs({ "Feeding", "FeedEmotes", "Ammo", "AbilityLearned", "BeastMap" }) do
            assert.is_false(Addon:GetModule(name):IsEnabled(), name)
            assert.is_false(Addon:IsModuleOn(name), name)
            assert.is_nil(switches(client)[name], name .. "'s switch")
            assert.is_nil(Addon:GetOptionsTable().args[name], name .. "'s page")
            Addon:SetModuleOn(name, true)
            assert.is_false(Addon:GetModule(name):IsEnabled(), name .. " stays off")
        end
        for _, name in ipairs({ "CareButton", "AutocastCheck", "PetJournal" }) do
            assert.is_true(Addon:GetModule(name):IsEnabled(), name)
        end
    end)
end)
