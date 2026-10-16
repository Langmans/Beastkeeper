local _, ns = ...

-- The splash skin: a toast in the middle of the screen, for things worth a moment. A black panel
-- whose edges fade out; at the top the name of the module it comes from, in the accent colour,
-- over a thin line; below it the icon in a diamond of that colour, which pops in; the title, the
-- text and a grey hint centred under it; and a short bar at the bottom that runs down while it
-- stays. Plain text, no glow.

---@type Kennel
local Kennel = ns

local WIDTH, HEIGHT = 380, 220
local DIAMOND = 46
local ICON_SIZE = 30
local BG_OPACITY = 0.78
local BG_LAYERS = 20
local BG_FADE_FRACTION = 0.14 -- fade band per side, as a fraction of that side
local TIMER_WIDTH = 160
local TITLE_COLOR = { 1, 0.92, 0.78 }
local HINT_COLOR = { 0.72, 0.74, 0.77 }

-- Hide, IsMouseOver and Frame come with NewToastSkin; Show and Update follow.
local Splash = Kennel:NewToastSkin(Kennel.L.TOAST_SKIN_SPLASH) --[[@as KennelSplashSkin]]

---@param t number from 0 to 1
---@return number
local function SmoothStep(t)
    return t * t * (3 - 2 * t)
end

---Overshoots a little before settling at 1: the diamond's pop.
---@param p number from 0 to 1
---@return number
local function EaseOutBack(p)
    local c = 1.70158
    return 1 + (c + 1) * (p - 1) ^ 3 + c * (p - 1) ^ 2
end

---Stacked black layers, each inset a little further, so the panel is solid in the middle and
---fades to nothing at the edges; each layer's alpha is chosen so the stack follows a smoothstep.
---@param frame Frame
local function Background(frame)
    local fadeX, fadeY = WIDTH * BG_FADE_FRACTION, HEIGHT * BG_FADE_FRACTION
    local previous = 0
    for k = 1, BG_LAYERS do
        local layer = frame:CreateTexture(nil, "BACKGROUND")
        local insetX, insetY = fadeX * (k - 1) / BG_LAYERS, fadeY * (k - 1) / BG_LAYERS
        layer:SetPoint("TOPLEFT", frame, "TOPLEFT", insetX, -insetY)
        layer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetX, insetY)
        local target = BG_OPACITY * SmoothStep(k / BG_LAYERS)
        layer:SetColorTexture(0, 0, 0, math.max(0, 1 - (1 - target) / (1 - previous)))
        previous = target
    end
end

---A centred line of text.
---@param frame Frame
---@param template string
---@return FontString
local function Line(frame, template)
    local text = frame:CreateFontString(nil, "OVERLAY", template)
    text:SetWidth(WIDTH - 60)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(true)
    return text
end

---Makes the frame, the first time it shows.
---@return KennelSplashFrame
local function Build()
    local frame = Kennel:NewToastFrame("KennelToastSplash") --[[@as KennelSplashFrame]]
    frame:SetSize(WIDTH, HEIGHT)
    Background(frame)

    frame.Source = Line(frame, "GameFontNormalSmall")
    frame.Source:SetPoint("TOP", frame, "TOP", 0, -22)
    frame.Divider = frame:CreateTexture(nil, "ARTWORK")
    frame.Divider:SetSize(TIMER_WIDTH, 1)
    frame.Divider:SetPoint("TOP", frame.Source, "BOTTOM", 0, -5)

    -- The diamond: a square of the accent colour turned 45 degrees, a dark one inside it, and the
    -- icon upright on top.
    frame.Diamond = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.Diamond:SetPoint("TOP", frame.Divider, "BOTTOM", 0, -14)
    frame.Diamond:SetRotation(math.pi / 4)
    frame.Inner = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    frame.Inner:SetPoint("CENTER", frame.Diamond, "CENTER")
    frame.Inner:SetColorTexture(0.05, 0.05, 0.06, 1)
    frame.Inner:SetRotation(math.pi / 4)
    frame.Icon = frame:CreateTexture(nil, "OVERLAY")
    frame.Icon:SetPoint("CENTER", frame.Diamond, "CENTER")
    frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.Title = Line(frame, "GameFontNormalLarge")
    frame.Title:SetPoint("TOP", frame.Diamond, "BOTTOM", 0, -16)
    frame.Title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    frame.Text = Line(frame, "GameFontHighlight")
    frame.Text:SetPoint("TOP", frame.Title, "BOTTOM", 0, -6)
    frame.Hint = Line(frame, "GameFontHighlightSmall")
    frame.Hint:SetPoint("TOP", frame.Text, "BOTTOM", 0, -6)
    frame.Hint:SetTextColor(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])

    frame.Timer = frame:CreateTexture(nil, "OVERLAY")
    frame.Timer:SetHeight(2)
    frame.Timer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 22)
    return frame
end

---@param info KennelToastInfo
---@param settings KennelToastSettings
function Splash:Show(info, settings)
    self.frame = self.frame or Build()
    local frame = self.frame
    local accent = info.accent or Kennel.TOAST_ACCENT
    frame.Source:SetTextColor(accent[1], accent[2], accent[3])
    frame.Divider:SetColorTexture(accent[1], accent[2], accent[3], 0.6)
    frame.Diamond:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Timer:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Source:SetText(info.source or "")
    frame.Icon:SetTexture(info.icon or Kennel.TOAST_ICON)
    frame.Title:SetText(info.title)
    frame.Text:SetText(info.text or "")
    frame.Hint:SetText(info.hint or "")
    frame:SetScale(settings.scale)
    Kennel:PlaceToast(frame, "CENTER", 0, 160)
    frame:Show()
end

---@param intro number
---@param fade number
---@param left number
function Splash:Update(intro, fade, left)
    local frame = self.frame --[[@as KennelSplashFrame]]
    frame:SetAlpha(intro * (1 - fade))
    -- The diamond grows from 60% and overshoots a little; the icon keeps inside it.
    local size = DIAMOND * (0.6 + 0.4 * EaseOutBack(intro))
    frame.Diamond:SetSize(size, size)
    frame.Inner:SetSize(size - 4, size - 4)
    frame.Icon:SetSize(size * ICON_SIZE / DIAMOND, size * ICON_SIZE / DIAMOND)
    frame.Timer:SetWidth(math.max(1, TIMER_WIDTH * left))
end

Kennel:RegisterToastSkin("splash", Splash)
