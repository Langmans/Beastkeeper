-- The locale files. Their translations come from the packager, so in the repository every
-- language other than English is empty and shows the English strings.

describe("the strings", function()
    it("are English on an English client", function()
        assert.are.equal("Modules", NewClient():login().Addon.L.MODULES)
    end)

    for _, locale in ipairs({ "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
        it("fall back to English on a " .. locale .. " client", function()
            local client = NewClient({ locale = locale }):login()
            assert.are.equal("Modules", client.Addon.L.MODULES)
            assert.are.same({}, client.errors)
        end)
    end
end)
