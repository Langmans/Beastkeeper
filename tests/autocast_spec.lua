-- AutocastCheck: the modes, what counts as wrong in each, when it toasts and when the toast goes
-- away, its commands, settings and key bindings. The simulated pet starts as solo wants it:
-- Growl on, Cower off.

local HINT_OFF = "Right-click it on the pet bar or in your pet's spellbook to turn autocast off."
local HINT_ON = "Right-click it on the pet bar or in your pet's spellbook to turn autocast on."

---A saved file with these AutocastCheck settings in the Default profile.
local function savedWith(settings)
    return { namespaces = { AutocastCheck = { profiles = { Default = settings } } } }
end

---@param client table
local function module(client)
    return client.Kennel:GetModule("AutocastCheck")
end

---A client in a dungeon (still alone), logged in.
local function inDungeon(opts)
    local client = NewClient(opts)
    client.instance = "party"
    return client:login()
end

describe("AutocastCheck", function()
    describe("the mode", function()
        it("is solo, or dungeon in a dungeon or raid group, or kite or tank when chosen", function()
            local client = NewClient():login()
            local M = module(client)
            assert.are.equal("solo", M:Mode())
            client.inGroup = true
            assert.are.equal("solo", M:Mode(), "a group outside")
            client.instance = "party"
            assert.are.equal("dungeon", M:Mode())
            client.inGroup = false
            assert.are.equal("solo", M:Mode(), "alone in a dungeon")
            for kind, mode in pairs({ raid = "dungeon", pvp = "solo", arena = "solo" }) do
                client.inGroup, client.instance = true, kind
                assert.are.equal(mode, M:Mode(), kind)
            end
            client:slash("autocast kite")
            assert.are.equal("kite", M:Mode())
            client:slash("autocast tank")
            assert.are.equal("tank", M:Mode())
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
            assert.are.equal("Solo your pet holds the mobs: Growl on, Cower off.", toast.Text.text)
            assert.are.equal(HINT_ON, toast.Hint.text)
            client:autocast(GROWL, true):animate(1)
            assert.is_false(toast.shown)
            client:autocast(COWER, true)
            assert.are.equal("Cower is on autocast", client:toastTitle())
            assert.are.equal(HINT_OFF, toast.Hint.text)
        end)
    end)

    describe("a dungeon group", function()
        it("wants Growl off and Cower on; both toast, Growl first", function()
            local client = inDungeon():group(true)
            local toast = client:toast()
            assert.are.equal("Growl is on autocast", client:toastTitle())
            assert.are.equal(132270, toast.Icon.texture)
            assert.are.equal("In a dungeon group the tank holds the mobs: Growl off, Cower on.", toast.Text.text)
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
            client.Kennel:HideToast()
            client.instance = "party"
            client:fire("PLAYER_ENTERING_WORLD"):advance(0.2)
            assert.are.equal("Growl is on autocast", client:toastTitle())
            client.instance = "none"
            client:fire("PLAYER_ENTERING_WORLD"):advance(0.2):animate(1)
            assert.are.equal("Cower is on autocast", client:toastTitle(), "solo again: Cower on is wrong again")
        end)
    end)

    it("kite mode wants Growl off and Cower on, anywhere", function()
        local client = NewClient({ saved = savedWith({ mode = "kite" }) }):login()
        assert.are.equal("Growl is on autocast", client:toastTitle())
        assert.are.equal(
            "Kite mode: the mob is on you, not on your pet: Growl off, Cower on.",
            client:toast().Text.text
        )
        client:autocast(GROWL, false):autocast(COWER, true):animate(1)
        assert.is_false(client:toast().shown)
    end)

    it("tank mode wants Growl on and Cower off, in a dungeon group too", function()
        local client = inDungeon({ saved = savedWith({ mode = "tank" }) }):group(true)
        assert.is_nil(client:toastTitle())
        client:autocast(COWER, true)
        assert.are.equal("Cower is on autocast", client:toastTitle())
        assert.are.equal("Tank mode: your pet tanks for the group: Growl on, Cower off.", client:toast().Text.text)
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
            client.Kennel:SetModuleOn("AutocastCheck", false)
            client:animate(1)
            assert.is_false(client:toast().shown)
            client:autocast(GROWL, true):autocast(COWER, false)
            client:group(false)
            assert.is_false(client:toast().shown)
        end)

        it("drops a check that was already on its way", function()
            local client = NewClient():login():setAutocast(GROWL, false)
            client:fire("PET_BAR_UPDATE")
            client.Kennel:SetModuleOn("AutocastCheck", false)
            client:advance(0.2)
            assert.is_nil(client:toastTitle())
        end)
    end)

    describe("the commands", function()
        it("switch kite mode on and off, and say so only when it changes", function()
            local client = NewClient():login()
            local M = module(client)
            client:slash("autocast kite on")
            assert.are.equal("kite", M.db.profile.mode)
            assert.is_true(client:printedContains("Kite mode on: Growl off, Cower on."))
            client.printed = {}
            client:slash("autocast kite on")
            assert.are.same({}, client.printed, "pressed again: nothing to say")
            client:slash("autocast kite off")
            assert.are.equal("auto", M.db.profile.mode)
            assert.is_true(client:printedContains("Kite mode off"))
        end)

        it("toggle without a word, and tank replaces kite", function()
            local client = NewClient():login()
            local M = module(client)
            client:slash("autocast tank")
            assert.are.equal("tank", M.db.profile.mode)
            client:slash("autocast kite")
            assert.are.equal("kite", M.db.profile.mode)
            client:slash("autocast kite")
            assert.are.equal("auto", M.db.profile.mode)
            client:slash("autocast tank off")
            assert.are.equal("auto", M.db.profile.mode, "already off")
        end)

        it("check again at once: kite mode makes Growl on wrong", function()
            local client = NewClient():login()
            client:slash("autocast kite on")
            assert.are.equal("Growl is on autocast", client:toastTitle())
        end)

        it("are listed in /kennel help", function()
            local client = NewClient():login():slash("help")
            assert.is_true(client:printedContains("/kennel autocast kite - kite mode on, off"))
            assert.is_true(client:printedContains("/kennel autocast tank - tank mode on, off"))
        end)
    end)

    describe("the key bindings", function()
        it("are named, and switch kite and tank mode through /kennel", function()
            local client = NewClient():login()
            assert.are.equal("Kennel", BINDING_HEADER_KENNEL)
            assert.are.equal("Autocast Check: toggle kite mode", BINDING_NAME_KENNEL_AUTOCAST_KITE)
            assert.are.equal("Autocast Check: toggle tank mode", BINDING_NAME_KENNEL_AUTOCAST_TANK)
            Kennel_AutocastKite()
            assert.are.equal("kite", module(client).db.profile.mode)
            Kennel_AutocastTank()
            assert.are.equal("tank", module(client).db.profile.mode)
        end)

        it("say the module is off instead of switching", function()
            local client = NewClient():login()
            client.Kennel:SetModuleOn("AutocastCheck", false)
            Kennel_AutocastKite()
            assert.are.equal("auto", module(client).db.profile.mode)
            assert.is_true(client:printedContains("Autocast Check is off."))
        end)
    end)

    describe("the settings page", function()
        local client, args

        before_each(function()
            client = NewClient():login()
            args = client.Kennel:GetOptionsTable().args.AutocastCheck.args
        end)

        it("passes AceConfig's validation", function()
            LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(client.Kennel:GetOptionsTable(), "Kennel")
        end)

        it("sets each setting and checks again", function()
            for key, value in pairs({ growl = false, cower = false, remind = false, sound = "off" }) do
                args[key].set({}, value)
                assert.are.equal(value, args[key].get(), key)
            end
            args.growl.set({}, true)
            args.mode.set({}, "kite")
            assert.are.equal("kite", args.mode.get())
            assert.are.equal("Growl is on autocast", client:toastTitle())
        end)

        it("only stores a setting while the module is off", function()
            client.Kennel:SetModuleOn("AutocastCheck", false)
            args.mode.set({}, "kite")
            assert.are.equal("kite", module(client).db.profile.mode)
            assert.is_nil(client:toastTitle())
        end)

        it("shows an example toast for the chosen mode, beside a real one", function()
            for mode, title in pairs({
                auto = "Growl is on autocast",
                kite = "Cower is not on autocast",
                tank = "Growl is not on autocast",
            }) do
                client.Kennel:HideToast()
                module(client).db.profile.mode = mode
                args.test.func()
                assert.are.equal(title, client:toastTitle(), mode)
            end
        end)
    end)
end)
