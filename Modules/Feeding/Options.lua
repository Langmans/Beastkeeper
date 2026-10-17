local _, ns = ...

-- Feeding's page in the settings window (Kennel > Feeding): a switch per toast, and the button's
-- place back beside the pet frame.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("Feeding") --[[@as KennelFeeding]]

---A toggle for one toast's setting.
---@param key "content"|"unhappy"|"noFood"
---@param name string
---@param order number
---@return table
local function Toggle(key, name, order)
    local get, set = Kennel:Setting(M, key)
    return { type = "toggle", name = name, order = order, width = "full", get = get, set = set }
end

---@return table
function M:GetOptions()
    return {
        args = {
            content = Toggle("content", L.FEEDING_OPTION_CONTENT, 1),
            unhappy = Toggle("unhappy", L.FEEDING_OPTION_UNHAPPY, 2),
            noFood = Toggle("noFood", L.FEEDING_OPTION_NOFOOD, 3),
            resetPosition = {
                type = "execute",
                name = L.FEEDING_OPTION_RESET,
                order = 4,
                func = function()
                    M:Settings().position = nil
                    M:PlaceButton()
                end,
            },
        },
    }
end
