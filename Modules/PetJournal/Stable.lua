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

---A text on a card, in the skin's font.
---@param card Frame
---@param skin KennelButtonHolderSkin
---@param template string?
---@param size number?
---@return FontString
local function Text(card, skin, template, size)
    local text = card:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", 6, 0)
    text:SetPoint("RIGHT", -6, 0)
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
        card.name = Text(card, skin, "GameFontNormal", 13)
        card.name:SetPoint("TOP", 0, -6)
        card.level = Text(card, skin)
        card.level:SetPoint("TOP", card.name, "BOTTOM", 0, -2)
        card.spec = Text(card, skin)
        card.spec:SetPoint("TOP", card.level, "BOTTOM", 0, -2)
        card.abilities = Text(card, skin)
        card.abilities:SetPoint("TOP", 0, -MODEL_SIZE - 10)
        card.teach = Text(card, skin, "GameFontNormalSmall")
        card.teach:SetPoint("BOTTOM", 0, 6)
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
            card.spec:SetText(entry.specialization or "")
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
