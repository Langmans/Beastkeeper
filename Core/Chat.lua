local _, ns = ...

-- Chat sent on the player's next key press or click: WoW: Forever blocks an addon's chat outside
-- a hardware event. One message waits at a time, for at most MAX_WAIT seconds; with MessageQueue
-- loaded, that addon does the waiting.

---@type Kennel
local Kennel = ns

local MAX_WAIT = 10 -- seconds

---The message waiting, its chat type, and when it was handed over (GetTime).
---@type string?, string?, number?
local waitingText, waitingKind, waitingSince

-- Shown only while a message waits; it passes every key on. Passing keys on is restricted in
-- combat, so loaded in combat it stays hidden (it would swallow keys) and only clicks send.
local keys = CreateFrame("Frame", "KennelChatKeys", UIParent)
keys:Hide()
keys:EnableKeyboard(true)
local propagating = false
Kennel:OutOfCombat("chat:keys", function()
    keys:SetPropagateKeyboardInput(true)
    propagating = true
end)

---Sends the waiting message, if it is still fresh and the client allows chat; called inside a
---hardware event.
local function Flush()
    local text, kind, since = waitingText, waitingKind, waitingSince
    waitingText, waitingKind, waitingSince = nil, nil, nil
    keys:Hide()
    if not text or GetTime() - since > MAX_WAIT then return end
    if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return end
    local send = C_ChatInfo.SendChatMessage or SendChatMessage
    send(text, kind)
end

keys:SetScript("OnKeyDown", Flush)
WorldFrame:HookScript("OnMouseDown", function()
    if waitingText then Flush() end
end)

---Sends `text` as `kind` ("EMOTE", "SAY", ...) on the player's next key press or click; a newer
---message replaces one still waiting, and one not sent within ten seconds is dropped.
---@param text string
---@param kind string
function Kennel:SendOnInput(text, kind)
    local since = GetTime()
    waitingText, waitingKind, waitingSince = text, kind, since
    -- Enqueue, not its SendChatMessage: that one sends an EMOTE at once, and gets blocked.
    if MessageQueue and MessageQueue.Enqueue then
        MessageQueue.Enqueue(Flush)
    elseif propagating then
        keys:Show()
    end
    -- Without input in time: hide the key frame again so it does not stay in the keyboard chain.
    C_Timer.After(MAX_WAIT + 0.5, function()
        if waitingSince == since then Flush() end
    end)
end
