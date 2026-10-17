-- Beast Map: a HandyNotes plugin with a pin for every beast that can teach the hunter a pet ability
-- rank. The specs use a small data set of their own instead of the generated Data\Beasts.lua.

local BITE, CHARGE = 17253, 7371
local ELWYNN, TIRISFAL = 1429, 1420
local CLAW_ICON, BITE_ICON = 132140, 132278

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

describe("Beast Map", function()
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
