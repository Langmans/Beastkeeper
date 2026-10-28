-- The /beastkeeper slash command.

local function modules(Addon)
    local autocast = Addon:NewModule("Autocast")
    autocast.title = "Autocast Check"
    -- Its own word: the real AutocastCheck has "autocast", and which of two matches is found
    -- would depend on table order.
    autocast.command = "fake"
    autocast.commands = {
        kite = { desc = "switch kite mode", func = spy.new(function() end) },
        tank = { desc = "switch tank mode", func = spy.new(function() end) },
    }
    local off = Addon:NewModule("Off")
    off.enabledByDefault = false
    off.command = "off"
    off.commands = { go = { desc = "go", func = spy.new(function() end) } }
    -- A command word without any commands.
    Addon:NewModule("Bare").command = "bare"
end

describe("/beastkeeper", function()
    local client, Addon

    before_each(function()
        client = NewClient({ modules = modules }):login()
        Addon = client.Addon
    end)

    it("config opens the options page", function()
        client:slash("config")
        assert.are.same({ Addon.optionsCategoryID }, client.opened)
    end)

    it("hands a module command the module and the rest of the line", function()
        local autocast = Addon:GetModule("Autocast")
        local kite = autocast.commands.kite.func
        client:slash("fake kite on")
        assert.spy(kite).was.called_with(autocast, "on")
        client:slash("FAKE KITE")
        assert.spy(kite).was.called_with(autocast, "")
    end)

    it("says a module is off instead of running its command", function()
        client:slash("off go")
        assert.spy(Addon:GetModule("Off").commands.go.func).was_not.called()
        assert.is_true(client:printedContains("Off is off."))
    end)

    for _, line in ipairs({ "nope", "fake", "fake nope", "bare thing" }) do
        it("reports an unknown command: " .. line, function()
            client:slash(line)
            assert.is_true(client:printedContains("Unknown command: " .. line))
        end)
    end

    it("help lists every module command, sorted", function()
        client:slash("help")
        local printed = table.concat(client.printed, "\n")
        assert.truthy(printed:find("/beastkeeper - open or close Beastkeeper's window", 1, true))
        assert.truthy(printed:find("/beastkeeper config - open the options", 1, true))
        local kite = printed:find("/beastkeeper fake kite - switch kite mode", 1, true)
        local tank = printed:find("/beastkeeper fake tank - switch tank mode", 1, true)
        local go = printed:find("/beastkeeper off go - go", 1, true)
        assert.truthy(kite and tank and go and kite < tank and tank < go, printed)
    end)
end)
