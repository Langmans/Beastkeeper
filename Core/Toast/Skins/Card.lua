local _, ns = ...

-- The card skin: a card near the top of the screen. A dark panel with a 1-pixel edge and a
-- coloured bar down its left side, a square icon, and to its right a title in that colour, a line
-- of text and a grey hint. A thin bar along the bottom runs down while the toast stays. It slides
-- in from a little higher and fades out.

---@type Kennel
local Kennel = ns

local WIDTH = 340
local ICON_SIZE = 40
local PAD = 12
local ACCENT_WIDTH = 4
local SLIDE = 12
local EDGE = { 0.28, 0.3, 0.33, 1 }
local PANEL = { 0.06, 0.07, 0.08, 0.94 }
local HINT_COLOR = { 0.62, 0.64, 0.67 }

-- Hide, IsMouseOver and Frame come with NewToastSkin; Show and Update follow.
local Card = Kennel:NewToastSkin(Kennel.L.TOAST_SKIN_CARD) --[[@as KennelCardSkin]]

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

---Makes the frame, the first time it shows.
---@return KennelCardFrame
local function Build()
    local frame = Kennel:NewToastFrame("KennelToastCard") --[[@as KennelCardFrame]]
    frame:SetSize(WIDTH, ICON_SIZE + 2 * PAD)

    -- The edge is the frame filled in its colour, with the panel one pixel inside it.
    Solid(frame, "BACKGROUND", EDGE):SetAllPoints(frame)
    local panel = Solid(frame, "BORDER", PANEL)
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

    frame.Accent = Solid(frame, "ARTWORK", Kennel.TOAST_ACCENT)
    frame.Accent:SetPoint("TOPLEFT", panel, "TOPLEFT")
    frame.Accent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")
    frame.Accent:SetWidth(ACCENT_WIDTH)

    local iconEdge = Solid(frame, "ARTWORK", { 0, 0, 0, 1 })
    iconEdge:SetSize(ICON_SIZE + 2, ICON_SIZE + 2)
    iconEdge:SetPoint("TOPLEFT", panel, "TOPLEFT", ACCENT_WIDTH + PAD - 1, -PAD + 1)
    frame.Icon = frame:CreateTexture(nil, "OVERLAY")
    frame.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    frame.Icon:SetPoint("CENTER", iconEdge, "CENTER")
    frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local textWidth = WIDTH - ACCENT_WIDTH - ICON_SIZE - 3 * PAD
    frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Title:SetPoint("TOPLEFT", iconEdge, "TOPRIGHT", PAD, -1)
    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Text:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -4)
    frame.Hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Hint:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 0, -4)
    frame.Hint:SetTextColor(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])
    for _, text in ipairs({ frame.Title, frame.Text, frame.Hint }) do
        text:SetWidth(textWidth)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(true)
    end

    frame.Timer = Solid(frame, "OVERLAY", Kennel.TOAST_ACCENT)
    frame.Timer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", ACCENT_WIDTH, 0)
    frame.Timer:SetHeight(2)
    return frame
end

---@param info KennelToastInfo
---@param settings KennelToastSettings
function Card:Show(info, settings)
    self.frame = self.frame or Build()
    local frame = self.frame
    local accent = info.accent or Kennel.TOAST_ACCENT
    frame.Accent:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Timer:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Title:SetTextColor(accent[1], accent[2], accent[3])
    frame.Icon:SetTexture(info.icon or Kennel.TOAST_ICON)
    frame.Title:SetText(info.title)
    frame.Text:SetText(info.text or "")
    frame.Hint:SetText(info.hint or "")
    -- As high as the text needs, and at least as high as the icon.
    local text = frame.Title:GetStringHeight() + frame.Text:GetStringHeight() + frame.Hint:GetStringHeight() + 8
    frame:SetHeight(math.max(ICON_SIZE, text) + 2 * PAD)
    frame:SetScale(settings.scale)
    frame:Show()
end

---@param intro number
---@param fade number
---@param left number
function Card:Update(intro, fade, left)
    local frame = self.frame --[[@as KennelCardFrame]]
    local slide = 1 - (1 - intro) * (1 - intro)
    Kennel:PlaceToast(frame, "TOP", 0, -120, SLIDE * (1 - slide))
    frame:SetAlpha(slide * (1 - fade))
    frame.Timer:SetWidth(math.max(1, (WIDTH - ACCENT_WIDTH) * left))
end

Kennel:RegisterToastSkin("card", Card)
