-- Data Broker: Kennel as a LibDataBroker-1.1 data source, for Titan Panel, ChocolateBar, ElvUI's
-- datatexts and the like: the pet out in its text, more in its tooltip, Kennel's page on a click.
-- The simulated pet is Fluffy, a level 15 cat, happy, loyalty 4, 43 of 50 training points free.

---Kennel's data object.
---@return table?
local function broker()
    return LibStub("LibDataBroker-1.1"):GetDataObjectByName("Kennel")
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
        assert.are.equal("Kennel", object.label)
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
        assert.are.equal("Click: Kennel's window. Right-click: settings.", lines[#lines])
        client.Kennel:SetModuleOn("PetJournal", false)
        assert.are.equal(4, #tooltip(client), "no journal while it is off")
        client:petGone():fire("UNIT_PET", "player")
        assert.are.equal("No pet out", tooltip(client)[1])
    end)

    it("opens Kennel's window on a click, the options on a right-click", function()
        local client = NewClient():login()
        broker().OnClick(nil, "LeftButton")
        assert.is_true(_G.KennelWindow.shown)
        broker().OnClick(nil, "RightButton")
        assert.are.same({ client.Kennel.optionsCategoryID }, client.opened)
    end)

    it("says so while switched off, and is not there on another class", function()
        local client = NewClient():login()
        client.Kennel:SetModuleOn("Broker", false)
        assert.are.equal("Off", broker().text)
        client.Kennel:SetModuleOn("Broker", true)
        assert.are.equal("Fluffy: Happy, 43 TP", broker().text)
        NewClient({ class = "MAGE" }):login()
        assert.is_nil(broker())
    end)
end)
