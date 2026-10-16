local _, ns = ...

-- AutocastCheck's page in the settings window (Kennel > Autocast Check): the mode, which abilities
-- are watched, the combat reminder, the sound, an example toast and the macros. Kennel's core
-- builds the page from GetOptions and greys it out while the module is off.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("AutocastCheck") --[[@as KennelAutocastCheck]]

---A getter and setter for one profile setting; a change checks again, since what counts as
---wrong may have changed.
---@param key string
---@return fun(): string|boolean get
---@return fun(info: table, value: string|boolean) set
local function Setting(key)
    ---@type table<string, string|boolean>
    local settings = M:Settings()
    ---@return string|boolean
    local function get()
        return settings[key]
    end
    ---@param _ table AceConfig's info about the option
    ---@param value string|boolean
    local function set(_, value)
        settings[key] = value
        if M:IsEnabled() then M:Check() end
    end
    return get, set
end

---@return table
function M:GetOptions()
    local modeGet, modeSet = Setting("mode")
    local growlGet, growlSet = Setting("growl")
    local cowerGet, cowerSet = Setting("cower")
    local remindGet, remindSet = Setting("remind")
    local soundGet, soundSet = Setting("sound")
    return {
        args = {
            mode = {
                type = "select",
                name = L.AUTOCAST_OPTION_MODE,
                order = 1,
                width = "full",
                values = {
                    auto = L.AUTOCAST_OPTION_MODE_AUTO,
                    kite = L.AUTOCAST_OPTION_MODE_KITE,
                    tank = L.AUTOCAST_OPTION_MODE_TANK,
                },
                sorting = { "auto", "kite", "tank" },
                get = modeGet,
                set = modeSet,
            },
            modeNote = { type = "description", name = L.AUTOCAST_OPTION_MODE_NOTE, order = 2 },
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
            remind = {
                type = "toggle",
                name = L.AUTOCAST_OPTION_REMIND,
                desc = L.AUTOCAST_OPTION_REMIND_DESC,
                order = 5,
                width = "full",
                get = remindGet,
                set = remindSet,
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
                    Kennel:CreateMacros(M, true)
                end,
            },
        },
    }
end
