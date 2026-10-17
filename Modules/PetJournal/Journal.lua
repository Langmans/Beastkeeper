local _, ns = ...

-- A pet's journal as lines of text, for its page (Options.lua) and for its tooltip (Tooltip.lua):
-- when and where it came, level and loyalty, the time out, deaths, the loyalty forecast, its
-- abilities and what it could still teach. The tooltip leaves out the level and the abilities,
-- which the game's own tooltip and the page already show.

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

---A pet's journal as lines; the same table each time, refilled. Empty for a pet not in it.
---@param key string
---@param brief boolean? for a tooltip: without the level and the abilities
---@return string[]
function M:JournalLines(key, brief)
    wipe(lines)
    local entry = self:Pets()[key]
    if not entry then return lines end
    local first = entry.first
    local when = date("%Y-%m-%d %H:%M", first.t)
    -- The pet number and the NPC ID come from the same GUID: a pet with an entry has both.
    if first.tamed then
        lines[#lines + 1] = L.PETJOURNAL_TAMED:format(when, first.zone or "?", first.npc or 0)
    else
        lines[#lines + 1] = L.PETJOURNAL_FIRST:format(when, first.zone or "?")
    end
    if not brief then
        local loyalty = entry.loyalty and Kennel.LoyaltyLabel(entry.loyalty, entry.loyaltyName) or "?"
        lines[#lines + 1] = L.PETJOURNAL_LEVEL:format(entry.level or 0, entry.family or "?", loyalty)
    end
    lines[#lines + 1] = L.PETJOURNAL_OUT:format(Duration(self:Out(key)))
    if entry.deaths > 0 then lines[#lines + 1] = L.PETJOURNAL_DIED:format(entry.deaths) end
    lines[#lines + 1] = Forecast(key, entry)
    if not brief and #entry.abilities > 0 then
        lines[#lines + 1] = L.PETJOURNAL_ABILITIES:format(table.concat(entry.abilities, ", "))
    end
    lines[#lines + 1] = CanTeachLine(entry)
    return lines
end

---A pet's journal, for its page.
---@param key string
---@return string
function M:JournalText(key)
    return table.concat(self:JournalLines(key), "\n")
end
