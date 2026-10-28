-- AutocastCheck: Growl or Cower, which one fits (a dungeon group wants Cower, elsewhere Growl,
-- unless the player chose), when it toasts and when the toast goes away, the button that sets it
-- right, its commands, macros, settings and key binding. The simulated pet starts as solo wants
-- it: Growl on, Cower off.

local HINT = "Press your BeastkeeperAutocast macro."

---A saved file with these AutocastCheck settings in the Default profile.
local function savedWith(settings)
    return { namespaces = { AutocastCheck = { profiles = { Default = settings } } } }
end
local SOLO_TEXT = "Growl on, Cower off."
local DUNGEON_TEXT = "Growl off, Cower on."

---@param client table
local function module(client)
    return client.Addon:GetModule("AutocastCheck")
end

---A client in a dungeon (still alone), logged in.
local function inDungeon(opts)
    local client = NewClient(opts)
    client.instance = "party"
    return client:login()
end

describe("AutocastCheck", function()
    describe("which one fits", function()
        it("is Cower in a dungeon or raid group, Growl anywhere else", function()
            local client = NewClient():login()
            local M = module(client)
            assert.are.equal("growl", (M:Wanted()))
            client.inGroup = true
            assert.are.equal("growl", (M:Wanted()), "a group outside")
            client.instance = "party"
            assert.are.equal("cower", (M:Wanted()))
            client.inGroup = false
            assert.are.equal("growl", (M:Wanted()), "alone in a dungeon")
            for kind, wanted in pairs({ raid = "cower", pvp = "growl", arena = "growl" }) do
                client.inGroup, client.instance = true, kind
                assert.are.equal(wanted, (M:Wanted()), kind)
            end
        end)

        it("is the player's choice until a dungeon group is entered or left", function()
            local client = NewClient():login()
            local M = module(client)
            client:slash("autocast cower")
            assert.are.same({ "cower", "chosen" }, { M:Wanted() }, "kiting solo")
            client:group(true)
            assert.are.same({ "cower", "chosen" }, { M:Wanted() }, "a group outside is no dungeon group")
            client.instance = "party"
            client:fire("PLAYER_ENTERING_WORLD"):advance(0.2)
            assert.are.same({ "cower", "dungeon" }, { M:Wanted() }, "entering one ends the choice")
            client:slash("autocast growl")
            assert.are.same({ "growl", "chosen" }, { M:Wanted() }, "the pet tanks for the group")
            client:group(false)
            assert.are.same({ "growl", "solo" }, { M:Wanted() }, "leaving the group ends it too")
        end)

        it("is told to other addons as BEASTKEEPER_AUTOCAST_WANTED when it changes", function()
            local client = NewClient():login():advance(0.2)
            local heard = {}
            client.Addon:Listen(heard, "BEASTKEEPER_AUTOCAST_WANTED", function(_, event)
                heard[#heard + 1] = event
            end)
            client:fire("PET_BAR_UPDATE"):advance(0.2)
            assert.are.same({}, heard, "still Growl, solo")
            client:slash("autocast cower")
            client:advance(1)
            client.instance = "party"
            client:group(true)
            client:advance(0.2)
            assert.are.same({
                { module = "AutocastCheck", wanted = "cower", why = "chosen", before = "growl" },
                { module = "AutocastCheck", wanted = "cower", why = "dungeon", before = "cower" },
            }, heard)
        end)
    end)

    describe("solo", function()
        it("toasts nothing while Growl is on and Cower off", function()
            assert.is_nil(NewClient():login():toastTitle())
        end)

        it("toasts Growl off and Cower on, and takes a toast away once fixed", function()
            local client = NewClient():login():autocast(GROWL, false)
            local toast = client:toast()
            assert.are.equal("Growl is not on autocast", client:toastTitle())
            assert.are.equal("Solo your pet holds the mobs: " .. SOLO_TEXT, toast.Text.text)
            assert.are.equal(HINT, toast.Hint.text)
            client:autocast(GROWL, true):animate(1)
            assert.is_false(toast.shown)
            client:autocast(COWER, true)
            assert.are.equal("Cower is on autocast", client:toastTitle())
        end)

        it("names the button's key in the hint when it has one", function()
            local client = NewClient()
            client.bindings["CLICK BeastkeeperAutocastButton:LeftButton"] = "G"
            client:login():autocast(GROWL, false)
            assert.are.equal("Press <G>.", client:toast().Hint.text)
        end)
    end)

    describe("a dungeon group", function()
        it("wants Growl off and Cower on; both toast, Growl first", function()
            local client = inDungeon():group(true)
            local toast = client:toast()
            assert.are.equal("Growl is on autocast", client:toastTitle())
            assert.are.equal(132270, toast.Icon.texture)
            assert.are.equal("In a dungeon group the tank holds the mobs: " .. DUNGEON_TEXT, toast.Text.text)
            client:animate(8)
            assert.are.equal("Cower is not on autocast", client:toastTitle())
            assert.are.equal(132118, toast.Icon.texture, "Cower is only in the book; the icon comes from the spell")
        end)

        it("takes the toasts away when the group is left", function()
            local client = inDungeon():group(true)
            client:group(false):animate(1)
            assert.is_false(client:toast().shown, "faded out at once, and the waiting one dropped")
        end)

        it("toasts on entering the dungeon and stops on leaving it", function()
            local client = NewClient():setAutocast(COWER, true):login():group(true)
            assert.are.equal("Cower is on autocast", client:toastTitle(), "solo still")
            client.Addon:HideToast()
            client.instance = "party"
            client:fire("PLAYER_ENTERING_WORLD"):advance(0.2)
            assert.are.equal("Growl is on autocast", client:toastTitle())
            client.instance = "none"
            client:fire("PLAYER_ENTERING_WORLD"):advance(0.2):animate(1)
            assert.are.equal("Cower is on autocast", client:toastTitle(), "solo again: Cower on is wrong again")
        end)
    end)

    it("chosen Cower (kiting) wants Growl off and Cower on, solo too", function()
        local client = NewClient():login():slash("autocast cower"):advance(1)
        assert.are.equal("Growl is on autocast", client:toastTitle())
        local text = client:toast().Text.text
        assert.are.equal("You chose Cower: the mob is on you, not on your pet. " .. DUNGEON_TEXT, text)
        client:autocast(GROWL, false):autocast(COWER, true):animate(1)
        assert.is_false(client:toast().shown)
    end)

    it("chosen Growl (the pet tanks) wants Growl on and Cower off, in a dungeon group too", function()
        local client = inDungeon():group(true)
        client:slash("autocast growl"):advance(1):animate(1)
        assert.is_nil(client:toastTitle(), "the dungeon's toasts are gone")
        client:autocast(COWER, true)
        assert.are.equal("Cower is on autocast", client:toastTitle())
        assert.are.equal("You chose Growl: your pet holds the mobs. " .. SOLO_TEXT, client:toast().Text.text)
    end)

    describe("reading the pet", function()
        it("counts a higher rank of Growl too", function()
            local client = NewClient()
            client.petBar[3] = { 14916, false }
            client.petBook[6] = { 14916, false }
            client:login()
            assert.are.equal("Growl is not on autocast", client:toastTitle())
        end)

        it("skips a token, an ability that cannot autocast and an empty slot on the bar", function()
            local client = NewClient()
            client.petBar = { { token = "PET_ACTION_ATTACK" }, { 2649 } }
            client.petBook = {}
            client:login()
            assert.is_nil(client:toastTitle())
            assert.is_nil(module(client):PetAutocasts()["Growl"])
        end)

        it("skips a command or an ability that cannot autocast in the spellbook", function()
            local states = module(NewClient({ noPetBarAPI = true }):login()):PetAutocasts()
            assert.is_nil(states["Attack"])
            assert.is_nil(states["Great Stamina"])
            assert.is_false(states["Cower"].on)
            assert.is_true(states["Growl"].on)
        end)

        it("skips a spellbook entry that cannot be read and reads the rest", function()
            local client = NewClient({ noPetBarAPI = true }):login()
            client.petBook[1] = { broken = true }
            client.petBook[2] = { 17253, true, noInfo = true }
            local states = module(client):PetAutocasts()
            assert.is_nil(states["Bite"])
            assert.is_false(states["Cower"].on)
        end)

        it("reads only the pet bar without the spellbook's count or API", function()
            for _, opts in ipairs({ { noPetSpellCount = true }, { noSpellBookAPI = true } }) do
                local client = NewClient(opts):setAutocast(COWER, true):login()
                assert.is_nil(client:toastTitle(), "Cower is only in the book")
                client:autocast(GROWL, false)
                assert.are.equal("Growl is not on autocast", client:toastTitle())
            end
        end)

        it("sees it all in the spellbook without the pet bar API", function()
            local client = inDungeon({ noPetBarAPI = true }):group(true)
            assert.are.equal("Growl is on autocast", client:toastTitle())
            assert.are.equal(132270, client:toast().Icon.texture)
        end)

        it("sees nothing without the pet bar and the spellbook", function()
            assert.is_nil(inDungeon({ noPetBarAPI = true, noSpellBookAPI = true }):group(true):toastTitle())
        end)

        it("skips an autocast state the client hides", function()
            local client = NewClient():setAutocast(COWER, true)
            client.secret = true
            client.instance = "party"
            client:login():group(true)
            assert.is_nil(client:toastTitle())
        end)

        it("names abilities in the client's language", function()
            local client = inDungeon({ locale = "deDE" }):group(true)
            assert.are.equal("Knurren is on autocast", client:toastTitle(), "the title itself is not translated yet")
        end)

        it("sees nothing wrong when the client cannot name the spells", function()
            assert.is_nil(inDungeon({ noSpellAPI = true }):group(true):toastTitle())
        end)

        it("checks a pet summoned or dismissed, not another unit's pet", function()
            local client = NewClient({ noPet = true }):login()
            assert.is_nil(client:toastTitle(), "no pet, nothing wrong")
            client.pet = { health = 100, max = 100, dead = false }
            client.petBar = { { 2649, false } }
            client.petBook = {}
            local waiting = #client.timers
            client:fire("UNIT_PET", "party1")
            assert.are.equal(waiting, #client.timers)
            client:fire("UNIT_PET", "player"):advance(0.2)
            assert.are.equal("Growl is not on autocast", client:toastTitle())
        end)
    end)

    describe("when it checks", function()
        it("does not toast a problem again on every pet bar update", function()
            local client = NewClient():login():autocast(GROWL, false):animate(8)
            client:petBarUpdate()
            assert.is_false(client:toast().shown)
        end)

        it("checks once for many pet bar updates at once", function()
            local client = NewClient():login():setAutocast(GROWL, false)
            local waiting = #client.timers
            client:fire("PET_BAR_UPDATE"):fire("PET_BAR_UPDATE")
            assert.are.equal(waiting + 1, #client.timers)
            client:advance(0.2)
            assert.are.equal("Growl is not on autocast", client:toastTitle())
        end)

        it("toasts what is still wrong again when combat starts", function()
            local client = NewClient():login():autocast(GROWL, false):animate(8)
            client:fire("PLAYER_REGEN_DISABLED")
            assert.are.equal("Growl is not on autocast", client:toastTitle())
        end)

        it("toasts only what is new when combat starts without the reminder", function()
            local client = NewClient({ saved = savedWith({ remind = false }) }):login()
            client:autocast(GROWL, false):animate(8)
            client:fire("PLAYER_REGEN_DISABLED")
            assert.is_false(client:toast().shown)
        end)

        it("watches neither ability with both switched off", function()
            local client = inDungeon({ saved = savedWith({ growl = false, cower = false }) }):group(true)
            assert.is_nil(client:toastTitle())
        end)

        it("watches nothing on another class", function()
            local client = inDungeon({ class = "WARRIOR" }):group(true)
            assert.is_nil(client:toastTitle())
            assert.are.equal(0, #client.timers)
        end)
    end)

    describe("the sound", function()
        it("is the pet's call, the raid warning for a family without one, or none", function()
            local client = NewClient():login():autocast(GROWL, false)
            assert.are.same({ file = 562387, channel = "Master" }, client.sounds[1])

            client = NewClient():login()
            client.familyID = 6
            client:autocast(GROWL, false)
            assert.are.same({ kit = 8959, channel = "Master" }, client.sounds[1])

            client = NewClient({ saved = savedWith({ sound = "warning" }) }):login():autocast(GROWL, false)
            assert.are.same({ kit = 8959, channel = "Master" }, client.sounds[1])

            client = NewClient({ saved = savedWith({ sound = "off" }) }):login():autocast(GROWL, false)
            assert.are.same({}, client.sounds)
        end)
    end)

    describe("switched off", function()
        it("takes its toasts away and stops checking", function()
            local client = inDungeon():group(true)
            client.Addon:SetModuleOn("AutocastCheck", false)
            client:animate(1)
            assert.is_false(client:toast().shown)
            client:autocast(GROWL, true):autocast(COWER, false)
            client:group(false)
            assert.is_false(client:toast().shown)
        end)

        it("drops a check that was already on its way", function()
            local client = NewClient():login():setAutocast(GROWL, false)
            client:fire("PET_BAR_UPDATE")
            client.Addon:SetModuleOn("AutocastCheck", false)
            client:advance(0.2)
            assert.is_nil(client:toastTitle())
        end)
    end)

    describe("the commands", function()
        it("choose Growl or Cower, and say so only when it changes", function()
            local client = NewClient():login()
            client:slash("autocast cower")
            assert.is_true(client:printedContains("Cower from now on, until you enter or leave a dungeon group."))
            assert.is_nil(client:toastTitle(), "the macro's next lines set autocast: not checked at once")
            client:advance(1)
            assert.are.equal("Growl is on autocast", client:toastTitle(), "checked a second later")
            client.printed = {}
            client:slash("autocast COWER")
            assert.are.same({}, client.printed, "pressed again: nothing to say")
            client:slash("autocast growl")
            assert.is_true(client:printedContains("Growl from now on, until you enter or leave a dungeon group."))
        end)

        it(
            "toast nothing when the macro sets autocast right after, as BeastkeeperKite and BeastkeeperGrowl do",
            function()
                local client = NewClient():login():slash("autocast cower")
                client:advance(0.1):setAutocast(GROWL, false):setAutocast(COWER, true)
                client:advance(0.3):petBarUpdate():advance(1)
                assert.is_nil(client:toastTitle())
                client:slash("autocast growl"):advance(0.4)
                client:setAutocast(GROWL, true):setAutocast(COWER, false):petBarUpdate():advance(1)
                assert.is_nil(client:toastTitle())
            end
        )

        it("are listed in /beastkeeper help", function()
            local client = NewClient():login():slash("help")
            assert.is_true(client:printedContains("/beastkeeper autocast growl - "))
            assert.is_true(client:printedContains("/beastkeeper autocast cower - "))
        end)

        it("say the module is off instead of choosing", function()
            local client = NewClient():login()
            client.Addon:SetModuleOn("AutocastCheck", false)
            client:slash("autocast cower")
            assert.is_true(client:printedContains("Autocast Check is off."))
        end)
    end)

    describe("the button", function()
        local GROWL_LINES = "/petautocaston Growl\n/petautocastoff Cower"
        local COWER_LINES = "/petautocaston Cower\n/petautocastoff Growl"

        it("sets autocast to what fits now, with a key binding of its own", function()
            local client = NewClient():login()
            local button = _G.BeastkeeperAutocastButton
            assert.are.equal("macro", button.attributes.type)
            assert.are.equal(GROWL_LINES, button.attributes.macrotext)
            local binding = _G["BINDING_NAME_CLICK BeastkeeperAutocastButton:LeftButton"]
            assert.are.equal("Autocast Check: set Growl and Cower as fits", binding)
            client.instance = "party"
            client:group(true)
            assert.are.equal(COWER_LINES, button.attributes.macrotext)
            client:slash("autocast growl")
            assert.are.equal(GROWL_LINES, button.attributes.macrotext)
        end)

        it("says in chat what it set, once per press (the key's release)", function()
            local client = NewClient():login()
            local button = _G.BeastkeeperAutocastButton
            client.printed = {}
            for _, down in ipairs({ true, false }) do
                for _, hook in ipairs(button.hooks.OnClick) do
                    hook(button, "LeftButton", down)
                end
            end
            assert.are.equal(1, #client.printed)
            assert.is_true(client:printedContains("Autocast: Growl on, Cower off."))
        end)

        it("is in the client's language", function()
            NewClient({ locale = "deDE" }):login()
            local lines = _G.BeastkeeperAutocastButton.attributes.macrotext
            assert.are.equal("/petautocaston Knurren\n/petautocastoff Ducken", lines)
        end)

        it("changes after combat, when it cannot before", function()
            local client = NewClient():login():enterCombat()
            client:slash("autocast cower")
            assert.are.equal(GROWL_LINES, _G.BeastkeeperAutocastButton.attributes.macrotext)
            client:leaveCombat()
            assert.are.equal(COWER_LINES, _G.BeastkeeperAutocastButton.attributes.macrotext)
        end)

        it("does nothing while the module is off", function()
            local client = NewClient():login()
            client.Addon:SetModuleOn("AutocastCheck", false)
            assert.is_nil(_G.BeastkeeperAutocastButton.attributes.macrotext)
            client.Addon:SetModuleOn("AutocastCheck", true)
            assert.are.equal(GROWL_LINES, _G.BeastkeeperAutocastButton.attributes.macrotext)
        end)
    end)

    describe("the settings page", function()
        local client, args

        before_each(function()
            client = NewClient():login()
            args = client.Addon:GetOptionsTable().args.AutocastCheck.args
        end)

        it("passes AceConfig's validation", function()
            LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(client.Addon:GetOptionsTable(), "Beastkeeper")
        end)

        it("sets each setting and checks again", function()
            for key, value in pairs({ growl = false, cower = false, remind = false, sound = "off" }) do
                args[key].set({}, value)
                assert.are.equal(value, args[key].get(), key)
            end
            client:autocast(COWER, true)
            assert.is_nil(client:toastTitle(), "Cower is not watched")
            args.cower.set({}, true)
            assert.are.equal("Cower is on autocast", client:toastTitle(), "checked again at once")
        end)

        it("only stores a setting while the module is off", function()
            client.Addon:SetModuleOn("AutocastCheck", false)
            client:setAutocast(GROWL, false)
            args.growl.set({}, false)
            args.growl.set({}, true)
            assert.is_true(module(client).db.profile.growl)
            assert.is_nil(client:toastTitle())
        end)

        it("shows an example toast for what fits now, beside a real one", function()
            args.test.func()
            assert.are.equal("Growl is not on autocast", client:toastTitle())
            client.Addon:HideToast()
            client:slash("autocast cower")
            client.Addon:HideToast()
            args.test.func()
            assert.are.equal("Cower is not on autocast", client:toastTitle())
        end)
    end)
end)
