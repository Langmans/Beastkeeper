local _, ns = ...

-- Screenshots for development, to see afterwards what happened in game: each toast once it has
-- faded in, and each line Kennel prints (at most one every two seconds), with a grey chat line
-- first saying what it was for. Only in a copy straight from the repository, behind a box on
-- Kennel's page that starts unticked: the packager comments the debug block out of every release,
-- so a player never has Kennel.dev, nor the box. English only: no player ever sees it.

---@type Kennel
local Kennel = ns

--@debug@
Kennel.dev = true
--@end-debug@

local SHOT_DELAY = 0.3 -- seconds for the chat line to show before the screenshot
local SHOT_GAP = 2 -- seconds at least between two screenshots of chat
local lastShot = -SHOT_GAP

---Whether screenshots are on: a development copy with the box ticked.
---@return boolean
local function On()
    return Kennel.dev == true and Kennel.db.global.devScreenshots == true
end

---Says in chat, in grey, what a screenshot is for.
---@param what string
local function Say(what)
    print("|cff888888[Kennel dev] " .. what .. "|r")
end

local showToast = Kennel.ShowToast
---@param info KennelToastInfo
function Kennel:ShowToast(info)
    if On() then
        Say("toast " .. info.key)
        info.screenshot = true
    end
    showToast(self, info)
end

local kennelPrint = Kennel.Print
---@param ... any
function Kennel:Print(...)
    kennelPrint(self, ...)
    if not On() or GetTime() - lastShot < SHOT_GAP then return end
    lastShot = GetTime()
    Say("chat: " .. strjoin(" ", tostringall(...)))
    C_Timer.After(SHOT_DELAY, Screenshot)
end

local getOptionsTable = Kennel.GetOptionsTable
---@return AceConfig.OptionsTable
function Kennel:GetOptionsTable()
    local options = getOptionsTable(self)
    if self.dev then
        options.args.modules.args.devScreenshots = {
            type = "toggle",
            name = "Screenshots for development",
            desc = "A screenshot of each toast and each Kennel chat line. Only in a copy from the repository.",
            order = 99,
            width = "full",
            get = function()
                return On()
            end,
            ---@param _ table
            ---@param value boolean
            set = function(_, value)
                self.db.global.devScreenshots = value
            end,
        }
    end
    return options
end
