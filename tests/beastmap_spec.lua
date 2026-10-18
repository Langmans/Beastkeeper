-- Beast Map: a HandyNotes plugin with a pin for every beast that can teach the hunter a pet ability
-- rank. The specs use a small data set of their own instead of the generated Data\Beasts.lua.

local BITE, CHARGE = 17253, 7371
local ELWYNN, TIRISFAL, BARRENS, STORMWIND = 1429, 1420, 1413, 1453
local TRAINER_ICON, STABLE_ICON = 132162, 132161
local CLAW_ICON, BITE_ICON, CHARGE_ICON = 132140, 132278, 132183

---@param Kennel Kennel
local function SmallData(Kennel)
    Kennel.data = {
        petAbilityRanks = {
            [CLAW] = { ability = CLAW, rank = 1, level = 1, families = { 2 }, teachers = { 101 } },
            [CLAW_2] = { ability = CLAW, rank = 2, level = 8, families = { 2 }, teachers = { 101 } },
            [CLAW_3] = { ability = CLAW, rank = 3, level = 16, families = { 2 }, teachers = { 102, 104, 106 } },
            [BITE] = { ability = BITE, rank = 1, level = 1, families = { 1, 3 }, teachers = { 103 } },
            [CHARGE] = { ability = CHARGE, rank = 1, level = 1, families = { 5 }, teachers = { 105, 107 } },
        },
        beasts = {
            [101] = { name = "Low Cat", family = 2, minLevel = 5, maxLevel = 6, pins = { [ELWYNN] = { 40, 50 } } },
            [102] = { name = "High Cat", family = 2, minLevel = 65, maxLevel = 66, pins = { [ELWYNN] = { 60, 60 } } },
            [103] = {
                name = "Spider",
                family = 3,
                minLevel = 5,
                maxLevel = 5,
                pins = { [ELWYNN] = { 10, 10, 20, 20 } },
            },
            [104] = {
                name = "Rare Cat",
                family = 2,
                minLevel = 10,
                maxLevel = 10,
                rare = true,
                elite = true,
                pins = { [TIRISFAL] = { 30, 30 } },
            },
            [105] = { name = "Cave Boar", family = 5, minLevel = 12, maxLevel = 12, zones = { 718 } },
            -- Teaches Claw 3 like Rare Cat, but from level 11: no news at 11.
            [106] = { name = "Late Cat", family = 2, minLevel = 11, maxLevel = 11, pins = { [9999] = { 50, 50 } } },
            -- Teaches Charge like Cave Boar, at the same level, out in the open.
            [107] = { name = "Field Boar", family = 5, minLevel = 12, maxLevel = 12, pins = { [ELWYNN] = { 70, 70 } } },
        },
        -- In Stormwind, apart from the beasts' maps. The simulated hunter is Alliance.
        trainers = {
            [201] = { name = "Trainer Bob", kind = "trainer", pins = { [STORMWIND] = { 60, 70 } } },
            [202] = { name = "Stabler Sue", kind = "stable", side = "Alliance", pins = { [STORMWIND] = { 50, 50 } } },
            [203] = { name = "Horde Stabler", kind = "stable", side = "Horde", pins = { [STORMWIND] = { 40, 40 } } },
        },
    }
end

---A hunter at `level` with HandyNotes, logged in and past AbilityLearned's login wait.
---@param level number?
---@param opts TestClientOptions?
local function hunter(level, opts)
    opts = opts or {}
    opts.handyNotes = opts.handyNotes ~= false
    opts.modules = SmallData
    local client = NewClient(opts)
    client.playerLevel = level or 10
    return client:login():advance(5)
end

---The pins on a map as "x,y" -> icon.
---@param client table
---@param uiMapID number
---@return table<string, number>
local function pins(client, uiMapID)
    local out = {}
    for _, pin in ipairs(client:mapPins(uiMapID)) do
        out[pin.x .. "," .. pin.y] = pin.icon
    end
    return out
end

---Ticks or unticks a setting on the module's page, as the player would.
---@param client table
---@param key string
---@param value boolean
local function set(client, key, value)
    client.Kennel:GetModule("BeastMap"):GetOptions().args[key].set(nil, value)
end

---Kennel's button on the world map, if it made one.
---@param client table
---@return table?
local function mapButton(client)
    for _, frame in ipairs(client.frames) do
        if frame.parent == WorldMapFrame then return frame end
    end
end

