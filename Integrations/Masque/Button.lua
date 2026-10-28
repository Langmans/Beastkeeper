local _, ns = ...

-- Beastkeeper's buttons in the player's Masque skin: each module's buttons in a group of their own
-- under "Beastkeeper" in Masque's options. The border Masque draws is a texture Beastkeeper hands it, so it
-- can still be coloured (the feed button's happiness). Masque skins buttons only: lists keep
-- another holder skin. Only when Masque is loaded; it is in Beastkeeper's OptionalDeps.

local Masque = LibStub("Masque", true) --[[@as MasqueApi?]]
if not Masque then return end

---@type Addon
local Addon = ns

---@param button Button
---@param parts AddonButtonParts
---@return fun(r: number, g: number, b: number)
local function Style(button, parts)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    Masque:Group(Addon.NAME, parts.group):AddButton(button, { Icon = parts.icon, Border = border })
    ---@param r number
    ---@param g number
    ---@param b number
    local function Recolour(r, g, b)
        border:SetVertexColor(r, g, b)
    end
    return Recolour
end

-- Above every other: Masque is there only to skin buttons.
Addon:RegisterButtonSkin("masque", { name = "Masque", priority = 30, Style = Style })
