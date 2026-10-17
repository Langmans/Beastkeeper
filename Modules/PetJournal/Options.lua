local _, ns = ...

-- PetJournal's page (Kennel > Pet Journal): a choice of the character's pets, the pet out first
-- chosen, and its journal below.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("PetJournal") --[[@as KennelPetJournal]]

local HIGHEST_LOYALTY = 6

---"1 h 5 min", or "16 min".
---@param seconds number
---@return string
local function Duration(seconds)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    if hours > 0 then return L.PETJOURNAL_HOURS:format(hours, minutes % 60) end
    return L.PETJOURNAL_MINUTES:format(minutes)
end

---The line about the next loyalty level: from the average time out between the rises it saw.
---@param key string
---@param entry KennelJournalEntry
---@return string?
local function Forecast(key, entry)
    local loyalty = entry.loyalty
    if not loyalty or loyalty >= HIGHEST_LOYALTY then return nil end
    local total, count = 0, 0
    for level, at in pairs(entry.rises) do
        local before = entry.rises[level - 1]
        if before then
            total, count = total + at - before, count + 1
        end
    end
    local last = entry.rises[loyalty]
    if count == 0 or not last then return L.PETJOURNAL_NEXT_UNKNOWN end
    local left = last + total / count - M:Out(key)
    if left <= 0 then return L.PETJOURNAL_NEXT_NOW end
    return L.PETJOURNAL_NEXT_IN:format(Duration(left))
end

-- The journal's lines and what the pet could teach, refilled for each look.
---@type string[], string[]
local lines, teach = {}, {}

---The line of ranks the pet could still teach this character, from Ability Learned's known ranks;
---nil when it teaches nothing new or Ability Learned is off.
---@param entry KennelJournalEntry
---@return string?
local function CanTeachLine(entry)
    local known = Kennel:GetModule("AbilityLearned", true) --[[@as KennelAbilityLearned?]]
    if not known or not known:IsEnabled() or not entry.ranks then return nil end
    wipe(teach)
    for name, rank in pairs(entry.ranks) do
        if known:CanTeach(name, rank) then teach[#teach + 1] = ("%s (%s)"):format(name, rank) end
    end
    if #teach == 0 then return nil end
    table.sort(teach)
    return L.PETJOURNAL_TEACH:format(table.concat(teach, ", "))
end

---A pet's journal.
---@param key string
---@return string
function M:JournalText(key)
    local entry = self:Pets()[key]
    if not entry then return "" end
    wipe(lines)
    local first = entry.first
    local when = date("%Y-%m-%d %H:%M", first.t)
    -- The pet number and the NPC ID come from the same GUID: a pet with an entry has both.
    if first.tamed then
        lines[#lines + 1] = L.PETJOURNAL_TAMED:format(when, first.zone or "?", first.npc or 0)
    else
        lines[#lines + 1] = L.PETJOURNAL_FIRST:format(when, first.zone or "?")
    end
    local loyalty = entry.loyalty and Kennel.LoyaltyLabel(entry.loyalty, entry.loyaltyName) or "?"
    lines[#lines + 1] = L.PETJOURNAL_LEVEL:format(entry.level or 0, entry.family or "?", loyalty)
    lines[#lines + 1] = L.PETJOURNAL_OUT:format(Duration(self:Out(key)))
    if entry.deaths > 0 then lines[#lines + 1] = L.PETJOURNAL_DIED:format(entry.deaths) end
    lines[#lines + 1] = Forecast(key, entry)
    if #entry.abilities > 0 then
        lines[#lines + 1] = L.PETJOURNAL_ABILITIES:format(table.concat(entry.abilities, ", "))
    end
    lines[#lines + 1] = CanTeachLine(entry)
    return table.concat(lines, "\n")
end

---The pet chosen on the page: the one picked, else the pet out, else any.
---@return string?
function M:Chosen()
    local pets = self:Pets()
    if self.picked and pets[self.picked] then return self.picked end
    if self.current then return self.current end
    return next(pets)
end

---"Fluffy (level 15 Cat)", for the choice of pet.
---@param entry KennelJournalEntry
---@return string
local function PetLabel(entry)
    return L.PETJOURNAL_PET_ENTRY:format(entry.name or "?", entry.level or 0, entry.family or "?")
end

---@return table
function M:GetOptions()
    return {
        args = {
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
