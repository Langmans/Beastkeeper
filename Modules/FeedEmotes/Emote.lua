local _, ns = ...

-- Building the emote text: which lines apply, the placeholders in a line, and the sentence in
-- front. No state of its own.

---@type Kennel
local Kennel = ns
local M = Kennel:GetModule("FeedEmotes") --[[@as KennelFeedEmotes]]
local SEX = Kennel.sex

---Adds the lines of `list`, if there is one, to the end of `pool`.
---@param pool string[]
---@param list string[]?
local function Append(pool, list)
    for _, line in ipairs(list or {}) do
        pool[#pool + 1] = line
    end
end

---What the lines are chosen by for one feeding: the pet's sex, the food's type and the pet's
---family ID (the same in every language, unlike the name); each nil when unknown or hidden.
---@param itemID number?
---@return KennelFeedSituation
local function SituationOf(itemID)
    local _, familyID = UnitCreatureFamily("pet")
    return {
        sex = M:PetSex(),
        foodType = itemID and M.FoodTypes[itemID] or nil,
        family = familyID and Kennel.Readable(familyID) and familyID or nil,
    }
end

---The lines that fit feeding the current pet this item: the player's own whose conditions hold
---(without their conditions), and the built-in ones. A line with {food} needs the food's name; so
---do the whole sentences (emotes.whole, emotes.wholeFamily), which join only when it is known.
---@param itemID number?
---@param foodName string?
---@return string[] own
---@return string[] builtIn
function M:LinePools(itemID, foodName)
    local emotes = self:LinesInUse().emotes
    ---@type string[], string[]
    local own, builtIn = {}, {}
    local situation = SituationOf(itemID)
    for _, line in ipairs(self:CustomLines()) do
        -- A saved line with a tag this version does not know is skipped.
        local tags, text = self.ParseCustomLine(line)
        if tags and self.ConditionsHold(tags, situation) and (foodName or not text:find("{food}", 1, true)) then
            own[#own + 1] = text
        end
    end
    Append(builtIn, emotes.any)
    if situation.sex == SEX.male then
        Append(builtIn, emotes.male)
    elseif situation.sex == SEX.female then
        Append(builtIn, emotes.female)
    end
    local group = itemID and self.FoodGroups[itemID]
    if group then Append(builtIn, emotes.food[group]) end
    if situation.foodType and emotes.foodType then Append(builtIn, emotes.foodType[situation.foodType]) end
    if situation.family then Append(builtIn, emotes.family[situation.family]) end
    if foodName then
        Append(builtIn, emotes.whole)
        if situation.family and emotes.wholeFamily then Append(builtIn, emotes.wholeFamily[situation.family]) end
    end
    return own, builtIn
end

---Every fitting line, own and built-in together: what an even chance picks from.
---@param itemID number?
---@param foodName string?
---@return string[]
function M:EmotePool(itemID, foodName)
    local own, builtIn = self:LinePools(itemID, foodName)
    Append(own, builtIn)
    return own
end

---Picks the line for one emote, or nil for none. Chance 0: every fitting line counts the same.
---Above 0: a roll at or under the chance wants an own line, above it a built-in one (100: own
---lines only). When an own line is wanted but none fits, customFallback decides: a built-in line,
---or none (the emote then only says who was fed what).
---@param itemID number?
---@param foodName string?
---@return string?
function M:PickLine(itemID, foodName)
    local settings = self:Settings()
    local own, builtIn = self:LinePools(itemID, foodName)
    ---@type string[]
    local pool
    if settings.customChance == 0 then
        pool = self:EmotePool(itemID, foodName)
    elseif math.random(100) <= settings.customChance then
        pool = (#own > 0 or not settings.customFallback) and own or builtIn
    else
        -- A language always has built-in lines; own ones stand in if it ever has none.
        pool = #builtIn > 0 and builtIn or own
    end
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

---"male", "female", or nil when the pet's sex is unknown or the player wants its name.
---@return "male"|"female"|nil
local function PronounSex()
    if M:Settings().petName then return nil end
    local sex = M:PetSex()
    return sex == SEX.male and "male" or sex == SEX.female and "female" or nil
end

---Replaces the placeholders in an emote line. {pet} is the pet's name, {food} the food, {a} its
---article. Any other {token} is one of the language's pronouns ({he} -> he/she); without a known
---sex, or for a token the language does not define, it becomes the pet's name, which reads right
---in every language. A pronoun whose name form differs ({his} -> "Fluffy's") gives it as
---`unknown`: a format with %s for the name, or a function of the name.
---@param line string
---@param pet string
---@param food string?
---@param article string?
---@return string
function M:FillPlaceholders(line, pet, food, article)
    local sex = PronounSex()
    local pronouns = self:LinesInUse().pronouns or {}
    ---@param token string
    ---@return string
    local function Replace(token)
        if token == "food" and food then return food end
        if token == "a" and article then return article end
        local words = token ~= "pet" and pronouns[token]
        if not words then return pet end
        if sex then return words[sex] end
        local unknown = words.unknown
        if type(unknown) == "string" then return unknown:format(pet) end
        return unknown and unknown(pet) or pet
    end
    return (line:gsub("{([^}]+)}", Replace))
end

---Whether `line` is one of the language's whole sentences, for any pet or for one family.
---@param line string
---@return boolean
local function IsWhole(line)
    local emotes = M:LinesInUse().emotes
    local lists = { emotes.whole or {} }
    for _, list in pairs(emotes.wholeFamily or {}) do
        lists[#lists + 1] = list
    end
    for _, list in ipairs(lists) do
        for _, whole in ipairs(list) do
            if whole == line then return true end
        end
    end
    return false
end

---The sentence in front of the line: the feed sentence or one of the language's openings, picked
---at random with the feed sentence counting as one of them; without a known food, always the plain
---one.
---@param pet string
---@param food string? the item link, or the plain name without one
---@param article string?
---@return string
local function Opening(pet, food, article)
    local lines = M:LinesInUse()
    if not food then return lines.feedNoFood:format(pet) end
    local openings = lines.emotes.openings or {}
    local chosen = openings[math.random(#openings + 1)]
    if chosen then return M:FillPlaceholders(chosen, pet, food, article) .. " " end
    local feed = lines.feed
    if type(feed) == "function" then return feed(pet, food) end
    return feed:format(pet, food)
end

---The full /emote text, or nil when the pet's name is unavailable. Usually an opening followed by
---a line; a whole sentence, when that is the line picked, stands alone.
---@param itemID number?
---@return string?
function M:BuildEmote(itemID)
    local pet = UnitName("pet")
    if not pet or not Kennel.Readable(pet) then return nil end
    ---@type string?, string?
    local name, link
    if itemID then
        name, link = C_Item.GetItemInfo(itemID)
    end
    local food = link or name
    local article = self:LinesInUse().article
    local a = name and article and article(name) or nil
    local line = self:PickLine(itemID, name)
    if line and IsWhole(line) then return self:FillPlaceholders(line, pet, food, a) end
    local text = Opening(pet, food, a)
    -- No line: the sentence alone, without the space the openings end in.
    if not line then return (text:gsub("%s+$", "")) end
    return text .. self:FillPlaceholders(line, pet, name)
end
