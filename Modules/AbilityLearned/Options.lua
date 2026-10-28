local _, ns = ...

-- AbilityLearned's page in the settings window (Beastkeeper > Ability Learned): the sound, the
-- screenshot, the hints, the training points and loyalty toasts with their sounds, an example toast, a simulated learn, what the pet can teach, and the
-- history.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("AbilityLearned") --[[@as AddonAbilityLearned]]

---A getter and setter for one profile setting (Beastkeeper:Setting).
---@param key string
---@return fun(): string|boolean|number get
---@return fun(info: table, value: string|boolean|number) set
local function Setting(key)
    return Addon:Setting(M, key)
end

---A sound choice for the setting `key`.
---@param key "sound"|"pointsSound"|"loyaltySound"
---@param name string
---@param order number
---@return table
local function SoundSelect(key, name, order)
    local get, set = Setting(key)
    return {
        type = "select",
        name = name,
        order = order,
        width = "full",
        values = {
            family = L.ABILITYLEARNED_OPTION_SOUND_FAMILY,
            levelup = L.ABILITYLEARNED_OPTION_SOUND_LEVELUP,
            off = L.ABILITYLEARNED_OPTION_SOUND_OFF,
        },
        sorting = { "family", "levelup", "off" },
        get = get,
        set = set,
    }
end

---@return table
function M:GetOptions()
    local screenshotGet, screenshotSet = Setting("screenshot")
    local hintsGet, hintsSet = Setting("hints")
    local pointsGet, pointsSet = Setting("points")
    local loyaltyGet, loyaltySet = Setting("loyalty")
    return {
        args = {
            sound = SoundSelect("sound", L.ABILITYLEARNED_OPTION_SOUND, 1),
            pointsSound = SoundSelect("pointsSound", L.ABILITYLEARNED_OPTION_POINTS_SOUND, 3.6),
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
            points = {
                type = "toggle",
                name = L.ABILITYLEARNED_OPTION_POINTS,
                desc = L.ABILITYLEARNED_OPTION_POINTS_DESC,
                order = 3.5,
                width = "full",
                get = pointsGet,
                set = pointsSet,
            },
            loyalty = {
                type = "toggle",
                name = L.ABILITYLEARNED_OPTION_LOYALTY,
                order = 3.7,
                width = "full",
                get = loyaltyGet,
                set = loyaltySet,
            },
            loyaltySound = SoundSelect("loyaltySound", L.ABILITYLEARNED_OPTION_LOYALTY_SOUND, 3.8),
            test = {
                type = "execute",
                name = L.ABILITYLEARNED_OPTION_TEST,
                order = 4,
                func = function()
                    local name, rank, icon, petSpell = M.Example()
                    local teacher = petSpell and UnitName("pet") or nil
                    Addon:ShowToast(M:Toast({ name = name, rank = rank, icon = icon, teacher = teacher }))
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
            teachers = {
                type = "execute",
                name = L.ABILITYLEARNED_OPTION_TEACHERS,
                desc = L.ABILITYLEARNED_OPTION_TEACHERS_DESC,
                order = 6.5,
                func = function()
                    M:ReportMissingTeachers()
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
