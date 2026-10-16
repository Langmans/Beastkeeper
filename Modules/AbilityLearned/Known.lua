local _, ns = ...

-- What this character has learned, per character (the namespace's char): every learn the module
-- saw (history), the highest rank known per ability (known), from those learns and from the
-- Beast Training window, and each pet's training points total (points). From that, what the pet out can still teach: said in chat when a pet is
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

---When the pet out has more training points in total than last time: a toast saying how many it
---gained and how many are free. Each pet's total is kept by name, so a pet seen for the first time
---is only noted, and one summoned again is told what it gained while away. Spending points at
---Beast Training changes only what is used, not the total, and says nothing.
function M:CheckPoints()
    if not self.ready then return end
    local free, total = Kennel.PetTrainingPoints()
    if not total then return end
    local pet = UnitName("pet")
    local seen = Char().points
    local before = seen[pet]
    seen[pet] = total
    if not before or total <= before or not self:Settings().points then return end
    Kennel:ShowToast({
        key = "AbilityLearned:points",
        type = "AbilityLearned:points",
        source = self.title,
        title = L.ABILITYLEARNED_POINTS_GAINED:format(pet, total - before),
        text = L.ABILITYLEARNED_POINTS_FREE:format(free),
        icon = BEAST_TRAINING_ICON,
        portrait = "pet",
        sound = self:Sound("pointsSound", true),
    })
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
