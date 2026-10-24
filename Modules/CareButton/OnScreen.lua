local _, ns = ...

-- The Care Button on screen: the secure button of Button.lua given a size, a place below the pet
-- frame and the look of the chosen button skin. Its icon is the spell a click casts now, its
-- border that spell's colour: Mend Pet green, Revive Pet red, Call Pet yellow. That is worked out
-- here from what the secure part knows too (the pet's state, the remembered death); the icon and
-- border are textures, which may change in combat. Showing, hiding and moving it may not: those
-- wait for combat to end. Shift-drag moves it; the place is kept per profile.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("CareButton") --[[@as KennelCareButton]]

local SIZE = 36
local HINT_COLOR = { 0.5, 0.5, 0.5 }
-- Per spell the button casts: its border colour.
---@type table<number, number[]>
local COLORS = { [M.MEND_PET] = { 0, 1, 0 }, [M.REVIVE_PET] = { 1, 0, 0 }, [M.CALL_PET] = { 1, 0.8, 0 } }

local button = M.button
button:SetSize(SIZE, SIZE)
button:SetFrameStrata("MEDIUM")
button:SetMovable(true)
button:RegisterForDrag("LeftButton")
button:Hide()
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
button.icon = icon
button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

-- How to colour the border, from the button skin; the first time the look is set.
---@type fun(r: number, g: number, b: number)?
local SetBorderColor

---The spell a click without modifiers casts now: Revive Pet for a dead pet (also one whose body
---is gone), Call Pet without a pet, else Mend Pet.
---@return number
function M:NextCast()
    if self:PetDead() or (UnitExists("pet") and UnitIsDead("pet")) then return M.REVIVE_PET end
    if not UnitExists("pet") then return M.CALL_PET end
    return M.MEND_PET
end

---Gives the button the icon and border of the spell it casts now.
function M:UpdateLook()
    local spell = self:NextCast()
    local _, spellIcon = Kennel.SpellInfo(spell)
    icon:SetTexture(spellIcon)
    SetBorderColor = SetBorderColor or Kennel:StyleButton(button, { icon = icon, group = "CareButton" })
    local color = COLORS[spell]
    SetBorderColor(color[1], color[2], color[3])
end

---Puts the button where the profile keeps it, or below the pet frame.
function M:PlaceButton()
    local at = self:Settings().position
    button:ClearAllPoints()
    if at then
        button:SetPoint(at[1], UIParent, at[2], at[3], at[4])
    else
        button:SetPoint("TOPLEFT", Kennel.PetFrame(), "BOTTOMLEFT", 0, -4)
    end
end

---Shows the button while the module is on for a hunter who knows Call Pet and its switch is on;
---outside combat only (from ApplyButton).
function M:ShowOnScreen()
    local _, class = UnitClass("player")
    local shown = self:IsEnabled()
        and class == "HUNTER"
        and self:Settings().visible
        and Kennel.KnowsSpell(Kennel.CALL_PET)
    if shown then
        self:PlaceButton()
        self:UpdateLook()
    end
    button:SetShown(shown)
end

---The tooltip: the spell a click casts now, and what Shift and Ctrl do.
---@param self Button
local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.CAREBUTTON_TITLE)
    GameTooltip:AddLine(M.SpellName(M:NextCast()), 1, 1, 1)
    local hint = L.CAREBUTTON_ONSCREEN_HINT:format(M.SpellName(M.REVIVE_PET), M.SpellName(M.CALL_PET))
    GameTooltip:AddLine(hint, HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3], true)
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
    M:Settings().position = { point, relativePoint, x, y }
end

button:SetScript("OnEnter", OnEnter)
button:SetScript("OnLeave", OnLeave)
button:SetScript("OnDragStart", OnDragStart)
button:SetScript("OnDragStop", OnDragStop)
