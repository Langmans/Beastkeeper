local _, ns = ...

-- What every skin's frame does the same way, so a toast behaves alike whatever draws it: it sits
-- on top of the UI and on screen, moves where it is dragged (the spot is saved in the profile,
-- shared by all skins, until it is reset) and closes on a right-click.

---@type Kennel
local Kennel = ns

---@param frame Frame
local function OnDragStart(frame)
    frame:StartMoving()
end

---@param frame Frame
local function OnDragStop(frame)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then Kennel:ToastSettings().pos = { point, relativePoint, x, y } end
end

---@param _ Frame
---@param button string
local function OnMouseUp(_, button)
    if button == "RightButton" then Kennel:HideToast() end
end

---A frame for a skin: on top of the UI, kept on screen, draggable, closed by a right-click.
---Hidden until the skin shows it.
---@param name string? a global name, for /fstack and other addons
---@return Frame
function Kennel:NewToastFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", OnDragStart)
    frame:SetScript("OnDragStop", OnDragStop)
    frame:SetScript("OnMouseUp", OnMouseUp)
    frame:Hide()
    return frame
end

---Places a skin's frame where it was dragged to, or at the skin's own standard spot; `lift`
---raises it that many pixels (for a slide in).
---@param frame Frame
---@param point string the standard spot: an anchor point on UIParent
---@param x number
---@param y number
---@param lift number?
function Kennel:PlaceToast(frame, point, x, y, lift)
    lift = lift or 0
    frame:ClearAllPoints()
    local pos = self:ToastSettings().pos
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4] + lift)
    else
        frame:SetPoint(point, UIParent, point, x, y + lift)
    end
end

local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

---A round badge for a unit's portrait (KennelToastInfo.portrait) on the lower right of `icon`, in
---a ring; it becomes frame.Portrait and frame.PortraitRing, shown by ShowToastPortrait.
---@param frame Frame the skin's frame
---@param icon Region what the badge sits on
---@param size number the portrait's size; the ring is 4 pixels wider
function Kennel:AddToastPortrait(frame, icon, size)
    local ring = frame:CreateTexture(nil, "OVERLAY", nil, 6)
    ring:SetSize(size + 4, size + 4)
    ring:SetPoint("CENTER", icon, "BOTTOMRIGHT", -2, 2)
    local portrait = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    portrait:SetSize(size, size)
    portrait:SetPoint("CENTER", ring, "CENTER")
    for _, texture in ipairs({ ring, portrait }) do
        local mask = frame:CreateMaskTexture()
        mask:SetAllPoints(texture)
        mask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        texture:AddMaskTexture(mask)
    end
    frame.PortraitRing, frame.Portrait = ring, portrait
end

---Shows `unit`'s portrait on the badge, the ring in `accent`, while that unit exists; hides the
---badge otherwise.
---@param frame KennelPortraitFrame
---@param unit string?
---@param accent number[]
function Kennel:ShowToastPortrait(frame, unit, accent)
    local shown = unit ~= nil and UnitExists(unit)
    if shown then
        SetPortraitTexture(frame.Portrait, unit --[[@as string]])
        frame.PortraitRing:SetColorTexture(accent[1], accent[2], accent[3], 1)
    end
    frame.Portrait:SetShown(shown)
    frame.PortraitRing:SetShown(shown)
end

---Puts the toast back in its standard spot.
function Kennel:ResetToastPosition()
    self:ToastSettings().pos = nil
end

-- What a skin that draws in one frame, kept in self.frame, does like every other.
local SkinBase = {}

---@param self KennelFrameSkin
function SkinBase.Hide(self)
    (self.frame --[[@as Frame]]):Hide()
end

---@param self KennelFrameSkin
---@return boolean
function SkinBase.IsMouseOver(self)
    return (self.frame --[[@as Frame]]):IsMouseOver()
end

---@param self KennelFrameSkin
---@return Frame?
function SkinBase.Frame(self)
    return self.frame
end

---A skin drawing in self.frame, with Hide, IsMouseOver and Frame; it adds Show and Update.
---@param name string shown in the look choice; localized
---@return KennelFrameSkin
function Kennel:NewToastSkin(name)
    return setmetatable({ name = name }, { __index = SkinBase }) --[[@as KennelFrameSkin]]
end
