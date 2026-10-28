local _, ns = ...

-- The Families tab of Beastkeeper's window (Core\Window.lua): every pet family (Core\Constants\Families.lua), with
-- how many of the hunter's pets are of it; for the chosen one (the pet out's at first) its
-- specialization, diet, the abilities beasts teach it with how many ranks the hunter knows, and the
-- beasts of that family nearest first (BeastMap.lua's Nearest), each with a button that goes there,
-- and the first one's model.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as AddonBeastMap]]

local LIST_WIDTH, ROW_HEIGHT, LIST_ROWS = 150, 16, 20
local BEAST_ROWS, BEAST_HEIGHT, MODEL_SIZE = 3, 22, 150
local GO_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local CHOSEN, OTHER = { 1, 1, 1 }, { 0.6, 0.6, 0.6 }

-- The families in list order, the abilities' lines and a family's beasts; refilled for each look.
---@type number[], string[], number[]
local order, lines, beasts = {}, {}, {}

---@param a number
---@param b number
---@return boolean
local function ByName(a, b)
    return (Addon.FamilyName(a) or "") < (Addon.FamilyName(b) or "")
end

---The families on this client, by name: one Beastkeeper has for one client only (the Fox on WoW:
---Forever, Burning Crusade's on Burning Crusade) only there.
---@return number[]
local function Order()
    wipe(order)
    local client = (LibStub("LibTameable-1.0") --[[@as LibTameable]]):GetClient()
    for familyID, info in pairs(Addon.familyInfo) do
        if not info.client or info.client == client then order[#order + 1] = familyID end
    end
    table.sort(order, ByName)
    return order
end

---How many of the hunter's pets in the Pet Journal are of the family; 0 while it is off.
---@param familyID number
---@return number
local function PetCount(familyID)
    local journal = Addon:GetModule("PetJournal", true) --[[@as AddonPetJournal?]]
    if not journal or not journal:IsEnabled() then return 0 end
    local name, count = Addon.FamilyName(familyID), 0
    for _, entry in pairs(journal:Pets()) do
        if entry.family == name then count = count + 1 end
    end
    return count
end

---Whether a rank can be learned by the family: its list names it, or names none (every family).
---@param rank AddonPetAbilityRank
---@param familyID number
---@return boolean
local function ForFamily(rank, familyID)
    if #rank.families == 0 then return true end
    for _, id in ipairs(rank.families) do
        if id == familyID then return true end
    end
    return false
end

---The lines of the abilities beasts teach the family: per ability its ranks and how many the
---hunter knows, by ability name.
---@param familyID number
---@return string
local function AbilitiesText(familyID)
    ---@type table<number, {low: number, high: number, known: number}>
    local found = {}
    local ranks = Addon.data.petAbilityRanks --[[@as table<number, AddonPetAbilityRank>]]
    for spellID, rank in pairs(ranks) do
        if ForFamily(rank, familyID) then
            local seen = found[rank.ability] or { low = rank.rank, high = rank.rank, known = 0 }
            found[rank.ability] = seen
            seen.low, seen.high = math.min(seen.low, rank.rank), math.max(seen.high, rank.rank)
            if not M.Lacking(spellID) then seen.known = seen.known + 1 end
        end
    end
    wipe(lines)
    for ability, seen in pairs(found) do
        local name = Addon.SpellInfo(ability) or "?"
        lines[#lines + 1] = L.BEASTMAP_FAMILY_ABILITY:format(name, seen.low, seen.high, seen.known)
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

---The family's beasts in the data, nearest first.
---@param familyID number
---@return number[]
local function Beasts(familyID)
    wipe(beasts)
    local all = Addon.data.beasts --[[@as table<number, AddonBeast>]]
    for npc, beast in pairs(all) do
        if beast.family == familyID then beasts[#beasts + 1] = npc end
    end
    return M.Nearest(beasts)
end

---The diet line: "Eats: Meat, Fish"; empty when Beastkeeper does not know it.
---@param info AddonFamilyInfo
---@return string
local function DietText(info)
    if not info.diet then return "" end
    ---@type string[]
    local foods = {}
    for i, food in ipairs(info.diet) do
        foods[i] = L["BEASTMAP_FOOD_" .. food:upper()]
    end
    return L.BEASTMAP_EATS:format(table.concat(foods, ", "))
end

---A text in the skin's font.
---@param parent Frame
---@param skin AddonButtonHolderSkin
---@param template string?
---@param size number?
---@return FontString
local function Text(parent, skin, template, size)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    text:SetJustifyH("LEFT")
    skin.Font(text, size or 12)
    return text
end

---A family's portrait, cropped as the look crops icons (Beastkeeper:CropIcon).
---@param parent Frame
---@param skin AddonButtonHolderSkin
---@param size number
---@return Texture
local function Portrait(parent, skin, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size)
    Addon:CropIcon(icon, skin.CropIcon)
    return icon
end

---Builds the panel: the families' rows, the card's texts, the beasts' rows and the model.
---@param panel AddonFamiliesPanel
---@param skin AddonButtonHolderSkin
local function Create(panel, skin)
    panel.rows, panel.beasts = {}, {}
    for index = 1, LIST_ROWS do
        local row = CreateFrame("Button", nil, panel) --[[@as AddonFamilyRow]]
        row:SetSize(LIST_WIDTH, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row.icon = Portrait(row, skin, ROW_HEIGHT - 4)
        row.icon:SetPoint("LEFT", 4, 0)
        row.label = Text(row, skin)
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:SetScript("OnClick", function()
            panel.chosen = row.familyID
            Addon:RefreshWindow("families")
        end)
        panel.rows[index] = row
    end
    local left = LIST_WIDTH + 16
    panel.model = CreateFrame("PlayerModel", nil, panel)
    panel.model:SetSize(MODEL_SIZE, MODEL_SIZE)
    panel.model:SetPoint("TOPRIGHT")
    panel.titleIcon = Portrait(panel, skin, 20)
    panel.titleIcon:SetPoint("TOPLEFT", left, 0)
    panel.title = Text(panel, skin, "GameFontNormalLarge", 16)
    panel.title:SetPoint("LEFT", panel.titleIcon, "RIGHT", 6, 0)
    panel.spec = Text(panel, skin, "GameFontNormal")
    panel.spec:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4)
    panel.diet = Text(panel, skin)
    panel.diet:SetPoint("TOPLEFT", panel.spec, "BOTTOMLEFT", 0, -4)
    panel.abilities = Text(panel, skin)
    panel.abilities:SetPoint("TOPLEFT", panel.diet, "BOTTOMLEFT", 0, -10)
    panel.none = Text(panel, skin)
    panel.none:SetPoint("BOTTOMLEFT", left, BEAST_ROWS * BEAST_HEIGHT + 4)
    for index = 1, BEAST_ROWS do
        local row = CreateFrame("Frame", nil, panel) --[[@as AddonFamilyBeastRow]]
        row:SetHeight(BEAST_HEIGHT)
        row:SetPoint("BOTTOMLEFT", left, (BEAST_ROWS - index) * BEAST_HEIGHT)
        row:SetPoint("RIGHT")
        row.text = Text(row, skin)
        row.text:SetPoint("LEFT")
        row.go = CreateFrame("Button", nil, row)
        row.go:SetSize(BEAST_HEIGHT - 4, BEAST_HEIGHT - 4)
        row.go:SetPoint("RIGHT")
        row.go:SetNormalTexture(GO_ICON)
        row.go:SetScript("OnClick", function()
            M:GoToBeast(row.npc --[[@as number]])
        end)
        panel.beasts[index] = row
    end
end

---Fills the beasts' rows and the model from the family's beasts.
---@param panel AddonFamiliesPanel
---@param familyID number
local function FillBeasts(panel, familyID)
    local list = Beasts(familyID)
    for index, row in ipairs(panel.beasts) do
        local npc = list[index]
        row.npc = npc
        row:SetShown(npc ~= nil)
        if npc then
            local beast = Addon.data.beasts[npc] --[[@as AddonBeast]]
            row.text:SetText(L.BEASTMAP_TEACHER_LINE:format(M.Place(npc), M.LevelText(beast)))
            row.go:SetShown(beast.pins ~= nil)
        end
    end
    panel.none:SetText(#list == 0 and L.BEASTMAP_NO_BEASTS or "")
    -- By display ID the model shows at once; by NPC ID only once the client has the creature in its
    -- cache, else the old model stays: so cleared first.
    local first = list[1] and Addon.data.beasts[list[1]]
    if first then
        panel.model:ClearModel()
        if first.display then
            panel.model:SetDisplayInfo(first.display)
        else
            panel.model:SetCreature(list[1])
        end
        panel.model:Show()
    else
        panel.model:Hide()
    end
end

---Fills the list and the chosen family's card.
---@param panel AddonFamiliesPanel
local function Refresh(panel)
    local families = Order()
    if not panel.chosen then
        local out = Addon.PetFamilyID()
        panel.chosen = out and Addon.familyInfo[out] and out or families[1]
    end
    for index, row in ipairs(panel.rows) do
        local familyID = families[index]
        row.familyID = familyID
        row:SetShown(familyID ~= nil)
        if familyID then
            local name, count = Addon.FamilyName(familyID) or "?", PetCount(familyID)
            row.label:SetText(count > 0 and L.BEASTMAP_FAMILY_ROW:format(name, count) or name)
            row.icon:SetTexture(Addon.FamilyIcon(familyID))
            local colour = familyID == panel.chosen and CHOSEN or OTHER
            row.label:SetTextColor(colour[1], colour[2], colour[3])
        end
    end
    local familyID = panel.chosen --[[@as number]]
    local info = Addon.familyInfo[familyID]
    panel.title:SetText(Addon.FamilyName(familyID) or "?")
    panel.titleIcon:SetTexture(Addon.FamilyIcon(familyID))
    -- Pet specializations came with Wrath; WoW: Forever has them. The classic clients have a
    -- category and fixed modifiers per family instead.
    local hasSpecs = (LibStub("LibTameable-1.0") --[[@as LibTameable]]):GetClient() == "forever"
    if hasSpecs then
        panel.spec:SetText(Addon.SpecName(familyID) or "")
    else
        panel.spec:SetText(Addon.FamilyModsText(familyID) or "")
    end
    panel.diet:SetText(DietText(info))
    panel.abilities:SetText(AbilitiesText(familyID))
    FillBeasts(panel, familyID)
end

Addon:RegisterWindowTab({
    id = "families",
    title = L.BEASTMAP_TAB_FAMILIES,
    order = 30,
    module = "BeastMap",
    Create = Create,
    Refresh = Refresh,
})
