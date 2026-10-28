local _, ns = ...

-- The splash: a toast in the middle of the screen, for things worth a moment. The module's name
-- over a thin line, the icon in a diamond that pops in (a unit's portrait as a round badge on its
-- lower right, when the toast brings one), the title, text and a grey hint centred,
-- and a short timer bar; plain text, no glow. Beastkeeper's own has a black panel whose edges fade
-- out; NewSplashSkin makes one in any style (AddonSkinStyle), such as EllesmereUI's.

---@type Addon
local Addon = ns

local WIDTH, HEIGHT = 380, 220
local DIAMOND = 46
local ICON_SIZE = 30
local PORTRAIT_SIZE = 22
local BG_OPACITY = 0.78
local BG_LAYERS = 20
local BG_FADE_FRACTION = 0.14 -- fade band per side, as a fraction of that side
local TIMER_WIDTH = 160
local SOURCE_SIZE, TITLE_SIZE, TEXT_SIZE, HINT_SIZE = 10, 16, 12, 11
local TITLE_COLOR = { 1, 0.92, 0.78 }
local HINT_COLOR = { 0.72, 0.74, 0.77 }

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

---A centred line of text, in the style's font when it has one.
---@param frame Frame
---@param style AddonSkinStyle
---@param template string the game's font, without a style font
---@param size number the size in the style's font
---@return FontString
local function Line(frame, style, template, size)
    local text = frame:CreateFontString(nil, "OVERLAY", template)
    if style.Font then style.Font(text, size) end
    text:SetWidth(WIDTH - 60)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(true)
    return text
end

---Makes the frame, the first time it shows: the style's panel and border, else the fading one.
---@param style AddonSkinStyle
---@return AddonSplashFrame
local function Build(style)
    local frame = Addon:NewToastFrame(style.frameName) --[[@as AddonSplashFrame]]
    frame:SetSize(WIDTH, HEIGHT)
    if style.panel then
        local panel = frame:CreateTexture(nil, "BACKGROUND")
        panel:SetAllPoints(frame)
        panel:SetColorTexture(style.panel[1], style.panel[2], style.panel[3], style.panel[4])
    else
        Background(frame)
    end
    if style.Border then style.Border(frame) end

    frame.Source = Line(frame, style, "GameFontNormalSmall", SOURCE_SIZE)
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
    Addon:CropIcon(frame.Icon)
    Addon:AddToastPortrait(frame, frame.Diamond, PORTRAIT_SIZE)

    frame.Title = Line(frame, style, "GameFontNormalLarge", TITLE_SIZE)
    frame.Title:SetPoint("TOP", frame.Diamond, "BOTTOM", 0, -16)
    frame.Title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    frame.Text = Line(frame, style, "GameFontHighlight", TEXT_SIZE)
    frame.Text:SetPoint("TOP", frame.Title, "BOTTOM", 0, -6)
    frame.Hint = Line(frame, style, "GameFontHighlightSmall", HINT_SIZE)
    frame.Hint:SetPoint("TOP", frame.Text, "BOTTOM", 0, -6)
    frame.Hint:SetTextColor(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])

    frame.Timer = frame:CreateTexture(nil, "OVERLAY")
    frame.Timer:SetHeight(2)
    frame.Timer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 22)
    return frame
end

---@param self AddonSplashSkin
---@param info AddonToastInfo
---@param settings AddonToastSettings
local function Show(self, info, settings)
    self.frame = self.frame or Build(self.style)
    local frame = self.frame
    local accent = info.accent or self.style.accent()
    frame.Source:SetTextColor(accent[1], accent[2], accent[3])
    frame.Divider:SetColorTexture(accent[1], accent[2], accent[3], 0.6)
    frame.Diamond:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Timer:SetColorTexture(accent[1], accent[2], accent[3], 1)
    frame.Source:SetText(info.source or "")
    frame.Icon:SetTexture(info.icon or Addon.TOAST_ICON)
    Addon:ShowToastPortrait(frame, info.portrait, accent)
    frame.Title:SetText(info.title)
    frame.Text:SetText(info.text or "")
    frame.Hint:SetText(info.hint or "")
    frame:SetScale(settings.scale)
    Addon:PlaceToast(frame, "CENTER", 0, 160)
    frame:Show()
end

---@param self AddonSplashSkin
---@param intro number
---@param fade number
---@param left number
local function Update(self, intro, fade, left)
    local frame = self.frame --[[@as AddonSplashFrame]]
    frame:SetAlpha(intro * (1 - fade))
    -- The diamond grows from 60% and overshoots a little; the icon keeps inside it.
    local size = DIAMOND * (0.6 + 0.4 * EaseOutBack(intro))
    frame.Diamond:SetSize(size, size)
    frame.Inner:SetSize(size - 4, size - 4)
    frame.Icon:SetSize(size * ICON_SIZE / DIAMOND, size * ICON_SIZE / DIAMOND)
    frame.Timer:SetWidth(math.max(1, TIMER_WIDTH * left))
end

---A splash skin in `style`; register it with RegisterToastSkin.
---@param name string shown in the look choice
---@param style AddonSkinStyle
---@return AddonSplashSkin
function Addon:NewSplashSkin(name, style)
    local skin = self:NewToastSkin(name) --[[@as AddonSplashSkin]]
    skin.style, skin.Show, skin.Update = style, Show, Update
    return skin
end

Addon:RegisterToastSkin(
    "splash",
    Addon:NewSplashSkin(
        Addon.L.TOAST_SKIN_SPLASH,
        { frameName = Addon.Global("ToastSplash"), accent = Addon.DefaultToastAccent }
    )
)