---The mouse over the map button: the tooltip's title and lines.
---@param client table
---@return string? title
---@return table[] lines
local function hoverMapButton(client)
    client.tooltipLines, GameTooltip.text = {}, nil
    local button = mapButton(client) --[[@as table]]
    button:GetScript("OnEnter")(button)
    return GameTooltip.text, client.tooltipLines
end

describe("Beast Map", function()
    describe("its button on the world map", function()
        it("switches the pins off and on", function()
            local client = hunter(10)
            local button = mapButton(client) --[[@as table]]
            assert.is_true(button:IsShown())
            local title, lines = hoverMapButton(client)
            assert.are.equal("Beast Map", title)
            assert.are.equal("Pins shown. Click to hide them.", lines[1].text)
            local before = client.mapUpdates.world
            button:GetScript("OnClick")(button, "LeftButton")
            assert.are.same({}, client:mapPins(ELWYNN))
            assert.are.same({}, client:mapPins(ELWYNN, true), "the minimap too")
            assert.are.equal(before + 1, client.mapUpdates.world)
            assert.is_false(client.Kennel:GetModule("BeastMap"):Settings().pins)
            assert.are.equal("Pins hidden. Click to show them.", select(2, hoverMapButton(client))[1].text)
            button:GetScript("OnClick")(button, "LeftButton")
            assert.are.equal(3, #client:mapPins(ELWYNN))
            button:GetScript("OnLeave")(button)
            assert.is_false(GameTooltip:IsShown())
        end)

        it("is a setting, also on the page; the pins switch is there too", function()
            local client = hunter(10)
            set(client, "mapButton", false)
            assert.is_false(mapButton(client):IsShown())
            set(client, "mapButton", true)
            assert.is_true(mapButton(client):IsShown())
            set(client, "pins", false)
            assert.are.same({}, client:mapPins(ELWYNN))
        end)

        it("is not there without HandyNotes, or while the module is off", function()
            assert.is_nil(mapButton(hunter(10, { handyNotes = false })))
            local client = hunter(10)
            client.Kennel:GetModule("BeastMap"):Disable()
            assert.is_false(mapButton(client):IsShown())
            client.Kennel:GetModule("BeastMap"):Enable()
            assert.is_true(mapButton(client):IsShown())
        end)
    end)

    it("joins HandyNotes as the Kennel plugin, and stays out without it", function()
        local client = hunter()
        assert.is_not_nil(HandyNotes.plugins.Kennel)
        assert.is_not_nil(HandyNotes.pluginOptions)
        assert.has_no.errors(function()
            hunter(10, { handyNotes = false })
        end)
    end)

    it("is for hunters only", function()
        hunter(10, { class = "MAGE" })
        assert.is_nil(HandyNotes.plugins.Kennel)
    end)

    it("pins the beasts at or below the hunter's level that teach a rank it lacks", function()
        local client = hunter(10)
        -- High Cat is level 65; Cave Boar lives in an instance, which has no map to pin it on.
        assert.are.same({ ["40,50"] = CLAW_ICON, ["10,10"] = BITE_ICON, ["20,20"] = BITE_ICON }, pins(client, ELWYNN))
        assert.are.same({ ["30,30"] = CLAW_ICON }, pins(client, TIRISFAL))
        assert.are.same({}, pins(client, 1411))
        assert.are.equal(3, #client:mapPins(ELWYNN, true), "the minimap too")
    end)

    it("leaves out a beast that teaches only ranks the hunter has, or lower", function()
        local client = hunter(10)
        client:openTrainer({ { "Claw", "used", CLAW_2 } }):closeTrainer()
        assert.are.same({ ["10,10"] = BITE_ICON, ["20,20"] = BITE_ICON }, pins(client, ELWYNN))
        assert.are.same({ ["30,30"] = CLAW_ICON }, pins(client, TIRISFAL), "Rare Cat teaches Claw 3")
    end)

    it("shows a missing lower rank when asked to", function()
        local client = hunter(10)
        client:openTrainer({ { "Claw", "used", CLAW }, { "Claw", "used", CLAW_3 } }):closeTrainer()
        assert.is_nil(pins(client, ELWYNN)["40,50"])
        set(client, "gaps", true)
        assert.are.equal(CLAW_ICON, pins(client, ELWYNN)["40,50"], "Low Cat teaches Claw 2")
    end)

    it("shows every beast in reach, or above the hunter's level too, when asked to", function()
        local client = hunter(10)
        client:openTrainer({ { "Claw", "used", CLAW_3 }, { "Bite", "used", BITE } }):closeTrainer()
        assert.are.same({}, pins(client, ELWYNN))
        set(client, "usefulOnly", false)
        assert.are.same({ ["40,50"] = CLAW_ICON, ["10,10"] = BITE_ICON, ["20,20"] = BITE_ICON }, pins(client, ELWYNN))
        set(client, "aboveLevel", true)
        assert.are.equal(CLAW_ICON, pins(client, ELWYNN)["60,60"])
    end)

    it("names the beast, its level and the ranks it teaches, green for one the hunter lacks", function()
        local client = hunter(10)
        client:openTrainer({ { "Claw", "used", CLAW } }):closeTrainer()
        local low = client:mapPins(ELWYNN)[1]
        local title, lines = client:hoverPin(ELWYNN, low.coord)
        assert.are.equal("Low Cat", title)
        assert.are.equal("Level 5-6", lines[1].text)
        assert.are.equal("Claw (Rank 1)", lines[2].text)
        assert.are.same({ 0.5, 0.5, 0.5 }, lines[2].color)
        assert.are.equal("Claw (Rank 2)", lines[3].text)
        assert.are.same({ 0, 1, 0 }, lines[3].color)
        assert.are.equal("Click to go there.", lines[#lines].text)
        local rare = client:mapPins(TIRISFAL)[1]
        title, lines = client:hoverPin(TIRISFAL, rare.coord)
        assert.are.equal("Rare Cat", title)
        assert.are.equal("Level 10, rare elite", lines[1].text)
        local spider = client:mapPins(ELWYNN)[2]
        _, lines = client:hoverPin(ELWYNN, spider.coord)
        assert.are.equal("Level 5", lines[1].text)
        assert.is_true(GameTooltip:IsShown())
        HandyNotes.plugins.Kennel.OnLeave()
        assert.is_false(GameTooltip:IsShown())
        assert.has_no.errors(function()
            client:hoverPin(ELWYNN, 1)
        end)
    end)

    it("names a beast as the client does, in English while the client has no name yet", function()
        local client = hunter(10)
        local low = client:mapPins(ELWYNN)[1]
        assert.are.equal("Low Cat", (client:hoverPin(ELWYNN, low.coord)))
        client.creatureNames[101] = "Kleine Katze"
        assert.are.equal("Kleine Katze", (client:hoverPin(ELWYNN, low.coord)))
        client:clickPin(ELWYNN, low.coord)
        assert.is_true(client:printedContains("Kleine Katze"), "the label of the target")
        client = hunter(11)
        client.creatureNames[105] = "Höhleneber"
        client:fire("PLAYER_LEVEL_UP", 12)
        assert.are.equal("Höhleneber in Wailing Caverns teaches it.", client:toast().Text.text)
    end)

    it("pins the beasts in a dungeon at its entrance, named in the tooltip", function()
        local client = hunter(11)
        assert.are.same({}, client:mapPins(BARRENS), "Cave Boar is level 12")
        client = hunter(12)
        local pin = client:mapPins(BARRENS)[1]
        assert.are.equal(1, #client:mapPins(BARRENS), "Razorfen Kraul has no beast in the data")
        assert.are.same({ 46, 36, CHARGE_ICON }, { pin.x, pin.y, pin.icon })
        local title, lines = client:hoverPin(BARRENS, pin.coord)
        assert.are.equal("Wailing Caverns", title)
        assert.are.equal("Cave Boar: Level 12", lines[1].text)
        assert.are.same({ 1, 1, 1 }, lines[1].color)
        assert.are.equal("Charge (Rank 1)", lines[2].text)
        assert.are.same({ 0, 1, 0 }, lines[2].color)
        assert.are.equal("Click to go there.", lines[#lines].text)
        client:clickPin(BARRENS, pin.coord)
        assert.is_true(client:printedContains("|Hworldmap:1413:4600:3600|h"), "to the entrance")
        assert.is_true(client:printedContains("Wailing Caverns"))
    end)

    describe("on a beast's tooltip", function()
        ---A creature's GUID, as the client gives it.
        local function creature(npc)
            return ("Creature-0-5250-0-12-%d-0000ABCDEF"):format(npc)
        end

        it("says what it teaches and whether the hunter lacks it", function()
            local client = hunter(10)
            client:openTrainer({ { "Claw", "used", CLAW } }):closeTrainer()
            local lines = client:hoverUnit(creature(101))
            assert.are.equal("Teaches Claw (Rank 1): you know it", lines[1].text)
            assert.are.same({ 0.5, 0.5, 0.5 }, lines[1].color)
            assert.are.equal("Teaches Claw (Rank 2): new for you", lines[2].text)
            assert.are.same({ 0, 1, 0 }, lines[2].color)
        end)

        it("names a lower rank the hunter never learned", function()
            local client = hunter(20)
            client:openTrainer({ { "Claw", "used", CLAW }, { "Claw", "used", CLAW_3 } }):closeTrainer()
            local lines = client:hoverUnit(creature(101))
            assert.are.equal("Teaches Claw (Rank 2): below your highest, never learned", lines[2].text)
            assert.are.same({ 1, 1, 0 }, lines[2].color)
        end)

        it("says nothing on another unit, a hidden GUID, another tooltip, or switched off", function()
            local client = hunter(10)
            assert.are.same({}, client:hoverUnit(creature(999)), "a beast that teaches nothing")
            assert.are.same({}, client:hoverUnit("Player-5250-0ABCDEF0"))
            assert.are.same({}, client:hoverUnit(SECRET))
            assert.are.same({}, client:hoverUnit(creature(101), {}), "a tooltip other than the game's")
            set(client, "tooltip", false)
            assert.are.same({}, client:hoverUnit(creature(101)))
            set(client, "tooltip", true)
            client.Kennel:GetModule("BeastMap"):Disable()
            assert.are.same({}, client:hoverUnit(creature(101)))
            assert.are.same({}, hunter(10, { class = "MAGE" }):hoverUnit(creature(101)))
        end)

        it("is there without HandyNotes too", function()
            local lines = hunter(10, { handyNotes = false }):hoverUnit(creature(101))
            assert.are.equal("Teaches Claw (Rank 2): new for you", lines[2].text)
        end)
    end)

    describe("the tame key", function()
        local TARGET_RARE_CAT = "/cast [mod:shift] Tame Beast\n/stopmacro [mod:shift]\n/targetexact Rare Cat\n/tm 8"

        ---The key's release, as the client runs a key binding's click.
        local function press(client)
            local button = _G.KennelTameButton
            for _, hook in ipairs(button.hooks.OnClick or {}) do
                hook(button, "LeftButton", false)
            end
            return client
        end

        it("targets and marks the beast the rare alarm named; Shift tames it", function()
            local client = hunter(10)
            client.unitGUIDs.nameplate1 = "Creature-0-5250-0-12-104-0000ABCDEF"
            client:fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
            assert.are.equal(TARGET_RARE_CAT, _G.KennelTameButton.attributes.macrotext)
            assert.are.equal("macro", _G.KennelTameButton.attributes.type)
            assert.is_true(client:printedContains("The tame key now targets Rare Cat."))
            assert.are.equal(
                "Beast Map: target and mark the beast to tame",
                _G["BINDING_NAME_CLICK KennelTameButton:LeftButton"]
            )
        end)

        it("takes the beast whose pin was clicked, after combat when in it", function()
            local client = hunter(10):enterCombat()
            client:clickPin(TIRISFAL, client:mapPins(TIRISFAL)[1].coord)
            assert.is_nil(_G.KennelTameButton.attributes.macrotext)
            client:leaveCombat()
            assert.are.equal(TARGET_RARE_CAT, _G.KennelTameButton.attributes.macrotext)
        end)

        it("says how to set a beast when there is none yet, and stays empty while switched off", function()
            local client = press(hunter(10))
            assert.is_true(client:printedContains("No beast to target yet"))
            client.Kennel:GetModule("BeastMap"):Disable()
            client:clickPin(TIRISFAL, 1)
            assert.is_nil(_G.KennelTameButton.attributes.macrotext)
        end)
    end)

    describe("pet trainers and stable masters", function()
        it("have a pin each, for the hunter's faction or both", function()
            local client = hunter(10)
            assert.are.same({ ["60,70"] = TRAINER_ICON, ["50,50"] = STABLE_ICON }, pins(client, STORMWIND))
        end)

        it("say what they are in the tooltip, and a click goes there", function()
            local client = hunter(10)
            local trainer, stable = client:mapPins(STORMWIND)[1], client:mapPins(STORMWIND)[2]
            local title, lines = client:hoverPin(STORMWIND, trainer.coord)
            assert.are.equal("Trainer Bob", title)
            assert.are.equal("Pet Trainer", lines[1].text)
            assert.are.equal("Click to go there.", lines[#lines].text)
            title, lines = client:hoverPin(STORMWIND, stable.coord)
            assert.are.equal("Stabler Sue", title)
            assert.are.equal("Stable Master", lines[1].text)
            client:clickPin(STORMWIND, stable.coord)
            assert.is_true(client:printedContains("Stabler Sue"))
        end)

        it("each have a switch", function()
            local client = hunter(10)
            set(client, "trainers", false)
            assert.are.same({ ["50,50"] = STABLE_ICON }, pins(client, STORMWIND))
            set(client, "stables", false)
            assert.are.same({}, pins(client, STORMWIND))
        end)
    end)

    describe("the rare alarm", function()
        local RARE_CAT = "Creature-0-5250-0-12-104-0000ABCDEF"

        ---The toasts shown from now on.
        local function toasts(client)
            local seen = {}
            client.Kennel.RegisterMessage(seen, "KENNEL_TOAST", function(_, event)
                seen[#seen + 1] = event.toast
            end)
            return seen
        end

        ---A nameplate showing the unit with this GUID.
        local function nameplate(client, guid)
            client.unitGUIDs.nameplate1 = guid
            return client:fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
        end

        it("toasts a rare beast that teaches a rank the hunter lacks, once per spawn", function()
            local client = hunter(10)
            local seen = toasts(client)
            nameplate(client, RARE_CAT)
            assert.are.equal(1, #seen)
            local toast = seen[1]
            assert.are.equal("BeastMap:rare", toast.type)
            assert.are.equal("Rare beast nearby: Rare Cat", toast.title)
            assert.are.equal("Teaches Claw (Rank 3)", toast.text)
            assert.are.equal("Level 10, rare elite", toast.hint)
            assert.are.equal(CLAW_ICON, toast.icon)
            nameplate(client, RARE_CAT)
            client.unitGUIDs.target = RARE_CAT
            client:fire("PLAYER_TARGET_CHANGED")
            assert.are.equal(1, #seen, "the same spawn")
            nameplate(client, "Creature-0-5250-0-12-104-0000FEDCBA")
            assert.are.equal(2, #seen, "another spawn")
        end)

        it("is told to other addons as KENNEL_RARE_SEEN, also with the toast off", function()
            local client = hunter(10)
            local heard = {}
            client.Kennel:Listen(heard, "KENNEL_RARE_SEEN", function(_, event)
                heard[#heard + 1] = event
            end)
            local seen = toasts(client)
            set(client, "rareToast", false)
            nameplate(client, RARE_CAT)
            nameplate(client, RARE_CAT)
            assert.are.same({}, seen)
            assert.are.same({
                { module = "BeastMap", npc = 104, name = "Rare Cat", guid = RARE_CAT, ranks = { CLAW_3 } },
            }, heard)
        end)

        it("sees it as a target, under the mouse, or on the minimap", function()
            local client = hunter(10)
            local seen = toasts(client)
            client.unitGUIDs.target = RARE_CAT
            client:fire("PLAYER_TARGET_CHANGED")
            assert.are.equal(1, #seen)
            client = hunter(10)
            seen = toasts(client)
            client.unitGUIDs.mouseover = RARE_CAT
            client:fire("UPDATE_MOUSEOVER_UNIT")
            assert.are.equal(1, #seen)
            client = hunter(10)
            seen = toasts(client)
            client.vignettes["Vignette-1"] = { objectGUID = RARE_CAT, name = "Rare Cat" }
            client:fire("VIGNETTE_MINIMAP_UPDATED", "Vignette-1", true)
            client:fire("VIGNETTE_MINIMAP_UPDATED", "Vignette-2", true)
            assert.are.equal(1, #seen)
        end)

        it(
            "stays quiet for an ordinary beast, a rank the hunter has, a beast above its level, or switched off",
            function()
                local client = hunter(10)
                local seen = toasts(client)
                nameplate(client, "Creature-0-5250-0-12-101-0000ABCDEF")
                nameplate(client, "Player-5250-0ABCDEF0")
                nameplate(client, SECRET)
                assert.are.same({}, seen)
                client = hunter(10)
                client:openTrainer({ { "Claw", "used", CLAW_3 } }):closeTrainer()
                seen = toasts(client)
                nameplate(client, RARE_CAT)
                assert.are.same({}, seen, "Claw 3 known")
                client = hunter(9)
                seen = toasts(client)
                nameplate(client, RARE_CAT)
                assert.are.same({}, seen, "level 10, the hunter 9")
                set(client, "aboveLevel", true)
                nameplate(client, RARE_CAT)
                assert.are.equal(1, #seen, "when beasts above the hunter's level count")
                client = hunter(10)
                seen = toasts(client)
                set(client, "rareToast", false)
                nameplate(client, RARE_CAT)
                client.Kennel:GetModule("BeastMap"):Disable()
                set(client, "rareToast", true)
                nameplate(client, "Creature-0-5250-0-12-104-0000FEDCBA")
                assert.are.same({}, seen)
            end
        )
    end)

    describe("the Abilities tab", function()
        ---The tab, opened in Kennel's window.
        local function tab(client)
            client.Kennel:OpenWindow("abilities")
            return client.Kennel.window.panels.abilities
        end

        ---The shown rows' label texts of a list.
        local function texts(rows, field)
            local out = {}
            for _, row in ipairs(rows) do
                if row.shown then out[#out + 1] = row[field or "label"].text end
            end
            return out
        end

        ---Clicks a button by its script.
        local function click(button)
            button:GetScript("OnClick")(button, "LeftButton")
        end

        it("lists every ability with how many of its ranks the hunter knows", function()
            local client = hunter(10)
            client:openTrainer({ { "Claw", "used", CLAW } }):closeTrainer()
            local panel = tab(client)
            assert.are.same({ "Bite  0/1", "Charge  0/1", "Claw  1/3" }, texts(panel.rows))
            assert.are.equal("Bite", panel.title.text, "the first is chosen")
        end)

        it("shows every rank: its pet level, known, or the nearest beast that teaches it", function()
            local client = hunter(10)
            client:openTrainer({ { "Claw", "used", CLAW } }):closeTrainer()
            local panel = tab(client)
            click(panel.rows[3])
            assert.are.equal("Claw", panel.title.text)
            assert.are.same({ "Rank 1", "Rank 2", "Rank 3" }, texts(panel.ranks, "rank"))
            assert.are.same({ "1", "8", "16" }, texts(panel.ranks, "level"))
            assert.are.same({
                "Known",
                "Low Cat in Elwynn Forest",
                "Rare Cat in Tirisfal Glades, +2 more",
            }, texts(panel.ranks, "text"), "Rare Cat: the one in reach, before Late Cat and High Cat")
            assert.is_false(panel.ranks[1].go.shown, "nothing to go to for a known rank")
            assert.is_true(panel.ranks[3].go.shown)
        end)

        it("says so when every teacher is above the hunter's level, or no beast teaches the rank", function()
            local client = hunter(4)
            local panel = tab(client)
            click(panel.rows[3])
            assert.are.equal("Low Cat in Elwynn Forest, above your level", panel.ranks[1].text.text)
            client.Kennel.data.petAbilityRanks[CLAW_2].teachers = {}
            client.Kennel:RefreshWindow("abilities")
            assert.are.equal("No beast teaches it", panel.ranks[2].text.text)
            assert.is_false(panel.ranks[2].go.shown)
            local row = panel.ranks[2]
            GameTooltip.shown = false
            row:GetScript("OnEnter")(row)
            assert.is_false(GameTooltip.shown, "no tooltip without teachers")
        end)

        it("puts the beast reached first on top, with its travel time, when a route addon knows them", function()
            local client = hunter(70)
            LibStub("LibGoThere-1.0"):RegisterProvider({
                id = "test",
                order = 1,
                Usable = function()
                    return true
                end,
                Navigate = function()
                    return true
                end,
                TravelTime = function(_, _, _, _, map)
                    if map == TIRISFAL then return 600 end
                    if map == ELWYNN then return 125 end
                end,
            })
            local panel = tab(client)
            click(panel.rows[3])
            assert.are.equal("High Cat in Elwynn Forest, ~2 min, +2 more", panel.ranks[3].text.text)
        end)

        it("without travel times puts beasts on the hunter's map first, then the closest in level", function()
            local client = hunter(70)
            local panel = tab(client)
            click(panel.rows[3])
            assert.are.equal("High Cat in Elwynn Forest, +2 more", panel.ranks[3].text.text)
            client.Kennel.data.beasts[102].pins = { [TIRISFAL] = { 1, 1 } }
            client.Kennel:RefreshWindow("abilities")
            assert.are.equal("High Cat in Tirisfal Glades, +2 more", panel.ranks[3].text.text, "65 is closer to 70")
        end)

        it("sends the hunter to the beast on a click, and makes it the tame key's", function()
            local client = hunter(10)
            local panel = tab(client)
            click(panel.rows[3])
            click(panel.ranks[3].go)
            assert.is_true(client:printedContains("|Hworldmap:1420:3000:3000|h"), "LibGoThere's pin link")
            assert.is_true(client:printedContains("The tame key now targets Rare Cat."))
        end)

        it("lists every teacher in the rank's tooltip, in order", function()
            local client = hunter(10)
            local panel = tab(client)
            click(panel.rows[3])
            client.tooltipLines, GameTooltip.text = {}, nil
            local row = panel.ranks[3]
            row:GetScript("OnEnter")(row)
            local lines = {}
            for _, line in ipairs(client.tooltipLines) do
                lines[#lines + 1] = line.text
            end
            assert.are.equal("Claw (Rank 3)", GameTooltip.text)
            assert.are.same({
                "Rare Cat in Tirisfal Glades: Level 10, rare elite",
                "Late Cat: Level 11",
                "High Cat in Elwynn Forest: Level 65-66",
            }, lines)
            row:GetScript("OnLeave")(row)
            assert.is_false(GameTooltip.shown)
        end)

        it("follows what the hunter learns while it is open", function()
            local client = hunter(10)
            local panel = tab(client)
            client:openTrainer({ { "Bite", "used", BITE } }):closeTrainer()
            assert.are.equal("Bite  1/1", panel.rows[1].label.text)
        end)

        it("is a tab only while Beast Map is on", function()
            local client = hunter(10)
            tab(client)
            client.Kennel:GetModule("BeastMap"):Disable()
            client.Kennel:ToggleWindow()
            client.Kennel:OpenWindow("abilities")
            assert.are.equal("pets", client.Kennel.window.current)
        end)
    end)

    describe("the Families tab", function()
        local function tab(client)
            client.Kennel:OpenWindow("families")
            return client.Kennel.window.panels.families
        end

        local function shown(rows, field)
            local out = {}
            for _, row in ipairs(rows) do
                if row.shown then out[#out + 1] = row[field or "label"].text end
            end
            return out
        end

        local function click(button)
            button:GetScript("OnClick")(button, "LeftButton")
        end

        it("lists every family by name, with how many of your pets are of it; the pet out's chosen", function()
            local client = hunter(10)
            client.familyNames[2] = "Cat"
            local panel = tab(client)
            local rows = shown(panel.rows)
            assert.are.equal(18, #rows)
            assert.are.equal("Bat", rows[1])
            assert.is_truthy(tContains(rows, "Cat (1)"), "Fluffy")
            assert.are.equal("Cat", panel.title.text)
        end)

        it("says its specialization, diet and what it can learn", function()
            local client = hunter(10)
            client:openTrainer({ { "Claw", "used", CLAW } }):closeTrainer()
            local panel = tab(client)
            assert.are.equal("Ferocity", panel.spec.text)
            assert.are.equal("Eats: Meat, Fish", panel.diet.text)
            assert.are.equal("Claw: ranks 1-3, you know 1", panel.abilities.text)
        end)

        it("names the beasts of the family the hunter can tame, nearest first, and goes there", function()
            local client = hunter(10)
            local panel = tab(client)
            assert.are.same({
                "Low Cat in Elwynn Forest: Level 5-6",
                "Rare Cat in Tirisfal Glades: Level 10, rare elite",
                "Late Cat: Level 11",
            }, shown(panel.beasts, "text"))
            assert.are.same({ creature = 101 }, panel.model.shownModel)
            click(panel.beasts[2].go)
            assert.is_true(client:printedContains("The tame key now targets Rare Cat."))
            for _, row in ipairs(panel.rows) do
                if row.shown and row.label.text == "Boar" then click(row) end
            end
            assert.are.equal("Cave Boar in Wailing Caverns: Level 12", panel.beasts[2].text.text)
            assert.is_false(panel.beasts[2].go.shown, "no pin to go to")
        end)

        it("shows another family on a click, also one Kennel knows little of", function()
            local client = hunter(10)
            client.familyNames[40] = "Fuchs"
            local panel = tab(client)
            local fox
            for _, row in ipairs(panel.rows) do
                if row.shown and row.label.text == "Fuchs" then fox = row end
            end
            click(fox)
            assert.are.equal("Fuchs", panel.title.text)
            assert.are.equal("", panel.spec.text)
            assert.are.equal("", panel.diet.text)
            assert.are.equal("", panel.abilities.text)
            assert.are.same({}, shown(panel.beasts, "text"))
            assert.are.equal("No beast of this family in Kennel's data.", panel.none.text)
            assert.is_false(panel.model.shown)
        end)

        it("falls back to the first family without a pet out", function()
            local client = hunter(10, { noPet = true })
            assert.are.equal("Bat", tab(client).title.text)
        end)
    end)

    it("sends the hunter to a beast with a left click on its pin, through LibGoThere", function()
        local client = hunter(10)
        local low = client:mapPins(ELWYNN)[1]
        client:clickPin(ELWYNN, low.coord, "RightButton")
        assert.is_false(client:printedContains("|Hworldmap:"), "a right click does nothing")
        client:clickPin(ELWYNN, low.coord)
        -- No route addon and no game waypoint in the simulated client: LibGoThere's pin link.
        local links = 0
        for _, line in ipairs(client.printed) do
            if line:find("|Hworldmap:1429:4000:5000|h", 1, true) and line:find("Low Cat", 1, true) then
                links = links + 1
            end
        end
        assert.are.equal(1, links, "once, as the button comes up")
        assert.has_no.errors(function()
            client:clickPin(ELWYNN, 1)
        end)
    end)

    it("redraws when the hunter levels, learns a rank or changes a setting", function()
        local client = hunter(10)
        local before = client.mapUpdates.world
        client.playerLevel = 11
        client:fire("PLAYER_LEVEL_UP", 11)
        assert.are.equal(before + 1, client.mapUpdates.world)
        assert.are.equal(client.mapUpdates.world, client.mapUpdates.minimap)
        client:openTrainer({ { "Claw", "used", CLAW } }):closeTrainer()
        assert.are.equal(before + 2, client.mapUpdates.world)
        set(client, "gaps", true)
        assert.is_true(client.Kennel:GetModule("BeastMap"):Settings().gaps)
        assert.are.equal(before + 3, client.mapUpdates.world)
    end)

    it("pins nothing while switched off", function()
        local client = hunter(10)
        client.Kennel:GetModule("BeastMap"):Disable()
        assert.are.same({}, client:mapPins(ELWYNN))
        assert.is_true(client.mapUpdates.world > 0)
        client.Kennel:GetModule("BeastMap"):Enable()
        assert.are.equal(3, #client:mapPins(ELWYNN))
    end)

    describe("at a level-up", function()
        ---The hunter reaches `level`; gives the toast's title and text, or nil.
        ---@param client table
        ---@param level number
        local function levelUp(client, level)
            client:fire("PLAYER_LEVEL_UP", level)
            local toast = client:toast()
            if not (toast and toast.shown) then return nil end
            return client:toastTitle(), toast.Text.text
        end

        it("toasts the ranks a beast of the new level brings in reach, where to tame it", function()
            local client = hunter(11)
            local title, text = levelUp(client, 12)
            assert.are.equal("Now in reach: Charge (Rank 1)", title)
            assert.are.equal("Cave Boar in Wailing Caverns teaches it.", text)
        end)

        it("lists several ranks, each with a beast", function()
            local client = hunter(4)
            local title, text = levelUp(client, 5)
            assert.are.equal("3 pet ability ranks now in reach", title)
            assert.are.equal(
                "Claw (Rank 1): Low Cat in Elwynn Forest\nClaw (Rank 2): Low Cat in Elwynn Forest\nBite (Rank 1): Spider in Elwynn Forest",
                text
            )
        end)

        it("leaves out ranks the hunter has, and ranks a lower beast taught already", function()
            local client = hunter(4)
            client:openTrainer({ { "Claw", "used", CLAW_2 } }):closeTrainer()
            assert.are.equal("Now in reach: Bite (Rank 1)", (levelUp(client, 5)))
            client = hunter(10)
            assert.is_nil(levelUp(client, 11), "Claw 3 was in reach at 10 already")
        end)

        it("names the beast reached first, when a route addon knows the travel times", function()
            local client = hunter(11)
            local GoThere = LibStub("LibGoThere-1.0")
            GoThere:RegisterProvider({
                id = "test",
                order = 1,
                Usable = function()
                    return true
                end,
                Navigate = function()
                    return true
                end,
                TravelTime = function(_, _, _, _, map, x, y)
                    -- Field Boar's pin, 70/70 on Elwynn Forest; Cave Boar has none.
                    if map == 1429 and x == 0.7 and y == 0.7 then return 45 end
                end,
            })
            local _, text = levelUp(client, 12)
            assert.are.equal("Field Boar in Elwynn Forest teaches it.", text)
        end)

        it("names an ordinary beast before a rare, and the beast alone when its map has no name", function()
            local client = hunter(9)
            client.Kennel.data.beasts[104].minLevel = 11 -- Rare Cat now comes with Late Cat
            local _, text = levelUp(client, 11)
            assert.are.equal("Late Cat teaches it.", text)
        end)

        it("stays quiet when switched off, also without HandyNotes", function()
            local client = hunter(4)
            set(client, "levelToast", false)
            assert.is_nil(levelUp(client, 5))
            client = hunter(11, { handyNotes = false })
            assert.are.equal("Now in reach: Charge (Rank 1)", (levelUp(client, 12)))
        end)
    end)
end)
