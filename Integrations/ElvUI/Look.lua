local _, ns = ...

-- Kennel's toasts, buttons and lists in ElvUI's look, through the methods ElvUI's Toolkit gives
-- every frame: SetTemplate for the backdrop and border, StyleButton for hover and press,
-- FontTemplate for text, SetTexCoords for its icon crop; its value colour as the toast's accent.
-- Only when ElvUI is loaded; it is in Kennel's OptionalDeps, so its Toolkit has run.

if type(ElvUI) ~= "table" then return end

---@type Kennel
local Kennel = ns
local E = (ElvUI --[[@as ElvUIEngine[] ]])[1]

-- ElvUI draws the panel with its backdrop (SetTemplate); the card's own panel stays clear.
local CLEAR = { 0, 0, 0, 0 }

---ElvUI's value colour (its "value color" setting), for a toast that brings no accent.
---@return number[]
local function Accent()
    local color = E.media and E.media.rgbvaluecolor
    return color and { color[1], color[2], color[3] } or Kennel.TOAST_ACCENT
end

---@param button Button
---@param parts KennelButtonParts
---@return fun(r: number, g: number, b: number)
local function StyleButton(button, parts)
    local elv = button --[[@as ElvUIFrame]]
    elv:SetTemplate("Default")
    elv:StyleButton()
    local icon = parts.icon --[[@as ElvUITexture]]
    icon:SetTexCoords()
    ---@param r number
    ---@param g number
    ---@param b number
    local function Recolour(r, g, b)
        elv:SetBackdropBorderColor(r, g, b)
    end
    return Recolour
end

---Eltruism's shadow around a panel, as Eltruism puts it around ElvUI's own: only with Eltruism
---loaded and its shadows on (its settings in ElvUI's profile), in its length and colour.
---@param frame ElvUIFrame
local function EltruismShadow(frame)
    local eltruism = ElvUI_EltreumUI
    local db = E.db and E.db.ElvUI_EltreumUI
    ---@type {enable: boolean, length: number}?
    local shadow = db and db.skins and db.skins.shadow
    if not eltruism or not shadow or not shadow.enable or frame.shadow then return end
    frame:CreateShadow(shadow.length)
    eltruism:ShadowColor(frame.shadow --[[@as Frame]])
end

---@param frame Frame
local function StyleHolder(frame)
    local elv = frame --[[@as ElvUIFrame]]
    elv:SetTemplate("Transparent")
    EltruismShadow(elv)
end

---ElvUI's font, outline and shadow, at `size`.
---@param text FontString
---@param size number
local function Font(text, size)
    (text --[[@as ElvUIFontString]]):FontTemplate(nil, size)
end

---@param icon Texture
local function CropIcon(icon)
    (icon --[[@as ElvUITexture]]):SetTexCoords()
end

---A close button as ElvUI's Skins module draws its own.
---@param button Button
local function Close(button)
    local skins = E:GetModule("Skins")
    if skins and skins.HandleCloseButton then skins:HandleCloseButton(button) end
end

---The look of a toast, for a frame of this name: ElvUI's transparent backdrop is its panel.
---@param frameName string
---@return KennelSkinStyle
local function ToastStyle(frameName)
    return { frameName = frameName, panel = CLEAR, Border = StyleHolder, accent = Accent, Font = Font }
end

Kennel:RegisterToastSkin("elvui", Kennel:NewCardSkin("ElvUI", ToastStyle("KennelToastElvUI")))
Kennel:RegisterToastSkin("elvuisplash", Kennel:NewSplashSkin("ElvUI (splash)", ToastStyle("KennelToastElvUISplash")))
Kennel:RegisterButtonSkin("elvui", { name = "ElvUI", priority = 20, Style = StyleButton })
Kennel:RegisterButtonHolderSkin("elvui", {
    name = "ElvUI",
    priority = 20,
    Style = StyleHolder,
    Font = Font,
    CropIcon = CropIcon,
    Accent = Accent,
    Close = Close,
})
