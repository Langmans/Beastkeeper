local _, ns = ...

-- The list a right-click on the feed button opens: every food in feeding order, each row a secure
-- button that feeds that food, for when another than the first should go (a full bag: feed what
-- you carry least of). Rows are made once and reused; their macro text is set when the list
-- opens, which only happens outside combat. A row's click, a second right-click, Escape or a
-- change in the bags closes it.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("Feeding") --[[@as KennelFeeding]]

local ROW_HEIGHT, WIDTH, PAD = 24, 220, 4

local list = CreateFrame("Frame", "KennelFeedList", UIParent)
list:SetWidth(WIDTH)
list:SetFrameStrata("DIALOG")
list:Hide()
table.insert(UISpecialFrames, "KennelFeedList")
-- The chosen holder skin (Core\Buttons.lua), applied the first time the list opens.
---@type KennelButtonHolderSkin?
local skin

---@type KennelFoodRow[]
local rows = {}

local function Close()
    list:Hide()
end

---The row at `index`, made the first time.
---@param index number
---@return KennelFoodRow
local function Row(index)
    if rows[index] then return rows[index] end
    local row = CreateFrame("Button", "KennelFeedChoice" .. index, list, "SecureActionButtonTemplate") --[[@as KennelFoodRow]]
    row:SetSize(WIDTH - 2 * PAD, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", PAD, -PAD - (index - 1) * ROW_HEIGHT)
    row:RegisterForClicks("AnyUp")
    row:SetAttribute("type", "macro")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
    row.icon:SetPoint("LEFT", 2, 0)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    local look = skin --[[@as KennelButtonHolderSkin]]
    look.Font(row.label, 12)
    if look.CropIcon then look.CropIcon(row.icon) end
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:HookScript("OnClick", Close)
    rows[index] = row
    return row
end

---Opens the list under the feed button, or closes it. Not in combat, where its rows cannot
---change (nor can Feed Pet be cast), and not without food.
function M:ToggleFoodList()
    if list:IsShown() then return Close() end
    local foods = self:Foods()
    if InCombatLockdown() or #foods == 0 then return end
    skin = skin or Kennel:StyleButtonHolder(list)
    for index, food in ipairs(foods) do
        local row = Row(index)
        row:SetAttribute("macrotext", M.FeedMacro(food))
        row.icon:SetTexture(C_Item.GetItemIconByID(food.itemID))
        row.label:SetText(L.FEEDING_FOOD:format(M.FoodName(food), food.count))
        row.label:SetTextColor(M.FoodColor(food))
        row:Show()
    end
    for index = #foods + 1, #rows do
        rows[index]:Hide()
    end
    list:SetHeight(#foods * ROW_HEIGHT + 2 * PAD)
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", M.button, "BOTTOMLEFT", 0, -2)
    list:Show()
end

---Closes the list: its rows point at bag slots that may have changed.
function M:CloseFoodList()
    if not InCombatLockdown() then Close() end
end
