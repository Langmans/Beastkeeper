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
