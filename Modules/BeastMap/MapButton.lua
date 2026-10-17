local _, ns = ...

-- A round button in the world map's top-right corner that shows or hides Beast Map's pins, on the
-- world map and the minimap; HandyNotes has its own switch only deep in its settings. WoW: Forever
-- moved Blizzard's map pin button to the top-left, so that corner is free. The look is that of
-- Blizzard's own map buttons (WorldMapTrackingPinButtonTemplate). The button is a plain child of
-- WorldMapFrame: nothing is added to Blizzard's own tables, which keeps the map's code untainted.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("BeastMap") --[[@as KennelBeastMap]]

local ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"

---@type Button?
local button

---The tooltip: what the pins are now, and what a click does.
---@param self Button
local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.BEASTMAP_TITLE)
    GameTooltip:AddLine(M:Settings().pins and L.BEASTMAP_PINS_SHOWN or L.BEASTMAP_PINS_HIDDEN, 1, 1, 1)
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

---Switches the pins, and says so in the tooltip the mouse is still over.
---@param self Button
local function OnClick(self)
    local settings = M:Settings()
    settings.pins = not settings.pins
    M:Refresh()
    OnEnter(self)
end

---A texture of the button, at its size and place from the top-left.
---@param layer DrawLayer
---@param file string
---@param size number
---@param x number
---@param y number
---@return Texture
local function Layer(layer, file, size, x, y)
    local texture = (button --[[@as Button]]):CreateTexture(nil, layer)
    texture:SetTexture(file)
    texture:SetSize(size, size)
    texture:SetPoint("TOPLEFT", x, y)
    return texture
end

---Makes the button, once; called when the module joins HandyNotes.
function M:CreateMapButton()
    button = CreateFrame("Button", nil, WorldMapFrame)
    button:SetSize(32, 32)
    button:SetFrameStrata("HIGH")
    button:SetPoint("TOPRIGHT", WorldMapFrame:GetCanvasContainer(), "TOPRIGHT", -4, -2)
    Layer("BACKGROUND", "Interface\\Minimap\\UI-Minimap-Background", 25, 3, -4)
    button.icon = Layer("ARTWORK", ICON, 20, 7, -6)
    Layer("OVERLAY", "Interface\\Minimap\\MiniMap-TrackingBorder", 54, 0, 0)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnClick", OnClick)
    self:UpdateMapButton()
end

---Shown while the module is on and the setting asks for it; the icon greyed while the pins are off.
function M:UpdateMapButton()
    if not button then return end
    local settings = self:Settings()
    button:SetShown(self:IsEnabled() and settings.mapButton)
    button.icon:SetDesaturated(not settings.pins)
end
