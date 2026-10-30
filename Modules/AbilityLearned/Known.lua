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
-- rank, so the row's spell comes from a hidden tooltip and the rank from that spell. On Classic Era
-- and Burning Crusade, Beast Training is the craft window, whose rows give name and rank text.
-- Either way each rank's training point cost and pet level are kept, for what the pet out's free
-- points can buy (Affordable).

---@type Addon
local Addon = ns
local L = Addon.L
local M = Addon:GetModule("AbilityLearned") --[[@as AddonAbilityLearned]]

local HISTORY_MAX = 200
local BEAST_TRAINING_ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"

-- The list said last for each pet, so summoning it again stays quiet until there is news.
---@type table<string, string>
local lastSaid = {}

local scanTip = CreateFrame("GameTooltip", Addon.Global("ScanTooltip"), nil, "GameTooltipTemplate")

---This character's data.
---@return AddonAbilityLearnedChar
local function Char()
    return M.db.char --[[@as AddonAbilityLearnedChar]]
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

---Sends BEASTKEEPER_RANKS_KNOWN with the ranks that were news (docs\04-hooking.md).
---@param source "learn"|"training"
---@param ranks AddonKnownRank[]
local function RanksKnown(source, ranks)
    Addon:SendMessage(Addon.messages.ranksKnown, { module = M:GetName(), source = source, ranks = ranks })
end

---Whether a pet with this ability at this rank could teach it to this character: an ability
---learned from beasts, at a higher rank than the highest known. Also for the Pet Journal.
---@param name string
---@param rank string? the client's rank text, "Rank 3"
---@return boolean
function M:CanTeach(name, rank)
    return M.IsWildAbility(name) and RankNumber(rank) > (Char().known[name] or 0)
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

