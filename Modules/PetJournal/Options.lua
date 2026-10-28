local _, ns = ...

-- PetJournal's page (Beastkeeper > Pet Journal): the tooltip switch, a choice of the character's pets
-- (the pet out first chosen), and its journal below (Journal.lua).

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("PetJournal") --[[@as AddonPetJournal]]

---The pet chosen on the page: the one picked, else the pet out, else any.
---@return string?
function M:Chosen()
    local pets = self:Pets()
    if self.picked and pets[self.picked] then return self.picked end
    if self.current then return self.current end
    return next(pets)
end

---"Fluffy (level 15 Cat)", for the choice of pet.
---@param entry AddonJournalEntry
---@return string
local function PetLabel(entry)
    return L.PETJOURNAL_PET_ENTRY:format(entry.name or "?", entry.level or 0, entry.family or "?")
end

---@return table
function M:GetOptions()
    local tooltipGet, tooltipSet = Addon:Setting(M, "tooltip")
    return {
        args = {
            tooltip = {
                type = "toggle",
                name = L.PETJOURNAL_OPTION_TOOLTIP,
                desc = L.PETJOURNAL_OPTION_TOOLTIP_DESC,
                order = 0.5,
                width = "full",
                get = tooltipGet,
                set = tooltipSet,
            },
            pet = {
                type = "select",
                name = L.PETJOURNAL_PET,
                order = 1,
                width = "double",
                values = function()
                    ---@type table<string, string>
                    local names = {}
                    for key, entry in pairs(M:Pets()) do
                        names[key] = PetLabel(entry)
                    end
                    return names
                end,
                get = function()
                    return M:Chosen()
                end,
                ---@param _ table AceConfig's info about the option
                ---@param key string
                set = function(_, key)
                    M.picked = key
                end,
            },
            journal = {
                type = "description",
                order = 2,
                fontSize = "medium",
                name = function()
                    local key = M:Chosen()
                    return key and M:JournalText(key) or ""
                end,
            },
        },
    }
end
