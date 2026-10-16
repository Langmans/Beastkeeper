local _, ns = ...

-- The card and the splash in EllesmereUI's look: its global font, outline and shadow, its 1-pixel
-- border on a dark panel, and its theme colour as the accent. Registered only when EllesmereUI is
-- loaded; it is in Kennel's OptionalDeps, so it loads first.

local EUI = EllesmereUI
if type(EUI) ~= "table" then return end

---@type Kennel
local Kennel = ns

---EllesmereUI's theme colour, for a toast that brings no accent of its own.
---@return number[]
local function Accent()
    local green = EUI.ELLESMERE_GREEN
    return green and { green.r, green.g, green.b } or Kennel.TOAST_ACCENT
end

---Its border, drawn by EllesmereUI so it stays pixel-perfect at any UI scale.
---@param frame Frame
local function Border(frame)
    if EUI.MakeBorder then EUI.MakeBorder(frame, 0, 0, 0, 1) end
end

---Its global font (no module key), outline and shadow.
---@param text FontString
---@param size number
local function Font(text, size)
    text:SetFont(EUI.GetFontPath(), size, EUI.GetFontOutlineFlag())
    if EUI.PrimeFontShadow then EUI.PrimeFontShadow(text, EUI.GetFontUseShadow()) end
end

---The look, for a frame of this name.
---@param frameName string
---@return KennelSkinStyle
local function Style(frameName)
    return { frameName = frameName, panel = { 0.06, 0.06, 0.08, 0.85 }, Border = Border, accent = Accent, Font = Font }
end

Kennel:RegisterToastSkin("ellesmere", Kennel:NewCardSkin("EllesmereUI", Style("KennelToastEllesmere")))
Kennel:RegisterToastSkin(
    "ellesmeresplash",
    Kennel:NewSplashSkin("EllesmereUI (splash)", Style("KennelToastEllesmereSplash"))
)
