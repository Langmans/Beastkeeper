local _, ns = ...

-- The toast every module shows, split in two:
--   - the engine, here: which toast is up and which wait, how long one stays, its sound, and the
--     clock that runs its intro, its stay and its fade;
--   - a skin, which draws it: Core\Skins\ has the card and the splash, and any other addon can add
--     one with Kennel:RegisterToastSkin, to draw in its own style or to hand the toast to another
--     addon altogether. What a skin does is described by KennelToastSkin in annotations\Kennel.lua.
--
-- Which skin draws a toast is a setting: one for every toast, and per kind of toast (the kinds a
-- module lists in its toastTypes) "the same as every toast" or a skin of its own. A skin that is
-- not registered (an addon that provided it is gone) falls back to the card.
--
-- Each toast has a key, such as "AutocastCheck:growlOn". One key has at most one toast up or
-- waiting; toasts for different keys show one after the other. A module takes its toast away with
-- DropToast when what it was about is solved, and drops all of its own when it is switched off.
--
-- The clock: a toast's intro and fade count from when it showed; its stay counts only while the
-- mouse is not over it, so hovering keeps it up to be read. A small frame of its own drives the
-- clock (OnUpdate runs only while a frame is shown), made on the first toast.

---@type Kennel
local Kennel = ns

-- Seconds.
local INTRO, FADE_OUT = 0.2, 0.35

-- The skin a toast falls back to.
local DEFAULT_SKIN = "card"

-- What a skin draws when the toast brings none: a warm amber accent, a question mark icon.
Kennel.TOAST_ACCENT = { 1, 0.62, 0.18 }
Kennel.TOAST_ICON = 134400 -- INV_Misc_QuestionMark

---@type table<string, KennelToastSkin>
local skins = {}
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

-- The functions that call each other in a circle (Display starts the clock, which ends in
-- ShowNext, which calls Display) are fields here rather than locals declared ahead.
local Engine = {}

---@return KennelToastSettings
local function Settings()
    return Kennel.db.profile.toast --[[@as KennelToastSettings]]
end

-- What every skin must have (KennelToastSkin): RegisterToastSkin refuses one without.
local SKIN_METHODS = { "Show", "Update", "Hide", "IsMouseOver" }

---Makes a skin available. Another addon calls this on Kennel's addon object
---(LibStub("AceAddon-3.0"):GetAddon("Kennel", true)), at any time after Kennel has loaded.
---Raises an error naming what is missing when the skin does not keep the contract.
---@param id string kept in the saved settings; a short lowercase word
---@param skin KennelToastSkin
function Kennel:RegisterToastSkin(id, skin)
    if type(id) ~= "string" or id == "" then error("Kennel:RegisterToastSkin: id must be a non-empty string", 2) end
    if type(skin) ~= "table" then error("Kennel:RegisterToastSkin(" .. id .. "): skin must be a table", 2) end
    ---@type string[]
    local missing = {}
    if type(skin.name) ~= "string" then missing[#missing + 1] = "name (a string)" end
    for _, method in ipairs(SKIN_METHODS) do
        if type(skin[method]) ~= "function" then missing[#missing + 1] = method end
    end
    if #missing > 0 then
        error("Kennel:RegisterToastSkin(" .. id .. "): the skin has no " .. table.concat(missing, ", "), 2)
    end
    skins[id] = skin
end

---The registered skins, by id.
---@return table<string, KennelToastSkin>
function Kennel:ToastSkins()
    return skins
end

---The id of the skin that draws toasts of `kind`: its own choice, else the one for every toast,
---else the card, whichever of those is registered first.
---@param kind string? "<Module>:<type>"
---@return string
function Kennel:ToastSkinFor(kind)
    local settings = Settings()
    local chosen = kind and settings.skins[kind]
    if chosen and skins[chosen] then return chosen end
    if skins[settings.skin] then return settings.skin end
    return DEFAULT_SKIN
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
    if skin ~= skins[DEFAULT_SKIN] then Engine.Fallback(method ~= "Hide") end
    return false
end

---Puts the card in place of the skin that failed, for the toast that is up; `show` is false when
---the toast was going away anyway.
---@param show boolean
function Engine.Fallback(show)
    local failed = currentSkin --[[@as KennelToastSkin]]
    pcall(failed.Hide, failed)
    currentSkin = skins[DEFAULT_SKIN]
    lastSkin = currentSkin
    if show then Call("Show", current, Settings()) end
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
    local settings = Settings()
    current, currentSkin = info, skins[Kennel:ToastSkinFor(info.type)]
    lastSkin = currentSkin
    clock, shownFor, fadeStart, stay = 0, 0, nil, settings.duration
    Call("Show", info, settings)
    Call("Update", 0, 0, 1)
    driver:Show()
    Play(info.sound)
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
---second one.
---@param info KennelToastInfo
function Kennel:ShowToast(info)
    if (current and current.key == info.key) or Queued(info.key) then return end
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

-- What every skin's frame does the same way: it moves where it is dragged (the spot is saved in
-- the profile, shared by all skins) and closes on a right-click.

---@param frame Frame
local function OnDragStart(frame)
    frame:StartMoving()
end

---@param frame Frame
local function OnDragStop(frame)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then Settings().pos = { point, relativePoint, x, y } end
end

---@param _ Frame
---@param button string
local function OnMouseUp(_, button)
    if button == "RightButton" then Kennel:HideToast() end
end

---A frame for a skin: on top of the UI, kept on screen, draggable, closed by a right-click.
---Hidden until the skin shows it.
---@param name string? a global name, for /fstack and other addons
---@return Frame
function Kennel:NewToastFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", OnDragStart)
    frame:SetScript("OnDragStop", OnDragStop)
    frame:SetScript("OnMouseUp", OnMouseUp)
    frame:Hide()
    return frame
end

---Places a skin's frame where it was dragged to, or at the skin's own standard spot; `lift`
---raises it that many pixels (for a slide in).
---@param frame Frame
---@param point string the standard spot: an anchor point on UIParent
---@param x number
---@param y number
---@param lift number?
function Kennel:PlaceToast(frame, point, x, y, lift)
    lift = lift or 0
    frame:ClearAllPoints()
    local pos = Settings().pos
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4] + lift)
    else
        frame:SetPoint(point, UIParent, point, x, y + lift)
    end
end

---Puts the toast back in its standard spot.
function Kennel:ResetToastPosition()
    Settings().pos = nil
end

---The kinds of toast the modules show, as "<Module>:<type>" with their names, for the skin
---choice; from each module's toastTypes.
---@return table<string, string>
function Kennel:ToastTypes()
    ---@type table<string, string>
    local kinds = {}
    for name, module in pairs(self.modules) do
        for kind, label in pairs(module.toastTypes or {}) do
            kinds[name .. ":" .. kind] = (module.title or name) .. ": " .. label
        end
    end
    return kinds
end
