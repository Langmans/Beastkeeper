local _, ns = ...

-- FeedEmotes' page in the settings window (Beastkeeper > Feed Emotes): the pet's name or he/she, the
-- pet's sex, an example, and the player's own lines with their conditions, edited in place.

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("FeedEmotes") --[[@as BeastkeeperFeedEmotes]]

local MYSTERY_MEAT = 12037
local SEX = { game = nil, male = Addon.sex.male, female = Addon.sex.female }
local EMOTE_COLOR = "|cffff8040"

-- The conditions ticked for the next new line, by tag.
---@type table<string, true>
local draft = {}

---A getter and setter for one profile setting (Beastkeeper:Setting).
---@param key string
---@return fun(): string|boolean|number get
---@return fun(info: table, value: string|boolean|number) set
local function Setting(key)
    return Addon:Setting(M, key)
end

---The condition boxes of one group, as a multiselect for the next new line. Families no hunter
---can tame on WoW: Forever are left out; a typed [chimaera] still works.
---@param group "sex"|"foodType"|"family"
---@param name string
---@param order number
---@return table
local function ConditionBoxes(group, name, order)
    ---@type table<string, string>
    local values = {}
    for _, condition in ipairs(M.Conditions) do
        if condition.group == group and not M.ExoticFamily[condition.value] then
            values[condition.tag] = L["FEEDEMOTES_COND_" .. condition.tag:upper()]
        end
    end
    return {
        type = "multiselect",
        name = name,
        order = order,
        values = values,
        ---@param _ table
        ---@param tag string
        ---@return boolean
        get = function(_, tag)
            return draft[tag] == true
        end,
        ---@param _ table
        ---@param tag string
        ---@param on boolean
        set = function(_, tag, on)
            draft[tag] = on or nil
        end,
    }
end

---Prints why a line was refused; nothing when it was saved.
---@param ok boolean
---@param result string
local function Report(ok, result)
    if not ok then M:Print(result) end
end

---The pet's sex choice: from the game, male or female, for the pet out.
---@return table
local function SexChoice()
    ---@type table<string, string>
    local names = { [Addon.sex.male] = "male", [Addon.sex.female] = "female" }
    return {
        type = "select",
        name = function()
            local pet = UnitName("pet")
            return Addon.PetNumber() and L.FEEDEMOTES_OPTION_SEX_FOR:format(pet) or L.FEEDEMOTES_OPTION_SEX_NONE
        end,
        desc = L.FEEDEMOTES_OPTION_SEX_DESC,
        order = 2,
        values = {
            game = L.FEEDEMOTES_OPTION_SEX_GAME,
            male = L.FEEDEMOTES_OPTION_SEX_MALE,
            female = L.FEEDEMOTES_OPTION_SEX_FEMALE,
        },
        sorting = { "game", "male", "female" },
        disabled = function()
            return Addon.PetNumber() == nil
        end,
        get = function()
            local petNumber = Addon.PetNumber()
            return petNumber and names[M:Char().petSex[petNumber]] or "game"
        end,
        ---@param _ table
        ---@param value "game"|"male"|"female"
        set = function(_, value)
            M:ChoosePetSex(SEX[value])
        end,
    }
end

---@return table
function M:GetOptions()
    local petNameGet, petNameSet = Setting("petName")
    local chanceGet, chanceSet = Setting("customChance")
    local fallbackGet, fallbackSet = Setting("customFallback")
    local lines = self:CustomLines()
    local shared = self:Char().sharedLines
    local args = {
        petName = {
            type = "toggle",
            name = L.FEEDEMOTES_OPTION_PET_NAME,
            desc = L.FEEDEMOTES_OPTION_PET_NAME_DESC,
            order = 1,
            width = "full",
            get = petNameGet,
            set = petNameSet,
        },
        sex = SexChoice(),
        test = {
            type = "execute",
            name = L.FEEDEMOTES_OPTION_TEST,
            desc = L.FEEDEMOTES_OPTION_TEST_DESC,
            order = 3,
            func = function()
                local text = M:BuildEmote(MYSTERY_MEAT)
                M:Print(text and EMOTE_COLOR .. UnitName("player") .. " " .. text .. "|r" or L.FEEDEMOTES_NO_PET)
            end,
        },
        own = { type = "header", name = L.FEEDEMOTES_OPTION_OWN, order = 10 },
        ownDesc = {
            type = "description",
            name = L.FEEDEMOTES_OPTION_OWN_DESC:format(self:PlaceholderList()),
            order = 11,
        },
        chance = {
            type = "range",
            name = L.FEEDEMOTES_OPTION_CHANCE,
            desc = L.FEEDEMOTES_OPTION_CHANCE_DESC,
            order = 12,
            min = 0,
            max = 100,
            step = 1,
            get = chanceGet,
            set = chanceSet,
        },
        fallback = {
            type = "toggle",
            name = L.FEEDEMOTES_OPTION_FALLBACK,
            desc = L.FEEDEMOTES_OPTION_FALLBACK_DESC,
            order = 13,
            width = "full",
            get = fallbackGet,
            set = fallbackSet,
        },
        shared = {
            type = "toggle",
            name = L.FEEDEMOTES_OPTION_SHARED,
            desc = L.FEEDEMOTES_OPTION_SHARED_DESC,
            order = 14,
            width = "full",
            get = function()
                return M:Char().sharedLines
            end,
            ---@param _ table
            ---@param value boolean
            set = function(_, value)
                M:Char().sharedLines = value
            end,
        },
        condSex = ConditionBoxes("sex", L.FEEDEMOTES_OPTION_COND_SEX, 20),
        condFood = ConditionBoxes("foodType", L.FEEDEMOTES_OPTION_COND_FOODTYPE, 21),
        condFamily = ConditionBoxes("family", L.FEEDEMOTES_OPTION_COND_FAMILY, 22),
        new = {
            type = "input",
            name = L.FEEDEMOTES_OPTION_NEW,
            desc = L.FEEDEMOTES_OPTION_NEW_DESC,
            order = 23,
            width = "full",
            get = function()
                return ""
            end,
            ---@param _ table
            ---@param text string
            set = function(_, text)
                local ok, result = M:AddCustomLine(text, draft)
                if ok then
                    wipe(draft)
                    M:Print(L.FEEDEMOTES_ADDED:format(#M:CustomLines(), result))
                end
                Report(ok, result)
            end,
        },
        list = {
            type = "header",
            name = (shared and L.FEEDEMOTES_OPTION_LIST_SHARED or L.FEEDEMOTES_OPTION_LIST_OWN):format(#lines),
            order = 30,
        },
        none = { type = "description", name = L.FEEDEMOTES_OPTION_NONE, order = 31, hidden = #lines > 0 },
    }
    for index, line in ipairs(lines) do
        args["line" .. index] = {
            type = "input",
            name = L.FEEDEMOTES_OPTION_LINE:format(index),
            order = 100 + 2 * index,
            width = "double",
            get = function()
                return line
            end,
            ---@param _ table
            ---@param text string
            set = function(_, text)
                Report(M:ReplaceCustomLine(index, text))
            end,
        }
        args["remove" .. index] = {
            type = "execute",
            name = L.FEEDEMOTES_OPTION_REMOVE,
            order = 101 + 2 * index,
            func = function()
                M:RemoveCustomLine(index)
            end,
        }
    end
    return { args = args }
end
