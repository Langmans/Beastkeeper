-- Ammo: the hunter's ammo count as a data broker source ("Beastkeeper Ammo"), orange when low, red when
-- critically low, a toast at each; a click sends the hunter to the nearest vendor of its faction
-- that sells its kind of ammo; at a vendor it buys the best ammo for its level to fill the ammo bag
-- (or the stacks set without one). The hunter here has a bow (2504) and Rough Arrows (2512).

local ROUGH, SHARP, LIGHT_SHOT = 2512, 2515, 2516
local BOW, GUN, CROSSBOW, SWORD = 2504, 2508, 15808, 25

---Beastkeeper's ammo data object.
local function broker()
    return LibStub("LibDataBroker-1.1"):GetDataObjectByName("Beastkeeper Ammo")
end

---A hunter with `count` Rough Arrows in the bags.
---@param count number
---@param opts TestClientOptions?
local function hunter(count, opts)
    opts = opts or {}
    opts.ranged, opts.ammo = BOW, ROUGH
    local client = NewClient(opts):login()
    -- The login's count was 0: its toast fades out before the test starts.
    client:stock(ROUGH, count):animate(2)
    return client
end

---The toasts shown from now on, as Beastkeeper hands them to listeners.
local function toasts(client)
    local seen = {}
    client.Addon.RegisterMessage(seen, "BEASTKEEPER_TOAST", function(_, event)
        seen[#seen + 1] = event.toast
    end)
    return seen
end

---A few vendors around the hunter, who stands in the middle of Elwynn Forest (1429).
local function vendors(client)
    client.Addon.data.ammoVendors = {
        [1] = { name = "Arrow Al", sells = { ROUGH }, side = "Alliance", pins = { [1429] = { 10, 10 } } },
        [2] = { name = "Horde Hal", sells = { ROUGH }, side = "Horde", pins = { [1429] = { 50, 52 } } },
        [3] = { name = "Bullet Bob", sells = { LIGHT_SHOT }, pins = { [1429] = { 51, 51 } } },
        [4] = { name = "Far Fran", sells = { SHARP, LIGHT_SHOT }, pins = { [1429] = { 95, 95 } } },
    }
end

---A route addon that gives every spot `seconds`; it counts the spots it was asked about.
---@param seconds number
local function routes(seconds)
    local asked = { n = 0 }
    LibStub("LibGoThere-1.0"):RegisterProvider({
        id = "test",
        order = 1,
        Usable = function()
            return true
        end,
        Navigate = function()
            return true
        end,
        TravelTime = function()
            asked.n = asked.n + 1
            return seconds
        end,
    })
    return asked
end

---The tooltip a display shows: its lines' texts.
local function tooltip(client)
    client.tooltipLines = {}
    broker().OnTooltipShow(GameTooltip)
    local texts = {}
    for _, line in ipairs(client.tooltipLines) do
        texts[#texts + 1] = line.text
    end
    return texts
end

describe("Ammo", function()
    it("has data: arrows and bullets with their level, and vendors that sell them with a pin", function()
        local ns = {}
        assert(loadfile("Core/Constants/Enums.lua"))("Beastkeeper", ns)
        assert(loadfile("Data/Forever/Ammo.lua"))("Beastkeeper", ns)
        local ammo, vendors = ns.data.ammo, ns.data.ammoVendors
        assert.are.same({ arrow = 2, bullet = 3 }, ns.ammoKinds, "the Projectile item subclasses")
        assert.are.same({ name = "Rough Arrow", kind = ns.ammoKinds.arrow, level = 1 }, ammo[ROUGH])
        assert.are.equal(ns.ammoKinds.bullet, ammo[LIGHT_SHOT].kind)
        local count = 0
        for npc, vendor in pairs(vendors) do
            count = count + 1
            assert.is_true(#vendor.sells > 0, npc)
            for _, itemID in ipairs(vendor.sells) do
                assert.is_truthy(ammo[itemID], npc .. " sells " .. itemID)
            end
            assert.is_truthy(next(vendor.pins), npc .. " has a pin")
        end
        assert.is_true(count > 100, "vendors: " .. count)
    end)

    describe("the count", function()
        it("is the data broker's text: white, orange below the low line, red below the critical one", function()
            local client = hunter(1000)
            assert.are.equal("Ammo", broker().label)
            assert.are.equal("1000", broker().text)
            assert.are.equal(133000 + ROUGH, broker().icon)
            client:stock(ROUGH, 499)
            assert.are.equal("|cffff8000499|r", broker().text)
            client:stock(ROUGH, 249)
            assert.are.equal("|cffff2020249|r", broker().text)
        end)

        it("toasts once below each line, and takes the toast away once restocked", function()
            local client = hunter(1000)
            local seen = toasts(client)
            client:stock(ROUGH, 450)
            client:stock(ROUGH, 400)
            assert.are.equal(1, #seen)
            assert.are.equal("Ammo:low", seen[1].type)
            assert.are.equal("Ammo low: 450 left", seen[1].title)
            client:stock(ROUGH, 200)
            assert.are.equal(2, #seen)
            assert.are.equal("Ammo:critical", seen[2].type)
            assert.are.equal("Ammo critically low: 200 left", seen[2].title)
            assert.are.equal(
                "Enough for ~10 min of Auto Shot. Click the ammo counter for the nearest ammo vendor.",
                seen[2].text
            )
            client:stock(ROUGH, 1000):animate(1)
            assert.is_false(client:toast().shown)
            client:stock(ROUGH, 400)
            assert.are.equal(3, #seen, "low again after a restock")
        end)

        it("says how long the ammo lasts at the weapon's speed, in the toast and the tooltip", function()
            local client = hunter(1000)
            client.rangedSpeed = 2.5
            local seen = toasts(client)
            client:stock(ROUGH, 400)
            assert.are.equal(
                "Enough for ~17 min of Auto Shot. Click the ammo counter for the nearest ammo vendor.",
                seen[1].text
            )
            assert.are.equal("Rough Arrow: 400 (~17 min of Auto Shot)", tooltip(client)[1])
            client:stock(ROUGH, 10)
            assert.are.equal(
                "Enough for ~25 s of Auto Shot. Click the ammo counter for the nearest ammo vendor.",
                seen[2].text
            )
            client:stock(ROUGH, 0)
            assert.are.equal("Rough Arrow: 0", tooltip(client)[1], "nothing to last")
        end)

        it("goes by the pace of this fight, else of the last one, else the weapon's speed", function()
            local client = hunter(1000)
            client.rangedSpeed = 3
            assert.are.equal("Rough Arrow: 1000 (~50 min of Auto Shot)", tooltip(client)[1], "weapon speed")
            client:fire("PLAYER_REGEN_DISABLED")
            assert.are.equal("Rough Arrow: 1000 (~50 min of Auto Shot)", tooltip(client)[1], "nothing shot yet")
            client:advance(10)
            client:stock(ROUGH, 990)
            assert.are.equal("Rough Arrow: 990 (~17 min of Auto Shot)", tooltip(client)[1], "one a second")
            client:advance(10)
            client:stock(ROUGH, 970)
            assert.are.equal("Rough Arrow: 970 (~11 min of Auto Shot)", tooltip(client)[1], "1.5 a second")
            client:fire("PLAYER_REGEN_ENABLED")
            client:advance(60)
            assert.are.equal("Rough Arrow: 970 (~11 min of Auto Shot)", tooltip(client)[1], "the last fight")
            client:fire("PLAYER_REGEN_DISABLED")
            client:advance(5)
            assert.are.equal("Rough Arrow: 970 (~11 min of Auto Shot)", tooltip(client)[1], "nothing shot yet")
        end)

        it("follows the lines set on its page, and the toasts' switch", function()
            local client = hunter(1000)
            local args = client.Addon:GetModule("Ammo"):GetOptions().args
            args.low.set(nil, 1200)
            assert.are.equal("|cffff80001000|r", broker().text)
            args.critical.set(nil, 1100)
            assert.are.equal("|cffff20201000|r", broker().text)
            local seen = toasts(client)
            args.toasts.set(nil, false)
            client:stock(ROUGH, 10)
            assert.are.same({}, seen)
        end)

        it("tells other addons when it crosses a line", function()
            local client = hunter(1000)
            local heard = {}
            client.Addon:Listen(heard, "BEASTKEEPER_AMMO", function(_, event)
                heard[#heard + 1] = event
            end)
            client:stock(ROUGH, 990)
            client:stock(ROUGH, 400)
            client:stock(ROUGH, 100)
            local arrow = client.Addon.ammoKinds.arrow
            assert.are.same({
                { module = "Ammo", count = 400, state = "low", kind = arrow },
                { module = "Ammo", count = 100, state = "critical", kind = arrow },
            }, heard)
        end)

        it("says so without a bow, gun or crossbow, and counts nothing then", function()
            local client = hunter(1000)
            client.ranged = SWORD
            client:fire("PLAYER_EQUIPMENT_CHANGED", 18)
            assert.are.equal("No bow or gun", broker().text)
            assert.are.equal("No bow or gun", tooltip(client)[1])
            broker().OnClick(nil, "LeftButton")
            assert.is_true(client:printedContains("No ammo vendor known."), "nothing to go to")
            client.ranged = nil
            client:fire("PLAYER_EQUIPMENT_CHANGED", 18)
            assert.are.equal("No bow or gun", broker().text)
        end)

        it("counts the ammo in the ammo slot by default, every kind at once on a switch", function()
            local client = hunter(1200)
            client:stock(SHARP, 495)
            assert.are.equal("1200", broker().text, "the Rough Arrows in the ammo slot")
            local option = client.Addon:GetModule("Ammo"):GetOptions().args.equippedOnly
            assert.is_true(option.get())
            option.set(nil, false)
            assert.are.equal("1695", broker().text, "at once")
        end)

        it("counts every kind of ammo the weapon shoots and the hunter's level allows", function()
            local client = hunter(1200)
            client.Addon:GetModule("Ammo"):Settings().equippedOnly = false
            client:stock(SHARP, 495)
            assert.are.equal("1695", broker().text, "Rough and Sharp Arrows, not the ammo slot's alone")
            client:stock(LIGHT_SHOT, 300)
            assert.are.equal("1695", broker().text, "bullets do not go in a bow")
            client.playerLevel = 9
            client:stock(SHARP, 495)
            assert.are.equal("1200", broker().text, "Sharp Arrows need level 10")
        end)

        it("is zero, and critical, with no ammo in the ammo slot", function()
            local client = hunter(1000)
            client.ammoID = nil
            client:fire("PLAYER_EQUIPMENT_CHANGED", 0)
            assert.are.equal("|cffff20200|r", broker().text)
        end)

        it("is not there on another class", function()
            NewClient({ class = "MAGE" }):login()
            assert.is_nil(broker())
        end)

        it("says Off while the module is off", function()
            local client = hunter(1000)
            client.Addon:SetModuleOn("Ammo", false)
            assert.are.equal("Off", broker().text)
        end)
    end)

    describe("the vendor", function()
        it("is the nearest of the hunter's faction that sells its kind of ammo, on a click", function()
            local client = hunter(400)
            vendors(client)
            broker().OnClick(nil, "LeftButton")
            assert.is_true(client:printedContains("Arrow Al, Elwynn Forest 10.0, 10.0"), "Arrow Al's spot")
            client.ranged = GUN
            client:fire("PLAYER_EQUIPMENT_CHANGED", 18)
            broker().OnClick(nil, "LeftButton")
            assert.is_true(client:printedContains("Bullet Bob, Elwynn Forest 51.0, 51.0"), "Bullet Bob, for a gun")
        end)

        it("is named in the tooltip with the count and the ammo", function()
            local client = hunter(400)
            vendors(client)
            local lines = tooltip(client)
            assert.are.equal("Rough Arrow: 400 (~20 min of Auto Shot)", lines[1])
            assert.are.equal("Nearest ammo vendor: Arrow Al in Elwynn Forest", lines[2])
            assert.are.equal("Click: the way to it. Right-click: settings.", lines[#lines])
        end)

        it("says so when no vendor sells the hunter's kind", function()
            local client = hunter(400)
            client.Addon.data.ammoVendors = {}
            assert.are.equal("No ammo vendor known.", tooltip(client)[2])
            broker().OnClick(nil, "LeftButton")
            assert.is_true(client:printedContains("No ammo vendor known."))
        end)

        it("is kept within 100 yards of where it was looked up, for a minute, for one kind of ammo", function()
            local client = hunter(400)
            vendors(client)
            local asked = routes(120)
            tooltip(client)
            local first = asked.n
            assert.is_true(first > 0)
            client.worldPos = { -9010, 400, 0 }
            tooltip(client)
            assert.are.equal(first, asked.n, "10 yards, whatever line lies between")
            client.worldPos = { -8940, 480, 0 }
            tooltip(client)
            broker().OnClick(nil, "LeftButton")
            assert.are.equal(first, asked.n, "60 and 80 yards: 100 yards away")
            client.worldPos = { -8930, 480, 0 }
            tooltip(client)
            assert.are.equal(2 * first, asked.n, "70 and 80 yards: 106 yards away")
            client.worldPos = { -8930, 400, 0 }
            tooltip(client)
            assert.are.equal(2 * first, asked.n, "80 yards from the new spot")
            client:advance(61)
            tooltip(client)
            assert.are.equal(3 * first, asked.n, "a minute later")
            client.ranged = GUN
            client:fire("PLAYER_EQUIPMENT_CHANGED", 18)
            tooltip(client)
            assert.is_true(asked.n > 3 * first, "another kind of ammo")
        end)

        it("without a world position, goes by where the map position lies in the world", function()
            local client = hunter(400)
            vendors(client)
            local asked = routes(120)
            client.worldPos = nil
            tooltip(client)
            local first = asked.n
            assert.is_true(first > 0)
            client.mapPos = { 0.51, 0.5 } -- 35 yards on
            tooltip(client)
            assert.are.equal(first, asked.n, "within 100 yards")
            client.mapPos = { 0.53, 0.5 }
            tooltip(client)
            assert.are.equal(2 * first, asked.n, "moved on")
        end)

        describe("among many", function()
            -- The hunter at Elwynn Forest's east edge; arrow vendors further west in Elwynn, and one
            -- just across the border on map 1430.
            local EDGE = { -9000, 400 - 0.45 * 3470, 0 }

            local function many(client)
                local list = {}
                for i, x in ipairs({ 80, 75, 70, 65, 60, 55 }) do
                    list[i] = { name = "West " .. x, sells = { ROUGH }, pins = { [1429] = { x, 50 } } }
                end
                list[#list + 1] = { name = "Over the border", sells = { ROUGH }, pins = { [1430] = { 10, 50 } } }
                client.Addon.data.ammoVendors = list
                client.worldPos = EDGE
            end

            it("asks the route addon about the 5 nearest only", function()
                local client = hunter(400)
                many(client)
                local asked = routes(120)
                tooltip(client)
                assert.are.equal(5, asked.n)
            end)

            it("measures in the world, so a vendor across a zone border counts as near", function()
                local client = hunter(400)
                many(client)
                broker().OnClick(nil, "LeftButton")
                assert.is_true(client:printedContains("Border Valley 10.0, 50.0"), "over the border")
            end)

            it("asks about every vendor when none is on the hunter's continent", function()
                local client = hunter(400)
                many(client)
                client.worldPos = { -9000, 400, 1 }
                local asked = routes(120)
                tooltip(client)
                assert.are.equal(7, asked.n)
            end)

            it("takes the nearest on the hunter's own map when the world position is unknown", function()
                local client = hunter(400)
                many(client)
                client.worldPos, client.mapWorld = nil, {}
                client.mapPos = { 0.95, 0.5 }
                broker().OnClick(nil, "LeftButton")
                assert.is_true(client:printedContains("West 80, Elwynn Forest 80.0, 50.0"), "West 80")
            end)
        end)

        it("is looked up each time when the hunter's position is unknown", function()
            local client = hunter(400)
            vendors(client)
            local asked = routes(120)
            client.worldPos, client.mapPos = nil, nil
            tooltip(client)
            local first = asked.n
            tooltip(client)
            assert.are.equal(2 * first, asked.n)
        end)

        it("opens the module's settings on a right-click", function()
            local client = hunter(400)
            broker().OnClick(nil, "RightButton")
            assert.are.same({ client.Addon.moduleCategoryIDs.Ammo }, client.opened)
        end)
    end)

    describe("buying at a vendor", function()
        it("buys the best ammo for the level the vendor has, a stack without an ammo bag", function()
            local client = hunter(0)
            client.playerLevel = 12
            client.merchant = { 117, ROUGH, SHARP, LIGHT_SHOT }
            client:fire("MERCHANT_SHOW")
            assert.are.same({ { SHARP, 200 } }, client.bought)
            assert.is_true(client:printedContains("Bought 200 Sharp Arrow."))
        end)

        it("says what it bought once the client has loaded the ammo, in the client's name", function()
            local client = hunter(0)
            client.playerLevel = 12
            client.unloadedItems[SHARP] = true
            client.merchant = { SHARP }
            client:fire("MERCHANT_SHOW")
            assert.are.same({ { SHARP, 200 } }, client.bought)
            assert.is_false(client:printedContains("Bought 200"), "not before the name is known")
            client:loadItem(SHARP)
            assert.is_true(client:printedContains("Bought 200 Sharp Arrow."))
        end)

        it("fills the ammo bag's slots, minus what the hunter has", function()
            local client = hunter(0)
            client.playerLevel = 12
            client.ammoBag = { slots = 4, type = 1 }
            client:stock(SHARP, 300)
            client.merchant = { SHARP }
            client:fire("MERCHANT_SHOW")
            assert.are.same({ { SHARP, 200 }, { SHARP, 200 }, { SHARP, 100 } }, client.bought)
        end)

        it("buys bullets for a gun, arrows for a crossbow, and as many stacks as set", function()
            local client = hunter(0)
            client.ranged = GUN
            client.merchant = { ROUGH, LIGHT_SHOT }
            client.Addon:GetModule("Ammo"):GetOptions().args.stacks.set(nil, 2)
            client:fire("MERCHANT_SHOW")
            assert.are.same({ { LIGHT_SHOT, 200 }, { LIGHT_SHOT, 200 } }, client.bought)
            client = hunter(0)
            client.ranged = CROSSBOW
            client.merchant = { ROUGH, LIGHT_SHOT }
            client:fire("MERCHANT_SHOW")
            assert.are.same({ { ROUGH, 200 } }, client.bought)
        end)

        it("buys nothing when there is enough, the vendor has none, without a bow, or switched off", function()
            local client = hunter(0)
            client:stock(ROUGH, 250)
            client.merchant = { ROUGH }
            client:fire("MERCHANT_SHOW")
            client.merchant = { 117 }
            client:fire("MERCHANT_SHOW")
            client.merchant, client.ranged = { ROUGH }, SWORD
            client:fire("MERCHANT_SHOW")
            client.ranged = BOW
            client.Addon:GetModule("Ammo"):GetOptions().args.buy.set(nil, false)
            client:stock(ROUGH, 0)
            client:fire("MERCHANT_SHOW")
            assert.are.same({}, client.bought)
        end)
    end)
end)
