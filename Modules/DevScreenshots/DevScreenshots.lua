--@debug@
local _, ns = ...

-- Screenshots for development, to see afterwards what happened in game: a toast once it has faded
-- in, and a line Kennel prints (at most one every two seconds), with a grey chat line first saying
-- what it was for. It listens to the core's KENNEL_TOAST and KENNEL_PRINT, like any other addon
-- could. Each only the first time: a toast by its kind (type, else key), a chat line by its text
-- with every number as "#", kept across sessions so the Screenshots folder does not fill up; a
-- button on the page forgets them.
--
-- The whole file sits in a --@debug@ block: the packager comments it out of every release, so only
-- a copy straight from the repository has the module. Off until switched on. English only: no
-- player ever sees it.

---@type Kennel
local Kennel = ns

---@type KennelDevScreenshots
local M = Kennel:NewModule("DevScreenshots")
M.title = "Dev Screenshots"
M.description = "A screenshot of each kind of toast and chat line, the first time. Repository copies only."
M.enabledByDefault = false
M.defaults = { global = { shots = {} } }

local SHOT_DELAY = 0.3 -- seconds for the chat line to show before the screenshot
local SHOT_GAP = 2 -- seconds at least between two screenshots of chat
local lastShot = -SHOT_GAP

---Whether `what` has no screenshot yet; then marks it as taken and says in chat, in grey, what the
---screenshot is for.
---@param what string
---@return boolean
local function Shoot(what)
    ---@type table<string, true>
    local shots = M.db.global.shots
    if shots[what] then return false end
    shots[what] = true
    print("|cff888888[Kennel dev] " .. what .. "|r")
    return true
end

---@param _ string the message
---@param event KennelToastEvent
function M:KENNEL_TOAST(_, event)
    local toast = event.toast
    if Shoot("toast " .. (toast.type or toast.key)) then toast.screenshot = true end
end

---The screenshot itself. C_Timer.After takes only a Lua function, not the client's Screenshot.
local function TakeScreenshot()
    Screenshot()
end

---@param _ string the message
---@param event KennelPrintEvent
function M:KENNEL_PRINT(_, event)
    if GetTime() - lastShot < SHOT_GAP then return end
    if not Shoot("chat: " .. event.line:gsub("%d+", "#")) then return end
    lastShot = GetTime()
    C_Timer.After(SHOT_DELAY, TakeScreenshot)
end

function M:OnEnable()
    self:RegisterMessage("KENNEL_TOAST")
    self:RegisterMessage("KENNEL_PRINT")
end

---@return table
function M:GetOptions()
    return {
        args = {
            forget = {
                type = "execute",
                name = "Forget the screenshots taken",
                desc = "Take a screenshot of every kind of toast and chat line again.",
                order = 1,
                func = function()
                    wipe(M.db.global.shots)
                end,
            },
        },
    }
end
--@end-debug@
