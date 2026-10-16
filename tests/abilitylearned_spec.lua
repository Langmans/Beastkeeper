-- AbilityLearned: a toast when the hunter learns a pet ability from a tamed beast, the history of
-- those learns per character, and what a pet out can still teach.

local LEVEL_UP = 888
local CAT_CALL = 562387 -- Kennel.sounds.AGGRO_PER_FAMILY[2]

---A hunter past the login wait, with a cat named Fluffy that has Claw rank 2 and Bite; chat
---emptied of the hint said for it.
local function ready(opts)
    local client = NewClient(opts):login()
    client.petBook = { { CLAW_2 }, { 17253 } }
    client:advance(5)
    client.printed = {}
    return client
end

---The module's settings and per-character data.
local function module(client)
    return client.Kennel:GetModule("AbilityLearned")
end

---Lets the merge window pass, so the learn shows.
local function settle(client)
    return client:advance(0.3)
end

describe("AbilityLearned", function()
    describe("a learn", function()
        it("toasts a wild ability with its rank, the pet that taught it and its free points", function()
            local client = settle(ready():learnLine("Claw (Rank 2)"))
            local toast = client:toast()
            assert.are.equal("New pet ability: Claw (Rank 2)", toast.Title.text)
            assert.are.equal("Fluffy has taught you Claw.", toast.Text.text)
            assert.are.equal("Fluffy has 43 training points free.", toast.Hint.text)
            assert.are.equal("Ability Learned", toast.Source.text, "the splash, by default")
            assert.are.equal(132140, toast.Icon.texture)
            assert.are.equal("pet", toast.Portrait.portrait)
            assert.are.same({ file = CAT_CALL, channel = "Master" }, client.sounds[#client.sounds])
        end)

        it("reads the name from a spell link, and the rank from its spell", function()
            local client = settle(ready():learnLine("|cff71d5ff|Hspell:16828:0|h[Claw]|h|r"))
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
        end)

        it("takes the rank and icon from the pet's spellbook when the line has none", function()
            local client = settle(ready():learnLine("Claw"))
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
        end)

        it("without the pet that has it, points to Beast Training and plays the level-up sound", function()
            local client = ready()
            client.pet = nil
            settle(client:learnLine("Charge (Rank 1)"))
            local toast = client:toast()
            assert.are.equal("New pet ability: Charge (Rank 1)", toast.Title.text)
            assert.are.equal("Teach it to your pet from the Beast Training window.", toast.Text.text)
            assert.are.equal("", toast.Hint.text)
            assert.is_false(toast.Portrait.shown)
            assert.are.same({ kit = LEVEL_UP, channel = "Master" }, client.sounds[#client.sounds])
        end)

        it("shows once when the chat line and the spellbook event both report it", function()
            local client = ready():learnLine("Claw (Rank 2)")
            client:fire("LEARNED_SPELL_IN_TAB", CLAW_2)
            client:fire("LEARNED_SPELL_IN_SKILL_LINE", CLAW_2)
            settle(client):animate(10)
            assert.are.equal(1, #module(client).db.char.history)
            assert.is_nil(client:toastTitle(), "no second toast")
        end)

        it("takes a rank the chat line lacks from the spellbook event merged into it", function()
            local client = ready()
            client.pet = nil
            client:learnLine("Claw"):fire("LEARNED_SPELL_IN_TAB", CLAW_3)
            assert.are.equal("New pet ability: Claw (Rank 3)", settle(client):toastTitle())
        end)

        it("comes from the spellbook event alone as well", function()
            local client = settle(ready():fire("LEARNED_SPELL_IN_TAB", CLAW_2))
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
        end)

        it("shows two different abilities one after the other", function()
            local client = ready():learnLine("Claw (Rank 2)"):learnLine("Bite (Rank 1)")
            settle(client)
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
            client:animate(8)
            assert.are.equal("New pet ability: Bite (Rank 1)", client:toastTitle())
        end)

        it("works in another language, from the client's own names and line", function()
            local client = settle(ready({ locale = "deDE" }):learnLine("Klaue (Rang 2)"))
            assert.truthy(client:toastTitle():find("Klaue (Rang 2)", 1, true))
        end)

        it("leaves out what a trainer sells, other spells and other lines", function()
            local client = ready()
            client:learnLine("Great Stamina (Rank 1)")
            client:fire("CHAT_MSG_SYSTEM", "You have learned a new spell: Distracting Shot.")
            client:fire("CHAT_MSG_SYSTEM", "Langmans has come online.")
            client:fire("CHAT_MSG_SYSTEM", SECRET)
            client:fire("CHAT_MSG_SYSTEM", "")
            client:fire("LEARNED_SPELL_IN_TAB", 99999)
            settle(client)
            assert.is_nil(client:toast())
        end)

        it("is not news while a trainer window is open", function()
            local client = ready():openTrainer({}, true)
            settle(client:learnLine("Claw (Rank 2)"))
            assert.is_nil(client:toast())
            client:closeTrainer()
            assert.is_not_nil(settle(client:learnLine("Claw (Rank 2)")):toast())
        end)

        it("counts again once the trainer window is gone, also when no close event came", function()
            local client = ready():openTrainer({}, true)
            ClassTrainerFrame:Hide()
            assert.is_not_nil(settle(client:learnLine("Claw (Rank 2)")):toast())
            client = ready():openTrainer({})
            client:closeTrainer("TRADE_SKILL_CLOSE")
            assert.is_not_nil(settle(client:learnLine("Claw (Rank 2)")):toast())
        end)

        it("is not news in the first seconds after login, when spells are replayed", function()
            local client = NewClient():login()
            settle(client:learnLine("Claw (Rank 2)"))
            assert.is_nil(client:toast())
        end)

        it("shows the same ability once, also when a late duplicate comes after the window", function()
            local client = settle(ready():learnLine("Claw (Rank 2)"))
            client:animate(8)
            settle(client:advance(2):learnLine("Claw (Rank 2)"))
            assert.is_nil(client:toastTitle())
            assert.are.equal(1, #module(client).db.char.history)
        end)

        it("has the screenshot asked of the toast when that is on", function()
            local client = ready()
            module(client).db.profile.screenshot = true
            settle(client:learnLine("Claw (Rank 2)")):animate(1)
            assert.are.equal(1, client.screenshots)
        end)

        it("plays the level-up sound, or none, as set", function()
            local client = ready()
            module(client).db.profile.sound = "levelup"
            settle(client:learnLine("Claw (Rank 2)"))
            assert.are.same({ kit = LEVEL_UP, channel = "Master" }, client.sounds[#client.sounds])
            client = ready()
            module(client).db.profile.sound = "off"
            settle(client:learnLine("Claw (Rank 2)"))
            assert.are.same({}, client.sounds)
        end)

        it("plays the level-up sound for a family without a call", function()
            local client = ready()
            client.familyID = 6 -- a crocolisk
            settle(client:learnLine("Claw (Rank 2)"))
            assert.are.same({ kit = LEVEL_UP, channel = "Master" }, client.sounds[#client.sounds])
        end)

        it("leaves the training points out when the client has no way to read them", function()
            local client = settle(ready({ noTrainingAPI = true }):learnLine("Claw (Rank 2)"))
            assert.are.equal("", client:toast().Hint.text)
        end)

        it("is watched only on a hunter", function()
            local client = NewClient({ class = "MAGE" }):login():advance(5)
            settle(client:learnLine("Claw (Rank 2)"))
            assert.is_nil(client:toast())
        end)

        it("is watched on a client without the learn lines, through the spellbook event", function()
            local client = settle(ready({ noLearnLines = true }):fire("LEARNED_SPELL_IN_TAB", CLAW_2))
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
        end)
    end)

    describe("the history", function()
        it("keeps each learn with its pet, family, zone and time, per character", function()
            local client = settle(ready():learnLine("Claw (Rank 2)"))
            assert.are.same(
                { { name = "Claw", rank = "Rank 2", pet = "Fluffy", familyID = 2, zone = "Darkshore", t = 1791374580 } },
                module(client).db.char.history
            )
            client:logout()
            local relogged = NewClient({ saved = Saved() }):login()
            assert.are.equal(1, #module(relogged).db.char.history)
        end)

        it("keeps the last 200", function()
            local client = ready()
            local history = module(client).db.char.history
            for i = 1, 200 do
                history[i] = { name = "Old " .. i, t = i }
            end
            settle(client:learnLine("Claw (Rank 2)"))
            assert.are.equal(200, #history)
            assert.are.equal("Old 2", history[1].name)
            assert.are.equal("Claw", history[200].name)
        end)

        it("is a line per learn, newest first, on the module's page", function()
            local client = settle(ready():learnLine("Claw (Rank 2)"))
            client:animate(8)
            client.pet = nil
            settle(client:learnLine("Charge (Rank 1)"))
            local text = module(client):GetOptions().args.history.name()
            local claw = text:find("Claw (Rank 2), from Fluffy, Darkshore", 1, true)
            local charge = text:find("Charge (Rank 1), Darkshore", 1, true)
            assert.truthy(claw and charge and charge < claw, text)
            assert.truthy(text:find("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d  Charge"), "the date and time first")
            assert.are.equal("Nothing learned on this character yet.", module(ready()):GetOptions().args.history.name())
        end)
    end)

    describe("what a pet can teach", function()
        it("is said in chat when a pet is summoned, once per pet, until there is something new", function()
            local client = ready()
            module(client).db.char.known = { Claw = 2, Bite = 1 }
            client:summon("Shadow", { CLAW_3, 17253, 4187 }):advance(1)
            assert.is_true(client:printedContains("Shadow can teach you: Claw (Rank 3)."))
            client.printed = {}
            client:summon("Shadow", { CLAW_3, 17253 }):advance(1)
            assert.are.same({}, client.printed, "said before")
            client:summon("Rex", { 17253 }):advance(1)
            assert.are.same({}, client.printed, "nothing to teach")
        end)

        it("asks to open Beast Training once while a rank may simply be unknown", function()
            local client = ready()
            client:summon("Shadow", { CLAW_2 }):advance(1)
            assert.is_true(client:printedContains("Shadow can teach you: Claw (Rank 2)."))
            assert.is_true(client:printedContains("Open Beast Training once"))
        end)

        it("says nothing with hints off, or before the login wait is over", function()
            local client = ready()
            module(client).db.profile.hints = false
            client:summon("Shadow", { CLAW_3 }):advance(1)
            assert.are.same({}, client.printed)
            local early = NewClient():login()
            early.printed = {}
            early:summon("Shadow", { CLAW_3 }):advance(1)
            assert.are.same({}, early.printed)
        end)

        it("is said for a pet already out once the login wait is over", function()
            local client = NewClient():login()
            client.petBook = { { CLAW_3 } }
            client:advance(5)
            assert.is_true(client:printedContains("Fluffy can teach you: Claw (Rank 3)."))
        end)

        it("is said on the page's button whenever asked, also when it is nothing", function()
            local client = ready()
            local check = module(client):GetOptions().args.check.func
            module(client).db.char.known = { Claw = 2, Bite = 1 }
            check()
            assert.is_true(client:printedContains("Fluffy has nothing left to teach you."))
            client.petBook = { { CLAW_3 }, { 7371 } }
            check()
            assert.is_true(client:printedContains("Fluffy can teach you: Charge (Rank 1), Claw (Rank 3)."))
            assert.is_true(client:printedContains("Open Beast Training once"))
            client.pet = nil
            check()
            assert.is_true(client:printedContains("No pet out to check."))
        end)
    end)

    describe("Beast Training", function()
        it("tells which ranks the hunter knows, so the hints are sure", function()
            local client = ready()
            client:openTrainer({ { "Claw", "used", CLAW_3 }, { "Pets", "header" }, { "Bite", "used", 17253 } })
            local char = module(client).db.char
            assert.are.same({ Claw = 3, Bite = 1 }, char.known)
            assert.is_true(char.trainingRead)
            client:fire("TRAINER_UPDATE")
            client:closeTrainer()
            client.printed = {}
            client:summon("Shadow", { CLAW_3 }):advance(1)
            assert.are.same({}, client.printed)
        end)

        it("never lowers a rank, and leaves a pet trainer's ranks for sale alone", function()
            local client = ready()
            module(client).db.char.known = { Claw = 3 }
            client:openTrainer({ { "Bite", "available", 17253 } }, true):closeTrainer()
            assert.is_nil(module(client).db.char.known.Bite)
            assert.is_false(module(client).db.char.trainingRead)
            client:openTrainer({ { "Claw", "used", CLAW_2 } })
            assert.are.equal(3, module(client).db.char.known.Claw)
        end)

        it("skips a row it cannot read, and a window with nothing it can read", function()
            local client = ready()
            client:openTrainer({ { broken = true }, { "Claw", "used", CLAW_2 } })
            assert.are.same({ Claw = 2 }, module(client).db.char.known)
            client = ready()
            client:openTrainer({ { "Claw", "used" } })
            assert.is_false(module(client).db.char.trainingRead)
        end)

        it("counts a learn already known by its rank", function()
            local client = settle(ready():learnLine("Claw (Rank 2)"))
            assert.are.equal(2, module(client).db.char.known.Claw)
            client:animate(8)
            client.pet = nil
            settle(client:advance(5):learnLine("Charge"))
            assert.are.equal(1, module(client).db.char.known.Charge, "no rank: rank 1")
        end)
    end)

    describe("training points gained", function()
        it("toast how many the pet got and how many are free", function()
            local client = ready():gainPoints(3)
            local toast = client:toast()
            assert.are.equal("Fluffy gained 3 training points", toast.Title.text)
            assert.are.equal("46 free to spend at Beast Training.", toast.Text.text)
            assert.are.equal("Interface\\Icons\\Ability_Hunter_BeastTraining", toast.Icon.texture)
            assert.are.equal("pet", toast.Portrait.portrait)
            assert.are.same({ file = CAT_CALL, channel = "Master" }, client.sounds[#client.sounds])
            assert.are.equal("card", client.Kennel:ToastSkinFor("AbilityLearned:points"), "the look for every toast")
        end)

        it("say nothing when points are spent, or the event comes without a change", function()
            local client = ready()
            client.trainingPoints = { 50, 20 }
            client:fire("UNIT_PET_TRAINING_POINTS", "pet")
            client:fire("UNIT_PET_TRAINING_POINTS", "player")
            assert.is_nil(client:toast())
        end)

        it("are counted per pet: a new pet is only noted, one back with more is told", function()
            local client = ready()
            client.trainingPoints = { 10, 0 }
            client:summon("Shadow", {}):advance(1)
            assert.is_nil(client:toast(), "first time Kennel sees Shadow")
            client.trainingPoints = { 50, 7 }
            client:summon("Fluffy", {}):advance(1)
            assert.is_nil(client:toast(), "Fluffy as it was")
            client.trainingPoints = { 14, 0 }
            client:summon("Shadow", {}):advance(1)
            assert.are.equal("Shadow gained 4 training points", client:toastTitle())
        end)

        it("are kept per character across a relog, and told once the login wait is over", function()
            local client = ready()
            client:logout()
            local relogged = NewClient({ saved = Saved() })
            relogged.trainingPoints = { 52, 7 }
            relogged:login()
            assert.is_nil(relogged:toast(), "not in the login wait")
            relogged:advance(5)
            assert.are.equal("Fluffy gained 2 training points", relogged:toastTitle())
        end)

        it("are noted but not told with the toast off, or on a client without them", function()
            local client = ready()
            module(client).db.profile.points = false
            client:gainPoints(3)
            assert.is_nil(client:toast())
            module(client).db.profile.points = true
            client:fire("UNIT_PET_TRAINING_POINTS", "pet")
            assert.is_nil(client:toast(), "the 3 were noted")
            client = ready({ noTrainingAPI = true }):gainPoints(3)
            assert.is_nil(client:toast())
        end)

        it("are not watched with the module off", function()
            local client = ready()
            client.Kennel:SetModuleOn("AbilityLearned", false)
            assert.is_nil(client:gainPoints(3):toast())
        end)
    end)

    describe("the page", function()
        it("sets the sound, the screenshot and the hints", function()
            local client = ready()
            local args = module(client):GetOptions().args
            local settings = module(client).db.profile
            assert.are.equal("family", args.sound.get())
            args.sound.set({}, "off")
            assert.are.equal("off", settings.sound)
            assert.is_false(args.screenshot.get())
            args.screenshot.set({}, true)
            assert.is_true(settings.screenshot)
            assert.is_true(args.hints.get())
            args.hints.set({}, false)
            assert.is_false(settings.hints)
            assert.is_true(args.points.get())
            args.points.set({}, false)
            assert.is_false(settings.points)
        end)

        it("shows an example toast, kept out of the history", function()
            local client = ready()
            module(client):GetOptions().args.test.func()
            assert.are.equal("New pet ability: Bite (Rank 1)", client:toastTitle(), "one of the pet's own")
            assert.are.same({}, module(client).db.char.history)
            client:animate(8)
            client.pet = nil
            module(client):GetOptions().args.test.func()
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle(), "Claw without a pet")
        end)

        it("simulates a learn through the detection, also in the login wait, kept out of the history", function()
            local client = NewClient():login()
            client.petBook = { { CLAW_2 } }
            module(client):GetOptions().args.simulate.func()
            assert.is_true(client:printedContains("Simulating: You have learned a new ability: Claw (Rank 2)."))
            settle(client)
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
            assert.are.same({}, module(client).db.char.history)
            assert.are.same({}, module(client).db.char.known)
            settle(client:learnLine("Claw (Rank 2)"))
            assert.are.same({}, module(client).db.char.history, "the wait holds again for real lines")
        end)

        it("says so when the client has no line to simulate", function()
            local client = ready({ noLearnLines = true })
            module(client):GetOptions().args.simulate.func()
            assert.is_true(client:printedContains("This client has no learn message to imitate."))
        end)

        it("names Claw from the locale when the client cannot", function()
            local client = ready({ noSpellAPI = true })
            client.pet = nil
            module(client):GetOptions().args.test.func()
            assert.are.equal("New pet ability: Claw (Rank 2)", client:toastTitle())
            module(client):GetOptions().args.simulate.func()
            assert.is_true(client:printedContains("Claw is not a pet ability learned in the wild."))
        end)
    end)

    it("starts on the splash look", function()
        assert.are.equal("splash", ready().Kennel:ToastSkinFor("AbilityLearned:learned"))
    end)

    it("does not show a learn still waiting to merge when switched off", function()
        local client = ready():learnLine("Claw (Rank 2)")
        client.Kennel:SetModuleOn("AbilityLearned", false)
        settle(client)
        assert.is_nil(client:toast())
    end)

    it("drops its toasts and stops watching when switched off", function()
        local client = ready():learnLine("Claw (Rank 2)")
        settle(client)
        client.Kennel:SetModuleOn("AbilityLearned", false)
        client:animate(1)
        assert.is_nil(client:toastTitle())
        settle(client:advance(10):learnLine("Bite (Rank 1)"))
        assert.is_nil(client:toastTitle())
        client:summon("Shadow", { CLAW_3 }):advance(1)
        assert.is_false(client:printedContains("Shadow can teach you"))
    end)
end)
