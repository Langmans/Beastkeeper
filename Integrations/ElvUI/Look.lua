local _, ns = ...

-- Kennel's buttons and their lists in ElvUI's look, through the methods ElvUI's Toolkit gives every
-- frame: SetTemplate for the backdrop and border, StyleButton for hover and press, FontTemplate
-- for text, SetTexCoords for its icon crop. Only when ElvUI is loaded; it is in Kennel's
-- OptionalDeps, so its Toolkit has run.

if type(ElvUI) ~= "table" then return end

---@type Kennel
local Kennel = ns

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

---@param frame Frame
local function StyleHolder(frame)
    (frame --[[@as ElvUIFrame]]):SetTemplate("Transparent")
end

---@param text FontString
local function Font(text)
    (text --[[@as ElvUIFontString]]):FontTemplate()
end

---@param icon Texture
local function CropIcon(icon)
    (icon --[[@as ElvUITexture]]):SetTexCoords()
end

Kennel:RegisterButtonSkin("elvui", { name = "ElvUI", priority = 20, Style = StyleButton })
Kennel:RegisterButtonHolderSkin(
    "elvui",
    { name = "ElvUI", priority = 20, Style = StyleHolder, Font = Font, CropIcon = CropIcon }
)
