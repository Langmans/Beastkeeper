local _, ns = ...

-- The Stable tab of Kennel's window (Core\Window.lua): the character's pets side by side, the pet
-- out first, each card with its model, level, specialization, abilities (those it could teach you
-- in green) and how many ranks it could still teach you. A click opens the pet in the Pets tab
-- (Window.lua).

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("PetJournal") --[[@as KennelPetJournal]]

local COLUMNS, ROWS, CARD_HEIGHT, MODEL_SIZE, GAP = 3, 2, 190, 80, 8

---A text on a card, in the skin's font, from `top` down (its offset from the card's top, or below
---the text `under`); `right` keeps it clear of the model.
---@param card Frame
---@param skin KennelButtonHolderSkin
---@param top number|FontString
---@param right number the gap to the card's right edge
---@param template string?
---@param size number?
---@return FontString
local function Text(card, skin, top, right, template, size)
    local text = card:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    text:SetJustifyH("LEFT")
    if type(top) == "number" then
        text:SetPoint("TOPLEFT", 6, top)
        text:SetPoint("TOPRIGHT", -right, top)
    else
        text:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -2)
        text:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, -2)
    end
    skin.Font(text, size or 11)
    return text
end

---Builds the panel: a grid of cards.
---@param panel KennelStablePanel
---@param skin KennelButtonHolderSkin
local function Create(panel, skin)
    panel.cards = {}
    local width = (Kennel.WINDOW_PANEL_WIDTH - (COLUMNS - 1) * GAP) / COLUMNS
    for index = 1, COLUMNS * ROWS do
        local column, row = (index - 1) % COLUMNS, math.floor((index - 1) / COLUMNS)
        local card = CreateFrame("Button", nil, panel) --[[@as KennelStableCard]]
        card:SetSize(width, CARD_HEIGHT)
        card:SetPoint("TOPLEFT", column * (width + GAP), -row * (CARD_HEIGHT + GAP))
        skin.Style(card)
        card.model = CreateFrame("PlayerModel", nil, card)
        card.model:SetSize(MODEL_SIZE, MODEL_SIZE)
        card.model:SetPoint("TOPRIGHT", -4, -4)
        local beside = MODEL_SIZE + 10
        card.name = Text(card, skin, -6, beside, "GameFontNormal", 13)
        card.level = Text(card, skin, card.name, beside)
        card.spec = Text(card, skin, card.level, beside)
        card.abilities = Text(card, skin, -MODEL_SIZE - 10, 6)
        card.teach = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.teach:SetJustifyH("LEFT")
        card.teach:SetPoint("BOTTOMLEFT", 6, 6)
        card.teach:SetPoint("BOTTOMRIGHT", -6, 6)
        skin.Font(card.teach, 11)
        card:SetScript("OnClick", function()
            M.picked = card.key
            Kennel:ShowWindowTab("pets")
        end)
        panel.cards[index] = card
    end
end

---Fills the cards, one per pet in list order; the rest hidden.
---@param panel KennelStablePanel
local function Refresh(panel)
    local pets = M:Pets()
    local keys = M.PetOrder()
    for index, card in ipairs(panel.cards) do
        local key = keys[index]
        card.key = key
        card:SetShown(key ~= nil)
        if key then
            local entry = pets[key]
            card.name:SetText(entry.name or "?")
            card.level:SetText(M.LevelLine(entry))
            card.spec:SetText(Kennel.SpecName(Kennel.FamilyID(entry.family)) or "")
            card.abilities:SetText(M.AbilitiesLine(entry, true) or "")
            local count = M.TeachCount(entry)
            card.teach:SetText(count > 0 and L.PETJOURNAL_TEACHES:format(count) or L.PETJOURNAL_TEACHES_NONE)
            M.ShowModel(card.model, key, entry)
        end
    end
end

Kennel:RegisterWindowTab({
    id = "stable",
    title = L.PETJOURNAL_TAB_STABLE,
    order = 40,
    module = "PetJournal",
    Create = Create,
    Refresh = Refresh,
})
