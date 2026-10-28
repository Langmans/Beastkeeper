-- The macros a module makes: once per character, per character or account-wide, never in combat.
-- AutocastCheck's three (BeastkeeperKite, BeastkeeperGrowl, BeastkeeperAutocast) serve as the example; CareButton, with a macro of its own, is switched off
-- here so the counts and the order are AutocastCheck's alone.

local NAMES = { "BeastkeeperKite", "BeastkeeperGrowl", "BeastkeeperAutocast" }

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
            name = "BeastkeeperKite",
            icon = 134400,
            body = "#showtooltip Distracting Shot\n/beastkeeper autocast cower\n/petautocaston Cower\n"
                .. "/petautocastoff Growl\n/use Distracting Shot",
        }, client:macro("BeastkeeperKite"))
        assert.are.same({
            name = "BeastkeeperGrowl",
            icon = 132270,
            body = "/beastkeeper autocast growl\n/petautocaston Growl\n/petautocastoff Cower",
        }, client:macro("BeastkeeperGrowl"))
        assert.are.same({
            name = "BeastkeeperAutocast",
            icon = 132162, -- Ability_Hunter_BeastTraining
            body = "/click BeastkeeperAutocastButton",
        }, client:macro("BeastkeeperAutocast"))
        assert.is_true(
            client:printedContains(
                "Made the macros BeastkeeperKite, BeastkeeperGrowl, BeastkeeperAutocast for this character"
            )
        )
        assert.is_true(client.Addon.db.char.macrosMade.AutocastCheck)
    end)

    it("use the client's spell names, or English ones and a question mark without them", function()
        local german = NewClient({ locale = "deDE" }):login()
        assert.truthy(german:macro("BeastkeeperKite").body:find("/use Ablenkender Schuss", 1, true))
        assert.truthy(
            german:macro("BeastkeeperGrowl").body:find("/petautocaston Knurren\n/petautocastoff Ducken", 1, true)
        )
        local bare = NewClient({ noSpellAPI = true }):login()
        assert.truthy(bare:macro("BeastkeeperKite").body:find("/use Distracting Shot", 1, true))
        assert.are.equal(134400, bare:macro("BeastkeeperGrowl").icon)
    end)

    it("are made once: deleted afterwards, they stay gone", function()
        local client = NewClient():login()
        client:logout()
        local again = NewClient({ saved = Saved() }):login()
        assert.are.equal(0, #again.charMacros)
    end)

    it("leave a macro of the same name alone", function()
        local client = NewClient()
        client.charMacros[1] = { name = "BeastkeeperGrowl", icon = 1, body = "mine" }
        client:login()
        assert.are.equal("mine", client:macro("BeastkeeperGrowl").body)
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
        assert.are.equal("BeastkeeperKite", client.macros[120].name)
        assert.is_true(client:printedContains("Made BeastkeeperKite among the account-wide macros"))
        assert.is_true(client:printedContains("No room for BeastkeeperGrowl, BeastkeeperAutocast"))
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
        client.Addon:SetModuleOn("AutocastCheck", true)
        assert.are.equal(3, #client.charMacros)
    end)

    it("are made again by hand, and say so when they are all there", function()
        local client = NewClient():login()
        local button = client.Addon:GetOptionsTable().args.AutocastCheck.args.macros
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
        client.Addon:GetOptionsTable().args.AutocastCheck.args.macros.func()
        assert.are.equal(0, #client.charMacros)
        assert.is_true(client:printedContains("Macros cannot be made in combat"))
    end)

    it("say what they do in the tooltip of the action button they are on", function()
        local client = NewClient({}, { CareButton = true }):login()
        local lines = client:hoverAction(1, "BeastkeeperKite")
        assert.are.equal(1, #lines)
        assert.are.equal(
            "Beastkeeper: puts Cower on and Growl off, then casts Distracting Shot. Holds until you enter or "
                .. "leave a dungeon group.",
            lines[1].text
        )
        assert.is_true(lines[1].wrap)
        assert.truthy(client:hoverAction(2, "BeastkeeperGrowl")[1].text:find("puts Growl on and Cower off", 1, true))
        assert.truthy(
            client:hoverAction(3, "BeastkeeperAutocast")[1].text:find("sets Growl and Cower as fits", 1, true)
        )
        assert.truthy(client:hoverAction(4, "BeastkeeperCare")[1].text:find("Mend Pet while your pet lives", 1, true))
    end)

    it("leave other actions' tooltips alone, and those of a module switched off", function()
        local client = NewClient():login()
        client.charMacros[#client.charMacros + 1] = { name = "Mine", icon = 1, body = "/dance" }
        assert.are.same({}, client:hoverAction(1, "Mine"))
        client.actions[2] = { "spell", 136 }
        assert.are.same({}, client:hoverAction(2))
        assert.are.same({}, client:hoverAction(3))
        client.Addon:SetModuleOn("AutocastCheck", false)
        assert.are.same({}, client:hoverAction(4, "BeastkeeperKite"))
    end)

    it("are not made on another class", function()
        local client = NewClient({ class = "WARRIOR" }):login()
        assert.are.equal(0, #client.charMacros)
        for _, name in ipairs(NAMES) do
            assert.is_nil(client:macro(name))
        end
    end)
end)
