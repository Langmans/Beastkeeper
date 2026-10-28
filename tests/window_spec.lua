-- Beastkeeper's window: a frame of its own with a tab per part (modules add them), opened by /beastkeeper,
-- the broker, a key binding; styled by the chosen holder skin. The Pets tab (Pet Journal): every
-- pet of the character, the pet out first, and a card with its model and journal.

local FLUFFY, SHADOW = "3069428", "77"

---The window, opened by /beastkeeper.
---@param client table
---@return table
local function open(client)
    client:slash("")
    return _G.BeastkeeperWindow
end

---Clicks a button by its OnClick script.
---@param button table
---@param mouse string?
local function click(button, mouse)
    button:GetScript("OnClick")(button, mouse or "LeftButton")
end

---The Pets panel.
---@param client table
---@return table
local function pets(client)
    return client.Addon.window.panels.pets
end

---The texts of the list's shown rows.
---@param panel table
---@return string[]
local function rows(panel)
    local texts = {}
    for _, row in ipairs(panel.rows) do
        if row.shown then texts[#texts + 1] = row.label.text end
    end
    return texts
end

---A client with Fluffy out and Shadow, a level 12 wolf, in the stable, read there once.
---@return table
local function withStable()
    local client = NewClient():login():advance(1)
    client.stable.stabled = {
        {
            petNumber = 77,
            name = "Shadow",
            level = 12,
            familyName = "Wolf",
            specialization = "Default",
            displayID = 903,
            creatureID = 1131,
        },
        { petNumber = 78, name = "Ash", level = 9, familyName = "Boar", specialization = "Default" },
    }
    client:fire("PET_STABLE_UPDATE")
    return client
end

describe("Beastkeeper's window", function()
    it("opens with /beastkeeper on its first tab, and closes again; /beastkeeper config opens the options", function()
        local client = NewClient():login()
        local window = open(client)
        assert.is_true(window.shown)
        assert.are.equal("pets", client.Addon.window.current)
        assert.are.equal("Beastkeeper", window.title.text)
        open(client)
        assert.is_false(window.shown)
        client:slash("config")
        assert.are.same({ client.Addon.optionsCategoryID }, client.opened)
    end)

    it("in Beastkeeper's own look: the game's dark dialog background with a tooltip border", function()
        local client = NewClient():login()
        local window = open(client)
        assert.are.equal("Interface\\DialogFrame\\UI-DialogBox-Background-Dark", window.backdrop.bgFile)
        assert.are.equal("Interface\\Tooltips\\UI-Tooltip-Border", window.backdrop.edgeFile)
    end)

    it("underlines the tab that shows, in the look's accent, under a line across the window", function()
        local client = NewClient():login()
        local window = open(client)
        local tabs = client.Addon.window.tabs
        assert.is_true(tabs.pets.selected.shown)
        assert.are.same({ 1, 0.82, 0, 1 }, tabs.pets.selected.color, "the game's gold")
        client.Addon:ShowWindowTab("abilities")
        assert.is_false(tabs.pets.selected.shown)
        assert.is_true(tabs.abilities.selected.shown)
        assert.is_true(window.divider.shown)
    end)

    it("closes with Escape, moves by dragging, and keeps its place", function()
        local client = NewClient():login()
        local window = open(client)
        local found = false
        for _, name in ipairs(UISpecialFrames) do
            found = found or name == "BeastkeeperWindow"
        end
        assert.is_true(found)
        window:GetScript("OnDragStart")(window)
        window:GetScript("OnDragStop")(window)
        assert.are.same(
            { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 300, y = 700 },
            client.Addon.db.profile.window.pos
        )
        client:logout()
        client = NewClient({ saved = Saved() }):login()
        window = open(client)
        assert.are.same({ "TOPLEFT", UIParent, "BOTTOMLEFT", 300, 700 }, window.points[#window.points])
    end)

    it("has the look of the chosen holder skin", function()
        local client = NewClient():login()
        open(client)
        assert.are.equal("Beastkeeper", client.Addon.window.skin.name)
    end)

    it("shows a tab only while its module is on, and the options without any", function()
        local client = NewClient():login()
        local window = open(client)
        assert.is_true(client.Addon.window.tabs.pets.shown)
        window:Hide()
        client.Addon:SetModuleOn("PetJournal", false)
        client.Addon:SetModuleOn("BeastMap", false)
        open(client)
        assert.is_false(window.shown)
        assert.are.same({ client.Addon.optionsCategoryID }, client.opened)
    end)

    it("opens from the key binding's button and from the broker; the broker's right-click opens the options", function()
        local client = NewClient():login()
        assert.are.equal(
            "Beastkeeper: open or close the window",
            _G["BINDING_NAME_CLICK BeastkeeperWindowButton:LeftButton"]
        )
        click(_G.BeastkeeperWindowButton)
        assert.is_true(_G.BeastkeeperWindow.shown)
        click(_G.BeastkeeperWindowButton)
        local broker = LibStub("LibDataBroker-1.1"):GetDataObjectByName("Beastkeeper")
        broker.OnClick(nil, "LeftButton")
        assert.is_true(_G.BeastkeeperWindow.shown)
        broker.OnClick(nil, "RightButton")
        assert.are.same({ client.Addon.optionsCategoryID }, client.opened)
    end)
end)

describe("the Pets tab", function()
    it("lists every pet, the pet out first, and shows the chosen one's card", function()
        local client = withStable()
        open(client)
        local panel = pets(client)
        assert.are.same({ "Fluffy, 15 Cat", "Ash, 9 Boar", "Shadow, 12 Wolf" }, rows(panel))
        assert.are.equal("Fluffy", panel.name.text)
        assert.are.equal("Level 15 Cat, loyalty 4 (|cff00cc7aDependable|r).", panel.level.text)
        assert.are.equal("Ferocity", panel.spec.text, "the cat's, not the client's \"Default\"")
        assert.is_truthy(panel.journal.text:find("Out together: 0 min.", 1, true), panel.journal.text)
        assert.is_nil(panel.journal.text:find("Abilities", 1, true), "abilities have their own line")
        click(panel.rows[3])
        assert.are.equal(SHADOW, client.Addon:GetModule("PetJournal").picked)
        assert.are.equal("Shadow", panel.name.text)
        assert.are.equal("Level 12 Wolf, loyalty ?.", panel.level.text)
        assert.are.equal("Ferocity", panel.spec.text)
    end)

    it("says so while the journal has no pet yet", function()
        local client = NewClient({ noPet = true }):login()
        open(client)
        assert.are.equal("No pets yet: summon one.", pets(client).name.text)
        assert.are.same({}, rows(pets(client)))
        assert.is_false(pets(client).model.shown)
    end)

    it("switches between tabs, in their order", function()
        local client = NewClient():login()
        local made = 0
        client.Addon:RegisterWindowTab({
            id = "test",
            title = "Test",
            order = 5,
            Create = function()
                made = made + 1
            end,
            Refresh = function() end,
        })
        open(client)
        local window = client.Addon.window
        assert.are.equal("test", window.current, "the first in order")
        click(window.tabs.pets)
        assert.are.equal("pets", window.current)
        assert.is_false(window.panels.test.shown)
        click(window.tabs.test)
        assert.is_false(window.panels.pets.shown)
        assert.are.equal(1, made, "a panel is made once")
    end)

    it("shows the abilities, those the pet could teach you in green", function()
        local client = NewClient():login():advance(1)
        client:openTrainer({ { "Bite", "used", 17253 }, { "Cower", "used", 1742 } }):closeTrainer()
        open(client)
        assert.are.equal(
            "Abilities: Bite (Rank 1), |cff40ff40Claw (Rank 2)|r, Cower (Rank 1), Great Stamina (Rank 1), Growl.",
            pets(client).abilities.text,
            "Bite 1 and Cower 1 known; Great Stamina comes from a trainer"
        )
        client.Addon:SetModuleOn("AbilityLearned", false)
        client.Addon:RefreshWindow("pets")
        assert.are.equal(
            "Abilities: Bite (Rank 1), Claw (Rank 2), Cower (Rank 1), Great Stamina (Rank 1), Growl.",
            pets(client).abilities.text,
            "nothing to compare with"
        )
    end)

    it("turns the pet out's model, a stabled pet's from the stable, else the beast it was tamed as", function()
        local client = withStable()
        open(client)
        local model = pets(client).model
        assert.are.same({ unit = "pet" }, model.shownModel)
        click(pets(client).rows[3])
        assert.are.same({ displayID = 903 }, model.shownModel)
        client.Addon:GetModule("PetJournal"):Pets()[SHADOW].displayID = nil
        client.Addon:RefreshWindow("pets")
        assert.are.same({ creature = 1131 }, model.shownModel)
        client.Addon:GetModule("PetJournal"):Pets()[SHADOW].first.npc = nil
        client.Addon:RefreshWindow("pets")
        assert.is_false(model.shown)
    end)

    it("turns the model while the mouse drags it", function()
        local client = NewClient():login():advance(1)
        open(client)
        local model = pets(client).model
        client.cursorX = 100
        model:GetScript("OnMouseDown")(model)
        client.cursorX = 150
        model:GetScript("OnUpdate")(model)
        assert.are.equal(0.5, model.facing)
        model:GetScript("OnMouseUp")(model)
        client.cursorX = 300
        model:GetScript("OnUpdate")(model)
        assert.are.equal(0.5, model.facing, "not after the button is up")
    end)

    it("follows a pet summoned while it is open", function()
        local client = NewClient():login():advance(1)
        open(client)
        client.petGUID = "Pet-0-5250-0-1-3825-0100ABCDEF"
        client:summon("Whiskers", {}):advance(1)
        assert.are.equal("Whiskers", pets(client).name.text)
        assert.are.equal("Whiskers, 15 Cat", rows(pets(client))[1])
    end)

    it("keeps a stabled pet's name, level, family and model, and the beast it was", function()
        local client = withStable()
        local entry = client.Addon:GetModule("PetJournal"):Pets()[SHADOW]
        assert.are.equal("Shadow", entry.name)
        assert.are.equal(12, entry.level)
        assert.are.equal("Wolf", entry.family)
        assert.are.equal(903, entry.displayID)
        assert.are.equal(1131, entry.first.npc)
        assert.is_nil(entry.specialization, 'Forever says "Default" for every pet')
        assert.are.equal(FLUFFY, client.Addon:GetModule("PetJournal").current)
    end)

    it("reads no stable on a client without one", function()
        local client = NewClient({ noStableInfo = true }):login()
        client:fire("PET_STABLE_UPDATE")
        assert.is_nil(client.Addon:GetModule("PetJournal"):Pets()[SHADOW])
    end)
end)

describe("the Stable tab", function()
    ---The Stable panel, opened.
    local function stable(client)
        client.Addon:OpenWindow("stable")
        return client.Addon.window.panels.stable
    end

    it("shows every pet side by side, the pet out first, with what each could teach you", function()
        local client = withStable()
        client.Addon:GetModule("PetJournal"):Pets()[SHADOW].abilities = { "Bite (Rank 2)", "Dash (Rank 1)" }
        local panel = stable(client)
        local fluffy, shadow = panel.cards[1], panel.cards[3]
        assert.are.equal("Fluffy", fluffy.name.text)
        assert.are.equal("Level 15 Cat, loyalty 4 (|cff00cc7aDependable|r).", fluffy.level.text)
        assert.are.equal("Can teach you 3 |4rank:ranks;", fluffy.teach.text, "Bite 1, Claw 2, Cower 1")
        assert.are.same({ unit = "pet" }, fluffy.model.shownModel)
        assert.are.equal("Shadow", shadow.name.text)
        assert.are.equal("Ferocity", shadow.spec.text)
        assert.are.equal("Abilities: |cff40ff40Bite (Rank 2)|r, Dash (Rank 1).", shadow.abilities.text)
        assert.are.equal("Can teach you 1 |4rank:ranks;", shadow.teach.text)
        assert.are.same({ displayID = 903 }, shadow.model.shownModel)
        assert.are.equal("Nothing new for you", panel.cards[2].teach.text, "Ash has no abilities seen")
        assert.are.equal("Cunning", panel.cards[2].spec.text, "a boar")
        assert.is_false(panel.cards[4].shown)
    end)

    it("opens a pet's card in the Pets tab on a click", function()
        local client = withStable()
        local card = stable(client).cards[3]
        click(card)
        assert.are.equal("pets", client.Addon.window.current)
        assert.are.equal("Shadow", pets(client).name.text)
    end)
end)
