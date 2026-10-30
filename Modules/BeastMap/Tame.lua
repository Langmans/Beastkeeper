local _, ns = ...

-- The tame key: a secure button behind its own key binding that targets the beast Beast Map
-- pointed at last (the rare alarm's, or the one whose pin was clicked) and puts a skull on it;
-- with Shift it casts Tame Beast instead. Only a secure button may target, so its macro text holds
-- the beast's name, rewritten outside combat. For an action bar: a macro with
-- /click BeastkeeperTameButton. During a hunt the same button shows on screen too, with Tame
-- Beast's icon (the profile's tameButton switch); Shift-drag moves it, its place kept per profile.
-- Showing, hiding and moving it wait for combat to end, like the macro text.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as AddonBeastMap]]

local TAME_BEAST = Addon.TAME_BEAST
local SKULL = Addon.raidMarks.skull

local SIZE = 36
local HINT_COLOR = { 0.5, 0.5, 0.5 }

local button = CreateFrame("Button", Addon.Global("TameButton"), UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown")
button:SetSize(SIZE, SIZE)
button:SetFrameStrata("MEDIUM")
button:SetMovable(true)
button:RegisterForDrag("LeftButton")
button:Hide()
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
button.icon = icon
button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
-- The button skin's look, given the first time the button shows.
local styled = false

---Shows the button during a hunt with its switch on, in its place; hides it otherwise. Outside
---combat only (from ApplyTameButton).
local function ShowOnScreen()
    local settings = M:Settings()
    local shown = M:IsEnabled() and settings.tameButton and M:Hunt() ~= nil and M.tameTarget ~= nil
    if shown then
        local at = settings.tamePosition
        button:ClearAllPoints()
        if at then
            button:SetPoint(at[1], UIParent, at[2], at[3], at[4])
        else
            button:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        end
        local _, spellIcon = Addon.SpellInfo(TAME_BEAST)
        icon:SetTexture(spellIcon)
        if not styled then
            styled = true
            Addon:StyleButton(button, { icon = icon, group = "BeastMap" })
        end
    end
    button:SetShown(shown == true)
end

---The button's lines for a beast: Shift tames, else target it by name and mark it.
---@param name string
---@return string
local function MacroText(name)
    local tame = Addon.SpellInfo(TAME_BEAST) or "Tame Beast"
    return ("/cast [mod:shift] %s\n/stopmacro [mod:shift]\n/targetexact %s\n/tm %d"):format(tame, name, SKULL)
end

---Gives the button its lines for the beast to tame now, or none while there is none or the module
---is off; after combat when in it.
function M:ApplyTameButton()
    Addon:OutOfCombat("BeastMap:tame", function()
        local name = self:IsEnabled() and self.tameTarget
        button:SetAttribute("useOnKeyDown", false)
        button:SetAttribute("type", name and "macro" or nil)
        button:SetAttribute("macrotext", name and MacroText(name) or nil)
        ShowOnScreen()
    end)
end

---Makes `name` the beast the tame key goes for, and says so when it changes.
---@param name string the beast's name as the client words it (else the data's)
function M:SetTameTarget(name)
    if not self:IsEnabled() or name == self.tameTarget then return end
    self.tameTarget = name
    self:Print(L.BEASTMAP_TAME_SET:format(name))
    self:ApplyTameButton()
end

---BEASTKEEPER_RARE_SEEN, the rare alarm's message: that beast is the one to tame.
---@param _ string the message
---@param event AddonRareSeenEvent
function M:OnRareSeen(_, event)
    self:SetTameTarget(event.name)
end

-- A press without a beast does nothing secure; this says how to get one.
---@param _ Button
---@param _mouse string
---@param down boolean
button:HookScript("OnClick", function(_, _mouse, down)
    if not down and not M.tameTarget then M:Print(L.BEASTMAP_TAME_NONE) end
end)

---The tooltip: the beast, and what a click does.
---@param self Button
local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(M.tameTarget or "?")
    GameTooltip:AddLine(L.BEASTMAP_TAME_HINT, HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3], true)
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

---Shift-drag moves the button, outside combat.
---@param self Button
local function OnDragStart(self)
    if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end
end

---Dropped: keeps the place in the profile.
---@param self Button
local function OnDragStop(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    M:Settings().tamePosition = { point, relativePoint, x, y }
end

button:SetScript("OnEnter", OnEnter)
button:SetScript("OnLeave", OnLeave)
button:SetScript("OnDragStart", OnDragStart)
button:SetScript("OnDragStop", OnDragStop)

_G["BINDING_NAME_CLICK " .. Addon.Global("TameButton") .. ":LeftButton"] = L.BEASTMAP_TAME_BINDING
