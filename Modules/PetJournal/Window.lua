local _, ns = ...

-- The Pets tab of Beastkeeper's window (Core\Window.lua): every pet in the journal on the left, the pet
-- out first, the ones the hunter no longer has under a Past pets heading at the end, and a card
-- for the chosen one on the right: its model, name, level and loyalty, its
-- family's specialization (Ferocity, Cunning, Tenacity: Beastkeeper.SpecName), the journal (Journal.lua)
-- and its abilities, those it could teach you in green. The model is the pet
-- out itself; a stabled pet's as the stable showed it (its displayID), else the beast it was
-- tamed as. Dragging turns it.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("PetJournal") --[[@as AddonPetJournal]]

local LIST_WIDTH, ROW_HEIGHT, ROWS, MODEL_SIZE = 180, 20, 16, 180
-- How far a pixel of drag turns the model, in radians.
local TURN = 0.01
local OUT, AWAY, HEADING = { 1, 1, 1 }, { 0.6, 0.6, 0.6 }, { 1, 0.82, 0 }
-- In the list, where the past pets start: a row with a heading instead of a pet. No journal key
-- looks like it (numbers, GUIDs, "stable:...").
local PAST = "past"

-- The pets in list order, refilled for each look.
---@type string[]
local order = {}

---The pet out before every other pet, the hunter's pets before the past ones, each by name.
---@param a string
---@param b string
---@return boolean
local function Earlier(a, b)
    if a == M.current or b == M.current then return a == M.current end
    local pets = M:Pets()
    local pastA, pastB = pets[a].past == true, pets[b].past == true
    if pastA ~= pastB then return pastB end
    return (pets[a].name or "") < (pets[b].name or "")
end

---The journal's pets in list order: the pet out first, the hunter's other pets by name; with
---`withPast`, then PAST and the pets the hunter no longer has, by name.
---@param withPast boolean?
---@return string[]
local function Order(withPast)
    wipe(order)
    local pets = M:Pets()
    for key, entry in pairs(pets) do
        if withPast or not entry.past then order[#order + 1] = key end
    end
    table.sort(order, Earlier)
    for index, key in ipairs(order) do
        if pets[key].past then
            table.insert(order, index, PAST)
            break
        end
    end
    return order
end
-- The Stable tab (Stable.lua) lists the hunter's pets in the same order, without the past ones.
M.PetOrder = Order

---Shows the pet's model: the pet out, else its stable model, else the beast it was; none without.
---@param model PlayerModel
---@param key string
---@param entry AddonJournalEntry
local function ShowModel(model, key, entry)
    model:ClearModel()
    if key == M.current and UnitExists("pet") then
        model:SetUnit("pet")
    elseif entry.displayID then
        model:SetDisplayInfo(entry.displayID)
    elseif entry.first.npc then
        model:SetCreature(entry.first.npc)
    else
        model:Hide()
        return
    end
    model:Show()
end
M.ShowModel = ShowModel

---Turns the model while the mouse drags it.
---@param model AddonPetModel
local function OnUpdate(model)
    if not model.dragX then return end
    local x = GetCursorPosition()
    model:SetFacing(model:GetFacing() + (x - model.dragX) * TURN)
    model.dragX = x
end

---@param model AddonPetModel
local function OnMouseDown(model)
    model.dragX = GetCursorPosition()
end

---@param model AddonPetModel
local function OnMouseUp(model)
    model.dragX = nil
end

---A text on the card, in the skin's font.
---@param panel AddonPetsPanel
---@param template string
---@param size number
---@return FontString
local function Text(panel, template, size)
    local text = panel:CreateFontString(nil, "OVERLAY", template)
    text:SetJustifyH("LEFT")
    text:SetWidth(Addon.WINDOW_PANEL_WIDTH - LIST_WIDTH - MODEL_SIZE - 30)
    panel.skin.Font(text, size)
    return text
end

---Builds the panel: the list's rows, the model and the card's texts.
---@param panel AddonPetsPanel
---@param skin AddonButtonHolderSkin
local function Create(panel, skin)
    panel.skin = skin
    panel.rows = {}
    for index = 1, ROWS do
        local row = CreateFrame("Button", nil, panel) --[[@as AddonPetRow]]
        row:SetSize(LIST_WIDTH, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", 6, 0)
        skin.Font(row.label, 12)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:SetScript("OnClick", function()
            if not row.key then return end -- the Past pets heading
            M.picked = row.key
            Addon:RefreshWindow("pets")
        end)
        panel.rows[index] = row
    end
    local model = CreateFrame("PlayerModel", nil, panel) --[[@as AddonPetModel]]
    model:SetSize(MODEL_SIZE, MODEL_SIZE)
    model:SetPoint("TOPRIGHT")
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", OnMouseDown)
    model:SetScript("OnMouseUp", OnMouseUp)
    model:SetScript("OnUpdate", OnUpdate)
    panel.model = model
    panel.name = Text(panel, "GameFontNormalLarge", 16)
    panel.name:SetPoint("TOPLEFT", LIST_WIDTH + 16, 0)
    panel.level = Text(panel, "GameFontHighlight", 12)
    panel.level:SetPoint("TOPLEFT", panel.name, "BOTTOMLEFT", 0, -4)
    panel.spec = Text(panel, "GameFontNormal", 12)
    panel.spec:SetPoint("TOPLEFT", panel.level, "BOTTOMLEFT", 0, -4)
    panel.journal = Text(panel, "GameFontHighlight", 12)
    panel.journal:SetPoint("TOPLEFT", panel.spec, "BOTTOMLEFT", 0, -10)
    panel.abilities = Text(panel, "GameFontHighlight", 12)
    panel.abilities:SetPoint("TOPLEFT", panel.journal, "BOTTOMLEFT", 0, -10)
end

---Fills the list and the chosen pet's card.
---@param panel AddonPetsPanel
local function Refresh(panel)
    local pets = M:Pets()
    local keys = Order(true)
    for index, row in ipairs(panel.rows) do
        local key = keys[index]
        row.key = key ~= PAST and key or nil
        row:SetShown(key ~= nil)
        if key == PAST then
            row.label:SetText(L.PETJOURNAL_PAST)
            row.label:SetTextColor(HEADING[1], HEADING[2], HEADING[3])
        elseif key then
            local entry = pets[key]
            row.label:SetText(L.PETJOURNAL_ROW:format(entry.name or "?", entry.level or 0, entry.family or "?"))
            local colour = key == M.current and OUT or AWAY
            row.label:SetTextColor(colour[1], colour[2], colour[3])
        end
    end
    local key = M:Chosen()
    local entry = key and pets[key]
    if not key or not entry then
        panel.name:SetText(L.PETJOURNAL_NONE)
        panel.level:SetText("")
        panel.spec:SetText("")
        panel.journal:SetText("")
        panel.abilities:SetText("")
        panel.model:Hide()
        return
    end
    panel.name:SetText(entry.name or "?")
    panel.level:SetText(M.LevelLine(entry))
    panel.spec:SetText(Addon.FamilyLine(Addon.FamilyID(entry.family)))
    panel.journal:SetText(table.concat(M:JournalLines(key, true), "\n"))
    panel.abilities:SetText(M.AbilitiesLine(entry, true) or "")
    ShowModel(panel.model, key, entry)
end

Addon:RegisterWindowTab({
    id = "pets",
    title = L.PETJOURNAL_TAB,
    order = 10,
    module = "PetJournal",
    Create = Create,
    Refresh = Refresh,
})
