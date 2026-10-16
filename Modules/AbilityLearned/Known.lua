local _, ns = ...

-- What this character has learned, per character (the namespace's char): every learn the module
-- saw (history), the highest rank known per ability (known), from those learns and from the
-- Beast Training window, and how each pet stood when last seen (pets: training points total,
-- level, loyalty level). From that, what the pet out can still teach: said in chat when a pet is
-- summoned or tamed ("Fluffy can teach you: Claw (Rank 3)."), and on the page's button.
--
-- Until Beast Training has been read once (trainingRead), an ability missing from what is known
-- may simply not have been seen yet, so the hint then asks to open it once.
--
-- On WoW: Forever, Beast Training is the trainer window without an NPC; a pet trainer's is the same
-- window with one, selling ranks the hunter does not have yet, and is left alone. Each row of
-- Beast Training is a rank the hunter has learned. GetTrainerServiceInfo gives the name, not the
-- rank, so the row's spell comes from a hidden tooltip and the rank from that spell.

---@type Kennel
local Kennel = ns
local L = Kennel.L
local M = Kennel:GetModule("AbilityLearned") --[[@as KennelAbilityLearned]]

local HISTORY_MAX = 200
local BEAST_TRAINING_ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"
-- The loyalty name's colour runs from the friendly to the exalted reputation colour.
local FRIENDLY, EXALTED = { 0, 0.8, 0 }, { 0, 0.8, 0.8 }

-- The list said last for each pet, so summoning it again stays quiet until there is news.
---@type table<string, string>
local lastSaid = {}

local scanTip = CreateFrame("GameTooltip", "KennelScanTooltip", nil, "GameTooltipTemplate")

---This character's data.
---@return KennelAbilityLearnedChar
local function Char()
    return M.db.char --[[@as KennelAbilityLearnedChar]]
end

---The number in a rank text, whatever the language calls it: "Rank 2", "Rang 2", "2 레벨" -> 2.
---A spell without ranks counts as rank 1.
---@param rank string?
---@return number
local function RankNumber(rank)
    return tonumber(rank and rank:match("%d+")) or 1
end

---Records that this character knows an ability at a rank; a lower rank never replaces a higher.
---@param name string
---@param rank number
function M:MarkKnown(name, rank)
    local known = Char().known
    if rank > (known[name] or 0) then known[name] = rank end
end

---Adds a learn to the history, keeping the last HISTORY_MAX, and to what is known.
---@param entry KennelLearnEntry
function M:RecordLearn(entry)
    local history = Char().history
    history[#history + 1] = entry
    while #history > HISTORY_MAX do
        table.remove(history, 1)
    end
    self:MarkKnown(entry.name, RankNumber(entry.rank))
end

---One history line: "2026-10-07 14:03  Claw (Rank 2), from Fluffy, Darkshore".
---@param entry KennelLearnEntry
---@return string
local function HistoryLine(entry)
    ---@type string
    local line = date("%Y-%m-%d %H:%M", entry.t) .. "  " .. entry.name
    if entry.rank then line = line .. " (" .. entry.rank .. ")" end
    if entry.pet then line = line .. ", " .. L.ABILITYLEARNED_HISTORY_FROM:format(entry.pet) end
    if entry.zone then line = line .. ", " .. entry.zone end
    return line
end

---The history as lines, newest first.
---@return string
function M:HistoryText()
    local history = Char().history
    if #history == 0 then return L.ABILITYLEARNED_HISTORY_EMPTY end
    ---@type string[]
    local lines = {}
    for i = #history, 1, -1 do
        lines[#lines + 1] = HistoryLine(history[i])
    end
    return table.concat(lines, "\n")
end

---The spell behind a trainer row, through the hidden tooltip.
---@param index number
---@return number?
local function RowSpellID(index)
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:SetTrainerService(index)
    local _, spellID = scanTip:GetSpell()
    scanTip:Hide()
    return spellID
end

---Reads the hunter's learned ranks from Beast Training. A row that cannot be read is skipped.
function M:ReadBeastTraining()
    if UnitExists("npc") then return end
    local read = 0
    for index = 1, GetNumTrainerServices() do
        local ok, name, kind = pcall(GetTrainerServiceInfo, index)
        local spellID = ok and type(name) == "string" and kind ~= "header" and RowSpellID(index)
        if spellID then
            local _, _, rank = Kennel.SpellInfo(spellID)
            self:MarkKnown(name, RankNumber(rank))
            read = read + 1
        end
    end
    if read > 0 then Char().trainingRead = true end
end

---The wild abilities the pet out has at a higher rank than this character knows, as
---"Claw (Rank 3)", sorted; and whether one of them has no known rank at all.
---@return string[] teachable
---@return boolean unsure
local function Teachable()
    local known = Char().known
    ---@type string[]
    local list = {}
    local unsure = false
    for name, spell in pairs(Kennel.PetSpells()) do
        if M.IsWildAbility(name) and RankNumber(spell.rank) > (known[name] or 0) then
            list[#list + 1] = spell.rank and ("%s (%s)"):format(name, spell.rank) or name
            unsure = unsure or known[name] == nil
        end
    end
    table.sort(list)
    return list, unsure
end

---Says what `pet` can teach, and asks for Beast Training while a rank may be unknown.
---@param pet string
---@param list string[]
---@param unsure boolean
local function Say(pet, list, unsure)
    Kennel:Print(L.ABILITYLEARNED_TEACHES:format(pet, table.concat(list, ", ")))
    if unsure and not Char().trainingRead then Kennel:Print(L.ABILITYLEARNED_OPEN_TRAINING) end
end

---After a summon or the login wait: says what the pet out can teach, unless hints are off, it is
---nothing, or it was said for this pet already.
function M:CheckHints()
    if not self.ready or not self:Settings().hints or not UnitExists("pet") then return end
    local pet = UnitName("pet")
    local list, unsure = Teachable()
    local said = table.concat(list, ", ")
    if said == "" or lastSaid[pet] == said then return end
    lastSaid[pet] = said
    Say(pet, list, unsure)
end

---The loyalty level in the game's loyalty text ("Loyalty Level 5 (Faithful)" -> 5), or nil.
---@param text string?
---@return number?
local function LoyaltyLevel(text)
    return tonumber(text and text:match("%d+"))
end

---The colour code of a loyalty level, along the reputation colours: friendly green at loyalty
---level 1 to exalted teal at 6.
---@param level number
---@return string
local function LoyaltyColor(level)
    local t = (math.min(math.max(level, 1), 6) - 1) / 5
    ---@type number[]
    local rgb = {}
    for i = 1, 3 do
        rgb[i] = math.floor((FRIENDLY[i] + (EXALTED[i] - FRIENDLY[i]) * t) * 255 + 0.5)
    end
    return ("|cff%02x%02x%02x"):format(rgb[1], rgb[2], rgb[3])
end

---The game's loyalty text with the level's name (in parentheses) in its colour.
---@param text string
---@param level number
---@return string
local function ColorLoyalty(text, level)
    return (text:gsub("%((.-)%)", "(" .. LoyaltyColor(level) .. "%1|r)"))
end

---The level's name alone ("Faithful"), in its colour; the whole text when it names none.
---@param text string
---@param level number
---@return string
local function LoyaltyName(text, level)
    local name = text:match("%((.-)%)")
    return name and LoyaltyColor(level) .. name .. "|r" or text
end

---A toast about the pet out's growth, of `kind` ("points" or "loyalty").
---@param kind string
---@param title string
---@param text string
---@param hint string?
---@param sound KennelSound?
---@return KennelToastInfo
local function GrowthToast(kind, title, text, hint, sound)
    return {
        key = "AbilityLearned:" .. kind,
        type = "AbilityLearned:" .. kind,
        source = M.title,
        title = title,
        text = text,
        hint = hint,
        icon = BEAST_TRAINING_ICON,
        portrait = "pet",
        sound = sound,
    }
end

---Compares the pet out with how it stood last time (kept per pet name): a toast when its total of
---training points rose, naming the cause when there is one (a level-up, a higher loyalty level),
---and one when its loyalty level dropped, with the points that cost. A pet seen for the first time
---is only noted; one summoned again is told what changed while it was away. Spending points at
---Beast Training changes only what is used, not the total, and says nothing; so does a level-up
---at loyalty level 1, which brings no points.
function M:CheckGrowth()
    if not self.ready then return end
    local free, total = Kennel.PetTrainingPoints()
    if not total then return end
    local pet, level = UnitName("pet"), UnitLevel("pet")
    local loyaltyText = GetPetLoyalty and GetPetLoyalty()
    local loyalty = LoyaltyLevel(loyaltyText)
    local pets = Char().pets
    local before = pets[pet]
    pets[pet] = { total = total, level = level, loyalty = loyalty }
    if not before then return end
    local settings = self:Settings()
    local change = total - before.total
    local loyaltyUp = (loyalty and before.loyalty and loyalty > before.loyalty) == true
    if loyalty and before.loyalty and loyalty < before.loyalty then
        if not settings.loyalty then return end
        local text = L.ABILITYLEARNED_LOYALTY_DROP_TEXT:format(ColorLoyalty(loyaltyText, loyalty))
        local lost = change < 0 and L.ABILITYLEARNED_POINTS_LOST:format(-change, free) or nil
        local sound = self:Sound("loyaltySound", "WOUND")
        Kennel:ShowToast(GrowthToast("loyalty", L.ABILITYLEARNED_LOYALTY_DROP:format(pet), text, lost, sound))
        return
    end
    if change <= 0 or not settings.points then return end
    local levelUp = level > before.level
    ---@type string, string
    local title, text
    if levelUp == loyaltyUp then
        title = L.ABILITYLEARNED_POINTS_GAINED:format(pet, change)
        text = L.ABILITYLEARNED_POINTS_FREE:format(free)
    else
        -- loyaltyUp is only true when the loyalty level (and so its text) was read.
        local newLoyalty = loyalty --[[@as number]]
        title = levelUp and L.ABILITYLEARNED_LEVEL_UP:format(pet, level)
            or L.ABILITYLEARNED_LOYALTY_UP:format(pet, newLoyalty, LoyaltyName(loyaltyText, newLoyalty))
        text = L.ABILITYLEARNED_POINTS_CAUSED:format(change, free)
    end
    Kennel:ShowToast(GrowthToast("points", title, text, nil, self:Sound("pointsSound", "AGGRO")))
end

---The page's button: what the pet out can teach, whenever asked, also when that is nothing.
function M:ReportTeachable()
    if not UnitExists("pet") then
        Kennel:Print(L.ABILITYLEARNED_NO_PET)
        return
    end
    local pet = UnitName("pet")
    local list, unsure = Teachable()
    if #list == 0 then
        Kennel:Print(L.ABILITYLEARNED_NOTHING:format(pet))
    else
        Say(pet, list, unsure)
    end
end
