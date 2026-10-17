local _, ns = ...

-- BeastMap's page (Kennel > Beast Map), also shown under HandyNotes' plugins: which beasts get a
-- pin. HandyNotes keeps the table for the session, so each toggle reads the profile in use when
-- asked rather than holding on to one.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("BeastMap") --[[@as KennelBeastMap]]

---A toggle for one setting; changing it redraws the pins.
---@param key "pins"|"mapButton"|"usefulOnly"|"gaps"|"aboveLevel"|"levelToast"
---@param name string
---@param desc string
---@param order number
---@return table
local function Toggle(key, name, desc, order)
    return {
        type = "toggle",
        name = name,
        desc = desc,
        order = order,
        width = "full",
        get = function()
            return M:Settings()[key]
        end,
        ---@param _ table AceConfig's info about the option
        ---@param value boolean
        set = function(_, value)
            M:Settings()[key] = value
            if M:IsEnabled() then M:Refresh() end
        end,
    }
end

---@return table
function M:GetOptions()
    return {
        args = {
            missing = {
                type = "description",
                name = L.BEASTMAP_NO_HANDYNOTES,
                order = 0,
                hidden = function()
                    return HandyNotes ~= nil
                end,
            },
            pins = Toggle("pins", L.BEASTMAP_OPTION_PINS, L.BEASTMAP_OPTION_PINS_DESC, 0.5),
            mapButton = Toggle("mapButton", L.BEASTMAP_OPTION_BUTTON, L.BEASTMAP_OPTION_BUTTON_DESC, 0.6),
            usefulOnly = Toggle("usefulOnly", L.BEASTMAP_OPTION_USEFUL, L.BEASTMAP_OPTION_USEFUL_DESC, 1),
            gaps = Toggle("gaps", L.BEASTMAP_OPTION_GAPS, L.BEASTMAP_OPTION_GAPS_DESC, 2),
            aboveLevel = Toggle("aboveLevel", L.BEASTMAP_OPTION_ABOVE, L.BEASTMAP_OPTION_ABOVE_DESC, 3),
            levelToast = Toggle("levelToast", L.BEASTMAP_OPTION_TOAST, L.BEASTMAP_OPTION_TOAST_DESC, 4),
        },
    }
end
