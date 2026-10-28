local _, ns = ...

-- CareButton's page in the settings window (Beastkeeper > Care Button): the toasts, the low-health
-- line, the sound, whether the pet counts as dead, an example toast and the macro.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("CareButton") --[[@as AddonCareButton]]

---Checks the health again after the low line or the marker's switch changed.
local function RecheckHealth()
    M:CheckHealth()
end

---Shows or hides the button on screen after its switch changed; after combat when in it.
local function Reapply()
    M:ApplyButton()
end

-- What changing a setting sets off: the low line and the marker check the health again, the
-- on-screen switch shows or hides the button.
---@type table<string, fun()>
local CHANGED = { low = RecheckHealth, marker = RecheckHealth, visible = Reapply }

---A getter and setter for one profile setting (Beastkeeper:Setting), with what its change sets off.
---@param key string
---@return fun(): string|boolean|number get
---@return fun(info: table, value: string|boolean|number) set
local function Setting(key)
    return Addon:Setting(M, key, CHANGED[key])
end

---Counts the pet as dead or alive by hand; says so in combat, where it cannot.
---@param dead boolean
local function SetDead(dead)
    if not M:SetPetDead(dead) then M:Print(L.CAREBUTTON_IN_COMBAT) end
end

---@return table
function M:GetOptions()
    local diedGet, diedSet = Setting("died")
    local nopetGet, nopetSet = Setting("nopet")
    local passiveGet, passiveSet = Setting("passive")
    local lowGet, lowSet = Setting("low")
    local markerGet, markerSet = Setting("marker")
    local visibleGet, visibleSet = Setting("visible")
    local soundGet, soundSet = Setting("sound")
    return {
        args = {
            died = {
                type = "toggle",
                name = L.CAREBUTTON_OPTION_DIED,
                desc = L.CAREBUTTON_OPTION_DIED_DESC,
                order = 1,
                width = "full",
                get = diedGet,
                set = diedSet,
            },
            nopet = {
                type = "toggle",
                name = L.CAREBUTTON_OPTION_NOPET,
                order = 2,
                width = "full",
                get = nopetGet,
                set = nopetSet,
            },
            passive = {
                type = "toggle",
                name = L.CAREBUTTON_OPTION_PASSIVE,
                order = 2.5,
                width = "full",
                get = passiveGet,
                set = passiveSet,
            },
            low = {
                type = "range",
                name = L.CAREBUTTON_OPTION_LOW,
                order = 3,
                min = 0,
                max = 90,
                step = 1,
                get = lowGet,
                set = lowSet,
            },
            visible = {
                type = "toggle",
                name = L.CAREBUTTON_OPTION_VISIBLE,
                desc = L.CAREBUTTON_OPTION_VISIBLE_DESC,
                order = 0.5,
                width = "full",
                get = visibleGet,
                set = visibleSet,
            },
            resetPosition = {
                type = "execute",
                name = L.CAREBUTTON_OPTION_RESET,
                order = 0.6,
                func = function()
                    M:Settings().position = nil
                    M:PlaceButton()
                end,
            },
            marker = {
                type = "toggle",
                name = L.CAREBUTTON_OPTION_MARKER,
                desc = L.CAREBUTTON_OPTION_MARKER_DESC,
                order = 3.5,
                width = "full",
                get = markerGet,
                set = markerSet,
            },
            sound = {
                type = "select",
                name = L.CAREBUTTON_OPTION_SOUND,
                order = 4,
                width = "full",
                values = {
                    family = L.CAREBUTTON_OPTION_SOUND_FAMILY,
                    warning = L.CAREBUTTON_OPTION_SOUND_WARNING,
                    off = L.CAREBUTTON_OPTION_SOUND_OFF,
                },
                sorting = { "family", "warning", "off" },
                get = soundGet,
                set = soundSet,
            },
            dead = {
                type = "execute",
                name = L.CAREBUTTON_OPTION_DEAD,
                desc = L.CAREBUTTON_OPTION_DEAD_DESC,
                order = 5,
                func = function()
                    SetDead(true)
                end,
            },
            alive = {
                type = "execute",
                name = L.CAREBUTTON_OPTION_ALIVE,
                desc = L.CAREBUTTON_OPTION_ALIVE_DESC,
                order = 6,
                func = function()
                    SetDead(false)
                end,
            },
            test = {
                type = "execute",
                name = L.CAREBUTTON_OPTION_TEST,
                order = 7,
                func = function()
                    local info = M:Toast("dead")
                    info.key = info.key .. ":test"
                    Addon:ShowToast(info)
                end,
            },
            macro = {
                type = "execute",
                name = L.CAREBUTTON_OPTION_MACRO,
                desc = L.CAREBUTTON_OPTION_MACRO_DESC,
                order = 8,
                func = function()
                    Addon:CreateMacros(M, true)
                end,
            },
        },
    }
end
