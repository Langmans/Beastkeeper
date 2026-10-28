local _, ns = ...

-- Ammo's page in the settings window (Beastkeeper > Ammo): the low and critical lines, the toasts'
-- switch, buying at a vendor and the stacks to keep without an ammo bag.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("Ammo") --[[@as AddonAmmo]]

---The count's look follows a changed line at once.
local function Changed()
    M:Update()
end

---A slider for one setting.
---@param key "low"|"critical"|"stacks"
---@param name string
---@param desc string
---@param order number
---@param max number
---@param step number
---@return table
local function Slider(key, name, desc, order, max, step)
    local get, set = Addon:Setting(M, key, Changed)
    return {
        type = "range",
        name = name,
        desc = desc,
        order = order,
        min = step == 1 and 1 or 0,
        max = max,
        step = step,
        get = get,
        set = set,
    }
end

---@return table
function M:GetOptions()
    local toastsGet, toastsSet = Addon:Setting(M, "toasts")
    local buyGet, buySet = Addon:Setting(M, "buy")
    return {
        args = {
            low = Slider("low", L.AMMO_OPTION_LOW, L.AMMO_OPTION_LOW_DESC, 1, 2000, 50),
            critical = Slider("critical", L.AMMO_OPTION_CRITICAL, L.AMMO_OPTION_CRITICAL_DESC, 2, 1000, 25),
            toasts = {
                type = "toggle",
                name = L.AMMO_OPTION_TOASTS,
                order = 3,
                width = "full",
                get = toastsGet,
                set = toastsSet,
            },
            buy = {
                type = "toggle",
                name = L.AMMO_OPTION_BUY,
                desc = L.AMMO_OPTION_BUY_DESC,
                order = 4,
                width = "full",
                get = buyGet,
                set = buySet,
            },
            stacks = Slider("stacks", L.AMMO_OPTION_STACKS, L.AMMO_OPTION_STACKS_DESC, 5, 10, 1),
        },
    }
end
