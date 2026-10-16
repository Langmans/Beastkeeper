local _, ns = ...

-- The toast every module shows: a card near the top of the screen. A dark panel with a 1-pixel
-- edge and a coloured bar down its left side, a square icon, and to its right a title in that
-- colour, a line of text and a grey hint. A thin bar along the bottom runs down while the toast
-- stays, and stands still while the mouse is over it. It slides in from a little higher and fades
-- out at the end. Drag it to move it (the spot is saved in the profile), right-click to close it.
--
-- Each toast has a key, such as "AutocastCheck:growlOn". One key has at most one toast up or
-- waiting; toasts for different keys show one after the other. A module takes its toast away with
-- DropToast when what it was about is solved, and drops all of its own when it is switched off.
--
-- The frame is made on the first toast, so a session without one creates nothing.

---@type Kennel
local Kennel = ns

local WIDTH = 340
local ICON_SIZE = 40
local PAD = 12
local ACCENT_WIDTH = 4
local EDGE = { 0.28, 0.3, 0.33, 1 }
local PANEL = { 0.06, 0.07, 0.08, 0.94 }
local HINT_COLOR = { 0.62, 0.64, 0.67 }
-- The colour of a toast that brings none: a warm amber.
Kennel.TOAST_ACCENT = { 1, 0.62, 0.18 }
local FALLBACK_ICON = 134400 -- INV_Misc_QuestionMark

-- Timings, in seconds, and how far it slides.
local SLIDE_IN, SLIDE_DISTANCE = 0.2, 12
local FADE_OUT = 0.35

---@type KennelToastFrame?
local frame
---The toast up now; nil when none is.
---@type KennelToastInfo?
local current
---Toasts waiting while another is up; each shows when the one before it is gone.
---@type KennelToastInfo[]
local queue = {}
---Seconds since the toast was shown; how many of those it was not hovered (what counts towards
---its stay); how long it stays before it fades; when the fade began, on the first clock.
---@type number, number, number, number?
local clock, shownFor, stay, fadeStart = 0, 0, 0, nil

-- The functions that call each other in a circle (Display starts Animate, which ends in
-- ShowNext, which calls Display) are fields here rather than locals declared ahead.
local Toast = {}

---@return KennelToastSettings
local function Settings()
    return Kennel.db.profile.toast --[[@as KennelToastSettings]]
end

---Puts the toast where it was dragged to, or in its standard spot near the top; `drop` lifts it
---that many pixels, for the slide in.
---@param drop number
local function Position(drop)
    local toast = frame --[[@as KennelToastFrame]]
    toast:ClearAllPoints()
    local pos = Settings().pos
    if pos then
        toast:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4] + drop)
    else
        toast:SetPoint("TOP", UIParent, "TOP", 0, -120 + drop)
    end
end

---@param p number from 0 to 1
---@return number
local function EaseOut(p)
    return 1 - (1 - p) * (1 - p)
end

---How far an animation that starts at `delay` and lasts `duration` is at time `t`, from 0 to 1.
---@param t number
---@param delay number
---@param duration number
---@return number
local function Progress(t, delay, duration)
    return math.max(0, math.min(1, (t - delay) / duration))
end

---Shows the next waiting toast, if any; called whenever one is gone.
local function ShowNext()
    current = nil
    local info = table.remove(queue, 1)
    if info then Toast.Display(info) end
end

---@param toast KennelToastFrame
---@param elapsed number seconds since the previous frame
local function Animate(toast, elapsed)
    clock = clock + elapsed
    -- Its stay stands still while the mouse is over it, so it can be read.
    if not toast:IsMouseOver() then shownFor = shownFor + elapsed end

    local slide = EaseOut(Progress(clock, 0, SLIDE_IN))
    Position(SLIDE_DISTANCE * (1 - slide))
    local alpha = slide

    local left = 1 - Progress(shownFor, 0, stay)
    toast.Timer:SetWidth(math.max(1, (WIDTH - ACCENT_WIDTH) * left))

    if not fadeStart and shownFor >= stay then fadeStart = clock end
    if fadeStart then
        local p = Progress(clock, fadeStart, FADE_OUT)
        alpha = alpha * (1 - p)
        if p >= 1 then
            toast:SetScript("OnUpdate", nil)
            toast:Hide()
            ShowNext()
            return
        end
    end
    toast:SetAlpha(alpha)
end

---Closes the toast at once, without the fade; the next waiting one, if any, follows.
function Kennel:HideToast()
    if not frame then return end
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    ShowNext()
end

---@param toast KennelToastFrame
local function OnDragStart(toast)
    toast:StartMoving()
end

---@param toast KennelToastFrame
local function OnDragStop(toast)
    toast:StopMovingOrSizing()
    local point, _, relativePoint, x, y = toast:GetPoint(1)
    if point then Settings().pos = { point, relativePoint, x, y } end
end

---@param _ KennelToastFrame
---@param button string
local function OnMouseUp(_, button)
    if button == "RightButton" then Kennel:HideToast() end
end

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