---Adds a learn to the history, keeping the last HISTORY_MAX, and to what is known; sends
---BEASTKEEPER_ABILITY_LEARNED (docs\04-hooking.md).
---@param entry AddonLearnEntry
function M:RecordLearn(entry)
    local history = Char().history
    history[#history + 1] = entry
    while #history > HISTORY_MAX do
        table.remove(history, 1)
    end
    local rank = RankNumber(entry.rank)
    Addon:SendMessage(Addon.messages.abilityLearned, {
        module = M:GetName(),
        name = entry.name,
        rank = rank,
        pet = entry.pet,
        npc = entry.npc,
        zone = entry.zone,
    })
    if self:MarkKnown(entry.name, rank) then RanksKnown("learn", { { name = entry.name, rank = rank } }) end
end

---One history line: "2026-10-07 14:03  Claw (Rank 2), from Fluffy, Darkshore".
---@param entry AddonLearnEntry
---@return string
local function HistoryLine(entry)
    ---@type string
    local line = date("%Y-%m-%d %H:%M", entry.t) .. "  " .. entry.name
    if entry.rank then line = line .. " (" .. entry.rank .. ")" end
    if entry.pet then line = line .. ", " .. L.ABILITYLEARNED_HISTORY_FROM:format(entry.pet) end
    if entry.zone then line = line .. ", " .. entry.zone end
    return line
end

---Whether Beastkeeper's beast data (Data\Beasts.lua) has beast `npc` as a teacher of an ability's rank.
---@param name string the ability's name in the client's language
---@param rank number
---@param npc number
---@return boolean
local function KnownTeacher(name, rank, npc)
    local data = Addon.data --[[@as AddonData]]
    for _, info in pairs(data.petAbilityRanks) do
        if info.rank == rank and Addon.SpellInfo(info.ability) == name then
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

-- The ranks a Beast Training read found new, refilled for each read.
---@type AddonKnownRank[]
local news = {}

---Keeps a rank Beast Training lists: known to the hunter, its training point cost and the pet
---level it needs (the same for every character: the namespace's global), and that the pet out's
---family is shown the ability.
---@param name string
---@param rank number
---@param cost GameValue
---@param level GameValue
local function KeepRow(name, rank, cost, level)
    if M:MarkKnown(name, rank) then news[#news + 1] = { name = name, rank = rank } end
    if type(cost) ~= "number" or not Addon.Readable(cost) then return end
    local global = M.db.global --[[@as AddonAbilityLearnedGlobal]]
    global.costs[name] = global.costs[name] or {}
    global.costs[name][rank] = { cost = cost, level = Addon.Readable(level) and tonumber(level) or 0 }
    local family = Addon.PetFamilyID()
    if not family then return end
    global.taught[family] = global.taught[family] or {}
    global.taught[family][name] = true
end

---After a Beast Training read: whether it read anything, and the news.
---@param read number rows read
local function Finish(read)
    if read > 0 then Char().trainingRead = true end
    if #news > 0 then RanksKnown("training", news) end
end

---Reads the hunter's learned ranks from Beast Training, WoW: Forever's (the trainer window without
---an NPC; the pet trainer type's cost is its training points). A row that cannot be read is skipped.
function M:ReadBeastTraining()
    if UnitExists("npc") then return end
    local read = 0
    wipe(news)
    for index = 1, GetNumTrainerServices() do
        local ok, name, kind = pcall(GetTrainerServiceInfo, index)
        local spellID = ok and type(name) == "string" and kind ~= "header" and RowSpellID(index)
        if spellID then
            local _, _, rankText = Addon.SpellInfo(spellID)
            KeepRow(
                name --[[@as string]],
                RankNumber(rankText),
                GetTrainerServiceCost(index),
                GetTrainerServiceLevelReq(index)
            )
            read = read + 1
        end
    end
    Finish(read)
end

---Reads Beast Training on Classic Era and Burning Crusade, the craft window: each row a rank the
---hunter learned, with its cost and pet level (GetCraftInfo's 6th and 7th returns). Enchanting's
---window has no cost, and is left alone.
function M:ReadBeastCraft()
    local read = 0
    wipe(news)
    -- The craft window is there only on the clients that send CRAFT_SHOW (Classic Era, Burning Crusade).
    ---@diagnostic disable-next-line: wrong-flavor-api
    for index = 1, GetNumCrafts() do
        ---@diagnostic disable-next-line: wrong-flavor-api
        local name, rankText, kind, _, _, cost, level = GetCraftInfo(index)
        if type(name) == "string" and kind ~= "header" and type(cost) == "number" then
            KeepRow(name, RankNumber(rankText), cost, level)
            read = read + 1
        end
    end
    Finish(read)
end

-- What the free points can buy, refilled for each ask.
---@type string[]
local affordable = {}

---What the pet out's free training points can buy: per ability its family is shown in Beast
---Training, the highest rank the hunter knows that the pet does not have yet, its level allows and
---the free points cover (Beast Training's own test: the rank's cost against the free points), as
---"Bite rank 2 (10)", sorted. Empty while a cost, the family or the pet's values are unknown.
---@return string[]
function M:Affordable()
    wipe(affordable)
    local free = Addon.PetTrainingPoints()
    local family, level = Addon.PetFamilyID(), UnitLevel("pet")
    local global = self.db.global --[[@as AddonAbilityLearnedGlobal]]
    local taught = family and global.taught[family]
    if not free or not taught or type(level) ~= "number" or not Addon.Readable(level) then return affordable end
    local petSpells = Addon.PetSpells()
    for name in pairs(taught) do
        local spell = petSpells[name]
        local has = spell and RankNumber(spell.rank) or 0
        local costs = global.costs[name] or {}
        ---@type number?, number?
        local best, price
        for rank in pairs(Char().ranks[name] or {}) do
            local row = costs[rank]
            if row and rank > has and row.cost <= free and row.level <= level and (not best or rank > best) then
                best, price = rank, row.cost
            end
        end
        if best then affordable[#affordable + 1] = L.ABILITYLEARNED_AFFORDABLE:format(name, best, price) end
    end
    table.sort(affordable)
    return affordable
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
    for name, spell in pairs(Addon.PetSpells()) do
        if M:CanTeach(name, spell.rank) then
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

local LoyaltyLabel = Addon.LoyaltyLabel

---A toast about the pet out's growth, of `kind` ("points" or "loyalty").
---@param kind string
---@param title string
---@param text string
---@param hint string?
---@param sound AddonSound?
---@return AddonToastInfo
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

---The core's BEASTKEEPER_PET_GROWTH (the pet's points total, level or loyalty changed since last seen):
---a toast when its total rose, naming the cause when there is one (a level-up, a higher loyalty
---level), and one when its loyalty level dropped, with the points that cost. A level-up at loyalty
---level 1 brings no points and says nothing.
---@param _ string the message
---@param event AddonPetGrowthEvent
function M:OnGrowth(_, event)
    local settings = self:Settings()
    local pet, level, loyalty, loyaltyName = event.pet, event.level, event.loyalty, event.loyaltyName
    local before, free = event.before, event.free
    local beforeLevel, beforeLoyalty = before.level, before.loyalty
    local change = event.points - before.points
    local loyaltyUp = (loyalty and beforeLoyalty and loyalty > beforeLoyalty) == true
    if loyalty and beforeLoyalty and loyalty < beforeLoyalty then
        if not settings.loyalty then return end
        local text = L.ABILITYLEARNED_LOYALTY_DROP_TEXT:format(LoyaltyLabel(loyalty, loyaltyName))
        local lost = change < 0 and L.ABILITYLEARNED_POINTS_LOST:format(-change, free) or nil
        local sound = self:Sound("loyaltySound", "WOUND")
        Addon:ShowToast(GrowthToast("loyalty", L.ABILITYLEARNED_LOYALTY_DROP:format(pet), text, lost, sound))
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
    Addon:ShowToast(GrowthToast("points", title, text, nil, self:Sound("pointsSound", "AGGRO")))
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
