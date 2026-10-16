-- The options table and the pages in the settings window.

local function modules(Kennel)
    local alpha = Kennel:NewModule("Alpha")
    alpha.title = "Alpha Title"
    alpha.description = "Does alpha things."
    function alpha:GetOptions()
        return { args = { size = { type = "range", name = "Size", min = 1, max = 5, step = 1 } } }
    end
    local beta = Kennel:NewModule("Beta")
    beta.enabledByDefault = false
    function beta:GetOptions()
        return { name = "Beta Page", args = {} }
    end
    Kennel:NewModule("Gamma")
end

describe("the options", function()
    local client, options

    before_each(function()
        client = NewClient({ modules = modules }):login()
        options = client.Kennel:GetOptionsTable()
    end)

    it("pass AceConfig's validation", function()
        -- Raises on any malformed entry.
        LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(options, "Kennel")
        assert.are.same({}, client.errors)
    end)

    describe("module switches", function()
        it("carry the module's title, or its name", function()
            local switches = options.args.modules.args
            assert.are.equal("Alpha Title", switches.Alpha.name)
            assert.are.equal("Does alpha things.", switches.Alpha.desc)
            assert.are.equal("Gamma", switches.Gamma.name)
            assert.is_table(switches.intro, "explains the switches")
        end)

        it("show and change the module's state", function()
            local switches = options.args.modules.args
            assert.is_false(switches.Beta.get())
            switches.Beta.set({}, true)
            assert.is_true(client.Kennel:GetModule("Beta"):IsEnabled())
            assert.is_true(client.Kennel:GetOptionsTable().args.modules.args.Beta.get())
        end)
    end)

    it("give a module with options its own page, greyed out while it is off", function()
        local args = options.args
        assert.are.equal("group", args.Alpha.type)
        assert.are.equal("Alpha Title", args.Alpha.name, "named after the module")
        assert.are.equal("Beta Page", args.Beta.name, "a name of its own wins")
        assert.is_nil(args.Gamma, "no options, no page")
        assert.is_false(args.Alpha.disabled())
        assert.is_true(args.Beta.disabled())
    end)

    describe("Profiles page", function()
        local function keys(tbl)
            local list = {}
            for key in pairs(tbl) do
                list[#list + 1] = key
            end
            table.sort(list)
            return list
        end

        it("lists every entry of AceDBOptions' own page", function()
            -- No other addon is loaded here, so the shared table holds only AceDBOptions' entries.
            -- A new AceDBOptions version with more entries fails this until PROFILE_OPTIONS has them.
            local shared = LibStub("AceDBOptions-3.0"):GetOptionsTable(client.Kennel.db)
            assert.are.same(keys(shared.args), keys(options.args.profiles.args))
        end)

        it("leaves out what other addons write into AceDBOptions' shared table", function()
            -- As RestedXP Guides does with its guide buttons.
            local shared = LibStub("AceDBOptions-3.0"):GetOptionsTable(client.Kennel.db)
            shared.args.resetGuideProgress = { type = "execute", name = "Reset Guide Progress", func = function() end }
            local profiles = client.Kennel:GetOptionsTable().args.profiles
            assert.is_nil(profiles.args.resetGuideProgress)
            assert.is_table(profiles.args.reset)
            shared.args.resetGuideProgress = nil
        end)

        it("still changes KennelDB's profile", function()
            local profiles = options.args.profiles
            -- AceConfig calls a string `set` on the handler with AceConfig's info for the option.
            profiles.handler:SetProfile({ arg = nil }, "Tank")
            assert.are.equal("Tank", client.Kennel.db:GetCurrentProfile())
        end)
    end)
end)

describe("the settings window", function()
    it("gets Kennel, a page per module with options and Profiles", function()
        local client = NewClient({ modules = modules }):login()
        local names = {}
        for _, category in pairs(client.categories) do
            local parent = category.parent and category.parent.name or "-"
            names[#names + 1] = parent .. " > " .. category.name
        end
        table.sort(names)
        assert.are.same({ "- > Kennel", "Kennel > Alpha Title", "Kennel > Beta Page", "Kennel > Profiles" }, names)
    end)

    it("uses the page name as category ID on a client without C_SettingsUtil", function()
        local client = NewClient({ modules = modules, noSettingsPanel = true }):login()
        assert.are.equal("Kennel", client.Kennel.optionsCategoryID)
    end)

    it("draws every page when shown", function()
        local client = NewClient({ modules = modules }):login()
        local shown = 0
        for _, category in pairs(client.categories) do
            local onShow = category.frame.scripts.OnShow
            assert.is_function(onShow, category.name .. " has an OnShow")
            onShow(category.frame)
            shown = shown + 1
        end
        assert.are.equal(4, shown)
        assert.are.same({}, client.errors)
    end)

    it("can also be drawn by AceConfigDialog in a window of its own", function()
        local client = NewClient({ modules = modules }):login()
        local dialog = LibStub("AceConfigDialog-3.0")
        for _, path in ipairs({ "modules", "Alpha", "Beta", "profiles" }) do
            dialog:Open("Kennel", path)
        end
        dialog:Close("Kennel")
        assert.are.same({}, client.errors)
    end)
end)
