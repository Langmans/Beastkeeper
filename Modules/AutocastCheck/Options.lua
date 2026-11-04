local _, ns = ...

-- AutocastCheck's page in the settings window (Huntsworn > Autocast Check): which abilities are
-- watched, the combat reminder, the sound, an example toast and the macros. Huntsworn's core
-- builds the page from GetOptions and greys it out while the module is off.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("AutocastCheck") --[[@as AddonAutocastCheck]]

---Checks again after a change, since what counts as wrong may have changed.
local function Recheck()
    M:Check()
end

---A getter and setter for one profile setting (Huntsworn:Setting).
---@param key string
---@return fun(): string|boolean|number get
---@return fun(info: table, value: string|boolean|number) set
local function Setting(key)
    return Addon:Setting(M, key, Recheck)
end

---@return table
function M:GetOptions()
    local growlGet, growlSet = Setting("growl")
    local cowerGet, cowerSet = Setting("cower")
    local learnGet, learnSet = Setting("learnCower")
    local remindGet, remindSet = Setting("remind")
    local remindEveryGet, remindEverySet = Setting("remindEvery")
    local soundGet, soundSet = Setting("sound")
    return {
        args = {
            growl = {
                type = "toggle",
                name = L.AUTOCAST_OPTION_GROWL,
                desc = L.AUTOCAST_OPTION_GROWL_DESC,
                order = 3,
                width = "full",
                get = growlGet,
                set = growlSet,
            },
            cower = {
                type = "toggle",
                name = L.AUTOCAST_OPTION_COWER,
                desc = L.AUTOCAST_OPTION_COWER_DESC,
                order = 4,
                width = "full",
                get = cowerGet,
                set = cowerSet,
            },
            learnCower = {
                type = "toggle",
                name = L.AUTOCAST_OPTION_LEARN_COWER,
                desc = L.AUTOCAST_OPTION_LEARN_COWER_DESC,
                order = 4.5,
                width = "full",
                disabled = function()
                    return not M:Settings().cower
                end,
                get = learnGet,
                set = learnSet,
            },
            remind = {
                type = "toggle",
                name = L.AUTOCAST_OPTION_REMIND,
                desc = L.AUTOCAST_OPTION_REMIND_DESC,
                order = 5,
                width = "full",
                get = remindGet,
                set = remindSet,
            },
            remindEvery = {
                type = "range",
                name = L.AUTOCAST_OPTION_REMIND_EVERY,
                desc = L.AUTOCAST_OPTION_REMIND_EVERY_DESC,
                order = 5.1,
                min = 0,
                max = 30,
                step = 1,
                disabled = function()
                    return not M:Settings().remind
                end,
                get = remindEveryGet,
                set = remindEverySet,
            },
            sound = {
                type = "select",
                name = L.AUTOCAST_OPTION_SOUND,
                order = 6,
                width = "full",
                values = {
                    family = L.AUTOCAST_OPTION_SOUND_FAMILY,
                    warning = L.AUTOCAST_OPTION_SOUND_WARNING,
                    off = L.AUTOCAST_OPTION_SOUND_OFF,
                },
                sorting = { "family", "warning", "off" },
                get = soundGet,
                set = soundSet,
            },
            test = {
                type = "execute",
                name = L.AUTOCAST_OPTION_TEST,
                order = 7,
                func = function()
                    M:TestToast()
                end,
            },
            macros = {
                type = "execute",
                name = L.AUTOCAST_OPTION_MACROS,
                desc = L.AUTOCAST_OPTION_MACROS_DESC,
                order = 8,
                func = function()
                    Addon:CreateMacros(M, true)
                end,
            },
        },
    }
end
