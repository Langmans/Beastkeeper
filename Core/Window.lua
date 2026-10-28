local _, ns = ...

-- Beastkeeper's window: a frame of its own with a tab per part, which modules add with
-- Beastkeeper:RegisterWindowTab. A tab shows while its module is on; without any tab the window is not
-- there and opening it opens the options. Made the first time it opens, in the look of the chosen
-- holder skin (Core\Buttons.lua). Escape closes it; it moves by dragging and keeps its place per
-- profile. /beastkeeper, the broker and a key binding (BeastkeeperWindowButton) open it.

---@type Addon
local Addon = ns
local L = Addon.L

local WIDTH, HEIGHT, PAD, TAB_HEIGHT, TAB_WIDTH = 680, 460, 12, 24, 96
local CURRENT, OTHER = { 1, 1, 1 }, { 0.6, 0.6, 0.6 }
-- The underline of the tab that shows, without an accent from the look: the game's gold.
local GOLD = { 1, 0.82, 0 }
-- A panel's width, for the tabs that lay out by it (a new frame may not have its size yet).
Addon.WINDOW_PANEL_WIDTH = WIDTH - 2 * PAD

-- The registered tabs, in their order.
---@type BeastkeeperWindowTab[]
local registered = {}

---@param a BeastkeeperWindowTab
---@param b BeastkeeperWindowTab
---@return boolean
local function ByOrder(a, b)
    return a.order < b.order
end

---Adds a tab to the window. Its Create builds the panel the first time the tab shows; Refresh fills
---it each time it shows, and on RefreshWindow.
---@param tab BeastkeeperWindowTab
function Addon:RegisterWindowTab(tab)
    registered[#registered + 1] = tab
    table.sort(registered, ByOrder)
end

---Whether a tab shows now: its module, if it names one, is on.
---@param tab BeastkeeperWindowTab
---@return boolean
local function Showing(tab)
    if not tab.module then return true end
    local module = Addon:GetModule(tab.module, true) --[[@as BeastkeeperModule?]]
    return module ~= nil and module:IsEnabled() == true
end

---The tab with `id`, if registered.
---@param id string
---@return BeastkeeperWindowTab?
local function Find(id)
    for _, tab in ipairs(registered) do
        if tab.id == id then return tab end
    end
end

---The tab with `id` when there is one and it shows.
---@param id string?
---@return BeastkeeperWindowTab?
local function Shown(id)
    local tab = id and Find(id)
    if tab and Showing(tab) then return tab end
end

---The tab to show: `id` when it shows, else the current one, else the first that shows.
---@param id string?
---@return BeastkeeperWindowTab?
local function Pick(id)
    local tab = Shown(id) or Shown(Addon.window and Addon.window.current)
    if tab then return tab end
    for _, other in ipairs(registered) do
        if Showing(other) then return other end
    end
end

---The window's saved settings.
---@return BeastkeeperWindowSettings
local function Settings()
    return Addon.db.profile.window --[[@as BeastkeeperWindowSettings]]
end

---Keeps the window's place in the profile.
---@param frame Frame
local function OnDragStop(frame)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    Settings().pos = { point = point, relativePoint = relativePoint, x = x, y = y }
end

---@param frame Frame
local function OnDragStart(frame)
    frame:StartMoving()
end

---Builds the window: frame, title, close button, the place it was left.
---@return BeastkeeperWindow
local function Build()
    local frame = CreateFrame("Frame", Addon.Global("Window"), UIParent, "BackdropTemplate") --[[@as BeastkeeperWindow]]
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", OnDragStart)
    frame:SetScript("OnDragStop", OnDragStop)
    local pos = Settings().pos
    if pos then
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        frame:SetPoint("CENTER")
    end
    table.insert(UISpecialFrames, Addon.Global("Window"))
    frame.skin = Addon:StyleButtonHolder(frame)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", PAD, -PAD)
    frame.title:SetText(L.WINDOW_TITLE)
    frame.skin.Font(frame.title, 14)
    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -2, -2)
    if frame.skin.Close then frame.skin.Close(frame.close) end
    frame.divider = frame:CreateTexture(nil, "ARTWORK")
    frame.divider:SetHeight(1)
    frame.divider:SetPoint("TOPLEFT", PAD, -PAD - TAB_HEIGHT - 2)
    frame.divider:SetPoint("TOPRIGHT", -PAD, -PAD - TAB_HEIGHT - 2)
    frame.divider:SetColorTexture(1, 1, 1, 0.15)
    frame.tabs, frame.panels = {}, {}
    return frame
