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
-- OAP Debug's table, found once when Kennel's settings load (OptionalDeps loads it first); nil
-- without it.
---@type OAPDebugApi?
local api
-- The table Kennel listens with, to its own messages.
local listener = {}

---Finds OAP Debug and registers Kennel with it, once.
local function Connect()
    if api then return end
    api = rawget(_G, "OAPDebug") --[[@as OAPDebugApi?]]
    if api then api.Register(SOURCE, { title = addonName, folder = addonName, icon = ICON }) end
end

---Whether OAP Debug is installed.
---@return boolean
function Kennel.HasOAPDebug()
    return api ~= nil
end

---A log line: "error", "warn", "info" or "debug"; values fill {1}, {2}, ... (tables become links).
---@param kind "error"|"warn"|"info"|"debug"
---@param msg string
---@param ... any
function Kennel:Log(kind, msg, ...)
    if api and level >= NEEDS[kind] then api.Log(SOURCE, msg, kind, ...) end
end

---Counts something that happens, from Normal + metrics.
---@param name string
function Kennel:Count(name)
    if api and level >= METRICS then api.Count(SOURCE, name) end
end

---Runs fn, timed from Normal + metrics.
---@param name string
---@param fn fun(...)
---@param ... any
function Kennel:Time(name, fn, ...)
    if api and level >= METRICS then
        api.Time(SOURCE, name, fn, ...)
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
    if api and level >= NORMAL then api.Chat(SOURCE, event.line) end
end

---Takes the profile's level; listens to Kennel's messages while OAP Debug is there and the level
---logs them, stops otherwise.
function Kennel:ApplyDebugLevel()
    Connect()
    level = LEVELS[self.db.profile.oapDebug] or METRICS
    self:StopListening(listener)
    if level < NORMAL or not api then return end
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
