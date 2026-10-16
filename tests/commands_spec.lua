-- The /kennel slash command.

local function modules(Kennel)
    local autocast = Kennel:NewModule("Autocast")
    autocast.title = "Autocast Check"
    autocast.command = "autocast"
    autocast.commands = {
        kite = { desc = "switch kite mode", func = spy.new(function() end) },
        tank = { desc = "switch tank mode", func = spy.new(function() end) },
    }
    local off = Kennel:NewModule("Off")
    off.enabledByDefault = false
    off.command = "off"
    off.commands = { go = { desc = "go", func = spy.new(function() end) } }
    -- A command word without any commands.
    Kennel:NewModule("Bare").command = "bare"
end

describe("/kennel", function()
    local client, Kennel

    before_each(function()
        client = NewClient({ modules = modules }):login()
        Kennel = client.Kennel
    end)

    it("alone opens the options page", function()
        client:slash("")
        assert.are.same({ Kennel.optionsCategoryID }, client.opened)
    end)

    it("hands a module command the module and the rest of the line", function()
        local autocast = Kennel:GetModule("Autocast")
        local kite = autocast.commands.kite.func
        client:slash("autocast kite on")
        assert.spy(kite).was.called_with(autocast, "on")
        client:slash("AUTOCAST KITE")
        assert.spy(kite).was.called_with(autocast, "")
    end)

    it("says a module is off instead of running its command", function()
        client:slash("off go")
        assert.spy(Kennel:GetModule("Off").commands.go.func).was_not.called()
        assert.is_true(client:printedContains("Off is off."))
    end)

    for _, line in ipairs({ "nope", "autocast", "autocast nope", "bare thing" }) do
        it("reports an unknown command: " .. line, function()
            client:slash(line)
            assert.is_true(client:printedContains("Unknown command: " .. line))
        end)
    end

    it("help lists every module command, sorted", function()
        client:slash("help")
        local printed = table.concat(client.printed, "\n")
        assert.truthy(printed:find("/kennel - open the options", 1, true))
        local kite = printed:find("/kennel autocast kite - switch kite mode", 1, true)
        local tank = printed:find("/kennel autocast tank - switch tank mode", 1, true)
        local go = printed:find("/kennel off go - go", 1, true)
        assert.truthy(kite and tank and go and kite < tank and tank < go, printed)
    end)
end)