end

---The look's accent colour, else the game's gold.
---@param skin BeastkeeperButtonHolderSkin
---@return number[]
local function Accent(skin)
    return skin.Accent and skin.Accent() or GOLD
end

---The button of a tab, made the first time.
---@param window BeastkeeperWindow
---@param tab BeastkeeperWindowTab
---@return BeastkeeperWindowTabButton
local function TabButton(window, tab)
    local button = window.tabs[tab.id]
    if button then return button end
    button = CreateFrame("Button", nil, window) --[[@as BeastkeeperWindowTabButton]]
    button:SetSize(TAB_WIDTH, TAB_HEIGHT)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("CENTER")
    button.label:SetText(tab.title)
    window.skin.Font(button.label, 12)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local accent = Accent(window.skin)
    button.selected = button:CreateTexture(nil, "ARTWORK")
    button.selected:SetHeight(2)
    button.selected:SetPoint("BOTTOMLEFT", 8, -2)
    button.selected:SetPoint("BOTTOMRIGHT", -8, -2)
    button.selected:SetColorTexture(accent[1], accent[2], accent[3], 1)
    button:SetScript("OnClick", function()
        Addon:ShowWindowTab(tab.id)
    end)
    window.tabs[tab.id] = button
    return button
end

---Lays out the tab buttons of the tabs that show, top right; hides the others.
---@param window BeastkeeperWindow
local function LayOutTabs(window)
    local x = -40
    for index = #registered, 1, -1 do
        local tab = registered[index]
        local button = TabButton(window, tab)
        button:SetShown(Showing(tab))
        if Showing(tab) then
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", x, -PAD + 4)
            x = x - TAB_WIDTH - 4
        end
    end
end

---Shows the tab with `id` (it must show), making its panel the first time, and fills it.
---@param id string
function Addon:ShowWindowTab(id)
    local window = self.window --[[@as BeastkeeperWindow]]
    local tab = Find(id) --[[@as BeastkeeperWindowTab]]
    window.current = id
    for other, panel in pairs(window.panels) do
        panel:SetShown(other == id)
    end
    for other, button in pairs(window.tabs) do
        local colour = other == id and CURRENT or OTHER
        button.label:SetTextColor(colour[1], colour[2], colour[3])
        button.selected:SetShown(other == id)
    end
    local panel = window.panels[id]
    if not panel then
        panel = CreateFrame("Frame", nil, window)
        panel:SetPoint("TOPLEFT", PAD, -PAD - TAB_HEIGHT - 12)
        panel:SetPoint("BOTTOMRIGHT", -PAD, PAD)
        window.panels[id] = panel
        tab.Create(panel, window.skin)
    end
    panel:Show()
    self:Time("window: " .. id, tab.Refresh, panel)
end

---Opens the window on tab `id` (or the one it was on, or the first); the options when no tab shows.
---@param id string?
function Addon:OpenWindow(id)
    local tab = Pick(id)
    if not tab then
        self:OpenOptions()
        return
    end
    self.window = self.window or Build()
    LayOutTabs(self.window)
    self.window:Show()
    self:ShowWindowTab(tab.id)
end

---Closes the window when it is open, else opens it.
---@param id string?
function Addon:ToggleWindow(id)
    if self.window and self.window:IsShown() then
        self.window:Hide()
    else
        self:OpenWindow(id)
    end
end

---Fills the tab `id` again when it is the one showing; for a module whose data changed.
---@param id string
function Addon:RefreshWindow(id)
    local window = self.window
    if not window or not window:IsShown() or window.current ~= id then return end
    local tab = Find(id) --[[@as BeastkeeperWindowTab]]
    self:Time("window: " .. id, tab.Refresh, window.panels[id])
end

-- The key binding's button (Bindings.xml); a macro can /click it too.
local button = CreateFrame("Button", Addon.Global("WindowButton"), UIParent)
button:SetScript("OnClick", function()
    Addon:ToggleWindow()
end)
_G["BINDING_NAME_CLICK " .. Addon.Global("WindowButton") .. ":LeftButton"] = L.WINDOW_BINDING
