local _, ns = ...

-- The card: a card near the top of the screen, a coloured bar down its left side, a square icon
-- (with a unit's portrait as a round badge, when the toast brings one), a title in that colour, a line of text, a grey hint and a timer bar along the bottom. It slides
-- in from a little higher. NewCardSkin makes one in any style (AddonSkinStyle), such as
-- EllesmereUI's (Integrations\EllesmereUI\).

---@type Addon
local Addon = ns

local WIDTH = 340
local ICON_SIZE = 40
local PORTRAIT_SIZE = 18
local PAD = 12
local ACCENT_WIDTH = 4
local SLIDE = 12
local TITLE_SIZE, TEXT_SIZE = 13, 11
local HINT_COLOR = { 0.62, 0.64, 0.67 }

---A texture of one colour on `parent`, in `layer`.
---@param parent Frame
---@param layer DrawLayer
---@param color number[]
---@return Texture
local function Solid(parent, layer, color)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return texture
end

---A line of text, in the style's font when it has one.
---@param frame Frame
---@param style AddonSkinStyle
---@param template string the game's font, without a style font
---@param size number the size in the style's font
---@return FontString
local function Line(frame, style, template, size)
    local text = frame:CreateFontString(nil, "OVERLAY", template)
    if style.Font then style.Font(text, size) end
    text:SetWidth(WIDTH - ACCENT_WIDTH - ICON_SIZE - 3 * PAD)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(true)
    return text
end

---Makes the frame, the first time it shows.
---@param style AddonSkinStyle
---@return AddonCardFrame
local function Build(style)
    local frame = Addon:NewToastFrame(style.frameName) --[[@as AddonCardFrame]]
    frame:SetSize(WIDTH, ICON_SIZE + 2 * PAD)

    -- The edge: the frame filled in its colour with the panel one pixel inside, or drawn by the style.
    if style.edge then Solid(frame, "BACKGROUND", style.edge):SetAllPoints(frame) end
    if style.Border then style.Border(frame) end
    -- A card always has a panel; only the splash can do without.
    local panel = Solid(frame, "BORDER", style.panel --[[@as number[] ]])
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

    frame.Accent = Solid(frame, "ARTWORK", Addon.TOAST_ACCENT)
    frame.Accent:SetPoint("TOPLEFT", panel, "TOPLEFT")
    frame.Accent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")
    frame.Accent:SetWidth(ACCENT_WIDTH)

    local iconEdge = Solid(frame, "ARTWORK", { 0, 0, 0, 1 })
    iconEdge:SetSize(ICON_SIZE + 2, ICON_SIZE + 2)
    iconEdge:SetPoint("TOPLEFT", panel, "TOPLEFT", ACCENT_WIDTH + PAD - 1, -PAD + 1)
    frame.Icon = frame:CreateTexture(nil, "OVERLAY")
    frame.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    frame.Icon:SetPoint("CENTER", iconEdge, "CENTER")
    Addon:CropIcon(frame.Icon)
    Addon:AddToastPortrait(frame, frame.Icon, PORTRAIT_SIZE)

    frame.Title = Line(frame, style, "GameFontNormal", TITLE_SIZE)
    frame.Title:SetPoint("TOPLEFT", iconEdge, "TOPRIGHT", PAD, -1)
    frame.Text = Line(frame, style, "GameFontHighlightSmall", TEXT_SIZE)
    frame.Text:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -4)
    frame.Hint = Line(frame, style, "GameFontHighlightSmall", TEXT_SIZE)
    frame.Hint:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 0, -4)
    frame.Hint:SetTextColor(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])

    frame.Timer = Solid(frame, "OVERLAY", Addon.TOAST_ACCENT)
    frame.Timer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", ACCENT_WIDTH, 0)
    frame.Timer:SetHeight(2)
    return frame
end

---@param self AddonCardSkin
---@param info AddonToastInfo
---@param settings AddonToastSettings
local function Show(self, info, settings)
    self.frame = self.frame or Build(self.style)
    local frame = self.frame
    local accent = info.accent or self.style.accent()
    frame.Accent:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Timer:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Title:SetTextColor(accent[1], accent[2], accent[3])
    frame.Icon:SetTexture(info.icon or Addon.TOAST_ICON)
    Addon:ShowToastPortrait(frame, info.portrait, accent)
    frame.Title:SetText(info.title)
    frame.Text:SetText(info.text or "")
    frame.Hint:SetText(info.hint or "")
    -- As high as the text needs, and at least as high as the icon.
    local text = frame.Title:GetStringHeight() + frame.Text:GetStringHeight() + frame.Hint:GetStringHeight() + 8
    frame:SetHeight(math.max(ICON_SIZE, text) + 2 * PAD)
    frame:SetScale(settings.scale)
    frame.placed = false
    frame:Show()
end

---@param self AddonCardSkin
---@param intro number
---@param fade number
---@param left number
local function Update(self, intro, fade, left)
    local frame = self.frame --[[@as AddonCardFrame]]
    local slide = 1 - (1 - intro) * (1 - intro)
    -- Placed while it slides in only, so the mouse can drag it once it is there.
    if intro < 1 or not frame.placed then
        Addon:PlaceToast(frame, "TOP", 0, -120, SLIDE * (1 - slide))
        frame.placed = intro >= 1
    end
    frame:SetAlpha(slide * (1 - fade))
    frame.Timer:SetWidth(math.max(1, (WIDTH - ACCENT_WIDTH) * left))
end

---A card skin in `style`; register it with RegisterToastSkin.
---@param name string shown in the look choice
---@param style AddonSkinStyle
---@return AddonCardSkin
function Addon:NewCardSkin(name, style)
    local skin = self:NewToastSkin(name) --[[@as AddonCardSkin]]
    skin.style, skin.Show, skin.Update = style, Show, Update
    return skin
end

Addon:RegisterToastSkin(
    "card",
    Addon:NewCardSkin(Addon.L.TOAST_SKIN_CARD, {
        frameName = Addon.Global("ToastCard"),
        panel = { 0.06, 0.07, 0.08, 0.94 },
        edge = { 0.28, 0.3, 0.33, 1 },
        accent = Addon.DefaultToastAccent,
    })
)
