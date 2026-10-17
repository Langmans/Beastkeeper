local _, ns = ...

-- What this character has learned, per character (the namespace's char): every learn the module
-- saw (history), the ranks known per ability (ranks) and the highest (known), from those learns and from the
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

---Records that this character knows an ability at a rank: in the set of its ranks, and as the
---highest when it is. Returns whether that was news; the caller then tells (RanksKnown), once
---for a whole Beast Training window.
---@param name string
---@param rank number
---@return boolean
function M:MarkKnown(name, rank)
    local char = Char()
    local set = char.ranks[name]
    if not set then
        set = {}
        char.ranks[name] = set
    end
    if set[rank] then return false end
    set[rank] = true
    if rank > (char.known[name] or 0) then char.known[name] = rank end
    return true
end

---The highest rank of an ability this character knows, nil for none.
---@param name string the ability's name in the client's language
---@return number?
function M:HighestRank(name)
    return Char().known[name]
end

---Sends KENNEL_RANKS_KNOWN with the ranks that were news (docs\04-hooking.md).
---@param source "learn"|"training"
---@param ranks KennelKnownRank[]
local function RanksKnown(source, ranks)
    Kennel:SendMessage("KENNEL_RANKS_KNOWN", { module = M:GetName(), source = source, ranks = ranks })
end

---Whether this character knows an ability at exactly this rank. Ranks are separate spells, so a
---lower one can be missing below a higher one (it suits a young pet, or costs fewer points).
---@param name string
---@param rank number
---@return boolean
function M:HasRank(name, rank)
    local set = Char().ranks[name]
    return set ~= nil and set[rank] == true
end

---Adds a learn to the history, keeping the last HISTORY_MAX, and to what is known.
---@param entry KennelLearnEntry
function M:RecordLearn(entry)
    local history = Char().history
    history[#history + 1] = entry
    while #history > HISTORY_MAX do
        table.remove(history, 1)
    end
    local rank = RankNumber(entry.rank)
    if self:MarkKnown(entry.name, rank) then RanksKnown("learn", { { name = entry.name, rank = rank } }) end
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

---Whether Kennel's beast data (Data\Beasts.lua) has beast `npc` as a teacher of an ability's rank.
---@param name string the ability's name in the client's language
---@param rank number
---@param npc number
---@return boolean
local function KnownTeacher(name, rank, npc)
    local data = Kennel.data --[[@as KennelData]]
    for _, info in pairs(data.petAbilityRanks) do
        if info.rank == rank and Kennel.SpellInfo(info.ability) == name then
            for _, teacher in ipairs(info.teachers) do
                if teacher == npc then return true end
            end
            return false
        end
    end
    return false
end

---Says in chat which learns from a pet came from a beast the beast data does not have as a teacher
---of that rank: new teachers for Beast Map.
function M:ReportMissingTeachers()
    local any = false
    for _, entry in ipairs(Char().history) do
        local rank = RankNumber(entry.rank)
        if entry.npc and not KnownTeacher(entry.name, rank, entry.npc) then
            any = true
            local ability = entry.rank and ("%s (%s)"):format(entry.name, entry.rank) or entry.name
            M:Print(L.ABILITYLEARNED_TEACHER_MISSING:format(ability, entry.pet or "?", entry.npc, entry.zone or "?"))
        end
    end
    if not any then M:Print(L.ABILITYLEARNED_TEACHERS_ALL) end
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
    ---@type KennelKnownRank[]
    local news = {}
    for index = 1, GetNumTrainerServices() do
        local ok, name, kind = pcall(GetTrainerServiceInfo, index)
        local spellID = ok and type(name) == "string" and kind ~= "header" and RowSpellID(index)
        if spellID then
            local _, _, rankText = Kennel.SpellInfo(spellID)
            local rank = RankNumber(rankText)
            if self:MarkKnown(name, rank) then news[#news + 1] = { name = name, rank = rank } end
            read = read + 1
        end
    end
    if read > 0 then Char().trainingRead = true end
    if #news > 0 then RanksKnown("training", news) end
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
    M:Print(L.ABILITYLEARNED_TEACHES:format(pet, table.concat(list, ", ")))
    if unsure and not Char().trainingRead then M:Print(L.ABILITYLEARNED_OPEN_TRAINING) end
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

local ReadLoyalty, LoyaltyLabel = Kennel.PetLoyalty, Kennel.LoyaltyLabel

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
    local loyalty, loyaltyName = ReadLoyalty(total, level)
    local pets = Char().pets
    local seen = pets[pet]
    if not seen then
        pets[pet] = { total = total, level = level, loyalty = loyalty }
        return
    end
    -- The pet's own table is updated in place: this runs on every PET_UI_UPDATE.
    local beforeTotal, beforeLevel, beforeLoyalty = seen.total, seen.level, seen.loyalty
    seen.total, seen.level, seen.loyalty = total, level, loyalty
    local settings = self:Settings()
    local change = total - beforeTotal
    local loyaltyUp = (loyalty and beforeLoyalty and loyalty > beforeLoyalty) == true
    if loyalty and beforeLoyalty and loyalty < beforeLoyalty then
        if not settings.loyalty then return end
        local text = L.ABILITYLEARNED_LOYALTY_DROP_TEXT:format(LoyaltyLabel(loyalty, loyaltyName))
        local lost = change < 0 and L.ABILITYLEARNED_POINTS_LOST:format(-change, free) or nil
        local sound = self:Sound("loyaltySound", "WOUND")
        Kennel:ShowToast(GrowthToast("loyalty", L.ABILITYLEARNED_LOYALTY_DROP:format(pet), text, lost, sound))
        return
    end
    if change <= 0 or not settings.points then return end
    local levelUp = level > beforeLevel
    ---@type string, string
    local title, text
    if levelUp == loyaltyUp then
        title = L.ABILITYLEARNED_POINTS_GAINED:format(pet, change)
        text = L.ABILITYLEARNED_POINTS_FREE:format(free)
    elseif levelUp then
        title = L.ABILITYLEARNED_LEVEL_UP:format(pet, level)
        text = L.ABILITYLEARNED_POINTS_CAUSED:format(change, free)
    else
        -- loyaltyUp is only true when the loyalty level was read.
        title = L.ABILITYLEARNED_LOYALTY_UP:format(pet, LoyaltyLabel(loyalty --[[@as number]], loyaltyName))
        text = L.ABILITYLEARNED_POINTS_CAUSED:format(change, free)
    end
    Kennel:ShowToast(GrowthToast("points", title, text, nil, self:Sound("pointsSound", "AGGRO")))
end

---The page's button: what the pet out can teach, whenever asked, also when that is nothing.
function M:ReportTeachable()
    if not UnitExists("pet") then
        M:Print(L.ABILITYLEARNED_NO_PET)
        return
    end
    local pet = UnitName("pet")
    local list, unsure = Teachable()
    if #list == 0 then
        M:Print(L.ABILITYLEARNED_NOTHING:format(pet))
    else
        Say(pet, list, unsure)
    end
end