---Makes the frame, the first time a toast shows.
---@return KennelToastFrame
local function Build()
    local toast = CreateFrame("Frame", "KennelToast", UIParent) --[[@as KennelToastFrame]]
    toast:SetSize(WIDTH, ICON_SIZE + 2 * PAD)
    toast:SetFrameStrata("HIGH")
    toast:SetClampedToScreen(true)
    toast:EnableMouse(true)
    toast:SetMovable(true)
    toast:RegisterForDrag("LeftButton")
    toast:SetScript("OnDragStart", OnDragStart)
    toast:SetScript("OnDragStop", OnDragStop)
    toast:SetScript("OnMouseUp", OnMouseUp)

    -- The edge is the frame filled in its colour, with the panel one pixel inside it.
    Solid(toast, "BACKGROUND", EDGE):SetAllPoints(toast)
    local panel = Solid(toast, "BORDER", PANEL)
    panel:SetPoint("TOPLEFT", toast, "TOPLEFT", 1, -1)
    panel:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -1, 1)

    toast.Accent = Solid(toast, "ARTWORK", Kennel.TOAST_ACCENT)
    toast.Accent:SetPoint("TOPLEFT", panel, "TOPLEFT")
    toast.Accent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")
    toast.Accent:SetWidth(ACCENT_WIDTH)

    local iconEdge = Solid(toast, "ARTWORK", { 0, 0, 0, 1 })
    iconEdge:SetSize(ICON_SIZE + 2, ICON_SIZE + 2)
    iconEdge:SetPoint("TOPLEFT", panel, "TOPLEFT", ACCENT_WIDTH + PAD - 1, -PAD + 1)
    toast.Icon = toast:CreateTexture(nil, "OVERLAY")
    toast.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    toast.Icon:SetPoint("CENTER", iconEdge, "CENTER")
    toast.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local textWidth = WIDTH - ACCENT_WIDTH - ICON_SIZE - 3 * PAD
    toast.Title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toast.Title:SetPoint("TOPLEFT", iconEdge, "TOPRIGHT", PAD, -1)
    toast.Text = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toast.Text:SetPoint("TOPLEFT", toast.Title, "BOTTOMLEFT", 0, -4)
    toast.Hint = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toast.Hint:SetPoint("TOPLEFT", toast.Text, "BOTTOMLEFT", 0, -4)
    toast.Hint:SetTextColor(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3])
    for _, text in ipairs({ toast.Title, toast.Text, toast.Hint }) do
        text:SetWidth(textWidth)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(true)
    end

    toast.Timer = Solid(toast, "OVERLAY", Kennel.TOAST_ACCENT)
    toast.Timer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", ACCENT_WIDTH, 0)
    toast.Timer:SetHeight(2)

    toast:Hide()
    return toast
end

---The height the text needs, and at least the icon's, with the padding around it.
---@param toast KennelToastFrame
---@return number
local function Height(toast)
    local text = toast.Title:GetStringHeight() + toast.Text:GetStringHeight() + toast.Hint:GetStringHeight() + 8
    return math.max(ICON_SIZE, text) + 2 * PAD
end

---Plays a toast's sound: a sound file, or a sound kit.
---@param sound KennelSound?
local function Play(sound)
    if not sound then return end
    if sound.file then
        PlaySoundFile(sound.file, "Master")
    else
        PlaySound(sound.kit, "Master")
    end
end

---Fills the toast with `info` and starts it.
---@param info KennelToastInfo
function Toast.Display(info)
    frame = frame or Build()
    local toast = frame --[[@as KennelToastFrame]]
    current = info
    local accent = info.accent or Kennel.TOAST_ACCENT
    toast.Accent:SetColorTexture(accent[1], accent[2], accent[3], 1)
    toast.Timer:SetColorTexture(accent[1], accent[2], accent[3], 1)
    toast.Title:SetTextColor(accent[1], accent[2], accent[3])
    toast.Icon:SetTexture(info.icon or FALLBACK_ICON)
    toast.Title:SetText(info.title)
    toast.Text:SetText(info.text or "")
    toast.Hint:SetText(info.hint or "")
    toast:SetHeight(Height(toast))

    local settings = Settings()
    toast:SetScale(settings.scale)
    clock, shownFor, fadeStart, stay = 0, 0, nil, settings.duration
    toast:SetAlpha(0)
    Position(SLIDE_DISTANCE)
    toast:SetScript("OnUpdate", Animate)
    toast:Show()
    Play(info.sound)
end

---The place in the queue of the toast for `key`, or nil.
---@param key string
---@return number?
local function Queued(key)
    for i, info in ipairs(queue) do
        if info.key == key then return i end
    end
    return nil
end

---Shows a toast now, or after the one that is up. A key whose toast is up or waiting gets no
---second one.
---@param info KennelToastInfo
function Kennel:ShowToast(info)
    if (current and current.key == info.key) or Queued(info.key) then return end
    if current then
        queue[#queue + 1] = info
    else
        Toast.Display(info)
    end
end

---Takes away the toast for `key`: it fades out if it is up, and is dropped if it is waiting.
---@param key string
function Kennel:DropToast(key)
    local index = Queued(key)
    if index then table.remove(queue, index) end
    if current and current.key == key and not fadeStart then fadeStart = clock end
end

---Takes away every toast whose key starts with `prefix` (a module's name and a colon).
---@param prefix string
function Kennel:DropToasts(prefix)
    for i = #queue, 1, -1 do
        if queue[i].key:sub(1, #prefix) == prefix then table.remove(queue, i) end
    end
    if current and current.key:sub(1, #prefix) == prefix then self:DropToast(current.key) end
end

---The toast frame, once one has shown; for tests and for modules that place things by it.
---@return KennelToastFrame?
function Kennel:ToastFrame()
    return frame
end

---Puts the toast back in its standard spot.
function Kennel:ResetToastPosition()
    Settings().pos = nil
end
