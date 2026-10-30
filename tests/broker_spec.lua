-- Data Broker: Beastkeeper as a LibDataBroker-1.1 data source, for Titan Panel, ChocolateBar, ElvUI's
-- datatexts and the like: the pet out in its text, more in its tooltip, Beastkeeper's page on a click.
-- The simulated pet is Fluffy, a level 15 cat, happy, loyalty 4, 43 of 50 training points free.

---Beastkeeper's data object.
---@return table?
local function broker()
    return LibStub("LibDataBroker-1.1"):GetDataObjectByName("Beastkeeper")
end

---The tooltip a display shows for it: the texts of its lines.
---@param client table
---@return string[]
local function tooltip(client)
    client.tooltipLines = {}
    broker().OnTooltipShow(GameTooltip)
    local texts = {}
    for _, line in ipairs(client.tooltipLines) do
        texts[#texts + 1] = line.text
    end
    return texts
end

describe("Data Broker", function()
    it("shows the pet out: its name, happiness and free training points", function()
        local client = NewClient():login()
        local object = broker()
        assert.are.equal("data source", object.type)
        assert.are.equal("Fluffy: Happy, 43 TP", object.text)
        assert.are.equal("Beastkeeper", object.label)
        client:setHappiness(2)
        assert.are.equal("Fluffy: Content, 43 TP", object.text)
        client:gainPoints(5)
        assert.are.equal("Fluffy: Content, 48 TP", object.text)
        client:petGone():fire("UNIT_PET", "player")
        assert.are.equal("No pet out", object.text)
    end)

    it("tells more in its tooltip: level, loyalty, points, then the pet's journal", function()
        local client = NewClient():login():advance(65)
        local lines = tooltip(client)
        assert.are.equal("Fluffy, level 15 Cat", lines[1])
        assert.is_truthy(lines[2]:find("^Loyalty 4 %(.*Dependable"), lines[2])
        assert.are.equal("43 of 50 training points free", lines[3])
        assert.is_truthy(table.concat(lines, "\n"):find("Out together: 1 min.", 1, true), "the journal")
        assert.are.equal(
            "Click: Beastkeeper's window. Middle-click: the pet abilities. Right-click: settings.",
            lines[#lines]
        )
        client.Addon:SetModuleOn("PetJournal", false)
        assert.are.equal(4, #tooltip(client), "no journal while it is off")
        client:petGone():fire("UNIT_PET", "player")
        assert.are.equal("No pet out", tooltip(client)[1])
    end)

    it("advises what to train with the free points, once Beast Training gave the costs", function()
        local client = NewClient({ era = true }):login():advance(1)
        local text = table.concat(tooltip(client), "\n")
        assert.is_nil(text:find("free points", 1, true), "no costs known yet")
        client:openCraft({
            { "Bite", "Rank 1", "used", 1, 1 },
            { "Bite", "Rank 2", "available", 10, 8 },
            { "Dash", "Rank 1", "available", 40, 1 },
        })
        text = table.concat(tooltip(client), "\n")
        assert.truthy(text:find("Train (Upgrades), 43 free points: Bite rank 2 (10); 33 left.", 1, true), text)
        assert.truthy(text:find("Saving for Dash rank 1 (40): 7 points short.", 1, true), text)
        client.Addon:GetModule("PetJournal"):Pets()[client.Addon:GetModule("PetJournal").current].advice = "dps"
        text = table.concat(tooltip(client), "\n")
        assert.truthy(text:find("Train (DPS), 43 free points: Bite rank 2 (10); 33 left.", 1, true), text)
    end)

    it("has a minimap button, through LibDBIcon, which the page hides", function()
        local client = NewClient():login()
        local button = LibStub("LibDBIcon-1.0"):GetMinimapButton("Beastkeeper")
        assert.is_true(button.shown)
        local option = client.Addon:GetModule("Broker"):GetOptions().args.minimap
        assert.is_true(option.get())
        option.set(nil, false)
        assert.is_false(button.shown)
        assert.is_false(option.get())
        assert.is_true(client.Addon:GetModule("Broker").db.profile.minimap.hide, "LibDBIcon's own key")
        option.set(nil, true)
        assert.is_true(button.shown)
        client.Addon:SetModuleOn("Broker", false)
        assert.is_false(button.shown, "gone with the module")
        option.set(nil, true)
        assert.is_false(button.shown, "the switch alone does not bring it back")
        client.Addon:SetModuleOn("Broker", true)
        assert.is_true(button.shown)
        button:GetScript("OnClick")(button, "LeftButton")
        assert.is_true(_G.BeastkeeperWindow.shown, "a click opens the window, as the broker's")
    end)

    it("opens Beastkeeper's window on a click, the options on a right-click", function()
        local client = NewClient():login()
        broker().OnClick(nil, "LeftButton")
        assert.is_true(_G.BeastkeeperWindow.shown)
        broker().OnClick(nil, "RightButton")
        assert.are.same({ client.Addon.optionsCategoryID }, client.opened)
    end)

    it("opens the window on the pet abilities on a middle-click", function()
        local client = NewClient():login()
        broker().OnClick(nil, "MiddleButton")
        assert.is_true(_G.BeastkeeperWindow.shown)
        assert.are.equal("abilities", client.Addon.window.current)
    end)

    it("says so while switched off, and is not there on another class", function()
        local client = NewClient():login()
        client.Addon:SetModuleOn("Broker", false)
        assert.are.equal("Off", broker().text)
        client.Addon:SetModuleOn("Broker", true)
        assert.are.equal("Fluffy: Happy, 43 TP", broker().text)
        NewClient({ class = "MAGE" }):login()
        assert.is_nil(broker())
    end)
end)
