local _, ns = ...

-- The player's own emote lines. A line is saved as one string, maybe starting with conditions in
-- brackets: "[cat,wolf,fish] Good hunter!". Tags of one group match if any holds (cat or wolf);
-- every group named must match (and fish). The tags are English on every client language.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("FeedEmotes") --[[@as KennelFeedEmotes]]

-- An emote is at most 255 bytes, and "feeds <pet> a <item link>. " in front can take about 100.
-- The conditions are not sent, so they do not count.
M.CUSTOM_LINE_MAX = 150

---Every condition, in the order a saved line lists them: sex, food type, family by ID.
---@type KennelFeedCondition[]
M.Conditions = {
    { tag = "male", group = "sex", value = 2 },
    { tag = "female", group = "sex", value = 3 },
}
for _, foodType in ipairs({ "bread", "meat", "fish", "cheese", "fruit", "fungus" }) do
    M.Conditions[#M.Conditions + 1] = { tag = foodType, group = "foodType", value = foodType }
end
---@type KennelFeedCondition[]
local families = {}
for name, id in pairs(M.Family) do
    families[#families + 1] = { tag = name:lower(), group = "family", value = id }
end
---Families by ID: their values are numbers.
---@param a KennelFeedCondition
---@param b KennelFeedCondition
---@return boolean
local function ByID(a, b)
    ---@type number, number
    local left, right = a.value, b.value
    return left < right
end
table.sort(families, ByID)
for _, condition in ipairs(families) do
    M.Conditions[#M.Conditions + 1] = condition
end

---Tag -> its condition.
---@type table<string, KennelFeedCondition>
M.ConditionByTag = {}
for _, condition in ipairs(M.Conditions) do
    M.ConditionByTag[condition.tag] = condition
end

---Every tag, for the message about an unknown one.
---@return string
local function AllTags()
    ---@type string[]
    local tags = {}
    for _, condition in ipairs(M.Conditions) do
        tags[#tags + 1] = condition.tag
    end
    return table.concat(tags, ", ")
end

---Splits a line into its conditions and its text.
---@param line string
---@return table<string, true>? tags empty for none; nil when one is unknown
---@return string text the line without its conditions; the unknown tag when tags is nil
function M.ParseCustomLine(line)
    local list, text = line:match("^%[([^%]]*)%]%s*(.*)$")
    if not list then return {}, line end
    ---@type table<string, true>
    local tags = {}
    for word in list:gmatch("[^,%s]+") do
        word = word:lower()
        if not M.ConditionByTag[word] then return nil, word end
        tags[word] = true
    end
    return tags, text
end

---A line as it is saved: its conditions in a fixed order, then the text.
---@param tags table<string, true>
---@param text string
---@return string
function M.FormatCustomLine(tags, text)
    ---@type string[]
    local list = {}
    for _, condition in ipairs(M.Conditions) do
        if tags[condition.tag] then list[#list + 1] = condition.tag end
    end
    if #list == 0 then return text end
    return "[" .. table.concat(list, ",") .. "] " .. text
end

---Whether a line's conditions hold for one feeding.
---@param tags table<string, true>
---@param situation KennelFeedSituation
---@return boolean
function M.ConditionsHold(tags, situation)
    ---@type table<string, true>, table<string, true>
    local named, met = {}, {}
    for tag in pairs(tags) do
        local condition = M.ConditionByTag[tag]
        named[condition.group] = true
        if situation[condition.group] == condition.value then met[condition.group] = true end
    end
    for group in pairs(named) do
        if not met[group] then return false end
    end
    return true
end

---Trims and checks a line, merges in extra conditions, and gives it as it is saved. skip is the
---index of the line being replaced, which may equal the result.
---@param text string?
---@param extraTags table<string, true>?
---@param skip number?
---@return boolean ok
---@return string result the line to save, or why it was refused
local function Prepare(text, extraTags, skip)
    local tags, body = M.ParseCustomLine((text or ""):match("^%s*(.-)%s*$"))
    if not tags then return false, L.FEEDEMOTES_UNKNOWN_CONDITION:format(body, AllTags()) end
    for tag in pairs(extraTags or {}) do
        tags[tag] = true
    end
    if body == "" then return false, L.FEEDEMOTES_EMPTY end
    if #body > M.CUSTOM_LINE_MAX then return false, L.FEEDEMOTES_TOO_LONG:format(M.CUSTOM_LINE_MAX) end
    -- | starts an escape sequence in chat; a stray one can break the message.
    if body:find("|", 1, true) then return false, L.FEEDEMOTES_BAR end
    local line = M.FormatCustomLine(tags, body)
    for index, existing in ipairs(M:CustomLines()) do
        if existing == line and index ~= skip then return false, L.FEEDEMOTES_DUPLICATE end
    end
    return true, line
end

---Checks a line, then saves it at the end of the list.
---@param text string? may start with [conditions]
---@param extraTags table<string, true>? conditions ticked on the page
---@return boolean added
---@return string result the saved line, or why it was refused
function M:AddCustomLine(text, extraTags)
    local ok, result = Prepare(text, extraTags)
    if ok then
        local lines = self:CustomLines()
        lines[#lines + 1] = result
    end
    return ok, result
end

---Checks a line, then saves it in place of the one at index.
---@param index number
---@param text string?
---@return boolean replaced
---@return string result the saved line, or why it was refused
function M:ReplaceCustomLine(index, text)
    local lines = self:CustomLines()
    if not lines[index] then return false, L.FEEDEMOTES_NO_SUCH:format(index) end
    local ok, result = Prepare(text, nil, index)
    if ok then lines[index] = result end
    return ok, result
end

---Removes the line at index; gives it, or nil when there is none.
---@param index number
---@return string?
function M:RemoveCustomLine(index)
    local lines = self:CustomLines()
    if not lines[index] then return nil end
    return table.remove(lines, index)
end

---The placeholders a line can use in the client's language, such as "{pet}, {food}, {he}".
---@return string
function M:PlaceholderList()
    ---@type string[]
    local tokens = {}
    for token in pairs(self:LinesInUse().pronouns or {}) do
        tokens[#tokens + 1] = "{" .. token .. "}"
    end
    table.sort(tokens)
    table.insert(tokens, 1, "{food}")
    table.insert(tokens, 1, "{pet}")
    return table.concat(tokens, ", ")
end
