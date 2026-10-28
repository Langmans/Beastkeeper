local _, ns = ...

-- The card, the splash and Beastkeeper's buttons in EllesmereUI's look: its global font, outline and
-- shadow, its 1-pixel border on a dark panel, and its theme colour as the accent. Only when
-- EllesmereUI is loaded; it is in Beastkeeper's OptionalDeps, so it loads first, and this file loads
-- before the modules, so its button skins are there when they style their buttons.

local EUI = EllesmereUI
if type(EUI) ~= "table" then return end

---@type Addon
local Addon = ns

---EllesmereUI's theme colour, for a toast that brings no accent of its own.
---@return number[]
local function Accent()
    local green = EUI.ELLESMERE_GREEN
    return green and { green.r, green.g, green.b } or Addon.TOAST_ACCENT
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
---@return AddonSkinStyle
local function Style(frameName)
    return { frameName = frameName, panel = { 0.06, 0.06, 0.08, 0.85 }, Border = Border, accent = Accent, Font = Font }
end

local MakeBorder = EUI.MakeBorder

---Trims an icon's edges, as EllesmereUI's action buttons do.
---@param icon Texture
local function CropIcon(icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

---A button: its 1-pixel border, to colour, and a trimmed icon.
---@param button Button
---@param parts AddonButtonParts
---@return fun(r: number, g: number, b: number)
local function StyleButton(button, parts)
    Addon:CropIcon(parts.icon, CropIcon)
    local border = (
        MakeBorder --[[@as fun(parent: Frame, r: number, g: number, b: number, a: number): EllesmereUIBorder]]
    )(button, 0, 0, 0, 1)
    ---@param r number
    ---@param g number
    ---@param b number
    local function SetColor(r, g, b)
        border:SetColor(r, g, b, 1)
    end
    return SetColor
end

---A list of buttons: the dark panel with the border.
---@param frame Frame
local function StyleHolder(frame)
    local panel = frame:CreateTexture(nil, "BACKGROUND")
    panel:SetAllPoints()
    panel:SetColorTexture(0.06, 0.06, 0.08, 0.85)
    Border(frame)
end

-- Between ElvUI (20) and Beastkeeper's own (0): a player with both chose ElvUI's buttons on purpose.
if MakeBorder then
    Addon:RegisterButtonSkin("ellesmere", { name = "EllesmereUI", priority = 10, Style = StyleButton })
    Addon:RegisterButtonHolderSkin(
        "ellesmere",
        { name = "EllesmereUI", priority = 10, Style = StyleHolder, Font = Font, CropIcon = CropIcon }
    )
end

Addon:RegisterToastSkin("ellesmere", Addon:NewCardSkin("EllesmereUI", Style(Addon.Global("ToastEllesmere"))))
Addon:RegisterToastSkin(
    "ellesmeresplash",
    Addon:NewSplashSkin("EllesmereUI (splash)", Style(Addon.Global("ToastEllesmereSplash")))
)
