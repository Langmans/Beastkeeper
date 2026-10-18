local addonName, ns = ...

-- The bridge to OAP Debug (an addon of its own, a debug window: log, inspector, metrics, Lua
-- errors), the only file that talks to it. When it is installed, Kennel registers with it under
-- its folder (so its Lua errors are filed under Kennel), sends its own KENNEL_* messages to the
-- log with their table, copies its chat lines and counts the messages; the window's tabs are
-- timed. How much goes is the "OAP Debug" setting every OAP addon has: errors only, normal,
-- normal + metrics (the default), detailed. Without OAP Debug nothing is sent and Kennel listens
-- to nothing for it.

---@type Kennel
local Kennel = ns
local L = Kennel.L

local SOURCE = "Kennel"
local ICON = "Interface\\Icons\\Ability_Hunter_BeastCall"
local ERRORS, NORMAL, METRICS, DETAILED = 1, 2, 3, 4
local LEVELS = { errors = ERRORS, normal = NORMAL, metrics = METRICS, detailed = DETAILED }
-- What a log line of each kind needs.
local NEEDS = { error = ERRORS, warn = NORMAL, info = NORMAL, debug = DETAILED }
-- Kennel's messages that go to the log; KENNEL_PRINT goes to its chat tab instead.
local MESSAGES = {
    "KENNEL_TOAST",
    "KENNEL_RANKS_KNOWN",
    "KENNEL_ABILITY_LEARNED",
    "KENNEL_PET_GROWTH",
    "KENNEL_AUTOCAST_WANTED",
    "KENNEL_RARE_SEEN",
    "KENNEL_PET_HAPPINESS",
    "KENNEL_PET_DIED",
    "KENNEL_PET_TAMED",
}

local level = METRICS
local registered = false
-- The table Kennel listens with, to its own messages.
local listener = {}

---OAP Debug's table when it is installed.
---@return OAPDebugApi?
local function Installed()
    local api = rawget(_G, "OAPDebug") --[[@as GameValue]]
    if type(api) == "table" and type(api.Log) == "function" then
        return api --[[@as OAPDebugApi]]
    end
end

---OAP Debug's table, registering Kennel the first time; nil when it is not installed.
---@return OAPDebugApi?
local function D()
    local api = Installed()
    if api and not registered then
        registered = true
        api.Register(SOURCE, { title = addonName, folder = addonName, icon = ICON })
    end
    return api
end

---Whether OAP Debug is installed.
---@return boolean
function Kennel.HasOAPDebug()
    return Installed() ~= nil
end

---A log line: "error", "warn", "info" or "debug"; values fill {1}, {2}, ... (tables become links).
---@param kind "error"|"warn"|"info"|"debug"
---@param msg string
---@param ... any
function Kennel:Log(kind, msg, ...)
    if level < NEEDS[kind] then return end
    local d = D()
    if d then d.Log(SOURCE, msg, kind, ...) end
end

---Counts something that happens, from Normal + metrics.
---@param name string
function Kennel:Count(name)
    if level < METRICS then return end
    local d = D()
    if d then d.Count(SOURCE, name) end
end

---Runs fn, timed from Normal + metrics.
---@param name string
---@param fn fun(...)
---@param ... any
function Kennel:Time(name, fn, ...)
    local d = level >= METRICS and D()
    if d then
        d.Time(SOURCE, name, fn, ...)
    else
        fn(...)
    end
end

---A Kennel message: to the log with its table, and counted.
---@param message string
---@param event table
local function OnMessage(message, event)
    Kennel:Log("info", message .. " {1}", event)
    Kennel:Count(message)
end

---A chat line Kennel printed: to OAP Debug's chat tab.
---@param _ string the message
---@param event KennelPrintEvent
local function OnPrint(_, event)
    if level < NORMAL then return end
    local d = D()
    if d then d.Chat(SOURCE, event.line) end
end

---Listens to Kennel's messages while OAP Debug is there and the level logs them; stops otherwise.
function Kennel:ApplyDebugLevel()
    level = LEVELS[self.db.profile.oapDebug] or METRICS
    self:StopListening(listener)
    if level < NORMAL or not Kennel.HasOAPDebug() then return end
    self:Listen(listener, "KENNEL_PRINT", OnPrint)
    for _, message in ipairs(MESSAGES) do
        self:Listen(listener, message, OnMessage)
    end
end

---The OAP Debug setting, as on every OAP addon's page.
---@return AceConfig.OptionsTable
function Kennel:GetDebugOptions()
    return {
        type = "group",
        inline = true,
        name = L.DEBUG,
        order = 120,
        args = {
            level = {
                type = "select",
                name = L.DEBUG_LEVEL,
                desc = function()
                    return Kennel.HasOAPDebug() and L.DEBUG_DESC or L.DEBUG_DESC .. " " .. L.DEBUG_MISSING
                end,
                order = 1,
                values = {
                    errors = L.DEBUG_ERRORS,
                    normal = L.DEBUG_NORMAL,
                    metrics = L.DEBUG_METRICS,
                    detailed = L.DEBUG_DETAILED,
                },
                get = function()
                    return self.db.profile.oapDebug --[[@as string]]
                end,
                ---@param _ table AceConfig's info about the option
                ---@param value string
                set = function(_, value)
                    self.db.profile.oapDebug = value
                    self:ApplyDebugLevel()
                end,
            },
        },
    }
end
