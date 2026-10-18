-- The addon object, the saved settings and the module switches.

---A module that reports its OnEnable/OnDisable calls to the spies module.enabled and
---module.disabled. The handlers themselves stay functions: AceAddon only calls a function.
---@param Kennel Kennel
---@param name string
---@param fields table?
local function spyModule(Kennel, name, fields)
    local module = Kennel:NewModule(name)
    for key, value in pairs(fields or {}) do
        module[key] = value
    end
    module.enabled, module.disabled = spy.new(function() end), spy.new(function() end)
    function module:OnEnable()
        self.enabled(self)
    end
    function module:OnDisable()
        self.disabled(self)
    end
    return module
end

local function twoModules(Kennel)
    spyModule(Kennel, "Alpha", { defaults = { profile = { size = 3 } } })
    spyModule(Kennel, "Beta", { enabledByDefault = false })
end

describe("Kennel", function()
    local client, Kennel, alpha, beta

    local function start(opts)
        opts = opts or {}
        opts.modules = twoModules
        client = NewClient(opts):login()
        Kennel = client.Kennel
        alpha, beta = Kennel:GetModule("Alpha"), Kennel:GetModule("Beta")
    end

    it("loads all of Ace3 and the core without errors", function()
        client = NewClient():login()
        assert.are.same({}, client.errors)
        assert.is_table(client.Kennel.db)
    end)

    it("registers only the events this client has, so switching modules off stays quiet", function()
        for _, opts in ipairs({ {}, { noEventUtils = true } }) do
            opts.unknownEvents = { "LEARNED_SPELL_IN_TAB", "VIGNETTE_MINIMAP_UPDATED", "UNIT_HAPPINESS" }
            local real = NewClient(opts):login()
            real.Kennel.db:SetProfile("other")
            for name in pairs(real.Kennel.modules) do
                real.Kennel:SetModuleOn(name, false)
            end
            assert.are.same({}, real.errors)
        end
    end)

    describe("module switches", function()
        before_each(function()
            start()
        end)

        it("are on by default unless the module says otherwise", function()
            assert.is_true(Kennel:IsModuleOn("Alpha"))
            assert.is_false(Kennel:IsModuleOn("Beta"))
            assert.is_true(alpha:IsEnabled())
            assert.is_false(beta:IsEnabled())
            assert.spy(alpha.enabled).was.called(1)
            assert.spy(beta.enabled).was_not.called()
        end)

        it("give a module with defaults its own namespace", function()
            assert.are.equal(3, alpha.db.profile.size)
            assert.is_nil(beta.db)
        end)

        it("start and stop a module through SetModuleOn and save the switch", function()
            Kennel:SetModuleOn("Alpha", false)
            Kennel:SetModuleOn("Beta", true)
            assert.is_false(alpha:IsEnabled())
            assert.is_true(beta:IsEnabled())
            assert.spy(alpha.disabled).was.called(1)

            client:logout()
            assert.are.same({ Alpha = false, Beta = true }, Saved().profiles.Default.modules)
        end)

        it("are not saved while they keep their default", function()
            client:logout()
            -- AceDB keeps the empty profile itself on a main database.
            assert.are.same({}, Saved().profiles.Default)
        end)
    end)

    it("takes a saved switch over the default at login", function()
        start({ saved = { profileKeys = {}, profiles = { Default = { modules = { Alpha = false, Beta = true } } } } })
        assert.is_false(alpha:IsEnabled())
        assert.is_true(beta:IsEnabled())
    end)

    describe("a profile change", function()
        before_each(function()
            start()
        end)

        it("restarts the running modules from the new profile", function()
            Kennel.db:SetProfile("Tank")
            assert.spy(alpha.disabled).was.called(1)
            assert.spy(alpha.enabled).was.called(2)
            assert.spy(beta.enabled).was_not.called()
        end)

        it("follows the switches of the profile switched to, copied or reset", function()
            Kennel.db:SetProfile("Tank")
            Kennel:SetModuleOn("Beta", true)
            Kennel.db:SetProfile("Default")
            assert.is_false(beta:IsEnabled(), "off again in Default")

            Kennel.db:CopyProfile("Tank")
            assert.is_true(beta:IsEnabled(), "copied from Tank")

            Kennel.db:ResetProfile()
            assert.is_false(beta:IsEnabled(), "back to the default")
        end)
    end)
end)
