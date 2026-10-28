local _, ns = ...

-- BeastMap's page (Beastkeeper > Beast Map), also shown under HandyNotes' plugins: which beasts get a
-- pin. HandyNotes keeps the table for the session, so each toggle reads the profile in use when
-- asked rather than holding on to one.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("BeastMap") --[[@as BeastkeeperBeastMap]]

---@alias BeastkeeperBeastMapSetting "pins"|"mapButton"|"usefulOnly"|"gaps"|"aboveLevel"|"untilTame"|"levelToast"|"levelChat"|"tooltip"|"rareToast"|"trainers"|"stables"

-- How far a refining option sits in from the one it refines, and how wide it is then (AceConfig's
-- widths, in units of its column).
local INDENT, INDENTED_WIDTH = 0.15, 3

---A toggle for one setting; changing it redraws the pins.
---@param key BeastkeeperBeastMapSetting
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

---A toggle that refines `parent`'s: indented under it (an empty line part before it), greyed
---while `parent` is off. Adds the toggle and its indent to `args`.
---@param args table
---@param key BeastkeeperBeastMapSetting
---@param parent BeastkeeperBeastMapSetting
---@param name string
---@param desc string
---@param order number
local function Refining(args, key, parent, name, desc, order)
    args[key .. "Indent"] = { type = "description", name = "", width = INDENT, order = order - 0.001 }
    local toggle = Toggle(key, name, desc, order)
    toggle.width = INDENTED_WIDTH
    toggle.disabled = function()
        return not M:Settings()[parent]
    end
    args[key] = toggle
end

---@return table
function M:GetOptions()
    local args = {
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
        levelToast = Toggle("levelToast", L.BEASTMAP_OPTION_TOAST, L.BEASTMAP_OPTION_TOAST_DESC, 4),
        tooltip = Toggle("tooltip", L.BEASTMAP_OPTION_TOOLTIP, L.BEASTMAP_OPTION_TOOLTIP_DESC, 5),
        rareToast = Toggle("rareToast", L.BEASTMAP_OPTION_RARE, L.BEASTMAP_OPTION_RARE_DESC, 6),
        trainers = Toggle("trainers", L.BEASTMAP_OPTION_TRAINERS, L.BEASTMAP_OPTION_TRAINERS_DESC, 3.5),
        stables = Toggle("stables", L.BEASTMAP_OPTION_STABLES, L.BEASTMAP_OPTION_STABLES_DESC, 3.6),
    }
    Refining(args, "gaps", "usefulOnly", L.BEASTMAP_OPTION_GAPS, L.BEASTMAP_OPTION_GAPS_DESC, 1.1)
    Refining(args, "aboveLevel", "usefulOnly", L.BEASTMAP_OPTION_ABOVE, L.BEASTMAP_OPTION_ABOVE_DESC, 1.2)
    Refining(args, "untilTame", "usefulOnly", L.BEASTMAP_OPTION_UNTIL_TAME, L.BEASTMAP_OPTION_UNTIL_TAME_DESC, 1.3)
    Refining(args, "levelChat", "levelToast", L.BEASTMAP_OPTION_CHAT, L.BEASTMAP_OPTION_CHAT_DESC, 4.1)
    return { args = args }
end
