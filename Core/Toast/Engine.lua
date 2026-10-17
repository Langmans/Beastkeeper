local _, ns = ...

-- The toast engine: one toast per key up or waiting, shown one after the other; the clock (intro
-- and fade count from showing, the stay only while not hovered); the sound; and the card taking
-- over from a skin that errors. A frame of its own drives the clock, made on the first toast.

---@type Kennel
local Kennel = ns

-- Seconds. A toast that asks for a screenshot gets it a moment after its intro, fully drawn.
local INTRO, FADE_OUT = 0.2, 0.35
local SCREENSHOT_AT = INTRO + 0.2

---The skin that drew the last toast; for tests and for ToastFrame.
---@type KennelToastSkin?
local lastSkin
---@type Frame?
local driver
---The toast up now, and the skin drawing it; nil when none is.
---@type KennelToastInfo?, KennelToastSkin?
local current, currentSkin
---Toasts waiting while another is up; each shows when the one before it is gone.
---@type KennelToastInfo[]
local queue = {}
---Seconds since the toast was shown; how many of those it was not hovered (what counts towards
---its stay); how long it stays before it fades; when the fade began, on the first clock.
---@type number, number, number, number?
local clock, shownFor, stay, fadeStart = 0, 0, 0, nil
---The toast up wants a screenshot that has not been taken yet.
local screenshotDue = false

-- The functions that call each other in a circle (Display starts the clock, which ends in
-- ShowNext, which calls Display) are fields here rather than locals declared ahead.
local Engine = {}

---The card, which takes over from a skin that fails.
---@return KennelToastSkin
local function Card()
    return Kennel:ToastSkins()[Kennel.TOAST_DEFAULT_SKIN]
end

---Calls a method of the skin drawing the toast. When it errors, the error goes to the error
---handler (BugSack and the like), and a skin other than the card is replaced by the card for the
---rest of this toast: a broken skin from another addon cannot stop Kennel's toasts.
---@param method string
---@param ... any the method's arguments
---@return boolean? result what IsMouseOver answers; false after an error
local function Call(method, ...)
    local skin = currentSkin --[[@as KennelToastSkin]]
    local ok, result = pcall(skin[method], skin, ...)
    if ok then
        return result --[[@as boolean?]]
    end
    geterrorhandler()(result)
    if skin ~= Card() then Engine.Fallback(method ~= "Hide") end
    return false
end

---Puts the card in place of the skin that failed, for the toast that is up; `show` is false when
---the toast was going away anyway.
---@param show boolean
function Engine.Fallback(show)
    local failed = currentSkin --[[@as KennelToastSkin]]
    pcall(failed.Hide, failed)
    currentSkin = Card()
    lastSkin = currentSkin
    if show then Call("Show", current, Kennel:ToastSettings()) end
end

---Shows the next waiting toast, if any; called whenever one is gone.
local function ShowNext()
    current, currentSkin = nil, nil
    local info = table.remove(queue, 1)
    if info then
        Engine.Display(info)
    else
        (driver --[[@as Frame]]):Hide()
    end
end

---How far an animation that starts at `delay` and lasts `duration` is at time `t`, from 0 to 1.
---@param t number
---@param delay number
---@param duration number
---@return number
local function Progress(t, delay, duration)
    return math.max(0, math.min(1, (t - delay) / duration))
end

---The clock, every frame while a toast is up.
---@param _ Frame the driver
---@param elapsed number seconds since the previous frame
local function Tick(_, elapsed)
    clock = clock + elapsed
    if screenshotDue and clock >= SCREENSHOT_AT then
        screenshotDue = false
        Screenshot()
    end
    if not Call("IsMouseOver") then shownFor = shownFor + elapsed end
    if not fadeStart and shownFor >= stay then fadeStart = clock end
    local fade = fadeStart and Progress(clock, fadeStart, FADE_OUT) or 0
    Call("Update", Progress(clock, 0, INTRO), fade, 1 - Progress(shownFor, 0, stay))
    if fade >= 1 then
        Call("Hide")
        ShowNext()
    end
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

---Hands `info` to its skin and starts the clock.
---@param info KennelToastInfo
function Engine.Display(info)
    if not driver then
        driver = CreateFrame("Frame", "KennelToastDriver", UIParent)
        driver:SetScript("OnUpdate", Tick)
    end
    local settings = Kennel:ToastSettings()
    current, currentSkin = info, Kennel:ToastSkins()[Kennel:ToastSkinFor(info.type)]
    lastSkin = currentSkin
    clock, shownFor, fadeStart, stay = 0, 0, nil, settings.duration
    screenshotDue = info.screenshot == true
    Call("Show", info, settings)
    Play(info.sound)
    -- An instant skin is done once shown (it handed the toast on): the next one follows at once.
    if
        (currentSkin --[[@as KennelToastSkin]]).instant
    then
        ShowNext()
        return
    end
    Call("Update", 0, 0, 1)
    driver:Show()
end

---Closes the toast at once, without the fade; the next waiting one, if any, follows.
function Kennel:HideToast()
    if not currentSkin then return end
    Call("Hide")
    ShowNext()
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
---second one. Sends KENNEL_TOAST ({ module, toast }) first, so a listener may still change the
---toast (docs\hooking.md); the module is the part of the key before the colon.
---@param info KennelToastInfo
function Kennel:ShowToast(info)
    if (current and current.key == info.key) or Queued(info.key) then return end
    self:SendMessage("KENNEL_TOAST", { module = info.key:match("^([^:]+):"), toast = info })
    if current then
        queue[#queue + 1] = info
    else
        Engine.Display(info)
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

---The frame that drives the clock, once a toast has shown; for tests.
---@return Frame?
function Kennel:ToastDriver()
    return driver
end

---The frame of the skin that drew the last toast, if that skin has one to give.
---@return Frame?
function Kennel:ToastFrame()
    return lastSkin and lastSkin.Frame and lastSkin:Frame()
end
