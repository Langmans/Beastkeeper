local _, ns = ...

-- A round button on the world map that shows or hides Beast Map's pins, on the world map and the
-- minimap; HandyNotes has its own switch only deep in its settings. Krowi_WorldMapButtons places
-- it: one row with Blizzard's map buttons and those of other addons that use the library
-- (MapNotes, RareScanner, Questie), top-right on the classic clients, a column top-left on WoW:
-- Forever; a hidden button leaves no gap. The look is that of Blizzard's own map buttons
-- (WorldMapTrackingPinButtonTemplate). Nothing is added to Blizzard's own tables, which keeps the
-- map's code untainted.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as AddonBeastMap]]

local ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"

---@type AddonMapButton?
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

---After every map change, before the library lays out the row again.
local function Refresh()
    M:UpdateMapButton()
end

---Makes the button, once; called when the module joins HandyNotes.
function M:CreateMapButton()
    button = LibStub("Krowi_WorldMapButtons-1.4"):Add(nil, "Button") --[[@as AddonMapButton]]
    button.Refresh = Refresh
    button:SetSize(32, 32)
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
---A change of shown closes or opens its place in the row.
function M:UpdateMapButton()
    if not button then return end
    local settings = self:Settings()
    local shown = self:IsEnabled() and settings.mapButton
    button.icon:SetDesaturated(not settings.pins)
    if shown == button:IsShown() then return end
    button:SetShown(shown)
    LibStub("Krowi_WorldMapButtons-1.4").SetPoints()
end
