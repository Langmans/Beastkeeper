-- The macros a module makes: once per character, per character or account-wide, never in combat.
-- AutocastCheck's three (KennelKite, KennelGrowl, KennelAutocast) serve as the example; CareButton, with a macro of its own, is switched off
-- here so the counts and the order are AutocastCheck's alone.

local NAMES = { "KennelKite", "KennelGrowl", "KennelAutocast" }

---A client with only AutocastCheck making macros; `modules` adds module switches.
local function NewClient(opts, modules)
    opts = opts or {}
    local switches = { CareButton = false }
    for name, on in pairs(modules or {}) do
        switches[name] = on
    end
    opts.saved = opts.saved or { profiles = { Default = { modules = switches } } }
    return _G.NewClient(opts)
end

describe("module macros", function()
    it("are made for the character at the first login, with the spells' names", function()
        local client = NewClient():login()
        assert.are.equal(3, #client.charMacros)
        assert.are.same({
            name = "KennelKite",
            icon = 134400,
            body = "#showtooltip Distracting Shot\n/kennel autocast cower\n/petautocaston Cower\n"
                .. "/petautocastoff Growl\n/cast Distracting Shot",
        }, client:macro("KennelKite"))
        assert.are.same({
            name = "KennelGrowl",
            icon = 132270,
            body = "/kennel autocast growl\n/petautocaston Growl\n/petautocastoff Cower",
        }, client:macro("KennelGrowl"))
        assert.are.same({
            name = "KennelAutocast",
            icon = "Interface\\Icons\\Ability_Hunter_BeastTraining",
            body = "/click KennelAutocastButton",
        }, client:macro("KennelAutocast"))
        assert.is_true(
            client:printedContains("Made the macros KennelKite, KennelGrowl, KennelAutocast for this character")
        )
        assert.is_true(client.Kennel.db.char.macrosMade.AutocastCheck)
    end)

    it("use the client's spell names, or English ones and a question mark without them", function()
        local german = NewClient({ locale = "deDE" }):login()
        assert.truthy(german:macro("KennelKite").body:find("/cast Ablenkender Schuss", 1, true))
        assert.truthy(german:macro("KennelGrowl").body:find("/petautocaston Knurren\n/petautocastoff Ducken", 1, true))
        local bare = NewClient({ noSpellAPI = true }):login()
        assert.truthy(bare:macro("KennelKite").body:find("/cast Distracting Shot", 1, true))
        assert.are.equal(134400, bare:macro("KennelGrowl").icon)
    end)

    it("are made once: deleted afterwards, they stay gone", function()
        local client = NewClient():login()
        client:logout()
        local again = NewClient({ saved = Saved() }):login()
        assert.are.equal(0, #again.charMacros)
    end)

    it("leave a macro of the same name alone", function()
        local client = NewClient()
        client.charMacros[1] = { name = "KennelGrowl", icon = 1, body = "mine" }
        client:login()
        assert.are.equal("mine", client:macro("KennelGrowl").body)
        assert.are.equal(3, #client.charMacros)
    end)

    it("go among the account's when the character's are full, or say there is no room", function()
        local client = NewClient({ noMacroConsts = true })
        for i = 1, 18 do
            client.charMacros[i] = { name = "c" .. i }
        end
        for i = 1, 119 do
            client.macros[i] = { name = "a" .. i }
        end
        client:login()
        assert.is_table(client.macros[120])
        assert.are.equal("KennelKite", client.macros[120].name)
        assert.is_true(client:printedContains("Made KennelKite among the account-wide macros"))
        assert.is_true(client:printedContains("No room for KennelGrowl, KennelAutocast"))
    end)

    it("wait for the end of combat", function()
        local client = NewClient()
        client.inCombat = true
        client:login()
        assert.are.equal(0, #client.charMacros)
        client.inCombat = false
        client:fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(3, #client.charMacros)
    end)

    it("are made at once for a module switched on after login", function()
        local client = NewClient({}, { AutocastCheck = false }):login()
        assert.are.equal(0, #client.charMacros)
        client.Kennel:SetModuleOn("AutocastCheck", true)
        assert.are.equal(3, #client.charMacros)
    end)

    it("are made again by hand, and say so when they are all there", function()
        local client = NewClient():login()
        local button = client.Kennel:GetOptionsTable().args.AutocastCheck.args.macros
        client.charMacros = {}
        button.func()
        assert.are.equal(3, #client.charMacros)
        client.printed = {}
        button.func()
        assert.is_true(client:printedContains("The macros are there already."))
    end)

    it("cannot be made by hand in combat", function()
        local client = NewClient():login()
        client.charMacros = {}
        client.inCombat = true
        client.Kennel:GetOptionsTable().args.AutocastCheck.args.macros.func()
        assert.are.equal(0, #client.charMacros)
        assert.is_true(client:printedContains("Macros cannot be made in combat"))
    end)

    it("are not made on another class", function()
        local client = NewClient({ class = "WARRIOR" }):login()
        assert.are.equal(0, #client.charMacros)
        for _, name in ipairs(NAMES) do
            assert.is_nil(client:macro(name))
        end
    end)
end)
