local _, ns = ...

-- AbilityLearned's page in the settings window (Kennel > Ability Learned): the sound, the
-- screenshot, the hints, an example toast, a simulated learn, what the pet can teach, and the
-- history.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("AbilityLearned") --[[@as KennelAbilityLearned]]

---A getter and setter for one profile setting.
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
    end
    return get, set
end

---@return table
function M:GetOptions()
    local soundGet, soundSet = Setting("sound")
    local screenshotGet, screenshotSet = Setting("screenshot")
    local hintsGet, hintsSet = Setting("hints")
    return {
        args = {
            sound = {
                type = "select",
                name = L.ABILITYLEARNED_OPTION_SOUND,
                order = 1,
                width = "full",
                values = {
                    family = L.ABILITYLEARNED_OPTION_SOUND_FAMILY,
                    levelup = L.ABILITYLEARNED_OPTION_SOUND_LEVELUP,
                    off = L.ABILITYLEARNED_OPTION_SOUND_OFF,
                },
                sorting = { "family", "levelup", "off" },
                get = soundGet,
                set = soundSet,
            },
            screenshot = {
                type = "toggle",
                name = L.ABILITYLEARNED_OPTION_SCREENSHOT,
                desc = L.ABILITYLEARNED_OPTION_SCREENSHOT_DESC,
                order = 2,
                width = "full",
                get = screenshotGet,
                set = screenshotSet,
            },
            hints = {
                type = "toggle",
                name = L.ABILITYLEARNED_OPTION_HINTS,
                desc = L.ABILITYLEARNED_OPTION_HINTS_DESC,
                order = 3,
                width = "full",
                get = hintsGet,
                set = hintsSet,
            },
            test = {
                type = "execute",
                name = L.ABILITYLEARNED_OPTION_TEST,
                order = 4,
                func = function()
                    local name, rank, icon, petSpell = M.Example()
                    local teacher = petSpell and UnitName("pet") or nil
                    Kennel:ShowToast(M:Toast({ name = name, rank = rank, icon = icon, teacher = teacher }))
                end,
            },
            simulate = {
                type = "execute",
                name = L.ABILITYLEARNED_OPTION_SIMULATE,
                desc = L.ABILITYLEARNED_OPTION_SIMULATE_DESC,
                order = 5,
                func = function()
                    M:Simulate()
                end,
            },
            check = {
                type = "execute",
                name = L.ABILITYLEARNED_OPTION_CHECK,
                order = 6,
                func = function()
                    M:ReportTeachable()
                end,
            },
            historyTitle = { type = "header", name = L.ABILITYLEARNED_OPTION_HISTORY, order = 7 },
            history = {
                type = "description",
                order = 8,
                name = function()
                    return M:HistoryText()
                end,
            },
        },
    }
end
