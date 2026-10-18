-- Kennel's window: a frame of its own with a tab per part (modules add them), opened by /kennel,
-- the broker, a key binding; styled by the chosen holder skin. The Pets tab (Pet Journal): every
-- pet of the character, the pet out first, and a card with its model and journal.

local FLUFFY, SHADOW = "3069428", "77"

---The window, opened by /kennel.
---@param client table
---@return table
local function open(client)
    client:slash("")
    return _G.KennelWindow
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
    return client.Kennel.window.panels.pets
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
            specialization = "Ferocity",
            displayID = 903,
            creatureID = 1131,
        },
        { petNumber = 78, name = "Ash", level = 9, familyName = "Boar", specialization = "" },
    }
    client:fire("PET_STABLE_UPDATE")
    return client
end

describe("Kennel's window", function()
    it("opens with /kennel on its first tab, and closes again; /kennel config opens the options", function()
        local client = NewClient():login()
        local window = open(client)
        assert.is_true(window.shown)
        assert.are.equal("pets", client.Kennel.window.current)
        assert.are.equal("Kennel", window.title.text)
        open(client)
        assert.is_false(window.shown)
        client:slash("config")
        assert.are.same({ client.Kennel.optionsCategoryID }, client.opened)
    end)

    it("closes with Escape, moves by dragging, and keeps its place", function()
        local client = NewClient():login()
        local window = open(client)
        local found = false
        for _, name in ipairs(UISpecialFrames) do
            found = found or name == "KennelWindow"
        end
        assert.is_true(found)
        window:GetScript("OnDragStart")(window)
        window:GetScript("OnDragStop")(window)
        assert.are.same(
            { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 300, y = 700 },
            client.Kennel.db.profile.window.pos
        )
        client:logout()
        client = NewClient({ saved = Saved() }):login()
        window = open(client)
        assert.are.same({ "TOPLEFT", UIParent, "BOTTOMLEFT", 300, 700 }, window.points[#window.points])
    end)

    it("has the look of the chosen holder skin", function()
        local client = NewClient():login()
        open(client)
        assert.are.equal("Kennel", client.Kennel.window.skin.name)
    end)

    it("shows a tab only while its module is on, and the options without any", function()
        local client = NewClient():login()
        local window = open(client)
        assert.is_true(client.Kennel.window.tabs.pets.shown)
        window:Hide()
        client.Kennel:SetModuleOn("PetJournal", false)
        open(client)
        assert.is_false(window.shown)
        assert.are.same({ client.Kennel.optionsCategoryID }, client.opened)
    end)

    it("opens from the key binding's button and from the broker; the broker's right-click opens the options", function()
        local client = NewClient():login()
        assert.are.equal("Kennel: open or close the window", _G["BINDING_NAME_CLICK KennelWindowButton:LeftButton"])
        click(_G.KennelWindowButton)
        assert.is_true(_G.KennelWindow.shown)
        click(_G.KennelWindowButton)
        local broker = LibStub("LibDataBroker-1.1"):GetDataObjectByName("Kennel")
        broker.OnClick(nil, "LeftButton")
        assert.is_true(_G.KennelWindow.shown)
        broker.OnClick(nil, "RightButton")
        assert.are.same({ client.Kennel.optionsCategoryID }, client.opened)
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
        assert.are.equal("", panel.spec.text, "the stable never named Fluffy's specialization")
        assert.is_truthy(panel.journal.text:find("Out together: 0 min.", 1, true), panel.journal.text)
        assert.is_nil(panel.journal.text:find("Abilities", 1, true), "abilities have their own line")
        click(panel.rows[3])
        assert.are.equal(SHADOW, client.Kennel:GetModule("PetJournal").picked)
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
        client.Kennel:RegisterWindowTab({
            id = "test",
            title = "Test",
            order = 5,
            Create = function()
                made = made + 1
            end,
            Refresh = function() end,
        })
        open(client)
        local window = client.Kennel.window
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
        client.Kennel:SetModuleOn("AbilityLearned", false)
        client.Kennel:RefreshWindow("pets")
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
        client.Kennel:GetModule("PetJournal"):Pets()[SHADOW].displayID = nil
        client.Kennel:RefreshWindow("pets")
        assert.are.same({ creature = 1131 }, model.shownModel)
        client.Kennel:GetModule("PetJournal"):Pets()[SHADOW].first.npc = nil
        client.Kennel:RefreshWindow("pets")
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
        local entry = client.Kennel:GetModule("PetJournal"):Pets()[SHADOW]
        assert.are.equal("Shadow", entry.name)
        assert.are.equal(12, entry.level)
        assert.are.equal("Wolf", entry.family)
        assert.are.equal(903, entry.displayID)
        assert.are.equal(1131, entry.first.npc)
        assert.are.equal("Ferocity", entry.specialization)
        assert.is_nil(client.Kennel:GetModule("PetJournal"):Pets()["78"].specialization, "an empty one is none")
        assert.are.equal(FLUFFY, client.Kennel:GetModule("PetJournal").current)
    end)

    it("reads no stable on a client without one", function()
        local client = NewClient({ noStableInfo = true }):login()
        client:fire("PET_STABLE_UPDATE")
        assert.is_nil(client.Kennel:GetModule("PetJournal"):Pets()[SHADOW])
    end)
end)
