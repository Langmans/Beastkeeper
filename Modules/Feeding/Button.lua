local _, ns = ...

-- The feed button beside the pet frame. Only a secure button the player presses may cast Feed Pet
-- on a bag slot, so its macro text holds the first food's slot; the module rewrites it outside
-- combat. It shows while the pet is not happy: happiness is no macro condition, so the module
-- shows and hides it itself, also only outside combat (Feed Pet cannot be cast in combat anyway).
-- The border shows the happiness; the tooltip the feeding order. Shift-drag moves it; the place
-- is kept per profile.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("Feeding") --[[@as KennelFeeding]]

-- Border colour per happiness (1 unhappy, 2 content, 3 happy), and food line colour per bite.
local HAPPINESS = {
    { name = L.FEEDING_UNHAPPY, color = { 1, 0, 0 } },
    { name = L.FEEDING_CONTENT, color = { 1, 1, 0 } },
    { name = L.FEEDING_HAPPY, color = { 0, 1, 0 } },
}
local HINT_COLOR = { 0.5, 0.5, 0.5 }
local SIZE = 36

local button = CreateFrame("Button", "KennelFeedButton", UIParent, "SecureActionButtonTemplate")
button:SetSize(SIZE, SIZE)
button:SetFrameStrata("MEDIUM")
button:RegisterForClicks("AnyUp")
button:RegisterForDrag("LeftButton")
button:SetMovable(true)
button:Hide()
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- Styled by the chosen button skin (Core\Buttons.lua) the first time it is given its look, when
-- the settings are there; that gives how to colour the border.
---@type fun(r: number, g: number, b: number)?
local SetBorderColor

M.button = button
-- A right-click runs the module's own handler: a secure button calls a function field named
-- after an action type it does not know, outside the secure path.
button.foodlist = function()
    M:ToggleFoodList()
end

---Puts the button where the profile keeps it, or beside the pet frame (Kennel.PetFrame).
function M:PlaceButton()
    local at = self:Settings().position
    button:ClearAllPoints()
    if at then
        button:SetPoint(at[1], UIParent, at[2], at[3], at[4])
    else
        button:SetPoint("LEFT", Kennel.PetFrame(), "RIGHT", 4, 0)
    end
end

---Gives the button the first food and its look, and shows it while the pet is not happy; after
---combat when in it. Off, or on another class, it has no food and stays hidden.
function M:ApplyButton()
    Kennel:OutOfCombat("Feeding:button", function()
        local _, class = UnitClass("player")
        local active = self:IsEnabled() and class == "HUNTER"
        local first = active and self:Foods()[1]
        button:SetAttribute("type2", active and "foodlist" or nil)
        if first then
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", M.FeedMacro(first))
        else
            button:SetAttribute("type", nil)
            button:SetAttribute("macrotext", nil)
        end
        self:PlaceButton()
        local _, feedIcon = Kennel.SpellInfo(M.FEED_PET)
        icon:SetTexture(first and C_Item.GetItemIconByID(first.itemID) or feedIcon)
        local watching = self:IsEnabled() and class == "HUNTER" and UnitExists("pet")
        local happiness = watching and M.Happiness() or 3
        local mood = HAPPINESS[happiness]
        SetBorderColor = SetBorderColor or Kennel:StyleButton(button, { icon = icon, group = "Feeding" })
        SetBorderColor(mood.color[1], mood.color[2], mood.color[3])
        button:SetShown(happiness < 3)
    end)
end

---The tooltip: the pet's happiness, then every food in feeding order.
---@param self Button
local function OnEnter(self)
    local pet = UnitName("pet") or ""
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.FEEDING_TOOLTIP:format(pet))
    local happiness = HAPPINESS[M.Happiness() or 3]
    GameTooltip:AddLine(happiness.name, happiness.color[1], happiness.color[2], happiness.color[3])
    local foods = M:Foods()
    for _, food in ipairs(foods) do
        local text = L.FEEDING_FOOD:format(M.FoodName(food), food.count)
        GameTooltip:AddLine(food.wellFed and text .. L.FEEDING_WELL_FED or text, M.FoodColor(food))
    end
    if #foods == 0 then GameTooltip:AddLine(L.FEEDING_NO_FOOD:format(pet), 1, 1, 1) end
    GameTooltip:AddLine(L.FEEDING_CLICK, HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

---Shift-drag moves the button, outside combat (a secure button cannot move in it).
---@param self Button
local function OnDragStart(self)
    if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end
end

---Dropped: keeps the place in the profile.
---@param self Button
local function OnDragStop(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    M:Settings().position = { point, relativePoint, x, y }
end

button:SetScript("OnEnter", OnEnter)
button:SetScript("OnLeave", OnLeave)
button:SetScript("OnDragStart", OnDragStart)
button:SetScript("OnDragStop", OnDragStop)
